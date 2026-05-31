# Docker 部署快速故障排除指南

## 🔴 常见错误及解决方案

### 1. 权限错误

```bash
[ERROR] 请使用 sudo 或 root 用户运行此脚本
```

**解决**:
```bash
sudo bash deploy/docker/deploy-docker.sh
```

---

### 2. 内存不足

```bash
[ERROR] 内存不足 2GB (1024MB)，无法部署
```

**解决**:
```bash
# 方案 1: 增加服务器内存（推荐）

# 方案 2: 降低资源限制
cp .env.example .env
vi .env
# 修改:
EUREKA_MEMORY_LIMIT=512m
SERVICE_MEMORY_LIMIT=256m
GATEWAY_MEMORY_LIMIT=512m
```

---

### 3. 磁盘空间不足

```bash
[ERROR] 磁盘空间不足 5GB (3072MB)，无法部署
```

**解决**:
```bash
# 清理空间
docker system prune -a
rm -rf /tmp/*
yum clean all  # CentOS
apt-get clean  # Ubuntu

# 查看占用
df -h
du -sh /var/log/*
```

---

### 4. 端口被占用

```bash
[WARN] 端口 8080 已被占用
```

**解决**:
```bash
# 查找占用进程
ss -tlnp | grep 8080
# 或
netstat -tlnp | grep 8080

# 停止进程
kill -9 <PID>

# 或修改端口
vi .env
GATEWAY_PORT=8888
```

---

### 5. Docker 安装失败

```bash
[ERROR] Docker 安装失败
```

**解决**:
```bash
# 手动安装
curl -fsSL https://get.docker.com | sh

# 或使用国内镜像
curl -fsSL https://get.docker.com | sh -s docker --mirror Aliyun

# 启动服务
systemctl start docker
systemctl enable docker
```

---

### 6. Docker 服务未启动

```bash
[ERROR] 无法启动 Docker 服务
```

**解决**:
```bash
# 查看状态
systemctl status docker

# 查看日志
journalctl -u docker.service -f

# 重启服务
systemctl restart docker

# 检查配置文件
cat /etc/docker/daemon.json
```

---

### 7. 网络连接失败

```bash
[WARN] 无法访问外网，Docker 安装可能失败
```

**解决**:
```bash
# 测试网络
ping 8.8.8.8
ping docker.com

# 配置代理（如果需要）
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port

# 配置 Docker 镜像源
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF
systemctl restart docker
```

---

### 8. DNS 解析失败

```bash
[WARN] DNS 解析可能有问题
```

**解决**:
```bash
# 添加公共 DNS
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

# 测试
nslookup docker.com
```

---

### 9. 内核版本过低

```bash
[ERROR] 内核版本过低 (2.6.32)，Docker 需要 3.10+
```

**解决**:
```bash
# 升级系统（推荐）
# CentOS
yum update

# Ubuntu
apt-get update && apt-get upgrade

# 重启
reboot

# 或更换更高版本的服务器
```

---

### 10. Docker Socket 权限错误

```bash
[ERROR] Docker socket 不可写，请检查权限
```

**解决**:
```bash
# 修复权限
chmod 666 /var/run/docker.sock

# 或将用户加入 docker 组
usermod -aG docker $USER
newgrp docker
```

---

### 11. 项目文件缺失

```bash
[ERROR] 缺少必要文件: pom.xml
```

**解决**:
```bash
# 确认当前目录
pwd
# 应该是: /path/to/eureka-pro

# 检查文件
ls -la pom.xml Dockerfile docker-compose.yml

# 从 Git 恢复
git checkout .
```

---

### 12. 镜像构建失败

```bash
[ERROR] 镜像构建失败
```

**解决**:
```bash
# 查看详细错误
bash scripts/docker-build.sh 1.0.0

# 清理并重试
docker system prune -a
bash scripts/docker-build.sh 1.0.0

# 配置 Maven 镜像
mkdir -p ~/.m2
cat > ~/.m2/settings.xml <<EOF
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <url>https://maven.aliyun.com/repository/public</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
EOF
```

---

### 13. 服务启动超时

```bash
[ERROR] 服务启动超时
```

**解决**:
```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs --tail=100

# 检查资源
docker stats

# 增加 JVM 内存
vi .env
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=60.0

# 重新启动
bash scripts/docker-manage.sh restart
```

---

### 14. 健康检查失败

```bash
[WARN] ⚠️  Eureka Server (8761) 健康检查失败
```

**解决**:
```bash
# 等待更长时间
sleep 60

# 手动检查
curl http://localhost:8761/actuator/health

# 查看日志
docker logs eureka-server-1

# 检查端口
docker port eureka-server-1

# 进入容器调试
docker exec -it eureka-server-1 sh
ps aux | grep java
```

---

### 15. API 访问失败

```bash
[WARN] ⚠️  API 接口访问失败
```

**解决**:
```bash
# 检查 Gateway
curl http://localhost:8080/actuator/health

# 检查 Demo Service A
curl http://localhost:8081/actuator/health

# 查看 Gateway 日志
docker logs gateway

# 测试直连
curl http://localhost:8081/api/a/hello

# 检查路由配置
cat gateway/src/main/resources/application.yml
```

---

## 🔧 常用诊断命令

### 查看容器状态
```bash
docker compose ps
```

### 查看实时日志
```bash
docker compose logs -f
```

### 查看特定服务日志
```bash
docker logs -f eureka-server-1
docker logs -f gateway
```

### 查看资源使用
```bash
docker stats
```

### 进入容器调试
```bash
docker exec -it eureka-server-1 sh
docker exec -it gateway sh
```

### 检查端口映射
```bash
docker port eureka-server-1
docker port gateway
```

### 查看网络配置
```bash
docker network ls
docker network inspect eureka-pro_default
```

### 清理资源
```bash
# 停止服务
docker compose down

# 删除所有容器和镜像
docker compose down -v --rmi all

# 清理系统
docker system prune -a
```

---

## 📞 获取帮助

### 1. 查看部署日志
```bash
ls -lt /tmp/eureka-pro-docker-deploy-*.log
cat /tmp/eureka-pro-docker-deploy-最新.log
```

### 2. 查看详细文档
```bash
# 环境检查说明
less deploy/docker/ENVIRONMENT_CHECK.md

# 增强说明
less deploy/docker/ENHANCEMENT_SUMMARY.md

# 完整部署指南
less DOCKER_DEPLOYMENT.md
```

### 3. 在线资源
- Docker 官方文档: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- Spring Boot: https://spring.io/projects/spring-boot

---

## ✅ 部署成功验证清单

部署完成后，确认以下各项：

- [ ] 所有 5 个容器运行正常
- [ ] Eureka Server 1 (8761) 可访问
- [ ] Eureka Server 2 (8762) 可访问
- [ ] Gateway (8080) 可访问
- [ ] Demo Service A (8081) 可访问
- [ ] Demo Service B (8082) 可访问
- [ ] API 接口返回正确结果
- [ ] 服务已注册到 Eureka
- [ ] 防火墙规则已配置
- [ ] 日志文件已保存

**快速验证命令**:
```bash
# 1. 检查容器
docker compose ps

# 2. 测试 Eureka
curl http://localhost:8761/actuator/health

# 3. 测试 Gateway
curl http://localhost:8080/actuator/health

# 4. 测试 API
curl http://localhost:8080/api/a/hello

# 5. 测试认证 API
curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a
```

---

**最后更新**: 2026-05-31  
**适用版本**: deploy-docker.sh v2.0.0+
