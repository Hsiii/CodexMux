<div align="center">
  <img src="assets/logo.png" alt="CodexMux logo" width="160" />

<h1>CodexMux</h1>

A macOS menu bar app to track and sort your Codex account limits at a glance.

<img src="assets/demo.png" alt="CodexMux demo" height="720" />
</div>

## Why CodexMux

- **Zero Setup:** Picks up local Codex sessions automatically and refreshes usage in the background, no manual setup required.
- **Unified Tracking:** See usage across multiple Codex accounts and workspaces in one menu bar view, without bouncing between sessions.
- **Plan your Usage:** Accounts are ranked by remaining headroom, making it obvious which account to use next.
- **Privacy First:** Keep account details readable without exposing more than you need. CodexMux supports custom display names and stores account metadata locally in a native on-disk SQLite database, so your account inventory stays private, durable, and under your control.

## Install

Open [CodexMux.app](dist/CodexMux.app) directly or [CodexMux.dmg](dist/CodexMux.dmg) to install it to your Applications folder.

## Development

Run directly:

```bash
swift run CodexMux
```

Build the native macOS app bundle:

```bash
./scripts/build-app.sh
```

Build a DMG for distribution:

```bash
./scripts/package-dmg.sh
```
