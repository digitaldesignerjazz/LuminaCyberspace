#!/usr/bin/env bash
#==============================================================================
# Lumina OS – Ollama Client Helper
#==============================================================================
# Simple helper that agents can use to talk to a local Ollama instance.
# Usage:
#   source /usr/lib/lumina/agents/ollama-client.sh
#   ollama_ask "Your prompt here"
#==============================================================================

OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2:1b}"

ollama_available() {
    curl -s --max-time 2 "${OLLAMA_HOST}/api/tags" >/dev/null 2>&1
}

ollama_ask() {
    local prompt="$1"
    local model="${2:-$OLLAMA_MODEL}"

    if ! ollama_available; then
        echo "[ollama-client] Ollama is not reachable at ${OLLAMA_HOST}"
        return 1
    fi

    python3 - "$OLLAMA_HOST" "$model" "$prompt" << 'PY'
import json, sys, urllib.request
host, model, prompt = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(
    host.rstrip("/") + "/api/generate",
    data=json.dumps({"model": model, "prompt": prompt, "stream": False}).encode(),
    headers={"Content-Type": "application/json"},
    method="POST",
)
with urllib.request.urlopen(req, timeout=120) as resp:
    data = json.loads(resp.read().decode())
print(data.get("response", ""), end="")
PY
}

ollama_list_models() {
    curl -s "${OLLAMA_HOST}/api/tags" 2>/dev/null | python3 -c "import sys,json; print('\n'.join(m.get('name','') for m in json.load(sys.stdin).get('models',[])))" 2>/dev/null
}
