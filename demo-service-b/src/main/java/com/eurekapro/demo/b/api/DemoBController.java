package com.eurekapro.demo.b.api;

import com.eurekapro.common.api.ApiResponse;
import com.eurekapro.demo.b.client.DemoAClient;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class DemoBController {

  private final DemoAClient demoAClient;

  @Value("${spring.application.name}")
  private String serviceName;

  public DemoBController(DemoAClient demoAClient) {
    this.demoAClient = demoAClient;
  }

  @GetMapping("/call-a")
  public ApiResponse<Map<String, Object>> callA() {
    ApiResponse<Map<String, String>> remote = demoAClient.hello();
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("caller", serviceName);
    payload.put("remote", remote);
    return ApiResponse.ok(payload);
  }
}
