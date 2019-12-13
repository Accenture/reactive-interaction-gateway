# Kinesis Localstack

Example showing how to use RIG with AWS Kinesis and [Localstack](https://github.com/localstack/localstack).

## Setup local Kinesis with RIG

> In case you still want to use deprecated version, uncomment line `examples/kinesis-localstack/docker-compose.yml:37`

```sh
# run Localstack and RIG
docker-compose up -d

# create Kinesis streams
docker-compose exec localstack bash -c 'awslocal kinesis create-stream --stream-name RIG-outbound --shard-count 1 --region eu-west-1 && awslocal kinesis create-stream --stream-name RIG-firehose --shard-count 1 --region eu-west-1'

# check created resources in Localstack
http://localhost:8080

# check RIG logs -> after few moments you should see running "record workers"
# you'll see all plenty fo logs about CloudWatch, but that's not important in local setup
docker logs -f reactive-interaction-gateway

# send event via AWS CLI
docker-compose exec localstack bash -c 'awslocal kinesis put-record --stream-name RIG-outbound --data "{\"specversion\":\"0.2\",\"type\":\"com.github.pull.create\",\"source\":\"https://github.com/cloudevents/spec/pull\",\"id\":\"A234-1234-1234\",\"time\":\"2018-04-05T17:31:00Z\",\"data\":\"hello\"}" --partition-key test --region eu-west-1'
```

## Setup Proxy API endpoint

### Recommended way

```sh
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"kinesis-service\",\"name\":\"kinesis-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"kinesis-producer-endpoint\",\"path\":\"/kinesis\",\"method\":\"POST\",\"secured\":false,\"target\":\"kinesis\",\"topic\":\"RIG-outbound\"}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"localstack\",\"port\":4568}}" \
--silent \
"http://localhost:4010/v2/apis"
```

### Deprecated way

> Will be removed in version 3.0.

```sh
# send event via RIG's proxy -> register API in RIG's proxy and send HTTP request
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"id\":\"kinesis-service\",\"name\":\"kinesis-service\",\"version_data\":{\"default\":{\"endpoints\":[{\"id\":\"kinesis-producer-endpoint\",\"path\":\"/kinesis\",\"method\":\"POST\",\"secured\":false,\"target\":\"kinesis\"}]}},\"proxy\":{\"use_env\":false,\"target_url\":\"localstack\",\"port\":4568}}" \
--silent \
"http://localhost:4010/v2/apis"
```

## Produce messages

```sh
# setting partition key manually
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"specversion\":\"0.2\",\"type\":\"com.github.pull.create\",\"source\":\"https://github.com/cloudevents/spec/pull\",\"id\":\"A234-1234-1234\",\"time\":\"2018-04-05T17:31:00Z\",\"rig\":{\"target_partition\":\"the-partition-key\"},\"data\":\"hello\"}" \
--silent \
"http://localhost:4000/kinesis"

# partition key not set -> will be randomized
curl -X "POST" \
-H "Content-Type: application/json" \
-d "{\"specversion\":\"0.2\",\"type\":\"com.github.pull.create\",\"source\":\"https://github.com/cloudevents/spec/pull\",\"id\":\"A234-1234-1234\",\"time\":\"2018-04-05T17:31:00Z\",\"data\":\"hello\"}" \
--silent \
"http://localhost:4000/kinesis"

# get Kinesis shard iterator and record -> should list several records ... you can also monitor RIG logs and see consumed events
docker-compose exec localstack bash -c 'export SHARD_ITERATOR=$(awslocal kinesis get-shard-iterator --stream-name RIG-outbound --shard-id 0 --shard-iterator-type TRIM_HORIZON --region eu-west-1 --query ShardIterator --output text) && awslocal kinesis get-records --shard-iterator $SHARD_ITERATOR --region eu-west-1'
```
