package com.example.eurekapro.demo.a.api;

import com.example.eurekapro.common.api.ApiResponse;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class DemoAController {

  @Value("${spring.application.name}")
  private String serviceName;

  @GetMapping("/hello")
  public ApiResponse<Map<String, String>> hello() {
    return ApiResponse.ok(Map.of(
        "service", serviceName,
        "message", "hello from demo-service-a"
    ));
  }
}
