package com.example.eurekapro.demo.a;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@EnableDiscoveryClient
@SpringBootApplication
public class DemoServiceAApplication {

  public static void main(String[] args) {
    SpringApplication.run(DemoServiceAApplication.class, args);
  }
}
