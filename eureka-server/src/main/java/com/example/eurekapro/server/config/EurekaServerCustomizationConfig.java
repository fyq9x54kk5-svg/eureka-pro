package com.example.eurekapro.server.config;

import org.springframework.cloud.netflix.eureka.server.EurekaServerConfigBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Eureka Server 配置扩展点。
 * 可在此覆盖默认行为，例如 peer 节点、响应缓存、自我保护策略等。
 */
@Configuration
public class EurekaServerCustomizationConfig {

  @Bean
  public EurekaServerConfigBean eurekaServerConfigBean() {
    EurekaServerConfigBean config = new EurekaServerConfigBean();
    config.setEnableSelfPreservation(false);
    config.setRenewalPercentThreshold(0.49);
    return config;
  }
}
