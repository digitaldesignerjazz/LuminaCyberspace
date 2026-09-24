#!/usr/bin/env bash
# Connect Hannover Ygg to Lumina (201:e68a:5e25:166f:4bf9:7b75:5d76:5c2b).
# This host has no systemd: restart is the live yggdrasil.conf daemon, not systemctl.
# SKIP_RESTART=1  → ping only
set -euo pipefail
LUMINA_YGG="201:e68a:5e25:166f:4bf9:7b75:5d76:5c2b"
HUB_CONF="${HUB_CONF:-/workspace/lumina-state/yggdrasil.conf}"
SOCK="${YGG_ADMIN:-unix:///var/run/yggdrasil/yggdrasil.sock}"
LOG="${YGG_LOG:-/workspace/lumina-state/ygg-hannover.log}"

hannover_pids() {
  python3 -c 'import os
for pid in os.listdir("/proc"):
    if not pid.isdigit():
        continue
    try:
        raw = open("/proc/%s/cmdline" % pid, "rb").read()
    except Exception:
        continue
    args = [x.decode(errors="replace") for x in raw.split(b"\0") if x]
    if len(args) >= 3 and args[0].endswith("yggdrasil") and args[1] == "-useconffile" and args[2].endswith("yggdrasil.conf"):
        print(pid)
'
}

if [ "${SKIP_RESTART:-0}" != "1" ]; then
  echo "== restart yggdrasil =="
  mapfile -t PIDS < <(hannover_pids)
  if [ "${#PIDS[@]}" -gt 0 ]; then
    sudo kill "${PIDS[@]}"
    sleep 1
  fi
  sudo mkdir -p /var/run/yggdrasil
  : >> "$LOG"
  nohup sudo yggdrasil -useconffile "$HUB_CONF" >> "$LOG" 2>&1 &
  sleep 3
  sudo chmod 666 /var/run/yggdrasil/yggdrasil.sock 2>/dev/null || true
  if ! hannover_pids | grep -q .; then
    echo "yggdrasil failed to start" >&2
    tail -20 "$LOG" >&2 || true
    exit 1
  fi
else
  echo "== SKIP_RESTART=1, leaving daemon running =="
  sudo chmod 666 /var/run/yggdrasil/yggdrasil.sock 2>/dev/null || true
fi

echo "== getPeers =="
yggdrasilctl -endpoint="$SOCK" getPeers sort=cost || sudo yggdrasilctl -endpoint="$SOCK" getPeers sort=cost

echo "== ping6 Lumina $LUMINA_YGG =="
if command -v ping6 >/dev/null 2>&1; then
  ping6 -c 3 "$LUMINA_YGG"
else
  ping -6 -c 3 "$LUMINA_YGG"
fi
