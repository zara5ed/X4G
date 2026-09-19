# Herald · AI agent gateway (Railway edition)

Deploy a private AI agent that lives in your chat apps — Telegram, Discord or
Slack — as a single Railway service with persistent memory.

<p>
  <img src="https://img.shields.io/badge/runtime-Hermes%20Agent%20(MIT)-blue" alt="Runtime: Hermes Agent (MIT)">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT">
  <img src="https://img.shields.io/badge/railway-IaC%20(.railway%2Frailway.ts)-blueviolet" alt="Railway Infrastructure as Code">
</p>

<!--
  Publishing this as a one-click Railway template?
  Generate the template (Railway → Project → Settings → Generate Template) and
  paste the resulting URL into a badge like the one below. The step-by-step is
  in docs/DEPLOY.md §7. Until a template exists there is nothing honest to link
  to, so the button stays out of the README.

  <a href="https://railway.com/deploy/YOUR-TEMPLATE-SLUG">
    <img src="https://railway.com/button.svg" alt="Deploy on Railway" height="38">
  </a>
-->

Herald is a **deployment template**: a thin, auditable wrapper that runs the
open-source [Hermes Agent](https://github.com/NousResearch/hermes-agent) runtime
on Railway with sane defaults, first-boot validation and a small health
endpoint. It is **not** a fork of any third-party template — the Dockerfile,
bootstrap script and documentation here are written from scratch for this repo.

---

## Why Herald

| | |
|---|---|
| 🔒 **No public surface by default** | The agent talks *out* to your chat platform. No domain, no open API, no proxy — nothing for an abuse scanner to find. |
| 🧱 **Fails loudly, not in a loop** | On boot it checks your variables and prints exactly what is missing instead of crash-looping for hours. |
| 💾 **Persistent memory** | State lives on a Railway volume, so the agent keeps its memory, skills and sessions across redeploys. |
| 🔑 **Key-gated API** | If you ever turn the HTTP API on, Herald refuses to expose it without a key — it mints one and stores it on the volume. |
| 🛡️ **Allowlist-first security** | Warns you when `*_ALLOW_ALL_USERS` is on, so a stranger cannot spend your provider credits. |
| 🧾 **Compliance-aware** | Ships with a plain-language [compliance guide](docs/COMPLIANCE.md) mapped to Railway's acceptable-use rules. |
| 🩺 **Health endpoint** | `/healthz` and `/readyz` from the standard library — zero extra dependencies to patch. |

---

## Quick start

### 0. Get the code

```bash
git clone <your-fork-url> herald-agent-railway && cd herald-agent-railway
./publish.sh            # optional: create your own GitHub repo in one command
```

Already cloned or downloaded a copy? Skip straight to step 1.

### 1. Create the service

- **Dashboard** — New Project → Deploy from GitHub repo → pick your fork of this repo.
  Railway detects the `Dockerfile` automatically; no build settings needed.
- **CLI**

  ```bash
  railway init
  railway up
  ```

### 2. Add the volume (do this before the first deploy)

Create a volume mounted at **`/opt/data`**. Without it the agent has no memory:
every redeploy starts from zero.

### 3. Set your variables

Minimum viable set — one model provider **and** one chat platform:

```bash
railway variables --set OPENROUTER_API_KEY=sk-or-...      # or ANTHROPIC_API_KEY / OPENAI_API_KEY / GOOGLE_API_KEY …
railway variables --set TELEGRAM_BOT_TOKEN=123456:ABC...  # from @BotFather
railway variables --set TELEGRAM_ALLOWED_USERS=123456789  # your numeric Telegram id, from @userinfobot
```

Then `railway up` (or hit **Deploy**). Watch the logs: Herald prints a short
checklist of what it found, and the bot usually answers within a minute.

> **Prefer free tiers?** `GOOGLE_API_KEY` (Gemini, no credit card) and
> `GROQ_API_KEY` both work and are free to start with. Any model you pick needs
> a **64k token context window** — that is a runtime requirement of the agent,
> not a Herald limitation.

### 4. Talk to it

Open Telegram, find your bot, send `/start`. The agent replies as **Herald**
(the default persona is seeded once into `SOUL.md` — edit or delete it freely).

---

## Configuration

### Model provider (pick one)

`OPENROUTER_API_KEY` · `ANTHROPIC_API_KEY` · `OPENAI_API_KEY` · `GOOGLE_API_KEY` ·
`GEMINI_API_KEY` · `GROQ_API_KEY` · `MISTRAL_API_KEY` · `DEEPSEEK_API_KEY` ·
`XAI_API_KEY` · `CEREBRAS_API_KEY` · `TOGETHER_API_KEY` · `NOUS_API_KEY`

Optional: `LLM_MODEL` to override the default model.

### Chat platform (pick at least one)

| Platform | Variables |
|---|---|
| Telegram | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS` |
| Discord | `DISCORD_BOT_TOKEN`, `DISCORD_ALLOWED_USERS` |
| Slack | `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS` |
| Matrix / Mattermost / DingTalk / Feishu / LINE / IRC / ntfy / Email | see [.env.example](.env.example) |

### Herald-specific variables

| Variable | Default | Purpose |
|---|---|---|
| `HERALD_AGENT_NAME` | `Herald` | The name the agent uses for itself. |
| `HERALD_COMMAND` | `gateway run` | What to run — e.g. `cron list`, or `gateway run --profile work`. |
| `HERALD_HEALTH_PORT` | `$PORT` or `8080` | Port for the health endpoint. |
| `HERALD_STRICT` | `1` | `0` starts anyway when the provider/platform check fails. |
| `HERALD_DRY_RUN` | `0` | `1` validates the configuration and exits — great for debugging. |
| `HERALD_SEED_SOUL` | `1` | `0` skips creating the default `SOUL.md` persona. |
| `HERALD_ALLOW_NO_PROVIDER` | `0` | Allow booting without any model credentials. |
| `HERALD_SKIP_VOLUME_CHECK` | `0` | Silence the missing-volume warning. |

### Everything else

The runtime itself is configured through its own documented environment
variables — Herald passes your Railway variables straight through, so the full
upstream surface keeps working. See [.env.example](.env.example) for the
common ones.

---

## How it fits together

```
Telegram / Discord / Slack
          │  (outbound long-poll / websocket — no inbound port needed)
          ▼
┌──────────────────────────────────────────────────────────┐
│ Railway service (1 replica)                              │
│                                                          │
│  /opt/herald/bootstrap.sh   ← validates variables,       │
│    • fail fast on misconfig    seeds persona, starts …   │
│    • never prints secrets                                │
│                                                          │
│  /opt/herald/health_server.py   :8080  /healthz /readyz   │
│                                                          │
│  hermes gateway run             ← the agent runtime      │
│                                                          │
│  /opt/data  ← Railway volume: memory, sessions, skills   │
└──────────────────────────────────────────────────────────┘
```

Boot sequence:

1. The upstream image's init runs as root, fixes volume ownership and drops to
   the unprivileged `hermes` user.
2. `bootstrap.sh` runs as that user: it resolves the runtime, validates your
   variables, warns about insecure or impossible settings, and seeds `SOUL.md`.
3. The health endpoint starts (for Railway's optional healthcheck or your own
   uptime monitor).
4. `hermes gateway run` takes over in the foreground. On `SIGTERM` Herald shuts
   the gateway down gracefully so the state on the volume stays consistent.

---

## Operations

```bash
railway logs                    # structured logs from the agent and the bootstrap
railway variables               # review your configuration
railway redeploy                # pick up variable changes
railway ssh                     # shell into the running container (if enabled)
```

**Pin the runtime for reproducible deploys:**

```bash
railway variables --set HERMES_IMAGE=nousresearch/hermes-agent:v2026.9.7
```

**Upgrade:** bump `HERMES_IMAGE`, redeploy, then revert the pin once you are
happy. Two gateways must never share one volume, so keep the service at a
**single replica** — `numReplicas` is pinned in the deploy config for that
reason.

Troubleshooting lives in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## Before you deploy — the short compliance version

Herald is built to stay inside Railway's acceptable-use policy:

- it ships **no proxy, VPN or tunnelling capability** of any kind;
- it exposes **no public endpoint** unless you deliberately add a domain;
- it ships **no crypto, faucet or blockchain automation**;
- it runs **one replica** and stops retrying after repeated crashes, so it will
  not quietly consume your plan's usage.

Your side of the deal: use it for yourself, keep your provider keys private,
and respect the limits of your plan. The full checklist — including what to do
if a bot of yours gets flagged — is in [docs/COMPLIANCE.md](docs/COMPLIANCE.md).

---

## Repository layout

```
Dockerfile              thin overlay on the upstream runtime image
.railway/               Railway Infrastructure-as-Code (the current format;
                        railway.toml is deprecated — see .railway/README.md)
scripts/bootstrap.sh    validation, persona seed, graceful shutdown
app/health_server.py    /healthz + /readyz, standard library only
assets/soul.md          default persona template
publish.sh              one command to create your own GitHub repo and push
docs/                   deploy, compliance, troubleshooting, security
MOVE-TO-OWN-REPO.md     how this folder becomes a standalone repository
```

---

## License and credits

Herald's own code is MIT licensed — see [LICENSE](LICENSE).

It **runs** [Hermes Agent](https://github.com/NousResearch/hermes-agent) by
[Nous Research](https://nousresearch.com), also MIT licensed, pulled in as the
base image at build time. That project is where the actual agent lives; Herald
only packages and operates it. Attribution and the upstream license text are in
[NOTICE](NOTICE).

Not affiliated with, endorsed by, or supported by Nous Research or Railway.
"Herald" is the name of this deployment wrapper, not a rename of the upstream
project — please report runtime bugs upstream and packaging bugs here.
