cask "claude-code-companion" do
  version "0.1.4"
  sha256 "a70e748034c1425d0fdb7332ebf02fe43e9c6aef3c965ec25601a34654a4a429"

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

    # Autostart on login: drop a LaunchAgent so the daemon is up before the
    # first artifact write of each session — fixes the "nothing pops after a
    # reboot because the daemon wasn't running yet" issue. User can remove via
    # `launchctl unload` or via the `brew uninstall --zap` path below.
    plist_path = File.join(Dir.home, "Library", "LaunchAgents", "Companion Overlay.plist")
    exe_path   = "#{appdir}/Companion Overlay.app/Contents/MacOS/companion-overlay"
    File.write(plist_path, <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>Companion Overlay</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{exe_path}</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>ProcessType</key>
        <string>Interactive</string>
      </dict>
      </plist>
    PLIST
    # Load it now so autostart starts working without a reboot (idempotent —
    # safe if already loaded from a prior install). Failure here is non-fatal
    # (the plist still takes effect on next login).
    system_command "/bin/launchctl", args: ["load", "-w", plist_path],
                   sudo: false, print_stderr: false
  end

  uninstall_preflight do
    # Stop and unregister the LaunchAgent so an uninstall doesn't leave a
    # dangling plist that tries to launch a deleted binary on next login.
    plist_path = File.join(Dir.home, "Library", "LaunchAgents", "Companion Overlay.plist")
    if File.exist?(plist_path)
      system_command "/bin/launchctl", args: ["unload", plist_path],
                     sudo: false, print_stderr: false
    end
  end

  zap trash: [
    "~/Library/LaunchAgents/Companion Overlay.plist",
    "~/Library/Logs/companion-overlay.log",
  ]

  caveats <<~EOS
    Companion Overlay is an unsigned preview build. This cask clears the macOS
    quarantine flag for you on install, so no right-click → Open is needed.

    The overlay autostarts on every login (via a LaunchAgent dropped at
    ~/Library/LaunchAgents/Companion Overlay.plist) so it's already running
    when you start a new session. Remove with `launchctl unload`, or get rid
    of all state with `brew uninstall --zap claude-code-companion`.

    Sanity-check the install any time with:

      companion doctor

    For the auto-pop loop — so Claude's HTML artifacts open in the overlay
    automatically — install the Claude Code plugin (which also adds a
    Stop-hook backstop so deliverables don't get lost in walls of terminal
    text):

      /plugin marketplace add mrgyatso/claude-code-companion
      /plugin install companion@claude-code-companion

    Then explore /companion:doctor and /companion:example inside Claude Code.
  EOS
end
