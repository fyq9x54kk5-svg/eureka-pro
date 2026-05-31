#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash "$ROOT_DIR/scripts/build.sh" >/dev/null

echo "Start each service in a separate terminal:"
echo
echo "  # 1-2 Eureka HA"
echo "  java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar --spring.profiles.active=peer1"
echo "  java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar --spring.profiles.active=peer2"
echo
echo "  # 3-5 Business services"
echo "  java -jar gateway/target/gateway-1.0.0-SNAPSHOT.jar"
echo "  java -jar demo-service-a/target/demo-service-a-1.0.0-SNAPSHOT.jar"
echo "  java -jar demo-service-b/target/demo-service-b-1.0.0-SNAPSHOT.jar"
