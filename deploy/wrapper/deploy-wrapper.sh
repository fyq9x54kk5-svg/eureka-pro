#!/usr/bin/env bash
# =============================================================================
# Eureka Pro - Java Service Wrapper 一键部署脚本
# 用途：在 Linux 服务器上以 Wrapper 方式部署 Eureka Pro 微服务平台
# 使用方法：sudo bash deploy-wrapper.sh [版本号]
# 示例：sudo bash deploy-wrapper.sh 1.0.0
# =============================================================================

set -euo pipefail

# ==================== 配置变量 ====================
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${1:-1.0.0}"
INSTALL_DIR="/opt/eureka-pro-wrapper"
LOG_FILE="/tmp/eureka-pro-wrapper-deploy-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义（用于美化输出）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# ==================== 工具函数 ====================

# 打印信息日志
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# 打印成功日志
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# 打印警告日志
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

# 打印错误日志
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# ==================== 步骤 1：检查系统环境 ====================
check_system() {
    log_info "=========================================="
    log_info "步骤 1: 检查系统环境"
    log_info "=========================================="
    
    # 检查是否以 root 权限运行
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 或 root 用户运行此脚本"
        exit 1
    fi
    
    # 检查操作系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log_info "操作系统: $NAME $VERSION_ID"
    fi
    
    # 检查内存（建议至少 4GB）
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    log_info "系统内存: ${TOTAL_MEM}MB"
    if [ "$TOTAL_MEM" -lt 2048 ]; then
        log_warn "内存不足 2GB，可能导致服务运行不稳定"
    else
        log_success "内存充足: ${TOTAL_MEM}MB"
    fi
    
    # 检查磁盘空间（建议至少 10GB）
    AVAILABLE_DISK=$(df -m /opt | awk 'NR==2 {print $4}')
    log_info "可用磁盘空间: ${AVAILABLE_DISK}MB"
    if [ "$AVAILABLE_DISK" -lt 5120 ]; then
        log_warn "磁盘空间不足 5GB"
    else
        log_success "磁盘空间充足: ${AVAILABLE_DISK}MB"
    fi
    
    log_success "系统环境检查完成"
    echo ""
}

# ==================== 步骤 2：安装 JDK 17 ====================
install_jdk() {
    log_info "=========================================="
    log_info "步骤 2: 安装 JDK 17"
    log_info "=========================================="
    
    # 检查 Java 是否已安装
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        log_info "检测到 Java 版本: $JAVA_VERSION"
        
        if [ "$JAVA_VERSION" -ge 17 ]; then
            log_success "Java 版本满足要求（>= 17）"
            return 0
        else
            log_warn "Java 版本过低，需要安装 Java 17+"
        fi
    fi
    
    # 检测包管理器并安装 JDK 17
    if command -v yum &> /dev/null; then
        # CentOS/RHEL 系统
        log_info "使用 yum 安装 OpenJDK 17..."
        yum install -y java-17-openjdk-devel || yum install -y java-17-openjdk
        
    elif command -v apt-get &> /dev/null; then
        # Ubuntu/Debian 系统
        log_info "使用 apt-get 安装 OpenJDK 17..."
        apt-get update -qq
        apt-get install -y openjdk-17-jdk
    else
        log_error "不支持的包管理器"
        exit 1
    fi
    
    # 验证安装
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        log_success "Java 安装完成: $JAVA_VERSION"
    else
        log_error "Java 安装失败"
        exit 1
    fi
    
    # 设置 JAVA_HOME
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    log_info "JAVA_HOME: $JAVA_HOME"
    
    log_success "JDK 17 安装完成"
    echo ""
}

# ==================== 步骤 3：安装 Maven（如需构建）====================
install_maven() {
    log_info "=========================================="
    log_info "步骤 3: 检查 Maven"
    log_info "=========================================="
    
    if command -v mvn &> /dev/null; then
        MVN_VERSION=$(mvn -version | head -n 1)
        log_success "Maven 已安装: $MVN_VERSION"
    else
        log_info "Maven 未安装，正在安装..."
        
        if command -v yum &> /dev/null; then
            yum install -y maven
        elif command -v apt-get &> /dev/null; then
            apt-get install -y maven
        fi
        
        log_success "Maven 安装完成"
    fi
    
    echo ""
}

# ==================== 步骤 4：构建项目 ====================
build_project() {
    log_info "=========================================="
    log_info "步骤 4: 构建项目"
    log_info "=========================================="
    
    cd "$ROOT_DIR"
    
    # 赋予构建脚本执行权限
    chmod +x scripts/build.sh
    
    # 执行构建
    log_info "开始构建项目（这可能需要几分钟）..."
    bash scripts/build.sh > /tmp/build.log 2>&1
    
    # 检查构建结果
    if [ -f "eureka-server/target/eureka-server-${VERSION}.jar" ]; then
        log_success "项目构建成功"
        ls -lh eureka-server/target/*.jar
    else
        log_error "项目构建失败，请查看 /tmp/build.log"
        cat /tmp/build.log
        exit 1
    fi
    
    log_success "项目构建完成"
    echo ""
}

# ==================== 步骤 5：安装 Java Service Wrapper ====================
install_wrapper() {
    log_info "=========================================="
    log_info "步骤 5: 安装 Java Service Wrapper"
    log_info "=========================================="
    
    # 赋予安装脚本执行权限
    chmod +x scripts/wrapper-install.sh
    
    # 执行安装
    log_info "开始安装 Wrapper（自动下载、配置、创建服务）..."
    bash scripts/wrapper-install.sh 2>&1 | tee -a "$LOG_FILE"
    
    # 验证安装
    if [ -d "$INSTALL_DIR" ]; then
        log_success "Wrapper 安装目录: $INSTALL_DIR"
        ls -la "$INSTALL_DIR"
    else
        log_error "Wrapper 安装失败"
        exit 1
    fi
    
    log_success "Java Service Wrapper 安装完成"
    echo ""
}

# ==================== 步骤 6：配置防火墙 ====================
configure_firewall() {
    log_info "=========================================="
    log_info "步骤 6: 配置防火墙"
    log_info "=========================================="
    
    # 检测防火墙类型并配置
    if command -v firewall-cmd &> /dev/null; then
        # firewalld（CentOS/RHEL）
        log_info "检测到 firewalld，配置端口规则..."
        firewall-cmd --permanent --add-port=8761/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=8762/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=8081/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=8082/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log_success "firewalld 配置完成"
        
    elif command -v ufw &> /dev/null; then
        # ufw（Ubuntu/Debian）
        log_info "检测到 UFW，配置端口规则..."
        ufw allow 8761/tcp 2>/dev/null || true
        ufw allow 8762/tcp 2>/dev/null || true
        ufw allow 8080/tcp 2>/dev/null || true
        ufw allow 8081/tcp 2>/dev/null || true
        ufw allow 8082/tcp 2>/dev/null || true
        log_success "UFW 配置完成"
    else
        log_warn "未检测到防火墙，如需配置请手动执行"
    fi
    
    log_success "防火墙配置完成"
    echo ""
}

# ==================== 步骤 7：启动服务 ====================
start_services() {
    log_info "=========================================="
    log_info "步骤 7: 启动服务"
    log_info "=========================================="
    
    # 赋予管理脚本执行权限
    chmod +x scripts/wrapper-manage.sh
    
    # 按顺序启动服务（Eureka 先启动，其他服务后启动）
    log_info "启动 Eureka Server Peer 1..."
    bash scripts/wrapper-manage.sh start eureka-peer1
    sleep 10
    
    log_info "启动 Eureka Server Peer 2..."
    bash scripts/wrapper-manage.sh start eureka-peer2
    sleep 10
    
    log_info "启动 Demo Service A..."
    bash scripts/wrapper-manage.sh start demo-service-a
    sleep 5
    
    log_info "启动 Demo Service B..."
    bash scripts/wrapper-manage.sh start demo-service-b
    sleep 5
    
    log_info "启动 Gateway..."
    bash scripts/wrapper-manage.sh start gateway
    sleep 5
    
    log_success "所有服务启动命令已执行"
    echo ""
}

# ==================== 步骤 8：设置开机自启 ====================
enable_autostart() {
    log_info "=========================================="
    log_info "步骤 8: 设置开机自启"
    log_info "=========================================="
    
    # 为每个服务设置开机自启
    for service in eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway; do
        systemctl enable "$service" 2>/dev/null || true
        log_info "已启用 $service 开机自启"
    done
    
    log_success "开机自启设置完成"
    echo ""
}

# ==================== 步骤 9：验证部署 ====================
verify_deployment() {
    log_info "=========================================="
    log_info "步骤 9: 验证部署"
    log_info "=========================================="
    
    # 等待服务完全启动
    log_info "等待服务启动（30秒）..."
    sleep 30
    
    # 检查 systemd 服务状态
    log_info "检查服务状态..."
    for service in eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_success "✅ $service 运行正常"
        else
            log_warn "⚠️  $service 未运行"
        fi
    done
    
    # 检查端口监听
    log_info "检查端口监听..."
    if command -v netstat &> /dev/null; then
        netstat -tlnp | grep -E '8761|8762|8080|8081|8082' || true
    elif command -v ss &> /dev/null; then
        ss -tlnp | grep -E '8761|8762|8080|8081|8082' || true
    fi
    
    # 健康检查
    log_info "执行健康检查..."
    if curl -sf http://localhost:8761/actuator/health > /dev/null 2>&1; then
        log_success "✅ Eureka Server (8761) 健康检查通过"
    else
        log_warn "⚠️  Eureka Server (8761) 健康检查失败"
    fi
    
    if curl -sf http://localhost:8080/actuator/health > /dev/null 2>&1; then
        log_success "✅ Gateway (8080) 健康检查通过"
    else
        log_warn "⚠️  Gateway (8080) 健康检查失败"
    fi
    
    # 测试 API
    log_info "测试 API 接口..."
    if curl -sf http://localhost:8080/api/a/hello > /dev/null 2>&1; then
        log_success "✅ API 接口访问正常"
    else
        log_warn "⚠️  API 接口访问失败"
    fi
    
    log_success "部署验证完成"
    echo ""
}

# ==================== 步骤 10：显示部署信息 ====================
print_summary() {
    echo ""
    echo "================================================================"
    echo "                    🎉 部署完成！"
    echo "================================================================"
    echo ""
    echo "📦 部署信息："
    echo "   部署方式: Java Service Wrapper"
    echo "   版本: $VERSION"
    echo "   安装目录: $INSTALL_DIR"
    echo "   日志文件: $LOG_FILE"
    echo ""
    echo "🌐 访问地址："
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "   📊 Eureka Peer 1: http://${SERVER_IP}:8761"
    echo "   📊 Eureka Peer 2: http://${SERVER_IP}:8762"
    echo "   🚪 API Gateway:   http://${SERVER_IP}:8080"
    echo ""
    echo "🔑 默认凭证："
    echo "   Eureka 控制台: admin / admin123"
    echo "   Eureka 客户端: eureka-client / client123"
    echo "   Gateway Token: gateway-token"
    echo ""
    echo "📝 管理命令："
    echo "   查看所有状态: sudo bash scripts/wrapper-manage.sh status"
    echo "   查看服务日志: sudo bash scripts/wrapper-manage.sh logs <service>"
    echo "   重启服务:     sudo bash scripts/wrapper-manage.sh restart <service>"
    echo "   停止所有:     sudo bash scripts/wrapper-manage.sh stop all"
    echo "   卸载部署:     sudo bash scripts/wrapper-uninstall.sh"
    echo ""
    echo "📋 Systemd 命令："
    echo "   查看状态:   systemctl status eureka-peer1"
    echo "   查看日志:   journalctl -u eureka-peer1 -f"
    echo "   重启服务:   systemctl restart eureka-peer1"
    echo "   停止服务:   systemctl stop eureka-peer1"
    echo ""
    echo "🧪 测试命令："
    echo "   curl http://localhost:8080/api/a/hello"
    echo "   curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a"
    echo ""
    echo "📂 重要目录："
    echo "   配置文件: $INSTALL_DIR/conf/"
    echo "   日志文件: $INSTALL_DIR/logs/"
    echo "   JAR 包:   $INSTALL_DIR/lib/"
    echo ""
    echo "⚠️  安全提醒："
    echo "   1. 生产环境请务必修改 wrapper 配置文件中的默认密码！"
    echo "      编辑: sudo vim $INSTALL_DIR/conf/wrapper-*.conf"
    echo "   2. 建议配置 HTTPS（使用 Nginx 反向代理）"
    echo "   3. 定期备份配置文件和日志"
    echo "   4. 限制服务器访问权限（只开放必要端口）"
    echo ""
    echo "📚 相关文档："
    echo "   - WRAPPER_DEPLOYMENT.md（详细部署指南）"
    echo "   - WRAPPER_ENVIRONMENT_VARIABLES.md（环境变量配置）"
    echo "   - WRAPPER_ENV_CHEATSHEET.md（快速参考）"
    echo ""
    echo "================================================================"
}

# ==================== 主函数 ====================
main() {
    echo ""
    echo "================================================================"
    echo "     Eureka Pro - Wrapper 一键部署脚本"
    echo "================================================================"
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 询问用户确认
    log_info "即将开始部署，配置如下："
    log_info "  部署方式: Java Service Wrapper"
    log_info "  版本: $VERSION"
    log_info "  安装目录: $INSTALL_DIR"
    echo ""
    read -p "确认开始部署？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
    
    # 执行部署步骤
    check_system
    install_jdk
    install_maven
    build_project
    install_wrapper
    configure_firewall
    start_services
    enable_autostart
    verify_deployment
    
    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    # 显示总结
    print_summary
    
    log_success "部署成功！总耗时: ${DURATION} 秒"
    log_info "详细日志已保存到: $LOG_FILE"
}

# 执行主函数
main "$@"
