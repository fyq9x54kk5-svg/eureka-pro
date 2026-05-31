<#import "/spring.ftl" as spring />
<!doctype html>
<html lang="zh-CN">
  <head>
    <base href="<@spring.url basePath/>">
    <meta charset="utf-8">
    <title>Eureka Pro Console</title>
    <meta name="description" content="Enhanced Eureka dashboard">
    <meta name="viewport" content="width=device-width">

    <link rel="stylesheet" href="eureka/css/wro.css">
    <link rel="stylesheet" href="eureka/css/custom-dashboard.css">

  </head>

  <body id="one">
    <script type="text/javascript">
      if ( document.documentMode ) {
         document.write('<p>You are using an <strong>outdated</strong> browser. Please upgrade your browser to improve your experience.</p>');
      }
    </script>

    <#include "header.ftlh">
    <div class="container-fluid xd-container">
      <#include "navbar.ftlh">

      <#if extendedInfo?? && extendedInfo.statusBreakdown?? && (extendedInfo.statusBreakdown?size > 0)>
        <h1 class="section-title">实例状态分布</h1>
        <table class="table table-striped table-hover detail-table">
          <thead>
            <tr><th>Status</th><th>Count</th></tr>
          </thead>
          <tbody>
            <#list extendedInfo.statusBreakdown as item>
              <tr>
                <td>${item.status!""}</td>
                <td>${item.count!0}</td>
              </tr>
            </#list>
          </tbody>
        </table>
      </#if>

      <h1 class="section-title">Instances currently registered with Eureka</h1>
      <table id='instances' class="table table-striped table-hover">
        <thead>
          <tr><th>Application</th><th>AMIs</th><th>Availability Zones</th><th>Status</th></tr>
        </thead>
        <tbody>
          <#if apps?has_content>
            <#list apps as app>
              <tr>
                <td><b>${app.name}</b></td>
                <td>
                  <#list app.amiCounts as amiCount>
                    <b>${amiCount.key}</b> (${amiCount.value})<#if amiCount_has_next>,</#if>
                  </#list>
                </td>
                <td>
                  <#list app.zoneCounts as zoneCount>
                    <b>${zoneCount.key}</b> (${zoneCount.value})<#if zoneCount_has_next>,</#if>
                  </#list>
                </td>
                <td>
                  <#list app.instanceInfos as instanceInfo>
                    <#if instanceInfo.isNotUp>
                      <font color=red size=+1><b>
                    </#if>
                    <b>${instanceInfo.status}</b> (${instanceInfo.instances?size}) -
                    <#if instanceInfo.isNotUp>
                      </b></font>
                    </#if>
                    <#list instanceInfo.instances as instance>
                      <#if instance.isHref>
                        <a href="${instance.url}" target="_blank">${instance.id}</a>
                      <#else>
                        ${instance.id}
                      </#if><#if instance_has_next>,</#if>
                    </#list>
                  </#list>
                </td>
              </tr>
            </#list>
          <#else>
            <tr><td colspan="4">No instances available</td></tr>
          </#if>

        </tbody>
      </table>

      <#if extendedInfo?? && extendedInfo.instanceDetails?? && (extendedInfo.instanceDetails?size > 0)>
        <h1 class="section-title">实例详细信息</h1>
        <table class="table table-striped table-hover detail-table">
          <thead>
            <tr>
              <th>Application</th>
              <th>Instance</th>
              <th>Network</th>
              <th>Status</th>
              <th>Lease</th>
              <th>Endpoints</th>
              <th>Metadata</th>
            </tr>
          </thead>
          <tbody>
            <#list extendedInfo.instanceDetails as detail>
              <tr>
                <td>${detail.appName!""}</td>
                <td>
                  <div>${detail.instanceId!""}</div>
                  <div>注册：${detail.registrationTimestamp!""}</div>
                  <div>更新：${detail.lastUpdated!""}</div>
                </td>
                <td>
                  <div>${detail.ip!""}:${detail.port!0}</div>
                  <div>${detail.hostName!""}</div>
                  <div>VIP: ${detail.vipAddress!""}</div>
                </td>
                <td>
                  <div>${detail.status!""}</div>
                  <div>Override: ${detail.overriddenStatus!""}</div>
                </td>
                <td>
                  <div>Renew: ${detail.leaseRenewalInterval!0}s</div>
                  <div>Duration: ${detail.leaseDuration!0}s</div>
                </td>
                <td>
                  <div><a href="${detail.homePageUrl!'#'}" target="_blank">Home</a></div>
                  <div><a href="${detail.statusPageUrl!'#'}" target="_blank">Status</a></div>
                  <div><a href="${detail.healthCheckUrl!'#'}" target="_blank">Health</a></div>
                </td>
                <td>
                  <#if detail.metadata?? && (detail.metadata?size > 0)>
                    <ul class="metadata-list">
                      <#list detail.metadata?keys as metaKey>
                        <li>${metaKey}: ${detail.metadata[metaKey]!""}</li>
                      </#list>
                    </ul>
                  <#else>
                    -
                  </#if>
                </td>
              </tr>
            </#list>
          </tbody>
        </table>
      </#if>

      <div class="row">
        <div class="col-md-6">
          <h1 class="section-title">JVM / Runtime</h1>
          <table class="table table-striped table-hover detail-table">
            <thead><tr><th>Name</th><th>Value</th></tr></thead>
            <tbody>
              <#if extendedInfo?? && extendedInfo.jvm??>
                <tr><td>Java Version</td><td>${extendedInfo.jvm.javaVersion!""}</td></tr>
                <tr><td>Java Vendor</td><td>${extendedInfo.jvm.javaVendor!""}</td></tr>
                <tr><td>JVM Name</td><td>${extendedInfo.jvm.jvmName!""}</td></tr>
                <tr><td>Heap Used / Max (MB)</td><td>${extendedInfo.jvm.heapUsedMb!0} / ${extendedInfo.jvm.heapMaxMb!0}</td></tr>
                <tr><td>Non-Heap Used (MB)</td><td>${extendedInfo.jvm.nonHeapUsedMb!0}</td></tr>
                <tr><td>Thread Count / Peak</td><td>${extendedInfo.runtime.threadCount!0} / ${extendedInfo.runtime.peakThreadCount!0}</td></tr>
              </#if>
            </tbody>
          </table>
        </div>
        <div class="col-md-6">
          <h1 class="section-title">OS / Host</h1>
          <table class="table table-striped table-hover detail-table">
            <thead><tr><th>Name</th><th>Value</th></tr></thead>
            <tbody>
              <#if extendedInfo?? && extendedInfo.os??>
                <tr><td>OS</td><td>${extendedInfo.os.name!""}</td></tr>
                <tr><td>Arch</td><td>${extendedInfo.os.arch!""}</td></tr>
                <tr><td>Version</td><td>${extendedInfo.os.version!""}</td></tr>
                <tr><td>Host</td><td>${extendedInfo.os.hostName!""}</td></tr>
                <tr><td>Host Address</td><td>${extendedInfo.os.hostAddress!""}</td></tr>
                <tr><td>Timezone</td><td>${extendedInfo.os.timezone!""}</td></tr>
              </#if>
            </tbody>
          </table>
        </div>
      </div>

      <h1 class="section-title">Eureka Server Config</h1>
      <table class="table table-striped table-hover detail-table">
        <thead><tr><th>Name</th><th>Value</th></tr></thead>
        <tbody>
          <#if extendedInfo?? && extendedInfo.serverConfig??>
            <tr><td>Self Preservation</td><td>${extendedInfo.serverConfig.enableSelfPreservation?c}</td></tr>
            <tr><td>Renewal Percent Threshold</td><td>${extendedInfo.serverConfig.renewalPercentThreshold!0}</td></tr>
            <tr><td>Eviction Interval (ms)</td><td>${extendedInfo.serverConfig.evictionIntervalMs!0}</td></tr>
            <tr><td>Response Cache Update (ms)</td><td>${extendedInfo.serverConfig.responseCacheUpdateIntervalMs!0}</td></tr>
            <tr><td>Response Cache Expiration (s)</td><td>${extendedInfo.serverConfig.responseCacheAutoExpirationInSeconds!0}</td></tr>
            <tr><td>Peer Read Timeout (ms)</td><td>${extendedInfo.serverConfig.peerNodeReadTimeoutMs!0}</td></tr>
            <tr><td>Peer Connect Timeout (ms)</td><td>${extendedInfo.serverConfig.peerNodeConnectTimeoutMs!0}</td></tr>
          </#if>
        </tbody>
      </table>

      <h1 class="section-title">General Info</h1>

      <table id='generalInfo' class="table table-striped table-hover">
        <thead>
          <tr><th>Name</th><th>Value</th></tr>
        </thead>
        <tbody>
          <#list statusInfo.generalStats?keys as stat>
            <tr>
              <td>${stat}</td><td>${statusInfo.generalStats[stat]!""}</td>
            </tr>
          </#list>
          <#list statusInfo.applicationStats?keys as stat>
            <tr>
              <td>${stat}</td><td>${statusInfo.applicationStats[stat]!""}</td>
            </tr>
          </#list>
        </tbody>
      </table>

      <h1 class="section-title">Instance Info</h1>

      <table id='instanceInfo' class="table table-striped table-hover">
        <thead>
          <tr><th>Name</th><th>Value</th></tr>
        <thead>
        <tbody>
          <#list instanceInfo?keys as key>
            <tr>
              <td>${key}</td><td>${instanceInfo[key]!""}</td>
            </tr>
          </#list>
        </tbody>
      </table>
    </div>
    <script type="text/javascript" src="eureka/js/wro.js" ></script>
  </body>
</html>
