#!/usr/bin/env bash
set -e

echo "=== Gemma 4 26B-A4B Deployment Script ==="

MODEL_SRC="/home/df/AI_performance/models/OpenVINO/gemma-4-26b-a4b-it-int4-ov"
SERVABLE_GPU="/home/df/AI_performance/models/servables/gemma4_gpu"
SERVABLE_CPU="/home/df/AI_performance/models/servables/gemma4_cpu"

echo "[1/4] Checking download status..."
if [ -f "$MODEL_SRC/openvino_language_model.binlfs_part" ]; then
    echo "Download is still in progress..."
    exit 1
fi

if [ ! -f "$MODEL_SRC/openvino_language_model.bin" ]; then
    echo "Model file openvino_language_model.bin not found!"
    exit 1
fi

echo "[2/4] Symlinking model files to servable directories..."
mkdir -p "$SERVABLE_GPU" "$SERVABLE_CPU"

cd "$SERVABLE_GPU"
ln -sf ../../OpenVINO/gemma-4-26b-a4b-it-int4-ov/* .
rm -f graph.pbtxt

cd "$SERVABLE_CPU"
ln -sf ../../OpenVINO/gemma-4-26b-a4b-it-int4-ov/* .
rm -f graph.pbtxt

echo "[3/4] Generating MediaPipe execution graphs for GPU and CPU..."
DOCKER_HOST=unix:///var/run/docker.sock docker run --rm -v /home/df/AI_performance/models:/models openvino/model_server:latest-gpu --configure --model_path /models/servables/gemma4_gpu --task text_generation --target_device GPU
DOCKER_HOST=unix:///var/run/docker.sock docker run --rm -v /home/df/AI_performance/models:/models openvino/model_server:latest-gpu --configure --model_path /models/servables/gemma4_cpu --task text_generation --target_device CPU

echo "[4/4] Restarting OVMS container to serve Gemma 4 26B..."
DOCKER_HOST=unix:///var/run/docker.sock docker compose -f /home/df/AI_performance/docker-compose.yml restart ovms

echo "=== Gemma 4 26B Deployment Completed Successfully! ==="
