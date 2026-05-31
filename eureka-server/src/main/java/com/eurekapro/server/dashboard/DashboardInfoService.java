package com.eurekapro.server.dashboard;

import com.netflix.appinfo.InstanceInfo;
import com.netflix.discovery.shared.Application;
import com.netflix.eureka.registry.PeerAwareInstanceRegistry;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.RuntimeMXBean;
import java.lang.management.ThreadMXBean;
import java.net.InetAddress;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.netflix.eureka.server.EurekaServerConfigBean;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

@Service
public class DashboardInfoService {

  private static final DateTimeFormatter TIME_FORMAT =
      DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").withZone(ZoneId.systemDefault());

  private final RegistrySupport registrySupport;
  private final Environment environment;
  private final EurekaServerConfigBean serverConfig;

  @Value("${spring.application.name:eureka-server}")
  private String applicationName;

  @Value("${server.port:8761}")
  private int serverPort;

  @Value("${eureka.instance.hostname:localhost}")
  private String hostname;

  public DashboardInfoService(
      RegistrySupport registrySupport,
      Environment environment,
      EurekaServerConfigBean serverConfig) {
    this.registrySupport = registrySupport;
    this.environment = environment;
    this.serverConfig = serverConfig;
  }

  public Map<String, Object> buildExtendedInfo() {
    Map<String, Object> info = new LinkedHashMap<>();
    info.put("overview", buildOverview());
    info.put("jvm", buildJvmInfo());
    info.put("os", buildOsInfo());
    info.put("runtime", buildRuntimeInfo());
    info.put("serverConfig", buildServerConfig());
    info.put("statusBreakdown", buildStatusBreakdown());
    info.put("instanceDetails", buildInstanceDetails());
    return info;
  }

  private Map<String, Object> buildOverview() {
    PeerAwareInstanceRegistry registry = registrySupport.registry();
    Map<String, Object> overview = new LinkedHashMap<>();
    if (registry == null) {
      overview.put("ready", false);
      return overview;
    }

    int totalInstances = 0;
    int upInstances = 0;
    int downInstances = 0;
    int startingInstances = 0;
    int unknownInstances = 0;

    for (Application application : registry.getApplications().getRegisteredApplications()) {
      for (InstanceInfo instance : application.getInstances()) {
        totalInstances++;
        switch (instance.getStatus()) {
          case UP -> upInstances++;
          case DOWN -> downInstances++;
          case STARTING -> startingInstances++;
          default -> unknownInstances++;
        }
      }
    }

    overview.put("ready", true);
    overview.put("registeredAppCount", registry.getApplications().getRegisteredApplications().size());
    overview.put("totalInstanceCount", totalInstances);
    overview.put("upInstanceCount", upInstances);
    overview.put("downInstanceCount", downInstances);
    overview.put("startingInstanceCount", startingInstances);
    overview.put("unknownInstanceCount", unknownInstances);
    overview.put("selfPreservationMode", registry.isSelfPreservationModeEnabled());
    overview.put("belowRenewThreshold", registry.isBelowRenewThresold() == 1);
    overview.put("renewsLastMin", registry.getNumOfRenewsInLastMin());
    overview.put("renewThreshold", registry.getNumOfRenewsPerMinThreshold());
    return overview;
  }

  private Map<String, Object> buildJvmInfo() {
    MemoryMXBean memory = ManagementFactory.getMemoryMXBean();
    Runtime runtime = Runtime.getRuntime();

    Map<String, Object> jvm = new LinkedHashMap<>();
    jvm.put("javaVersion", System.getProperty("java.version"));
    jvm.put("javaVendor", System.getProperty("java.vendor"));
    jvm.put("jvmName", System.getProperty("java.vm.name"));
    jvm.put("processors", Runtime.getRuntime().availableProcessors());
    jvm.put("heapUsedMb", toMb(memory.getHeapMemoryUsage().getUsed()));
    jvm.put("heapMaxMb", toMb(memory.getHeapMemoryUsage().getMax()));
    jvm.put("nonHeapUsedMb", toMb(memory.getNonHeapMemoryUsage().getUsed()));
    jvm.put("totalMemoryMb", toMb(runtime.totalMemory()));
    jvm.put("freeMemoryMb", toMb(runtime.freeMemory()));
    return jvm;
  }

  private Map<String, Object> buildOsInfo() {
    Map<String, Object> os = new LinkedHashMap<>();
    os.put("name", System.getProperty("os.name"));
    os.put("arch", System.getProperty("os.arch"));
    os.put("version", System.getProperty("os.version"));
    os.put("user", System.getProperty("user.name"));
    os.put("timezone", ZoneId.systemDefault().toString());
    try {
      os.put("hostAddress", InetAddress.getLocalHost().getHostAddress());
      os.put("hostName", InetAddress.getLocalHost().getHostName());
    } catch (Exception ex) {
      os.put("hostAddress", hostname);
      os.put("hostName", hostname);
    }
    return os;
  }

  private Map<String, Object> buildRuntimeInfo() {
    RuntimeMXBean runtime = ManagementFactory.getRuntimeMXBean();
    ThreadMXBean threads = ManagementFactory.getThreadMXBean();
    Instant startTime = Instant.ofEpochMilli(runtime.getStartTime());

    Map<String, Object> runtimeInfo = new LinkedHashMap<>();
    runtimeInfo.put("applicationName", applicationName);
    runtimeInfo.put("serverPort", serverPort);
    runtimeInfo.put("activeProfiles", String.join(",", environment.getActiveProfiles()));
    runtimeInfo.put("defaultProfiles", String.join(",", environment.getDefaultProfiles()));
    runtimeInfo.put("pid", runtime.getPid());
    runtimeInfo.put("startTime", TIME_FORMAT.format(startTime));
    runtimeInfo.put("uptime", formatDuration(Duration.ofMillis(runtime.getUptime())));
    runtimeInfo.put("threadCount", threads.getThreadCount());
    runtimeInfo.put("peakThreadCount", threads.getPeakThreadCount());
    runtimeInfo.put("daemonThreadCount", threads.getDaemonThreadCount());
    return runtimeInfo;
  }

  private Map<String, Object> buildServerConfig() {
    Map<String, Object> config = new LinkedHashMap<>();
    config.put("enableSelfPreservation", serverConfig.isEnableSelfPreservation());
    config.put("renewalPercentThreshold", serverConfig.getRenewalPercentThreshold());
    config.put("evictionIntervalMs", serverConfig.getEvictionIntervalTimerInMs());
    config.put("responseCacheUpdateIntervalMs", serverConfig.getResponseCacheUpdateIntervalMs());
    config.put("responseCacheAutoExpirationInSeconds", serverConfig.getResponseCacheAutoExpirationInSeconds());
    config.put("peerNodeReadTimeoutMs", serverConfig.getPeerNodeReadTimeoutMs());
    config.put("peerNodeConnectTimeoutMs", serverConfig.getPeerNodeConnectTimeoutMs());
    return config;
  }

  private List<Map<String, Object>> buildStatusBreakdown() {
    EnumMap<InstanceInfo.InstanceStatus, Integer> counts =
        new EnumMap<>(InstanceInfo.InstanceStatus.class);
    for (InstanceInfo.InstanceStatus status : InstanceInfo.InstanceStatus.values()) {
      counts.put(status, 0);
    }

    PeerAwareInstanceRegistry registry = registrySupport.registry();
    if (registry != null) {
      for (Application application : registry.getApplications().getRegisteredApplications()) {
        for (InstanceInfo instance : application.getInstances()) {
          counts.computeIfPresent(instance.getStatus(), (status, count) -> count + 1);
        }
      }
    }

    List<Map<String, Object>> rows = new ArrayList<>();
    counts.forEach((status, count) -> {
      if (count > 0) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("status", status.name());
        row.put("count", count);
        rows.add(row);
      }
    });
    return rows;
  }

  private List<Map<String, Object>> buildInstanceDetails() {
    List<Map<String, Object>> details = new ArrayList<>();
    PeerAwareInstanceRegistry registry = registrySupport.registry();
    if (registry == null) {
      return details;
    }

    for (Application application : registry.getApplications().getRegisteredApplications()) {
      for (InstanceInfo instance : application.getInstances()) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("appName", application.getName());
        row.put("instanceId", instance.getInstanceId());
        row.put("hostName", instance.getHostName());
        row.put("ip", instance.getIPAddr());
        row.put("port", instance.getPort());
        row.put("status", instance.getStatus().name());
        row.put("overriddenStatus", instance.getOverriddenStatus().name());
        row.put("vipAddress", instance.getVIPAddress());
        row.put("secureVipAddress", instance.getSecureVipAddress());
        row.put("homePageUrl", instance.getHomePageUrl());
        row.put("statusPageUrl", instance.getStatusPageUrl());
        row.put("healthCheckUrl", instance.getHealthCheckUrl());
        row.put("secureHealthCheckUrl", instance.getSecureHealthCheckUrl());
        row.put("countryId", instance.getCountryId());
        row.put("lastUpdated", TIME_FORMAT.format(Instant.ofEpochMilli(instance.getLastUpdatedTimestamp())));
        row.put("registrationTimestamp",
            TIME_FORMAT.format(Instant.ofEpochMilli(instance.getLeaseInfo().getRegistrationTimestamp())));
        row.put("leaseRenewalInterval", instance.getLeaseInfo().getRenewalIntervalInSecs());
        row.put("leaseDuration", instance.getLeaseInfo().getDurationInSecs());
        row.put("metadata", instance.getMetadata());
        details.add(row);
      }
    }
    return details;
  }

  private long toMb(long bytes) {
    return bytes <= 0 ? 0 : bytes / (1024 * 1024);
  }

  private String formatDuration(Duration duration) {
    long hours = duration.toHours();
    long minutes = duration.toMinutesPart();
    long seconds = duration.toSecondsPart();
    return String.format("%dh %dm %ds", hours, minutes, seconds);
  }
}
