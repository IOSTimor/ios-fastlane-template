class IosFastlaneTemplate < Formula
  desc "Local IPA builder and release template installer for iOS"
  homepage "https://github.com/IOSTimor/ios-fastlane-template"
  url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.3.1/scripts/install.sh"
  version "1.3.1"
  sha256 "881b334a4f76439dd4984b8b9cd666483f3107a23fabc9a043d35bf705c4a970"
  license "MIT"

  depends_on "bash"
  depends_on "fastlane"
  depends_on "ruby"

  resource "local-ipa-builder" do
    url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.3.1/scripts/build_local.rb"
    sha256 "3b81ac1d1c5bb412db7bb937dc43c5199f6e759e8302a1eb8ff87dfd1a489dc4"
  end

  def install
    libexec.install "install.sh"
    resource("local-ipa-builder").stage do
      libexec.install "build_local.rb"
    end

    (bin/"ios-fastlane-template").write <<~EOS
      #!#{Formula["bash"].opt_bin}/bash
      export PATH="#{Formula["ruby"].opt_bin}:$PATH"
      export REPO_OWNER="IOSTimor"
      export REPO_NAME="ios-fastlane-template"
      export REPO_REF="v1.3.1"
      export ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/tags/${REPO_REF}"
      export SCRIPT_NAME_OVERRIDE="$(basename "$0")"
      exec "#{Formula["bash"].opt_bin}/bash" "#{libexec}/install.sh" "$@"
    EOS
    bin.install_symlink bin/"ios-fastlane-template" => "iosipa"
  end

  test do
    output = shell_output("#{bin}/ios-fastlane-template 2>&1", 1)
    assert_match "Usage:", output
    assert_match "Automatically find an iOS app", shell_output("#{bin}/ios-fastlane-template build --help")
    assert_predicate bin/"iosipa", :symlink?
    assert_match "Usage: iosipa build", shell_output("#{bin}/iosipa build --help")
    assert_match "Usage: iosipa", shell_output("#{bin}/iosipa --help")
    (testpath/"DemoApp/DemoApp.xcodeproj").mkpath
    system bin/"ios-fastlane-template", testpath/"DemoApp"
    assert_predicate testpath/"DemoApp/fastlane/Fastfile", :exist?
    mock_bin = testpath/"mock-bin"
    mock_bin.mkpath
    (mock_bin/"xcodebuild").write <<~RUBY
      #!#{Formula["ruby"].opt_bin}/ruby
      require "json"
      if ARGV.include?("-list")
        puts JSON.generate(project: { schemes: ["ActualApp"] })
      else
        puts JSON.generate([{ buildSettings: {
          "PRODUCT_TYPE" => "com.apple.product-type.application",
          "SUPPORTED_PLATFORMS" => "iphoneos iphonesimulator",
          "CODE_SIGN_STYLE" => "Automatic",
          "DEVELOPMENT_TEAM" => "TESTTEAM01"
        } }])
      end
    RUBY
    (mock_bin/"fastlane").write <<~RUBY
      #!#{Formula["ruby"].opt_bin}/ruby
      require "fileutils"
      abort "Unexpected action" unless ARGV.shift(2) == ["run", "build_app"]
      options = ARGV.to_h { |argument| argument.split(":", 2) }
      export = File.read(options.fetch("export_options"))
      abort "Must export locally" unless export.include?("<key>destination</key><string>export</string>")
      output = File.join(options.fetch("output_directory"), options.fetch("output_name"))
      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, "test IPA")
    RUBY
    chmod 0755, mock_bin/"xcodebuild"
    chmod 0755, mock_bin/"fastlane"
    ENV.prepend_path "PATH", mock_bin
    %w[iosipa ios-fastlane-template].each do |command|
      output_dir = testpath/"DemoApp/build"/command
      system bin/command, "build", testpath/"DemoApp", "--non-interactive", "--output-dir", output_dir
      assert_equal 1, output_dir.glob("ActualApp-*.ipa").length
    end
  end
end
