package com.eurekapro.server.config;

import java.util.List;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
@EnableConfigurationProperties(EurekaSecurityProperties.class)
public class EurekaSecurityConfig {

  @Bean
  SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers(
                "/actuator/health",
                "/actuator/health/**",
                "/login",
                "/error",
                "/eureka/css/**",
                "/eureka/js/**",
                "/css/**",
                "/js/**")
            .permitAll()
            .requestMatchers("/eureka/**").hasRole("CLIENT")
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().hasAnyRole("ADMIN", "VIEWER"))
        .formLogin(form -> form
            .loginPage("/login")
            .defaultSuccessUrl("/", true)
            .permitAll())
        .logout(logout -> logout
            .logoutUrl("/logout")
            .logoutSuccessUrl("/login?logout")
            .deleteCookies("JSESSIONID")
            .permitAll())
        .httpBasic(Customizer.withDefaults())
        .csrf(csrf -> csrf.ignoringRequestMatchers("/eureka/**"));
    return http.build();
  }

  @Bean
  PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
  }

  @Bean
  UserDetailsService userDetailsService(
      EurekaSecurityProperties properties,
      PasswordEncoder passwordEncoder) {
    List<EurekaSecurityProperties.SecurityUser> users = properties.getUsers();
    if (users.isEmpty()) {
      throw new IllegalStateException("Configure at least one user under eureka-pro.security.users");
    }

    UserDetails[] userDetails = users.stream()
        .map(user -> User.builder()
            .username(user.getUsername())
            .password(passwordEncoder.encode(user.getPassword()))
            .roles(user.getRoles().toArray(String[]::new))
            .build())
        .toArray(UserDetails[]::new);
    return new InMemoryUserDetailsManager(userDetails);
  }
}
