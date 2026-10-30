# --- Stage 1: Build the application ---
FROM maven:3.9.6-eclipse-temurin-21-jammy AS builder
WORKDIR /app

# Copy the pom.xml and dependency wrapper configuration to cache layers
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

# Download dependencies (this layer remains cached if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -B

# Copy the source code and build the package
COPY src ./src
RUN ./mvnw clean package -DskipTests

# --- Stage 2: Lean, secure runtime ---
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN apt-get update && apt-get install -y wget

# Create a non-root system user and group for security
RUN groupadd -r devops && useradd -r -g devops devops

# Copy the built jar from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Adjust ownership to the non-root user
RUN chown -R devops:devops /app
USER devops

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
