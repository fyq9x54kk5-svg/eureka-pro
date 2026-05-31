<#if currentUser??>
<div class="page-toolbar">
  <div class="title-block">
    <h2>Eureka Pro 控制台</h2>
    <p>已登录：${currentUser} | 角色：${currentRoles!""} | 当前时间：${currentTime!""}</p>
  </div>
  <div class="user-block">
    <div>服务端口：${extendedInfo.runtime.serverPort!8761}</div>
    <div>运行时长：${extendedInfo.runtime.uptime!""}</div>
  </div>
</div>
</#if>

<#if extendedInfo?? && extendedInfo.overview?? && extendedInfo.overview.ready>
<div class="metric-grid">
  <div class="metric-card">
    <div class="label">注册应用数</div>
    <div class="value">${extendedInfo.overview.registeredAppCount!0}</div>
  </div>
  <div class="metric-card">
    <div class="label">实例总数</div>
    <div class="value">${extendedInfo.overview.totalInstanceCount!0}</div>
  </div>
  <div class="metric-card">
    <div class="label">UP 实例</div>
    <div class="value ok">${extendedInfo.overview.upInstanceCount!0}</div>
  </div>
  <div class="metric-card">
    <div class="label">DOWN / STARTING</div>
    <div class="value <#if (extendedInfo.overview.downInstanceCount!0) gt 0 || (extendedInfo.overview.startingInstanceCount!0) gt 0>bad<#else>ok</#if>">
      ${extendedInfo.overview.downInstanceCount!0} / ${extendedInfo.overview.startingInstanceCount!0}
    </div>
  </div>
  <div class="metric-card">
    <div class="label">最近 1 分钟续约</div>
    <div class="value <#if extendedInfo.overview.belowRenewThreshold!false>warn<#else>ok</#if>">
      ${extendedInfo.overview.renewsLastMin!0} / ${extendedInfo.overview.renewThreshold!0}
    </div>
  </div>
  <div class="metric-card">
    <div class="label">自我保护</div>
    <div class="value <#if extendedInfo.overview.selfPreservationMode!false>ok<#else>warn</#if>">
      <#if extendedInfo.overview.selfPreservationMode!false>开启<#else>关闭</#if>
    </div>
  </div>
</div>
</#if>

<h1>System Status</h1>
<div class="row">
  <div class="col-md-6">
    <table id='instances' class="table table-condensed table-striped table-hover">
      <#if amazonInfo??>
        <tr>
          <td>EUREKA SERVER</td>
          <td>AMI: ${amiId!}</td>
        </tr>
        <tr>
          <td>Zone</td>
          <td>${availabilityZone!}</td>
        </tr>
        <tr>
          <td>instance-id</td>
          <td>${instanceId!}</td>
        </tr>
      </#if>
      <tr>
        <td>Environment</td>
        <td>${environment!}</td>
      </tr>
      <tr>
        <td>Data center</td>
        <td>${datacenter!}</td>
      </tr>
      <#if extendedInfo?? && extendedInfo.runtime??>
        <tr>
          <td>Application</td>
          <td>${extendedInfo.runtime.applicationName!""}</td>
        </tr>
        <tr>
          <td>Active profiles</td>
          <td>${extendedInfo.runtime.activeProfiles!""}</td>
        </tr>
        <tr>
          <td>PID</td>
          <td>${extendedInfo.runtime.pid!""}</td>
        </tr>
        <tr>
          <td>Start time</td>
          <td>${extendedInfo.runtime.startTime!""}</td>
        </tr>
      </#if>
    </table>
  </div>
  <div class="col-md-6">
    <table id='instances' class="table table-condensed table-striped table-hover">
      <tr>
        <td>Current time</td>
        <td>${currentTime}</td>
      </tr>
      <tr>
        <td>Uptime</td>
        <td>${upTime}</td>
      </tr>
      <tr>
        <td>Lease expiration enabled</td>
        <td>${registry.leaseExpirationEnabled?c}</td>
      </tr>
      <tr>
        <td>Renews threshold</td>
        <td>${registry.numOfRenewsPerMinThreshold}</td>
      </tr>
      <tr>
        <td>Renews (last min)</td>
        <td>${registry.numOfRenewsInLastMin}</td>
      </tr>
      <#if extendedInfo?? && extendedInfo.jvm??>
        <tr>
          <td>JVM heap used / max (MB)</td>
          <td>${extendedInfo.jvm.heapUsedMb!0} / ${extendedInfo.jvm.heapMaxMb!0}</td>
        </tr>
        <tr>
          <td>Java version</td>
          <td>${extendedInfo.jvm.javaVersion!""}</td>
        </tr>
        <tr>
          <td>CPU cores</td>
          <td>${extendedInfo.jvm.processors!0}</td>
        </tr>
      </#if>
    </table>
  </div>
</div>

<#if isBelowRenewThreshold>
    <#if !registry.selfPreservationModeEnabled>
        <h4 id="uptime"><font size="+1" color="red"><b>RENEWALS ARE LESSER THAN THE THRESHOLD. THE SELF PRESERVATION MODE IS TURNED OFF. THIS MAY NOT PROTECT INSTANCE EXPIRY IN CASE OF NETWORK/OTHER PROBLEMS.</b></font></h4>
    <#else>
        <h4 id="uptime"><font size="+1" color="red"><b>EMERGENCY! EUREKA MAY BE INCORRECTLY CLAIMING INSTANCES ARE UP WHEN THEY'RE NOT. RENEWALS ARE LESSER THAN THRESHOLD AND HENCE THE INSTANCES ARE NOT BEING EXPIRED JUST TO BE SAFE.</b></font></h4>
    </#if>
<#elseif !registry.selfPreservationModeEnabled>
    <h4 id="uptime"><font size="+1" color="red"><b>THE SELF PRESERVATION MODE IS TURNED OFF. THIS MAY NOT PROTECT INSTANCE EXPIRY IN CASE OF NETWORK/OTHER PROBLEMS.</b></font></h4>
</#if>

<h1>DS Replicas</h1>
<ul class="list-group mb-3">
  <#list replicas as replica>
    <li class="list-group-item"><a href="${replica.value}">${replica.key}</a></li>
  </#list>
</ul>
