#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# اجرای محلی X4G (بدون Docker)
#   ./run-local.sh                 → اجرا روی پورت 8000
#   PORT=9000 ./run-local.sh       → اجرا روی پورت دلخواه
#   ADMIN_PASSWORD='...' ./run-local.sh
#
# نکته: روی Railway نیازی به این فایل نیست؛ همان Dockerfile/CMD استفاده می‌شود.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")"

PORT="${PORT:-8000}"
export PORT
export DATA_DIR="${DATA_DIR:-$(pwd)/data}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-X4GKING}"
# دامنه‌ای که لینک‌های کانفیگ با آن ساخته می‌شوند (اگر خالی باشد از هدر Host درخواست خوانده می‌شود)
export RAILWAY_PUBLIC_DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-localhost}"
export PYTHONUNBUFFERED=1

# ساخت venv و نصب وابستگی‌ها در اولین اجرا
if [ ! -x ".venv/bin/python" ]; then
  echo "→ ساخت virtualenv و نصب وابستگی‌ها..."
  python3 -m venv .venv
  .venv/bin/pip install --quiet --upgrade pip
  .venv/bin/pip install --quiet -r requirements.txt
fi

mkdir -p "$DATA_DIR"
echo "→ X4G روی http://0.0.0.0:${PORT}  (DATA_DIR=${DATA_DIR})"
exec .venv/bin/python main.py
