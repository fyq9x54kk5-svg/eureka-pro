# Java Service Wrapper 环境变量配置指南

## 📋 Wrapper 支持环境变量的三种方式

Java Service Wrapper 提供了灵活的环境变量配置方式，与 Docker 的 `-e` 参数类似。

---

## 1️⃣ **在 wrapper.conf 中使用 `set.` 前缀（推荐）**

这是最常用和推荐的方式，直接在配置文件中定义环境变量。

### 语法
```properties
set.环境变量名=值
```

### 示例
```properties
# Spring Boot 配置
set.SPRING_PROFILES_ACTIVE=peer1
set.SERVER_PORT=8761

# 自定义业务配置
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

# Gateway 特定配置
set.EUREKA_PRO_GATEWAY_AUTH_ENABLED=true
set.EUREKA_PRO_GATEWAY_AUTH_TOKEN=gateway-token
```

### ✅ 优点
- 配置集中管理
- 版本控制友好
- 无需修改系统环境
- 每个服务独立配置

---

## 2️⃣ **在 systemd 服务文件中设置环境变量**

通过 systemd 的 `Environment` 或 `EnvironmentFile` 指令传递环境变量。

### 方式 A：直接在 service 文件中定义

编辑 `/etc/systemd/system/eureka-peer1.service`：

```ini
[Unit]
Description=Eureka Server Peer 1
After=network.target

[Service]
Type=forking
User=root
WorkingDirectory=/opt/eureka-pro-wrapper

# 环境变量
Environment="SPRING_PROFILES_ACTIVE=peer1"
Environment="SERVER_PORT=8761"
Environment="EUREKA_PEER_1=localhost:8761"
Environment="EUREKA_PEER_2=localhost:8762"

ExecStart=/opt/eureka-pro-wrapper/bin/wrapper -c /opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf
ExecStop=/opt/eureka-pro-wrapper/bin/wrapper -c /opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf -t
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 方式 B：使用环境变量文件（推荐用于敏感信息）

创建环境变量文件 `/opt/eureka-pro-wrapper/conf/eureka-peer1.env`：

```bash
SPRING_PROFILES_ACTIVE=peer1
SERVER_PORT=8761
EUREKA_PEER_1=localhost:8761
EUREKA_PEER_2=localhost:8762
EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123
```

然后在 systemd 服务文件中引用：

```ini
[Service]
EnvironmentFile=/opt/eureka-pro-wrapper/conf/eureka-peer1.env
ExecStart=/opt/eureka-pro-wrapper/bin/wrapper -c /opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf
```

设置权限保护敏感信息：
```bash
sudo chmod 600 /opt/eureka-pro-wrapper/conf/eureka-peer1.env
sudo chown root:root /opt/eureka-pro-wrapper/conf/eureka-peer1.env
```

### ✅ 优点
- 可以与 wrapper.conf 配合使用
- 适合动态配置（不同环境不同值）
- 敏感信息可以单独保护

---

## 3️⃣ **在启动脚本中导出环境变量**

在运行 wrapper 之前，在 shell 中 export 环境变量。

### 示例脚本
```bash
#!/bin/bash

# 导出环境变量
export SPRING_PROFILES_ACTIVE=peer1
export SERVER_PORT=8761
export EUREKA_PEER_1=localhost:8761
export EUREKA_PEER_2=localhost:8762

# 启动 wrapper
/opt/eureka-pro-wrapper/bin/wrapper -c /opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf
```

### ⚠️ 缺点
- 不适合 systemd 管理的守护进程
- 环境变量可能泄露到子进程
- 不推荐生产环境使用

---

## 🔧 实际应用示例

### 示例 1：Eureka Server Peer 1 完整配置

**文件**: `/opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf`

```properties
# ============================================
# Java 基础配置
# ============================================
wrapper.java.command=/usr/bin/java
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/eureka-server-1.0.0-SNAPSHOT.jar
wrapper.java.library.path.1=../lib

# ============================================
# 环境变量配置
# ============================================

# Spring Profile
set.SPRING_PROFILES_ACTIVE=peer1

# 服务器端口
set.SERVER_PORT=8761

# Eureka 实例配置
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_INSTANCE_PREFER_IP_ADDRESS=false

# Peer 节点地址
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762

# 安全认证
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

# JVM 内存配置
wrapper.java.additional.1=-Xms512m
wrapper.java.additional.2=-Xmx1024m
wrapper.java.additional.3=-XX:+UseG1GC
wrapper.java.additional.4=-XX:MaxGCPauseMillis=200

wrapper.java.initmemory=512
wrapper.java.maxmemory=1024

# 应用参数
wrapper.app.parameter.1=../lib/eureka-server-1.0.0-SNAPSHOT.jar

# 日志配置
wrapper.logfile=../logs/eureka-peer1.log
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5

# 服务信息
wrapper.name=eureka-peer1
wrapper.displayname=Eureka Server Peer 1
wrapper.description=Eureka Service Registry - Peer 1
wrapper.mode=console
wrapper.pidfile=../logs/eureka-peer1.pid
wrapper.startup.timeout=300
wrapper.shutdown.timeout=60
```

---

### 示例 2：Gateway 服务配置

**文件**: `/opt/eureka-pro-wrapper/conf/wrapper-gateway.conf`

```properties
wrapper.java.command=/usr/bin/java
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/gateway-1.0.0-SNAPSHOT.jar
wrapper.java.library.path.1=../lib

# 环境变量
set.SPRING_PROFILES_ACTIVE=default
set.SERVER_PORT=8080
set.EUREKA_INSTANCE_HOSTNAME=localhost
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
set.EUREKA_PRO_EUREKA_CLIENT_USERNAME=eureka-client
set.EUREKA_PRO_EUREKA_CLIENT_PASSWORD=client123

# Gateway 鉴权配置
set.EUREKA_PRO_GATEWAY_AUTH_ENABLED=true
set.EUREKA_PRO_GATEWAY_AUTH_TOKEN=gateway-token

# JVM 配置
wrapper.java.additional.1=-Xms512m
wrapper.java.additional.2=-Xmx1024m
wrapper.java.initmemory=512
wrapper.java.maxmemory=1024

wrapper.app.parameter.1=../lib/gateway-1.0.0-SNAPSHOT.jar
wrapper.logfile=../logs/gateway.log
wrapper.name=gateway
wrapper.displayname=API Gateway
wrapper.mode=console
wrapper.pidfile=../logs/gateway.pid
```

---

## 🔄 环境变量优先级

当多种方式同时配置时，优先级从高到低：

1. **JVM 参数** (`-Dkey=value`) - 最高优先级
2. **wrapper.conf 中的 `set.` 变量**
3. **systemd Environment**
4. **系统环境变量** (`export VAR=value`)
5. **application.yml 默认值** - 最低优先级

### 示例：覆盖配置

```properties
# wrapper.conf 中设置
set.SERVER_PORT=8761

# 如果想临时覆盖，可以在 systemd 中设置
# /etc/systemd/system/eureka-peer1.service
[Service]
Environment="SERVER_PORT=9761"  # 这会覆盖 wrapper.conf 中的值
```

---

## 🛡️ 敏感信息管理

### 最佳实践：使用独立的环境变量文件

1. **创建敏感信息文件**

```bash
sudo vim /opt/eureka-pro-wrapper/conf/production.env
```

内容：
```bash
EUREKA_PRO_EUREKA_CLIENT_PASSWORD=SuperSecretPassword123
EUREKA_PRO_GATEWAY_AUTH_TOKEN=SecureTokenXYZ
DB_PASSWORD=DatabasePassword456
```

2. **设置严格权限**

```bash
sudo chmod 600 /opt/eureka-pro-wrapper/conf/production.env
sudo chown root:root /opt/eureka-pro-wrapper/conf/production.env
```

3. **在 systemd 中引用**

```ini
[Service]
EnvironmentFile=/opt/eureka-pro-wrapper/conf/production.env
```

4. **在 wrapper.conf 中引用其他非敏感配置**

```properties
set.SPRING_PROFILES_ACTIVE=production
set.SERVER_PORT=8761
# 敏感信息从 systemd EnvironmentFile 继承
```

---

## 📝 验证环境变量是否生效

### 方法 1：查看 Wrapper 日志

```bash
tail -f /opt/eureka-pro-wrapper/logs/eureka-peer1.log
```

查找类似输出：
```
INFO   | jvm 1    | 2024/01/01 12:00:00 | Starting EurekaServerApplication...
INFO   | jvm 1    | 2024/01/01 12:00:00 | SPRING_PROFILES_ACTIVE=peer1
INFO   | jvm 1    | 2024/01/01 12:00:00 | SERVER_PORT=8761
```

### 方法 2：在应用中打印环境变量

在 Spring Boot 应用中添加调试代码：

```java
@SpringBootApplication
public class EurekaServerApplication {
    public static void main(String[] args) {
        // 打印环境变量
        System.out.println("SPRING_PROFILES_ACTIVE: " + 
            System.getenv("SPRING_PROFILES_ACTIVE"));
        System.out.println("SERVER_PORT: " + 
            System.getenv("SERVER_PORT"));
        
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
```

### 方法 3：使用 Actuator 端点

如果启用了 actuator，可以访问：

```bash
curl http://localhost:8761/actuator/env | jq '.propertySources[] | select(.name == "systemEnvironment")'
```

---

## 🎯 常见场景配置

### 场景 1：多环境部署（Dev/Test/Prod）

**开发环境** (`wrapper-eureka-peer1-dev.conf`):
```properties
set.SPRING_PROFILES_ACTIVE=dev
set.SERVER_PORT=8761
set.EUREKA_PEER_1=localhost:8761
set.EUREKA_PEER_2=localhost:8762
```

**生产环境** (`wrapper-eureka-peer1-prod.conf`):
```properties
set.SPRING_PROFILES_ACTIVE=prod
set.SERVER_PORT=8761
set.EUREKA_PEER_1=prod-eureka-1.example.com:8761
set.EUREKA_PEER_2=prod-eureka-2.example.com:8762
```

### 场景 2：动态端口分配

```bash
# 从命令行传入端口
PORT=${1:-8761}
sed -i "s/set.SERVER_PORT=.*/set.SERVER_PORT=${PORT}/" \
    /opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf
```

### 场景 3：容器化部署时的环境变量注入

如果在 Docker 中使用 Wrapper：

```dockerfile
FROM eclipse-temurin:17-jre

# 安装 Wrapper
COPY wrapper /opt/wrapper

# 设置默认环境变量
ENV SPRING_PROFILES_ACTIVE=container
ENV SERVER_PORT=8761

# 启动时可以通过 docker run -e 覆盖
ENTRYPOINT ["/opt/wrapper/bin/wrapper", "-c", "/opt/wrapper/conf/wrapper.conf"]
```

```bash
docker run -e SPRING_PROFILES_ACTIVE=prod \
           -e SERVER_PORT=9761 \
           eureka-pro/eureka-server
```

---

## ⚙️ 高级技巧

### 1. 使用变量引用

Wrapper 支持在配置中引用其他变量：

```properties
set.BASE_DIR=/opt/eureka-pro-wrapper
set.LOG_DIR=${BASE_DIR}/logs

wrapper.logfile=${LOG_DIR}/eureka-peer1.log
```

### 2. 条件配置

根据环境变量加载不同配置：

```properties
# 根据 PROFILE 加载不同的 JVM 参数
set.JAVA_OPTS_DEV=-Xms256m -Xmx512m
set.JAVA_OPTS_PROD=-Xms1024m -Xmx2048m

# 在启动脚本中选择
if [ "$SPRING_PROFILES_ACTIVE" = "prod" ]; then
    export JAVA_OPTS=$JAVA_OPTS_PROD
else
    export JAVA_OPTS=$JAVA_OPTS_DEV
fi
```

### 3. 密码加密

对于敏感密码，可以使用 Wrapper 的加密功能：

```properties
# 明文（不推荐）
set.DB_PASSWORD=mysecretpassword

# 加密（推荐）
# 使用 wrapper.exe -e 命令加密
set.DB_PASSWORD=ENC[AES256:encrypted_value_here]
```

---

## 📚 参考资料

- [Java Service Wrapper 官方文档 - Environment Variables](https://wrapper.tanukisoftware.com/doc/english/properties-set.html)
- [systemd Environment 配置](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Environment)
- [Spring Boot 外部化配置](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.external-config)

---

## 💡 总结

| 方式 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| `set.` 前缀 | 大多数场景 | 简单、集中管理 | 需要修改配置文件 |
| systemd Environment | 动态配置 | 灵活、易于自动化 | 配置分散 |
| EnvironmentFile | 敏感信息 | 安全性高 | 需要额外文件管理 |
| export | 测试调试 | 快速验证 | 不适合生产 |

**推荐组合**：
- 常规配置 → `wrapper.conf` 中的 `set.` 变量
- 敏感信息 → systemd `EnvironmentFile`
- 动态配置 → systemd `Environment`

这样既保证了配置的灵活性，又确保了安全性！
