FROM anapsix/alpine-java:jdk8
MAINTAINER Mike Babineau michael.babineau@gmail.com

ENV \
    EXHIBITOR_POM="https://raw.githubusercontent.com/Netflix/exhibitor/d911a16d704bbe790d84bbacc655ef050c1f5806/exhibitor-standalone/src/main/resources/buildscripts/standalone/maven/pom.xml" \
    EXBT_HOME="/opt/exhibitor" \
    ZOOKEEPER_VERSION="3.4.8" \
    ZK_HOME="/opt/zookeeper" \
    ZK_DATA_DIR="/var/lib/zookeeper" \
    ZK_LOG_DIR="/var/log/zookeeper" \
    MAVEN_VERSION="3.3.9" \
    JAVA_PREFS="/.java/.userPrefs" 

# Use one step so we can remove intermediate dependencies and minimize size
RUN apk add --update wget curl jq coreutils && \
    wget -q -O - http://apache.mirrors.pair.com/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/zookeeper-${ZOOKEEPER_VERSION} ${ZK_HOME} && \
    mkdir -p ${ZK_HOME}/transactions ${ZK_HOME}/snapshots /tmp/zookeeper ${EXBT_HOME} && \
    cp ${ZK_HOME}/conf/zoo_sample.cfg ${ZK_HOME}/conf/zoo.cfg && \
    wget --quiet http://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O - | tar xzf -  && \
    mv apache-maven-${MAVEN_VERSION} /usr/share/maven && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    curl -Lo ${EXBT_HOME}/pom.xml $EXHIBITOR_POM && \
    mvn -f ${EXBT_HOME}/pom.xml package && \
    mv ${EXBT_HOME}/target/exhibitor*jar ${EXBT_HOME}/exhibitor.jar && \
    cd ${EXBT_HOME}/ && mvn clean && \
    mkdir -p ${JAVA_PREFS}

ADD include/* ${EXBT_HOME}/

RUN chown -R nobody.nobody ${JAVA_PREFS} ${ZK_HOME} ${EXBT_HOME}

USER nobody

WORKDIR /opt/exhibitor

EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["/bin/sh", "-ex", "/opt/exhibitor/wrapper.sh"]
