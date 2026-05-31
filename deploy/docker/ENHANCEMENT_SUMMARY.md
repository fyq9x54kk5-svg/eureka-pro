# Docker 部署脚本环境检查增强说明

## 📝 更新概述

本次更新对 `deploy-docker.sh` 脚本进行了全面的环境检查增强，确保部署过程的稳定性和可靠性。

---

## ✨ 新增检查项

### 1. DNS 解析检查
- **检查内容**: 验证 DNS 是否能正常解析域名
- **自动修复**: 尝试添加公共 DNS (8.8.8.8)
- **重要性**: ⭐⭐⭐⭐ (Docker 拉取镜像需要 DNS)

### 2. 内核版本检查
- **检查内容**: Linux 内核 >= 3.10
- **失败处理**: 强制退出（Docker 无法运行）
- **重要性**: ⭐⭐⭐⭐⭐ (必需条件)

### 3. cgroup 支持检查
- **检查内容**: `/sys/fs/cgroup` 是否存在
- **影响**: 容器资源限制功能
- **重要性**: ⭐⭐⭐ (影响资源管理)

### 4. Swap 交换空间检查
- **检查内容**: 是否启用 Swap
- **建议**: Java 应用建议禁用 Swap
- **重要性**: ⭐⭐⭐ (影响性能)

### 5. Docker Socket 权限检查
- **检查内容**: `/var/run/docker.sock` 是否可写
- **失败处理**: 提供修复命令
- **重要性**: ⭐⭐⭐⭐⭐ (必需条件)

### 6. Docker Compose 版本检测
- **检查内容**: V1 vs V2 版本
- **优化**: 优先使用 V2 plugin 方式
- **重要性**: ⭐⭐⭐⭐ (影响命令兼容性)

---

## 🔧 增强的检查逻辑

### 内存检查改进

**之前**:
```bash
if [ "$TOTAL_MEM" -lt 2048 ]; then
    log_warn "内存不足 2GB，可能导致服务运行不稳定"
fi
```

**现在**:
```bash
if [ "$TOTAL_MEM" -lt 2048 ]; then
    log_error "内存不足 2GB (${TOTAL_MEM}MB)，无法部署"
    exit 1  # 强制退出
elif [ "$TOTAL_MEM" -lt 4096 ]; then
    log_warn "内存较少 (${TOTAL_MEM}MB)，可能影响性能"
    read -p "是否继续？(y/N) "  # 用户确认
fi
```

**改进点**:
- ✅ < 2GB 时强制退出，避免部署失败
- ✅ 2-4GB 时要求用户确认
- ✅ 提供更明确的建议

---

### 磁盘空间检查改进

**之前**:
```bash
AVAILABLE_DISK=$(df -m /opt | awk 'NR==2 {print $4}')
log_info "可用磁盘空间: ${AVAILABLE_DISK}MB"
```

**现在**:
```bash
if [ "$AVAILABLE_DISK" -lt 5120 ]; then
    log_error "磁盘空间不足 5GB (${AVAILABLE_DISK}MB)，无法部署"
    exit 1
elif [ "$AVAILABLE_DISK" -lt 10240 ]; then
    log_warn "磁盘空间较少 (${AVAILABLE_DISK}MB)"
    read -p "是否继续？(y/N) "
fi
```

**改进点**:
- ✅ 设置最低门槛 (5GB)
- ✅ 分级警告机制
- ✅ 用户可控

---

### Docker 安装增强

**之前**:
```bash
curl -fsSL https://get.docker.com | sh
systemctl start docker
systemctl enable docker
```

**现在**:
```bash
# 1. 安装 Docker
if curl -fsSL https://get.docker.com | sh; then
    log_success "Docker 安装完成"
else
    log_error "Docker 安装失败"
    exit 1
fi

# 2. 检查服务状态
if systemctl is-active --quiet docker; then
    log_success "Docker 服务运行正常"
else
    log_warn "Docker 服务未运行，尝试启动..."
    if ! systemctl start docker; then
        log_error "无法启动 Docker 服务"
        exit 1
    fi
fi

# 3. 测试 Docker 可用性
if docker info &> /dev/null; then
    log_success "Docker 可用"
else
    log_error "Docker 不可用，请检查安装"
    exit 1
fi
```

**改进点**:
- ✅ 每步都有错误检查
- ✅ 验证 Docker 真正可用
- ✅ 提供清晰的错误信息

---

### Docker Compose 安装增强

**之前**:
```bash
if ! command -v docker compose &> /dev/null; then
    curl -L "..." -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi
```

**现在**:
```bash
# 1. 检查 V2 plugin
if docker compose version &> /dev/null; then
    log_success "Docker Compose V2 已安装"
    
# 2. 检查 V1 standalone
elif command -v docker-compose &> /dev/null; then
    log_warn "检测到旧版 Docker Compose V1"
    
# 3. 安装 V2
else
    mkdir -p ~/.docker/cli-plugins
    curl -L "..." -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # 创建 plugin 软链接
    ln -sf /usr/local/bin/docker-compose \
      /usr/libexec/docker/cli-plugins/docker-compose
fi
```

**改进点**:
- ✅ 区分 V1 和 V2
- ✅ 正确安装 V2 plugin
- ✅ 兼容两种方式

---

### 镜像构建验证增强

**之前**:
```bash
bash scripts/docker-build.sh "$VERSION"
if docker images | grep -q "eureka-pro"; then
    log_success "Docker 镜像构建完成"
else
    log_error "镜像构建失败"
    exit 1
fi
```

**现在**:
```bash
# 1. 检查项目文件完整性
local required_files=("pom.xml" "Dockerfile" "docker-compose.yml" ".env.example")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "缺少必要文件: $file"
        exit 1
    fi
done

# 2. 执行构建并捕获错误
if bash scripts/docker-build.sh "$VERSION"; then
    log_success "镜像构建成功"
else
    log_error "镜像构建失败"
    log_info "请查看错误信息并尝试以下解决方案："
    log_info "1. 检查网络连接（需要下载 Maven 依赖）"
    log_info "2. 检查磁盘空间是否充足"
    exit 1
fi

# 3. 验证所有镜像都已构建
local expected_images=("eureka-server" "demo-service-a" "demo-service-b" "gateway")
for img in "${expected_images[@]}"; do
    if ! docker images | grep -q "eureka-pro/${img}"; then
        log_error "部分镜像构建失败: $img"
        exit 1
    fi
done
```

**改进点**:
- ✅ 预检查项目文件
- ✅ 详细的错误提示
- ✅ 验证每个镜像

---

### 服务启动验证增强

**之前**:
```bash
sleep 30
docker compose ps
if curl -sf http://localhost:8761/actuator/health > /dev/null; then
    log_success "✅ Eureka Server 运行正常"
fi
```

**现在**:
```bash
# 1. 智能等待（最多 120 秒）
local max_wait=120
local wait_interval=5
local elapsed=0

while [ $elapsed -lt $max_wait ]; do
    local running_containers=$(docker compose ps --format json | grep -c '"Running"')
    if [ "$running_containers" -eq 5 ]; then
        log_success "所有容器已启动"
        break
    fi
    sleep $wait_interval
    elapsed=$((elapsed + wait_interval))
done

# 2. 超时处理
if [ $elapsed -ge $max_wait ]; then
    log_error "服务启动超时"
    docker compose logs --tail=50
    exit 1
fi

# 3. 逐个检查服务健康
for service in eureka-server-1 eureka-server-2 gateway demo-a demo-b; do
    if curl -sf --max-time 5 http://localhost:${PORT}/actuator/health > /dev/null; then
        log_success "✅ $service 运行正常"
    else
        log_warn "⚠️  $service 健康检查失败"
    fi
done

# 4. 测试 API 接口
if curl -sf http://localhost:8080/api/a/hello > /dev/null; then
    local api_result=$(curl -s http://localhost:8080/api/a/hello)
    log_info "API 响应: $api_result"
fi

# 5. 检查服务注册
if curl -sf -u admin:admin123 http://localhost:8761/eureka/apps | grep -q "DEMO-SERVICE-A"; then
    log_success "✅ 服务已成功注册到 Eureka"
fi
```

**改进点**:
- ✅ 动态等待而非固定时间
- ✅ 超时自动诊断
- ✅ 全面的健康检查
- ✅ API 功能测试
- ✅ 服务注册验证

---

## 📊 检查流程对比

### 之前的流程
```
检查系统 → 安装依赖 → 配置环境 → 构建镜像 → 启动服务 → 验证
   ↓                                            ↓
 简单检查                                    固定等待 30 秒
                                              简单健康检查
```

### 现在的流程
```
详细检查系统 (16 项) → 智能安装依赖 → 配置环境 → 验证文件 → 
     ↓                    ↓                        ↓
  分级警告/退出      错误处理+重试            完整性检查
                                              ↓
                                        智能构建镜像
                                              ↓
                                         验证所有镜像
                                              ↓
                                        智能启动服务
                                              ↓
                                   动态等待 (最多 120 秒)
                                              ↓
                                  全面健康检查 (5 个服务)
                                              ↓
                                     API 功能测试
                                              ↓
                                   服务注册验证
                                              ↓
                                      部署完成 ✅
```

---

## 🎯 关键改进总结

| 检查项 | 之前 | 现在 | 改进 |
|--------|------|------|------|
| 内存检查 | 仅警告 | <2GB 强制退出 | ✅ 防止无效部署 |
| 磁盘检查 | 仅显示 | <5GB 强制退出 | ✅ 防止空间不足 |
| Docker 检查 | 安装即认为成功 | 验证服务+可用性 | ✅ 确保真正可用 |
| Compose 检查 | 仅检查命令 | 区分 V1/V2 | ✅ 版本兼容 |
| 端口检查 | 无 | 检查 5 个端口 | ✅ 避免冲突 |
| DNS 检查 | 无 | 自动修复 | ✅ 网络可靠 |
| 内核检查 | 无 | >=3.10 必需 | ✅ 系统兼容 |
| cgroup 检查 | 无 | 检查支持 | ✅ 资源管理 |
| Swap 检查 | 无 | 性能警告 | ✅ 性能优化 |
| Socket 权限 | 无 | 可写性检查 | ✅ 权限正确 |
| 文件完整性 | 无 | 检查 4 个文件 | ✅ 项目完整 |
| 镜像验证 | 检查任意镜像 | 验证所有镜像 | ✅ 构建完整 |
| 服务等待 | 固定 30 秒 | 动态最多 120 秒 | ✅ 灵活可靠 |
| 健康检查 | 2 个服务 | 5 个服务 + API | ✅ 全面验证 |
| 错误提示 | 简单 | 详细+解决方案 | ✅ 易于排错 |

---

## 📖 相关文档

- **[ENVIRONMENT_CHECK.md](./ENVIRONMENT_CHECK.md)** - 详细的环境检查说明和故障排除指南
- **[deploy-docker.sh](./deploy-docker.sh)** - 增强后的一键部署脚本
- **[../../DOCKER_DEPLOYMENT.md](../../DOCKER_DEPLOYMENT.md)** - Docker 部署完整指南
- **[../../ENV_CONFIGURATION_GUIDE.md](../../ENV_CONFIGURATION_GUIDE.md)** - 环境变量配置指南

---

## 🚀 使用示例

```bash
# 1. 上传项目到服务器
scp -r eureka-pro user@server:/opt/

# 2. SSH 登录
ssh user@server
cd /opt/eureka-pro

# 3. 执行部署（自动进行所有检查）
sudo bash deploy/docker/deploy-docker.sh 1.0.0

# 4. 查看日志（如果遇到问题）
cat /tmp/eureka-pro-docker-deploy-*.log

# 5. 查看详细的环境检查文档
less deploy/docker/ENVIRONMENT_CHECK.md
```

---

## 💡 最佳实践

1. **部署前阅读检查文档**: `ENVIRONMENT_CHECK.md`
2. **确保满足最低要求**: 2GB 内存, 5GB 磁盘, 内核 3.10+
3. **推荐配置**: 4GB+ 内存, 10GB+ 磁盘
4. **生产环境**: 禁用 Swap, 配置防火墙, 修改默认密码
5. **遇到问题**: 查看日志文件获取详细错误信息

---

**更新日期**: 2026-05-31  
**脚本版本**: deploy-docker.sh v2.0.0 (增强版)  
**维护者**: Eureka Pro Team
