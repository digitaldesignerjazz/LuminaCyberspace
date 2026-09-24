#!/usr/bin/env bash
#==============================================================================
# Lumina OS – Elara Agent
#==============================================================================
# Elara is the primary interface and system orchestrator of the AI Swarm.
# She uses a local Ollama instance when available.
#==============================================================================

set -euo pipefail

AGENT_NAME="elara"
STATE_DIR="/workspace/lumina-state/agents/${AGENT_NAME}"
LOG_TAG="lumina-elara"
OLLAMA_CLIENT="/usr/lib/lumina/agents/ollama-client.sh"
export OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2:1b}"

mkdir -p "${STATE_DIR}"

log() {
    echo "[$(date -Iseconds)] [${AGENT_NAME}] $*"
    logger -t "${LOG_TAG}" "$*" 2>/dev/null || true
}

# Load Ollama helper if present
if [ -f "${OLLAMA_CLIENT}" ]; then
    # shellcheck source=/dev/null
    source "${OLLAMA_CLIENT}"
else
    log "Warning: ollama-client.sh not found. Running in limited mode."
    ollama_available() { return 1; }
    ollama_ask() { echo "[Elara] Ollama is not available."; }
fi

log "Elara agent starting..."

echo "status=running" > "${STATE_DIR}/status"
echo "started_at=$(date -Iseconds)" >> "${STATE_DIR}/status"
echo "role=personal-assistant-and-orchestrator" >> "${STATE_DIR}/status"

if ollama_available; then
    log "Ollama is reachable. Elara can use local models."
    echo "ollama=available" >> "${STATE_DIR}/status"

    RESPONSE=$(ollama_ask "You are Elara, the intelligent and devoted AI assistant of Lumina OS. Reply with one short friendly sentence in German introducing yourself." 2>/dev/null || true)
    if [ -n "${RESPONSE:-}" ]; then
        log "Self-introduction: ${RESPONSE}"
        echo "last_response=${RESPONSE}" >> "${STATE_DIR}/status"
    fi
else
    log "Ollama is not reachable yet. Elara runs in placeholder mode."
    echo "ollama=unavailable" >> "${STATE_DIR}/status"
fi

log "Elara is online."

# Main loop
while true; do
    echo "last_heartbeat=$(date -Iseconds)" >> "${STATE_DIR}/status"
    sleep 60
done
