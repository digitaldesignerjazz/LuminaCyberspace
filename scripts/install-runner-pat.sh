#!/usr/bin/env bash
# install-runner-pat.sh — self-hosted Runner ohne manuelles Registration-Token.
# Holt das Token selbst über die GitHub-API mit einem PAT (repo-Scope).
# Auf Hannover:  sudo bash install-runner-pat.sh <PAT>
set -euo pipefail

PAT="${1:-${GITHUB_PAT:-}}"
REPO_URL="https://github.com/digitaldesignerjazz/LuminaCyberspace"
RUNNER_DIR="/opt/actions-runner"
RUNNER_VER="2.323.0"
RUNNER_NAME="hannover-primary"
LABELS="self-hosted,linux,x64,hannover"

if [[ -z "$PAT" ]]; then
  echo "Usage: sudo bash install-runner-pat.sh <PAT>" >&2
  echo "Oder: export GITHUB_PAT=<PAT> && sudo -E bash install-runner-pat.sh" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

echo "[1/5] Registration-Token von der API holen..."
TOKEN_JSON=$(curl -sS -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/digitaldesignerjazz/LuminaCyberspace/actions/runners/registration-token)

TOKEN=$(echo "$TOKEN_JSON" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
if [[ -z "$TOKEN" ]]; then
  echo "Token konnte nicht geholt werden:" >&2
  echo "$TOKEN_JSON" >&2
  exit 1
fi
echo "Token erhalten (läuft in einer Stunde ab)."

echo "[2/5] Runner v$RUNNER_VER laden..."
mkdir -p "$RUNNER_DIR" && cd "$RUNNER_DIR"
curl -fsSL -o runner.tgz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz"
tar xzf runner.tgz

echo "[3/5] Registrieren als $RUNNER_NAME..."
export RUNNER_ALLOW_RUNASROOT=1
./config.sh --url "$REPO_URL" \
  --token "$TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$LABELS" \
  --work _work --unattended --replace

echo "[4/5] Als Dienst installieren..."
./svc.sh install
./svc.sh start

echo "[5/5] Status:"
./svc.sh status || true
echo "Fertig. Runner $RUNNER_NAME ist online."
