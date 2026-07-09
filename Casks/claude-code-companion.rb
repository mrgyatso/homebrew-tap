cask "claude-code-companion" do
  version "0.4.7"
  sha256 "6b654f40aee51107031030cc7dee91e406c12bcbe7f2206fc54c05390b755db2"

  # The cask version tracks the public release tag (v0.4.7); the DMG asset name
  # embeds the overlay's own version (0.1.8), which moves on its own cadence.
  url "https://github.com/mrgyatso/claude-code-companion/releases/download/v#{version}/Companion.Overlay_0.1.8_universal.dmg"
  name "Companion Overlay"
  desc "Desktop surface where your coding agents show their work and ask what's next"
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
    One more command finishes the install — it wires the Claude Code plugin,
    creates the watched folder, and runs a health check:

      companion setup

    It needs Node 18 or later (`brew install node`). Claude Code ships as a
    native binary, so having `claude` does not mean you have `node` — and the
    plugin's hooks are Node scripts.

    Then open the app with `companion board`.

    By default Companion only tracks sessions the app itself starts. To track
    every `claude` session wherever you launch it:

      companion setup --external-terminals

    Sanity-check the install any time with `companion doctor`. Inside Claude
    Code, `/companion:html` renders a page on demand, `/companion:mode
    selective|always|manual` sets how eagerly pages are generated, and
    `/companion:example` explains the app.

    Companion Overlay is an unsigned preview build. This cask clears the macOS
    quarantine flag for you on install, so no right-click → Open is needed.

    The overlay autostarts on every login (via a LaunchAgent dropped at
    ~/Library/LaunchAgents/Companion Overlay.plist) so it's already running
    when you start a new session. Remove with `launchctl unload`, or get rid
    of all state with `brew uninstall --zap claude-code-companion`.
  EOS
end
