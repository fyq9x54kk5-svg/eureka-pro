# Docker 部署完整指南

本文档介绍如何使用 Docker 和 Docker Compose 部署 Eureka Pro 微服务平台。

## 📋 前置条件

- **Docker**: 20.10+ 
- **Docker Compose**: v2.0+
- **内存**: 至少 4GB 可用内存
- **磁盘**: 至少 5GB 可用空间

### 检查安装

```bash
docker --version
docker compose version
```

---

## 🚀 快速开始

### 方式一：一键启动（推荐）

```bash
# 构建并启动所有服务
bash scripts/docker-manage.sh up

# 或者使用 docker-up.sh（旧版）
bash scripts/docker-up.sh 1.0.0
```

### 方式二：分步执行

```bash
# 1. 构建镜像
bash scripts/docker-build.sh 1.0.0

# 2. 启动服务
docker compose up -d

# 3. 查看状态
docker compose ps
```

---

## 📦 镜像构建优化

### Dockerfile 特性

✅ **多阶段构建** - 减小最终镜像体积  
✅ **依赖缓存** - 加速重复构建  
✅ **非 root 用户** - 提升安全性  
✅ **Tini init** - 正确处理信号  
✅ **JVM 优化** - 容器感知内存管理  

### 构建单个服务

```bash
# 只构建 Gateway
docker build --build-arg MODULE=gateway -t eureka-pro/gateway:1.0.0 .

# 只构建 Eureka Server
docker build --build-arg MODULE=eureka-server -t eureka-pro/eureka-server:1.0.0 .
```

### 清理构建缓存

```bash
# 清理未使用的构建缓存
docker builder prune

# 深度清理
docker builder prune -a
```

---

## ⚙️ 环境变量配置

### 使用 .env 文件

项目根目录的 `.env` 文件可以覆盖默认配置：

```bash
# 复制示例文件
cp .env.example .env

# 编辑配置
vim .env
```

### 常用配置项

```bash
# 镜像标签
IMAGE_TAG=1.0.0

# Eureka 凭证
EUREKA_CLIENT_PASSWORD=YourSecurePassword

# Gateway Token
GATEWAY_AUTH_TOKEN=YourSecureToken

# 资源限制
EUREKA_MEMORY_LIMIT=2048m
SERVICE_MEMORY_LIMIT=1024m

# JVM 参数
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0
```

### 运行时覆盖

```bash
# 临时覆盖环境变量
EUREKA_CLIENT_PASSWORD=newpass docker compose up -d

# 或使用 docker run
docker run -e EUREKA_CLIENT_PASSWORD=newpass eureka-pro/eureka-server:1.0.0
```

---

## 🔧 服务管理

### 使用管理脚本（推荐）

```bash
# 查看所有命令
bash scripts/docker-manage.sh

# 构建镜像
bash scripts/docker-manage.sh build 1.0.0

# 启动服务
bash scripts/docker-manage.sh up

# 查看日志
bash scripts/docker-manage.sh logs

# 查看状态和资源使用
bash scripts/docker-manage.sh status

# 重启服务
bash scripts/docker-manage.sh restart

# 停止服务
bash scripts/docker-manage.sh down

# 清理资源
bash scripts/docker-manage.sh clean
```

### 使用 Docker Compose 命令

```bash
# 启动
docker compose up -d

# 停止
docker compose down

# 重启特定服务
docker compose restart gateway

# 查看日志
docker compose logs -f eureka-server-1

# 查看特定服务日志
docker compose logs -f --tail=100 gateway

# 进入容器
docker compose exec gateway sh

# 查看服务列表
docker compose ps

# 扩展服务实例
docker compose up -d --scale demo-service-a=3
```

---

## 📊 监控与日志

### 查看容器状态

```bash
# 基本状态
docker compose ps

# 详细资源使用
docker stats

# 格式化输出
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### 日志管理

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务
docker compose logs -f gateway

# 查看最近 100 行
docker compose logs --tail=100 eureka-server-1

# 导出日志到文件
docker compose logs > all-services.log 2>&1
```

### 日志配置

在 `docker-compose.yml` 中已配置日志轮转：

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "50m"    # 单个日志文件最大 50MB
    max-file: "5"      # 保留 5 个历史文件
    tag: "gateway"     # 日志标签
```

---

## 🛡️ 安全最佳实践

### 1. 修改默认密码

编辑 `.env` 文件：

```bash
EUREKA_CLIENT_PASSWORD=SuperSecurePassword123!
GATEWAY_AUTH_TOKEN=RandomSecureTokenXYZ789
```

### 2. 使用 Docker Secrets（生产环境）

创建 secret 文件：

```bash
echo "SuperSecurePassword" | docker secret create eureka_password -
echo "SecureToken" | docker secret create gateway_token -
```

在 docker-compose.yml 中使用：

```yaml
services:
  eureka-server-1:
    secrets:
      - eureka_password
      - gateway_token

secrets:
  eureka_password:
    external: true
  gateway_token:
    external: true
```

### 3. 网络隔离

当前配置已使用独立的 Docker 网络 `eureka-net`，外部只能通过映射的端口访问。

### 4. 非 root 用户

Dockerfile 已配置以非 root 用户运行应用，提升安全性。

---

## 🔍 故障排查

### 服务无法启动

```bash
# 1. 查看详细日志
docker compose logs eureka-server-1

# 2. 检查端口占用
sudo lsof -i :8761
sudo lsof -i :8762
sudo lsof -i :8080

# 3. 检查容器状态
docker compose ps

# 4. 进入容器调试
docker compose exec eureka-server-1 sh
```

### 健康检查失败

```bash
# 查看健康检查状态
docker inspect --format='{{.State.Health.Status}}' eureka-server-1

# 手动测试健康端点
curl http://localhost:8761/actuator/health

# 调整健康检查参数（在 .env 中）
HEALTHCHECK_START_PERIOD=120s
HEALTHCHECK_RETRIES=15
```

### 内存不足

```bash
# 查看资源使用
docker stats

# 调整内存限制（在 .env 中）
EUREKA_MEMORY_LIMIT=2048m
SERVICE_MEMORY_LIMIT=1024m

# 重启生效
docker compose up -d
```

### 网络连接问题

```bash
# 检查网络
docker network ls
docker network inspect eureka-net

# 测试容器间连通性
docker compose exec demo-service-a ping eureka-server-1

# 重建网络
docker compose down
docker network rm eureka-pro_eureka-net
docker compose up -d
```

### 镜像构建失败

```bash
# 清理缓存重新构建
docker builder prune -f
bash scripts/docker-build.sh 1.0.0

# 检查 Docker 版本
docker --version
docker compose version

# 更新 Docker
sudo apt-get update && sudo apt-get upgrade docker-ce
```

---

## 🔄 更新与升级

### 更新应用代码

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建镜像
bash scripts/docker-build.sh 1.0.1

# 3. 滚动更新（零停机）
docker compose up -d --no-deps --build gateway

# 4. 验证新版本
curl http://localhost:8080/api/a/hello

# 5. 更新其他服务
docker compose up -d --no-deps --build demo-service-a
docker compose up -d --no-deps --build demo-service-b
```

### 回滚到旧版本

```bash
# 停止当前版本
docker compose down

# 使用旧镜像启动
IMAGE_TAG=1.0.0 docker compose up -d
```

---

## 📈 性能优化

### 1. JVM 调优

在 `.env` 中调整：

```bash
# Eureka Server（需要更多内存）
JAVA_OPTS=-XX:+UseContainerSupport \
          -XX:MaxRAMPercentage=75.0 \
          -XX:+UseG1GC \
          -XX:MaxGCPauseMillis=200 \
          -XX:InitiatingHeapOccupancyPercent=35

# Demo Services（较小内存）
JAVA_OPTS=-XX:+UseContainerSupport \
          -XX:MaxRAMPercentage=70.0 \
          -XX:+UseG1GC
```

### 2. 构建加速

使用 BuildKit：

```bash
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# 构建时启用缓存
docker compose build --progress=plain
```

### 3. 资源限制

根据服务器配置调整 `.env`：

```bash
# 小服务器（4GB RAM）
EUREKA_MEMORY_LIMIT=512m
SERVICE_MEMORY_LIMIT=256m
GATEWAY_MEMORY_LIMIT=512m

# 中等服务器（8GB RAM）
EUREKA_MEMORY_LIMIT=1024m
SERVICE_MEMORY_LIMIT=512m
GATEWAY_MEMORY_LIMIT=1024m

# 大服务器（16GB+ RAM）
EUREKA_MEMORY_LIMIT=2048m
SERVICE_MEMORY_LIMIT=1024m
GATEWAY_MEMORY_LIMIT=2048m
```

---

## 🎯 生产环境建议

### 1. 使用固定标签

不要使用 `latest` 标签，始终使用版本号：

```bash
IMAGE_TAG=1.0.0  # ✅ 好
IMAGE_TAG=latest # ❌ 不好
```

### 2. 镜像仓库

推送到私有镜像仓库：

```bash
# 登录
docker login registry.example.com

# 打标签
docker tag eureka-pro/eureka-server:1.0.0 \
           registry.example.com/eureka-pro/eureka-server:1.0.0

# 推送
docker push registry.example.com/eureka-pro/eureka-server:1.0.0
```

### 3. 备份数据

```bash
# 备份配置
tar czf eureka-pro-config-backup.tar.gz .env docker-compose.yml

# 备份日志
docker compose logs > backup-$(date +%Y%m%d).log
```

### 4. 监控集成

集成 Prometheus + Grafana：

```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
```

---

## 📚 相关文档

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 参考](https://docs.docker.com/compose/reference/)
- [Spring Boot Docker](https://spring.io/guides/topicals/spring-boot-docker/)
- [Wrapper 部署指南](WRAPPER_DEPLOYMENT.md) - 传统部署方式

---

## 💡 常见问题

**Q: 如何修改服务端口？**  
A: 在 `.env` 中设置 `SERVER_PORT`，或修改 `docker-compose.yml` 中的端口映射。

**Q: 如何在后台运行？**  
A: 使用 `docker compose up -d`（-d 表示 detached mode）。

**Q: 如何查看某个服务的 IP？**  
A: `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name`

**Q: 如何限制 CPU 使用？**  
A: 在 `.env` 中设置 `EUREKA_CPU_LIMIT=0.5`（50% CPU）。

**Q: 如何持久化日志？**  
A: 挂载卷：`volumes: - ./logs:/app/logs`

---

**提示**: 对于生产环境，建议结合 CI/CD 工具（如 Jenkins、GitLab CI）自动化构建和部署流程。
