FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app
RUN useradd -ms /bin/bash appuser
USER appuser
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:17-jre
COPY --from=builder /app/target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
