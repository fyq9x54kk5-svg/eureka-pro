# Wrapper 环境变量快速参考

## 🚀 三种配置方式对比

```
┌─────────────────────┬──────────────────┬──────────────┬──────────────┐
│       方式          │     语法示例      │    适用场景   │    优先级     │
├─────────────────────┼──────────────────┼──────────────┼──────────────┤
│ set. 前缀           │ set.PORT=8080    │ 常规配置      │    中        │
│ (wrapper.conf)      │                  │              │              │
├─────────────────────┼──────────────────┼──────────────┼──────────────┤
│ systemd Environment │ Environment=     │ 动态配置      │    高        │
│                     │ "PORT=8080"      │              │              │
├─────────────────────┼──────────────────┼──────────────┼──────────────┤
│ EnvironmentFile     │ EnvironmentFile= │ 敏感信息      │    高        │
│                     │ /path/to/.env    │              │              │
└─────────────────────┴──────────────────┴──────────────┴──────────────┘
```

---

## 📝 常用配置示例

### Eureka Server
```properties
set.SPRING_PROFILES_ACTIVE=peer1
set.SERVER_PORT=8761
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123
```

### Gateway
```properties
set.SPRING_PROFILES_ACTIVE=default
set.SERVER_PORT=8080
set.EUREKA_PRO_GATEWAY_AUTH_ENABLED=true
set.EUREKA_PRO_GATEWAY_AUTH_TOKEN=gateway-token
```

### Demo Services
```properties
set.SPRING_PROFILES_ACTIVE=default
set.SERVER_PORT=8081
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
```

---

## 🔧 管理命令

```bash
# 查看服务的环境变量配置
sudo bash scripts/wrapper-manage.sh env eureka-peer1

# 启动服务
sudo bash scripts/wrapper-manage.sh start all

# 查看日志
sudo bash scripts/wrapper-manage.sh logs gateway

# 重启服务
sudo bash scripts/wrapper-manage.sh restart demo-service-a
```

---

## 🛡️ 敏感信息保护

```bash
# 1. 创建环境变量文件
sudo vim /opt/eureka-pro-wrapper/conf/production.env

# 2. 添加敏感配置
EUREKA_PRO_EUREKA_CLIENT_PASSWORD=SecretPass123
EUREKA_PRO_GATEWAY_AUTH_TOKEN=SecureToken456

# 3. 设置权限
sudo chmod 600 /opt/eureka-pro-wrapper/conf/production.env
sudo chown root:root /opt/eureka-pro-wrapper/conf/production.env

# 4. 在 systemd 中引用
# /etc/systemd/system/gateway.service
[Service]
EnvironmentFile=/opt/eureka-pro-wrapper/conf/production.env
```

---

## ✅ 验证配置

```bash
# 方法 1: 查看 wrapper 日志
tail -f /opt/eureka-pro-wrapper/logs/eureka-peer1.log

# 方法 2: 检查 Spring Boot 环境
curl http://localhost:8761/actuator/env | jq '.propertySources[] | select(.name == "systemEnvironment")'

# 方法 3: 查看进程环境变量
cat /proc/$(cat /opt/eureka-pro-wrapper/logs/eureka-peer1.pid)/environ | tr '\0' '\n' | grep SPRING
```

---

## 💡 最佳实践

1. **常规配置** → 使用 `set.` 前缀在 wrapper.conf 中定义
2. **敏感信息** → 使用 systemd EnvironmentFile + 严格权限
3. **动态配置** → 使用 systemd Environment 覆盖
4. **多环境** → 为每个环境创建独立的 wrapper.conf 文件
5. **版本控制** → wrapper.conf 纳入 Git，.env 文件加入 .gitignore

---

## 📚 相关文件

- 详细文档: [WRAPPER_ENVIRONMENT_VARIABLES.md](WRAPPER_ENVIRONMENT_VARIABLES.md)
- 部署指南: [WRAPPER_DEPLOYMENT.md](WRAPPER_DEPLOYMENT.md)
- 配置文件位置: `/opt/eureka-pro-wrapper/conf/wrapper-*.conf`
