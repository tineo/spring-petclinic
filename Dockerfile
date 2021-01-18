FROM openjdk:8-jre-alpine
COPY target/spring-petclinic*.jar /app/spring-petclinic.jar
WORKDIR /app
ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar spring-petclinic.jar
