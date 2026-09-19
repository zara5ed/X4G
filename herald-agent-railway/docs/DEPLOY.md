# Deploying Herald on Railway

Two paths: the dashboard (fastest) and the CLI (repeatable). Both end in the
same place — a single worker service with a persistent volume.

---

## 0. Prerequisites

| You need | Where |
|---|---|
| A model-provider API key | [OpenRouter](https://openrouter.ai/keys), [Anthropic](https://console.anthropic.com/), [OpenAI](https://platform.openai.com/api-keys), or Gemini/Groq for a free tier. The model must support a **≥64k token context**. |
| A chat bot | [@BotFather](https://t.me/BotFather) for Telegram, or a Discord / Slack app |
| Your numeric user id | [@userinfobot](https://t.me/userinfobot) for Telegram |
| ~5 minutes | |

---

## 1. Dashboard path

1. **Fork this repository** to your own GitHub account (recommended, so you can
   edit the persona and pin versions).
2. Railway → **New Project** → **Deploy from GitHub repo** → select your fork.
   Railway detects the `Dockerfile` and starts building.
3. **Before the first successful boot, add the volume.** Service → **Variables**
   isn't enough — go to the service → **Settings → Volumes → Add volume**,
   mount path **`/opt/data`**.
4. **Add variables** (Service → Variables):

   ```
   OPENROUTER_API_KEY      = sk-or-...
   TELEGRAM_BOT_TOKEN      = 123456:ABC...
   TELEGRAM_ALLOWED_USERS  = 123456789
   ```

5. **Redeploy** so the volume and variables are both present.
6. Watch the logs. A healthy boot prints the banner, the provider and channel it
   detected, then starts the gateway. Send `/start` to your bot in Telegram.

### Recommended service settings

| Setting | Value | Why |
|---|---|---|
| Replicas | **1** | Two gateways sharing one state directory corrupt it. |
| Restart policy | `on_failure`, max 5 retries | Stop on a bad variable instead of burning usage in a loop. |
| Region | same as the volume | Keep the volume and service together. |
| Public networking | **off** | No public surface by default. Only add a domain if you enable the HTTP API. |

---

## 2. CLI path

```bash
git clone https://github.com/<you>/herald-agent-railway
cd herald-agent-railway

railway login
railway init                      # create a project
railway link                      # or link an existing one

# 1) create the volume at /opt/data (dashboard, or via IaC below)

# 2) secrets
railway variables --set OPENROUTER_API_KEY=sk-or-...
railway variables --set TELEGRAM_BOT_TOKEN=123456:ABC...
railway variables --set TELEGRAM_ALLOWED_USERS=123456789

# 3) ship it
railway up
railway logs
```

---

## 3. Infrastructure as Code (optional, recommended if you use the CLI)

Railway deprecated `railway.json` / `railway.toml`; existing files stop being
read on **2026-12-01**, and new services cannot opt into them. Herald therefore
ships `.railway/railway.ts`:

```bash
npm install railway     # SDK that evaluates the file
railway config plan     # preview; secrets are redacted
railway config apply    # create/update service, volume and non-secret variables
```

The file declares the service, its 1 GB volume at `/opt/data`, single-replica
pinning and non-secret environment defaults. Add the GitHub source and secrets
in the dashboard — see [`.railway/README.md`](../.railway/README.md).

---

## 4. Verify the deployment

```bash
railway logs --tail 80
```

A good boot looks like:

```
  ┌────────────────────────────────────────────────────────────┐
  │  HERALD · AI agent gateway                       v1.0.0    │
  │  Railway edition · powered by Hermes Agent (MIT)           │
  └────────────────────────────────────────────────────────────┘

[herald] agent runtime : /opt/hermes/.venv/bin/hermes (…)
[herald] state dir     : /opt/data
[herald] volume        : writable
[herald] provider      : OPENROUTER_API_KEY
[herald] channels      : telegram
[herald] api server    : disabled (no public API surface)
[herald] persona       : seeded /opt/data/SOUL.md as "Herald"
[herald] health        : listening on 0.0.0.0:8080  (/healthz)
[herald] starting      : hermes gateway run
```

Then message your bot. Nothing on Telegram? Read
[TROUBLESHOOTING.md](TROUBLESHOOTING.md) before redeploying.

---

## 5. Enable the HTTP API (optional)

Only do this if you actually need the OpenAI-compatible endpoint.

1. Set variables:

   ```bash
   railway variables --set API_SERVER_ENABLED=1
   railway variables --set API_SERVER_HOST=0.0.0.0
   railway variables --set API_SERVER_KEY=$(openssl rand -hex 32)
   ```

   If you skip `API_SERVER_KEY`, Herald generates one and writes it to
   `/opt/data/.api_server_key` — check the logs for the file path. It
   will **never** publish an unauthenticated endpoint.

2. Add a domain (Service → Networking → Generate domain) and set the target
   port to the health/API port.
3. Optionally enable the platform healthcheck now that a port is reachable:
   path `/healthz`, timeout `300`. Enabling it without a reachable port fails
   every deploy, which is why it is off by default.

---

## 6. Pinning and upgrading the runtime

```bash
# Pin the runtime for reproducible deploys. Check the tag exists first:
#   docker manifest inspect nousresearch/hermes-agent:v2026.9.14   (or the Tags tab on Docker Hub)
# Tags follow the upstream release tags, e.g. v2026.9.14 / v2026.9.7.
railway variables --set HERMES_IMAGE=nousresearch/hermes-agent:v2026.9.14
```

The build argument defaults to `:latest`. Pin it for reproducible deploys, and
revert the pin after you have confirmed the new version behaves.

Upgrade procedure: bump the pin → redeploy → verify in chat. If something
breaks, restore the old pin; your volume (memory, sessions, skills) is
untouched by image changes.

---

## 7. Publishing this as a Railway template (optional)

If you want a one-click "Deploy on Railway" button for other people:

1. Create the project in Railway exactly as you want it to appear, including
   the volume at `/opt/data` and placeholder variables (mark secrets as
   required so the deployer must fill them in).
2. Project → **Settings → Generate Template**.
3. Replace the button in `README.md` with the generated
   `https://railway.com/deploy/<template-slug>` URL.
4. Review the template: verify that no secret value is baked in, that the
   volume is included, and that replicas are set to 1.

---

## 8. Cost and resource notes

- Idle agent: typically a few hundred MB of RAM, near-zero CPU while no
  messages are in flight. Model calls dominate cost, not the container.
- The volume only needs to hold text state; 1 GB is generous.
- Set a monthly spend limit on your **model provider** account. An agent that
  loops on tool calls is a provider-billing event, not a Railway one.
- Optional: cap the agent's tool loop with `HERMES_MAX_ITERATIONS` to bound
  worst-case token spend per turn.


---

## Appendix · What the upstream image already does

Read from the upstream `Dockerfile` (via the GitHub API, September 2026) so you
do not have to reverse-engineer it:

| Upstream fact | Consequence for this template |
|---|---|
| `ENV HERMES_HOME=/opt/data` | The state root **is** the volume root. Redefining `HERMES_HOME` would move config, sessions and skills into a subdirectory that no upstream tooling expects — so Herald never overrides it. |
| `VOLUME ["/opt/data"]` | Railway's volume must be mounted at `/opt/data`; that is the path `requiredMountPath` protects. |
| `ENTRYPOINT ["/opt/hermes/docker/entrypoint-dispatch.sh"]` | Under a normal PID 1 it execs s6-overlay `/init`, which runs the first-boot hook as root, fixes volume ownership, then drops to the unprivileged `hermes` user. When a platform wraps the entrypoint under its own init, the dispatcher skips s6 and runs the bootstrap directly — either way the agent starts. |
| The dispatcher treats a first argument that is an executable on PATH as a command | That is why `CMD ["bash", "/opt/herald/bootstrap.sh"]` works and needs no `hermes` subcommand wrapper. |
| `ENV HERMES_WRITE_SAFE_ROOT=/opt/data` | Writes are expected under the volume; tool artefacts landing elsewhere may be rejected by the runtime. |
| No `ENV HOME` | `HOME` stays the image user's home, so CLI caches are *not* persisted. Set `HOME=/opt/data` yourself if you want them on the volume. |
| Image includes a Node/Playwright toolchain and the `hermes` CLI | Nothing has to be installed at deploy time; this template only adds the bootstrap, health endpoint and persona. |
