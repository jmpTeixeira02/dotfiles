# bunker

Backs up Bitwarden and Ente Auth encrypted secrets to USB drives.

## Dependencies

- [`bw`](https://bitwarden.com/help/cli/) — Bitwarden CLI
- [`ente`](https://github.com/ente-io/ente/tree/main/cli) — Ente CLI, with a user configured and export path at `$HOME/.ente`

## Usage

### `list`

Shows connected drives, lets you pick one or more, then backs up to each.

```sh
bunker list
```

### `watch`

Waits for drives to be plugged in and backs up automatically. Press Ctrl+C to stop after the current backup finishes.

```sh
bunker watch
```

## What gets backed up

| File             | Source                              |
| ---------------- | ----------------------------------- |
| `bitwarden.json` | `bw export --format encrypted_json` |
| `ente_auth.txt`  | `$HOME/.ente/ente_auth.txt`         |

Each backup is written to a timestamped directory on the drive: `bunker_YYYY-MM-DD_HHhMM/`.
