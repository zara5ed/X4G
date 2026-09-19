# Security

Herald runs an AI agent that can execute tools on your behalf. Treat the
deployment as you would an SSH account: the security of the agent is the
security of your chat account, your provider keys, and the volume it runs on.

## Threat model in one paragraph

Anyone who can send messages your bot accepts can task the agent, and the agent
runs with the permissions of the container's unprivileged user — including the
shell tool if it is enabled. Anyone who can read your environment variables can
spend your model-provider credits. Anyone with write access to the volume can
change what the agent believes and remembers. Everything below follows from
those three sentences.

## Before you deploy

- [ ] **Set an allowlist**, not an open bot: `TELEGRAM_ALLOWED_USERS`,
      `DISCORD_ALLOWED_USERS`, or `SLACK_ALLOWED_USERS`. Herald warns loudly when
      `*_ALLOW_ALL_USERS` is on.
- [ ] **Keep secrets in Railway variables**, never in the repository. `.env` is
      git-ignored, and no secret has a default value.
- [ ] **Use a dedicated bot token** for this deployment so it can be revoked
      without affecting anything else.
- [ ] **Set a spending limit with your model provider.** Prompt injection can
      make an agent do expensive things; a billing cap bounds the damage.
- [ ] **Leave the HTTP API off** unless you need it. When it is on, every request
      requires `Authorization: Bearer $API_SERVER_KEY`.

## Operational hygiene

- The bootstrap **never prints secret values** — only the names of the variables
  it found. Keep it that way if you extend the script.
- If you enable the API server without a key, Herald generates a 256-bit key and
  stores it with `0600` permissions at `/opt/data/.api_server_key`.
  Copy it to a variable and delete the file if you prefer key management in one
  place.
- `railway ssh` gives a shell inside the container. Treat that access like root
  on a server: it can read every variable, including provider keys.
- Volumes are the agent's memory. Snapshot anything important outside Railway
  (the text files under `/opt/data` are small enough to keep in a
  private repo or a bucket).
- Rotate `TELEGRAM_BOT_TOKEN` / provider keys if they ever appear in a log,
  screenshot, or issue.

## Known limits, stated plainly

- **The agent can be prompt-injected.** Content it reads — a web page, an email,
  a file, a group message — can attempt to steer it. This is inherent to
  tool-using agents, not specific to Herald. Keep the bot private, constrain what
  it can reach, and do not give it credentials you would not hand to a stranger.
- **The shell tool is powerful.** With the local terminal backend, commands run
  inside the container as the unprivileged `hermes` user, with access to the
  volume and your environment variables.
- **This wrapper is not a sandbox.** It does not add isolation beyond what the
  upstream image already provides. If you need stronger boundaries, run the
  agent on hardware you control rather than a shared platform.
- **No warranty.** See `LICENSE`. You are responsible for how your deployment is
  used and for the keys it holds.

## Reporting a problem

Open a private security advisory on this repository (Security → Report a
vulnerability) rather than a public issue, and include the version from the boot
banner plus the log excerpt. **Never paste API keys or bot tokens** — redact them
first.

Issues in the agent runtime itself belong upstream with
[Hermes Agent](https://github.com/NousResearch/hermes-agent); issues in the
Dockerfile, bootstrap script, health endpoint or documentation belong here.
