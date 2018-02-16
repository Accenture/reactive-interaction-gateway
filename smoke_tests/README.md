# Smoke tests

Test used to check correct integration between Reactive Interaction Gateway (RIG) and external backend services.

## Run fresh environment

Runs fresh environemnt, builds RIG image and runs smoke tests.

`docker-compose -f smoke_tests.docker-compose.yml up -d --build`

Show output of tests:

`docker logs -f rig`

## Re-run only tests

Keeps existing compose environment, restarts and rebuilds only RIG.

`docker-compose -f smoke_tests.docker-compose.yml up --no-deps --build rig`

## Local development testing

If you want to add new smoke tests or update existing ones, best way is to follow these steps:

```sh
# Start Kafka & Zookeeper
docker-compose -f kafka.docker-compose.yml up -d

# Start REST API, terminal 1
cd rest-api
npm i
npm start

# Run smoke tests, terminal 2
# from smoke_tests folder
cd ../
# make sure you are running it from project's root directory
KAFKA_ENABLED=true PROXY_CONFIG_FILE=proxy/proxy.smoke_test.json mix test --only smoke
```
