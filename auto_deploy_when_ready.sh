#!/usr/bin/env bash
set -e

echo "[$(date)] Waiting for pull_gemma26b container to finish downloading weights..."
DOCKER_HOST=unix:///var/run/docker.sock docker wait pull_gemma26b

echo "[$(date)] Container exited. Starting servable setup..."
/home/df/AI_performance/setup_gemma26b.sh

echo "[$(date)] Verification check against OVMS config endpoint..."
sleep 5
curl -s http://localhost:8000/v1/config | python3 -m json.tool || true

echo "[$(date)] All Gemma 4 26B deployment steps completed!"
