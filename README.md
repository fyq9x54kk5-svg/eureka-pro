# eureka-pro

基于 Spring Cloud Netflix Eureka 的可改造实验项目，包含：**注册中心鉴权、多节点高可用、Gateway 统一入口**。

## 技术栈

- JDK 17
- Spring Boot 3.2.2
- Spring Cloud 2023.0.0
- Eureka Server / Eureka Client / OpenFeign / Spring Cloud Gateway

## 模块结构

| 模块 | 端口 | 说明 |
|------|------|------|
| `eureka-common` | - | 通用响应体等公共代码 |
| `eureka-server` | 8761 / 8762 | 注册中心（支持单节点与双节点 HA） |
| `gateway` | 8080 | API 网关，基于 Eureka 服务发现转发 |
| `demo-service-a` | 8081 | 示例服务 A，`/api/hello` |
| `demo-service-b` | 8082 | 示例服务 B，Feign 调用 A |

## 快速启动

### 方式一：Docker 部署（推荐）

```bash
# 一键构建并启动
bash scripts/docker-manage.sh up

# 或使用旧版脚本
bash scripts/docker-up.sh 1.0.0
```

📚 详细文档：[Docker 部署指南](DOCKER_DEPLOYMENT.md) | [快速参考](DOCKER_QUICK_REFERENCE.md)

### 方式二：JAR 包直接运行

```bash
bash scripts/build.sh
bash scripts/start-all.sh   # 查看启动命令
```

### 方式三：Java Service Wrapper（生产环境）

```bash
# Linux 系统部署
sudo bash scripts/wrapper-install.sh
sudo bash scripts/wrapper-manage.sh start all
```

📚 详细文档：[Wrapper 部署指南](WRAPPER_DEPLOYMENT.md) | [环境变量配置](WRAPPER_ENVIRONMENT_VARIABLES.md)

📊 方案对比：[Docker vs Wrapper](DEPLOYMENT_COMPARISON.md)

### 推荐：高可用双节点 Eureka

```bash
# 终端 1
java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar --spring.profiles.active=peer1

# 终端 2
java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar --spring.profiles.active=peer2

# 终端 3-5
java -jar gateway/target/gateway-1.0.0-SNAPSHOT.jar
java -jar demo-service-a/target/demo-service-a-1.0.0-SNAPSHOT.jar
java -jar demo-service-b/target/demo-service-b-1.0.0-SNAPSHOT.jar
```

### 单节点模式（开发调试）

```bash
java -jar eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar
# 其余服务照常启动（client 会尝试连 8762，连不上不影响 8761 注册）
```

## 验证

| 场景 | 命令 / 地址 |
|------|-------------|
| Eureka 控制台 | http://localhost:8761 （admin / admin123） |
| HA 第二节点控制台 | http://localhost:8762 |
| 管理 API | http://localhost:8761/admin/registry/summary |
| Gateway → A | `curl http://localhost:8080/api/a/hello` |
| Gateway → B | `curl -H "X-Auth-Token: gateway-token" http://localhost:8080/api/b/call-a` |
| 直连 A | `curl http://localhost:8081/api/hello` |
| 直连 B | `curl http://localhost:8082/api/call-a` |

## 鉴权体系

### 1. 控制台 / 管理 API（Form Login）

| 账号 | 密码 | 角色 | 权限 |
|------|------|------|------|
| admin | admin123 | ADMIN, VIEWER | 控制台 + `/admin/**` |
| viewer | viewer123 | VIEWER | 控制台只读 |

配置位置：`eureka-server/src/main/resources/application.yml` → `eureka-pro.security.users`

### 2. 注册中心 API（HTTP Basic）

| 账号 | 密码 | 角色 | 用途 |
|------|------|------|------|
| eureka-client | client123 | CLIENT | 微服务注册/续约、节点间同步 |

- `/eureka/**` 必须携带 Basic 认证（`CLIENT` 角色）
- 微服务通过 URL 嵌入凭证连接注册中心：

```yaml
eureka:
  client:
    service-url:
      defaultZone: http://eureka-client:client123@localhost:8761/eureka/,http://eureka-client:client123@localhost:8762/eureka/
```

### 3. Gateway 路由鉴权

- `/api/a/**` 无需 token
- `/api/b/**` 需要请求头 `X-Auth-Token: gateway-token`

配置：`gateway/src/main/resources/application.yml` → `eureka-pro.gateway.auth`

## 高可用架构

```
                    ┌─────────────┐     ┌─────────────┐
                    │  peer1:8761 │◄───►│  peer2:8762 │
                    └──────┬──────┘     └──────┬──────┘
                           │    互相同步注册表    │
              ┌────────────┼────────────────────┼────────────┐
              ▼            ▼                    ▼            ▼
         gateway:8080  service-a:8081    service-b:8082   ...
```

- `application-peer1.yml`：8761，peer 指向 8762
- `application-peer2.yml`：8762，peer 指向 8761
- 所有 client 配置双 `defaultZone`，任意节点存活即可注册

Peer 同步同样使用 `eureka-client:client123` 凭证。

## Gateway 路由

| 外部路径 | 目标服务 | 转发后路径 |
|----------|----------|------------|
| `/api/a/**` | demo-service-a | `/api/**` |
| `/api/b/**` | demo-service-b | `/api/**` |

示例：`/api/a/hello` → `demo-service-a` 的 `/api/hello`

## 关键代码

| 能力 | 文件 |
|------|------|
| 注册中心 + 控制台鉴权 | `eureka-server/.../config/EurekaSecurityConfig.java` |
| 用户配置 | `eureka-server/.../config/EurekaSecurityProperties.java` |
| HA 配置 | `eureka-server/src/main/resources/application-peer1.yml` |
| Gateway 路由 | `gateway/src/main/resources/application.yml` |
| Gateway 鉴权 | `gateway/.../filter/GatewayAuthFilter.java` |
| 增强控制台 | `eureka-server/src/main/resources/templates/eureka/*.ftlh` |

## Docker 部署

### 构建镜像

```bash
bash scripts/docker-build.sh 1.0.0
```

会构建 4 个镜像：`eureka-pro/eureka-server`、`gateway`、`demo-service-a`、`demo-service-b`。

### 一键启动（Docker Compose）

```bash
bash scripts/docker-up.sh
```

| 服务 | 地址 |
|------|------|
| Eureka 节点 1 | http://localhost:8761 |
| Eureka 节点 2 | http://localhost:8762 |
| Gateway | http://localhost:8080 |

```bash
curl http://localhost:8080/api/a/hello
curl -H "X-Auth-Token: gateway-token" http://localhost:8080/api/b/call-a
```

停止：`docker compose down`

容器环境使用 `container` profile，通过环境变量 `EUREKA_PEER_1` / `EUREKA_PEER_2` 配置注册中心地址。

## Kubernetes 部署

### 前置条件

- 本地 K8s 集群（minikube / kind / Docker Desktop Kubernetes）
- `kubectl` 已配置
- 已构建镜像（见上方 Docker 构建）

**kind 集群**需先加载镜像：

```bash
kind load docker-image eureka-pro/eureka-server:1.0.0
kind load docker-image eureka-pro/gateway:1.0.0
kind load docker-image eureka-pro/demo-service-a:1.0.0
kind load docker-image eureka-pro/demo-service-b:1.0.0
```

### 部署

```bash
bash scripts/k8s-deploy.sh 1.0.0
```

或手动：

```bash
kubectl apply -k deploy/k8s
kubectl -n eureka-pro rollout status statefulset/eureka-server
```

### K8s 架构

| 资源 | 说明 |
|------|------|
| `StatefulSet/eureka-server` | 2 副本 HA，Headless Service 提供 DNS |
| `Deployment/gateway` | NodePort 30080 |
| `Deployment/demo-service-a/b` | 集群内 Service |
| `ConfigMap/eureka-pro-config` | Peer 地址、公共配置 |
| `Secret/eureka-pro-secret` | 注册中心密码、Gateway token |

| 访问（NodePort） | 地址 |
|------------------|------|
| Gateway | http://localhost:30080 |
| Eureka 控制台 | http://localhost:30761 |

```bash
kubectl -n eureka-pro get pods,svc
kubectl -n eureka-pro logs -f statefulset/eureka-server
```

卸载：

```bash
kubectl delete -k deploy/k8s
```

## 📦 部署方案选择

本项目支持多种部署方式，根据您的需求选择：

| 方案 | 适用场景 | 难度 | 文档 |
|------|---------|------|------|
| **Docker Compose** | 开发、测试、快速部署 | ⭐⭐ | [Docker 指南](DOCKER_DEPLOYMENT.md) |
| **Java Service Wrapper** | 生产环境、传统运维 | ⭐⭐⭐ | [Wrapper 指南](WRAPPER_DEPLOYMENT.md) |
| **Kubernetes** | 大规模、云原生 | ⭐⭐⭐⭐ | K8s 配置在 `deploy/k8s/` |
| **JAR 直接运行** | 简单测试、学习 | ⭐ | 本文档上方 |

📊 详细对比：[Docker vs Wrapper 对比分析](DEPLOYMENT_COMPARISON.md)

### 推荐路径

- **初学者**：Docker Compose → 理解架构 → JAR 运行 → Wrapper
- **生产环境**：Wrapper（稳定）或 Docker（云原生）
- **团队协作**：Docker（环境一致）+ CI/CD

### 部署文件目录

```
deploy/k8s/
├── namespace.yaml
├── configmap.yaml
├── secret.yaml
├── eureka-server-service.yaml
├── eureka-server-statefulset.yaml
├── demo-service-a.yaml
├── demo-service-b.yaml
├── gateway.yaml
└── kustomization.yaml
```

Docker 相关：

```
Dockerfile
docker-compose.yml
scripts/docker-build.sh
scripts/docker-up.sh
scripts/k8s-deploy.sh
```
