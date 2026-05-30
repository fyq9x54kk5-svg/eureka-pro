package com.example.eurekapro.demo.b.client;

import com.example.eurekapro.common.api.ApiResponse;
import java.util.Map;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

@FeignClient(name = "demo-service-a")
public interface DemoAClient {

  @GetMapping("/api/hello")
  ApiResponse<Map<String, String>> hello();
}
