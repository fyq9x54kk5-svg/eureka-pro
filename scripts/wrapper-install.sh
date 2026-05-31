#!/usr/bin/env bash
set -euo pipefail

# Java Service Wrapper 部署脚本
# 用于在 Linux 系统上将 Eureka Pro 服务包装为系统守护进程

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER_VERSION="3.5.51"
INSTALL_DIR="/opt/eureka-pro-wrapper"

echo "=========================================="
echo "Java Service Wrapper 安装与配置"
echo "=========================================="
echo

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
  echo "错误: 请以 root 权限运行此脚本 (sudo $0)"
  exit 1
fi

# 1. 构建项目
echo "步骤 1: 构建项目..."
cd "$ROOT_DIR"
bash "$ROOT_DIR/scripts/build.sh"
echo

# 2. 下载 Java Service Wrapper
echo "步骤 2: 下载 Java Service Wrapper ${WRAPPER_VERSION}..."
WRAPPER_URL="https://sourceforge.net/projects/wrapper/files/wrapper/${WRAPPER_VERSION}/wrapper-linux-x86-64-${WRAPPER_VERSION}.tar.gz/download"
WRAPPER_TAR="wrapper-linux-x86-64-${WRAPPER_VERSION}.tar.gz"

if [ ! -f "/tmp/${WRAPPER_TAR}" ]; then
  echo "正在下载 Wrapper..."
  curl -L -o "/tmp/${WRAPPER_TAR}" "${WRAPPER_URL}" || {
    echo "警告: 自动下载失败，请手动下载并放置到 /tmp/${WRAPPER_TAR}"
    echo "下载地址: ${WRAPPER_URL}"
    exit 1
  }
fi

# 3. 创建安装目录
echo "步骤 3: 创建安装目录..."
mkdir -p "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}/bin"
mkdir -p "${INSTALL_DIR}/lib"
mkdir -p "${INSTALL_DIR}/conf"
mkdir -p "${INSTALL_DIR}/logs"

# 4. 解压 Wrapper
echo "步骤 4: 解压 Wrapper..."
tar xzf "/tmp/${WRAPPER_TAR}" -C /tmp/
cp /tmp/wrapper-linux-x86-64-${WRAPPER_VERSION}/bin/wrapper "${INSTALL_DIR}/bin/"
cp /tmp/wrapper-linux-x86-64-${WRAPPER_VERSION}/lib/libwrapper.so "${INSTALL_DIR}/lib/"
cp /tmp/wrapper-linux-x86-64-${WRAPPER_VERSION}/lib/wrapper.jar "${INSTALL_DIR}/lib/"
chmod +x "${INSTALL_DIR}/bin/wrapper"
echo

# 5. 复制 JAR 包
echo "步骤 5: 复制应用 JAR 包..."
cp "$ROOT_DIR/eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar" "${INSTALL_DIR}/lib/"
cp "$ROOT_DIR/gateway/target/gateway-1.0.0-SNAPSHOT.jar" "${INSTALL_DIR}/lib/"
cp "$ROOT_DIR/demo-service-a/target/demo-service-a-1.0.0-SNAPSHOT.jar" "${INSTALL_DIR}/lib/"
cp "$ROOT_DIR/demo-service-b/target/demo-service-b-1.0.0-SNAPSHOT.jar" "${INSTALL_DIR}/lib/"
echo

# 6. 为每个服务创建配置文件
echo "步骤 6: 创建 Wrapper 配置文件..."

# Eureka Server Peer 1 配置
cat > "${INSTALL_DIR}/conf/wrapper-eureka-peer1.conf" <<'EOF'
# Java Application
wrapper.java.command=/usr/bin/java

# Java Main class
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp

# Java Classpath
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/eureka-server-1.0.0-SNAPSHOT.jar

# Java Library Path
wrapper.java.library.path.1=../lib

# ============================================
# 环境变量配置 (Environment Variables)
# ============================================

# Spring Profile
set.SPRING_PROFILES_ACTIVE=peer1

# Server Port
set.SERVER_PORT=8761

# Eureka Configuration
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762

# Security Credentials
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

# JVM Memory & GC Settings
wrapper.java.additional.1=-XX:+UseG1GC
wrapper.java.additional.2=-XX:MaxGCPauseMillis=200
wrapper.java.additional.3=-Xms512m
wrapper.java.additional.4=-Xmx1024m

# Initial Java Heap Size (in MB)
wrapper.java.initmemory=512

# Maximum Java Heap Size (in MB)
wrapper.java.maxmemory=1024

# Application parameters
wrapper.app.parameter.1=../lib/eureka-server-1.0.0-SNAPSHOT.jar

# Logging
wrapper.console.format=PM
wrapper.console.loglevel=INFO
wrapper.logfile=../logs/eureka-peer1.log
wrapper.logfile.format=LPTM
wrapper.logfile.loglevel=INFO
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5

# Service Name
wrapper.name=eureka-peer1
wrapper.displayname=Eureka Server Peer 1
wrapper.description=Eureka Service Registry - Peer 1 (Port 8761)

# Mode
wrapper.mode=console

# PID File
wrapper.pidfile=../logs/eureka-peer1.pid

# Timeout
wrapper.startup.timeout=300
wrapper.shutdown.timeout=60
EOF

# Eureka Server Peer 2 配置
cat > "${INSTALL_DIR}/conf/wrapper-eureka-peer2.conf" <<'EOF'
wrapper.java.command=/usr/bin/java
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/eureka-server-1.0.0-SNAPSHOT.jar
wrapper.java.library.path.1=../lib

# Environment Variables
set.SPRING_PROFILES_ACTIVE=peer2
set.SERVER_PORT=8762
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

wrapper.java.additional.1=-XX:+UseG1GC
wrapper.java.additional.2=-XX:MaxGCPauseMillis=200
wrapper.java.additional.3=-Xms512m
wrapper.java.additional.4=-Xmx1024m
wrapper.java.initmemory=512
wrapper.java.maxmemory=1024
wrapper.app.parameter.1=../lib/eureka-server-1.0.0-SNAPSHOT.jar
wrapper.console.format=PM
wrapper.console.loglevel=INFO
wrapper.logfile=../logs/eureka-peer2.log
wrapper.logfile.format=LPTM
wrapper.logfile.loglevel=INFO
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5
wrapper.name=eureka-peer2
wrapper.displayname=Eureka Server Peer 2
wrapper.description=Eureka Service Registry - Peer 2 (Port 8762)
wrapper.mode=console
wrapper.pidfile=../logs/eureka-peer2.pid
wrapper.startup.timeout=300
wrapper.shutdown.timeout=60
EOF

# Gateway 配置
cat > "${INSTALL_DIR}/conf/wrapper-gateway.conf" <<'EOF'
wrapper.java.command=/usr/bin/java
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/gateway-1.0.0-SNAPSHOT.jar
wrapper.java.library.path.1=../lib

# Environment Variables
set.SPRING_PROFILES_ACTIVE=default
set.SERVER_PORT=8080
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123
set.EUREKA_PRO_GATEWAY_AUTH_ENABLED=true
set.EUREKA_PRO_GATEWAY_AUTH_TOKEN=gateway-token

wrapper.java.additional.1=-XX:+UseG1GC
wrapper.java.additional.2=-XX:MaxGCPauseMillis=200
wrapper.java.additional.3=-Xms512m
wrapper.java.additional.4=-Xmx1024m
wrapper.java.initmemory=512
wrapper.java.maxmemory=1024
wrapper.app.parameter.1=../lib/gateway-1.0.0-SNAPSHOT.jar
wrapper.console.format=PM
wrapper.console.loglevel=INFO
wrapper.logfile=../logs/gateway.log
wrapper.logfile.format=LPTM
wrapper.logfile.loglevel=INFO
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5
wrapper.name=gateway
wrapper.displayname=API Gateway
wrapper.description=Spring Cloud Gateway (Port 8080)
wrapper.mode=console
wrapper.pidfile=../logs/gateway.pid
wrapper.startup.timeout=300
wrapper.shutdown.timeout=60
EOF

# Demo Service A 配置
cat > "${INSTALL_DIR}/conf/wrapper-demo-a.conf" <<'EOF'
wrapper.java.command=/usr/bin/java
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/demo-service-a-1.0.0-SNAPSHOT.jar
wrapper.java.library.path.1=../lib

# Environment Variables
set.SPRING_PROFILES_ACTIVE=default
set.SERVER_PORT=8081
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

wrapper.java.additional.1=-XX:+UseG1GC
wrapper.java.additional.2=-XX:MaxGCPauseMillis=200
wrapper.java.additional.3=-Xms256m
wrapper.java.additional.4=-Xmx512m
wrapper.java.initmemory=256
wrapper.java.maxmemory=512
wrapper.app.parameter.1=../lib/demo-service-a-1.0.0-SNAPSHOT.jar
wrapper.console.format=PM
wrapper.console.loglevel=INFO
wrapper.logfile=../logs/demo-service-a.log
wrapper.logfile.format=LPTM
wrapper.logfile.loglevel=INFO
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5
wrapper.name=demo-service-a
wrapper.displayname=Demo Service A
wrapper.description=Demo Microservice A (Port 8081)
wrapper.mode=console
wrapper.pidfile=../logs/demo-service-a.pid
wrapper.startup.timeout=300
wrapper.shutdown.timeout=60
EOF

# Demo Service B 配置
cat > "${INSTALL_DIR}/conf/wrapper-demo-b.conf" <<'EOF'
wrapper.java.command=/usr/bin/java
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/demo-service-b-1.0.0-SNAPSHOT.jar
wrapper.java.library.path.1=../lib

# Environment Variables
set.SPRING_PROFILES_ACTIVE=default
set.SERVER_PORT=8082
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

wrapper.java.additional.1=-XX:+UseG1GC
wrapper.java.additional.2=-XX:MaxGCPauseMillis=200
wrapper.java.additional.3=-Xms256m
wrapper.java.additional.4=-Xmx512m
wrapper.java.initmemory=256
wrapper.java.maxmemory=512
wrapper.app.parameter.1=../lib/demo-service-b-1.0.0-SNAPSHOT.jar
wrapper.console.format=PM
wrapper.console.loglevel=INFO
wrapper.logfile=../logs/demo-service-b.log
wrapper.logfile.format=LPTM
wrapper.logfile.loglevel=INFO
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5
wrapper.name=demo-service-b
wrapper.displayname=Demo Service B
wrapper.description=Demo Microservice B (Port 8082)
wrapper.mode=console
wrapper.pidfile=../logs/demo-service-b.pid
wrapper.startup.timeout=300
wrapper.shutdown.timeout=60
EOF

echo "配置文件创建完成"
echo

# 7. 创建 systemd 服务文件
echo "步骤 7: 创建 systemd 服务文件..."

for service in eureka-peer1 eureka-peer2 gateway demo-service-a demo-service-b; do
  cat > "/etc/systemd/system/${service}.service" <<EOF
[Unit]
Description=${service} - Managed by Java Service Wrapper
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/bin/wrapper -c ${INSTALL_DIR}/conf/wrapper-${service}.conf
ExecStop=${INSTALL_DIR}/bin/wrapper -c ${INSTALL_DIR}/conf/wrapper-${service}.conf -t
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
done

echo "systemd 服务文件创建完成"
echo

# 8. 重新加载 systemd
echo "步骤 8: 重新加载 systemd 配置..."
systemctl daemon-reload
echo

# 9. 设置权限
echo "步骤 9: 设置文件权限..."
chown -R root:root "${INSTALL_DIR}"
chmod -R 755 "${INSTALL_DIR}/bin"
chmod -R 644 "${INSTALL_DIR}/conf/*.conf"
echo

echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo
echo "服务管理命令："
echo "  启动所有服务:"
echo "    sudo systemctl start eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway"
echo
echo "  停止所有服务:"
echo "    sudo systemctl stop eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway"
echo
echo "  查看状态:"
echo "    sudo systemctl status eureka-peer1"
echo
echo "  开机自启:"
echo "    sudo systemctl enable eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway"
echo
echo "  查看日志:"
echo "    tail -f ${INSTALL_DIR}/logs/eureka-peer1.log"
echo "    journalctl -u eureka-peer1 -f"
echo
echo "访问地址："
echo "  Eureka Peer 1: http://localhost:8761 (admin/admin123)"
echo "  Eureka Peer 2: http://localhost:8762"
echo "  Gateway:       http://localhost:8080"
echo
