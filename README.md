# CodexBoard

CodexBoard is a local-first multi-account Codex usage dashboard built from the
`Hsiii/frontend-template` starter. It borrows the cookie-driven usage-fetch
approach from CodexBar, but changes the topology for multi-account use:

- the dashboard reads from one normalized local cache
- each account is synced independently
- the browser UI never needs all account cookies at the same time

## What is implemented

- Vite + React dashboard with a distinctive operations-board layout
- Bun local cache API at `http://localhost:8787`
- sample cache bootstrap so the UI renders immediately
- Swift menu bar feeder scaffold that can turn per-account ChatGPT cookies into
  normalized snapshots and push them into the local cache

## Local architecture

1. `macos/CodexBoardPulse` runs one periodic fetch loop across configured
   accounts.
2. Each loop uses that account's ChatGPT cookie to request
   `https://chatgpt.com/api/auth/session`, then uses the returned bearer token
   against `https://chatgpt.com/backend-api/wham/usage`.
3. The feeder normalizes the response into the shared account snapshot schema.
4. The Bun service stores snapshots in `~/.codexboard/cache.json`.
5. The Vite app polls `/api/cache` and renders the local comparison dashboard.

## Multi-account approaches worth considering

- Menu bar pusher: simplest local-first option and the one implemented here.
- Browser profile collectors: one Chrome profile per account, harvested by a
  local automation job rather than a GUI menu bar app.
- Remote account relays: one background worker per account that only emits
  sanitized metrics back to your machine.
- Shared browser extension: if you already maintain a Chrome extension, inject a
  background task that reads the active account context and posts snapshots into
  the same cache API.

## Run the dashboard

```bash
bun install
bun run dev
```

This starts:

- Vite on `http://localhost:5173`
- the local cache service on `http://localhost:8787`

If you want only the API:

```bash
bun run dev:server
```

To reset the local cache back to bundled sample data:

```bash
bun run feed:sample
```

## Run checks

```bash
bun run check
```

## Menu bar feeder

The Swift app lives in
`/Users/hsi/Documents/Projects/Personal/CodexBoard/macos/CodexBoardPulse`.

1. Copy `accounts.example.json` to `~/.codexboard/accounts.json`.
2. Fill in one entry per account with its own ChatGPT cookie.
3. Start the local cache API.
4. Launch the feeder:

```bash
cd macos/CodexBoardPulse
swift run
```

The current scaffold assumes the usage endpoint returns recognizable weekly and
rolling 5-hour fields. If OpenAI changes that payload, update the normalization
paths in `main.swift`.

## Notes

- The dashboard is local-first by design.
- Cookies stay in the feeder config, not in the browser UI.
- The bundled sample data is synthetic and only exists to make the app usable
  before live sync is wired up.
