FROM jeanblanchard/busybox-java:8
MAINTAINER Mike Babineau michael.babineau@gmail.com

ENV \
    ZK_RELEASE="http://www.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz" \
    EXHIBITOR_POM="https://raw.githubusercontent.com/Netflix/exhibitor/d911a16d704bbe790d84bbacc655ef050c1f5806/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    MVN_RELEASE="http://www.apache.org/dist/maven/maven-3/3.3.1/binaries/apache-maven-3.3.1-bin.tar.gz"

# Use one step so we can remove intermediate dependencies and minimize size
RUN \
    # Install dependencies
    opkg-install bash tar \

    # Default DNS cache TTL is -1. DNS records, like, change, man.
    && grep -q '^networkaddress.cache.ttl=' /opt/jdk/jre/lib/security/java.security || echo 'networkaddress.cache.ttl=60' >> /opt/jdk/jre/lib/security/java.security \

    # Install ZK
    && curl -Lo /tmp/zookeeper.tgz $ZK_RELEASE \
    && mkdir -p /opt/zookeeper/transactions /opt/zookeeper/snapshots \
    && tar -xzf /tmp/zookeeper.tgz -C /opt/zookeeper --strip=1 \
    && rm /tmp/zookeeper.tgz \

    # Install Maven (just for building)
    && mkdir -p /opt/maven \
    && curl -Lo /tmp/maven.tgz $MVN_RELEASE \
    && tar -xzf /tmp/maven.tgz -C /opt/maven --strip=1 \
    && rm /tmp/maven.tgz \

    # Install Exhibitor
    && mkdir -p /opt/exhibitor \
    && curl -kLo /opt/exhibitor/pom.xml $EXHIBITOR_POM \
    && /opt/maven/bin/mvn -f /opt/exhibitor/pom.xml package \
    && ln -s /opt/exhibitor/target/exhibitor*jar /opt/exhibitor/exhibitor.jar \

    # Remove build-time dependencies
    && rm -rf ~/.m2 \
    && rm -rf ~/opt/maven \
    && opkg-cl remove tar bzip2 libbz2 libacl libattr\
    && rm -rf /tmp/*

# Add the wrapper script to setup configs and exec exhibitor
ADD include/wrapper.sh /opt/exhibitor/wrapper.sh

# Add the optional web.xml for authentication
ADD include/web.xml /opt/exhibitor/web.xml

USER root
WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

VOLUME /opt/zookeeper/transactions
VOLUME /opt/zookeeper/snapshots

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/wrapper.sh"]
