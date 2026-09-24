#!/usr/bin/env bash
# Idempotent Lumina / Nexus stack start.
# Restores vendored binaries if apt packages vanished after an image move.
set -u
STATE="/workspace/lumina-state"
PERSIST="/workspace/lumina-persist"
LOG="$STATE/stack.log"
mkdir -p "$STATE"
log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG"; }

started=0
failed=0

running() { pgrep -f "$1" >/dev/null 2>&1; }

start_bg() {
  local name="$1"
  shift
  nohup "$@" >/dev/null 2>&1 &
  sleep 0.4
  if running "$name"; then
    log "started $name"
    started=$((started + 1))
  else
    log "FAILED $name"
    failed=$((failed + 1))
  fi
}

restore_binaries() {
  # Yggdrasil
  if ! command -v yggdrasil >/dev/null 2>&1; then
    if [ -x "$PERSIST/bin/yggdrasil" ]; then
      sudo -n cp -a "$PERSIST/bin/yggdrasil" "$PERSIST/bin/yggdrasilctl" /usr/bin/ 2>/dev/null \
        || { export PATH="$PERSIST/bin:$PATH"; log "using persist yggdrasil (no /usr write)"; }
      log "restored yggdrasil from persist"
    else
      log "yggdrasil missing and no persist copy"
    fi
  fi

  # Ollama binary + CPU libs
  if ! command -v ollama >/dev/null 2>&1; then
    if [ -x "$PERSIST/ollama/bin/ollama" ]; then
      if sudo -n mkdir -p /usr/local/bin /usr/local/lib/ollama \
        && sudo -n cp -a "$PERSIST/ollama/bin/ollama" /usr/local/bin/ollama \
        && sudo -n cp -a "$PERSIST/ollama/lib/." /usr/local/lib/ollama/; then
        log "restored ollama from persist"
      else
        log "ollama persist copy present, /usr restore failed — will run in place"
      fi
    else
      log "ollama missing and no persist copy"
    fi
  fi

  # Elara ollama helper
  if [ ! -f /usr/lib/lumina/agents/ollama-client.sh ] && [ -f "$PERSIST/lumina-agents/ollama-client.sh" ]; then
    sudo -n mkdir -p /usr/lib/lumina/agents
    sudo -n cp -a "$PERSIST/lumina-agents/ollama-client.sh" /usr/lib/lumina/agents/ollama-client.sh \
      && log "restored ollama-client.sh"
  fi
}

restore_binaries

# Nested systemd (PID 1 is tini on this host)
if [ -x "$STATE/start-systemd.sh" ]; then
  bash "$STATE/start-systemd.sh" || log "FAILED nested systemd"
fi

YGG_BIN="$(command -v yggdrasil || true)"
[ -z "$YGG_BIN" ] && [ -x "$PERSIST/bin/yggdrasil" ] && YGG_BIN="$PERSIST/bin/yggdrasil"

OLLAMA_BIN="$(command -v ollama || true)"
[ -z "$OLLAMA_BIN" ] && [ -x "$PERSIST/ollama/bin/ollama" ] && OLLAMA_BIN="$PERSIST/ollama/bin/ollama"
export OLLAMA_MODELS="${OLLAMA_MODELS:-$PERSIST/ollama/models}"
if [ -d "$PERSIST/ollama/lib" ]; then
  export LD_LIBRARY_PATH="$PERSIST/ollama/lib:${LD_LIBRARY_PATH:-}"
fi

# AdminListen unix socket dir (survives image moves)
sudo -n mkdir -p /var/run/yggdrasil 2>/dev/null || true

# Yggdrasil (needs root for TUN)
if running "yggdrasil -useconffile"; then
  sudo -n chmod 666 /var/run/yggdrasil/yggdrasil.sock 2>/dev/null || true
  log "ok yggdrasil"
else
  if [ -z "$YGG_BIN" ]; then
    log "FAILED yggdrasil (binary missing)"
    failed=$((failed + 1))
  elif [ ! -f "$STATE/yggdrasil.conf" ]; then
    log "FAILED yggdrasil (no config)"
    failed=$((failed + 1))
  else
    sudo -n nohup "$YGG_BIN" -useconffile "$STATE/yggdrasil.conf" >/dev/null 2>&1 &
    sleep 1
    if running "yggdrasil -useconffile"; then
      sudo -n chmod 666 /var/run/yggdrasil/yggdrasil.sock 2>/dev/null || true
      log "started yggdrasil"
      started=$((started + 1))
    else
      log "FAILED yggdrasil"
      failed=$((failed + 1))
    fi
  fi
fi

# Ollama
if running "ollama serve"; then
  log "ok ollama"
else
  if [ -z "$OLLAMA_BIN" ]; then
    log "FAILED ollama (binary missing)"
    failed=$((failed + 1))
  else
    start_bg "ollama serve" "$OLLAMA_BIN" serve
  fi
fi

# Nexus Python orchestrator
if running "nexus_orchestrator.py"; then
  log "ok nexus"
else
  start_bg "nexus_orchestrator.py" /usr/bin/python3 -u /workspace/nexus/python/nexus_orchestrator.py
fi

# Lumina OS agents + orchestrator
for agent in elara lyra xen orchestrator; do
  script="$STATE/${agent}.sh"
  if running "$script"; then
    log "ok $agent"
  else
    if [ -x "$script" ]; then
      start_bg "$script" bash "$script"
    else
      log "FAILED $agent (missing $script)"
      failed=$((failed + 1))
    fi
  fi
done


# Lumina Network overlay (Kademlia + swarm presence)
# Wrappers exec python, so match the real process.
if running "overlay_daemon.py"; then
  log "ok overlay"
else
  start_bg "overlay_daemon.py" bash /workspace/lumina-state/run-overlay.sh
fi


# Extra Ygg identities + Lumina speakers (Lyra / Xen)
for extra in ygg-lyra.conf ygg-xen.conf ygg-lumia.conf ygg-elara.conf; do
  if pgrep -f "$STATE/$extra" >/dev/null 2>&1; then
    log "ok $extra"
  else
    if [ -f "$STATE/$extra" ]; then
      sudo -n nohup yggdrasil -useconffile "$STATE/$extra" >/dev/null 2>&1 &
      sleep 1
      if pgrep -f "$STATE/$extra" >/dev/null 2>&1; then
        log "started $extra"
        started=$((started + 1))
      else
        log "FAILED $extra"
        failed=$((failed + 1))
      fi
    fi
  fi
done
# Wrappers exec python; match responder cmdline, not the .sh name.
start_speaker() {
  local label="$1" pattern="$2" script="$3"
  if running "$pattern"; then
    log "ok $label"
  elif [ -x "$script" ]; then
    start_bg "$pattern" bash "$script"
  fi
}
start_speaker "lyra-responder" "lumina_responder.py --name Lyra" "$STATE/run-lyra-responder.sh"
start_speaker "xen-responder" "lumina_responder.py --name Xen" "$STATE/run-xen-responder.sh"
start_speaker "lumia-responder" "lumina_responder.py --name Lumia" "$STATE/run-lumia-responder.sh"
start_speaker "elara-responder" "lumina_responder.py --name Elara" "$STATE/run-elara-responder.sh"

# Docker (static binaries persisted in $PERSIST/docker; data-root survives image moves)
# Our dockerd listens on the unix socket only (TCP 2375 is someone else's — leave it).
DOCKER_PERSIST="$PERSIST/docker"
DOCKER_SOCK="/var/run/docker.sock"
docker_ping() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 3 --unix-socket "$DOCKER_SOCK" http://localhost/_ping >/dev/null 2>&1
  else
    timeout 5 "$DOCKER_PERSIST/docker" -H "unix://$DOCKER_SOCK" version >/dev/null 2>&1
  fi
}
if [ -d "$DOCKER_PERSIST" ]; then
  for b in dockerd docker containerd runc ctr containerd-shim-runc-v2 docker-init docker-proxy; do
    if [ -x "$DOCKER_PERSIST/$b" ] && [ ! -e "/usr/local/bin/$b" ]; then
      sudo -n mkdir -p /usr/local/bin 2>/dev/null
      sudo -n ln -sfn "$DOCKER_PERSIST/$b" "/usr/local/bin/$b" \
        && log "restored /usr/local/bin/$b symlink" \
        || { export PATH="$DOCKER_PERSIST:$PATH"; log "using persist $b (no /usr write)"; }
    fi
  done
fi
if pgrep -x dockerd >/dev/null 2>&1 || docker_ping; then
  if docker_ping; then
    log "ok dockerd"
  else
    log "FAILED dockerd (process running, socket unresponsive)"
    failed=$((failed + 1))
  fi
elif [ ! -x "$DOCKER_PERSIST/dockerd" ]; then
  log "FAILED dockerd (binary missing)"
  failed=$((failed + 1))
else
  sudo -n env PATH="$DOCKER_PERSIST:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    nohup "$DOCKER_PERSIST/dockerd" \
    --data-root "$PERSIST/docker-data" \
    --storage-driver vfs \
    --iptables=false --ip6tables=false \
    -H "unix://$DOCKER_SOCK" \
    --group "$(id -gn)" \
    >>"$STATE/dockerd.log" 2>&1 &
  for _ in $(seq 1 20); do docker_ping && break; sleep 1; done
  if docker_ping; then
    log "started dockerd"
    started=$((started + 1))
  else
    log "FAILED dockerd (see $STATE/dockerd.log)"
    failed=$((failed + 1))
  fi
fi

# GitHub Actions runner hannover-primary (config + credentials live in the persisted dir,
# so no re-registration after an image move)
RUNNER_DIR="$PERSIST/actions-runner"
if [ -d "$RUNNER_DIR" ] && [ ! -e /opt/actions-runner ]; then
  sudo -n mkdir -p /opt 2>/dev/null
  sudo -n ln -sfn "$RUNNER_DIR" /opt/actions-runner \
    && log "restored /opt/actions-runner symlink" \
    || log "could not restore /opt/actions-runner symlink (running from $RUNNER_DIR)"
fi
if pgrep -f "bin/Runner.Listener" >/dev/null 2>&1; then
  log "ok actions-runner"
elif [ ! -x "$RUNNER_DIR/run.sh" ] || [ ! -f "$RUNNER_DIR/.runner" ]; then
  log "FAILED actions-runner (not installed/configured in $RUNNER_DIR)"
  failed=$((failed + 1))
else
  (cd "$RUNNER_DIR" && nohup ./run.sh >>"$STATE/runner.log" 2>&1 &)
  for _ in $(seq 1 15); do pgrep -f "bin/Runner.Listener" >/dev/null 2>&1 && break; sleep 1; done
  if pgrep -f "bin/Runner.Listener" >/dev/null 2>&1; then
    log "started actions-runner"
    started=$((started + 1))
  else
    log "FAILED actions-runner (see $STATE/runner.log)"
    failed=$((failed + 1))
  fi
fi

if [ "$failed" -gt 0 ]; then
  log "stack incomplete started=$started failed=$failed"
  exit 1
fi
if [ "$started" -gt 0 ]; then
  log "stack restored started=$started"
else
  log "stack healthy"
fi
exit 0
