#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'
require 'optparse'
require 'shellwords'
require 'tmpdir'

class LocalIpaBuilder
  class Error < StandardError; end

  EXCLUDED_DIRECTORIES = %w[.git .build .swiftpm Pods Carthage node_modules build DerivedData vendor].freeze
  EXPORT_METHODS = %w[development ad-hoc enterprise app-store].freeze

  def initialize(argv)
    @options = { configuration: 'Release', export_method: 'development', interactive: true, provisioning_updates: true }
    @parser = OptionParser.new do |parser|
      parser.banner = 'Usage: ios-fastlane-template build [PROJECT_DIRECTORY] [options]'
      parser.separator 'Automatically find an iOS app and export a local IPA. Directory defaults to the current directory.'
      parser.on('--project PATH', 'Use a specific .xcodeproj') { |value| @options[:project] = value }
      parser.on('--workspace PATH', 'Use a specific .xcworkspace') { |value| @options[:workspace] = value }
      parser.on('--scheme NAME', 'Use a specific application scheme') { |value| @options[:scheme] = value }
      parser.on('--configuration NAME', 'Build configuration (default: Release)') { |value| @options[:configuration] = value }
      parser.on('--export-method METHOD', EXPORT_METHODS, 'development, ad-hoc, enterprise or app-store (always exports locally)') { |value| @options[:export_method] = value }
      parser.on('--output-dir PATH', 'Output directory (default: PROJECT_DIRECTORY/build)') { |value| @options[:output_dir] = value }
      parser.on('--non-interactive', 'Fail on ambiguity instead of prompting') { @options[:interactive] = false }
      parser.on('--no-provisioning-updates', 'Do not let Xcode refresh automatic signing assets') { @options[:provisioning_updates] = false }
      parser.on('--dry-run', 'Inspect Xcode and print the plan without installing tools or building') { @options[:dry_run] = true }
      parser.on('-h', '--help', 'Show help') { puts parser; return }
    end
    arguments = @parser.parse(argv)
    raise Error, 'Specify only one project directory' if arguments.length > 1
    raise Error, 'Choose either --project or --workspace' if @options[:project] && @options[:workspace]

    @root = File.expand_path(arguments.first || '.')
    raise Error, "Project directory does not exist: #{@root}" unless File.directory?(@root)
    if %w[.xcodeproj .xcworkspace].include?(File.extname(@root))
      @options[File.extname(@root) == '.xcworkspace' ? :workspace : :project] = @root
      @root = File.dirname(@root)
    end
    run
  end

  private

  def executable(name)
    ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).map { |directory| File.join(directory, name) }
       .find { |path| File.file?(path) && File.executable?(path) }
  end

  def capture_json(command)
    stdout, stderr, status = Open3.capture3(*command, chdir: @root)
    unless status.success?
      detail = stderr.lines.last(8).join.strip
      raise Error, "Xcode inspection failed: #{command.shelljoin}\n#{detail}"
    end
    data = JSON.parse(stdout)
    if data.is_a?(Array)
      errors = data.map { |entry| entry['error'] if entry.is_a?(Hash) }.compact
      raise Error, "Xcode could not load build settings: #{errors.join('; ')}" unless errors.empty?
    end
    data
  rescue JSON::ParserError
    raise Error, "Xcode did not return valid JSON: #{command.shelljoin}"
  end

  def discover(directory = @root, depth = 0)
    return [] if depth > 2

    Dir.children(directory).sort.flat_map do |name|
      path = File.join(directory, name)
      next [] if EXCLUDED_DIRECTORIES.include?(name) || File.symlink?(path) || !File.directory?(path)
      next [path] if %w[.xcodeproj .xcworkspace].include?(File.extname(path))

      discover(path, depth + 1)
    end
  end

  def choose(label, entries, flag)
    return entries.first if entries.length == 1

    choices = entries.each_with_index.map { |entry, index| "  #{index + 1}. #{entry}" }.join("\n")
    unless @options[:interactive]
      raise Error, "Multiple #{label}s found:\n#{choices}\nChoose one with #{flag}."
    end
    begin
      File.open('/dev/tty', 'r+') do |terminal|
        unless terminal.tty?
          raise Error, "Multiple #{label}s found:\n#{choices}\nChoose one with #{flag}."
        end
        terminal.puts "Multiple #{label}s found:\n#{choices}"
        loop do
          terminal.print "Select #{label} [1-#{entries.length}]: "
          terminal.flush
          input = terminal.gets
          raise Error, "No selection received. Use #{flag}." unless input
          index = Integer(input.strip, 10) rescue nil
          return entries[index - 1] if index && index.between?(1, entries.length)
          terminal.puts 'Enter a number from the list.'
        end
      end
    rescue Errno::ENXIO, Errno::ENODEV, Errno::ENOENT, Errno::EACCES
      raise Error, "Multiple #{label}s found:\n#{choices}\nChoose one with #{flag}."
    end
  end

  def find_container
    explicit = @options[:workspace] || @options[:project]
    if explicit
      path = File.expand_path(explicit, @root)
      expected = @options[:workspace] ? '.xcworkspace' : '.xcodeproj'
      raise Error, "Expected an existing #{expected}: #{path}" unless File.directory?(path) && File.extname(path) == expected
      return path
    end
    containers = discover
    workspaces = containers.select { |path| File.extname(path) == '.xcworkspace' }
    candidates = workspaces.empty? ? containers : workspaces
    raise Error, "No Xcode project/workspace found under #{@root}" if candidates.empty?

    choose('project/workspace', candidates, '--workspace PATH or --project PATH')
  end

  def build_settings(scheme)
    capture_json([@xcodebuild, *@container_arguments, '-scheme', scheme, '-configuration', @options[:configuration],
                  '-sdk', 'iphoneos', '-destination', 'generic/platform=iOS', '-derivedDataPath', @inspection_directory, '-showBuildSettings', '-json'])
  end

  def ios_app_settings(entries)
    entries.map do |entry|
      settings = entry['buildSettings'] || {}
      application = settings['PRODUCT_TYPE'] == 'com.apple.product-type.application' || settings['WRAPPER_EXTENSION'] == 'app'
      platforms = settings.fetch('SUPPORTED_PLATFORMS', '').split
      ios = platforms.empty? ? settings.fetch('SDKROOT', '').match?(/iphoneos|iPhoneOS/) : platforms.include?('iphoneos')
      settings if application && ios
    end.compact
  end

  def find_scheme
    listing = capture_json([@xcodebuild, *@container_arguments, '-list', '-json'])
    schemes = (listing.dig('workspace', 'schemes') || listing.dig('project', 'schemes') || []).uniq.sort
    raise Error, 'No schemes found. Create/share an application scheme in Xcode.' if schemes.empty?
    if @options[:scheme]
      raise Error, "Unknown scheme #{@options[:scheme]}. Available: #{schemes.join(', ')}" unless schemes.include?(@options[:scheme])
      schemes = [@options[:scheme]]
    end
    @settings = {}
    candidates = schemes.select do |scheme|
      begin
        @settings[scheme] = build_settings(scheme)
        apps = ios_app_settings(@settings[scheme])
        apps.length == 1
      rescue Error => error
        raise if @options[:scheme] || schemes.length == 1
        warn "Skipping scheme #{scheme}: #{error.message}"
        false
      end
    end
    raise Error, 'No unambiguous iOS application scheme found. Select an iOS app scheme with --scheme NAME.' if candidates.empty?

    choose('application scheme', candidates, '--scheme NAME')
  end

  def export_options
    app = ios_app_settings(@settings.fetch(@scheme)).first
    raise Error, 'Code signing is disabled for this application. Configure iOS device signing in Xcode.' if app['CODE_SIGNING_ALLOWED'] == 'NO'
    options = { 'method' => @options[:export_method], 'destination' => 'export' }
    team = app['DEVELOPMENT_TEAM'].to_s.strip
    options['teamID'] = team unless team.empty?
    style = app['CODE_SIGN_STYLE'].to_s.downcase
    options['signingStyle'] = style if %w[automatic manual].include?(style)
    profiles = {}
    @settings.fetch(@scheme).each do |entry|
      settings = entry['buildSettings'] || {}
      identifier = settings['PRODUCT_BUNDLE_IDENTIFIER'].to_s
      profile = settings['PROVISIONING_PROFILE_SPECIFIER'].to_s.strip
      profile = settings['PROVISIONING_PROFILE'].to_s.strip if profile.empty?
      profiles[identifier] = profile unless identifier.empty? || profile.empty?
    end
    options['provisioningProfiles'] = profiles unless profiles.empty?
    options
  end

  def escape_xml(value)
    value.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
  end

  def write_plist(path, values)
    serialize = lambda do |value|
      if value.is_a?(Hash)
        '<dict>' + value.map { |key, item| "<key>#{escape_xml(key)}</key>#{serialize.call(item)}" }.join + '</dict>'
      else
        "<string>#{escape_xml(value)}</string>"
      end
    end
    File.write(path, '<?xml version="1.0" encoding="UTF-8"?>' +
                     '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' +
                     '<plist version="1.0">' + serialize.call(values) + '</plist>')
  end

  def fastlane
    command = executable('fastlane')
    return command if command

    brew = executable('brew')
    raise Error, 'fastlane was not found. Install it with Homebrew: brew install fastlane' unless brew
    puts 'fastlane not found; installing it with Homebrew...'
    raise Error, 'Homebrew could not install fastlane' unless system(brew, 'install', 'fastlane')

    executable('fastlane') || raise(Error, 'fastlane was installed but is not on PATH')
  end

  def run
    @xcodebuild = executable('xcodebuild') || raise(Error, 'Xcode is required. Install Xcode and select its developer directory.')
    @container = find_container
    @container_arguments = [File.extname(@container) == '.xcworkspace' ? '-workspace' : '-project', @container]
    Dir.mktmpdir('ios-ipa-inspect-') do |directory|
      @inspection_directory = directory
      @scheme = find_scheme
    end
    options = export_options
    output = File.expand_path(@options[:output_dir] || 'build', @root)
    name = @scheme.gsub(%r{[/\\]}, '-') + '-' + Time.now.strftime('%Y%m%d-%H%M%S') + '.ipa'
    puts "Project: #{@container}\nScheme: #{@scheme}\nConfiguration: #{@options[:configuration]}"
    puts "Signing: #{options['signingStyle'] || 'from Xcode'}; team: #{options['teamID'] || 'from signing profile'}"
    puts "Export: #{options['method']} (local file)\nIPA: #{File.join(output, name)}"
    if @options[:dry_run]
      puts 'Dry run complete. No tools installed and no archive/export performed.'
      return
    end

    command = fastlane
    # Isolate gym from the app's Fastfile, Gymfile, plugins, dotenv and Bundler config.
    Dir.mktmpdir('ios-local-ipa-') do |temporary|
      plist = File.join(temporary, 'ExportOptions.plist')
      write_plist(plist, options)
      arguments = [command, 'run', 'build_app', "#{@container_arguments.first.delete_prefix('-')}:#{@container}",
                   "scheme:#{@scheme}", "configuration:#{@options[:configuration]}", 'sdk:iphoneos',
                   'destination:generic/platform=iOS', "export_method:#{@options[:export_method]}",
                   "export_options:#{plist}", "output_directory:#{output}", "output_name:#{name}", 'clean:true']
      if options['signingStyle'] == 'automatic' && @options[:provisioning_updates]
        arguments.concat(['xcargs:-allowProvisioningUpdates', 'export_xcargs:-allowProvisioningUpdates'])
      end
      environment = ENV.keys.select { |key| key.start_with?('GYM_', 'BUNDLE_') }.each_with_object({}) { |key, clean| clean[key] = nil }
      environment.merge!('RUBYOPT' => nil, 'FASTLANE_SKIP_UPDATE_CHECK' => '1', 'FASTLANE_OPT_OUT_USAGE' => '1')
      success = system(environment, *arguments, chdir: temporary)
      raise Error, 'IPA export failed. Review the Xcode/fastlane error above; check signing and project dependencies.' unless success
    end
    ipa = File.join(output, name)
    raise Error, "fastlane completed but did not produce #{ipa}" unless File.file?(ipa)

    puts "IPA generated: #{ipa}"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    LocalIpaBuilder.new(ARGV)
  rescue LocalIpaBuilder::Error, OptionParser::ParseError => error
    warn "Error: #{error.message}"
    exit 1
  rescue Interrupt
    warn 'Build cancelled.'
    exit 130
  end
end
