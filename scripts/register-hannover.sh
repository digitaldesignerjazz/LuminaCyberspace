#!/usr/bin/env bash
# Registriert den Hannover-Runner auf Repo-Ebene (digitaldesignerjazz/LuminaCyberspace).
# Labels: self-hosted, linux, x64, lumina, hannover, cyberspace
# Aufruf: sudo bash scripts/register-hannover.sh
set -euo pipefail

REPO="digitaldesignerjazz/LuminaCyberspace"
RUNNER_DIR="/opt/actions-runner"

if [ ! -d "$RUNNER_DIR" ]; then
  echo "Runner-Verzeichnis $RUNNER_DIR nicht gefunden." >&2
  exit 1
fi

cd "$RUNNER_DIR"

echo "Stoppe bestehenden Runner..."
sudo ./svc.sh stop || true

TOKEN=$(gh api -X POST "repos/${REPO}/actions/runners/registration-token" --jq .token)

echo "Registriere Runner 'hannover-primary'..."
sudo ./config.sh --url "https://github.com/${REPO}" \
  --token "$TOKEN" \
  --name hannover-primary \
  --labels self-hosted,linux,x64,lumina,hannover,cyberspace \
  --unattended

echo "Installiere und starte Dienst..."
sudo ./svc.sh install
sudo ./svc.sh start

echo "Runner hannover-primary registriert und gestartet auf ${REPO}."
