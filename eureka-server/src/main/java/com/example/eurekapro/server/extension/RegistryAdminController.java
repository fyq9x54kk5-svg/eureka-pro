package com.example.eurekapro.server.extension;

import com.example.eurekapro.common.api.ApiResponse;
import com.netflix.appinfo.InstanceInfo;
import com.netflix.discovery.shared.Application;
import com.netflix.eureka.EurekaServerContext;
import com.netflix.eureka.EurekaServerContextHolder;
import com.netflix.eureka.registry.PeerAwareInstanceRegistry;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 自定义管理接口，便于观察注册表状态。
 * 后续改造时可在此增加：手动下线、权重调整、灰度标记等能力。
 */
@RestController
@RequestMapping("/admin/registry")
public class RegistryAdminController {

  private final EurekaRegistryEventListener eventListener;

  public RegistryAdminController(EurekaRegistryEventListener eventListener) {
    this.eventListener = eventListener;
  }

  @GetMapping("/summary")
  public ApiResponse<Map<String, Object>> summary() {
    PeerAwareInstanceRegistry registry = currentRegistry();
    if (registry == null) {
      return ApiResponse.fail("REGISTRY_NOT_READY", "Eureka registry is not initialized");
    }

    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("registeredAppCount", eventListener.countRegisteredApps());
    payload.put("applications", registry.getApplications().getRegisteredApplications().stream()
        .map(this::toAppView)
        .toList());
    return ApiResponse.ok(payload);
  }

  private Map<String, Object> toAppView(Application application) {
    List<Map<String, Object>> instances = application.getInstances().stream()
        .map(this::toInstanceView)
        .toList();

    Map<String, Object> view = new LinkedHashMap<>();
    view.put("name", application.getName());
    view.put("instanceCount", instances.size());
    view.put("instances", instances);
    return view;
  }

  private Map<String, Object> toInstanceView(InstanceInfo instance) {
    Map<String, Object> view = new LinkedHashMap<>();
    view.put("instanceId", instance.getInstanceId());
    view.put("host", instance.getHostName());
    view.put("ip", instance.getIPAddr());
    view.put("port", instance.getPort());
    view.put("status", instance.getStatus().name());
    view.put("homePageUrl", instance.getHomePageUrl());
    return view;
  }

  private PeerAwareInstanceRegistry currentRegistry() {
    EurekaServerContext context = EurekaServerContextHolder.getInstance().getServerContext();
    return context == null ? null : context.getRegistry();
  }
}
