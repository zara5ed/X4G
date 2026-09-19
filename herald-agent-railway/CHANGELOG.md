# Changelog

Versions refer to the Herald wrapper. The agent runtime version is pinned
separately through the `HERMES_IMAGE` build argument.

## 1.0.0 — 2026-09-19

First release.

**Deployment**
- Dockerfile overlay on the official `nousresearch/hermes-agent` image; the
  upstream entrypoint is intentionally left in place so first-boot volume
  ownership handling, privilege dropping and orphan reaping keep working.
- Railway Infrastructure as Code in `.railway/railway.ts` (service, 1 GB volume
  at `/opt/data`, single replica, non-secret defaults). No `railway.toml`:
  Railway deprecated Config as Code, and a service cannot be managed by both
  systems at once.
- `docker-compose.yml` for local smoke tests.

**Runtime behaviour**
- `scripts/bootstrap.sh`: validates provider and channel variables, fails with
  `EX_CONFIG` and a readable message instead of crash-looping, warns about
  insecure or impossible settings, seeds the persona once, starts the health
  endpoint, forwards `SIGTERM` for a clean shutdown.
- `app/health_server.py`: dependency-free `/healthz`, `/readyz` and service
  card, with `HEAD` support and no secret exposure. `SIGTERM` is handled on a
  helper thread, because calling `BaseServer.shutdown()` from the signal
  handler deadlocks and the process would ignore the stop signal.
- Generated API key when the HTTP API is enabled without one — an
  unauthenticated endpoint is never published.

**Security and compliance**
- No proxy, tunnel or VPN capability of any kind.
- No public surface unless you deliberately add a domain.
- No crypto, wallet or faucet automation.
- Compliance guide mapped to the patterns that get PaaS accounts flagged.

**Documentation**
- `docs/DEPLOY.md`, `docs/TROUBLESHOOTING.md`, `docs/COMPLIANCE.md`,
  `SECURITY.md`, `NOTICE` (upstream attribution), `.env.example`.
