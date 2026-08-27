#!/usr/bin/env bash
# start-primary.sh — Hannover-Primary online bringen.
# Selbstheilend: installiert den Runner, falls nötig, startet den Dienst,
# wartet auf den ersten erfolgreichen Job und meldet den Status.
# Aufruf auf Hannover:
#   sudo bash scripts/start-primary.sh <Repo-Scope>
set -euo pipefail

PAT="${1:-${GITHUB_PAT:-}}"
REPO_URL="https://github.com/digitaldesignerjazz/LuminaCyberspace"
OWNER="digitaldesignerjazz"
REPO="LuminaCyberspace"
RUNNER_DIR="/opt/actions-runner"
SERVICE="hannover-primary.service"

if [[ -z "$PAT" ]]; then
  echo "Usage: sudo bash scripts/start-primary.sh <Repo-Scope>" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

echo "[1/5] Repo frisch ziehen..."
if [[ -d /opt/LuminaCyberspace/.git ]]; then
  git -C /opt/LuminaCyberspace pull --ff-only
else
  git clone "$REPO_URL" /opt/LuminaCyberspace
fi
cd /opt/LuminaCyberspace

echo "[2/5] Runner installieren (falls nicht vorhanden)..."
if [[ ! -x "$RUNNER_DIR/run.sh" ]]; then
  bash scripts/install-runner-jit.sh "$PAT"
else
  echo "Runner bereits vorhanden."
fi

echo "[3/5] Dienst starten..."
systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl restart "$SERVICE"
sleep 5

if ! systemctl is-active --quiet "$SERVICE"; then
  echo "Dienst nicht aktiv. Log:" >&2
  journalctl -u "$SERVICE" -n 40 --no-pager >&2 || true
  exit 1
fi

echo "[4/5] Warte auf ersten erfolgreichen Job (max 180s)..."
for i in $(seq 1 36); do
  RESP=$(curl -sS -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$OWNER/$REPO/actions/runners")
  BUSY=$(echo "$RESP" | sed -n 's/.*"busy"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p' | head -1)
  if [[ "$BUSY" == "true" ]]; then
    echo "Runner ist busy — Job läuft."
    break
  fi
  sleep 5
done

echo "[5/5] Status..."
systemctl --no-pager --full status "$SERVICE" | head -n 14
echo "---"
curl -sS -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runners" \
  | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/name: \1/p; s/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/status: \1/p; s/.*"busy"[[:space:]]*:[[:space:]]*\(true\|false\).*/busy: \1/p'
echo "Fertig. Hannover-Primary ist online."
