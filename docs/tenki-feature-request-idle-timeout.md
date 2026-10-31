# Feature request: idle auto-pause for sandboxes (`--idle-timeout`)

**To:** tenki.cloud sandbox team
**From:** colincode (`colin`, the coding-agent-in-a-box wrapper around the tenki CLI)
**tenki CLI:** v2.8.0 · **SDK:** `@tenkicloud/sandbox` 1.4.1 · **Date:** 2026-10-31

## Summary

Add an idle timeout to sandbox sessions: when a sandbox has seen no activity for
N minutes, pause it (not terminate it), exactly as `--max-duration` expiry
pauses a non-sticky session today. Expose it as `--idle-timeout` on
`tenki sandbox create` and `tenki sandbox update`, and un-deprecate
`idleTimeoutMinutes` in the SDK so the two surfaces agree.

Today the only automatic pause is the wall-clock `--max-duration`, which the
workspace caps at 2h. A box that is being used gets paused mid-work every two
hours; a box that was abandoned keeps running for up to two hours. An idle
timeout fixes both ends.

## Who needs it

`colin` runs a long-lived interactive coding agent (Claude Code, Codex,
opencode) in a sandbox and attaches the user to it over SSH in tmux. The
pattern is "work for a while, walk away, come back tomorrow". Sessions are
resumed on the next command, so a pause is cheap for the user. What matters is
that the box pauses soon after the user leaves and *not* while they are
typing. Every hosted-agent product on tenki (agentcamp included) has the same
shape.

## What we observed

All tests on fresh sandboxes created with the CLI, 2026-10-30/31.

| Setup | Expected | Observed |
|---|---|---|
| non-sticky, `--max-duration 1h` | pause at expiry | `RUNNING → PAUSING → PAUSED` at `timeout_at`. Good. |
| resume a box paused by expiry | timer restarts | timer restarts with the same max duration. Good. |
| `--max-duration 24h` | 24h | capped to 2h, warning `MAX_DURATION_CAPPED` |
| non-sticky, no max-duration flag | some idle pause | `idle_timeout_minutes: null`; polled every 2 min for 32 min with nothing attached: still `RUNNING` |
| `--sticky` | run until terminated | as documented |
| SDK box with `idle_timeout_minutes: 5` (`agentcamp-v-g33fy4`) | pause after 5 idle min | `RUNNING`; README 1.4.1 says the field is "deprecated and ignored: sandboxes do not auto-pause on idle" |

So the field exists in the API response and was once a feature, but nothing
honours it, and the CLI never had a flag for it:

```
$ tenki sandbox create --help | grep -iE 'idle|sticky|max-duration|pause-retention'
   --max-duration duration     Max session duration (for example 30m) (default: 0s)
   --sticky                    Run until terminated, discarding --max-duration (default: false)
   --pause-retention duration  How long paused state is retained before cleanup (for example 168h) (default: 0s)
```

## Why `--max-duration` is not a substitute

- **It pauses active sessions.** A user who has been typing for 1h59m gets
  paused in the middle of a command. The agent survives in tmux, but open TCP
  connections and `/tmp` do not, so an in-flight model request fails and
  retries.
- **It cannot be long.** The 2h cap means a box has to be babysat; `colin`
  works around it by resuming on every command, but a job that must run
  unattended for 3h needs `--sticky`, which then never pauses at all.
- **It wastes the gap.** A box abandoned one minute after a resume runs for
  another 119 minutes before pausing. With a 10-minute idle timeout that is
  10 minutes.
- **Clients cannot emulate it well.** A wrapper could `tenki sandbox pause`
  from a local watchdog, but the client is not always running (laptop asleep,
  mobile Remote Control session), and only the host knows whether the sandbox
  is actually idle.

## Proposed surface

### CLI

```
tenki sandbox create --idle-timeout 15m ...
tenki sandbox update <id> --idle-timeout 15m
tenki sandbox update <id> --no-idle-timeout
```

- `duration` syntax like the other flags (`30m`, `2h`). `0s` / absent = no idle
  pause (today's behaviour), so nothing changes for existing scripts.
- Shown in `tenki sandbox get` as the existing `idle_timeout_minutes` field,
  plus an `idle_since` (or `last_activity_at`) timestamp so clients can
  display "pauses in 7 min".
- Composable with `--max-duration` (whichever fires first) and overridden by
  `--sticky` the same way max-duration is, with a `STICKY_OVERRIDES_IDLE_TIMEOUT`
  warning.
- A workspace cap, if any, reported like `MAX_DURATION_CAPPED`.

### SDK / API

- Un-deprecate `idleTimeoutMinutes` on `create` and add it to `update`; keep
  the field name so existing callers start working without a code change.
- Same warning code when combined with `sticky: true`.

### What counts as activity

The definition is the host's call, but for this use case these should all
reset the idle clock:

1. an open SSH connection or `tenki sandbox exec` (interactive use)
2. any process in the sandbox doing non-trivial CPU or network I/O over the
   last minute (an agent running a build or waiting on a model response)

and these should **not**: a sleeping tmux server, the sandbox agent's own
heartbeat, an idle shell prompt. A CPU/network threshold with a short grace
window (as CI runners and Codespaces do) is enough; perfect accuracy is not
needed because pause is cheap and the client resumes.

### Pause, not terminate

On idle expiry the session goes to `PAUSED` and follows `--pause-retention`,
identical to max-duration expiry. `resume` clears the idle clock. Manual
`pause`/`resume` behave as today.

## Acceptance test (what we would run)

```
tenki sandbox create --name idle-test --idle-timeout 5m --pause-retention 24h
# nothing attached → PAUSED within ~6 min
tenki sandbox resume idle-test && tenki sandbox ssh idle-test   # hold a shell open 10 min
# still RUNNING while the shell is open
# exit the shell → PAUSED within ~6 min
tenki sandbox create --name sticky-test --sticky --idle-timeout 5m
# warning STICKY_OVERRIDES_IDLE_TIMEOUT, never pauses
tenki sandbox create --name both-test --idle-timeout 5m --max-duration 1h
# busy loop in the box → paused at 1h, not before
```

## What colincode does meanwhile

`colin` creates non-sticky boxes with `--max-duration 2h --pause-retention 720h`
and resumes them on every command, with `COLINCODE_STICKY=1` as the escape
hatch for long unattended jobs. When `--idle-timeout` ships we would set it to
15 minutes by default and drop the 2h timer, so a box is paused only when
nobody is using it.

## Small related asks

- `tenki sandbox update <name> --sticky|--non-sticky` fails with
  "no sandbox session named … found in current scope"; it works with the id.
  Other subcommands accept the name.
- `tenki sandbox volume resize` is refused once a volume has ever been
  attached ("a volume keeps its size once it has been attached"), even when
  detached. Growing a detached volume would let users enlarge `~/work` without
  copying.
