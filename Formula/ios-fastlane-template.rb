class IosFastlaneTemplate < Formula
  desc "Local IPA builder and release template installer for iOS"
  homepage "https://github.com/IOSTimor/ios-fastlane-template"
  url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.3.0/scripts/install.sh"
  version "1.3.0"
  sha256 "ccbc4b7081e892a346682e80c355c418de99b13f1be1d46230d174e88c844874"
  license "MIT"

  depends_on "bash"
  depends_on "fastlane"
  depends_on "ruby"

  resource "local-ipa-builder" do
    url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.3.0/scripts/build_local.rb"
    sha256 "9044621b1a1890d7d77e43079772503e78d1ee59cd04a00400e47fcddfc8bde3"
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
      export REPO_REF="v1.3.0"
      export ARCHIVE_URL="https://codeload.github.com/${REPO_OWNER}/${REPO_NAME}/tar.gz/refs/tags/${REPO_REF}"
      export SCRIPT_NAME_OVERRIDE="ios-fastlane-template"
      exec "#{Formula["bash"].opt_bin}/bash" "#{libexec}/install.sh" "$@"
    EOS
  end

  test do
    output = shell_output("#{bin}/ios-fastlane-template 2>&1", 1)
    assert_match "Usage:", output
    assert_match "Automatically find an iOS app", shell_output("#{bin}/ios-fastlane-template build --help")
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
    system bin/"ios-fastlane-template", "build", testpath/"DemoApp", "--non-interactive"
    assert_equal 1, (testpath/"DemoApp/build").glob("ActualApp-*.ipa").length
  end
end
