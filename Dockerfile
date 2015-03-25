# Exhibitor + ZooKeeper
#
# VERSION       1

FROM thefactory/java

MAINTAINER Mike Babineau michael.babineau@gmail.com

# Get ZK
RUN curl -o /tmp/zookeeper-3.4.6.tar.gz http://www.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
RUN tar -xzf /tmp/zookeeper-3.4.6.tar.gz -C /opt && rm /tmp/zookeeper-3.4.6.tar.gz
RUN ln -s /opt/zookeeper-3.4.6 /opt/zookeeper
RUN mkdir /opt/zookeeper/transactions /opt/zookeeper/snapshots

# Get Exhibitor
RUN mkdir /opt/exhibitor
ADD include/pom.xml /opt/exhibitor/pom.xml
RUN cd /opt/exhibitor && mvn clean package
RUN ln -s /opt/exhibitor/target/exhibitor-1.0.jar /opt/exhibitor/exhibitor.jar

# Add the wrapper script to setup configs and exec exhibitor
ADD include/wrapper.sh /opt/exhibitor/wrapper.sh

# Add the optional web.xml for authentication
ADD include/web.xml /opt/exhibitor/web.xml

USER root
WORKDIR /opt/exhibitor
EXPOSE 2181 2888 3888 8181

ENTRYPOINT ["bash", "-ex", "/opt/exhibitor/wrapper.sh"]
