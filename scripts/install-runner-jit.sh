#!/usr/bin/env bash
# install-runner-jit.sh — Hannover-Primary per Just-in-Time Config.
# Kein Registration-Token, kein PAT auf dem Node. Holt encoded_jit_config
# über die GitHub-API und startet den Runner mit run.sh --jitconfig.
# Aufruf auf Hannover:
#   sudo bash install-runner-jit.sh <PAT>
# Oder: export GITHUB_PAT=<PAT> && sudo -E bash install-runner-jit.sh
set -euo pipefail

PAT="${1:-${GITHUB_PAT:-}}"
REPO_URL="https://github.com/digitaldesignerjazz/LuminaCyberspace"
OWNER="digitaldesignerjazz"
REPO="LuminaCyberspace"
RUNNER_DIR="/opt/actions-runner"
RUNNER_VER="2.323.0"
RUNNER_NAME="hannover-primary"
LABELS='["self-hosted","linux","x64","hannover"]'
WORK_FOLDER="_work"
RUNNER_GROUP_ID="1"

if [[ -z "$PAT" ]]; then
  echo "Usage: sudo bash install-runner-jit.sh <PAT>" >&2
  echo "Oder: export GITHUB_PAT=<PAT> && sudo -E bash install-runner-jit.sh" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

echo "[1/5] encoded_jit_config von der API holen..."
RESP=$(curl -sS -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -H "Content-Type: application/json" \
  https://api.github.com/repos/$OWNER/$REPO/actions/runners/generate-jitconfig \
  -d "{\"name\":\"$RUNNER_NAME\",\"runner_group_id\":$RUNNER_GROUP_ID,\"labels\":$LABELS,\"work_folder\":\"$WORK_FOLDER\"}")

JIT=$(echo "$RESP" | sed -n 's/.*"encoded_jit_config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
if [[ -z "$JIT" ]]; then
  echo "JIT-Config konnte nicht geholt werden:" >&2
  echo "$RESP" >&2
  exit 1
fi
echo "JIT-Config erhalten."

echo "[2/5] Runner v$RUNNER_VER laden..."
mkdir -p "$RUNNER_DIR" && cd "$RUNNER_DIR"
if [[ ! -x ./run.sh ]]; then
  curl -fsSL -o runner.tgz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz"
  tar xzf runner.tgz
fi

echo "[3/5] JIT-Runner starten (ephemeral, ein Job)..."
export RUNNER_ALLOW_RUNASROOT=1
nohup ./run.sh --jitconfig "$JIT" > /var/log/hannover-primary-runner.log 2>&1 &
echo $! > /var/run/hannover-primary-runner.pid
sleep 3

echo "[4/5] Prüfe Verbindung..."
if grep -q "Connected to GitHub" /var/log/hannover-primary-runner.log 2>/dev/null; then
  echo "Verbunden. Runner $RUNNER_NAME ist online."
else
  echo "Log (Tail):" >&2
  tail -n 20 /var/log/hannover-primary-runner.log >&2 || true
fi

echo "[5/5] Hinweis: JIT-Runner ist ephemeral — nach einem Job deregistriert er sich."
echo "Für Dauerbetrieb: systemd-Unit mit Restart=always und neuem JIT-Fetch pro Start."
echo "Fertig."
