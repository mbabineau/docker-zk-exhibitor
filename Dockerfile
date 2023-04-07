FROM debian:9.13
MAINTAINER Mike Babineau michael.babineau@gmail.com

ENV \
    ZK_RELEASE="https://dlcdn.apache.org/zookeeper/zookeeper-3.6.4/apache-zookeeper-3.6.4-bin.tar.gz" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/soabase/exhibitor/v1.5.6/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    # Append "+" to ensure the package doesn't get purged
    BUILD_DEPS="curl maven openjdk-8-jdk+" \
    DEBIAN_FRONTEND="noninteractive"

# Use one step so we can remove intermediate dependencies and minimize size

RUN    # Install dependencies
RUN    apt-get update
RUN    apt-get install -y --allow-unauthenticated --no-install-recommends procps
RUN    apt-get install -y --allow-unauthenticated --no-install-recommends $BUILD_DEPS

RUN    # Default DNS cache TTL is -1. DNS records, like, change, man.
RUN    grep '^networkaddress.cache.ttl=' /etc/java-8-openjdk/security/java.security || echo 'networkaddress.cache.ttl=60' >> /etc/java-8-openjdk/security/java.security

#RUN    # Install ZK
#RUN    curl -Lo /tmp/zookeeper.tar.gz $ZK_RELEASE
#RUN    mkdir /tmp/zookeeper
#RUN    mkdir -p /opt/zookeeper/transactions /opt/zookeeper/snapshots
#RUN    curl -Lo /opt/zookeeper/zookeeper-3.4.6.jar https://repo1.maven.org/maven2/org/apache/zookeeper/zookeeper/3.6.4/zookeeper-3.6.4.jar
#RUN    tar -xzf /tmp/zookeeper.tar.gz -C /opt/zookeeper --strip=1
#RUN    cp -rv /opt/zookeeper/lib/zookeeper* /opt/zookeeper
#RUN    rm /tmp/zookeeper.tgz
ADD zk-dist/zookeeper-3.4.6.tar.gz /opt/

RUN    # Install Exhibitor
RUN    mkdir -p /opt/exhibitor
RUN    curl -Lo /opt/exhibitor/pom.xml $EXHIBITOR_POM
RUN    mvn -f /opt/exhibitor/pom.xml package
RUN    ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar

RUN    # Remove build-time dependencies
RUN    apt-get purge -y --auto-remove $BUILD_DEPS
RUN    rm -rf /var/lib/apt/lists/*

# Add the wrapper script that sets up configs without using AWS
ADD include/vimond-wrapper.sh /opt/exhibitor/wrapper.sh

# Add the original wrapper script to setup configs and exec exhibitor using AWS
ADD include/wrapper.sh /opt/exhibitor/original-wrapper.sh

# Add the optional web.xml for authentication
ADD include/web.xml /opt/exhibitor/web.xml

USER root
WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENV SERVICE_8181_CHECK_HTTP=/exhibitor/v1/ui/index.html \
    SERVICE_2181_CHECK_TCP=true

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/wrapper.sh"]
