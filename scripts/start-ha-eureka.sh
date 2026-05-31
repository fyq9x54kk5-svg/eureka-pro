#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

JAR="$ROOT_DIR/eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar"
if [ ! -f "$JAR" ]; then
  mvn -q -DskipTests -pl eureka-server -am package
fi

echo "Starting Eureka peer1 on :8761 ..."
java -jar "$JAR" --spring.profiles.active=peer1 &
PEER1_PID=$!

sleep 8

echo "Starting Eureka peer2 on :8762 ..."
java -jar "$JAR" --spring.profiles.active=peer2 &
PEER2_PID=$!

echo "peer1 pid=$PEER1_PID, peer2 pid=$PEER2_PID"
echo "Dashboard: http://localhost:8761  http://localhost:8762"
wait
