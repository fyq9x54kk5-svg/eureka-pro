package com.eurekapro.server.dashboard;

import com.netflix.eureka.EurekaServerContext;
import com.netflix.eureka.EurekaServerContextHolder;
import com.netflix.eureka.registry.PeerAwareInstanceRegistry;
import org.springframework.stereotype.Component;

@Component
public class RegistrySupport {

  public PeerAwareInstanceRegistry registry() {
    EurekaServerContext context = EurekaServerContextHolder.getInstance().getServerContext();
    return context == null ? null : context.getRegistry();
  }
}
