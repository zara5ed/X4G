#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  publish.sh — create a new GitHub repository for Herald and push it there.
#
#  Run this from your own machine, where `gh` is authenticated as *you*.
#
#    ./publish.sh                          # public repo named herald-agent-railway
#    ./publish.sh my-agent                 # custom name
#    ./publish.sh my-agent --private       # private repo
#    ./publish.sh --dry-run                # run every check, print commands, change nothing
#
#  It is deliberately careful: it verifies your tooling, refuses to publish
#  anything that looks like a credential, and never force-pushes over an
#  existing repository.
# ──────────────────────────────────────────────────────────────────────────────
set -Eeuo pipefail

RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; DIM=$'\033[2m'; RST=$'\033[0m'
say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$GRN" "$RST" "$*"; }
warn() { printf '%s!%s %s\n' "$YLW" "$RST" "$*" >&2; }
die()  { printf '%s✗ %s%s\n' "$RED" "$*" "$RST" >&2; exit 1; }
run()  { if [[ "$DRY_RUN" == true ]]; then printf '%s  $ %s%s\n' "$DIM" "$*" "$RST"; else "$@"; fi; }

DRY_RUN=false
REPO_NAME=""
VISIBILITY="--public"

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --private)   VISIBILITY="--private" ;;
    --public)    VISIBILITY="--public" ;;
    -h|--help)   sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -* )         die "unknown flag: $arg" ;;
    * )          [[ -z "$REPO_NAME" ]] || die "only one repository name is allowed"
                 REPO_NAME="$arg" ;;
  esac
done

REPO_NAME="${REPO_NAME:-herald-agent-railway}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

say ""
say "  Herald · publish to GitHub"
say "  ─────────────────────────────────────────────"
say "  repository : $REPO_NAME  (${VISIBILITY#--})"
say "  directory  : $ROOT"
say ""

# ── 1. Tooling ────────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || die "git is not installed"
ok "git found"

if ! command -v gh >/dev/null 2>&1; then
  die "the GitHub CLI is not installed.
    Install it from https://cli.github.com, then run: gh auth login
    (or create the repository by hand and push this directory to it)"
fi
ok "gh found ($(gh --version | head -n1))"

if ! gh auth status >/dev/null 2>&1; then
  die "gh is not authenticated. Run: gh auth login"
fi

# Read the login, but never trust it blindly: a token without the `read:user`
# scope returns an error body instead of a name, and that JSON must not be
# mistaken for a username.
GH_USER="$(gh api user --jq .login 2>/dev/null || true)"
if [[ "$GH_USER" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,38})$ ]]; then
  ok "authenticated as ${GH_USER}"
else
  GH_USER=""
  warn "could not read your GitHub login from the token (missing read:user scope?)"
  warn "continuing without the duplicate-repository check"
fi

# ── 2. Refuse to publish credentials ─────────────────────────────────────────
say ""
say "  Checking for credentials that must not be committed…"

SUSPECT_FILES=()
while IFS= read -r f; do [[ -n "$f" ]] && SUSPECT_FILES+=("$f"); done < <(
  grep -rlIE '(sk-[A-Za-z0-9]{20,}|[0-9]{9,}:AA[A-Za-z0-9_-]{30,}|gh[pousr]_[A-Za-z0-9]{20,})' \
    --exclude-dir=.git --exclude-dir=node_modules . 2>/dev/null || true
)

if ((${#SUSPECT_FILES[@]} > 0)); then
  printf '%s✗%s possible credentials found in:\n' "$RED" "$RST" >&2
  printf '    %s\n' "${SUSPECT_FILES[@]}" >&2
  die "remove them (or replace with placeholders) before publishing"
fi
ok "no credential-looking strings in the project"

if [[ -f .env ]]; then
  say "  ${YLW}!${RST} .env exists locally — it is git-ignored and will not be pushed"
fi
grep -q '^\.env$' .gitignore 2>/dev/null || warn ".env is not in .gitignore — add it before committing secrets"

# ── 3. Git repository ────────────────────────────────────────────────────────
say ""
if [[ ! -d .git ]]; then
  warn "this directory is not a git repository yet — initialising one"
  run git init -q -b main
  run git add -A
  run git -c user.name="${GIT_AUTHOR_NAME:-${GH_USER:-Herald}}" \
          -c user.email="${GIT_AUTHOR_EMAIL:-${GH_USER:-herald}@users.noreply.github.com}" \
          commit -q -m "feat: Herald — Railway deployment template for a self-hosted AI agent"
  ok "created a fresh repository with an initial commit"
else
  ok "existing git repository ($(git log --oneline -1 2>/dev/null || echo 'no commits yet'))"
fi

# Uncommitted work would silently not be published.
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
  warn "you have uncommitted changes; they will NOT be published"
  git status --short | sed 's/^/    /' >&2
  say "  ${DIM}commit them first, or re-run after committing${RST}"
fi

# ── 4. Create the repository and push ────────────────────────────────────────
say ""
if [[ -n "$GH_USER" ]] && gh repo view "${GH_USER}/${REPO_NAME}" >/dev/null 2>&1; then
  warn "${GH_USER}/${REPO_NAME} already exists — not creating it again"
  if git remote get-url origin >/dev/null 2>&1; then
    ok "pushing to the existing 'origin' remote"
    run git push -u origin HEAD
  else
    run git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"
    run git push -u origin HEAD
  fi
else
  ok "creating ${GH_USER:+${GH_USER}/}${REPO_NAME} and pushing"
  run gh repo create "$REPO_NAME" "$VISIBILITY" \
      --description "Herald — Railway deployment template for a private self-hosted AI agent" \
      --source=. --remote=origin --push
fi

# ── 5. Optional: open the repo ───────────────────────────────────────────────
say ""
if [[ "$DRY_RUN" == true ]]; then
  say "  ${YLW}dry run — nothing was created or pushed${RST}"
else
  ok "done — https://github.com/${GH_USER:+${GH_USER}/}${REPO_NAME}"
  say ""
  say "  Next: Railway → New Project → Deploy from GitHub repo → ${REPO_NAME}"
  say "        then add a volume at /opt/data and set your provider + bot variables."
  say "        Details: README.md and docs/DEPLOY.md"
fi
say ""
