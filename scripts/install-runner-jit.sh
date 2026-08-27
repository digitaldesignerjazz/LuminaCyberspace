#!/usr/bin/env bash
# install-runner-jit.sh — Hannover-Primary, Dauerbetrieb per systemd.
# Kein Registration-Token, kein PAT auf dem Node. Holt encoded_jit_config
# über die GitHub-API, registriert den Runner und aktiviert die systemd-Unit
# mit Restart=always (frisches JIT-Config bei jedem Start).
# Aufruf auf Hannover:
#   sudo bash install-runner-jit.sh <Repo-Scope>
# Oder: export GITHUB_PAT=<Repo-Scope> && sudo -E bash install-runner-jit.sh
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
SERVICE_SRC="scripts/hannover-primary.service"
SERVICE_DST="/etc/systemd/system/hannover-primary.service"

if [[ -z "$PAT" ]]; then
  echo "Usage: sudo bash install-runner-jit.sh <Repo-Scope>" >&2
  echo "Oder: export GITHUB_PAT=<Repo-Scope> && sudo -E bash install-runner-jit.sh" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

echo "[1/6] encoded_jit_config von der API holen (Probe)..."
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
echo "JIT-Config erhalten (Probe erfolgreich)."

echo "[2/6] Runner v$RUNNER_VER laden..."
mkdir -p "$RUNNER_DIR" && cd "$RUNNER_DIR"
if [[ ! -x ./run.sh ]]; then
  curl -fsSL -o runner.tgz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz"
  tar xzf runner.tgz
fi

echo "[3/6] Repo-Scope für systemd-Unit hinterlegen..."
install -d -m 700 /etc/hannover-runner
echo "GITHUB_PAT=$PAT" > /etc/hannover-runner/env
chmod 600 /etc/hannover-runner/env

echo "[4/6] systemd-Unit installieren..."
# Service-Datei aus dem geklonten Repo, Fallback auf Inline-Version
if [[ -f "$SERVICE_SRC" ]]; then
  cp "$SERVICE_SRC" "$SERVICE_DST"
else
  cat > "$SERVICE_DST" <<'UNIT'
[Unit]
Description=Hannover-Primary GitHub Actions Runner (JIT, Dauerbetrieb)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/actions-runner
EnvironmentFile=-/etc/hannover-runner/env
Environment=RUNNER_ALLOW_RUNASROOT=1
ExecStartPre=/bin/bash -c 'curl -sS -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_PAT}" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" https://api.github.com/repos/digitaldesignerjazz/LuminaCyberspace/actions/runners/generate-jitconfig -d '\''{"name":"hannover-primary","runner_group_id":1,"labels":["self-hosted","linux","x64","hannover"],"work_folder":"_work"}'\'' | sed -n '\''s/.*"encoded_jit_config"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'\'' > /tmp/jitconfig'
ExecStart=/opt/actions-runner/run.sh --jitconfig /tmp/jitconfig
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
fi
systemctl daemon-reload

echo "[5/6] Dienst aktivieren und starten..."
systemctl enable hannover-primary.service
systemctl restart hannover-primary.service
sleep 4

echo "[6/6] Status..."
if systemctl is-active --quiet hannover-primary.service; then
  echo "Dauerbetrieb aktiv: hannover-primary.service läuft."
  systemctl --no-pager --full status hannover-primary.service | head -n 12
else
  echo "Dienst nicht aktiv. Log:" >&2
  journalctl -u hannover-primary.service -n 30 --no-pager >&2 || true
  exit 1
fi

echo "Fertig. Runner $RUNNER_NAME ist im Dauerbetrieb."
