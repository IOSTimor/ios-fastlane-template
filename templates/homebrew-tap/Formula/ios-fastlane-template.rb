class IosFastlaneTemplate < Formula
  desc "Installer for the reusable iOS fastlane release template"
  homepage "https://github.com/IOSTimor/ios-fastlane-template"
  url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh"
  version "1.2.0"
  sha256 "d9e776f46b425e25d8781643abac8ffd8d62d367ae46d112a4ed2b511542a733"
  license "MIT"

  depends_on "bash"

  def install
    libexec.install "install.sh"

    (bin/"ios-fastlane-template").write <<~EOS
      #!/bin/bash
      export REPO_OWNER="IOSTimor"
      export REPO_NAME="ios-fastlane-template"
      export REPO_REF="main"
      exec "#{libexec}/install.sh" "$@"
    EOS
  end

  test do
    output = shell_output("#{bin}/ios-fastlane-template 2>&1", 1)
    assert_match "Usage:", output
  end
end
