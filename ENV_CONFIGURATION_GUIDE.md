# 环境变量集中配置指南

本文档介绍如何使用 `.env` 文件集中管理所有服务的配置。

---

## 📋 概述

所有服务的配置项都已提取到 `.env` 文件中，实现了：

✅ **集中管理** - 所有配置在一个文件中  
✅ **易于修改** - 修改一处，全局生效  
✅ **环境隔离** - dev/test/prod 使用不同 .env 文件  
✅ **安全保护** - .env 已加入 .gitignore  

---

## 🚀 快速开始

### 1. 复制配置文件

```bash
# 从模板创建 .env 文件
cp .env.example .env
```

### 2. 编辑配置

```bash
vim .env
```

常用修改项：

```bash
# 修改密码（生产环境必须！）
EUREKA_CLIENT_PASSWORD=YourSecurePassword123
GATEWAY_AUTH_TOKEN=YourSecureToken456

# 调整资源限制（根据服务器配置）
EUREKA_MEMORY_LIMIT=2048m
SERVICE_MEMORY_LIMIT=1024m
GATEWAY_MEMORY_LIMIT=2048m
```

### 3. 启动服务

```bash
# Docker Compose 会自动加载 .env 文件
bash scripts/docker-manage.sh up
```

---

## 📊 配置分类

### 1️⃣ 镜像配置

```bash
IMAGE_TAG=1.0.0              # 镜像版本标签
IMAGE_PREFIX=eureka-pro      # 镜像前缀
```

**使用场景**：
- 版本升级时修改 `IMAGE_TAG`
- 推送到私有仓库时修改 `IMAGE_PREFIX`

---

### 2️⃣ Spring Boot 通用配置

```bash
SPRING_PROFILES_ACTIVE=container  # 激活的 profile
```

**说明**：
- `container` profile 启用基于环境变量的配置
- 所有服务共用此配置

---

### 3️⃣ Eureka 注册中心配置

```bash
# Peer 节点地址（所有微服务使用）
EUREKA_PEER_1=eureka-server-1:8761
EUREKA_PEER_2=eureka-server-2:8761

# 客户端认证凭证
EUREKA_CLIENT_USERNAME=eureka-client
EUREKA_CLIENT_PASSWORD=client123  # ⚠️ 生产环境必须修改
```

**影响范围**：
- 所有微服务（demo-service-a/b, gateway）
- Eureka Server 之间的同步

---

### 4️⃣ 服务端口配置

```bash
# Eureka Server
EUREKA_SERVER_1_PORT=8761
EUREKA_SERVER_2_PORT=8762

# 微服务
DEMO_SERVICE_A_PORT=8081
DEMO_SERVICE_B_PORT=8082

# 网关
GATEWAY_PORT=8080
```

**修改示例**：

```bash
# 避免端口冲突
GATEWAY_PORT=9080
DEMO_SERVICE_A_PORT=9081
```

---

### 5️⃣ 服务主机名配置

```bash
EUREKA_SERVER_1_HOSTNAME=eureka-server-1
EUREKA_SERVER_2_HOSTNAME=eureka-server-2
DEMO_SERVICE_A_HOSTNAME=demo-service-a
DEMO_SERVICE_B_HOSTNAME=demo-service-b
GATEWAY_HOSTNAME=gateway
```

**用途**：
- Eureka 实例注册时使用
- Docker 容器内部通信

---

### 6️⃣ Gateway 配置

```bash
# 启用/禁用鉴权
GATEWAY_AUTH_ENABLED=true

# 鉴权 Token（⚠️ 生产环境必须修改）
GATEWAY_AUTH_TOKEN=gateway-token
```

**安全提示**：
- 生产环境务必修改 `GATEWAY_AUTH_TOKEN`
- 建议使用随机生成的强密码

---

### 7️⃣ JVM 配置

```bash
# 通用 JVM 参数（所有服务）
JAVA_OPTS=-XX:+UseContainerSupport \
          -XX:MaxRAMPercentage=75.0 \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=200
```

**可选：服务特定 JVM 配置**

```bash
# 取消注释并修改以覆盖默认值
# EUREKA_JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC
# SERVICE_JAVA_OPTS=-Xms256m -Xmx512m -XX:+UseG1GC
# GATEWAY_JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC
```

---

### 8️⃣ 资源限制配置

#### Eureka Server（需要更多资源）

```bash
EUREKA_MEMORY_LIMIT=1024m         # 最大内存
EUREKA_CPU_LIMIT=1.0              # 最大 CPU（核数）
EUREKA_MEMORY_RESERVATION=512m    # 预留内存
EUREKA_CPU_RESERVATION=0.5        # 预留 CPU
```

#### Demo Services（轻量级）

```bash
SERVICE_MEMORY_LIMIT=512m
SERVICE_CPU_LIMIT=0.5
SERVICE_MEMORY_RESERVATION=256m
SERVICE_CPU_RESERVATION=0.25
```

#### Gateway（中等负载）

```bash
GATEWAY_MEMORY_LIMIT=1024m
GATEWAY_CPU_LIMIT=1.0
GATEWAY_MEMORY_RESERVATION=512m
GATEWAY_CPU_RESERVATION=0.5
```

**根据服务器配置调整**：

| 服务器规格 | EUREKA_MEMORY_LIMIT | SERVICE_MEMORY_LIMIT | GATEWAY_MEMORY_LIMIT |
|-----------|---------------------|----------------------|----------------------|
| 4GB RAM   | 512m                | 256m                 | 512m                 |
| 8GB RAM   | 1024m               | 512m                 | 1024m                |
| 16GB RAM  | 2048m               | 1024m                | 2048m                |

---

### 9️⃣ 重启策略

```bash
# 选项：no, on-failure, always, unless-stopped
RESTART_POLICY=unless-stopped
```

**推荐**：
- 开发环境：`unless-stopped`
- 生产环境：`always`

---

### 🔟 健康检查配置

```bash
# 通用参数
HEALTHCHECK_INTERVAL=15s          # 检查间隔
HEALTHCHECK_TIMEOUT=5s            # 超时时间
HEALTHCHECK_RETRIES=10            # 重试次数

# 启动宽限期
EUREKA_HEALTHCHECK_START_PERIOD=60s    # Eureka 需要更长时间
SERVICE_HEALTHCHECK_START_PERIOD=45s   # 其他服务
```

**调整建议**：
- 如果服务启动慢，增加 `START_PERIOD`
- 如果网络不稳定，增加 `RETRIES`

---

### 1️⃣1️⃣ 日志配置

```bash
# 日志驱动
LOG_DRIVER=json-file

# 日志轮转
LOG_MAX_SIZE=50m       # 单个日志文件最大大小
LOG_MAX_FILE=5         # 保留的历史文件数量
```

**防止磁盘占满**：
- 小磁盘：`LOG_MAX_SIZE=20m`, `LOG_MAX_FILE=3`
- 大磁盘：`LOG_MAX_SIZE=100m`, `LOG_MAX_FILE=10`

---

### 1️⃣2️⃣ 网络配置

```bash
NETWORK_DRIVER=bridge  # Docker 网络驱动
```

**高级选项**：
- `bridge` - 默认桥接网络
- `host` - 主机网络（性能更好，但隔离性差）
- `overlay` - 跨主机网络（Swarm 模式）

---

## 🎯 常见场景配置

### 场景 1：开发环境

```bash
# .env.dev
IMAGE_TAG=latest
EUREKA_CLIENT_PASSWORD=dev123
GATEWAY_AUTH_TOKEN=dev-token
EUREKA_MEMORY_LIMIT=512m
SERVICE_MEMORY_LIMIT=256m
GATEWAY_MEMORY_LIMIT=512m
LOG_MAX_SIZE=20m
LOG_MAX_FILE=3
```

使用：

```bash
cp .env.dev .env
docker compose up -d
```

---

### 场景 2：测试环境

```bash
# .env.test
IMAGE_TAG=1.0.0-test
EUREKA_CLIENT_PASSWORD=test123
GATEWAY_AUTH_TOKEN=test-token
EUREKA_MEMORY_LIMIT=1024m
SERVICE_MEMORY_LIMIT=512m
GATEWAY_MEMORY_LIMIT=1024m
```

---

### 场景 3：生产环境

```bash
# .env.prod
IMAGE_TAG=1.0.0
EUREKA_CLIENT_PASSWORD=SuperSecureProdPass123!
GATEWAY_AUTH_TOKEN=SecureProdTokenXYZ789!@#
EUREKA_MEMORY_LIMIT=2048m
SERVICE_MEMORY_LIMIT=1024m
GATEWAY_MEMORY_LIMIT=2048m
RESTART_POLICY=always
LOG_MAX_SIZE=100m
LOG_MAX_FILE=10
```

**生产环境检查清单**：
- ✅ 修改所有默认密码
- ✅ 设置合理的资源限制
- ✅ 配置日志轮转
- ✅ 设置 `RESTART_POLICY=always`
- ✅ 备份 .env 文件

---

### 场景 4：低配服务器（2-4GB RAM）

```bash
# .env.low-memory
EUREKA_MEMORY_LIMIT=512m
EUREKA_CPU_LIMIT=0.5
SERVICE_MEMORY_LIMIT=256m
SERVICE_CPU_LIMIT=0.25
GATEWAY_MEMORY_LIMIT=512m
GATEWAY_CPU_LIMIT=0.5
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=70.0
```

---

### 场景 5：高配服务器（16GB+ RAM）

```bash
# .env.high-performance
EUREKA_MEMORY_LIMIT=4096m
EUREKA_CPU_LIMIT=2.0
SERVICE_MEMORY_LIMIT=2048m
SERVICE_CPU_LIMIT=1.0
GATEWAY_MEMORY_LIMIT=4096m
GATEWAY_CPU_LIMIT=2.0
JAVA_OPTS=-XX:+UseContainerSupport \
          -XX:MaxRAMPercentage=80.0 \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=100
```

---

## 🔧 高级用法

### 1. 运行时覆盖

```bash
# 临时修改某个变量
EUREKA_CLIENT_PASSWORD=newpass docker compose up -d

# 或使用 --env-file 指定文件
docker compose --env-file .env.prod up -d
```

---

### 2. 多环境管理

```bash
# 创建不同环境的配置文件
.env.dev
.env.test
.env.staging
.env.prod

# 切换环境
ln -sf .env.prod .env
docker compose up -d
```

---

### 3. 查看当前配置

```bash
# 查看所有环境变量
docker compose config

# 查看特定服务的配置
docker compose config | grep -A 20 "demo-service-a:"
```

---

### 4. 验证配置

```bash
# 检查配置是否正确
docker compose config --quiet

# 如果有错误会显示详细信息
docker compose config
```

---

## 🛡️ 安全最佳实践

### 1. 保护 .env 文件

```bash
# 设置严格权限
chmod 600 .env
chown root:root .env
```

---

### 2. 不要提交到 Git

`.env` 已在 `.gitignore` 中，但请确认：

```bash
cat .gitignore | grep ".env"
# 应该看到：.env
```

---

### 3. 使用强密码

```bash
# 生成随机密码
openssl rand -base64 32

# 或使用在线工具
# https://passwordsgenerator.net/
```

---

### 4. 定期轮换密码

```bash
# 每月更新一次
EUREKA_CLIENT_PASSWORD=NewPassword$(date +%Y%m)
GATEWAY_AUTH_TOKEN=NewToken$(date +%Y%m)
```

---

## 📝 配置示例

### 完整的生产环境配置

```bash
# .env.production

# Image
IMAGE_TAG=1.0.0
IMAGE_PREFIX=registry.example.com/eureka-pro

# Security
EUREKA_CLIENT_USERNAME=eureka-client
EUREKA_CLIENT_PASSWORD=Pr0d_Secure_Pass_2024!
GATEWAY_AUTH_ENABLED=true
GATEWAY_AUTH_TOKEN=Pr0d_Token_XYZ_789!@#

# Ports (default is fine)
EUREKA_SERVER_1_PORT=8761
EUREKA_SERVER_2_PORT=8762
DEMO_SERVICE_A_PORT=8081
DEMO_SERVICE_B_PORT=8082
GATEWAY_PORT=8080

# Resources (8GB server)
EUREKA_MEMORY_LIMIT=2048m
EUREKA_CPU_LIMIT=2.0
EUREKA_MEMORY_RESERVATION=1024m
EUREKA_CPU_RESERVATION=1.0

SERVICE_MEMORY_LIMIT=1024m
SERVICE_CPU_LIMIT=1.0
SERVICE_MEMORY_RESERVATION=512m
SERVICE_CPU_RESERVATION=0.5

GATEWAY_MEMORY_LIMIT=2048m
GATEWAY_CPU_LIMIT=2.0
GATEWAY_MEMORY_RESERVATION=1024m
GATEWAY_CPU_RESERVATION=1.0

# JVM
JAVA_OPTS=-XX:+UseContainerSupport \
          -XX:MaxRAMPercentage=75.0 \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=200 \
          -XX:+HeapDumpOnOutOfMemoryError

# Restart
RESTART_POLICY=always

# Health Check
HEALTHCHECK_INTERVAL=10s
HEALTHCHECK_TIMEOUT=5s
HEALTHCHECK_RETRIES=15
EUREKA_HEALTHCHECK_START_PERIOD=90s
SERVICE_HEALTHCHECK_START_PERIOD=60s

# Logging
LOG_DRIVER=json-file
LOG_MAX_SIZE=100m
LOG_MAX_FILE=10

# Network
NETWORK_DRIVER=bridge
```

---

## 🔍 故障排查

### 问题 1：配置未生效

```bash
# 1. 检查 .env 文件是否存在
ls -la .env

# 2. 验证配置
docker compose config

# 3. 重新加载
docker compose down
docker compose up -d
```

---

### 问题 2：端口冲突

```bash
# 查看端口占用
sudo lsof -i :8080

# 修改 .env 中的端口
GATEWAY_PORT=9080

# 重启
docker compose up -d
```

---

### 问题 3：内存不足

```bash
# 查看资源使用
docker stats

# 降低内存限制
EUREKA_MEMORY_LIMIT=512m
SERVICE_MEMORY_LIMIT=256m

# 重启
docker compose up -d
```

---

## 📚 相关文档

- [Docker 部署指南](DOCKER_DEPLOYMENT.md)
- [Docker 快速参考](DOCKER_QUICK_REFERENCE.md)
- [.env.example](.env.example) - 配置模板

---

## 💡 总结

通过集中化的环境变量管理：

✅ **简化配置** - 一个文件管理所有服务  
✅ **提高安全性** - 敏感信息不硬编码  
✅ **灵活部署** - 轻松切换不同环境  
✅ **易于维护** - 修改一处，全局生效  

**记住**：始终从 `.env.example` 创建 `.env`，并根据实际需求调整配置！
