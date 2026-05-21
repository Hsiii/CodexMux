# CodexMux

CodexMux is a native macOS menu bar app that keeps your Codex account limits
visible, synced, and ranked so you can quickly see which account has room left
before you start your next task.

It is built for the simple workflow first: sign in to the Codex accounts you
already use, open the app, and let the menu bar tell you where your headroom is.

## Why it exists

Codex usage is easy to lose track of when you work across personal and team
accounts, multiple workspaces, or different reset windows. CodexMux turns that
into one local control panel so you do not have to keep checking each account
manually.

## What it does

- Reads your current Codex session automatically from `~/.codex/auth.json`
- Syncs usage into a local cache at `~/.codexmux/cache.json`
- Normalizes weekly and rolling 5-hour windows into one consistent view
- Sorts accounts by urgency instead of just listing them alphabetically
- Keeps a short per-account history so usage changes are easier to read over
  time
- Lets you rename accounts locally with nicknames

## First run

1. Sign in to Codex on the machine the way you normally do.
2. Launch CodexMux.
3. Open the menu bar app and it will read your current session automatically.

Run directly:

```bash
cd /Users/hsi/Documents/Projects/Personal/CodexBoard
swift run CodexMux
```

Or build a normal `.app` bundle:

```bash
cd /Users/hsi/Documents/Projects/Personal/CodexBoard
./scripts/build-app.sh
open .build/apple/CodexMux.app
```

On first launch, CodexMux creates `~/.codexmux/cache.json`.

## How syncing works

For the default setup, CodexMux reads the ambient Codex account from
`~/.codex/auth.json`, fetches usage from
`https://chatgpt.com/backend-api/wham/usage`, resolves the workspace name when
available, and writes the normalized result into the local cache.

The menu UI reads from that cache, which keeps the app fast and avoids waiting
on fresh network calls every time you open it.

## How accounts are merged

CodexMux treats an account identity as:

- `email + plan`

This keeps repeated syncs from creating duplicate cards for the same logical
account. When usage changes, CodexMux appends a fresh history point. When it
does not change, it does not add noise. The app keeps the latest 12 history
points per account.

For first-time users, the practical benefit is simple: the account list stays
stable and readable instead of growing into duplicate snapshots.

## How sorting works

The menu is designed to help you choose where to work next, not just to display
raw numbers.

Accounts are ordered by:

1. weekly usage pressure versus where the account is expected to be in its reset
   cycle
2. nearest weekly reset time
3. display name

In practice, the accounts most at risk of running tight rise to the top first.

## Privacy and local data

- Current session auth is read from `~/.codex/auth.json`
- Local cache is stored at `~/.codexmux/cache.json`
- Optional extra account config is stored at `~/.codexmux/accounts.json`
- Nicknames are stored locally in `UserDefaults`

The ambient system account does not need manual cookie configuration.

## Advanced: extra accounts

Most people should start by just signing in and opening the app.

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
