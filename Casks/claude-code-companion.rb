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

  # Unsigned preview build. The `companion` CLI and the PostToolUse hook exec the
  # app binary directly (not via LaunchServices), so a quarantined unsigned app
  # gets killed and trashed by Gatekeeper on first run. Clear the flag at install
  # time so the app launches. Remove this once the build is signed + notarized.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Companion Overlay.app"]
  end

  caveats <<~EOS
    Companion Overlay is an unsigned preview build. This cask clears the macOS
    quarantine flag for you on install, so no right-click → Open is needed.

    Verify your setup any time with:

      companion doctor
  EOS
end
