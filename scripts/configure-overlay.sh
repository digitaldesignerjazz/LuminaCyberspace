#!/usr/bin/env bash
# configure-overlay.sh — apply Hannover hub config, preserve live PrivateKey.
# Run on the Hannover node:  sudo bash configure-overlay.sh [config]
set -euo pipefail

CONF_SRC="${1:-./configs/yggdrasil-hannover.conf}"
CONF_DST="/etc/yggdrasil/yggdrasil.conf"
BACKUP_DIR="/etc/yggdrasil/backups"
BACKUP="$BACKUP_DIR/yggdrasil.conf.bak.$(date +%Y%m%d%H%M%S)"

if [[ ! -f "$CONF_SRC" ]]; then
  echo "Config not found: $CONF_SRC" >&2
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

install -d -m 755 /etc/yggdrasil
install -d -m 700 "$BACKUP_DIR"

if [[ -f "$CONF_DST" ]]; then
  cp -a "$CONF_DST" "$BACKUP"
  echo "Backup: $BACKUP"
fi

# Preserve the live PrivateKey from the existing config if present.
LIVE_KEY=""
if [[ -f "$CONF_DST" ]] && grep -q 'PrivateKey' "$CONF_DST"; then
  LIVE_KEY=$(grep -E '^\s*PrivateKey' "$CONF_DST" | head -1)
fi

{
  if [[ -n "$LIVE_KEY" ]]; then
    echo "$LIVE_KEY"
    echo ""
  fi
  cat "$CONF_SRC"
} > "$CONF_DST"

chmod 600 "$CONF_DST"

echo "Config written to $CONF_DST"

if systemctl list-unit-files | grep -q '^yggdrasil.service'; then
  systemctl restart yggdrasil
  echo "yggdrasil.service restarted."
else
  echo "No systemd unit found — restart the daemon manually."
fi

sleep 2
echo "=== Status report ==="
if command -v yggdrasilctl >/dev/null 2>&1; then
  yggdrasilctl getSelf || true
  yggdrasilctl getPeers sort=cost || true
  yggdrasilctl getTree || true
fi
systemctl is-active yggdrasil 2>/dev/null || true
