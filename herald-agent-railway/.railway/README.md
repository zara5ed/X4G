# `.railway/` — Railway Infrastructure as Code

This directory describes the Railway project for Herald:
one service (`herald`) with a 1 GB volume mounted at `/opt/data`, pinned to a
single replica.

## Why not `railway.toml`?

Railway **deprecated Config as Code** (`railway.json` / `railway.toml`):

- existing files stop being read on **2026-12-01** (hard cutoff),
- **new services cannot opt into it**,
- and a service cannot be managed by both systems at once — `railway config plan`
  refuses to continue while a legacy config file is still in play.

So this repository ships the current format instead of the deprecated one.

## Usage

```bash
npm install railway          # the SDK that evaluates railway.ts

railway login
railway link                 # pick the project + environment

railway config plan          # preview, safe, secrets are redacted
railway config apply         # apply after review
```

To import an existing project first (for example one you created in the
dashboard), run `railway config pull` and review the generated file before
applying.

## What this file does *not* cover

Railway's IaC DSL covers project resources — services, volumes, replicas,
variables, domains. A few deploy settings still live in the dashboard:

| Setting | Where to set it |
|---|---|
| GitHub repository connection for the service | Dashboard → Service → Settings → Source |
| Restart policy (Herald suggests `on_failure`, max 5 retries) | Dashboard → Service → Settings |
| Public domain (only if you enable the HTTP API) | Dashboard → Service → Networking |
| Healthcheck path (only if you add a domain) | `/healthz`, timeout `300` |

The `Dockerfile` in the repository root is detected automatically by Railway,
so no build configuration is required.
