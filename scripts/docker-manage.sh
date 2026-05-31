#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Eureka Pro - Docker Management Script
# Provides easy management of Docker containers
# =============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TAG="${1:-1.0.0}"

usage() {
  echo "用法: $0 {build|up|down|restart|logs|status|clean|prune} [tag]"
  echo
  echo "命令:"
  echo "  build    - 构建所有 Docker 镜像"
  echo "  up       - 启动所有服务（后台运行）"
  echo "  down     - 停止并移除所有容器"
  echo "  restart  - 重启所有服务"
  echo "  logs     - 查看所有服务日志"
  echo "  status   - 查看服务状态"
  echo "  clean    - 清理未使用的镜像和容器"
  echo "  prune    - 深度清理（包括构建缓存）"
  echo
  echo "示例:"
  echo "  $0 build 1.0.0"
  echo "  $0 up"
  echo "  $0 logs"
  echo "  $0 status"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

ACTION="$1"

case "$ACTION" in
  build)
    echo "=========================================="
    echo "构建 Docker 镜像 (Tag: ${TAG})"
    echo "=========================================="
    bash "$ROOT_DIR/scripts/docker-build.sh" "${TAG}"
    ;;

  up)
    echo "=========================================="
    echo "启动 Eureka Pro 服务"
    echo "=========================================="
    
    # 检查是否已构建
    if ! docker image inspect "eureka-pro/eureka-server:${TAG}" >/dev/null 2>&1; then
      echo "镜像未找到，先构建..."
      bash "$ROOT_DIR/scripts/docker-build.sh" "${TAG}"
    fi
    
    docker compose up -d
    
    echo
    echo "✅ 服务启动成功！"
    echo
    echo "访问地址："
    echo "  📊 Eureka Peer 1: http://localhost:8761 (admin/admin123)"
    echo "  📊 Eureka Peer 2: http://localhost:8762"
    echo "  🚪 Gateway:       http://localhost:8080"
    echo
    echo "测试命令："
    echo "  curl http://localhost:8080/api/a/hello"
    echo "  curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a"
    echo
    echo "查看日志: docker compose logs -f"
    echo "查看状态: docker compose ps"
    ;;

  down)
    echo "=========================================="
    echo "停止并移除所有服务"
    echo "=========================================="
    docker compose down
    echo "✅ 服务已停止"
    ;;

  restart)
    echo "=========================================="
    echo "重启所有服务"
    echo "=========================================="
    docker compose restart
    echo "✅ 服务已重启"
    ;;

  logs)
    echo "=========================================="
    echo "实时日志 (Ctrl+C 退出)"
    echo "=========================================="
    docker compose logs -f --tail=100
    ;;

  status)
    echo "=========================================="
    echo "服务状态"
    echo "=========================================="
    docker compose ps
    echo
    echo "资源使用情况："
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
    ;;

  clean)
    echo "=========================================="
    echo "清理未使用的 Docker 资源"
    echo "=========================================="
    
    read -p "确认清理未使用的镜像、容器和网络？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker system prune -f
      echo "✅ 清理完成"
    else
      echo "取消清理"
    fi
    ;;

  prune)
    echo "=========================================="
    echo "深度清理（包括构建缓存）"
    echo "=========================================="
    
    read -p "⚠️  这将删除所有未使用的镜像、容器、网络和构建缓存！确认？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker system prune -a --volumes -f
      echo "✅ 深度清理完成"
    else
      echo "取消清理"
    fi
    ;;

  *)
    echo "错误: 未知操作 '${ACTION}'"
    usage
    ;;
esac
