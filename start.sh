#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"

echo "Starting OpenVINO Model Server (TinyLlama 1.1B)..."
docker compose up -d

echo "Waiting for OVMS to be ready on port 8000..."
until curl -s http://127.0.0.1:8000/v1/config >/dev/null 2>&1; do
  sleep 1
done

echo "OpenVINO Model Server is ready!"
echo "REST / OpenAI API: http://localhost:8000/v3/chat/completions"
echo "gRPC API:          localhost:9001"
