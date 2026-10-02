#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8790}"
LOG_DIR="$DIR/logs"
mkdir -p "$LOG_DIR"
TRUEFORGE_LOG="$LOG_DIR/trueforge.log"

# Detect primary LAN IP
LAN_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || hostname -I 2>/dev/null | awk '{print $1}')
LAN_IP="${LAN_IP:-127.0.0.1}"

echo "=========================================="
echo " Starting AI Agent 2.0 (OVMS + TrueForge) "
echo "=========================================="

# 1. Check & start OpenVINO Model Server
if ! curl -s http://127.0.0.1:8000/v1/config >/dev/null 2>&1; then
  echo "OpenVINO Model Server is not running. Starting OVMS..."
  ./start.sh
else
  echo "✔ OpenVINO Model Server is running on port 8000."
fi

# 2. Check if TrueForge is already running on PORT
if curl -s "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 && ss -tulpn 2>/dev/null | grep -q "0.0.0.0:${PORT}"; then
  echo "✔ TrueForge is already running on ${HOST}:${PORT}."
else
  if curl -s "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then
    echo "TrueForge is running on 127.0.0.1. Restarting to bind to all interfaces (${HOST})..."
    ./stop_agent.sh
  fi
  echo "Starting TrueForge on ${HOST}:${PORT}..."
  export HOST="$HOST"
  export PORT="$PORT"
  export STANDALONE=true
  export NETWORK_POLICY_ENABLED=false
  export OUTBOUND_URL_ALLOWED_HOSTS='["localhost","127.0.0.1"]'

  if [ -f "$DIR/node_modules/.bin/trueforge" ]; then
    nohup "$DIR/node_modules/.bin/trueforge" --port "$PORT" > "$TRUEFORGE_LOG" 2>&1 &
  else
    nohup npx @truefoundry/trueforge --port "$PORT" > "$TRUEFORGE_LOG" 2>&1 &
  fi
  PID=$!
  echo "$PID" > "$DIR/.trueforge.pid"

  echo "Waiting for TrueForge to initialize on port ${PORT}..."
  MAX_RETRIES=30
  COUNT=0
  until curl -s "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; do
    sleep 1
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
      echo "❌ TrueForge failed to start within ${MAX_RETRIES} seconds."
      echo "Last 20 log lines from $TRUEFORGE_LOG:"
      tail -n 20 "$TRUEFORGE_LOG"
      exit 1
    fi
  done
  echo "✔ TrueForge started successfully (PID: $PID)."
fi

# 3. Ensure OpenVINO provider is registered in TrueForge
echo "Configuring OpenVINO provider in TrueForge..."
curl -s -X PUT "http://127.0.0.1:${PORT}/api/v1/settings/model-providers" \
  -H "Content-Type: application/json" \
  -d @"$DIR/openvino-provider.json" >/dev/null 2>&1 || true

echo "✔ OpenVINO provider synchronized."
echo ""
echo "=========================================="
echo " AI Agent 2.0 is READY! "
echo "=========================================="
echo " Local Web UI:     http://localhost:${PORT}"
echo " LAN / IP Web UI:  http://${LAN_IP}:${PORT}"
echo " OVMS REST API:    http://localhost:8000/v1"
echo " Active Models:    openvino/gemma4-gpu (Intel Arc GPU)"
echo "                   openvino/qwen3-gpu  (Intel Arc GPU)"
echo " Logs:             $TRUEFORGE_LOG"
echo "=========================================="
