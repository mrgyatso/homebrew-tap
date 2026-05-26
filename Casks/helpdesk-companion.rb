cask "helpdesk-companion" do
  version "0.2.1"
  sha256 "20692938c505551b4b02875307326dd31e46b6e45ada70ff195c685e1e60c6e2"

  url "https://github.com/mrgyatso/helpdesk-companion/releases/download/v#{version}/Helpdesk.Companion_#{version}_universal.dmg"
  name "Helpdesk Companion"
  desc "Live diagnostic copilot for MSP technician support calls"
  homepage "https://github.com/mrgyatso/helpdesk-companion"

  depends_on macos: :big_sur

  app "Helpdesk Companion.app"

  # Unsigned preview build. macOS quarantines casks by default; an unsigned
  # quarantined app gets killed by Gatekeeper on first launch. Clear the flag
  # at install time so the app launches. Remove this once the build is signed +
  # notarized (Apple Developer ID required).
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Helpdesk Companion.app"]
  end

  caveats <<~EOS
    Helpdesk Companion is an unsigned preview build. This cask clears the macOS
    quarantine flag for you on install, so no right-click → Open is needed.

    Out of the box the app runs in DEMO MODE — no API keys, no audio setup. Open
    the app and use the in-app demo to see the full Contoso/Outlook call arc.

    For live calls, set keys before launch:
        export ANTHROPIC_API_KEY=sk-ant-…
        export OPENAI_API_KEY=sk-…
        open -a "Helpdesk Companion"

    Live caller-side audio also needs BlackHole 2ch + a Multi-Output Device;
    see https://github.com/mrgyatso/helpdesk-companion#live-mode-real-calls
  EOS
end
