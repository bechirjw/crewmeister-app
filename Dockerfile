
# syntax=docker/dockerfile:1

# ============================
# Stage 1: Build
# ============================
FROM eclipse-temurin:17-jdk-noble AS build

WORKDIR /app

# Copy Maven Wrapper and configuration
COPY --chmod=0755 mvnw ./mvnw
COPY .mvn/ .mvn/
COPY pom.xml ./

# Cache Maven dependencies
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -B -ntp dependency:go-offline

# Build the application
COPY src/ ./src/
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw -B -ntp -DskipTests package


# ============================
# Stage 2: Runtime
# ============================
FROM eclipse-temurin:17-jre-alpine-3.24

WORKDIR /app

# Create non-root user
RUN addgroup -S -g 10001 crewmeister && \
    adduser -S -D -H -u 10001 \
    -G crewmeister crewmeister

# Copy application JAR
COPY --from=build --chmod=0444 \
    /app/target/crewmeisterchallenge-0.0.1-SNAPSHOT.jar \
    /app/app.jar

USER 10001:10001

EXPOSE 8080

# JVM memory management
ENV JAVA_TOOL_OPTIONS="\
-XX:MaxRAMPercentage=70.0 \
-XX:+ExitOnOutOfMemoryError"

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
