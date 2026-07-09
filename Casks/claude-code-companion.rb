cask "claude-code-companion" do
  version "0.4.8"
  sha256 "ea2af0a3e5b38576c191ffd79ea0830bb236edf9075fa29e4ee81da2db1a617d"

  # The cask version tracks the public release tag (v0.4.8); the DMG asset name
  # embeds the overlay's own version (0.1.9), which moves on its own cadence.
  url "https://github.com/mrgyatso/claude-code-companion/releases/download/v#{version}/Companion.Overlay_0.1.9_universal.dmg"
  name "Companion Overlay"
  desc "Desktop surface where your coding agents show their work and ask what's next"
  homepage "https://github.com/mrgyatso/claude-code-companion"

  depends_on macos: :big_sur

  app "Companion Overlay.app"
  binary "#{appdir}/Companion Overlay.app/Contents/Resources/scripts/companion"

  # The overlay is a long-lived daemon that holds a single-instance socket for the
  # life of the login session. Brew swaps the bundle on disk but does not stop the
  # process, so without this the OLD binary keeps running and keeps the socket —
  # and the freshly installed build forwards its args to it and exits 0, silently.
  # The upgrade looks like it did nothing.
  #
  # `quit:` is the polite ask, and it is not sufficient on its own: builds up to
  # 0.4.8 call `api.prevent_exit()` on every ExitRequested, so they refuse an
  # AppleScript quit and brew spins for its full 10s timeout. `signal:` is what
  # actually lands — SIGTERM is not trappable by the Tauri event loop. Keep both:
  # once every install is past 0.4.8, `quit:` succeeds first and `signal:` finds
  # no process left to signal.
  uninstall quit:   "com.claudecode.companion-overlay",
            signal: ["TERM", "com.claudecode.companion-overlay"]

  # Unsigned preview build. The `companion` CLI and the PostToolUse hook exec the
  # app binary directly (not via LaunchServices), so a quarantined unsigned app
  # gets killed and trashed by Gatekeeper on first run. Clear the flag at install
  # time so the app launches. Remove this once the build is signed + notarized.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Companion Overlay.app"]

    # No autostart. Earlier versions dropped a RunAtLoad LaunchAgent here so the
    # daemon was up before the first artifact of a session. It isn't worth the
    # cost: the app then runs from login whether or not you use it, and — because
    # it owns a single-instance socket — a running copy silently swallows every
    # attempt to launch a newer build. Open it when you want it, or `companion
    # board`. Any LaunchAgent left by an earlier install is removed below.
    plist_path = File.join(Dir.home, "Library", "LaunchAgents", "Companion Overlay.plist")
    if File.exist?(plist_path)
      system_command "/bin/launchctl", args: ["unload", "-w", plist_path],
                     sudo: false, print_stderr: false
      File.delete(plist_path)
    end
  end

  uninstall_preflight do
    # Stop and unregister the LaunchAgent an older install may have left behind,
    # so an uninstall can't leave a plist pointing at a deleted binary.
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

    The overlay does not start on login — open it when you want it, or run
    `companion board`. It stays running in the background after that, so the
    next artifact pops without a cold start. Get rid of all state with
    `brew uninstall --zap claude-code-companion`.
  EOS
end
