#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TAG="${1:-1.0.0}"
MODULES=(eureka-server gateway demo-service-a demo-service-b)

echo "Building Docker images with tag ${TAG} ..."
for module in "${MODULES[@]}"; do
  image="eureka-pro/${module}:${TAG}"
  echo "-> ${image}"
  docker build \
    --build-arg MODULE="${module}" \
    -t "${image}" \
    -f Dockerfile \
    .
done

echo
echo "Done. Images:"
docker images | grep eureka-pro || true
