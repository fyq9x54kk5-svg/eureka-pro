#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash "$ROOT_DIR/scripts/docker-build.sh" "${1:-1.0.0}"
docker compose up -d --build

echo
echo "Services:"
echo "  Eureka-1 dashboard: http://localhost:8761  (admin/admin123)"
echo "  Eureka-2 dashboard: http://localhost:8762"
echo "  Gateway:            http://localhost:8080"
echo
echo "Verify:"
echo "  curl http://localhost:8080/api/a/hello"
echo "  curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a"
