# =============================================================================
# Eureka Pro - Multi-stage Docker Build
# Usage: docker build --build-arg MODULE=gateway -t eureka-pro/gateway:1.0.0 .
# =============================================================================

# Stage 1: Build with Maven
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace

# Copy POM files first for better layer caching
COPY pom.xml .
COPY eureka-common/pom.xml eureka-common/
COPY eureka-server/pom.xml eureka-server/
COPY gateway/pom.xml gateway/
COPY demo-service-a/pom.xml demo-service-a/
COPY demo-service-b/pom.xml demo-service-b/

# Download dependencies (cached layer)
RUN mvn dependency:go-offline -B || true

# Copy source code
COPY eureka-common/src eureka-common/src
COPY eureka-server/src eureka-server/src
COPY gateway/src gateway/src
COPY demo-service-a/src demo-service-a/src
COPY demo-service-b/src demo-service-b/src

# Build the specified module
ARG MODULE=eureka-server
RUN mvn clean package -DskipTests -pl "${MODULE}" -am -q

# Stage 2: Runtime with JRE
FROM eclipse-temurin:17-jre-jammy

# Metadata labels
LABEL maintainer="eureka-pro-team"
LABEL description="Eureka Pro Microservices Platform"
LABEL version="1.0.0"

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

# Install curl for health checks
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Set working directory
WORKDIR /app

# Copy built JAR from build stage
ARG MODULE=eureka-server
COPY --from=build /workspace/${MODULE}/target/${MODULE}-1.0.0-SNAPSHOT.jar /app/app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose default port (can be overridden by SERVER_PORT env var)
EXPOSE 8080

# JVM optimizations for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+UseG1GC \
               -XX:MaxGCPauseMillis=200 \
               -XX:+HeapDumpOnOutOfMemoryError \
               -XX:HeapDumpPath=/app/logs/heapdump.hprof"

# Spring Boot defaults
ENV SPRING_PROFILES_ACTIVE=container
ENV SERVER_PORT=8080

# Use tini as init system for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Run Java application
CMD ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
