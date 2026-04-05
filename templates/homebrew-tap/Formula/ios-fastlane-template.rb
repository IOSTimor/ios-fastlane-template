class IosFastlaneTemplate < Formula
  desc "Installer for the reusable iOS fastlane release template"
  homepage "https://github.com/IOSTimor/ios-fastlane-template"
  url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/v1.2.1/scripts/install.sh"
  version "1.2.1"
  sha256 "b8c076530d1453cfa06d437a3a5edf304198c417d407ae193aa9c02a65164d00"
  license "MIT"

  depends_on "bash"

  def install
    libexec.install "install.sh"

    (bin/"ios-fastlane-template").write <<~EOS
      #!/bin/bash
      export REPO_OWNER="IOSTimor"
      export REPO_NAME="ios-fastlane-template"
      export REPO_REF="v1.2.1"
      export SCRIPT_NAME_OVERRIDE="ios-fastlane-template"
      exec bash "#{libexec}/install.sh" "$@"
    EOS
  end

  test do
    output = shell_output("#{bin}/ios-fastlane-template 2>&1", 1)
    assert_match "Usage:", output
  end
end
