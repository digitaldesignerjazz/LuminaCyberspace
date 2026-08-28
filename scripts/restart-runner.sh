#!/usr/bin/env bash
# Stoppt und startet den Self-Hosted Runner-Dienst auf dem Hannover-Knoten.
# Aufruf: sudo bash scripts/restart-runner.sh
set -euo pipefail

RUNNER_DIR="/opt/actions-runner"
SERVICE="hannover-primary"

if [ -d "$RUNNER_DIR" ]; then
  cd "$RUNNER_DIR"
  echo "Stoppe Runner in $RUNNER_DIR..."
  sudo ./svc.sh stop || true
  sleep 2
  echo "Starte Runner..."
  sudo ./svc.sh start
  echo "Runner neu gestartet."
  exit 0
fi

if systemctl list-unit-files | grep -q "${SERVICE}"; then
  echo "Stoppe systemd-Unit ${SERVICE}..."
  sudo systemctl stop "${SERVICE}" || true
  sleep 2
  echo "Starte ${SERVICE}..."
  sudo systemctl start "${SERVICE}"
  echo "Dienst ${SERVICE} neu gestartet."
  exit 0
fi

echo "Weder $RUNNER_DIR noch Unit ${SERVICE} gefunden." >&2
exit 1
