cask "claude-code-companion" do
  version "0.1.2"
  sha256 "ed70ac081f92e0988bba3463a53682bc2d09f500d9d51c0fbe815c9689c81c7d"

  url "https://github.com/mrgyatso/claude-code-companion/releases/download/v#{version}/Companion.Overlay_#{version}_universal.dmg"
  name "Companion Overlay"
  desc "Floating overlay that renders the HTML artifacts Claude Code writes"
  homepage "https://github.com/mrgyatso/claude-code-companion"

  depends_on macos: ">= :big_sur"

  app "Companion Overlay.app"
  binary "#{appdir}/Companion Overlay.app/Contents/Resources/scripts/companion"

  caveats <<~EOS
    Companion Overlay is an unsigned preview build. On first launch macOS
    Gatekeeper will block it. Either right-click the app in /Applications and
    choose Open, or clear the quarantine flag:

      xattr -dr com.apple.quarantine "/Applications/Companion Overlay.app"

    Then verify your setup with:

      companion doctor
  EOS
end
