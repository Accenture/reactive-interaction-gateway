# Functional tests

Functional tests using [Cypress](https://www.cypress.io/) to cover all examples.

## Interactive mode vs. CI mode

Interactive mode is running tests in watch mode with visible UI interface -- ideal for development. CI mode runs tests only once and shows results -- ideal for pipelines.

```sh
# interactive mode
npm run cypress:open

# CI mode
npm run cypress:run

# run all tests
npm run cypress:run:all
```

## Tests without authentication

```sh
# start RIG
EXTRACTORS=examples/extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server

# or via Docker
docker run -d --name rig \
-e EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/data/name"}}},"greeting.jwt":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}},"nope":{"fullname":{"stable_field_index":1,"jwt":{"json_pointer":"/fullname"},"event":{"json_pointer":"/data/fullname"}}},"example":{"email":{"stable_field_index":1,"event":{"json_pointer":"/data/email"}}}}' \
-e JWT_SECRET_KEY=secret \
-p 4000:4000 \
rig

# run tests
npm run cypress:run:noauth
```

## Tests with JWT authentication

```sh
# start RIG
SUBSCRIPTION_CHECK=jwt_validation \
EXTRACTORS=examples/extractor.json \
JWT_SECRET_KEY=secret \
mix phx.server

# or via Docker
docker run -d --name rig \
-e SUBSCRIPTION_CHECK=jwt_validation \
-e EXTRACTORS='{"greeting":{"name":{"stable_field_index":1,"event":{"json_pointer":"/data/name"}}},"greeting.jwt":{"name":{"stable_field_index":1,"jwt":{"json_pointer":"/username"},"event":{"json_pointer":"/data/name"}}},"nope":{"fullname":{"stable_field_index":1,"jwt":{"json_pointer":"/fullname"},"event":{"json_pointer":"/data/fullname"}}},"example":{"email":{"stable_field_index":1,"event":{"json_pointer":"/data/email"}}}}' \
-e JWT_SECRET_KEY=secret \
-p 4000:4000 \
rig

# run tests
npm run cypress:run:jwt
```

## Channels tests

```sh
# start channels example
cd ../channels-example
./run-compose.sh
cd ../tests

# run tests
npm run cypress:run:channels
```
