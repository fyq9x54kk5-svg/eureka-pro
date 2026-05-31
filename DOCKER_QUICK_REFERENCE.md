# Docker 快速参考指南

## 🚀 常用命令速查

### 一键操作

```bash
# 构建 + 启动
bash scripts/docker-manage.sh up

# 查看日志
bash scripts/docker-manage.sh logs

# 查看状态
bash scripts/docker-manage.sh status

# 停止服务
bash scripts/docker-manage.sh down
```

---

## 📦 镜像管理

```bash
# 构建所有镜像
bash scripts/docker-build.sh 1.0.0

# 构建单个服务
docker build --build-arg MODULE=gateway -t eureka-pro/gateway:1.0.0 .

# 查看本地镜像
docker images | grep eureka-pro

# 删除镜像
docker rmi eureka-pro/eureka-server:1.0.0

# 清理未使用镜像
docker image prune -f
```

---

## 🏃 容器管理

```bash
# 启动（后台）
docker compose up -d

# 停止
docker compose down

# 重启
docker compose restart

# 重启特定服务
docker compose restart gateway

# 查看运行状态
docker compose ps

# 进入容器
docker compose exec gateway sh

# 查看资源使用
docker stats

# 强制停止
docker compose kill
```

---

## 📋 日志查看

```bash
# 所有服务实时日志
docker compose logs -f

# 特定服务
docker compose logs -f eureka-server-1

# 最近 100 行
docker compose logs --tail=100 gateway

# 导出到文件
docker compose logs > logs.txt 2>&1

# 带时间戳
docker compose logs -f -t
```

---

## 🔧 故障排查

```bash
# 检查健康状态
docker inspect --format='{{.State.Health.Status}}' eureka-server-1

# 查看详细信息
docker inspect eureka-server-1

# 测试端口
curl http://localhost:8761/actuator/health

# 检查网络
docker network ls
docker network inspect eureka-pro_eureka-net

# 查看进程
docker top eureka-server-1

# 复制文件
docker cp eureka-server-1:/app/app.jar ./backup.jar
```

---

## 🌐 网络管理

```bash
# 查看网络
docker network ls

# 创建网络
docker network create eureka-net

# 连接容器到网络
docker network connect eureka-net container_name

# 断开连接
docker network disconnect eureka-net container_name

# 删除网络
docker network rm eureka-net
```

---

## 💾 数据卷管理

```bash
# 查看卷
docker volume ls

# 创建卷
docker volume create eureka-data

# 删除未使用卷
docker volume prune

# 挂载卷
docker run -v eureka-data:/app/data image_name
```

---

## 🧹 清理命令

```bash
# 清理停止的容器
docker container prune -f

# 清理未使用镜像
docker image prune -f

# 清理未使用卷
docker volume prune -f

# 清理未使用网络
docker network prune -f

# 深度清理（全部）
docker system prune -a --volumes -f

# 清理构建缓存
docker builder prune -f
```

---

## ⚙️ 环境变量

```bash
# 查看容器环境变量
docker exec eureka-server-1 env | grep SPRING

# 运行时设置环境变量
docker run -e SPRING_PROFILES_ACTIVE=prod image_name

# 从文件加载
docker run --env-file .env image_name
```

---

## 📊 监控命令

```bash
# 实时资源监控
docker stats

# 单次快照
docker stats --no-stream

# 格式化输出
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# 查看进程树
docker top eureka-server-1 -eo pid,comm

# 查看日志大小
du -sh /var/lib/docker/containers/*/ *-json.log
```

---

## 🔄 更新流程

```bash
# 1. 拉取代码
git pull

# 2. 构建新镜像
bash scripts/docker-build.sh 1.0.1

# 3. 滚动更新
docker compose up -d --no-deps --build gateway

# 4. 验证
curl http://localhost:8080/api/a/hello

# 5. 回滚（如需）
docker compose up -d --no-deps eureka-pro/gateway:1.0.0
```

---

## 🛡️ 安全命令

```bash
# 扫描镜像漏洞
docker scan eureka-pro/eureka-server:1.0.0

# 以非 root 运行
docker run --user 1000:1000 image_name

# 限制内存
docker run --memory=512m --memory-swap=512m image_name

# 限制 CPU
docker run --cpus=0.5 image_name

# 只读文件系统
docker run --read-only image_name
```

---

## 🎯 Eureka Pro 特定命令

```bash
# 访问 Eureka 控制台
open http://localhost:8761  # macOS
xdg-open http://localhost:8761  # Linux

# 测试 Gateway
curl http://localhost:8080/api/a/hello
curl -H "X-Auth-Token: gateway-token" http://localhost:8080/api/b/call-a

# 查看 Eureka 注册信息
curl http://admin:admin123@localhost:8761/eureka/apps

# 检查服务发现
curl http://localhost:8761/eureka/apps/demo-service-a
```

---

## 📝 Compose 快捷方式

```bash
# 扩展服务实例
docker compose up -d --scale demo-service-a=3

# 仅构建不启动
docker compose build

# 仅启动不构建
docker compose up -d --no-build

# 重新创建容器
docker compose up -d --force-recreate

# 无依赖启动
docker compose up -d --no-deps gateway

# 指定配置文件
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## 🔍 调试技巧

```bash
# 查看容器 IP
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name

# 查看端口映射
docker port container_name

# 查看挂载卷
docker inspect -f '{{json .Mounts}}' container_name

# 查看环境变量
docker inspect -f '{{json .Config.Env}}' container_name

# 查看启动命令
docker inspect -f '{{json .Config.Cmd}}' container_name

# 实时查看文件变化
docker exec -it container_name watch -n 1 'ls -la /app/logs'
```

---

## 💡 实用别名

添加到 `~/.bashrc` 或 `~/.zshrc`：

```bash
# Docker Compose 快捷方式
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dps='docker compose ps'
alias dr='docker compose restart'

# Docker 快捷方式
alias di='docker images'
alias dps-all='docker ps -a'
alias drm='docker rm $(docker ps -aq)'
alias dclean='docker system prune -f'

# Eureka Pro 特定
alias eureka-up='bash scripts/docker-manage.sh up'
alias eureka-logs='bash scripts/docker-manage.sh logs'
alias eureka-status='bash scripts/docker-manage.sh status'
```

---

## 📚 更多信息

- 完整文档: [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- Docker 官方文档: https://docs.docker.com/
- Compose 参考: https://docs.docker.com/compose/reference/
