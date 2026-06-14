FROM eclipse-temurin:17-jdk-alpine

LABEL maintainer="vegan-mundi-dev@example.com"

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    dumb-init

# Create app directory
WORKDIR /app

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Copy and run JAR
# This will be overridden by specific service Dockerfile
COPY target/*.jar app.jar

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["java", "-XX:+UseG1GC", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]

EXPOSE 8080
