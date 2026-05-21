# CodexMux

<img src="assets/demo.png" alt="CodexMux demo" >

A macOS menu bar app to track and sort your Codex account limits at a glance.

## Features

- Reads sessions and record accounts from `~/.codex/auth.json`.
- Groups accounts by excess usage.
- Use local nicknames to hide email addresses.

## Getting Started

Run directly:

```bash
swift run CodexMux
```

Or build as an app:

```bash
./scripts/build-app.sh
open .build/apple/CodexMux.app
```

Package a GitHub release archive and generate a Homebrew cask:

```bash
./scripts/package-homebrew.sh --version 1.0.0 --repo YOUR_GITHUB_OWNER/CodexMux
```

This writes:

- `.build/dist/CodexMux-1.0.0.zip`
- `.build/dist/codexmux.rb`

The generated cask expects a GitHub release asset published at:

```text
https://github.com/YOUR_GITHUB_OWNER/CodexMux/releases/download/v1.0.0/CodexMux-1.0.0.zip
```

To offer `brew install --cask YOUR_TAP/codexmux`, publish that archive in a
tagged GitHub release and copy the generated cask into your tap repository
under `Casks/codexmux.rb`.

## Release Structure

This repo now follows the same high-level release split as
[`steipete/CodexBar`](https://github.com/steipete/CodexBar):

- GitHub Releases host the signed app archive users download directly.
- Homebrew installs from a separate tap cask that points at the GitHub release asset.
- The generated cask declares `macOS Sonoma` or newer, so the distribution stays explicitly macOS-only.

GitHub Actions workflow:

- `.github/workflows/release.yml` packages `CodexMux.app` on `macos-14`
- On a published GitHub release, it uploads:
  - `CodexMux-<version>.zip`
  - `codexmux.rb`
- If `HOMEBREW_TAP_REPOSITORY` and `HOMEBREW_TAP_TOKEN` are configured, it also updates `Casks/codexmux.rb` in your tap automatically.

Suggested repo configuration:

- Repository variable: `HOMEBREW_TAP_REPOSITORY=YOUR_GITHUB_OWNER/homebrew-tap`
- Repository secret: `HOMEBREW_TAP_TOKEN` with push access to that tap repo

## How it Works

- **Sync:** Fetches usage from Codex API and caches it locally at `~/.codexmux/cache.json`.
- **Identity:** Accounts are tracked by `email + plan` to prevent duplicates.
- **Sorting:** Prioritizes accounts by usage pressure and nearest reset.

## Privacy

- **Local Only:** All data (auth, cache, and nicknames) is stored locally.
- **Hidden Emails:** Nicknames are used in the menu bar to keep your email addresses private and off-screen.

If you want to monitor additional accounts independently, you can create
`~/.codexmux/accounts.json` and add one object per extra account.

Minimal example:

```json
{
  "pollIntervalSeconds": 300,
  "accounts": [
    {
      "id": "work-pro",
      "label": "Work Pro",
      "email": "me@company.com",
      "workspaceLabel": "Company",
      "plan": "Codex Pro",
      "color": "#7cc6ff",
      "chatGPTCookie": "YOUR_CHATGPT_COOKIE"
    }
  ]
}
```

Supported fields come from [`AccountConfig`](./src/Model.swift):

- `id`: stable local ID for that configured account
- `label`: default display label before nicknames
- `email`: used as part of merge identity
- `workspaceLabel`: fallback workspace name if the API does not return one
- `plan`: used for display and merge identity
- `color`: card accent color
- `chatGPTCookie`: required for extra accounts
- `source`, `sessionEndpoint`, `usageEndpoint`, `accountHeader`: optional

Use `accountHeader` when a specific ChatGPT account or workspace header is
required.

## Product model

CodexMux gives you one ranked view of your Codex headroom so you can decide
where to work next without opening and comparing each account by hand.
