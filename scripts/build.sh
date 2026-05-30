#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building eureka-pro..."
mvn -q -DskipTests package

echo
echo "Start services in separate terminals:"
echo "  1) mvn -f eureka-server/pom.xml spring-boot:run"
echo "  2) mvn -f demo-service-a/pom.xml spring-boot:run"
echo "  3) mvn -f demo-service-b/pom.xml spring-boot:run"
echo
echo "Verify:"
echo "  Eureka dashboard: http://localhost:8761"
echo "  Registry summary: http://localhost:8761/admin/registry/summary"
echo "  Service B call A: http://localhost:8082/api/call-a"
