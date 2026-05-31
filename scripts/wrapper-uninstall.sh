#!/usr/bin/env bash
set -euo pipefail

# Wrapper 卸载脚本

INSTALL_DIR="/opt/eureka-pro-wrapper"

echo "=========================================="
echo "卸载 Java Service Wrapper 部署"
echo "=========================================="
echo

if [ "$EUID" -ne 0 ]; then
  echo "错误: 请以 root 权限运行此脚本 (sudo $0)"
  exit 1
fi

# 1. 停止所有服务
echo "步骤 1: 停止所有服务..."
for service in eureka-peer1 eureka-peer2 gateway demo-service-a demo-service-b; do
  systemctl stop "${service}" 2>/dev/null || true
  systemctl disable "${service}" 2>/dev/null || true
done
echo

# 2. 删除 systemd 服务文件
echo "步骤 2: 删除 systemd 服务文件..."
for service in eureka-peer1 eureka-peer2 gateway demo-service-a demo-service-b; do
  rm -f "/etc/systemd/system/${service}.service"
done
systemctl daemon-reload
echo

# 3. 删除安装目录
echo "步骤 3: 删除安装目录..."
rm -rf "${INSTALL_DIR}"
echo

echo "=========================================="
echo "卸载完成！"
echo "=========================================="
