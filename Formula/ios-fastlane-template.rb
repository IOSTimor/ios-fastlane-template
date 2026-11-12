class IosFastlaneTemplate < Formula
  desc "Local IPA builder and release template installer for iOS"
  homepage "https://github.com/IOSTimor/ios-fastlane-template"
  url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.4.1/scripts/install.sh"
  version "1.4.1"
  sha256 "feba9f5a9ea4f6717343c8269ceae2726091fa230c9f68f4d01a8a98c75f4183"
  license "MIT"

  depends_on "bash"
  depends_on "fastlane"
  depends_on "ruby"

  resource "local-ipa-builder" do
    url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.4.1/scripts/build_local.rb"
    sha256 "3b81ac1d1c5bb412db7bb937dc43c5199f6e759e8302a1eb8ff87dfd1a489dc4"
  end

  resource "release-commands" do
    url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.4.1/scripts/release.rb"
    sha256 "3d27d062cacdc09fc71ba20434246453689e08806da10eca5d61a2af2e58f445"
  end

  def install
    libexec.install "install.sh"
    resource("local-ipa-builder").stage do
      libexec.install "build_local.rb"
    end

    resource("release-commands").stage do
      libexec.install "release.rb"
    end

    (bin/"ios-fastlane-template").write <<~EOS
      #!#{Formula["bash"].opt_bin}/bash
      export PATH="#{Formula["ruby"].opt_bin}:$PATH"
      export REPO_OWNER="IOSTimor"
      export REPO_NAME="ios-fastlane-template"
      export REPO_REF="v1.4.1"
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
    %w[testflight metadata submit].each do |command|
      assert_match "#{command} [PROJECT_DIRECTORY]", shell_output("#{bin}/iosipa #{command} --help")
    end
    guide_url = "https://github.com/IOSTimor/ios-fastlane-template/blob/main/docs/user_guide.md"
    assert_equal guide_url, shell_output("#{bin}/iosipa docs --url").strip
    assert_equal guide_url, shell_output("#{bin}/ios-fastlane-template docs --url").strip
    assert_match "docs", shell_output("#{bin}/iosipa docs --help")
    (testpath/"DemoApp/DemoApp.xcodeproj").mkpath
    system bin/"ios-fastlane-template", testpath/"DemoApp"
    assert_predicate testpath/"DemoApp/fastlane/Fastfile", :exist?
    system bin/"iosipa", "testflight", testpath/"DemoApp", "--dry-run"
    system bin/"iosipa", "metadata", testpath/"DemoApp", "--dry-run"
    system bin/"iosipa", "submit", testpath/"DemoApp", "--version", "1.0.0", "--build-number", "1", "--dry-run"
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
    (mock_bin/"open").write <<~SH
      #!/bin/sh
      printf '%s' "$1" > "#{testpath}/opened-docs-url"
    SH
    chmod 0755, mock_bin/"open"
    ENV.prepend_path "PATH", mock_bin
    system bin/"iosipa", "docs"
    assert_equal guide_url, (testpath/"opened-docs-url").read
    %w[iosipa ios-fastlane-template].each do |command|
      output_dir = testpath/"DemoApp/build"/command
      system bin/command, "build", testpath/"DemoApp", "--non-interactive", "--output-dir", output_dir
      assert_equal 1, output_dir.glob("ActualApp-*.ipa").length
    end
  end
end
