#!/usr/bin/env bash
# =============================================================================
# Eureka Pro - Kubernetes 一键部署脚本
# 用途：在 Kubernetes 集群中部署 Eureka Pro 微服务平台
# 使用方法：bash deploy-k8s.sh [版本号] [namespace]
# 示例：bash deploy-k8s.sh 1.0.0 eureka-pro
# =============================================================================

set -euo pipefail

# ==================== 配置变量 ====================
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
K8S_DIR="$ROOT_DIR/deploy/k8s"
VERSION="${1:-1.0.0}"
NAMESPACE="${2:-eureka-pro}"
LOG_FILE="/tmp/eureka-pro-k8s-deploy-$(date +%Y%m%d-%H%M%S).log"

# 颜色定义（用于美化输出）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# ==================== 工具函数 ====================

# 打印信息日志
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# 打印成功日志
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# 打印警告日志
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

# 打印错误日志
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# ==================== 步骤 1：检查前置条件 ====================
check_prerequisites() {
    log_info "=========================================="
    log_info "步骤 1: 检查前置条件"
    log_info "=========================================="
    
    # 检查 kubectl 是否安装
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl 未安装，请先安装 kubectl"
        log_info "安装指南: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        exit 1
    fi
    log_success "kubectl 已安装: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
    
    # 检查 Kubernetes 集群连接
    log_info "检查 Kubernetes 集群连接..."
    if kubectl cluster-info &> /dev/null; then
        log_success "已连接到 Kubernetes 集群"
        kubectl cluster-info | head -n 2
    else
        log_error "无法连接到 Kubernetes 集群"
        log_info "请确认："
        log_info "  1. Minikube/Kind/K3s 等集群已启动"
        log_info "  2. kubeconfig 配置正确"
        exit 1
    fi
    
    # 检查 Docker 是否安装（用于构建镜像）
    if ! command -v docker &> /dev/null; then
        log_warn "Docker 未安装，将无法构建镜像"
    else
        log_success "Docker 已安装: $(docker --version)"
    fi
    
    log_success "前置条件检查完成"
    echo ""
}

# ==================== 步骤 2：构建并加载 Docker 镜像 ====================
build_and_load_images() {
    log_info "=========================================="
    log_info "步骤 2: 构建并加载 Docker 镜像"
    log_info "=========================================="
    
    cd "$ROOT_DIR"
    
    # 检测集群类型
    CLUSTER_TYPE=""
    if kubectl config current-context 2>/dev/null | grep -q "minikube"; then
        CLUSTER_TYPE="minikube"
        log_info "检测到 Minikube 集群"
    elif kubectl config current-context 2>/dev/null | grep -q "kind"; then
        CLUSTER_TYPE="kind"
        log_info "检测到 Kind 集群"
    else
        log_info "使用标准 Docker 镜像（需要镜像仓库）"
    fi
    
    # 构建镜像
    log_info "构建 Docker 镜像（版本: $VERSION）..."
    chmod +x scripts/docker-build.sh
    bash scripts/docker-build.sh "$VERSION"
    
    # 根据集群类型加载镜像
    if [ "$CLUSTER_TYPE" = "minikube" ]; then
        log_info "加载镜像到 Minikube..."
        minikube image load eureka-pro/eureka-server:$VERSION || true
        minikube image load eureka-pro/gateway:$VERSION || true
        minikube image load eureka-pro/demo-service-a:$VERSION || true
        minikube image load eureka-pro/demo-service-b:$VERSION || true
        log_success "镜像已加载到 Minikube"
        
    elif [ "$CLUSTER_TYPE" = "kind" ]; then
        log_info "加载镜像到 Kind..."
        kind load docker-image eureka-pro/eureka-server:$VERSION || true
        kind load docker-image eureka-pro/gateway:$VERSION || true
        kind load docker-image eureka-pro/demo-service-a:$VERSION || true
        kind load docker-image eureka-pro/demo-service-b:$VERSION || true
        log_success "镜像已加载到 Kind"
    else
        log_warn "请将镜像推送到镜像仓库，或手动加载到集群节点"
    fi
    
    log_success "镜像构建和加载完成"
    echo ""
}

# ==================== 步骤 3：创建命名空间 ====================
create_namespace() {
    log_info "=========================================="
    log_info "步骤 3: 创建命名空间"
    log_info "=========================================="
    
    # 检查命名空间是否已存在
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "命名空间 $NAMESPACE 已存在"
    else
        log_info "创建命名空间 $NAMESPACE..."
        kubectl apply -f "$K8S_DIR/namespace.yaml"
        log_success "命名空间创建完成"
    fi
    
    log_success "命名空间准备完成"
    echo ""
}

# ==================== 步骤 4：创建 ConfigMap 和 Secret ====================
create_config_and_secret() {
    log_info "=========================================="
    log_info "步骤 4: 创建 ConfigMap 和 Secret"
    log_info "=========================================="
    
    # 应用 ConfigMap（包含公共配置）
    log_info "创建 ConfigMap..."
    kubectl apply -f "$K8S_DIR/configmap.yaml" -n "$NAMESPACE"
    log_success "ConfigMap 创建完成"
    
    # 应用 Secret（包含敏感信息）
    log_info "创建 Secret..."
    kubectl apply -f "$K8S_DIR/secret.yaml" -n "$NAMESPACE"
    log_success "Secret 创建完成"
    
    # 显示创建的配置文件
    log_info "已创建的配置："
    kubectl get configmap,secret -n "$NAMESPACE" || true
    
    log_success "配置创建完成"
    echo ""
}

# ==================== 步骤 5：部署 Eureka Server ====================
deploy_eureka_server() {
    log_info "=========================================="
    log_info "步骤 5: 部署 Eureka Server"
    log_info "=========================================="
    
    # 部署 Eureka Service（Headless Service 用于 StatefulSet）
    log_info "创建 Eureka Service..."
    kubectl apply -f "$K8S_DIR/eureka-server-service.yaml" -n "$NAMESPACE"
    log_success "Eureka Service 创建完成"
    
    # 部署 Eureka StatefulSet（有状态应用，保证稳定的网络标识）
    log_info "创建 Eureka StatefulSet..."
    kubectl apply -f "$K8S_DIR/eureka-server-statefulset.yaml" -n "$NAMESPACE"
    log_success "Eureka StatefulSet 创建完成"
    
    # 等待 Eureka Pod 就绪
    log_info "等待 Eureka Pod 就绪..."
    kubectl rollout status statefulset/eureka-server -n "$NAMESPACE" --timeout=300s || {
        log_warn "Eureka Pod 启动超时，请检查日志"
        kubectl get pods -n "$NAMESPACE" -l app=eureka-server
        kubectl logs -n "$NAMESPACE" -l app=eureka-server --tail=50 || true
    }
    
    log_success "Eureka Server 部署完成"
    echo ""
}

# ==================== 步骤 6：部署微服务 ====================
deploy_microservices() {
    log_info "=========================================="
    log_info "步骤 6: 部署微服务"
    log_info "=========================================="
    
    # 部署 Demo Service A
    log_info "部署 Demo Service A..."
    kubectl apply -f "$K8S_DIR/demo-service-a.yaml" -n "$NAMESPACE"
    log_success "Demo Service A 部署完成"
    
    # 部署 Demo Service B
    log_info "部署 Demo Service B..."
    kubectl apply -f "$K8S_DIR/demo-service-b.yaml" -n "$NAMESPACE"
    log_success "Demo Service B 部署完成"
    
    # 等待微服务 Pod 就绪
    log_info "等待微服务 Pod 就绪..."
    kubectl wait --for=condition=ready pod -l app=demo-service-a -n "$NAMESPACE" --timeout=120s || true
    kubectl wait --for=condition=ready pod -l app=demo-service-b -n "$NAMESPACE" --timeout=120s || true
    
    log_success "微服务部署完成"
    echo ""
}

# ==================== 步骤 7：部署 Gateway ====================
deploy_gateway() {
    log_info "=========================================="
    log_info "步骤 7: 部署 API Gateway"
    log_info "=========================================="
    
    # 部署 Gateway
    log_info "部署 Gateway..."
    kubectl apply -f "$K8S_DIR/gateway.yaml" -n "$NAMESPACE"
    log_success "Gateway 部署完成"
    
    # 等待 Gateway Pod 就绪
    log_info "等待 Gateway Pod 就绪..."
    kubectl wait --for=condition=ready pod -l app=gateway -n "$NAMESPACE" --timeout=120s || {
        log_warn "Gateway Pod 启动超时，请检查日志"
        kubectl get pods -n "$NAMESPACE" -l app=gateway
        kubectl logs -n "$NAMESPACE" -l app=gateway --tail=50 || true
    }
    
    log_success "Gateway 部署完成"
    echo ""
}

# ==================== 步骤 8：验证部署 ====================
verify_deployment() {
    log_info "=========================================="
    log_info "步骤 8: 验证部署"
    log_info "=========================================="
    
    # 等待所有 Pod 就绪
    log_info "等待所有 Pod 就绪（最多 60 秒）..."
    sleep 30
    
    # 显示所有资源状态
    log_info "命名空间 '$NAMESPACE' 中的所有资源："
    kubectl get all -n "$NAMESPACE"
    echo ""
    
    # 检查 Pod 状态
    log_info "Pod 状态："
    kubectl get pods -n "$NAMESPACE"
    echo ""
    
    # 检查服务
    log_info "Service 状态："
    kubectl get svc -n "$NAMESPACE"
    echo ""
    
    # 健康检查
    log_info "执行健康检查..."
    
    # 获取 Eureka Pod 名称
    EUREKA_POD=$(kubectl get pods -n "$NAMESPACE" -l app=eureka-server -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$EUREKA_POD" ]; then
        if kubectl exec -n "$NAMESPACE" "$EUREKA_POD" -- curl -sf http://localhost:8761/actuator/health > /dev/null 2>&1; then
            log_success "✅ Eureka Server 健康检查通过"
        else
            log_warn "⚠️  Eureka Server 健康检查失败"
        fi
    fi
    
    # 获取 Gateway Pod 名称
    GATEWAY_POD=$(kubectl get pods -n "$NAMESPACE" -l app=gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$GATEWAY_POD" ]; then
        if kubectl exec -n "$NAMESPACE" "$GATEWAY_POD" -- curl -sf http://localhost:8080/actuator/health > /dev/null 2>&1; then
            log_success "✅ Gateway 健康检查通过"
        else
            log_warn "⚠️  Gateway 健康检查失败"
        fi
    fi
    
    log_success "部署验证完成"
    echo ""
}

# ==================== 步骤 9：显示访问信息 ====================
print_access_info() {
    log_info "=========================================="
    log_info "步骤 9: 显示访问信息"
    log_info "=========================================="
    
    echo ""
    echo "================================================================"
    echo "                    🎉 部署完成！"
    echo "================================================================"
    echo ""
    echo "📦 部署信息："
    echo "   部署方式: Kubernetes"
    echo "   版本: $VERSION"
    echo "   命名空间: $NAMESPACE"
    echo "   日志文件: $LOG_FILE"
    echo ""
    
    # 获取服务访问地址
    log_info "服务访问方式："
    echo ""
    
    # 检查是否有 NodePort 或 LoadBalancer
    GATEWAY_SVC=$(kubectl get svc -n "$NAMESPACE" gateway -o jsonpath='{.spec.type}' 2>/dev/null || echo "ClusterIP")
    
    if [ "$GATEWAY_SVC" = "NodePort" ]; then
        NODE_PORT=$(kubectl get svc -n "$NAMESPACE" gateway -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
        echo "🌐 Gateway 访问地址："
        echo "   http://${NODE_IP}:${NODE_PORT}"
        echo ""
    elif [ "$GATEWAY_SVC" = "LoadBalancer" ]; then
        LB_IP=$(kubectl get svc -n "$NAMESPACE" gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
        echo "🌐 Gateway 访问地址："
        echo "   http://${LB_IP}:8080"
        echo ""
    else
        echo "🌐 使用端口转发访问服务："
        echo ""
        echo "   # 终端 1 - Eureka Console"
        echo "   kubectl port-forward -n $NAMESPACE svc/eureka-server 8761:8761"
        echo ""
        echo "   # 终端 2 - Gateway"
        echo "   kubectl port-forward -n $NAMESPACE svc/gateway 8080:8080"
        echo ""
        echo "   然后访问："
        echo "   - Eureka: http://localhost:8761"
        echo "   - Gateway: http://localhost:8080"
        echo ""
    fi
    
    echo "🔑 默认凭证："
    echo "   Eureka 控制台: admin / admin123"
    echo "   Eureka 客户端: eureka-client / client123"
    echo "   Gateway Token: gateway-token"
    echo ""
    echo "📝 常用命令："
    echo "   查看所有资源: kubectl get all -n $NAMESPACE"
    echo "   查看 Pod 状态: kubectl get pods -n $NAMESPACE"
    echo "   查看日志:     kubectl logs -n $NAMESPACE -l app=gateway -f"
    echo "   进入容器:     kubectl exec -it -n $NAMESPACE <pod-name> -- sh"
    echo "   删除部署:     kubectl delete -k $K8S_DIR"
    echo ""
    echo "🧪 测试命令（端口转发后）："
    echo "   curl http://localhost:8080/api/a/hello"
    echo "   curl -H 'X-Auth-Token: gateway-token' http://localhost:8080/api/b/call-a"
    echo ""
    echo "📚 K8s 配置文件目录："
    echo "   $K8S_DIR/"
    echo ""
    echo "================================================================"
}

# ==================== 主函数 ====================
main() {
    echo ""
    echo "================================================================"
    echo "     Eureka Pro - Kubernetes 一键部署脚本"
    echo "================================================================"
    echo ""
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 询问用户确认
    log_info "即将开始部署，配置如下："
    log_info "  部署方式: Kubernetes"
    log_info "  版本: $VERSION"
    log_info "  命名空间: $NAMESPACE"
    echo ""
    read -p "确认开始部署？(y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
    
    # 执行部署步骤
    check_prerequisites
    build_and_load_images
    create_namespace
    create_config_and_secret
    deploy_eureka_server
    deploy_microservices
    deploy_gateway
    verify_deployment
    print_access_info
    
    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    log_success "部署成功！总耗时: ${DURATION} 秒"
    log_info "详细日志已保存到: $LOG_FILE"
}

# 执行主函数
main "$@"
