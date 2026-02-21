
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app
# Copy files and build 
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN groupadd -g 1003 appgroup && \
    useradd -u 1003 -g appgroup -ms /bin/bash appuser
COPY --from=builder /app/target/*.jar app.jar
RUN chown -R appuser:appgroup app.jar
USER 1003
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
