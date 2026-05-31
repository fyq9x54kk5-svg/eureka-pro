#!/usr/bin/env bash
# =============================================================================
# Eureka Pro - Docker 一键部署脚本
# 用途：在 Linux 服务器上自动部署 Eureka Pro 微服务平台
# 使用方法：sudo bash deploy-docker.sh [版本号]
# 示例：sudo bash deploy-docker.sh 1.0.0
# =============================================================================

set -euo pipefail

# ==================== 配置变量 ====================
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${1:-1.0.0}"
LOG_FILE="/tmp/eureka-pro-docker-deploy-$(date +%Y%m%d-%H%M%S).log"

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
        
        # 检查是否为支持的操作系统
        case "$ID" in
            centos|rhel|fedora|ubuntu|debian|alpine|alinux)
                log_success "操作系统受支持"
                ;;
            *)
                log_warn "未测试的操作系统: $ID，可能不兼容"
                read -p "是否继续？(y/N) " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log_info "部署已取消"
                    exit 0
                fi
                ;;
        esac
    else
        log_warn "无法检测操作系统类型"
    fi
    
    # 检查必要命令是否存在
    log_info "检查必要命令..."
    local missing_cmds=()
    for cmd in curl wget git; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        log_warn "缺少命令: ${missing_cmds[*]}，将在下一步安装"
    else
        log_success "必要命令检查通过"
    fi
    
    # 检查内存（建议至少 4GB）
    if command -v free &> /dev/null; then
        TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
        log_info "系统内存: ${TOTAL_MEM}MB"
        
        if [ "$TOTAL_MEM" -lt 2048 ]; then
            log_error "内存不足 2GB (${TOTAL_MEM}MB)，无法部署"
            log_info "建议：至少 4GB 内存，推荐 8GB"
            exit 1
        elif [ "$TOTAL_MEM" -lt 4096 ]; then
            log_warn "内存较少 (${TOTAL_MEM}MB)，可能影响性能"
            log_info "建议调整 .env 中的资源限制"
            read -p "是否继续？(y/N) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "部署已取消"
                exit 0
            fi
        else
            log_success "内存充足: ${TOTAL_MEM}MB"
        fi
    else
        log_warn "free 命令不存在，跳过内存检查"
    fi
    
    # 检查磁盘空间（建议至少 10GB）
    if command -v df &> /dev/null; then
        AVAILABLE_DISK=$(df -m /opt | awk 'NR==2 {print $4}')
        log_info "可用磁盘空间: ${AVAILABLE_DISK}MB"
        
        if [ "$AVAILABLE_DISK" -lt 5120 ]; then
            log_error "磁盘空间不足 5GB (${AVAILABLE_DISK}MB)，无法部署"
            log_info "建议：清理磁盘空间或扩展分区"
            exit 1
        elif [ "$AVAILABLE_DISK" -lt 10240 ]; then
            log_warn "磁盘空间较少 (${AVAILABLE_DISK}MB)"
            log_info "建议：至少 10GB 可用空间"
            read -p "是否继续？(y/N) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "部署已取消"
                exit 0
            fi
        else
            log_success "磁盘空间充足: ${AVAILABLE_DISK}MB"
        fi
    else
        log_warn "df 命令不存在，跳过磁盘检查"
    fi
    
    # 检查端口占用情况
    log_info "检查端口占用..."
    local ports=(8761 8762 8080 8081 8082)
    local port_conflict=false
    
    for port in "${ports[@]}"; do
        if command -v ss &> /dev/null; then
            if ss -tlnp | grep -q ":${port} "; then
                log_warn "端口 $port 已被占用"
                port_conflict=true
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -tlnp | grep -q ":${port} "; then
                log_warn "端口 $port 已被占用"
                port_conflict=true
            fi
        fi
    done
    
    if [ "$port_conflict" = true ]; then
        log_warn "检测到端口冲突，请确保停止占用端口的服务"
        read -p "是否继续？(y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            exit 0
        fi
    else
        log_success "端口检查通过"
    fi
    
    # 检查网络连接
    log_info "检查网络连接..."
    if ping -c 1 -W 3 docker.com &> /dev/null || curl -s --connect-timeout 3 https://docker.com > /dev/null; then
        log_success "网络连接正常"
    else
        log_warn "无法访问外网，Docker 安装可能失败"
        log_info "如果已离线安装 Docker，可以忽略此警告"
        read -p "是否继续？(y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "部署已取消"
            exit 0
        fi
    fi
    
    # 检查 DNS 解析
    log_info "检查 DNS 解析..."
    if nslookup docker.com &> /dev/null || dig docker.com &> /dev/null; then
        log_success "DNS 解析正常"
    else
        log_warn "DNS 解析可能有问题"
        log_info "建议检查 /etc/resolv.conf 配置"
        # 尝试使用公共 DNS
        if ! echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf > /dev/null 2>&1; then
            log_warn "无法添加公共 DNS，可能需要手动配置"
        fi
    fi
    
    # 检查内核版本（Docker 要求 3.10+）
    KERNEL_VERSION=$(uname -r | cut -d'-' -f1)
    KERNEL_MAJOR=$(echo "$KERNEL_VERSION" | cut -d'.' -f1)
    KERNEL_MINOR=$(echo "$KERNEL_VERSION" | cut -d'.' -f2)
    
    if [ "$KERNEL_MAJOR" -lt 3 ] || ([ "$KERNEL_MAJOR" -eq 3 ] && [ "$KERNEL_MINOR" -lt 10 ]); then
        log_error "内核版本过低 ($KERNEL_VERSION)，Docker 需要 3.10+"
        log_info "建议：升级系统内核或更换服务器"
        exit 1
    else
        log_success "内核版本: $KERNEL_VERSION"
    fi
    
    # 检查 cgroup 支持（用于资源限制）
    if [ -d /sys/fs/cgroup ]; then
        log_success "cgroup 文件系统存在"
    else
        log_warn "未检测到 cgroup 文件系统"
        log_info "容器资源限制可能无法生效"
    fi
    
    # 检查交换空间（Swap）
    if command -v free &> /dev/null; then
        SWAP_SIZE=$(free -m | awk '/^Swap:/{print $2}')
        if [ "$SWAP_SIZE" -gt 0 ]; then
            log_warn "检测到交换空间: ${SWAP_SIZE}MB"
            log_info "Java 应用在 Swap 上性能较差，建议禁用 Swap"
            log_info "临时禁用: sudo swapoff -a"
            log_info "永久禁用: 注释 /etc/fstab 中的 swap 行"
        else
            log_success "未启用交换空间（推荐）"
        fi
    fi
    
    # 检查 Docker socket 权限
    if [ -S /var/run/docker.sock ]; then
        if [ -w /var/run/docker.sock ]; then
            log_success "Docker socket 可写"
        else
            log_error "Docker socket 不可写，请检查权限"
            log_info "修复: sudo chmod 666 /var/run/docker.sock"
            exit 1
        fi
    else
        log_warn "Docker socket 不存在，Docker 可能未启动"
    fi
    
    log_success "系统环境检查完成"
    echo ""
}

# ==================== 步骤 2：安装依赖软件 ====================
install_dependencies() {
    log_info "=========================================="
    log_info "步骤 2: 安装依赖软件"
    log_info "=========================================="
    
    # 检测包管理器类型
    if command -v yum &> /dev/null; then
        # CentOS/RHEL 系统
        log_info "检测到 CentOS/RHEL 系统"
        
        # 安装基础工具
        log_info "安装基础工具（wget, curl, git）..."
        yum install -y wget curl git
        
        # 安装 Docker
        if ! command -v docker &> /dev/null; then
            log_info "安装 Docker..."
            
            # 尝试安装 Docker
            if curl -fsSL https://get.docker.com | sh; then
                log_success "Docker 安装完成"
            else
                log_error "Docker 安装失败"
                log_info "请手动安装 Docker 后重试"
                log_info "参考: https://docs.docker.com/engine/install/"
                exit 1
            fi
        else
            log_success "Docker 已安装: $(docker --version)"
        fi
        
        # 检查 Docker 服务状态
        log_info "检查 Docker 服务状态..."
        if systemctl is-active --quiet docker 2>/dev/null; then
            log_success "Docker 服务运行正常"
        else
            log_warn "Docker 服务未运行，尝试启动..."
            if systemctl start docker 2>/dev/null; then
                log_success "Docker 服务已启动"
            else
                log_error "无法启动 Docker 服务"
                log_info "请手动执行: sudo systemctl start docker"
                exit 1
            fi
        fi
        
        # 测试 Docker 是否可用
        log_info "测试 Docker..."
        if docker info &> /dev/null; then
            log_success "Docker 可用"
        else
            log_error "Docker 不可用，请检查安装"
            exit 1
        fi
        
    elif command -v apt-get &> /dev/null; then
        # Ubuntu/Debian 系统
        log_info "检测到 Ubuntu/Debian 系统"
        
        # 更新软件包列表
        apt-get update -qq
        
        # 安装基础工具
        log_info "安装基础工具（wget, curl, git）..."
        apt-get install -y wget curl git
        
        # 安装 Docker
        if ! command -v docker &> /dev/null; then
            log_info "安装 Docker..."
            
            # 尝试安装 Docker
            if curl -fsSL https://get.docker.com | sh; then
                log_success "Docker 安装完成"
            else
                log_error "Docker 安装失败"
                log_info "请手动安装 Docker 后重试"
                log_info "参考: https://docs.docker.com/engine/install/"
                exit 1
            fi
        else
            log_success "Docker 已安装: $(docker --version)"
        fi
        
        # 检查 Docker 服务状态
        log_info "检查 Docker 服务状态..."
        if systemctl is-active --quiet docker 2>/dev/null; then
            log_success "Docker 服务运行正常"
        else
            log_warn "Docker 服务未运行，尝试启动..."
            if systemctl start docker 2>/dev/null; then
                log_success "Docker 服务已启动"
            else
                log_error "无法启动 Docker 服务"
                log_info "请手动执行: sudo systemctl start docker"
                exit 1
            fi
        fi
        
        # 测试 Docker 是否可用
        log_info "测试 Docker..."
        if docker info &> /dev/null; then
            log_success "Docker 可用"
        else
            log_error "Docker 不可用，请检查安装"
            exit 1
        fi
    else
        log_error "不支持的包管理器"
        exit 1
    fi
    
    # 安装 Docker Compose
    log_info "检查 Docker Compose..."
    
    # 检查 Docker Compose V2 (plugin)
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | head -1)
        log_success "Docker Compose V2 已安装: $COMPOSE_VERSION"
    elif command -v docker-compose &> /dev/null; then
        # 检查 Docker Compose V1 (standalone)
        COMPOSE_VERSION=$(docker-compose --version)
        log_warn "检测到旧版 Docker Compose V1: $COMPOSE_VERSION"
        log_info "建议升级到 V2，但 V1 也可以使用"
    else
        # 需要安装 Docker Compose
        log_info "安装 Docker Compose V2..."
        DOCKER_COMPOSE_VERSION="v2.20.0"
        
        # 创建 docker cli-plugins 目录
        mkdir -p ~/.docker/cli-plugins 2>/dev/null || true
        
        # 下载 Docker Compose
        if curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose; then
            chmod +x /usr/local/bin/docker-compose
            
            # 创建软链接到 cli-plugins（V2 plugin 方式）
            mkdir -p /usr/libexec/docker/cli-plugins 2>/dev/null || true
            ln -sf /usr/local/bin/docker-compose /usr/libexec/docker/cli-plugins/docker-compose 2>/dev/null || true
            
            log_success "Docker Compose 安装完成"
        else
            log_error "Docker Compose 下载失败"
            log_info "请手动安装: https://docs.docker.com/compose/install/"
            exit 1
        fi
    fi
    
    # 将当前用户加入 docker 组（避免每次都用 sudo）
    if [ -n "${SUDO_USER:-}" ]; then
        usermod -aG docker "$SUDO_USER" 2>/dev/null || true
        log_info "已将用户 $SUDO_USER 加入 docker 组"
    fi
    
    log_success "依赖软件安装完成"
    echo ""
}

# ==================== 步骤 3：配置环境变量 ====================
configure_environment() {
    log_info "=========================================="
    log_info "步骤 3: 配置环境变量"
    log_info "=========================================="
    
    cd "$ROOT_DIR"

    # 检查 .env 文件是否存在
    if [ ! -f .env ]; then
        log_info "从模板创建 .env 配置文件..."
        cp .env.example .env
        log_success ".env 文件创建完成"
        log_warn "请编辑 .env 文件修改默认密码（生产环境必须！）"
    else
        log_success ".env 文件已存在"
    fi
    
    # 显示关键配置项
    log_info "当前配置："
    grep -E "^(IMAGE_TAG|EUREKA_CLIENT_PASSWORD|GATEWAY_AUTH_TOKEN)=" .env || true
    
    log_success "环境变量配置完成"
    echo ""
}

# ==================== 步骤 4：构建 Docker 镜像 ====================
build_images() {
    log_info "=========================================="
    log_info "步骤 4: 构建 Docker 镜像"
    log_info "=========================================="
    
    cd "$ROOT_DIR"
    
    # 检查项目文件完整性
    log_info "检查项目文件..."
    local required_files=("pom.xml" "Dockerfile" "docker-compose.yml" ".env.example")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "缺少必要文件: ${missing_files[*]}"
        log_info "请确保在项目根目录运行此脚本"
        exit 1
    else
        log_success "项目文件完整"
    fi
    
    # 检查 Maven Wrapper 或 Maven
    if [ ! -f "mvnw" ] && ! command -v mvn &> /dev/null; then
        log_warn "未检测到 Maven，将使用 Docker 多阶段构建"
        log_info "首次构建可能需要较长时间（下载依赖）"
    fi
    
    # 赋予构建脚本执行权限
    chmod +x scripts/docker-build.sh
    
    # 执行构建
    log_info "开始构建镜像（版本: $VERSION）..."
    log_info "这可能需要几分钟时间，请耐心等待..."
    
    if bash scripts/docker-build.sh "$VERSION"; then
        log_success "镜像构建成功"
    else
        log_error "镜像构建失败"
        log_info "请查看错误信息并尝试以下解决方案："
        log_info "1. 检查网络连接（需要下载 Maven 依赖）"
        log_info "2. 检查磁盘空间是否充足"
        log_info "3. 手动执行: bash scripts/docker-build.sh $VERSION"
        exit 1
    fi
    
    # 验证镜像是否构建成功
    log_info "验证构建的镜像..."
    local expected_images=("eureka-server" "demo-service-a" "demo-service-b" "gateway")
    local missing_images=()
    
    for img in "${expected_images[@]}"; do
        if ! docker images | grep -q "eureka-pro/${img}"; then
            missing_images+=("$img")
        fi
    done
    
    if [ ${#missing_images[@]} -gt 0 ]; then
        log_error "部分镜像构建失败: ${missing_images[*]}"
        log_info "已构建的镜像："
        docker images | grep eureka-pro || true
        exit 1
    else
        log_success "所有镜像构建完成"
        docker images | grep eureka-pro
    fi
    
    echo ""
}

# ==================== 步骤 5：启动服务 ====================
start_services() {
    log_info "=========================================="
    log_info "步骤 5: 启动服务"
    log_info "=========================================="
    
    cd "$ROOT_DIR"
    
    # 赋予管理脚本执行权限
    chmod +x scripts/docker-manage.sh
    
    # 使用管理脚本启动服务
    log_info "启动所有服务..."
    bash scripts/docker-manage.sh up
    
    log_success "服务启动命令已执行"
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

# ==================== 步骤 7：验证部署 ====================
verify_deployment() {
    log_info "=========================================="
    log_info "步骤 7: 验证部署"
    log_info "=========================================="
    
    cd "$ROOT_DIR"
    
    # 等待服务启动
    log_info "等待服务启动..."
    local max_wait=120  # 最大等待时间（秒）
    local wait_interval=5  # 检查间隔（秒）
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        # 检查所有容器是否运行
        local running_containers=$(docker compose ps --format json 2>/dev/null | grep -c '"Running"' || echo "0")
        local total_containers=5  # eureka-server-1, eureka-server-2, demo-a, demo-b, gateway
        
        if [ "$running_containers" -eq "$total_containers" ]; then
            log_success "所有容器已启动 ($running_containers/$total_containers)"
            break
        fi
        
        log_info "等待中... ($elapsed/${max_wait}s) - 运行中: $running_containers/$total_containers"
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
    done
    
    if [ $elapsed -ge $max_wait ]; then
        log_error "服务启动超时"
        log_info "查看容器状态:"
        docker compose ps
        log_info "查看日志:"
        docker compose logs --tail=50
        exit 1
    fi
    
    # 显示容器状态
    log_info "容器状态:"
    docker compose ps
    
    # 检查服务健康状态
    log_info "检查服务健康状态..."
    
    # 检查 Eureka Server 1
    log_info "检查 Eureka Server 1 (8761)..."
    if curl -sf --max-time 5 http://localhost:8761/actuator/health > /dev/null 2>&1; then
        log_success "✅ Eureka Server 1 (8761) 运行正常"
    else
        log_warn "⚠️  Eureka Server 1 (8761) 健康检查失败"
        log_info "可能原因：服务正在启动中，请稍后重试"
    fi
    
    # 检查 Eureka Server 2
    log_info "检查 Eureka Server 2 (8762)..."
    if curl -sf --max-time 5 http://localhost:8762/actuator/health > /dev/null 2>&1; then
        log_success "✅ Eureka Server 2 (8762) 运行正常"
    else
        log_warn "⚠️  Eureka Server 2 (8762) 健康检查失败"
    fi
    
    # 检查 Gateway
    log_info "检查 API Gateway (8080)..."
    if curl -sf --max-time 5 http://localhost:8080/actuator/health > /dev/null 2>&1; then
        log_success "✅ Gateway (8080) 运行正常"
    else
        log_warn "⚠️  Gateway (8080) 健康检查失败"
    fi
    
    # 检查 Demo Service A
    log_info "检查 Demo Service A (8081)..."
    if curl -sf --max-time 5 http://localhost:8081/actuator/health > /dev/null 2>&1; then
        log_success "✅ Demo Service A (8081) 运行正常"
    else
        log_warn "⚠️  Demo Service A (8081) 健康检查失败"
    fi
    
    # 检查 Demo Service B
    log_info "检查 Demo Service B (8082)..."
    if curl -sf --max-time 5 http://localhost:8082/actuator/health > /dev/null 2>&1; then
        log_success "✅ Demo Service B (8082) 运行正常"
    else
        log_warn "⚠️  Demo Service B (8082) 健康检查失败"
    fi
    
    # 测试 API 接口
    log_info "测试 API 接口..."
    if curl -sf --max-time 5 http://localhost:8080/api/a/hello > /dev/null 2>&1; then
        log_success "✅ API 接口访问正常"
        # 显示测试结果
        local api_result=$(curl -s --max-time 5 http://localhost:8080/api/a/hello)
        log_info "API 响应: $api_result"
    else
        log_warn "⚠️  API 接口访问失败"
        log_info "请检查 Gateway 和 Demo Service A 的状态"
    fi
    
    # 检查服务注册情况
    log_info "检查 Eureka 服务注册..."
    sleep 5  # 等待服务注册
    if curl -sf --max-time 5 -u admin:admin123 http://localhost:8761/eureka/apps | grep -q "DEMO-SERVICE-A"; then
        log_success "✅ 服务已成功注册到 Eureka"
    else
        log_warn "⚠️  服务注册可能未完成"
        log_info "请访问 Eureka 控制台查看: http://localhost:8761"
    fi
    
    log_success "部署验证完成"
    echo ""
}

# ==================== 步骤 8：显示部署信息 ====================
print_summary() {
    echo ""
    echo "================================================================"
    echo "                    🎉 部署完成！"
    echo "================================================================"
    echo ""
    echo "📦 部署信息："
    echo "   部署方式: Docker Compose"
    echo "   版本: $VERSION"
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
    echo "   查看状态:   bash scripts/docker-manage.sh status"
    echo "   查看日志:   bash scripts/docker-manage.sh logs"
    echo "   重启服务:   bash scripts/docker-manage.sh restart"
    echo "   停止服务:   bash scripts/docker-manage.sh down"
    echo "   清理资源:   bash scripts/docker-manage.sh clean"
    echo ""
    echo "🧪 测试命令："
    echo "   curl http://localhost:8080/api/a/hello"
    echo "   curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a"
    echo ""
    echo "⚠️  安全提醒："
    echo "   1. 生产环境请务必修改 .env 中的默认密码！"
    echo "   2. 建议配置 HTTPS（使用 Nginx 反向代理）"
    echo "   3. 定期备份数据和配置文件"
    echo ""
    echo "📚 相关文档："
    echo "   - DOCKER_DEPLOYMENT.md（详细部署指南）"
    echo "   - DOCKER_QUICK_REFERENCE.md（快速参考）"
    echo "   - ENV_CONFIGURATION_GUIDE.md（环境变量配置）"
    echo ""
    echo "================================================================"
}

# ==================== 主函数 ====================
main() {
    echo ""
    echo "================================================================"
    echo "     Eureka Pro - Docker 一键部署脚本"
    echo "================================================================"
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 预部署检查清单
    log_info "📋 预部署检查清单："
    log_info "  ✓ 项目目录: $ROOT_DIR"
    log_info "  ✓ 部署方式: Docker Compose"
    log_info "  ✓ 版本: $VERSION"
    log_info "  ✓ 日志文件: $LOG_FILE"
    echo ""
    
    # 显示系统信息
    log_info "🖥️  系统信息："
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        log_info "  操作系统: $NAME $VERSION_ID"
    fi
    log_info "  内核版本: $(uname -r)"
    log_info "  CPU 架构: $(uname -m)"
    if command -v free &> /dev/null; then
        log_info "  内存总量: $(free -h | awk '/^Mem:/{print $2}')"
    fi
    echo ""
    
    # 询问用户确认
    read -p "确认开始部署？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
    
    # 执行部署步骤
    check_system
    install_dependencies
    configure_environment
    build_images
    start_services
    configure_firewall
    verify_deployment
    
    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    # 显示总结
    print_summary
    
    log_success "部署成功！总耗时: ${MINUTES}分${SECONDS}秒"
    log_info "详细日志已保存到: $LOG_FILE"
    
    # 提供故障排除建议
    echo ""
    log_info "💡 故障排除提示："
    log_info "  • 如果服务无法访问，请检查防火墙配置"
    log_info "  • 如果容器启动失败，请查看日志: docker compose logs"
    log_info "  • 如果内存不足，请调整 .env 中的资源限制"
    log_info "  • 如需重新部署，请先执行: bash scripts/docker-manage.sh clean"
}

# 执行主函数
main "$@"
