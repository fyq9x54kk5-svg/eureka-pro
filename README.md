# eureka-pro

基于 Spring Cloud Netflix Eureka 的可改造实验项目，用于学习、验证和二次开发注册中心能力。

## 技术栈

- JDK 17
- Spring Boot 3.2.2
- Spring Cloud 2023.0.0
- Eureka Server / Eureka Client / OpenFeign

## 模块结构

| 模块 | 端口 | 说明 |
|------|------|------|
| `eureka-common` | - | 通用响应体等公共代码 |
| `eureka-server` | 8761 | 注册中心（主要改造入口） |
| `demo-service-a` | 8081 | 示例服务 A，提供 `/api/hello` |
| `demo-service-b` | 8082 | 示例服务 B，通过 Feign 调用 A |

## 快速启动

前置条件：本机已安装 JDK 17 和 Maven。

```bash
# 编译
bash scripts/build.sh

# 按顺序启动（建议开 3 个终端）
mvn -f eureka-server/pom.xml spring-boot:run
mvn -f demo-service-a/pom.xml spring-boot:run
mvn -f demo-service-b/pom.xml spring-boot:run
```

## 验证

1. Eureka 控制台：`http://localhost:8761`
2. 自定义注册表摘要：`http://localhost:8761/admin/registry/summary`
3. 服务 A：`curl http://localhost:8081/api/hello`
4. 服务 B 通过服务发现调用 A：`curl http://localhost:8082/api/call-a`

## 改造入口（推荐从这里改）

### 1. 注册事件监听

`eureka-server/src/main/java/com/example/eurekapro/server/extension/EurekaRegistryEventListener.java`

可扩展：

- 实例注册/下线审计
- 告警通知
- 自定义 metadata 校验

### 2. 管理接口

`eureka-server/src/main/java/com/example/eurekapro/server/extension/RegistryAdminController.java`

可扩展：

- 手动下线实例
- 查询/修改实例 metadata
- 灰度权重、标签管理

### 3. Server 配置

`eureka-server/src/main/java/com/example/eurekapro/server/config/EurekaServerCustomizationConfig.java`

`eureka-server/src/main/resources/application.yml`

可扩展：

- 自我保护策略
- Peer 高可用
- 缓存与剔除间隔

## 常见改造方向

- 增加鉴权（Dashboard / Admin API）
- 接入 Prometheus / 自定义 metrics
- 替换或增强实例健康检查逻辑
- 增加多环境隔离（dev/test/prod 注册隔离）
- 与 Gateway、Config Server 组合成完整微服务底座

## 与 spring-lab 的关系

你本地的 `Spring` 项目是一个更完整的微服务面试实验项目；`eureka-pro` 聚焦 Eureka 本身，结构更轻，便于专门做注册中心改造。
