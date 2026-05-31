# Docker 部署环境检查清单

本文档详细说明 `deploy-docker.sh` 脚本执行的环境检查项及处理方案。

---

## 📋 检查项目总览

部署脚本会自动执行以下检查：

1. ✅ 权限检查
2. ✅ 操作系统兼容性
3. ✅ 必要命令检查
4. ✅ 内存检查
5. ✅ 磁盘空间检查
6. ✅ 端口占用检查
7. ✅ 网络连接检查
8. ✅ DNS 解析检查
9. ✅ 内核版本检查
10. ✅ cgroup 支持检查
11. ✅ Swap 交换空间检查
12. ✅ Docker Socket 权限检查
13. ✅ Docker 服务状态检查
14. ✅ Docker Compose 版本检查
15. ✅ 项目文件完整性检查
16. ✅ Maven 依赖检查

---

## 🔍 详细检查说明

### 1. 权限检查

**检查内容**: 是否以 root 或 sudo 权限运行

**失败处理**:
```bash
# 错误信息
[ERROR] 请使用 sudo 或 root 用户运行此脚本

# 解决方案
sudo bash deploy-docker.sh
```

---

### 2. 操作系统兼容性

**检查内容**: 是否为支持的 Linux 发行版

**支持的系統**:
- CentOS 7+
- RHEL 7+
- Fedora
- Ubuntu 18.04+
- Debian 9+

**失败处理**:
```bash
# 警告信息
[WARN] 未测试的操作系统: xxx，可能不兼容

# 解决方案
# 1. 确认系统兼容性后手动输入 y 继续
# 2. 或在受支持的操作系统上部署
```

---

### 3. 必要命令检查

**检查内容**: curl, wget, git 是否存在

**失败处理**:
```bash
# 警告信息
[WARN] 缺少命令: xxx，将在下一步安装

# 解决方案
# 脚本会自动安装缺失的命令，无需手动干预
```

---

### 4. 内存检查

**检查内容**: 系统可用内存

**要求**:
- ❌ < 2GB: **无法部署**（强制退出）
- ⚠️ 2-4GB: **可以部署**（性能警告）
- ✅ > 4GB: **推荐配置**

**失败处理**:
```bash
# 错误信息（< 2GB）
[ERROR] 内存不足 2GB (xxxMB)，无法部署
[INFO] 建议：至少 4GB 内存，推荐 8GB

# 解决方案
# 1. 增加服务器内存
# 2. 调整 .env 中的资源限制：
EUREKA_MEMORY_LIMIT=512m
SERVICE_MEMORY_LIMIT=256m
GATEWAY_MEMORY_LIMIT=512m
```

---

### 5. 磁盘空间检查

**检查内容**: /opt 分区可用空间

**要求**:
- ❌ < 5GB: **无法部署**（强制退出）
- ⚠️ 5-10GB: **可以部署**（空间警告）
- ✅ > 10GB: **推荐配置**

**失败处理**:
```bash
# 错误信息（< 5GB）
[ERROR] 磁盘空间不足 5GB (xxxMB)，无法部署
[INFO] 建议：清理磁盘空间或扩展分区

# 解决方案
# 1. 清理磁盘空间
df -h
du -sh /var/log/*
rm -rf /tmp/*

# 2. 清理 Docker 缓存
docker system prune -a

# 3. 扩展分区或挂载新磁盘
```

---

### 6. 端口占用检查

**检查内容**: 以下端口是否被占用
- 8761 (Eureka Server 1)
- 8762 (Eureka Server 2)
- 8080 (Gateway)
- 8081 (Demo Service A)
- 8082 (Demo Service B)

**失败处理**:
```bash
# 警告信息
[WARN] 端口 8080 已被占用

# 解决方案
# 1. 查找占用端口的进程
ss -tlnp | grep 8080
# 或
netstat -tlnp | grep 8080

# 2. 停止占用端口的服务
systemctl stop <service-name>
# 或
kill -9 <pid>

# 3. 或修改 .env 中的端口配置
GATEWAY_PORT=8888
```

---

### 7. 网络连接检查

**检查内容**: 是否可以访问外网（下载 Docker）

**失败处理**:
```bash
# 警告信息
[WARN] 无法访问外网，Docker 安装可能失败
[INFO] 如果已离线安装 Docker，可以忽略此警告

# 解决方案
# 1. 检查网络配置
ping 8.8.8.8

# 2. 检查代理设置
echo $http_proxy
echo $https_proxy

# 3. 离线安装 Docker
# 参考: https://docs.docker.com/engine/install/binaries/

# 4. 配置国内镜像源
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

### 8. DNS 解析检查

**检查内容**: DNS 是否正常解析

**失败处理**:
```bash
# 警告信息
[WARN] DNS 解析可能有问题
[INFO] 建议检查 /etc/resolv.conf 配置

# 解决方案
# 1. 检查 DNS 配置
cat /etc/resolv.conf

# 2. 添加公共 DNS（脚本自动尝试）
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "nameserver 114.114.114.114" >> /etc/resolv.conf

# 3. 测试 DNS 解析
nslookup docker.com
dig docker.com
```

---

### 9. 内核版本检查

**检查内容**: Linux 内核版本 >= 3.10

**要求**:
- ❌ < 3.10: **无法部署**（强制退出）
- ✅ >= 3.10: **符合要求**

**失败处理**:
```bash
# 错误信息
[ERROR] 内核版本过低 (x.x.x)，Docker 需要 3.10+
[INFO] 建议：升级系统内核或更换服务器

# 解决方案
# 1. 查看当前内核版本
uname -r

# 2. 升级内核（CentOS）
yum update kernel

# 3. 升级内核（Ubuntu）
apt-get install linux-generic

# 4. 重启系统
reboot
```

---

### 10. cgroup 支持检查

**检查内容**: `/sys/fs/cgroup` 是否存在

**失败处理**:
```bash
# 警告信息
[WARN] 未检测到 cgroup 文件系统
[INFO] 容器资源限制可能无法生效

# 解决方案
# 1. 检查 cgroup 挂载
mount | grep cgroup

# 2. 启用 cgroup（ systemd 系统通常默认启用）
# 大多数现代 Linux 发行版已默认启用

# 3. 如使用 LXC/LXD 容器，需特殊配置
```

---

### 11. Swap 交换空间检查

**检查内容**: 是否启用 Swap

**影响**: Java 应用在 Swap 上性能较差

**失败处理**:
```bash
# 警告信息
[WARN] 检测到交换空间: xxxMB
[INFO] Java 应用在 Swap 上性能较差，建议禁用 Swap

# 解决方案
# 1. 临时禁用 Swap
sudo swapoff -a

# 2. 永久禁用 Swap
# 编辑 /etc/fstab，注释掉 swap 行
sudo vi /etc/fstab
# 在 swap 行前添加 #

# 3. 验证
free -h
```

---

### 12. Docker Socket 权限检查

**检查内容**: `/var/run/docker.sock` 是否可写

**失败处理**:
```bash
# 错误信息
[ERROR] Docker socket 不可写，请检查权限
[INFO] 修复: sudo chmod 666 /var/run/docker.sock

# 解决方案
# 1. 修复权限
sudo chmod 666 /var/run/docker.sock

# 2. 或将用户加入 docker 组
sudo usermod -aG docker $USER
newgrp docker

# 3. 重启 Docker 服务
sudo systemctl restart docker
```

---

### 13. Docker 服务状态检查

**检查内容**: Docker daemon 是否运行

**失败处理**:
```bash
# 错误信息
[ERROR] 无法启动 Docker 服务
[INFO] 请手动执行: sudo systemctl start docker

# 解决方案
# 1. 启动 Docker
sudo systemctl start docker

# 2. 设置开机自启
sudo systemctl enable docker

# 3. 检查状态
sudo systemctl status docker

# 4. 查看日志
sudo journalctl -u docker.service -f
```

---

### 14. Docker Compose 版本检查

**检查内容**: Docker Compose V1 或 V2 是否安装

**支持版本**:
- ✅ Docker Compose V2 (推荐)
- ⚠️ Docker Compose V1 (可用但不推荐)

**失败处理**:
```bash
# 如果未安装，脚本会自动安装 V2

# 手动安装 V2
DOCKER_COMPOSE_VERSION="v2.20.0"
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 验证
docker compose version
```

---

### 15. 项目文件完整性检查

**检查内容**: 必要文件是否存在
- pom.xml
- Dockerfile
- docker-compose.yml
- .env.example

**失败处理**:
```bash
# 错误信息
[ERROR] 缺少必要文件: xxx
[INFO] 请确保在项目根目录运行此脚本

# 解决方案
# 1. 确认当前目录
pwd
# 应该显示: /path/to/eureka-pro

# 2. 检查文件
ls -la pom.xml Dockerfile docker-compose.yml .env.example

# 3. 如果文件丢失，从 Git 恢复
git checkout pom.xml Dockerfile docker-compose.yml .env.example
```

---

### 16. Maven 依赖检查

**检查内容**: Maven 或 Maven Wrapper 是否存在

**失败处理**:
```bash
# 警告信息
[WARN] 未检测到 Maven，将使用 Docker 多阶段构建
[INFO] 首次构建可能需要较长时间（下载依赖）

# 解决方案
# 1. 安装 Maven（可选，加速构建）
# CentOS
yum install -y maven

# Ubuntu
apt-get install -y maven

# 2. 或使用 Maven Wrapper（项目自带）
./mvnw clean package

# 3. 或直接使用 Docker 多阶段构建（脚本默认方式）
```

---

## 🛠️ 常见问题解决

### 问题 1: Docker 安装失败

**症状**: 
```
[ERROR] Docker 安装失败
```

**解决方案**:
```bash
# 1. 手动安装 Docker
curl -fsSL https://get.docker.com | sh

# 2. 或使用官方文档
# https://docs.docker.com/engine/install/

# 3. 检查系统兼容性
cat /etc/os-release
uname -r
```

---

### 问题 2: 镜像构建失败

**症状**:
```
[ERROR] 镜像构建失败
```

**解决方案**:
```bash
# 1. 查看详细错误
bash scripts/docker-build.sh 1.0.0

# 2. 检查网络（需要下载 Maven 依赖）
ping repo.maven.apache.org

# 3. 配置 Maven 国内镜像
mkdir -p ~/.m2
cat > ~/.m2/settings.xml <<EOF
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
  </mirrors>
</settings>
EOF

# 4. 清理并重新构建
docker system prune -a
bash scripts/docker-build.sh 1.0.0
```

---

### 问题 3: 服务启动超时

**症状**:
```
[ERROR] 服务启动超时
```

**解决方案**:
```bash
# 1. 查看容器状态
docker compose ps

# 2. 查看日志
docker compose logs --tail=100

# 3. 检查资源使用情况
docker stats

# 4. 增加等待时间（修改脚本中的 max_wait 变量）

# 5. 调整 JVM 参数（减少内存需求）
# 编辑 .env 文件
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=60.0
```

---

### 问题 4: 健康检查失败

**症状**:
```
[WARN] ⚠️  Eureka Server (8761) 健康检查失败
```

**解决方案**:
```bash
# 1. 等待更长时间（服务可能还在启动）
sleep 60

# 2. 手动检查健康状态
curl http://localhost:8761/actuator/health

# 3. 查看容器日志
docker logs eureka-server-1

# 4. 检查端口映射
docker port eureka-server-1

# 5. 进入容器调试
docker exec -it eureka-server-1 sh
```

---

## 📊 检查流程图

```
开始部署
  ↓
检查 root 权限 ────→ 失败: 退出
  ↓ 成功
检查操作系统 ────→ 不支持: 询问是否继续
  ↓ 支持
检查必要命令 ────→ 缺失: 记录（稍后安装）
  ↓
检查内存 ────→ < 2GB: 退出
  ↓           2-4GB: 警告并询问
  ↓           > 4GB: 通过
检查磁盘空间 ────→ < 5GB: 退出
  ↓           5-10GB: 警告并询问
  ↓           > 10GB: 通过
检查端口占用 ────→ 占用: 警告并询问
  ↓
检查网络连接 ────→ 失败: 警告并询问
  ↓
检查 DNS 解析 ────→ 失败: 尝试修复
  ↓
检查内核版本 ────→ < 3.10: 退出
  ↓           >= 3.10: 通过
检查 cgroup ────→ 缺失: 警告
  ↓
检查 Swap ────→ 启用: 警告
  ↓
检查 Docker Socket ────→ 不可写: 退出
  ↓
安装依赖软件
  ↓
检查 Docker 状态 ────→ 未运行: 启动
  ↓           启动失败: 退出
  ↓
检查 Docker Compose ────→ 未安装: 安装
  ↓
检查项目文件 ────→ 缺失: 退出
  ↓
构建镜像 ────→ 失败: 退出
  ↓ 成功
启动服务 ────→ 失败: 退出
  ↓ 成功
验证部署 ────→ 失败: 提供诊断信息
  ↓ 成功
部署完成 ✅
```

---

## 💡 最佳实践建议

### 1. 部署前准备

```bash
# 1. 更新系统
sudo yum update -y  # CentOS
sudo apt-get update && sudo apt-get upgrade -y  # Ubuntu

# 2. 清理磁盘空间
sudo yum clean all
sudo apt-get autoremove -y

# 3. 禁用 Swap（可选但推荐）
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 4. 配置防火墙
sudo firewall-cmd --permanent --add-port=8761/tcp
sudo firewall-cmd --permanent --add-port=8762/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### 2. 资源配置建议

**开发环境** (4GB RAM):
```bash
EUREKA_MEMORY_LIMIT=512m
SERVICE_MEMORY_LIMIT=256m
GATEWAY_MEMORY_LIMIT=512m
```

**测试环境** (8GB RAM):
```bash
EUREKA_MEMORY_LIMIT=1024m
SERVICE_MEMORY_LIMIT=512m
GATEWAY_MEMORY_LIMIT=1024m
```

**生产环境** (16GB+ RAM):
```bash
EUREKA_MEMORY_LIMIT=2048m
SERVICE_MEMORY_LIMIT=1024m
GATEWAY_MEMORY_LIMIT=2048m
```

### 3. 监控和维护

```bash
# 1. 定期检查容器状态
docker compose ps

# 2. 查看资源使用
docker stats

# 3. 清理无用镜像和容器
docker system prune -a

# 4. 备份配置文件
cp .env .env.backup.$(date +%Y%m%d)

# 5. 查看日志
docker compose logs -f --tail=100
```

---

## 📞 获取帮助

如果遇到问题：

1. **查看日志文件**:
   ```bash
   cat /tmp/eureka-pro-docker-deploy-*.log
   ```

2. **查看容器日志**:
   ```bash
   docker compose logs
   ```

3. **检查系统资源**:
   ```bash
   free -h
   df -h
   top
   ```

4. **参考文档**:
   - [DOCKER_DEPLOYMENT.md](../../DOCKER_DEPLOYMENT.md)
   - [ENV_CONFIGURATION_GUIDE.md](../../ENV_CONFIGURATION_GUIDE.md)
   - [Docker 官方文档](https://docs.docker.com/)

---

**最后更新**: 2026-05-31  
**脚本版本**: deploy-docker.sh v1.0.0
