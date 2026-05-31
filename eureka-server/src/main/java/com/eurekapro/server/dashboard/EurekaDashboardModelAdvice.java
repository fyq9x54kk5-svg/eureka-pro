package com.eurekapro.server.dashboard;

import java.util.stream.Collectors;
import org.springframework.cloud.netflix.eureka.server.EurekaController;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice(assignableTypes = EurekaController.class)
public class EurekaDashboardModelAdvice {

  private final DashboardInfoService dashboardInfoService;

  public EurekaDashboardModelAdvice(DashboardInfoService dashboardInfoService) {
    this.dashboardInfoService = dashboardInfoService;
  }

  @ModelAttribute
  public void enrichDashboard(Model model, Authentication authentication) {
    model.addAttribute("extendedInfo", dashboardInfoService.buildExtendedInfo());
    if (authentication != null && authentication.isAuthenticated()) {
      model.addAttribute("currentUser", authentication.getName());
      model.addAttribute("currentRoles", authentication.getAuthorities().stream()
          .map(GrantedAuthority::getAuthority)
          .collect(Collectors.joining(", ")));
    }
  }
}
