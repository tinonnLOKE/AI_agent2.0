#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

export DOCKER_HOST="${DOCKER_HOST:-unix:///var/run/docker.sock}"

echo "Stopping OpenVINO Model Server..."
docker compose down
echo "OVMS stopped."
