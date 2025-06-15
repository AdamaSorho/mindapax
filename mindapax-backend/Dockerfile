# Stage 1: Build the Spring Boot application
FROM maven:3.8-openjdk-17 AS build

# Set the working directory
WORKDIR /usr/src/app

# Copy the Maven wrapper files and pom.xml to leverage Docker cache
COPY .mvn/ .mvn
COPY mvnw mvnw.cmd ./
COPY pom.xml .

# Download dependencies
# Using ./mvnw instead of mvn to ensure consistent builds
RUN ./mvnw dependency:go-offline

# Copy the rest of the application source code
COPY src ./src

# Package the application, skipping tests
# This will also compile the code and produce the JAR file
RUN ./mvnw package -DskipTests

# Stage 2: Set up the runtime environment (using the same image for simplicity)
# For a smaller image, a JRE-specific image could be used here (e.g., openjdk:17-jre-slim)
# and the JAR copied from the 'build' stage.

# Expose the port the Spring Boot application runs on (default is 8080)
EXPOSE 8080

# Define the command to run the application
# Note: The exact JAR file name might need adjustment based on your pom.xml (artifactId and version)
# Assuming the JAR is in the 'target' directory and follows a typical Spring Boot naming convention.
ENTRYPOINT ["java", "-jar", "target/mindapax-backend-0.0.1-SNAPSHOT.jar"]
