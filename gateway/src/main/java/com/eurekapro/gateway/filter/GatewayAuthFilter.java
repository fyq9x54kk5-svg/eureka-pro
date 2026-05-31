package com.eurekapro.gateway.filter;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class GatewayAuthFilter implements GlobalFilter, Ordered {

  private static final String HEADER_TOKEN = "X-Auth-Token";

  @Value("${eureka-pro.gateway.auth.enabled:true}")
  private boolean enabled;

  @Value("${eureka-pro.gateway.auth.token:gateway-token}")
  private String token;

  @Override
  public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
    if (!enabled) {
      return chain.filter(exchange);
    }

    String path = exchange.getRequest().getURI().getPath();
    if (!path.startsWith("/api/b/")) {
      return chain.filter(exchange);
    }

    String given = exchange.getRequest().getHeaders().getFirst(HEADER_TOKEN);
    if (given == null || !given.equals(token)) {
      exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
      return exchange.getResponse().setComplete();
    }
    return chain.filter(exchange);
  }

  @Override
  public int getOrder() {
    return -50;
  }
}
