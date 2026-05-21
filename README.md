<p align="center">
  <img src="assets/app_icon.png" alt="CodexMux logo" width="160" />
</p>

<h1 align="center">CodexMux</h1>

<p align="center">A macOS menu bar app to track and sort your Codex account limits at a glance.</p>

## Features

- Reads Codex sessions from `~/.codex/auth.json`
- Automatically discovers and tracks accounts
- Ranks accounts by usage pressure and nearest reset
- Supports nicknames to keep email addresses off-screen

## Development

Run directly:

```bash
swift run CodexMux
```

Build the native macOS app bundle:

```bash
./scripts/build-app.sh
open CodexMux.app
```

`scripts/build-app.sh` generates a native macOS app bundle, refreshes the repo-root `CodexMux.app`, and uses `assets/CodexMux.icns` as the final app icon. If that `.icns` file is missing, it is regenerated from `assets/app_icon.png`.

## Packaging

Build a Homebrew release archive and cask:

```bash
./scripts/package-homebrew.sh --version 1.0.0 --repo YOUR_GITHUB_OWNER/CodexBoard
```
