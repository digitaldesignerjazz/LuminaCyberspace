#!/usr/bin/env bash
# Apply Hannover hub Yggdrasil 0.5.x profile + ygg0 nft floor.
# Keeps the existing PrivateKey. Does not touch Blatt configs.
set -euo pipefail
STATE="${STATE:-/workspace/lumina-state}"
HUB="$STATE/yggdrasil.conf"
CANON="$STATE/yggdrasil-hannover.conf"
YGG_BIN="${YGG_BIN:-$(command -v yggdrasil)}"
SOCK="unix:///var/run/yggdrasil/yggdrasil.sock"
LOG="$STATE/ygg-hannover.log"

if [ ! -f "$HUB" ]; then
  echo "missing $HUB" >&2
  exit 1
fi

if [ -f "$CANON" ] && ! cmp -s "$HUB" "$CANON"; then
  cp -a "$HUB" "$HUB.bak-$(date +%Y%m%dT%H%M%S)"
  cp -a "$CANON" "$HUB"
  chmod 600 "$HUB"
fi

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

mapfile -t PIDS < <(hannover_pids)
if [ "${#PIDS[@]}" -gt 0 ]; then
  sudo kill "${PIDS[@]}"
  sleep 1
fi

sudo mkdir -p /var/run/yggdrasil
: >> "$LOG"
nohup sudo "$YGG_BIN" -useconffile "$HUB" >> "$LOG" 2>&1 &
sleep 2
sudo chmod 666 /var/run/yggdrasil/yggdrasil.sock 2>/dev/null || true

if ! hannover_pids | grep -q .; then
  echo "Hannover ygg failed to start" >&2
  tail -20 "$LOG" >&2 || true
  exit 1
fi

if command -v nft >/dev/null 2>&1; then
  sudo nft delete table ip6 ygg0 2>/dev/null || true
  sudo nft add table ip6 ygg0
  sudo nft add chain ip6 ygg0 input "{ type filter hook input priority 0; policy accept; }"
  sudo nft add rule ip6 ygg0 input iifname ygg0 ct state established,related accept
  sudo nft add rule ip6 ygg0 input iifname ygg0 meta l4proto ipv6-icmp accept
  sudo nft add rule ip6 ygg0 input iifname ygg0 udp dport 4242 accept
  sudo nft add rule ip6 ygg0 input iifname ygg0 tcp dport 22 drop
  sudo nft add rule ip6 ygg0 input iifname ygg0 drop
  echo "nft ygg0 floor applied"
else
  echo "WARN: nft not available; ygg0 floor skipped" >&2
fi

echo "=== getSelf ==="
yggdrasilctl -endpoint="$SOCK" getSelf
echo "=== getPeers sort=cost ==="
yggdrasilctl -endpoint="$SOCK" getPeers sort=cost
echo "=== getTree ==="
yggdrasilctl -endpoint="$SOCK" getTree
