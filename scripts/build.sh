#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building eureka-pro..."
mvn -q -DskipTests package

echo
echo "=== 单节点模式 ==="
echo "  java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar"
echo
echo "=== 高可用双节点模式（推荐）==="
echo "  java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar --spring.profiles.active=peer1"
echo "  java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar --spring.profiles.active=peer2"
echo
echo "=== 业务服务 ==="
echo "  java -jar gateway/target/gateway-1.0.0-SNAPSHOT.jar"
echo "  java -jar demo-service-a/target/demo-service-a-1.0.0-SNAPSHOT.jar"
echo "  java -jar demo-service-b/target/demo-service-b-1.0.0-SNAPSHOT.jar"
echo
echo "Verify:"
echo "  Eureka dashboard: http://localhost:8761 (admin/admin123)"
echo "  Gateway -> A:     curl http://localhost:8080/api/a/hello"
echo "  Gateway -> B:     curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a"
