FROM eclipse-temurin:17-jre

WORKDIR /app

COPY target/vegan-mundi-order-service-1.0.0-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
