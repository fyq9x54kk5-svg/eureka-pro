# Eureka Pro 一键部署指南

本文档介绍如何使用一键部署脚本在 Linux 服务器上快速部署 Eureka Pro 微服务平台。

---

## 📋 目录

- [Docker 部署](#docker-部署)
- [Wrapper 部署](#wrapper-部署)
- [Kubernetes 部署](#kubernetes-部署)
- [常见问题](#常见问题)

---

## 🐳 Docker 部署

### 适用场景
- ✅ 开发/测试环境
- ✅ 快速验证功能
- ✅ 团队熟悉容器技术
- ✅ 需要频繁更新

### 前置要求
- Linux 服务器（CentOS 7+ / Ubuntu 18.04+）
- 至少 4GB 内存
- 至少 10GB 磁盘空间
- root 或 sudo 权限

### 部署步骤

#### 1. 上传项目到服务器

```bash
# 在本地打包项目
cd /path/to/eureka-pro
tar czf eureka-pro.tar.gz --exclude='target' --exclude='.git' .

# 上传到服务器
scp eureka-pro.tar.gz user@your-server:/opt/

# SSH 登录并解压
ssh user@your-server
cd /opt
mkdir -p eureka-pro
tar xzf eureka-pro.tar.gz -C eureka-pro
cd eureka-pro
```

#### 2. 执行一键部署

```bash
# 赋予执行权限
chmod +x deploy/docker/deploy-docker.sh

# 执行部署（默认版本 1.0.0）
sudo bash deploy/docker/deploy-docker.sh

# 或指定版本
sudo bash deploy/docker/deploy-docker.sh 1.0.1
```

#### 3. 等待部署完成

脚本会自动完成以下步骤：
1. ✅ 检查系统环境
2. ✅ 安装 Docker 和 Docker Compose
3. ✅ 配置环境变量
4. ✅ 构建 Docker 镜像
5. ✅ 启动所有服务
6. ✅ 配置防火墙
7. ✅ 验证部署

#### 4. 访问服务

部署完成后，脚本会显示访问地址：

```
🌐 访问地址：
   Eureka Peer 1: http://YOUR_SERVER_IP:8761
   Eureka Peer 2: http://YOUR_SERVER_IP:8762
   API Gateway:   http://YOUR_SERVER_IP:8080

🔑 默认凭证：
   Eureka 控制台: admin / admin123
   Gateway Token: gateway-token
```

### 管理命令

```bash
# 查看服务状态
bash scripts/docker-manage.sh status

# 查看日志
bash scripts/docker-manage.sh logs

# 重启服务
bash scripts/docker-manage.sh restart

# 停止服务
bash scripts/docker-manage.sh down

# 清理资源
bash scripts/docker-manage.sh clean
```

---

## 📦 Wrapper 部署

### 适用场景
- ✅ 生产环境
- ✅ 追求稳定性和性能
- ✅ 传统运维团队
- ✅ 资源受限的服务器

### 前置要求
- Linux 服务器（CentOS 7+ / Ubuntu 18.04+）
- 至少 4GB 内存（推荐 8GB）
- 至少 10GB 磁盘空间
- root 或 sudo 权限

### 部署步骤

#### 1. 上传项目到服务器

```bash
# 在本地打包项目
cd /path/to/eureka-pro
tar czf eureka-pro.tar.gz --exclude='target' --exclude='.git' .

# 上传到服务器
scp eureka-pro.tar.gz user@your-server:/opt/

# SSH 登录并解压
ssh user@your-server
cd /opt
mkdir -p eureka-pro
tar xzf eureka-pro.tar.gz -C eureka-pro
cd eureka-pro
```

#### 2. 执行一键部署

```bash
# 赋予执行权限
chmod +x deploy/wrapper/deploy-wrapper.sh

# 执行部署（默认版本 1.0.0）
sudo bash deploy/wrapper/deploy-wrapper.sh

# 或指定版本
sudo bash deploy/wrapper/deploy-wrapper.sh 1.0.1
```

#### 3. 等待部署完成

脚本会自动完成以下步骤：
1. ✅ 检查系统环境
2. ✅ 安装 JDK 17
3. ✅ 安装 Maven
4. ✅ 构建项目 JAR 包
5. ✅ 安装 Java Service Wrapper
6. ✅ 配置防火墙
7. ✅ 启动所有服务
8. ✅ 设置开机自启
9. ✅ 验证部署

#### 4. 访问服务

部署完成后，脚本会显示访问地址和管理命令。

### 管理命令

```bash
# 查看所有服务状态
sudo bash scripts/wrapper-manage.sh status

# 查看特定服务日志
sudo bash scripts/wrapper-manage.sh logs eureka-peer1

# 重启服务
sudo bash scripts/wrapper-manage.sh restart gateway

# 停止所有服务
sudo bash scripts/wrapper-manage.sh stop all

# 使用 systemd 命令
systemctl status eureka-peer1
journalctl -u eureka-peer1 -f
```

---

## ☸️ Kubernetes 部署

### 适用场景
- ✅ 大规模生产环境
- ✅ 需要高可用和弹性伸缩
- ✅ 已有 K8s 集群
- ✅ 云原生架构

### 前置要求
- Kubernetes 集群（Minikube / Kind / K3s / 生产集群）
- kubectl 已配置
- Docker 已安装（用于构建镜像）
- 至少 8GB 内存（集群总资源）

### 部署步骤

#### 1. 准备 K8s 集群

```bash
# Minikube 示例
minikube start --memory=8192 --cpus=4

# Kind 示例
kind create cluster

# 验证集群
kubectl cluster-info
kubectl get nodes
```

#### 2. 上传项目到服务器

```bash
# 在本地打包项目
cd /path/to/eureka-pro
tar czf eureka-pro.tar.gz --exclude='target' --exclude='.git' .

# 上传到服务器
scp eureka-pro.tar.gz user@your-server:/opt/

# SSH 登录并解压
ssh user@your-server
cd /opt
mkdir -p eureka-pro
tar xzf eureka-pro.tar.gz -C eureka-pro
cd eureka-pro
```

#### 3. 执行一键部署

```bash
# 赋予执行权限
chmod +x deploy/k8s/deploy-k8s.sh

# 执行部署（默认命名空间 eureka-pro）
bash deploy/k8s/deploy-k8s.sh 1.0.0 eureka-pro

# 或自定义命名空间
bash deploy/k8s/deploy-k8s.sh 1.0.0 my-namespace
```

#### 4. 等待部署完成

脚本会自动完成以下步骤：
1. ✅ 检查前置条件
2. ✅ 构建并加载 Docker 镜像
3. ✅ 创建命名空间
4. ✅ 创建 ConfigMap 和 Secret
5. ✅ 部署 Eureka Server
6. ✅ 部署微服务
7. ✅ 部署 Gateway
8. ✅ 验证部署

#### 5. 访问服务

```bash
# 方式一：端口转发（推荐用于测试）
kubectl port-forward -n eureka-pro svc/eureka-server 8761:8761
kubectl port-forward -n eureka-pro svc/gateway 8080:8080

# 然后访问 http://localhost:8761 和 http://localhost:8080

# 方式二：NodePort（如果配置了）
kubectl get svc -n eureka-pro gateway
# 获取 NodePort 后访问 http://NODE_IP:NODE_PORT
```

### 管理命令

```bash
# 查看所有资源
kubectl get all -n eureka-pro

# 查看 Pod 状态
kubectl get pods -n eureka-pro

# 查看日志
kubectl logs -n eureka-pro -l app=gateway -f

# 进入容器
kubectl exec -it -n eureka-pro <pod-name> -- sh

# 删除部署
kubectl delete -k deploy/k8s
```

---

## ❓ 常见问题

### Q1: 部署失败怎么办？

**A:** 查看日志文件定位问题：

```bash
# Docker 部署日志
cat /tmp/eureka-pro-docker-deploy-*.log

# Wrapper 部署日志
cat /tmp/eureka-pro-wrapper-deploy-*.log

# K8s 部署日志
cat /tmp/eureka-pro-k8s-deploy-*.log
```

### Q2: 如何修改默认密码？

**A:** 

- **Docker**: 编辑 `.env` 文件
- **Wrapper**: 编辑 `/opt/eureka-pro-wrapper/conf/wrapper-*.conf`
- **K8s**: 编辑 `deploy/k8s/secret.yaml`

### Q3: 端口被占用怎么办？

**A:** 

- **Docker**: 修改 `.env` 中的端口配置
- **Wrapper**: 修改 wrapper 配置文件中的端口
- **K8s**: 修改 Service YAML 文件中的端口

### Q4: 如何更新版本？

**A:** 

```bash
# Docker
bash deploy/docker/deploy-docker.sh 1.0.1

# Wrapper
sudo bash deploy/wrapper/deploy-wrapper.sh 1.0.1

# K8s
bash deploy/k8s/deploy-k8s.sh 1.0.1 eureka-pro
```

### Q5: 如何完全卸载？

**A:** 

```bash
# Docker
bash scripts/docker-manage.sh down
docker system prune -a

# Wrapper
sudo bash scripts/wrapper-uninstall.sh

# K8s
kubectl delete -k deploy/k8s
kubectl delete namespace eureka-pro
```

---

## 📚 相关文档

- [Docker 详细部署指南](../DOCKER_DEPLOYMENT.md)
- [Wrapper 详细部署指南](../WRAPPER_DEPLOYMENT.md)
- [环境变量配置指南](../ENV_CONFIGURATION_GUIDE.md)
- [部署方案对比](../DEPLOYMENT_COMPARISON.md)

---

## 💡 提示

1. **首次部署建议使用 Docker**，快速验证功能
2. **生产环境推荐使用 Wrapper**，获得更好的性能和稳定性
3. **大规模部署使用 Kubernetes**，实现高可用和弹性伸缩
4. **务必修改默认密码**，特别是生产环境
5. **定期备份配置和数据**
6. **配置监控和告警**，及时发现问题

---

**祝部署顺利！** 🎉
