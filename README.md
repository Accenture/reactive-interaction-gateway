# Gateway

## Getting started

To get up and running:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

When debugging multi-node features, it's helpful to run the (named) nodes in `iex` sessions using `iex --sname nodename -S mix`.


## Architecture

Todo: a picture of the supervisor tree.

#### Kafka consumer
In order to scale horizontally, Kafka Consumer Group are used. Brod, which is the library used for communicating with Kafka, has its client supervised by `Gateway.Kafka.Sup`, which also takes care of the group subscriber. It uses delays between restarts, in order to delay reconnects in the case of connection errors.

`Gateway.Kafka.Sup` is itself supervised by `Gateway.Kafka.SupWrapper`. The wrapper's sole purpose is to allow the application to come up even if there is not a single broker online. Without it, the failure to connect to any broker would propagate all the way to the Phoenix application, bringing it down in the process. Having the wrapper makes the application startup more reliable.

The consumer setup is done in `Gateway.Kafka.GroupSubscriber`; take a look at its moduledoc for more information. Finally, `Gateway.Kafka.MessageHandler` hosts the code for the actual processing of incoming messages.

## More info on Phoenix

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## Deployment

```
# build environment
docker build \
-t rge-build \
-f build.dockerfile \
.

# run build environment
docker run \
--name rg-build \
-v "${PWD}"/fsa-reactive-gateway:/opt/sites/fsa-reactive-gateway/_build/prod/rel/gateway \
rge-build

# build app
docker build -t rge-app .

# run app
docker run \
--name rg-app \
-p 6060:6060 \
-e KAFKA_HOSTS=<host>:9092 \
-e IS_HOST=<host> \
-e PS_HOST=<host> \
-e TS_HOST=<host> \
rge-app
```
