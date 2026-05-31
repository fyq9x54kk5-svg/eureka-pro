#!/usr/bin/env bash
set -euo pipefail

# Wrapper 服务管理脚本
# 用于快速启动、停止、重启所有服务

INSTALL_DIR="/opt/eureka-pro-wrapper"

usage() {
  echo "用法: $0 {start|stop|restart|status|logs|env} [service-name]"
  echo
  echo "服务名称:"
  echo "  eureka-peer1    - Eureka Server Peer 1 (8761)"
  echo "  eureka-peer2    - Eureka Server Peer 2 (8762)"
  echo "  demo-service-a  - Demo Service A (8081)"
  echo "  demo-service-b  - Demo Service B (8082)"
  echo "  gateway         - API Gateway (8080)"
  echo "  all             - 所有服务"
  echo
  echo "示例:"
  echo "  $0 start all"
  echo "  $0 stop eureka-peer1"
  echo "  $0 status gateway"
  echo "  $0 logs eureka-peer1"
  echo "  $0 env gateway        # 查看环境变量配置"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

ACTION="$1"
SERVICE="${2:-all}"

SERVICES=("eureka-peer1" "eureka-peer2" "demo-service-a" "demo-service-b" "gateway")

if [ "$SERVICE" != "all" ]; then
  # 验证服务名称
  if [[ ! " ${SERVICES[@]} " =~ " ${SERVICE} " ]]; then
    echo "错误: 未知的服务名称 '${SERVICE}'"
    usage
  fi
  SERVICES=("$SERVICE")
fi

case "$ACTION" in
  start)
    echo "启动服务: ${SERVICES[*]}"
    for svc in "${SERVICES[@]}"; do
      echo "  -> 启动 ${svc}..."
      sudo systemctl start "${svc}"
      sleep 3
    done
    echo "完成"
    ;;

  stop)
    echo "停止服务: ${SERVICES[*]}"
    for svc in "${SERVICES[@]}"; do
      echo "  -> 停止 ${svc}..."
      sudo systemctl stop "${svc}"
    done
    echo "完成"
    ;;

  restart)
    echo "重启服务: ${SERVICES[*]}"
    for svc in "${SERVICES[@]}"; do
      echo "  -> 重启 ${svc}..."
      sudo systemctl restart "${svc}"
      sleep 3
    done
    echo "完成"
    ;;

  status)
    echo "服务状态:"
    echo "=========================================="
    for svc in "${SERVICES[@]}"; do
      echo
      echo "[${svc}]"
      sudo systemctl status "${svc}" --no-pager -l || true
      echo "------------------------------------------"
    done
    ;;

  logs)
    if [ "$SERVICE" == "all" ]; then
      echo "错误: 查看日志时必须指定具体服务名称"
      usage
    fi
    echo "查看 ${SERVICE} 的实时日志 (Ctrl+C 退出):"
    echo "=========================================="
    tail -f "${INSTALL_DIR}/logs/${SERVICE}.log"
    ;;

  env)
    if [ "$SERVICE" == "all" ]; then
      echo "错误: 查看环境变量时必须指定具体服务名称"
      usage
    fi
    echo "${SERVICE} 的环境变量配置:"
    echo "=========================================="
    grep "^set\." "${INSTALL_DIR}/conf/wrapper-${SERVICE}.conf" | sed 's/set\./export /'
    echo
    echo "提示: 这些变量会在服务启动时自动注入到 JVM 环境中"
    ;;

  *)
    echo "错误: 未知操作 '${ACTION}'"
    usage
    ;;
esac
