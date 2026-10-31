# colincode

A coding-agent box on tenki.cloud, one command away — with auto-resume.

```bash
colin claude        # Claude Code in a sandbox, reachable from claude.ai/code
colin opencode      # same box treatment, opencode
colin codex         # ...and Codex
```

The command is `colin`. The project is `colincode`.

## Why this exists

The tenki CLI already has every primitive (`create`, `ssh`, `resume`, `exec`),
and the tenki base image already ships Claude Code, opencode, and Codex. What it
lacks is the glue:

- no single command that does create-or-resume → wait → launch the agent
- **nothing auto-resumes a paused box** — every command just fails against one

Every `colin` subcommand routes through `ensure_running()`, which creates a
missing box, resumes a paused one, and waits out a pending one. A paused box
costs you a few seconds instead of an error and a manual `tenki sandbox resume`.

## Usage

```
colin <harness> [action]     harness: claude | opencode | codex
colin <action>               uses the default harness (claude)

up        (default)  create or resume the box and start the agent
ssh                  attach to the running agent session
shell                plain shell in the box
run -- <prompt>      one-shot headless prompt
status               show box state
down                 pause the box (auto-resumed next time)
rm                   terminate the box

colin auth [harness]         sign in (claude: inside the box)
colin ls                     list every colincode box
```

Each harness gets its own sandbox, named `colincode-<harness>`, created
`--sticky` so it is not reaped by a max-duration timer. They are independent —
`colin claude down` does not touch your codex box.

## Harnesses

| Harness | Interactive | Headless | Credentials |
|---|---|---|---|
| `claude` | `claude --remote-control <box>` | `claude -p` | `claude auth login` inside the box (`colin claude auth`) |
| `opencode` | `opencode` | `opencode run` | `ANTHROPIC_API_KEY` and/or `OPENAI_API_KEY` |
| `codex` | `codex` | `codex exec` | `OPENAI_API_KEY` |

All three run inside **tmux**, so they survive SSH disconnects and sandbox
pauses. Reattach with `colin <harness> ssh`.

**Only Claude Code has Remote Control**, so only `colin claude` gives you a
session you can drive from claude.ai/code or the mobile app. For opencode and
codex, SSH is the way in.

**Claude Code signs in inside the box.** Remote Control requires a full-scope
login made with `claude auth login`; long-lived tokens from `claude setup-token`
(`CLAUDE_CODE_OAUTH_TOKEN`) and API keys are inference-only and Claude Code
refuses Remote Control with them. So `colin` injects nothing for the `claude`
harness. The first `colin claude` (or `colin claude auth`) opens the sign-in
over SSH: it prints a URL, you sign in on any device, and paste the code back.
The login is stored under `$HOME` in the box and survives pauses. Any stale
token in the box environment is unset at launch so it cannot shadow the login.

For `opencode` and `codex`, credentials are read from the environment first,
then `~/.config/colincode/env` (mode 0600), and injected at create time. You
can skip `colin auth` and sign in inside the box instead — `colin codex shell`,
then `codex login`.

## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `COLINCODE_HARNESS` | `claude` | harness used when you omit one |
| `COLINCODE_CPU` | `4` | vCPU cores |
| `COLINCODE_MEMORY_MB` | `8192` | memory |
| `COLINCODE_DISK_GB` | `20` | root disk (tenki recommends 20 for agents) |
| `COLINCODE_IMAGE` | _(none)_ | start from a published registry image |

## Caveats

- **Pausing clears `/tmp` and drops TCP connections.** Keep work in `$HOME` or an
  attached volume. tmux survives; anything in `/tmp` does not.
- `--env` values are stored in plaintext session metadata, and credentials are
  injected **at create time only** (opencode, codex). To rotate: `colin <harness> rm`,
  then `up`. The `claude` login lives in the box's `$HOME`; rotate it with
  `colin claude shell`, then `claude auth logout` and `colin claude auth`.
- `run` is headless and skips approval prompts.
- Harness install commands are a fallback for custom images; on the stock tenki
  image all three are already present.
