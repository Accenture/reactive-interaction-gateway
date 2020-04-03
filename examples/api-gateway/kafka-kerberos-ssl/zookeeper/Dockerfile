FROM centos:centos8
MAINTAINER d.gasparina@gmail.com
ENV container docker

# 1. Adding Confluent repository
RUN rpm --import https://packages.confluent.io/rpm/5.4/archive.key
COPY confluent.repo /etc/yum.repos.d/confluent.repo
RUN yum clean all

# 2. Install zookeeper and kafka
RUN yum install -y java-11-openjdk
RUN yum install -y confluent-platform-2.12

# 3. Configure zookeeper for Kerberos
RUN yum install -y krb5-workstation krb5-libs
COPY zookeeper.properties /etc/kafka/zookeeper.properties
COPY zookeeper.sasl.jaas.config /etc/kafka/zookeeper_server_jaas.conf

EXPOSE 2181

ENV KAFKA_OPTS=-Djava.security.auth.login.config=/etc/kafka/zookeeper_server_jaas.conf

CMD zookeeper-server-start /etc/kafka/zookeeper.properties
