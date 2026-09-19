#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  Herald · Railway bootstrap
#
#  Runs on top of the official Hermes Agent image, validates the deployment
#  configuration coming from Railway variables, starts a tiny health endpoint
#  that Railway can probe, and then hands over to the agent gateway.
#
#  Design goals
#    • fail loudly and early on misconfiguration (no silent crash loops)
#    • never print secrets
#    • never expose an unauthenticated HTTP API
#    • shut down cleanly on SIGTERM so the state volume stays consistent
#
#  Set HERALD_DRY_RUN=1 to validate the configuration and exit without
#  starting the gateway (useful from `railway run` or a local shell).
# ──────────────────────────────────────────────────────────────────────────────
set -Eeuo pipefail

HERALD_VERSION="1.0.0"
HERALD_NAME="${HERALD_AGENT_NAME:-Herald}"

# ── Small helpers ─────────────────────────────────────────────────────────────
log()  { printf '%s [herald] %s\n' "$(date -u +%H:%M:%S)" "$*"; }
warn() { printf '%s [herald] WARN  %s\n' "$(date -u +%H:%M:%S)" "$*" >&2; }
die()  { printf '\n%s [herald] ERROR %s\n\n' "$(date -u +%H:%M:%S)" "$*" >&2; }

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

# Fails the deploy with a readable explanation instead of a restart loop.
fail_config() {
  die "$1"
  printf '  Fix the Railway variables listed above and redeploy.\n' >&2
  printf '  To start anyway (not recommended): set HERALD_STRICT=0\n\n' >&2
  exit 78   # EX_CONFIG
}

# ── Locate the runtime ────────────────────────────────────────────────────────
HERMES_BIN="$(command -v hermes 2>/dev/null || true)"
if [[ -z "${HERMES_BIN}" && -x /opt/hermes/.venv/bin/hermes ]]; then
  HERMES_BIN=/opt/hermes/.venv/bin/hermes
fi

PYTHON_BIN="$(command -v python3 2>/dev/null || true)"
if [[ -z "${PYTHON_BIN}" && -x /opt/hermes/.venv/bin/python ]]; then
  PYTHON_BIN=/opt/hermes/.venv/bin/python
fi

# ── Data directory (Railway volume) ───────────────────────────────────────────
# The official image sets HERMES_HOME=/opt/data (its volume root). We only fall
# back to ${HOME}/.hermes when the script runs outside that image, e.g. a local
# HERALD_DRY_RUN=1 check — never overriding the image's own default.
export HOME="${HOME:-/opt/data}"
export HERMES_HOME="${HERMES_HOME:-${HOME}/.hermes}"
mkdir -p "${HERMES_HOME}" 2>/dev/null || true

banner() {
  printf '\n'
  printf '  ┌────────────────────────────────────────────────────────────┐\n'
  printf '  │  HERALD · AI agent gateway                       v%-9s│\n' "${HERALD_VERSION}"
  printf '  │  Railway edition · powered by Hermes Agent (MIT)           │\n'
  printf '  └────────────────────────────────────────────────────────────┘\n\n'
}

banner

if [[ -n "${HERMES_BIN}" ]]; then
  log "agent runtime : ${HERMES_BIN} ($("${HERMES_BIN}" version 2>/dev/null | head -n1 || echo 'version unknown'))"
else
  log "agent runtime : not found on PATH (validation only)"
fi
log "agent name    : ${HERALD_NAME}"
log "state dir     : ${HERMES_HOME}"

# ── Volume sanity ─────────────────────────────────────────────────────────────
volume_ok=false
if touch "${HERMES_HOME}/.write-test" 2>/dev/null; then
  rm -f "${HERMES_HOME}/.write-test"
  volume_ok=true
  log "volume        : writable"
else
  warn "volume        : ${HERMES_HOME} is NOT writable — agent memory cannot persist"
fi

if [[ "${volume_ok}" == true ]] && ! mountpoint -q "${HOME}" 2>/dev/null; then
  if [[ "${HERALD_SKIP_VOLUME_CHECK:-0}" != "1" ]]; then
    warn "volume        : ${HOME} does not look like a mounted volume."
    warn "                Attach a Railway volume at ${HOME}, otherwise all agent"
    warn "                memory, skills and sessions are lost on every redeploy."
  fi
fi

# ── LLM provider validation ───────────────────────────────────────────────────
# Names only — values are never echoed.
PROVIDER_KEYS=(
  OPENROUTER_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY NOUS_API_KEY HERMES_PORTAL_TOKEN
  GOOGLE_API_KEY GEMINI_API_KEY GROQ_API_KEY MISTRAL_API_KEY DEEPSEEK_API_KEY
  XAI_API_KEY CEREBRAS_API_KEY TOGETHER_API_KEY FIREWORKS_API_KEY PERPLEXITY_API_KEY
)
found_provider=""
for key in "${PROVIDER_KEYS[@]}"; do
  if [[ -n "${!key:-}" ]]; then
    found_provider="${found_provider:+${found_provider}, }${key}"
  fi
done

if [[ -n "${found_provider}" ]]; then
  log "provider      : ${found_provider}"
elif ! is_true "${HERALD_ALLOW_NO_PROVIDER:-0}"; then
  providers_list="$(printf '  %s\n' "${PROVIDER_KEYS[@]}")"
  if is_true "${HERALD_STRICT:-1}"; then
    fail_config "No LLM provider credentials found.

  Set at least one of these Railway variables:
${providers_list}

  Get a free key from https://openrouter.ai/keys or https://aistudio.google.com/apikey
  (the agent needs a model with a >=64k token context window)."
  else
    warn "provider      : none configured — the agent will not be able to answer."
  fi
fi

# ── Messaging platform validation ─────────────────────────────────────────────
platforms=()
[[ -n "${TELEGRAM_BOT_TOKEN:-}"                       ]] && platforms+=("telegram")
[[ -n "${DISCORD_BOT_TOKEN:-}"                        ]] && platforms+=("discord")
[[ -n "${SLACK_BOT_TOKEN:-}" && -n "${SLACK_APP_TOKEN:-}" ]] && platforms+=("slack")
[[ -n "${MATRIX_ACCESS_TOKEN:-}"                      ]] && platforms+=("matrix")
[[ -n "${MATTERMOST_TOKEN:-}"                         ]] && platforms+=("mattermost")
[[ -n "${DINGTALK_CLIENT_ID:-}"                       ]] && platforms+=("dingtalk")
[[ -n "${FEISHU_APP_ID:-}"                            ]] && platforms+=("feishu")
[[ -n "${LINE_CHANNEL_ACCESS_TOKEN:-}"                ]] && platforms+=("line")
[[ -n "${EMAIL_IMAP_HOST:-}"                          ]] && platforms+=("email")
[[ -n "${IRC_SERVER:-}"                               ]] && platforms+=("irc")
[[ -n "${NTFY_TOPIC:-}"                               ]] && platforms+=("ntfy")
[[ -n "${BLUEBUBBLES_SERVER_URL:-}"                   ]] && platforms+=("bluebubbles")
is_true "${WHATSAPP_ENABLED:-0}"                      && platforms+=("whatsapp")

if (( ${#platforms[@]} > 0 )); then
  log "channels      : ${platforms[*]}"
else
  warn "channels      : none configured — nothing can reach the agent yet."
  warn "                Add TELEGRAM_BOT_TOKEN (or DISCORD_BOT_TOKEN / SLACK_*)"
  warn "                to talk to it from a chat app."
fi

# ── Security posture ──────────────────────────────────────────────────────────
if is_true "${TELEGRAM_ALLOW_ALL_USERS:-0}" || is_true "${DISCORD_ALLOW_ALL_USERS:-0}" || is_true "${GATEWAY_ALLOW_ALL_USERS:-0}"; then
  warn "security      : *_ALLOW_ALL_USERS is enabled — anyone who finds the bot"
  warn "                can use your agent and spend your provider credits."
  warn "                Prefer TELEGRAM_ALLOWED_USERS=<your numeric id>."
fi

if [[ -n "${TERMINAL_BACKEND:-}" && "${TERMINAL_BACKEND}" == "docker" ]]; then
  warn "security      : TERMINAL_BACKEND=docker will not work on Railway — there is"
  warn "                no Docker daemon inside this container. Use 'local' or leave"
  warn "                it unset. The local shell tool runs commands inside this"
  warn "                container with the agent's permissions."
fi

# Never expose the OpenAI-compatible API without a key. If the operator turned
# the API server on but forgot the key, mint one and persist it on the volume.
if is_true "${API_SERVER_ENABLED:-0}" || is_true "${HERALD_PUBLIC_API:-0}"; then
  if [[ -z "${API_SERVER_KEY:-}" ]]; then
    key_file="${HERMES_HOME}/.api_server_key"
    if [[ -s "${key_file}" ]]; then
      API_SERVER_KEY="$(head -n1 "${key_file}")"
      log "api server    : reusing generated key from ${key_file}"
    else
      API_SERVER_KEY="$("${PYTHON_BIN:-python3}" -c 'import secrets;print(secrets.token_hex(32))')"
      umask 077; printf '%s' "${API_SERVER_KEY}" > "${key_file}"
      log "api server    : generated a key and saved it to ${key_file}"
      log "                run: railway variables --set API_SERVER_KEY=${API_SERVER_KEY:0:8}…  (see file for the full value)"
    fi
    export API_SERVER_KEY
  fi
  export API_SERVER_HOST="${API_SERVER_HOST:-0.0.0.0}"
  if [[ "${API_SERVER_HOST}" != "0.0.0.0" ]]; then
    warn "api server    : API_SERVER_HOST is '${API_SERVER_HOST}'; Railway needs 0.0.0.0"
    export API_SERVER_HOST="0.0.0.0"
  fi
  log "api server    : enabled (key required on every request)"
else
  log "api server    : disabled (no public API surface)"
fi

# ── Optional persona seed (never overwrites your own SOUL.md) ─────────────────
SOUL_TEMPLATE="${HERALD_SOUL_FILE:-/opt/herald/soul.md}"
if is_true "${HERALD_SEED_SOUL:-1}" && [[ -f "${SOUL_TEMPLATE}" ]]; then
  if [[ ! -f "${HERMES_HOME}/SOUL.md" ]]; then
    sed "s/{{AGENT_NAME}}/${HERALD_NAME}/g" "${SOUL_TEMPLATE}" > "${HERMES_HOME}/SOUL.md"
    log "persona       : seeded ${HERMES_HOME}/SOUL.md as \"${HERALD_NAME}\""
  else
    log "persona       : keeping your existing SOUL.md"
  fi
fi

# ── Readiness file consumed by the health endpoint ────────────────────────────
provider_label="${found_provider:-none}"
[[ "${provider_label}" == *","* ]] && provider_label="multiple"
platforms_json="$(printf '"%s",' "${platforms[@]:-none}" | sed 's/,$//')"
printf '{"ready":true,"agent":"%s","version":"%s","provider":"%s","platforms":[%s]}' \
  "${HERALD_NAME}" "${HERALD_VERSION}" "${provider_label}" "${platforms_json}" \
  > /tmp/herald-ready.json 2>/dev/null || true

# ── Dry run ───────────────────────────────────────────────────────────────────
if is_true "${HERALD_DRY_RUN:-0}"; then
  log "dry run       : configuration looks OK, not starting the gateway."
  exit 0
fi

# ── Health endpoint (Railway can probe this) ──────────────────────────────────
HEALTH_PORT="${HERALD_HEALTH_PORT:-${PORT:-8080}}"
if [[ -n "${PYTHON_BIN}" && -f /opt/herald/health_server.py ]]; then
  HERALD_HEALTH_PORT="${HEALTH_PORT}" "${PYTHON_BIN}" /opt/herald/health_server.py &
  HEALTH_PID=$!
  log "health        : listening on 0.0.0.0:${HEALTH_PORT}  (/healthz)"
else
  HEALTH_PID=""
  warn "health        : health server unavailable (no python interpreter found)"
fi

# ── Hand over to the agent ────────────────────────────────────────────────────
HERALD_COMMAND="${HERALD_COMMAND:-gateway run}"

if [[ -z "${HERMES_BIN}" ]]; then
  die "Cannot start: the Hermes runtime is missing from this image."
  exit 70
fi

log "starting      : hermes ${HERALD_COMMAND}"

cleanup() {
  log "shutdown      : received stop signal, closing down cleanly"
  if [[ -n "${HEALTH_PID}" ]] && kill -0 "${HEALTH_PID}" 2>/dev/null; then
    kill -TERM "${HEALTH_PID}" 2>/dev/null || true
  fi
  if [[ -n "${AGENT_PID:-}" ]] && kill -0 "${AGENT_PID}" 2>/dev/null; then
    kill -TERM "${AGENT_PID}" 2>/dev/null || true
    for _ in $(seq 1 25); do
      kill -0 "${AGENT_PID}" 2>/dev/null || break
      sleep 0.4
    done
    kill -KILL "${AGENT_PID}" 2>/dev/null || true
  fi
  exit 0
}
trap cleanup SIGTERM SIGINT SIGQUIT

# shellcheck disable=SC2086  # HERALD_COMMAND is an intentional two-word command
"${HERMES_BIN}" ${HERALD_COMMAND} &
AGENT_PID=$!
wait "${AGENT_PID}"
status=$?

log "agent exited  : status ${status}"
exit "${status}"
