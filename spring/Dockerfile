FROM maven:3.5.2-jdk-8-alpine AS BUILDER
WORKDIR /notejam/
COPY pom.xml /notejam
COPY src /notejam/src
RUN mvn clean package -DskipTests=true

FROM openjdk:8-jre-alpine
COPY --from=BUILDER /notejam/target/*.jar notejam.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "notejam.jar"]