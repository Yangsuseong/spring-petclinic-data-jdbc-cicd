FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY ./spring-petclinic-data-jdbc ./
COPY ./config/application.properties /app/src/main/resources/application.properties
RUN ["./gradlew","build","-x","processTestAot"]
CMD java -jar build/libs/*.jar
