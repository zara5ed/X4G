# Compliance guide

A short, practical guide to running Herald on Railway without tripping over
platform rules. Written for a single owner running one personal agent.

> Herald is a deployment wrapper for the MIT-licensed Hermes Agent runtime.
> Railway's policies apply to **what your service does**, not to what the
> project is called. Renaming or rebranding a deployment does not change which
> rules apply to it — behaviour does. This page is about behaviour.

---

## 1. What actually gets accounts flagged

Across PaaS platforms, the same handful of patterns recur:

| Pattern | Why it is a problem |
|---|---|
| **Proxy / VPN / tunnel services** (VLESS, VMess, WireGuard, Shadowsocks, SOCKS relays, "free internet" gateways) | Almost universally banned by PaaS acceptable-use policies. Running them is the single fastest route to a suspended account. |
| **Multiple accounts** to harvest trial credits or free tiers | Multi-accounting is treated as fraud, and platforms link accounts by payment instrument, IP, and device. Accounts created after a ban are usually removed faster than the original. |
| **Reselling platform capacity** to third parties | Using a hobby plan as a commercial hosting backend is a breach of most terms. |
| **Abuse traffic** — spam, scraping at scale, port scanning, credential stuffing, crypto mining | Detected by egress and reputation monitoring, not by reading your code. |
| **Runaway resource consumption** — crash loops, unbounded loops, hundreds of concurrent browser sessions | Hits usage caps, gets throttled, and looks identical to abuse. |

Note what is **not** on that list: running a personal AI assistant that talks to
you over Telegram. That is ordinary application hosting.

---

## 2. What Herald does to keep you inside the lines

**It cannot be turned into a proxy.** There is no tunnelling, relaying, SOCKS or
VPN code in this repository. The runtime is a chat agent: it answers messages
and runs tools. That is its whole job.

**It exposes no public surface by default.** The service is a worker — no
domain, no published port, no open endpoints. The only listening socket is the
health endpoint on the container's internal port, which serves `/healthz`,
`/readyz` and a service card. Nothing accepts arbitrary traffic, so there is no
"open relay" for an abuse scanner to find.

**The optional HTTP API is key-gated by construction.** If you set
`API_SERVER_ENABLED=1` and forget a key, the bootstrap mints a 256-bit key and
stores it on your volume rather than exposing an unauthenticated
OpenAI-compatible endpoint. An open LLM endpoint is exactly the kind of thing
that turns a hobby app into an abuse platform.

**No crypto or faucet automation ships here.** Some community templates
auto-create wallets and hit testnet faucets on boot. Herald contains none of
that: it is unnecessary for a chat agent, it looks like automated abuse to
fraud systems, and it adds on-chain activity to a service that has no use for it.

**It is single-replica by default.** Two agent gateways must never share one
state directory anyway — and one replica also keeps you well inside the
resource envelope of a small plan.

**It fails loudly instead of looping.** Misconfiguration exits with a readable
message and a non-zero status rather than crash-looping for hours. The
recommended restart policy (`on_failure`, max 5 retries) means a broken deploy
stops instead of quietly burning usage.

**It does not self-update the runtime.** The base image is pinned by build
argument, so a redeploy never silently swaps the software underneath you.

**It logs without leaking.** Secrets are never printed; the bootstrap reports
variable *names* that were found, not values.

---

## 3. Your side of the deal

- [ ] Use it **for yourself**, not as a service you resell or host for others.
- [ ] Keep one Railway account, with accurate details, and one deployment.
- [ ] Prefer `TELEGRAM_ALLOWED_USERS` (an allowlist) over
      `TELEGRAM_ALLOW_ALL_USERS`. A bot that answers strangers is a bot that
      spends your provider credits and can be used to relay abuse.
- [ ] Set a spend limit or alerts with your **model provider** — an agent loop
      can burn API credit far faster than it can burn Railway credit.
- [ ] Keep the service inside your plan's usage. Check the Railway usage view
      after the first week; a chat agent should sit in the low hundreds of MB
      of RAM with near-zero CPU while idle.
- [ ] Don't run a tunnel, proxy or VPN in the same Railway project. If you want
      a proxy, run it on a VPS whose provider permits it.
- [ ] Rotate a bot token immediately if it is ever pasted into a public place.

---

## 4. If something does go wrong

1. **Read the notice.** Platforms usually name the violation. "Acceptable use",
   "abuse", and "payment" are three different conversations.
2. **Fix the specific thing named**, then reply to the notice through the
   platform's support channel. Suspensions caused by a misconfigured service are
   often reversible when you can point at the change you made.
3. **Do not create a new account to continue.** That converts a fixable
   suspension into ban evasion, and it is the reason a second removal tends to
   be permanent. Reconnect through support, or move that specific workload
   somewhere it is allowed.
4. **If the blocked workload was a proxy**, keep it off PaaS entirely — that is
   what VPS providers are for. Keep the agent where it is.

---

## 5. Where to read the real rules

- Railway's acceptable-use and terms pages — the authoritative source; this
  document is a practical summary, not a substitute, and not legal advice.
- Your model provider's usage policy, which governs how your agent may be used
  and how your data is handled.
- The upstream Hermes Agent security documentation for runtime-level concerns.

If a rule conflicts with something in this repository, the rule wins.
