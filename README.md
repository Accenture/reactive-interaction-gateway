# RIG - Reactive Interaction Gateway

_The missing link between back-end and front-end -- stop polling and go real-time!_

[![Build Status](https://travis-ci.org/Accenture/reactive-interaction-gateway.svg?branch=master)](https://travis-ci.org/Accenture/reactive-interaction-gateway)

Take a look at the [documentation](https://accenture.github.io/reactive-interaction-gateway/) and get in touch with us on [Slack](https://rig-opensource.slack.com)!

## What does it solve?

In short: handling asynchronous events.

Slightly longer:

You want UI updates without delay, "real time". However, handling connections to thousands of front-end instances concurrently is not only hard to implement in a scalable way---it also makes it very hard (impossible?) to upgrade your service without losing those connections. And in a microservice environment, which service should manage those connections?

Instead, let RIG handle those connections for you. RIG is designed for scalability and allows you to concentrate on the actual business logic. Back-end (micro)services no longer have to care about connection state, which means they can be stateless, making it very easy to roll out updates to them. Sending notifications to all online devices of a certain user becomes as easy as POSTing a message to an HTTP endpoint.

Additionally, RIG comes with a basic API gateway implementation, which allows you to communicate both ways between your microservices and your front-ends.

## Getting Started

RIG uses [JSON Web Tokens (JWT)](https://en.wikipedia.org/wiki/JSON_Web_Token) to figure out to which user a connection belongs to. In a real setup, an authentication service would create the JWT once a user has been authenticated (logged in). The service would also sign the token using a "secret" (a shared key) that is also known to RIG.

> RIG currently supports symmetric hashing only (HS256, HS384, HS512). Please make sure to use keys of appropriate length, as described in [the spec](https://tools.ietf.org/html/rfc7518#section-3.2). For example, if you use HS256, your secret key should be at least 32 character (256 bit) in length.

When a front-end creates a connection to (or through) RIG, the request must contain such a JWT. Before handling the request, RIG verifies the JWT signature, which ensures that the token hasn't been tampered with.

In order to get started quickly, you don't need to implement an authentication service. Instead, you can either go to [jwt.io](https://jwt.io/) to create a new token, or use our helper script:

```bash
cd scripts/encode_jwt
mix escript.build
token=$(./encode_jwt --secret myJwtSecret --user alice --exp 1893456000)
```

In this example we use "myJwtSecret" as the secret key (not a suitable key for production!). The token contains the user ID and---since we're only playing around here---we also add an expiration date that is well in the future (exp is given in [seconds since the epoch](https://en.wikipedia.org/wiki/Unix_time)).

RIG expects the following fields to be present in the token: [`exp`](https://tools.ietf.org/html/rfc7519#section-4.1.4), [`jti`](https://tools.ietf.org/html/rfc7519#section-4.1.7) (e.g., used when blacklisting tokens), `roles` (a list of roles, may be empty), and `user` (basically used as a routing key). Our token should now look similar to this:

```javascript
// Header:
{
  "alg": "HS256",
  "typ": "JWT"
}
// Payload:
{
  "exp": 1893456000,
  "jti": "1521227425",
  "roles": [],
  "user": "alice"
}
```

Next we start up RIG, with the JWT secret provided as an environment variable.

```bash
docker run \
  -p 4000:4000 \
  -p 4010:4010 \
  -e JWT_SECRET_KEY=myJwtSecret \
  accenture/reactive-interaction-gateway
```

RIG is now ready to accept front-end connections. Let's simulate a browser app that uses [Server-Sent Events](https://en.wikipedia.org/wiki/Server-sent_events) to subscribe to RIG:

```bash
# Using curl:
curl "localhost:4000/socket/sse?users\[\]=alice&token=$token"

# Or in case you prefer HTTPie:
http --stream "localhost:4000/socket/sse?users[]=alice&token=$token"
```

The username should match what's in the token, otherwise RIG won't allow you to connect.

You should see some messages now, followed by incoming heartbeat events. Fire up another terminal window, where we can push a message through RIG:

```bash
curl -H 'content-type: application/json' -d '{"user":"alice","text":"Hi, Alice!"}' localhost:4010/v1/messages
```

After this you should see "Hi, Alice!" popping up in the other window! :tada:

Note that for posting the message we've used another port---that's the _internal_ port running RIG's API. While the external port (4000) can be exposed to the internet, the internal one (4010) is meant to be used by your back-end services only.

## Feature Summary

- Massively scalable, thanks to
  - only using in-memory databases, along with eventually-consistent cluster synchronization
  - Erlang/OTP, the platform RIG is built on
- Towards frontends, support Server-Sent Events (SSE), WebSocket and HTTP long-polling
  connections
- Supports privileged users that are able to subscribe to messages of other users
- Supports JWT signature verification for APIs that need authentication
  - with blacklisting for immediate invalidation of tokens

## Configuration, Integration, Deployment

It should be easy to integrate RIG into your current architecture---if you have any problems, please open a Github issue. Check out
[the operator's guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-ops-guide.html) for details.

We use [SemVer](http://semver.org/) for versioning. For the versions available, take a look at the
[list of tags](https://github.com/Accenture/reactive-interaction-gateway/tags).

## Contribute

- **Use issues for everything.**
- For a small change, just send a PR.
- For bigger changes open an issue for discussion before sending a PR.
- PR should have:
  - Test case
  - Documentation (e.g., moduledoc, developer's guide, operator's guide)
  - Changelog entry
- You can also contribute by:
  - Reporting issues
  - Suggesting new features or enhancements
  - Improve/fix documentation

See the [developer's guide](guides/developer-guide.md) and [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

## License

The Reactive Interaction Gateway (patent pending) is licensed under the Apache License 2.0 - see
[LICENSE](LICENSE) for details.

## Acknowledgments

The Reactive Interaction Gateway is sponsored and maintained by [Accenture](https://accenture.github.io/).

Kudos to these awesome projects:

- Elixir
- Erlang/OTP
- Phoenix Framework
- Brod
- Distillery

## FAQ

### How is it different from other API gateways like [Tyk](https://tyk.io/) or [Kong](https://getkong.org/)?

They are great API gateways, but they don't handle asynchronous events.

### How is it different from Serverless' [Event Gateway](https://serverless.com/event-gateway/)?

While both are designed around the idea of being reactive to events, the Event Gateway has been
created with a different use case in mind, specializing on handling events across multiple cloud
providers. RIG's focus is on handling the online state of users, with multiple devices per user,
and the corresponding duplex connections. Consequently, RIG has a very strong focus on
horizontal scalability, while maintaining some of the characteristics of a traditional API
gateway. That said, if your architecture includes both, interactive UIs as frontends and
serverless backends, perhaps even running in different cloud environments, then you might even
benefit from running both gateways in a complementary way.
