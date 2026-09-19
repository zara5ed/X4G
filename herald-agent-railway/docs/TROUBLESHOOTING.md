# Troubleshooting

Start with the deploy logs — the bootstrap prints a checklist on every boot:

```bash
railway logs --tail 120
```

---

## Deploy fails or the container restarts immediately

**`ERROR No LLM provider credentials found`**
No provider key is set. Herald exits with status 78 (`EX_CONFIG`) on purpose, so
the deploy fails readably instead of looping. Set `OPENROUTER_API_KEY`,
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, or `GOOGLE_API_KEY`, then redeploy.

**`ERROR Cannot start: the Hermes runtime is missing`**
The base image was replaced by something that is not the upstream runtime image.
Restore `HERMES_IMAGE` (default `nousresearch/hermes-agent:latest`) and redeploy.

**Deploy stops after 5 restarts**
That is the recommended policy: `on_failure` with `restartPolicyMaxRetries = 5`.
The first error in the logs is the real one; the rest are repeats.

**Want to inspect without starting the agent?**

```bash
railway variables --set HERALD_DRY_RUN=1
railway redeploy      # validates configuration, prints the summary, exits 0
```

---

## The bot never answers

Check these in order — nine out of ten cases are the first two.

1. **Volume missing.** If the log shows
   `volume : /opt/data does not look like a mounted volume`, add a Railway
   volume at `/opt/data`. Without it the agent starts with no state and can
   behave oddly across redeploys.
2. **Wrong allowlist.** `TELEGRAM_ALLOWED_USERS` must contain **your numeric
   Telegram id**, not your @username. Get it from [@userinfobot](https://t.me/userinfobot).
   In groups, a bot with Telegram's default privacy mode only sees messages that
   mention it or reply to it — that is Telegram behaviour, not a Herald bug.
3. **Bot token typo.** Tokens look like `123456789:AAE...`. A trailing space or
   a newline pasted from the dashboard is enough to break authentication.
4. **Platform not detected.** The boot log lists the channels it found:
   `channels : telegram`. If it says `none configured`, the token variable is
   missing or misnamed.
5. **Webhook vs polling.** Herald runs the gateway in polling-friendly mode by
   default. If you previously configured a webhook for the same bot token,
   delete it — Telegram delivers to one target only.

---

## `TESTS FAIL` / model errors in the logs

**"context window too small"** — the runtime requires a model with **≥64,000
tokens of context**. Free small models often have 8k–32k. Pick a larger model
and optionally set `LLM_MODEL` to force it.

**429 / rate limit** — a free provider tier is rate limited. Either slow down,
or switch provider; `LLM_MODEL` plus a second provider key makes the fallback
path work.

**401 from the provider** — the key is wrong, expired, or has no credit.
Verify it outside Railway with a direct `curl`.

---

## The agent's shell tool does not work

`TERMINAL_BACKEND=docker` **cannot work on Railway** — there is no Docker daemon
inside the container. Herald warns about this on boot. Leave `TERMINAL_BACKEND`
unset (the local backend runs commands inside the container) and remember that
the shell tool executes with the agent's own permissions on your service.

If instead you see permission errors writing files, confirm the volume is
mounted at `/opt/data` and that you did not override the image entrypoint —
the first-boot hook needs to run to fix volume ownership.

---

## The HTTP API returns 401 / nothing listens

- `API_SERVER_ENABLED=1` requires `API_SERVER_HOST=0.0.0.0` for Railway to reach
  it; Herald forces this and warns if you set anything else.
- Every request needs `Authorization: Bearer $API_SERVER_KEY`. If you did not
  set a key, read it from `/opt/data/.api_server_key`.
- No domain attached means the API is not reachable from the internet. Add one
  and set the target port to match.

---

## Memory or disk growth

- Chat history and skills grow slowly and live on the volume. 1 GB is generous.
- The agent may cache downloaded files under `/opt/data`. If disk fills, raise
  the volume size (a resize upward is non-destructive in Railway).
- RAM spikes during long tool chains are normal; sustained high CPU is not.
  Check for a runaway loop and consider `HERMES_MAX_ITERATIONS`.

---

## Two deployments, one volume

Never run two gateway containers against the same data directory: sessions and
the memory store are not designed for concurrent writers. Keep `replicas = 1`.
Railway scales horizontally only if you ask it to, so this is usually caused by
an old service still running — delete it.

---

## Starting over

To reset the agent to a blank slate without touching your deployment:

```bash
railway ssh                     # if SSH is enabled on the service
find /opt/data -mindepth 1 -delete   # ⚠ empties the state volume (memory, sessions, credentials)
```

Then redeploy: the bootstrap recreates the directory and re-seeds the persona.
This is irreversible — copy anything you care about first.
