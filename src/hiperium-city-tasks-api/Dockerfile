#####################################################################################
########################## Stage 1: Docker Builder Image ############################
#####################################################################################
FROM quay.io/quarkus/ubi-quarkus-native-image:22.1.0-java11-arm64 AS builder
COPY --chown=quarkus:quarkus mvnw       /code/mvnw
COPY --chown=quarkus:quarkus .mvn       /code/.mvn
COPY --chown=quarkus:quarkus pom.xml    /code/
ARG quarkus_profile=dev

USER quarkus
RUN echo "Building Tasks Service with profile: $quarkus_profile"
WORKDIR /code

RUN ./mvnw -B org.apache.maven.plugins:maven-dependency-plugin:3.1.2:go-offline
COPY src /code/src
RUN ./mvnw package -Pnative -Dmaven.test.skip=true -Dquarkus.profile=$quarkus_profile

#####################################################################################
######################## Stage 2: Docker Application Image ##########################
#####################################################################################
FROM quay.io/quarkus/quarkus-micro-image:2.0-arm64
WORKDIR /work/
COPY --from=builder /code/target/*-runner /work/application

RUN chmod 775 /work
EXPOSE 8080
CMD ["./application", "-Dquarkus.http.host=0.0.0.0"]
