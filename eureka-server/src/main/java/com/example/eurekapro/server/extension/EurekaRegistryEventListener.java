package com.example.eurekapro.server.extension;

import com.netflix.appinfo.InstanceInfo;
import com.netflix.eureka.EurekaServerContext;
import com.netflix.eureka.EurekaServerContextHolder;
import com.netflix.eureka.registry.PeerAwareInstanceRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.netflix.eureka.server.event.EurekaInstanceCanceledEvent;
import org.springframework.cloud.netflix.eureka.server.event.EurekaInstanceRegisteredEvent;
import org.springframework.cloud.netflix.eureka.server.event.EurekaInstanceRenewedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/**
 * Eureka 服务端事件监听入口。
 * 改造注册中心时，可在此扩展：审计日志、告警、自定义路由权重、黑名单等。
 */
@Component
public class EurekaRegistryEventListener {

  private static final Logger log = LoggerFactory.getLogger(EurekaRegistryEventListener.class);

  @EventListener
  public void onRegistered(EurekaInstanceRegisteredEvent event) {
    InstanceInfo instance = event.getInstanceInfo();
    log.info("[eureka] registered app={} instanceId={} ip={}:{}",
        instance.getAppName(),
        instance.getInstanceId(),
        instance.getIPAddr(),
        instance.getPort());
  }

  @EventListener
  public void onRenewed(EurekaInstanceRenewedEvent event) {
    log.debug("[eureka] renewed app={} instanceId={}", event.getAppName(), event.getServerId());
  }

  @EventListener
  public void onCanceled(EurekaInstanceCanceledEvent event) {
    log.info("[eureka] canceled app={} instanceId={}", event.getAppName(), event.getServerId());
  }

  public int countRegisteredApps() {
    PeerAwareInstanceRegistry registry = currentRegistry();
    return registry == null ? 0 : registry.getApplications().getRegisteredApplications().size();
  }

  private PeerAwareInstanceRegistry currentRegistry() {
    EurekaServerContext context = EurekaServerContextHolder.getInstance().getServerContext();
    return context == null ? null : context.getRegistry();
  }
}
