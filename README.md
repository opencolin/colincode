# luxcode

A coding agent in a Luxor sandbox, one command away. Run Claude Code, Codex or
any of 26 coding agents in a box of their own: one command makes the box,
starts the agent and drops you in. Close the laptop and it keeps working. Pick
it up again from your phone. Let it run with approvals off, in a box that is
nobody's machine.

```bash
lux               # pick an agent (or create one) and jump into it
lux claude        # your Claude Code agent, reachable from claude.ai/code
lux codex         # Codex
lux crush         # or copilot, gemini, qwen, goose, kimi, omp, adal, hermes, openclaw
lux opencode-web  # a web UI instead: opencode-web, open-webui, hermes-web, openclaw-web, durable-pi
lux grok          # a box from a Luxor image: grok, amp, droid, pi, prime-agent, tinyfish, anchor, hotdata
```

Install (macOS and Linux; needs the [Luxor CLI](https://tenki.cloud/docs/cli)
and jq):

```bash
curl -fsSL https://luxcode.org/install.sh | sh
tenki login
lux
```

One bash script. The command is `lux`; the Luxor CLI it drives is still the
`tenki` command (Luxor is tenki.cloud's new name). The same script is also
published as **colincode**: `curl -fsSL https://colincode.org/install.sh | sh`
installs it as `colin`, with its config in `~/.config/colincode` and
`COLINCODE_*` in place of `LUX_*`. The command's own name picks the brand;
`build-site.sh` renders the site for either.

The harnesses come from [agentcamp](https://github.com/opencolin/agentcamp)
(fifteen terminal agents and five web UIs) plus Luxor's eight pre-built images
(Grok Build, Amp, Droid, Pi, Prime Agent, TinyFish, Anchor, Hotdata).

## Why this exists

The Luxor CLI (still the `tenki` command; Luxor is tenki.cloud's new name)
already has every primitive (`create`, `ssh`, `resume`, `exec`),
and the Luxor base image already ships Claude Code, Codex and opencode. What it
lacks is the glue:

- no single command that does create-or-resume → wait → launch the agent → attach
- **nothing auto-resumes a paused box** — every command just fails against one
- no way to point an agent at a different inference provider without editing
  config files inside the box

You never create or resume a box by hand. Run any `lux` command and the box
is simply there: made if it does not exist yet, woken if it was paused, waited
for if it is still starting. A paused box costs you a few seconds, not an error.

## Agents

An **agent** is a name plus a harness, an inference provider and a model. Each
agent gets its own sandbox named after it. `lux` with no arguments
shows your agents in an arrow-key menu, plus "new agent", which walks through:

1. **Terminal or web** — a terminal agent in tmux that you attach to over
   ssh, or a web UI served from the box and tunnelled to your browser
2. **Harness** — one of the terminal agents, Luxor's pre-built images, or
   the web UIs below
3. **Provider** — the harness default (its own sign-in or in-app setup), or
   one of the providers below
4. **Model** — the provider's recommended coding models, or type an id
5. **Size** — small 2 vCPU/4 GiB · medium 4/8 (default) · large 8/16 ·
   xlarge 12/32 · xxlarge 16/64
6. **Volume** — a persistent volume (10/25/50 GiB, or none; Luxor workspaces cap volumes, 50 GiB on ours) mounted at
   `~/work`. The agent starts there. It survives pause, `rm` and a box resize;
   the root disk does not.
7. **Name** — leave empty for the harness name on its default provider
   (`claude`, `opencode-web`, `tinyfish`), or `<provider>-<harness>` on a
   third-party one (`nebius-crush`, `openrouter-opencode-web`)

`lux <harness>` picks your only agent for that harness, offers a menu if you
have several, or starts the creation flow if you have none. `lux <name>`
targets a specific agent. Agents live in `~/.config/luxcode/agents/`.

## Usage

```
lux                        pick an agent (or create one) and jump into it
lux new [cli|web|harness]  create an agent: terminal or web → harness → provider → model → size → volume → name
lux <harness> [action]     a harness (see Harnesses): your agent for it, or a new one
lux <agent> [action]       a specific agent by name

up        (default)  create or resume the box, start the agent, attach
ssh                  same as up (attach to the running agent)
shell                plain shell in the box
run -- <prompt>      one-shot headless prompt
status               agent, provider, box state
provider             switch inference provider (and model)
model [id]           switch model
size [name]          box size; applies when the box is (re)created
volume [GiB|none]    add or drop the persistent volume at ~/work
url [off]            a public Luxor link: the web UI, or a browser terminal on a terminal agent
                     (anyone with the link gets in — share it like a password); off removes it
auth                 sign in / store or replace the provider key
down | pause         pause the box (auto-resumed next time)
rm | stop | kill     terminate the box; the volume is kept and `lux <name>` brings the agent
                     back on it (rm --purge deletes the volume too)

lux image [build [--full]] the golden image new boxes start from (see Golden image)
lux ls                     list agents and their boxes, and kept volumes
lux volumes                every volume: which agent is on it, kept ones, strays
lux volumes rm <name|id>   delete a volume for good (confirmed by name)
lux pause --all            pause every agent's box
lux rm --all               terminate every box and forget every agent
```

All three harnesses run inside **tmux**, so they survive SSH disconnects and
sandbox pauses. `lux <agent>` attaches you to that session every time; detach
with Ctrl-b d and the agent keeps running.

## Harnesses

The set agentcamp runs in its sandboxes, plus Luxor's own pre-built images.
Claude Code, Codex and opencode come with Luxor's base image; the others are
installed into the box on first use (a minute or two, once per box), except
the two image harnesses, whose box is created from that image.

Terminal harnesses run inside **tmux**, so they survive SSH disconnects and
sandbox pauses. `lux <agent>` attaches you to that session every time;
detach with Ctrl-b d and the agent keeps running.

| Harness | Command | Default provider | Headless `run` | Other providers |
|---|---|---|---|---|
| `claude` | Claude Code | Anthropic (`claude auth login` in the box, Remote Control) | `claude -p` | env (Anthropic API or proxy) |
| `codex` | Codex CLI | OpenAI (`codex login` in the box) | `codex exec` | `-c` flags |
| `opencode` | opencode | opencode (configure inside) | `opencode run` | env |
| `copilot` | GitHub Copilot CLI | GitHub (`/login` inside, Copilot plan) | `copilot -p` | env (its own-model settings) |
| `gemini` | Gemini CLI | Google (sign in inside) | `gemini -p` | — (speaks only Google's API) |
| `qwen` | Qwen Code | Qwen OAuth inside | `qwen -p` | injector |
| `crush` | Crush (Charm) | configure inside | `crush run` | injector |
| `goose` | Goose (Block) | `goose configure` inside | `goose run -t` | injector |
| `kimi` | Kimi Code CLI | Moonshot (`kimi login` inside) | — | injector |
| `pi` | Pi, from Luxor's `tenki/pi` image | `/login` inside (subscriptions) | `pi -p` | injector |
| `omp` | oh-my-pi | configure inside | `omp -p` | injector |
| `droid` | Droid, from Luxor's `tenki/droid` image | `FACTORY_API_KEY`, or sign in inside | `droid exec` | injector (added to `/model`) |
| `adal` | AdaL | AdaL account / ChatGPT subscription | — | — |
| `hermes` | Hermes (Nous) | `hermes setup` inside | — | injector |
| `openclaw` | OpenClaw (`openclaw chat`) | `openclaw onboard` inside | — | injector |
| `grok` | Grok Build, from Luxor's `tenki/grok` image | xAI (`XAI_API_KEY`, or `grok login --device-auth` inside) | `grok -p` | — |
| `amp` | Amp, from Luxor's `tenki/amp` image | Amp (`AMP_API_KEY`, or `amp login` inside) | `amp -x` | — |
| `prime-agent` | Prime Agent, from Luxor's `tenki/prime-agent` image | Prime Intellect (`PRIME_API_KEY`, or log in inside) | `prime-agent -p` | — (other providers' keys in the box env) |
| `tinyfish` | TinyFish toolkit, from Luxor's `tenki/tinyfish` image | TinyFish (`TINYFISH_API_KEY`) | `tinyfish …` (raw args) | — |
| `anchor` | Anchor Browser toolkit, from Luxor's `tenki/anchor` image | Anchor (`ANCHOR_API_KEY`) | — (a shell; `playwright-core`, `anchor-smoke`) | — |
| `hotdata` | Hotdata toolkit, from Luxor's `tenki/hotdata` image | Hotdata (`HOTDATA_API_KEY`) | `hotdata …` (raw args) | — |

The entries "from Luxor's image" are **Luxor's pre-built images**
([docs](https://tenki.cloud/docs/sandbox/base-image)) rather than programs
installed into the base box: the agent's box is created from that image, so
they sit in the same menu as the other harnesses. Where the image's agent
also has a device-code or browser login, the key can be left empty at
creation and the sign-in done inside. The toolkits (`tinyfish`, `anchor`,
`hotdata`) open a shell in the box with the key set; `lux tinyfish run --
fetch content get https://…` runs the CLI directly. `LUX_IMAGE` still
sets a custom image for every other harness.

**Web UIs** are a server started in the box (in tmux, like a terminal agent)
and reached through an ssh tunnel: `lux <agent>` forwards the box port to
`localhost`, opens your browser on it and holds the tunnel until Ctrl-C; the
UI keeps running. Nothing is exposed to the internet unless you ask:
`lux <agent> url` binds a Luxor preview URL to the port, a sticky public link
with no password of its own (OpenClaw's UI takes a token, which the link
carries), and `url off` removes it.

| Web UI | Port | Default provider | Other providers |
|---|---|---|---|
| `opencode-web` | 8086 | opencode (configure inside) | env, like `opencode` |
| `open-webui` | 8083 | configure a connection inside | env (`OPENAI_API_BASE_URL`), single user, no login screen |
| `hermes-web` | 8088 | `hermes setup` inside | injector |
| `openclaw-web` | 8087 | `openclaw onboard` inside | injector; a per-agent gateway token in the link |
| `durable-pi` | 8092 | pi's `/login` | injector (pi's config); sessions kept in `~/work/.durable-pi` |

"Injector" means agentcamp's `inject-provider.sh`, fetched from agentcamp.dev
into the box and run for that one harness: it merges the provider's base URL,
key and model into the CLI's own config file (the provider shows up as
`lux` in its pickers) and switches the CLI to its no-approval mode, as the
agentcamp sandboxes do — the box is yours alone. `LUX_INJECT_URL` points
it elsewhere. Claude Code, Codex, opencode, Copilot and Open WebUI are wired
through environment variables instead, with nothing written to their config.

**Only Claude Code has Remote Control**, so only a `claude` agent on the
Anthropic provider shows up at claude.ai/code and in the mobile app. Remote
Control needs a full-scope login made with `claude auth login` *inside the box*;
long-lived tokens from `claude setup-token` and API keys are inference-only and
Claude Code refuses Remote Control with them. The first `lux claude` opens
that sign-in over SSH (it prints a URL, you paste a code back). The login is
stored under `$HOME` in the box and survives pauses.

## Inference providers

Every provider below works with every harness that takes a custom endpoint
(the two tables above); the columns show the three original harnesses.

| Provider | `claude` | `codex` | `opencode` | Key | Default model |
|---|---|---|---|---|---|
| each harness's default | its own sign-in or key (see the harness tables above) | | | — | its own |
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
  box**: a stdlib-only Python script embedded in `lux`, written next to
  `agent.env`, run in a second tmux session (`claude-proxy`) on
  `127.0.0.1:8787`, serving `/v1/messages` (streaming and tool calls included)
  in front of the provider's `/chat/completions`. Claude Code is pointed at it.
  The proxy restarts with the agent on a provider or model change and is
  brought back by `lux <agent>` if it died. Debug it with `lux <agent>
  shell`, then `tmux attach -t claude-proxy`. `LUX_PROXY_PORT` moves it.
- **Codex** gets a `model_provider` on the command line (`-c` flags) with
  `wire_api = "responses"`, which is the only wire API Codex accepts for custom
  providers; all providers above expose a Responses endpoint.
- **opencode** gets `OPENCODE_CONFIG_CONTENT` selecting `<provider>/<model>`
  from its built-in catalog.

Provider keys are asked for once (hidden input) and kept in
`~/.config/luxcode/env` (mode 0600); the environment wins if the variable is
already set. At every `lux <agent>` the provider settings are written into the
box as `~/.config/luxcode/agent.env` (0600, sent over ssh stdin, never on a
command line) and sourced by the tmux launch. Changing provider or model just
restarts the agent — no `rm` needed.


## Configuration

Settings live in `~/.config/luxcode/env` (`~/.config/luxcode/env` for `lux`),
next to the provider keys. `lux config` shows every setting and key with where
its value comes from; `lux config size large` saves a default (the same names
as the variables below, prefix optional); `lux config unset size` drops it;
`lux config edit` opens the file. A variable set in the environment wins for
that one run. `lux auth nebius` stores or replaces a provider key (Enter keeps
the current one); `lux <agent> auth` does the same for that agent's provider,
or runs the harness's own sign-in.

| Variable | Default | Meaning |
|---|---|---|
| `LUX_HARNESS` | `claude` | harness used when you omit one |
| `LUX_SIZE` | `medium` | default box size offered (`small` … `xxlarge`) |
| `LUX_CPU` / `LUX_MEMORY_MB` | `4` / `8192` | an exact default instead of a preset |
| `LUX_VOLUME_GB` | `10` | default volume size offered (`0` = none) |
| `LUX_DISK_GB` | `20` | root disk (Luxor recommends 20 for agents) |
| `LUX_IMAGE` | _(none)_ | force one registry image for every harness without its own |
| `LUX_BASE_IMAGE` | `03q08p/colincode-base:stable` | the published golden image looked for on first use |
| `LUX_RESUME_TIMEOUT` | `3m` | how long to wait for a resume |
| `LUX_MAX_DURATION` | `2h` | a box pauses this long after each create or resume, whatever it is doing (Luxor caps it at 2h) |
| `LUX_PAUSE_RETENTION` | `720h` | how long Luxor keeps a paused box |
| `LUX_STICKY` | `0` | `1` creates sticky boxes that never pause by themselves |

## Golden image

Luxor's base image has no tmux, so a fresh box used to spend its first seconds
on apt. Boxes without an image of their own now start from a **golden image**:
Luxor's base plus tmux (and python3 and curl for the Claude proxy). The first
`lux` that creates a box looks for the published one, `03q08p/colincode-base:stable`,
and remembers it in `~/.config/luxcode/image`; a workspace that cannot see
it builds its own on the spot (a temporary 2 vCPU box, apt, snapshot, publish
to that workspace's registry, about a minute, once). The harnesses from Luxor's
own images (pi, droid, grok, amp, prime-agent, tinyfish, anchor, hotdata) keep
theirs.

```
lux image                  which image is in use, and whether it still resolves
lux image build            build and publish a fresh one in your workspace
lux image build --full     also preinstall copilot, gemini, qwen, crush, goose, kimi, omp, hermes, openclaw
lux image build --public   publish it for every workspace (how the default one is made)
lux image forget           go back to Luxor's base image (the registry image is kept)
```

`LUX_BASE_IMAGE` names a different published image to look for;
`LUX_IMAGE` forces one image for every harness without its own.

## Pausing

Boxes are not sticky. Luxor pauses one two hours after it was created or last
resumed (the workspace cap on `--max-duration`; `LUX_MAX_DURATION` can
only lower it). The Luxor CLI has no idle-timeout flag, and a box created
without one does not pause for being idle, so the timer is the pause. `lux <agent>
down` pauses it now. Every `lux` command resumes a paused box first, so a
pause costs a few seconds, not an error, and the timer starts again from the
resume. tmux and the agent's session survive it; `/tmp` and open TCP
connections do not, so an agent paused mid-request retries when the box is
back. For a job that must run unattended for longer than that, create the
agent with `LUX_STICKY=1`: a sticky box never pauses by itself. Boxes
made by earlier versions are sticky and stay that way; `status` says so, and
`rm` then `lux <agent>` recreates one that pauses (the volume is kept).

## Caveats

- **Pausing clears `/tmp` and drops TCP connections.** Keep work in `~/work`
  (the volume) or `$HOME`. tmux survives; anything in `/tmp` does not.
- **Luxor boxes can't be resized in place and volumes keep their size for
  life.** `size` takes effect on the next create (`rm`, then `up`; the volume
  is kept and reattached). To change a volume's size, `volume none` deletes
  it, then `volume <GiB>` makes a new one.
- Native `codex` / `opencode` credentials from `~/.config/luxcode/env` are
  injected **at create time only** and stored in plaintext session metadata;
  to rotate them, `rm` then `up`. Provider keys for the other providers are
  re-sent on every `up`, so rotating those is just editing the env file.
- `run` is headless and skips approval prompts.
- Boxes created by older versions (`luxcode-<harness>`) are adopted as agents
  automatically.
