# colincode

A coding agent in a tenki.cloud box, one command away — with auto-resume and
your choice of inference provider.

```bash
colin               # pick an agent (or create one) and jump into it
colin claude        # your Claude Code agent, reachable from claude.ai/code
colin codex         # Codex
colin opencode      # opencode
```

The command is `colin`. The project is `colincode`. Install:

```bash
curl -fsSL https://colincode.org/install.sh | sh
```

## Why this exists

The tenki CLI already has every primitive (`create`, `ssh`, `resume`, `exec`),
and the tenki base image already ships Claude Code, Codex and opencode. What it
lacks is the glue:

- no single command that does create-or-resume → wait → launch the agent → attach
- **nothing auto-resumes a paused box** — every command just fails against one
- no way to point an agent at a different inference provider without editing
  config files inside the box

Every `colin` command routes through `ensure_running()`, which creates a
missing box, resumes a paused one, and waits out a pending one. A paused box
costs you a few seconds instead of an error.

## Agents

An **agent** is a name plus a harness, an inference provider and a model. Each
agent gets its own sticky sandbox named after it. `colin` with no arguments
shows your agents in an arrow-key menu, plus "new agent", which walks through:

1. **Harness** — `claude`, `codex` or `opencode`
2. **Provider** — the harness default, or one of the providers below
3. **Model** — the provider's recommended coding models, or type an id
4. **Name** — leave empty for `<provider>-<harness>`, e.g. `anthropic-claude`,
   `nebius-codex`, `openrouter-opencode`

`colin <harness>` picks your only agent for that harness, offers a menu if you
have several, or starts the creation flow if you have none. `colin <name>`
targets a specific agent. Agents live in `~/.config/colincode/agents/`.

## Usage

```
colin                        pick an agent (or create one) and jump into it
colin new [harness]          create an agent: harness → provider → model → name
colin <harness> [action]     harness: claude | codex | opencode
colin <agent> [action]       a specific agent by name

up        (default)  create or resume the box, start the agent, attach
ssh                  same as up (attach to the running agent)
shell                plain shell in the box
run -- <prompt>      one-shot headless prompt
status               agent, provider, box state
provider             switch inference provider (and model)
model [id]           switch model
auth                 sign in / store the provider key
down                 pause the box (auto-resumed next time)
rm                   terminate the box and forget the agent

colin ls                     list agents and their boxes
```

All three harnesses run inside **tmux**, so they survive SSH disconnects and
sandbox pauses. `colin <agent>` attaches you to that session every time; detach
with Ctrl-b d and the agent keeps running.

## Harnesses

| Harness | Interactive | Headless | Default provider | Sign-in |
|---|---|---|---|---|
| `claude` | `claude --remote-control <agent>` | `claude -p` | Anthropic | `claude auth login` inside the box (`colin <agent> auth`) |
| `codex` | `codex` | `codex exec` | OpenAI | `codex login` inside the box, or `OPENAI_API_KEY` |
| `opencode` | `opencode` | `opencode run` | opencode | configure inside opencode, or `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` |

**Only Claude Code has Remote Control**, so only a `claude` agent on the
Anthropic provider shows up at claude.ai/code and in the mobile app. Remote
Control needs a full-scope login made with `claude auth login` *inside the box*;
long-lived tokens from `claude setup-token` and API keys are inference-only and
Claude Code refuses Remote Control with them. The first `colin claude` opens
that sign-in over SSH (it prints a URL, you paste a code back). The login is
stored under `$HOME` in the box and survives pauses.

## Inference providers

| Provider | `claude` | `codex` | `opencode` | Key | Default model |
|---|---|---|---|---|---|
| Anthropic / OpenAI / opencode | harness default | | | sign in | harness default |
| [Nebius Token Factory](https://tokenfactory.nebius.com) | ✓ (via proxy) | ✓ | ✓ | `NEBIUS_API_KEY` | `moonshotai/Kimi-K3` |
| [Boundless](https://inference.boundless.network) | ✓ | ✓ | ✓ | `BOUNDLESS_API_KEY` | `claude-fable-5.1` |
| [Baseten](https://www.baseten.co) | ✓ (beta) | ✓ | ✓ | `BASETEN_API_KEY` | `moonshotai/Kimi-K3` |
| [Friendli](https://friendli.ai) | ✓ | ✓ | ✓ | `FRIENDLI_TOKEN` | `zai-org/GLM-5.3` |
| [OpenRouter](https://openrouter.ai) | ✓ | ✓ | ✓ | `OPENROUTER_API_KEY` | `anthropic/claude-fable-5.1` |

Defaults are the most advanced model each provider serves (by its own pricing).
The model menu shows about ten recommended models first, then every model the
provider's `/v1/models` endpoint returns (cached for an hour); type to filter,
or pick "other" and enter any id.

How each harness is wired, with nothing written to the agent's own config:

- **Claude Code** gets `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN` and the
  model in `ANTHROPIC_MODEL` and the `ANTHROPIC_DEFAULT_*_MODEL` slots. Any
  third-party base URL disables Remote Control — the menu says so. Providers
  with no Anthropic Messages API (Nebius) get a **translation proxy in the
  box**: a stdlib-only Python script embedded in `colin`, written next to
  `agent.env`, run in a second tmux session (`claude-proxy`) on
  `127.0.0.1:8787`, serving `/v1/messages` (streaming and tool calls included)
  in front of the provider's `/chat/completions`. Claude Code is pointed at it.
  The proxy restarts with the agent on a provider or model change and is
  brought back by `colin <agent>` if it died. Debug it with `colin <agent>
  shell`, then `tmux attach -t claude-proxy`. `COLINCODE_PROXY_PORT` moves it.
- **Codex** gets a `model_provider` on the command line (`-c` flags) with
  `wire_api = "responses"`, which is the only wire API Codex accepts for custom
  providers; all providers above expose a Responses endpoint.
- **opencode** gets `OPENCODE_CONFIG_CONTENT` selecting `<provider>/<model>`
  from its built-in catalog.

Provider keys are asked for once (hidden input) and kept in
`~/.config/colincode/env` (mode 0600); the environment wins if the variable is
already set. At every `colin <agent>` the provider settings are written into the
box as `~/.config/colincode/agent.env` (0600, sent over ssh stdin, never on a
command line) and sourced by the tmux launch. Changing provider or model just
restarts the agent — no `rm` needed.


## Configuration

| Variable | Default | Meaning |
|---|---|---|
| `COLINCODE_HARNESS` | `claude` | harness used when you omit one |
| `COLINCODE_CPU` | `4` | vCPU cores |
| `COLINCODE_MEMORY_MB` | `8192` | memory |
| `COLINCODE_DISK_GB` | `20` | root disk (tenki recommends 20 for agents) |
| `COLINCODE_IMAGE` | _(none)_ | start from a published registry image |
| `COLINCODE_RESUME_TIMEOUT` | `3m` | how long to wait for a resume |

## Caveats

- **Pausing clears `/tmp` and drops TCP connections.** Keep work in `$HOME` or an
  attached volume. tmux survives; anything in `/tmp` does not.
- Native `codex` / `opencode` credentials from `~/.config/colincode/env` are
  injected **at create time only** and stored in plaintext session metadata;
  to rotate them, `rm` then `up`. Provider keys for the other providers are
  re-sent on every `up`, so rotating those is just editing the env file.
- `run` is headless and skips approval prompts.
- Boxes created by older versions (`colincode-<harness>`) are adopted as agents
  automatically.
