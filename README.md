# CodexMux

<img src="assets/demo.png" alt="CodexMux demo" width="50%"/>

A macOS menu bar app to track and sort your Codex account limits at a glance.

## Features

- Reads Codex sessions from `~/.codex/auth.json`
- Automatically discovers and tracks accounts.
- Ranks accounts by usage pressure and nearest reset.
- Support nicknames to keep email addresses off-screen.

## Install

Open the bundled app in the repo root:

```bash
open CodexMux.app
```

To refresh the tracked root bundle after rebuilding:

```bash
CODEXMUX_SYNC_TRACKED_BUNDLE=1 ./scripts/build-app.sh
```