# claude-auth

> Switch between multiple Claude Code accounts on one Mac — like `gh auth switch`, but for Claude Code.

If you juggle more than one Claude Code login (personal, work, a client's org…), you know the pain: there's no built-in account switcher, so you end up logging out and back in every time. `claude-auth` fixes that. Save each account once, then flip between them instantly.

```console
 ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
██║     ██║     ███████║██║   ██║██║  ██║█████╗
██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝
╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
 ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
auth  ·  multi-account switcher for Claude Code
```

```console
$ claude-auth list

  Accounts   ·   2 saved

  ┌───┬──────────┬───────────────────┬───────────┬──────┬─────────┐
  │   │ ACCOUNT  │ EMAIL             │ ORG       │ PLAN │ SAVED   │
  ├───┼──────────┼───────────────────┼───────────┼──────┼─────────┤
  │ ● │ personal │ you@gmail.com     │ —         │ max  │ 2m ago  │
  │ ○ │ work     │ you@company.com   │ Acme      │ team │ 3d ago  │
  └───┴──────────┴───────────────────┴───────────┴──────┴─────────┘

  ● active    ○ saved

$ claude-auth switch work

  ✓ Switched to work  · you@company.com
  ↻ restart Claude Code (and running sessions) to use this account
```

> The real output is rendered in Claude's warm "clay" palette with a gradient wordmark. Colors auto-disable when piped or when `NO_COLOR` is set.

### Usage tracking

`claude-auth usage` shows how much of each account's rate limit you've burned — the fastest way to decide *which account to switch to*:

```console
$ claude-auth usage

  Usage   ·   weekly limit is the one that bites

  ┌───┬──────────┬──────────────────────────┬─────────────────────────────────┬─────────┐
  │   │ ACCOUNT  │ SESSION                  │ WEEK                            │ UPDATED │
  ├───┼──────────┼──────────────────────────┼─────────────────────────────────┼─────────┤
  │ ○ │ personal │ ██░░░░░░░░  23%  10:19pm │ ██░░░░░░░░  24%  Jun 26 12:29am │ live    │
  │ ● │ work     │ █░░░░░░░░░  12%  8:39pm  │ ██████░░░░  57%  Jun 25 3:29am  │ live    │
  └───┴──────────┴──────────────────────────┴─────────────────────────────────┴─────────┘

  █ <50%   █ <80%   █ ≥80%
```

`claude-auth usage <name>` gives a detailed breakdown (5-hour session, weekly all-models, weekly Sonnet/Opus) with reset countdowns.

It works across **all** accounts at once — without switching — because each account's token is already saved, and usage is fetched from Anthropic's `/api/oauth/usage` endpoint (the same data Claude Code's `/status` → Usage tab shows). Bars are colored by severity (green < 50%, amber < 80%, red ≥ 80%). If an inactive account's short-lived token has expired, the last fetched snapshot is shown with its age; switching to that account refreshes it.

---

## Why this is needed

A Claude Code login isn't a single token in a single place. It's split across **two** locations on your machine:

| What | Where | Contains |
|------|-------|----------|
| **Secrets** | macOS Keychain, service `Claude Code-credentials` | OAuth `accessToken`, `refreshToken`, `expiresAt`, plus MCP server tokens |
| **Identity** | `~/.claude.json` → `oauthAccount` + `userID` | email, organization, account UUID |

Swapping just the token leaves the app convinced it's still the old account (wrong email/org, possible mismatches). A *correct* switch has to swap **both, atomically**. That's exactly what `claude-auth` does — and why hand-pasting tokens is fragile.

## Features

- 🔑 **Tokens never leave the Keychain.** Per-account backups are stored as namespaced Keychain items, not plaintext files. Only non-secret metadata (email/org) is written to disk.
- 🔄 **Atomic two-part swap** of Keychain credential + `~/.claude.json` identity.
- ♻️ **Auto-sync on switch.** The outgoing account's stored copy is refreshed before you leave it, so rotated tokens never go stale.
- 🚪 **`login` wrapper.** Drives the real `claude auth login` browser flow, then auto-saves the result under a name.
- 🛡️ **No re-prompt nags.** Updates the live Keychain item *in place* so macOS keeps trusting the `claude` binary.
- 📦 **Zero dependencies.** One self-contained Python 3 file (stdlib only). Nothing to `pip install`.

## Requirements

- **macOS** (uses the login Keychain via the `security` CLI)
- **Python 3** (ships with macOS / Xcode Command Line Tools)
- **Claude Code** installed and on your `PATH` (only needed for the `login` command)

## Install

### One-liner

```bash
git clone https://github.com/vishalmakwana111/claude-auth.git
cd claude-auth
./install.sh
```

The installer copies the script to `~/.local/bin/claude-auth` and checks that directory is on your `PATH`.

### Manual

```bash
cp bin/claude-auth ~/.local/bin/claude-auth
chmod +x ~/.local/bin/claude-auth
# ensure ~/.local/bin is on PATH:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

## Quick start

```bash
# 1. Save the account you're currently logged into
claude-auth add personal

# 2. Sign into another account and save it in one step
claude-auth login work        # opens the browser; saved as "work" when done

# 3. See what you've got
claude-auth list

# 4. Switch any time (no browser needed)
claude-auth switch personal
```

> **Restart Claude Code after switching.** A running session holds the old token in memory; the swap only affects new sessions.

## Commands

| Command | Description |
|---------|-------------|
| `claude-auth login [name]` | Sign in fresh (real OAuth flow), then save the result as a profile. Supports `--email`, `--console`, `--sso`. |
| `claude-auth add [name]` | Save the **currently** logged-in account. Name defaults to the email prefix. `--force` to overwrite. |
| `claude-auth list` / `ls` | List saved accounts. `*` marks the active one. |
| `claude-auth switch [name]` | Switch to a saved account. Interactive picker if no name. `--force`, `--no-save`. |
| `claude-auth usage [name]` | Show rate-limit usage (session + weekly) across accounts. Detail view for one account. |
| `claude-auth current` / `whoami` | Show the active account. |
| `claude-auth rename <old> <new>` | Rename a saved profile (moves its Keychain backup too). |
| `claude-auth remove <name>` / `rm` | Delete a saved profile. `--force` to remove the active one. |

### Flag reference

- `login --email <addr>` — pre-populate the email on the login page
- `login --console` — use Anthropic Console (API billing) instead of the Claude subscription
- `login --sso` — force the SSO login flow
- `switch --no-save` — don't refresh the outgoing account's stored copy before switching
- `switch --force` — switch even if the target is already active

## How it works

```
                         claude-auth switch work
                                   │
            ┌──────────────────────┼──────────────────────┐
            ▼                      ▼                       ▼
   1. refresh outgoing     2. write secrets         3. write identity
      account's backup        into the LIVE slot       into ~/.claude.json
            │                      │                       │
            ▼                      ▼                       ▼
   Keychain:               Keychain:                 ~/.claude.json
   claude-auth-store        "Claude Code-credentials"   oauthAccount + userID
     ├─ personal  ◄─┐         (-U, updated in place        ↑ replaced with
     └─ work        │          so the ACL survives)          work's identity
                    └─ (snapshot of current live)
```

A full deep-dive — storage layout, the in-place-update trick, atomic writes, and the active-account detection — lives in **[ARCHITECTURE.md](ARCHITECTURE.md)**.

## Where things are stored

| Path / item | Purpose | Secret? |
|-------------|---------|---------|
| Keychain `Claude Code-credentials` | The live credential Claude Code reads | yes |
| Keychain `claude-auth-store` (one item per profile) | Per-account credential backups | yes |
| `~/.claude-accounts/accounts.json` (chmod 600) | Non-secret index: names, emails, orgs, expiry | no |
| `~/.claude.json` → `oauthAccount`, `userID` | Live account identity (managed by Claude Code; swapped on switch) | no |

**The `claude-auth` script itself contains zero secrets** — safe to commit, share, and publish. All tokens stay in *your* Keychain on *your* machine.

## Security notes

- Secrets remain in the macOS Keychain, encrypted at rest — never in plaintext config.
- The live Keychain item is **updated in place** (`security add-generic-password -U`), preserving its access-control list so Claude Code isn't re-prompted for Keychain access on every launch.
- `~/.claude.json` is rewritten atomically (temp file + `os.replace`) so an interrupted switch can't corrupt your config.
- Brief caveat: `security ... -w "<secret>"` passes the secret as a CLI argument, so it's momentarily visible to `ps` for *your own user* during the write. Local-only and transient.

## Troubleshooting

**`claude-auth: command not found`** — `~/.local/bin` isn't on your `PATH`. See [Install → Manual](#manual).

**Switch had no effect** — restart Claude Code; running sessions cache the token in memory.

**`stored credential for X is missing from Keychain`** — the backup Keychain item was deleted (e.g. via Keychain Access). Re-create it: switch to that account through `claude auth login`, then `claude-auth add X`.

**macOS prompts for Keychain access** — click *Always Allow*. This should be rare since the tool updates items in place rather than recreating them.

## Limitations

- **macOS only** for now. Linux stores credentials in `~/.claude/.credentials.json` (plaintext) instead of the Keychain; a Linux backend is a natural future addition.
- Switching affects **new** sessions only.

## License

[MIT](LICENSE)

---

<sub>Not affiliated with Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic.</sub>
