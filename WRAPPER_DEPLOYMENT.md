# Java Service Wrapper 部署指南

本文档介绍如何使用 **Java Service Wrapper (JSW)** 在 Linux 系统上部署 Eureka Pro 项目。

## 📋 什么是 Java Service Wrapper？

Java Service Wrapper 是一个成熟的工具，用于将 Java 应用程序包装成系统守护进程（daemon），提供以下优势：

- ✅ **自动重启**：应用崩溃时自动重启
- ✅ **日志管理**：自动日志轮转和归档
- ✅ **进程监控**：实时监控 JVM 状态
- ✅ **优雅关闭**：确保应用正确关闭
- ✅ **系统集成**：与 systemd/init.d 完美集成
- ✅ **资源控制**：限制内存、CPU 等资源使用

## 🚀 快速开始

### 1. 前置条件

确保 Linux 服务器已安装：

```bash
# JDK 17
java -version

# Maven（可选，如果需要在服务器上构建）
mvn -version

# systemd（大多数现代 Linux 发行版默认安装）
systemctl --version
```

### 2. 上传项目到服务器

```bash
# 从开发机器上传整个项目
scp -r /Users/admin/corsor/eureka-pro user@your-linux-server:/opt/

# 进入项目目录
ssh user@your-linux-server
cd /opt/eureka-pro
```

### 3. 一键安装

```bash
# 赋予执行权限
chmod +x scripts/wrapper-*.sh

# 运行安装脚本（需要 root 权限）
sudo bash scripts/wrapper-install.sh
```

安装脚本会自动完成以下步骤：
1. 构建项目（生成 JAR 包）
2. 下载 Java Service Wrapper
3. 创建安装目录 `/opt/eureka-pro-wrapper`
4. 配置所有服务的 wrapper 配置文件
5. 创建 systemd 服务文件
6. 设置文件权限

### 4. 启动服务

#### 方式一：使用管理脚本（推荐）

```bash
# 启动所有服务（按依赖顺序）
sudo bash scripts/wrapper-manage.sh start all

# 或逐个启动
sudo bash scripts/wrapper-manage.sh start eureka-peer1
sudo bash scripts/wrapper-manage.sh start eureka-peer2
sleep 10  # 等待 Eureka 完全启动
sudo bash scripts/wrapper-manage.sh start demo-service-a
sudo bash scripts/wrapper-manage.sh start demo-service-b
sudo bash scripts/wrapper-manage.sh start gateway
```

#### 方式二：使用 systemctl

```bash
# 启动所有服务
sudo systemctl start eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway

# 设置开机自启
sudo systemctl enable eureka-peer1 eureka-peer2 demo-service-a demo-service-b gateway
```

### 5. 验证部署

```bash
# 查看服务状态
sudo bash scripts/wrapper-manage.sh status

# 检查端口
sudo netstat -tlnp | grep -E '8761|8762|8080|8081|8082'

# 访问 Eureka 控制台
curl http://localhost:8761

# 测试 Gateway
curl http://localhost:8080/api/a/hello
curl -H "X-Auth-Token: gateway-token" http://localhost:8080/api/b/call-a
```

## 📊 服务管理

### 常用命令

```bash
# 查看所有服务状态
sudo bash scripts/wrapper-manage.sh status

# 启动指定服务
sudo bash scripts/wrapper-manage.sh start eureka-peer1

# 停止指定服务
sudo bash scripts/wrapper-manage.sh stop gateway

# 重启指定服务
sudo bash scripts/wrapper-manage.sh restart demo-service-a

# 查看实时日志
sudo bash scripts/wrapper-manage.sh logs eureka-peer1

# 使用 systemctl 管理
sudo systemctl status eureka-peer1
sudo systemctl restart gateway
sudo journalctl -u eureka-peer1 -f
```

### 服务列表

| 服务名称 | 端口 | 说明 |
|---------|------|------|
| `eureka-peer1` | 8761 | Eureka 注册中心节点 1 |
| `eureka-peer2` | 8762 | Eureka 注册中心节点 2 |
| `demo-service-a` | 8081 | 示例微服务 A |
| `demo-service-b` | 8082 | 示例微服务 B |
| `gateway` | 8080 | API 网关 |

## 📁 目录结构

```
/opt/eureka-pro-wrapper/
├── bin/
│   └── wrapper              # Wrapper 可执行文件
├── lib/
│   ├── wrapper.jar          # Wrapper Java 库
│   ├── libwrapper.so        # Wrapper  native 库
│   ├── eureka-server-1.0.0-SNAPSHOT.jar
│   ├── gateway-1.0.0-SNAPSHOT.jar
│   ├── demo-service-a-1.0.0-SNAPSHOT.jar
│   └── demo-service-b-1.0.0-SNAPSHOT.jar
├── conf/
│   ├── wrapper-eureka-peer1.conf
│   ├── wrapper-eureka-peer2.conf
│   ├── wrapper-gateway.conf
│   ├── wrapper-demo-a.conf
│   └── wrapper-demo-b.conf
└── logs/
    ├── eureka-peer1.log
    ├── eureka-peer2.log
    ├── gateway.log
    ├── demo-service-a.log
    ├── demo-service-b.log
    └── *.pid                # PID 文件
```

## ⚙️ 配置调优

### 修改 JVM 参数

编辑对应的 wrapper 配置文件，例如 `/opt/eureka-pro-wrapper/conf/wrapper-eureka-peer1.conf`：

```properties
# 调整堆内存
wrapper.java.additional.5=-Xms1024m
wrapper.java.additional.6=-Xmx2048m

wrapper.java.initmemory=1024
wrapper.java.maxmemory=2048

# 添加 GC 日志
wrapper.java.additional.7=-XX:+PrintGCDetails
wrapper.java.additional.8=-XX:+PrintGCDateStamps
wrapper.java.additional.9=-Xloggc:../logs/gc-eureka-peer1.log
```

### 修改日志配置

```properties
# 日志文件大小和数量
wrapper.logfile.maxsize=50m      # 单个日志文件最大 50MB
wrapper.logfile.maxfiles=10      # 保留 10 个历史日志文件

# 日志级别
wrapper.logfile.loglevel=DEBUG   # DEBUG, INFO, WARN, ERROR
```

### 修改启动超时

```properties
# 如果应用启动较慢，增加超时时间
wrapper.startup.timeout=600      # 600 秒（默认 300 秒）
```

## 🔧 故障排查

### 1. 服务无法启动

```bash
# 查看详细日志
sudo journalctl -u eureka-peer1 -xe
tail -100 /opt/eureka-pro-wrapper/logs/eureka-peer1.log

# 检查端口占用
sudo netstat -tlnp | grep 8761

# 检查 Java 版本
java -version
```

### 2. 内存不足

```bash
# 查看 JVM 内存使用
jmap -heap $(cat /opt/eureka-pro-wrapper/logs/eureka-peer1.pid)

# 调整 wrapper 配置中的内存参数
```

### 3. 自动重启问题

```bash
# 查看重启历史
journalctl -u eureka-peer1 | grep "Started"

# 检查 wrapper 日志中的重启原因
grep "restart" /opt/eureka-pro-wrapper/logs/eureka-peer1.log
```

### 4. Wrapper 常见问题

**问题**: Wrapper 下载失败  
**解决**: 手动下载并放置到 `/tmp/wrapper-linux-x86-64-3.5.51.tar.gz`

**问题**: 权限错误  
**解决**: 确保以 root 运行安装脚本，或调整文件权限

**问题**: systemd 服务启动失败  
**解决**: 检查 `/etc/systemd/system/*.service` 文件中的路径是否正确

## 🔄 更新应用

当代码有更新时：

```bash
# 1. 停止服务
sudo bash scripts/wrapper-manage.sh stop all

# 2. 重新构建项目
cd /opt/eureka-pro
bash scripts/build.sh

# 3. 复制新的 JAR 包
cp eureka-server/target/eureka-server-1.0.0-SNAPSHOT.jar /opt/eureka-pro-wrapper/lib/
cp gateway/target/gateway-1.0.0-SNAPSHOT.jar /opt/eureka-pro-wrapper/lib/
cp demo-service-a/target/demo-service-a-1.0.0-SNAPSHOT.jar /opt/eureka-pro-wrapper/lib/
cp demo-service-b/target/demo-service-b-1.0.0-SNAPSHOT.jar /opt/eureka-pro-wrapper/lib/

# 4. 启动服务
sudo bash scripts/wrapper-manage.sh start all
```

## 🗑️ 卸载

```bash
# 停止所有服务
sudo bash scripts/wrapper-manage.sh stop all

# 运行卸载脚本
sudo bash scripts/wrapper-uninstall.sh
```

## 📝 Wrapper 配置文件详解

每个服务的配置文件位于 `/opt/eureka-pro-wrapper/conf/`，主要配置项：

```properties
# Java 命令路径
wrapper.java.command=/usr/bin/java

# 主类（不要修改）
wrapper.java.mainclass=org.tanukisoftware.wrapper.WrapperJarApp

# Classpath
wrapper.java.classpath.1=../lib/wrapper.jar
wrapper.java.classpath.2=../lib/your-app.jar

# JVM 参数
wrapper.java.additional.1=-Dspring.profiles.active=peer1
wrapper.java.additional.2=-Dserver.port=8761

# 内存配置
wrapper.java.initmemory=512     # 初始堆内存 (MB)
wrapper.java.maxmemory=1024     # 最大堆内存 (MB)

# 日志配置
wrapper.logfile=../logs/service.log
wrapper.logfile.maxsize=10m
wrapper.logfile.maxfiles=5

# 服务信息
wrapper.name=service-name
wrapper.displayname=Service Display Name
wrapper.description=Service Description

# 运行模式
wrapper.mode=console            # console, jsw, nt_service

# PID 文件
wrapper.pidfile=../logs/service.pid

# 超时设置
wrapper.startup.timeout=300     # 启动超时 (秒)
wrapper.shutdown.timeout=60     # 关闭超时 (秒)
```

## 🎯 最佳实践

1. **启动顺序**：先启动 Eureka Server，等待完全启动后再启动业务服务
2. **内存分配**：根据服务器总内存合理分配各服务的堆内存
3. **日志监控**：定期检查日志文件大小，配置合理的轮转策略
4. **健康检查**：使用 `curl` 定期检查服务健康状态
5. **备份配置**：定期备份 wrapper 配置文件
6. **监控告警**：集成监控系统（如 Prometheus + Grafana）监控服务状态

## 📚 参考资料

- [Java Service Wrapper 官方文档](https://wrapper.tanukisoftware.com/)
- [systemd 服务管理](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [Spring Boot 生产部署](https://docs.spring.io/spring-boot/docs/current/reference/html/deployment.html)

---

**提示**: 对于生产环境，建议结合配置管理工具（如 Ansible、Puppet）自动化部署流程。
