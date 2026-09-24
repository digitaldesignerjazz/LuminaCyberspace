#!/usr/bin/env bash
# Nested systemd: this host boots tini, so systemd runs in a PID namespace.
set -euo pipefail
if pgrep -x systemd >/dev/null 2>&1; then
  echo "nested systemd already running pid=$(pgrep -n -x systemd)"
  exit 0
fi
nohup sudo unshare --pid --fork --mount-proc \
  env container=docker SYSTEMD_LOG_TARGET=journal \
  /lib/systemd/systemd --system --unit=multi-user.target \
  >/tmp/systemd-nested.log 2>&1 &
sleep 2
pgrep -x systemd >/dev/null
echo "nested systemd started pid=$(pgrep -n -x systemd)"
