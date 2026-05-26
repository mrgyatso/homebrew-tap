cask "claude-code-companion" do
  version "0.1.3"
  sha256 "b6118f644a4d3452c577b0af58a8949cd185a88bfdef82967e3754c47bab5bf7"

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

    The overlay registers itself as a macOS Login Item on first launch, so it's
    already running for every new session. Disable any time via
    System Settings → General → Login Items.

    Sanity-check the install any time with:

      companion doctor

    For the auto-pop loop — so Claude's HTML artifacts open in the overlay
    automatically — install the Claude Code plugin (which also adds a Stop-hook
    backstop so deliverables don't get lost in walls of terminal text):

      /plugin marketplace add mrgyatso/claude-code-companion
      /plugin install companion@claude-code-companion

    Then explore /companion:doctor and /companion:example inside Claude Code.
  EOS
end
