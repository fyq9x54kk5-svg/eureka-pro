#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TAG="${1:-1.0.0}"
K8S_DIR="$ROOT_DIR/deploy/k8s"

bash "$ROOT_DIR/scripts/docker-build.sh" "$TAG"

if command -v kubectl >/dev/null 2>&1; then
  if kubectl config current-context >/dev/null 2>&1; then
    echo "Loading images into kind cluster (if applicable) ..."
    if kubectl config current-context 2>/dev/null | grep -q kind; then
      kind load docker-image "eureka-pro/eureka-server:${TAG}" 2>/dev/null || true
      kind load docker-image "eureka-pro/gateway:${TAG}" 2>/dev/null || true
      kind load docker-image "eureka-pro/demo-service-a:${TAG}" 2>/dev/null || true
      kind load docker-image "eureka-pro/demo-service-b:${TAG}" 2>/dev/null || true
    fi
  fi
fi

echo "Applying Kubernetes manifests ..."
kubectl apply -k "$K8S_DIR"

echo
echo "Waiting for eureka-server pods ..."
kubectl -n eureka-pro rollout status statefulset/eureka-server --timeout=300s

echo
echo "Waiting for gateway ..."
kubectl -n eureka-pro rollout status deployment/gateway --timeout=180s

echo
echo "Access (NodePort):"
echo "  Gateway:  http://localhost:30080"
echo "  Eureka:   http://localhost:30761  (admin/admin123)"
echo
echo "Verify:"
echo "  curl http://localhost:30080/api/a/hello"
echo "  curl -H 'X-Auth-Token: gateway-token' http://localhost:30080/api/b/call-a"
echo
echo "Status:"
kubectl -n eureka-pro get pods,svc
