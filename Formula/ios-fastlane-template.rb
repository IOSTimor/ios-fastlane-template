class IosFastlaneTemplate < Formula
  desc "Installer for the reusable iOS fastlane release template"
  homepage "https://github.com/IOSTimor/ios-fastlane-template"
  url "https://raw.githubusercontent.com/IOSTimor/ios-fastlane-template/main/scripts/install.sh"
  version "1.1.0"
  sha256 "5a907337508b8a20ba7723b62dee28a3b0830626ec797b16ad7630c4ecde0cc0"
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
