#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'shellwords'

# This adapter invokes existing release lanes. It never installs/overwrites an App's workflow.
class IosipaRelease
  class Error < StandardError; end
  LANES = { 'testflight' => 'testflight_only', 'metadata' => 'metadata_only', 'submit' => 'submit_review' }.freeze

  def initialize(argv)
    @action = argv.shift
    raise Error, 'Choose testflight, metadata or submit' unless LANES.key?(@action)
    @parameters = {}
    @dry_run = false
    @non_interactive = false
    name = ENV.fetch('SCRIPT_NAME_OVERRIDE', 'iosipa')
    parser = OptionParser.new do |options|
      options.banner = "Usage: #{name} #{@action} [PROJECT_DIRECTORY] [options]"
      options.separator "Uses fastlane ios #{LANES.fetch(@action)} in an existing release setup; directory defaults to the current directory."
      options.on('--app-identifier BUNDLE_ID', 'Override APP_IDENTIFIER') { |value| @parameters[:app_identifier] = value }
      options.on('--dry-run', 'Print the plan without installing gems, logging in or contacting Apple') { @dry_run = true }
      options.on('--non-interactive', 'Run fastlane in CI mode; do not prompt for login/input') { @non_interactive = true }
      if @action == 'testflight'
        { '--scheme NAME' => :scheme, '--project PATH' => :project, '--workspace PATH' => :workspace,
          '--configuration NAME' => :configuration, '--version VERSION' => :version, '--build-number NUMBER' => :build_number,
          '--groups GROUPS' => :groups, '--testers EMAILS' => :testers, '--changelog TEXT' => :beta_description }.each do |flag, key|
          options.on(flag) { |value| @parameters[key] = value }
        end
        options.on('--external', 'Distribute to external groups after processing; requires --groups') { @parameters[:distribute_external] = true }
        options.on('--[no-]wait', 'Wait for build processing (external distribution always waits)') { |value| @parameters[:skip_waiting_for_build_processing] = !value }
      else
        options.on('--[no-]metadata', 'Upload local metadata (metadata: default on; submit: default off)') { |value| @parameters[:upload_metadata] = value }
        options.on('--[no-]screenshots', 'Upload local screenshots (metadata: auto-detect; submit: default off)') { |value| @parameters[:upload_screenshots] = value }
        if @action == 'submit'
          options.on('--version VERSION', 'Required: App Store version of the existing build') { |value| @parameters[:version] = value }
          options.on('--build-number NUMBER', 'Required: select the exact uploaded build') { |value| @parameters[:build_number] = value }
          options.on('--automatic-release', 'Release automatically after review approval (default: manual)') { @parameters[:automatic_release] = true }
        end
      end
      options.on('-h', '--help') { puts options; return }
    end
    arguments = parser.parse(argv)
    raise Error, 'Specify only one project directory' if arguments.length > 1
    @root = File.expand_path(arguments.first || '.')
    raise Error, "Project directory does not exist: #{@root}" unless File.directory?(@root)
    unless File.file?(File.join(@root, 'fastlane', 'Fastfile'))
      raise Error, "Release setup not found. Run #{name} #{@root.shellescape} once, then configure fastlane/.env. Existing project files will not be overwritten by this command."
    end
    @parameters.each do |key, value|
      raise Error, "Empty value for #{key}" if value.is_a?(String) && value.strip.empty?
    end
    if @action == 'submit' && (!@parameters[:version] || !@parameters[:build_number])
      raise Error, 'submit requires --version and --build-number to select the exact existing build'
    end
    if @parameters[:distribute_external]
      raise Error, '--external requires --groups' unless @parameters[:groups]
      raise Error, '--external cannot be used with --no-wait' if @parameters[:skip_waiting_for_build_processing]
      @parameters[:skip_waiting_for_build_processing] = false
    end
    run
  end

  private

  def executable(name)
    ENV.fetch('PATH', '').split(File::PATH_SEPARATOR).map { |directory| File.join(directory, name) }
       .find { |path| File.file?(path) && File.executable?(path) }
  end

  def run
    gemfile = File.join(@root, 'Gemfile')
    bundled = File.file?(gemfile)
    command = bundled ? ['bundle', 'exec', 'fastlane'] : ['fastlane']
    command += ['ios', LANES.fetch(@action)] + @parameters.map { |key, value| "#{key}:#{value}" }
    puts "Project: #{@root}\nAction: #{@action}\nCommand: #{command.shelljoin}"
    if @dry_run
      puts 'Dry run complete. No dependency installation, authentication, build, upload or submission performed.'
      return
    end

    environment = ENV.keys.select { |key| key.start_with?('BUNDLE_') }.each_with_object({}) { |key, clean| clean[key] = nil }
    environment.merge!('RUBYOPT' => nil, 'FASTLANE_SKIP_UPDATE_CHECK' => '1', 'FASTLANE_OPT_OUT_USAGE' => '1')
    environment['BUNDLE_GEMFILE'] = gemfile if bundled
    environment['CI'] = 'true' if @non_interactive
    if bundled
      raise Error, 'Bundler is required. Install Ruby/Bundler before using this project Gemfile.' unless executable('bundle')
      unless system(environment, 'bundle', 'check', chdir: @root, out: File::NULL, err: File::NULL)
        puts 'Installing this project’s Ruby dependencies...'
        raise Error, 'bundle install failed; check the project Ruby version and Gemfile.lock' unless system(environment, 'bundle', 'install', chdir: @root)
      end
    else
      raise Error, 'fastlane was not found; install it or add a project Gemfile' unless executable('fastlane')
    end
    success = system(environment, *command, chdir: @root)
    raise Error, "#{@action} failed. Check the fastlane output and fastlane/.env configuration." unless success
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    IosipaRelease.new(ARGV)
  rescue IosipaRelease::Error, OptionParser::ParseError => error
    warn "Error: #{error.message}"
    exit 1
  rescue Interrupt
    warn 'Operation cancelled.'
    exit 130
  end
end
