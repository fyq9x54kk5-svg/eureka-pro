package com.eurekapro.server.config;

import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "eureka-pro.security")
public class EurekaSecurityProperties {

  private List<SecurityUser> users = new ArrayList<>();

  public List<SecurityUser> getUsers() {
    return users;
  }

  public void setUsers(List<SecurityUser> users) {
    this.users = users;
  }

  public static class SecurityUser {

    private String username;
    private String password;
    private List<String> roles = List.of("VIEWER");

    public String getUsername() {
      return username;
    }

    public void setUsername(String username) {
      this.username = username;
    }

    public String getPassword() {
      return password;
    }

    public void setPassword(String password) {
      this.password = password;
    }

    public List<String> getRoles() {
      return roles;
    }

    public void setRoles(List<String> roles) {
      this.roles = roles;
    }
  }
}
