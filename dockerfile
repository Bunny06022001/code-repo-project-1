
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app
# Copy files and build 
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN useradd -ms /bin/bash appuser
COPY --from=builder /app/target/*.jar app.jar
RUN chown appuser:appuser app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
