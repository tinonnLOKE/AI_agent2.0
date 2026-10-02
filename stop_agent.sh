#!/usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "Stopping TrueForge agent harness..."
if [ -f "$DIR/.trueforge.pid" ]; then
  PID=$(cat "$DIR/.trueforge.pid")
  if kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
    echo "✔ Stopped TrueForge process (PID: $PID)."
  fi
  rm -f "$DIR/.trueforge.pid"
fi

# Fallback: kill any remaining trueforge node processes
pkill -f "trueforge" 2>/dev/null || true
echo "✔ TrueForge stopped."

if [ "$1" == "--all" ]; then
  echo "Stopping OpenVINO Model Server..."
  ./stop.sh
fi
