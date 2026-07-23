cask "shelly" do
  version "0.11.0"
  sha256 "a3fdc534a5d86060e4ead7f97328f93a68dda03bad65a25da9a9862a399837c6"

  # Since v0.6.0 the app version tracks the release tag (CI enforces it), so the
  # DMG asset name is fully derivable from `version`. The DMG is built by CI
  # (release-macos.yml) — no more hand-built bundles.
  #
  # The repo was renamed claude-code-companion -> shelly with 0.10.2. GitHub redirects
  # the old path, so older casks keep resolving; this points at the real name.
  url "https://github.com/mrgyatso/shelly/releases/download/v#{version}/Shelly_#{version}_universal.dmg"
  name "Shelly"
  desc "Shell your coding agents work inside — they show their work and ask what's next"
  homepage "https://github.com/mrgyatso/shelly"

  # Renamed from claude-code-companion in 0.10.2. tap_migrations.json moves the
  # installed token across, but Homebrew will not remove an app bundle this cask
  # never installed — so a machine upgrading from Companion keeps a stale
  # "Companion Overlay.app" until the postflight below trashes it.
  conflicts_with cask: "mrgyatso/tap/claude-code-companion"
  depends_on macos: :big_sur

  app "Shelly.app"
  binary "#{appdir}/Shelly.app/Contents/Resources/scripts/shelly"

  # Unsigned preview build. The `shelly` CLI and the PostToolUse hook exec the
  # app binary directly (not via LaunchServices), so a quarantined unsigned app
  # gets killed and trashed by Gatekeeper on first run. Clear the flag at install
  # time so the app launches. Remove this once the build is signed + notarized.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Shelly.app"]

    # No autostart. Earlier versions dropped a RunAtLoad LaunchAgent here so the
    # daemon was up before the first artifact of a session. It isn't worth the
    # cost: the app then runs from login whether or not you use it, and — because
    # it owns a single-instance socket — a running copy silently swallows every
    # attempt to launch a newer build. Open it when you want it, or `shelly board`.
    # Any LaunchAgent left by an earlier install is removed here, under both names.
    ["Shelly.plist", "Companion Overlay.plist"].each do |leaf|
      plist_path = File.join(Dir.home, "Library", "LaunchAgents", leaf)
      next unless File.exist?(plist_path)

      system_command "/bin/launchctl", args: ["unload", "-w", plist_path],
                     sudo: false, print_stderr: false
      File.delete(plist_path)
    end

    # The rename leaves the old bundle behind — Homebrew only removes what the cask
    # it is replacing declared, and the token changed. Left in place it is not just
    # clutter: the old build still answers `open -a`, still owns the single-instance
    # socket if launched, and still ships a `companion` CLI whose plugin no longer
    # exists. Trash it rather than leave two apps that fight over the same socket.
    old_app = "#{appdir}/Companion Overlay.app"
    system_command "/bin/rm", args: ["-rf", old_app], sudo: false if File.exist?(old_app)
  end

  uninstall_preflight do
    # Stop and unregister the LaunchAgent an older install may have left behind,
    # so an uninstall can't leave a plist pointing at a deleted binary.
    ["Shelly.plist", "Companion Overlay.plist"].each do |leaf|
      plist_path = File.join(Dir.home, "Library", "LaunchAgents", leaf)
      next unless File.exist?(plist_path)

      system_command "/bin/launchctl", args: ["unload", plist_path],
                     sudo: false, print_stderr: false
    end
  end

  # The overlay is a long-lived daemon holding a single-instance socket. Brew swaps
  # the bundle on disk but does not stop the process, so without this the OLD binary
  # keeps running and keeps the socket — and the freshly installed build forwards its
  # argv to it and exits 0, silently. The upgrade looks like it did nothing.
  #
  # `quit:` does the work: an AppleScript quit becomes `-[NSApplication terminate:]`,
  # which nothing in the Tauri stack intercepts. `signal:` is the backstop for a build
  # that is wedged and cannot service the Apple Event; brew runs it after `quit:`, by
  # which point there is normally no process left to signal.
  #
  # Both identities are listed: a machine coming from Companion may still have the
  # old daemon running under the old bundle id, and it holds the same socket.
  uninstall quit:   ["io.github.mrgyatso.shelly", "com.claudecode.companion-overlay"],
            signal: [["TERM", "io.github.mrgyatso.shelly"],
                     ["TERM", "com.claudecode.companion-overlay"]]

  # ~/.claude/companion is listed as well as ~/.shelly: on a machine that came from
  # Companion the old path is a symlink to the new one, and a zap that removed only
  # the target would leave a dangling link behind in Claude Code's own directory.
  zap trash: [
    "~/.claude/companion",
    "~/.shelly",
    "~/Library/LaunchAgents/Companion Overlay.plist",
    "~/Library/LaunchAgents/Shelly.plist",
    "~/Library/Logs/companion-overlay.log",
    "~/Library/Logs/shelly-overlay.log",
  ]

  caveats <<~EOS
    One more command finishes the install — it wires the Claude Code plugin,
    creates the watched folder, and runs a health check:

      shelly setup

    It needs Node 18 or later (`brew install node`). Claude Code ships as a
    native binary, so having `claude` does not mean you have `node` — and the
    plugin's hooks are Node scripts.

    Then open the app with `shelly board`.

    By default Shelly only tracks sessions the app itself starts. To track
    every `claude` session wherever you launch it:

      shelly setup --external-terminals

    Sanity-check the install any time with `shelly doctor`. Inside Claude
    Code, `/shelly:html` renders a fresh page on demand and `/shelly:example`
    explains the app. Every turn ends with a page, so there is no eagerness to
    tune — a quick lookup gets a compact card, a decision gets a full document.

    Upgrading from Companion: `shelly setup` moves ~/.claude/companion to
    ~/.shelly (leaving a symlink) and removes the old plugin, which otherwise
    stays installed and quietly wins — its hooks look for the old environment
    variable, so sessions never register and artifacts never route. This cask
    trashes the old Companion Overlay.app for you.

    Shelly is an unsigned preview build. This cask clears the macOS quarantine
    flag for you on install, so no right-click → Open is needed.

    The overlay does not start on login — open it when you want it, or run
    `shelly board`. It stays running in the background after that, so the next
    artifact pops without a cold start. Get rid of all state with
    `brew uninstall --zap shelly`.
  EOS
end
