# Gatling test cases for Reactive Interaction Gateway

Recommended OS setup

```sh
sysctl -w fs.file-max=12000500
sysctl -w fs.nr_open=20000500
ulimit -n 20000000
sysctl -w net.ipv4.tcp_mem='10000000 10000000 10000000'
sysctl -w net.ipv4.tcp_rmem='1024 4096 16384'
sysctl -w net.ipv4.tcp_wmem='1024 4096 16384'
sysctl -w net.core.rmem_max=16384
sysctl -w net.core.wmem_max=16384
sysctl -w net.ipv4.ip_local_port_range="1024 64000"
```

## Components

Zookeeper

```sh
docker run --name zk -d \
-e ZOOKEEPER_CLIENT_PORT=2181 \
-p 2181:2181 \
confluentinc/cp-zookeeper:4.0.0-3
```

Kafka

```sh
docker run --name kafka -d \
-e KAFKA_BROKER_ID=1 \
-e KAFKA_ZOOKEEPER_CONNECT=zookeeper_ip:2181 \
-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka_ip:9092 \
-e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-p 9092:9092 \
-v /var/run/docker.sock:/var/run/docker.sock \
confluentinc/cp-kafka:4.0.0-3

# Create & list topic
kafka-topics --create --topic message --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper_ip:2181
kafka-topics --describe --topic message --zookeeper zookeeper_ip:2181
```

RIG

```sh
# Latest version
docker run --name rig -d \
-e NODE_HOST=127.0.0.1 \
-e NODE_COOKIE=magiccookie \
-e JWT_ROLES_FIELD=role \
-e JWT_SECRET_KEY=jwttoken \
-e JWT_USER_FIELD=username \
-e KAFKA_ENABLED=true \
-e KAFKA_SOURCE_TOPICS=message \
-e KAFKA_HOSTS=kafka_ip:9092 \
-e MESSAGE_USER_FIELD=username \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-p 4000:4000 \
-p 4010:4010 \
accenture/reactive-interaction-gateway

# Version 1
docker run --name rig -d \
-e JWT_ROLES_FIELD=role \
-e JWT_SECRET_KEY=jwttoken \
-e JWT_USER_FIELD=username \
-e KAFKA_ENABLED=true \
-e KAFKA_SOURCE_TOPICS=message \
-e KAFKA_HOSTS=kafka_ip:9092 \
-e KAFKA_USER_FIELD=username \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-p 4000:4000 \
accenture/reactive-interaction-gateway:1.1.0

# Using observer_cli
rebar3 shell --name 'observer_cli@127.0.0.1'
observer_cli:start('rig@127.0.0.1', 'magiccookie').
```

Gatling Kafka

```sh
docker run --name gatling \
-e TEST_SERVER=rig_ip:4000 \
-e KAFKA_HOSTS=kafka_ip:9092 \
-e TARGET_USERS=500 \
-e RAMP_UP_PERIOD=30 \
-e MESSAGES_N=500 \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-v $HOME/.m2:/root/.m2 \
-v $HOME/gatling:/usr/src/app/target/gatling \
rig-gatling mvn gatling:test -Dgatling.simulationClass=com.accenture.lwa.ares.simulation.WsMultiBroadcastSimulation
```

Gatling WS Idle

```sh
docker run --name gatling \
-e TEST_SERVER=rig_ip:4000 \
-e KAFKA_HOSTS=kafka_ip:9092 \
-e TARGET_USERS=5000 \
-e RAMP_UP_PERIOD=30 \
-e PAUSE_N=60 \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-v $HOME/.m2:/root/.m2 \
-v $HOME/gatling:/usr/src/app/target/gatling \
rig-gatling mvn gatling:test -Dgatling.simulationClass=com.accenture.lwa.ares.simulation.WsMaxUsersSimulation

docker run --name gatling \
-e TEST_SERVER=rig_ip:4000 \
-e KAFKA_HOSTS=kafka_ip:9092 \
-e TARGET_USERS=5000 \
-e RAMP_UP_PERIOD=30 \
-e PAUSE_N=60 \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-v $HOME/.m2:/root/.m2 \
-v $HOME/gatling:/usr/src/app/target/gatling \
rig-gatling mvn gatling:test -Dgatling.simulationClass=com.accenture.lwa.ares.simulation.WsMaxUsersSimulation
```

REST API

```sh
docker run --name rest-api -d \
-p 8000:8000 \
rest-api
```

Register endpoints

```sh
# Latest version
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"api-service\",\"name\":\"api-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"get-endpoint\",\"path\":\"/api\",\"method\":\"GET\",\"not_secured\":true}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"rest_api_ip\",\"port\":8000}}" \
--silent \
"http://localhost:4010/v1/apis"

# Version 1
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"api-service\",\"name\":\"api-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"get-endpoint\",\"path\":\"/api\",\"method\":\"GET\",\"not_secured\":true}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"52.47.101.190\",\"port\":8000}}" \
--silent \
"http://localhost:4000/apis"
```

Gatling REST API

```sh
docker run --name gatling \
-e TEST_SERVER=rig_ip:4000 \
-e TEST_SERVER_API=rig_ip:4010 \
-e KAFKA_HOSTS=kafka_ip:9092 \
-e TARGET_USERS=600 \
-e RAMP_UP_PERIOD=30 \
-e REQUESTS_N=1000 \
--sysctl net.ipv4.ip_local_port_range="1024 64000" \
-v $HOME/.m2:/root/.m2 \
-v $HOME/gatling:/usr/src/app/target/gatling \
rig-gatling mvn gatling:test -Dgatling.simulationClass=com.accenture.lwa.ares.simulation.GetSimulation
```

## Kafka roundtrip measurement

Measures how much time it takes to produce & consume message - end to end roundtrip for Kafka.

```
wget https://github.com/hey-johnnypark/kafka-latency-meter/releases/download/v1.0/kafka-latency-meter.jar && \
java -jar kafka-latency-meter.jar \
--kafka.topic=message \
--kafka.message.size=64 \
--kafka.ratePerSecond=10000 \
--kafka.numMessages=1000000 \
--spring.kafka.bootstrap-servers=kafka_ip:9092
```

