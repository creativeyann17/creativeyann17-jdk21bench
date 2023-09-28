FROM maven:3.9.4-amazoncorretto-21 as build-api
WORKDIR /tmp/api
COPY . .
RUN mvn clean install -DskipTests

FROM amazoncorretto:21-alpine as build-jre
WORKDIR /tmp/jre
COPY --from=build-api /tmp/api/target/creativeyann17-jdk21bench-0.0.1-SNAPSHOT.jar app.jar
RUN unzip app.jar -d unzip
# extract the list of modules from the app.jar
RUN $JAVA_HOME/bin/jdeps \
    --ignore-missing-deps \
    --print-module-deps \
    -q \
    --recursive \
    --multi-release 21 \
    --class-path="./unzip/BOOT-INF/lib/*" \
    --module-path="./unzip/BOOT-INF/lib/*" \
    ./app.jar > modules.info
# build the custom JRE from modules list
RUN apk add --no-cache binutils
RUN $JAVA_HOME/bin/jlink \
    --verbose \
    --add-modules $(cat modules.info) \
    --add-modules jdk.crypto.ec \
    --add-modules jdk.zipfs \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=2 \
    --output minimal

FROM alpine:latest
WORKDIR /app
ENV JAVA_HOME=/jre
ENV JAVA_OPTS="-XX:+UseG1GC -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XshowSettings:vm -XX:+PrintCommandLineFlags -XX:+TieredCompilation"
ENV PATH="$PATH:$JAVA_HOME/bin"
RUN apk update && apk add ca-certificates openssl
COPY --from=build-jre /tmp/jre/minimal $JAVA_HOME
COPY --from=build-api /tmp/api/target/creativeyann17-jdk21bench-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT java $JAVA_OPTS -jar app.jar
