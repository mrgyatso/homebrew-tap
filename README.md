# mrgyatso/homebrew-tap

Homebrew tap for [Claude Code Companion](https://github.com/mrgyatso/claude-code-companion) — a floating overlay that renders the HTML artifacts Claude Code writes, the moment it writes them.

## Install

```sh
brew install --cask mrgyatso/tap/claude-code-companion
```

This drops **Companion Overlay.app** in `/Applications` and symlinks the `companion` CLI onto your PATH. Then run `companion doctor` to confirm everything is wired.

> Unsigned preview build — first launch, right-click the app → **Open**, or run
> `xattr -dr com.apple.quarantine "/Applications/Companion Overlay.app"`.
