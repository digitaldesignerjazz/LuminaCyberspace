#!/usr/bin/env bash
# Join this node to Headscale as the Nexus WireGuard underlay.
# Usage: HEADSCALE_URL=... TS_AUTHKEY=... bash 02-tailscale-underlay.sh
set -euo pipefail

HEADSCALE_URL="${HEADSCALE_URL:-}"
TS_AUTHKEY="${TS_AUTHKEY:-}"
TS_HOSTNAME="${TS_HOSTNAME:-hannover}"

if [[ -z "$HEADSCALE_URL" || -z "$TS_AUTHKEY" ]]; then
  echo "usage: HEADSCALE_URL=<url> TS_AUTHKEY=<key> $0" >&2
  exit 1
fi

if [[ "$TS_AUTHKEY" == *"…"* || "$TS_AUTHKEY" == *"...*" ]]; then
  echo "TS_AUTHKEY looks like a placeholder" >&2
  exit 1
fi

install_tailscale() {
  if command -v tailscale >/dev/null 2>&1 && command -v tailscaled >/dev/null 2>&1; then
    return 0
  fi
  echo "installing tailscale"
  curl -fsSL https://tailscale.com/install.sh | sh
}

start_tailscaled() {
  if pgrep -x tailscaled >/dev/null 2>&1; then
    echo "ok tailscaled already running"
    return 0
  fi
  mkdir -p /var/lib/tailscale /var/run/tailscale
  if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    systemctl enable --now tailscaled 2>/dev/null || true
    sleep 1
  fi
  if pgrep -x tailscaled >/dev/null 2>&1; then
    echo "ok tailscaled via systemd"
    return 0
  fi
  nohup tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    --tun=tailscale0 \
    >/var/log/tailscaled.log 2>&1 &
  sleep 2
  if ! pgrep -x tailscaled >/dev/null 2>&1; then
    echo "FAILED tailscaled" >&2
    tail -20 /var/log/tailscaled.log >&2 || true
    exit 1
  fi
  echo "ok tailscaled"
}

echo "login-server: $HEADSCALE_URL"
echo "hostname: $TS_HOSTNAME"

install_tailscale
start_tailscaled

# Do not print the key.
tailscale up \
  --login-server="$HEADSCALE_URL" \
  --authkey="$TS_AUTHKEY" \
  --hostname="$TS_HOSTNAME" \
  --accept-routes \
  --accept-dns=false \
  --reset

echo "--- status ---"
tailscale status || true
echo "--- ips ---"
tailscale ip || true
