# Smoke tests

Test used to check correct integration between Reactive Interaction Gateway (RIG) and external backend services.

## Smoke-test a Docker build

Run the following script:

```bash
./run_smoke_tests.sh
```

Subsequent runs will be a bit faster, as the script does not tear down additional services.

## Smoke-test during development

The `run_smoke_tests.sh` scripts leaves Kafka and the fake REST-API service running, so you can easily run tests against them during development. For example, run this when in the project root directory:

```bash
KAFKA_ENABLED=true PROXY_CONFIG_FILE=proxy/proxy.smoke_test.json mix test --only smoke
```

The default setting for the Kafka broker location is `localhost:9092`, so it'll pick up the running Kafka Docker container.

## Clean up

When you're done:

```bash
docker-compose -f smoke_tests.docker-compose.yml down
```
