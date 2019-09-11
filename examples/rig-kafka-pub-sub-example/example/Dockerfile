FROM maven:3.6.0-jdk-8-alpine as compiler
COPY . .

RUN ["mvn", "package"]

FROM java:8-alpine

EXPOSE 8080

COPY --from=compiler /target/example-0.0.1-SNAPSHOT.jar ./app.jar

ENTRYPOINT ["java", "-jar",  "app.jar"]