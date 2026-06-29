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

### Updating

Once installed, update in place — no need to re-clone:

```bash
claude-auth update          # downloads the latest version and replaces itself
claude-auth update --check  # just tell me if a newer version exists
```

`update` fetches the latest `bin/claude-auth` from GitHub, verifies it parses as valid Python, then atomically swaps it over the running file. Your saved accounts are untouched — they live in the Keychain and `~/.claude-accounts/`, separate from the binary. `claude-auth doctor` also reports when a newer version is available.

> If the binary lives somewhere you can't write to, `update` tells you — just re-run `./install.sh` (or use `sudo`).

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
| `claude-auth autoswitch on/off/status` | Auto-switch to another account when usage gets high. `--threshold`, `--window`, `--strategy`. |
| `claude-auth pool start/stop/status` | Run a local proxy that pools all accounts and auto-fails-over on rate limits — **no restart needed**. `--port`, `--mode`, `--no-wire`. |
| `claude-auth refresh [name]` | Refresh stored tokens of inactive accounts (keeps usage live & backups fresh). |
| `claude-auth statusline` | Compact one-line status (active account + weekly %) for Claude Code's status line. |
| `claude-auth current` / `whoami` | Show the active account. |
| `claude-auth rename <old> <new>` | Rename a saved profile (moves its Keychain backup too). |
| `claude-auth remove <name>` / `rm` | Delete a saved profile. `--force` to remove the active one. |
| `claude-auth doctor` | Health-check the setup: `claude`/PATH/Keychain/hooks/token validity/latest version. |
| `claude-auth update` | Update claude-auth to the latest version from GitHub. `--check` to only check, `--force` to reinstall. |
| `claude-auth completion bash\|zsh` | Output a shell-completion script (tab-complete commands & account names). |
| `claude-auth commands` | Show a grouped cheat sheet of every command, with flags and aliases. |

### Flag reference

- `login --email <addr>` — pre-populate the email on the login page
- `login --console` — use Anthropic Console (API billing) instead of the Claude subscription
- `login --sso` — force the SSO login flow
- `switch --no-save` — don't refresh the outgoing account's stored copy before switching
- `switch --force` — switch even if the target is already active

### Auto-switch when you're running low

Turn on auto-switch and `claude-auth` will move you to a fresher account before you hit a wall:

```console
$ claude-auth autoswitch on --threshold 90 --window session

  ✓ Auto-switch enabled — switch above 90% session usage
  strategy next · checks at most every 120s when Claude is idle
  Stop hook installed in ~/.claude/settings.json
```

How it works:

- It installs a **`Stop` hook** — Claude Code runs it the moment a response finishes and the session goes idle. That's the guarantee that **it never switches while a prompt is running**.
- On each idle check (throttled, default every 120s) it reads the active account's usage. If it's over the threshold, it picks another account with headroom and swaps the credential.
- `--strategy next` rotates round-robin; `--strategy lowest` jumps to the account with the most headroom. `--window` chooses `session` (5-hour) or `week`.
- You get a macOS notification and a log line in `~/.claude-accounts/autoswitch.log`.

> **Important:** switching swaps the on-disk credential — it can't move an *already-running* session to the new account (the token is held in memory). So an auto-switch takes effect on your **next** Claude Code session/restart. The notification reminds you to restart.

Auto-switch installs **two** hooks: a `Stop` hook (idle checkpoint, detached/zero-latency) and a `SessionStart` hook (synchronous **pre-flight** — it tries to switch *before* a new session loads its credentials, so the next session can land on a fresh account automatically).

Check status any time with `claude-auth autoswitch status`, preview a decision with `claude-auth autoswitch run --force --dry-run`, and turn it off with `claude-auth autoswitch off` (which removes both hooks).

### Pool all accounts into one — no restarts: `pool`

`autoswitch` is great, but it has one rough edge: a switch only takes effect on your **next** Claude Code session. `pool` removes that edge entirely.

`claude-auth pool start` launches a tiny **local proxy** (on `127.0.0.1`, your machine only) and points Claude Code at it. From then on, every request Claude Code makes flows through the proxy, which forwards it to the real API using one of your accounts. The moment an account hits its rate limit, the proxy quietly **switches to another account and retries the same request** — mid-conversation, with no switch command and no restart.

```console
$ claude-auth pool start

  › Starting pool on 127.0.0.1:8848 · mode failover
  ✓ Pool is live · Claude Code will use it on next start
  wired ANTHROPIC_BASE_URL into ~/.claude/settings.json
  stop anytime with claude-auth pool stop

$ claude-auth pool status

  Pool   ·   shared multi-account proxy

  ● running   pid 40127 · 127.0.0.1:8848 · mode failover

  personal   ready       served 142 · failovers 0
  work       resting 24s served 38 · failovers 1

  ✓ wired into settings.json
```

**Why it can switch without a restart** (and why it's not a hack): the Messages API is *stateless* — Claude Code resends the whole conversation on every turn, so there is no server-side session to "move." The proxy is just a load-balancer over independent requests, so any account can serve any turn. That's the one thing a credential-on-disk swap can't do.

Two modes:

- `--mode failover` (default) — keep using your current account until it's actually rate-limited, then fail over. This is the safe, conservative choice: it behaves exactly like `autoswitch`, just instantly and without a restart.
- `--mode balance` — spread requests across all accounts every turn, keeping them all warm.

Turn it off with `claude-auth pool stop` — it shuts the proxy down and restores your `settings.json` (then restart Claude Code).

> **⚠️ Heads-up on Anthropic's terms.** `failover` mode uses one account at a time — the same as switching manually, just automated. `balance` mode draws on several subscription accounts to serve one workflow, which may run against Anthropic's subscription terms (around getting around rate limits). Use your own accounts, and use `balance` knowing that. When in doubt, stick with `failover`.

> **Note:** `pool` works by setting `ANTHROPIC_BASE_URL` so Claude Code routes through the local proxy. If a future Claude Code version stops honoring that for subscription logins, the pool simply won't receive traffic (and `pool status` / `doctor` will tell you) — it can't break your normal setup, because `pool stop` always restores `settings.json`.

### Keep every account's usage live: `refresh`

A saved account's access token is short-lived (~hours), so an account you haven't touched in a while can show a stale snapshot. `claude-auth refresh` exchanges each inactive account's refresh token for a fresh one (Anthropic's `POST /v1/oauth/token`), so `usage` stays live and switching never lands on a dead token. It only touches **inactive** accounts — the active one is owned by Claude Code and left alone. `usage` also auto-refreshes an account's token on demand if it returns expired.

### Status line

`claude-auth statusline` prints a compact, network-free segment from cached usage — ideal for Claude Code's status line:

```
● work · wk 57% · ↺ Jun 25 3:29am
```

Wire it into `~/.claude/settings.json`:

```jsonc
"statusLine": { "type": "command", "command": "claude-auth statusline" }
```

…or append it to your existing status-line script. It reads the cached snapshot (instant), and opportunistically kicks off a background usage refresh when the cache is older than 5 minutes, so it stays current without ever blocking a render.

### Shell completion

Tab-complete commands *and* account names:

```bash
# zsh — add to ~/.zshrc:
eval "$(claude-auth completion zsh)"
# bash — add to ~/.bashrc:
eval "$(claude-auth completion bash)"
```

```console
$ claude-auth switch <TAB>
personal   work
$ claude-auth usage wo<TAB>      # → work
```

### Health check

`claude-auth doctor` verifies the whole setup in one shot:

```console
$ claude-auth doctor

  Doctor   ·   checking your setup

  ✓ macOS
  ✓ claude CLI   2.1.187 (Claude Code)
  ✓ claude-auth on PATH   /Users/you/.local/bin/claude-auth
  ✓ Keychain access   live credential present
  ✓ 2 account(s) saved
  ✓ active account   personal
  ✓ autoswitch   Stop + SessionStart hooks present

  accounts:
  ✓ personal   active (managed live by Claude Code)
  ✓ work       token valid

  ● 9 ok
```

It catches the common gotchas — `claude` not on PATH, missing/partial auto-switch hooks, stale tokens, an active login that isn't saved.

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
- `switch` / `autoswitch` affect **new** sessions only (a running session caches its token in memory). If you want switching to take effect *inside* a running session, use `claude-auth pool` instead — it routes per-request, so there's nothing to restart.

## 🐈 One more thing

Run `claude-auth` (or `claude-auth --help`) in a real terminal and a little cat walks the full width of your CLI — in the clay gradient — and stops at the right edge with a trailing `meow~ ♪`, just above the wordmark. It's purely cosmetic: it's skipped when output is piped, and you can turn it off with `CLAUDE_AUTH_NO_ANIM=1`.

```
                                              meow~ ♪ /\_/\
                                                      ( ^.^ )
                                                       > ^ <
```

## License

[MIT](LICENSE)

---

<sub>Not affiliated with Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic.</sub>
