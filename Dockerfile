# Exhibitor + ZooKeeper
#
# VERSION       1

FROM debian:wheezy

MAINTAINER Mike Babineau mike@thefactory.com

# Update package list
RUN apt-get update

# Install Java, wget, and maven
RUN apt-get -y install openjdk-7-jdk wget maven
RUN ln -s /usr/lib/jvm/java-1.7.0-openjdk-amd64/jre/lib/amd64/server/libjvm.so /usr/lib/libjvm.so

# Get ZK
RUN wget -q -O /tmp/zookeeper-3.4.6.tar.gz http://www.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
RUN tar -xzf /tmp/zookeeper-3.4.6.tar.gz -C /opt && rm /tmp/zookeeper-3.4.6.tar.gz
RUN ln -s /opt/zookeeper-3.4.6 /opt/zookeeper
RUN mkdir /opt/zookeeper/transactions /opt/zookeeper/snapshots

# Get Exhibitor
RUN mkdir /opt/exhibitor
ADD include/pom.xml /opt/exhibitor/pom.xml
RUN cd /opt/exhibitor && mvn assembly:single
RUN ln -s /opt/exhibitor/target/exhibitor-1.0-jar-with-dependencies.jar /opt/exhibitor/exhibitor.jar

# Add the wrapper script to setup configs and exec exhibitor
ADD include/wrapper.sh /opt/exhibitor/wrapper.sh

USER root
WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/wrapper.sh"]