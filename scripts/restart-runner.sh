#!/usr/bin/env bash
# restart-runner.sh — Hannover self-hosted Runner neu starten.
# Auf Hannover:  sudo bash restart-runner.sh
set -euo pipefail

RUNNER_DIR="/opt/actions-runner"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

if [[ ! -d "$RUNNER_DIR" ]]; then
  echo "Runner-Verzeichnis $RUNNER_DIR fehlt. Bitte zuerst install-runner-pat.sh ausführen." >&2
  exit 1
fi

cd "$RUNNER_DIR"

echo "[1/3] Runner-Dienst stoppen..."
./svc.sh stop || true

echo "[2/3] Runner-Dienst starten..."
./svc.sh start

echo "[3/3] Status:"
./svc.sh status || true

echo "Fertig. Runner hannover-primary sollte jetzt online sein."
