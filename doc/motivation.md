# Why we built RIG

Typically, an API gateway acts as a
[reverse proxy](https://en.wikipedia.org/wiki/Reverse_proxy), forwarding
requests from frontend to backend services. The backend services typically
send back a reply, which is then forwarded back to the client.

Quite often, you'd like your UI to display events as they occur (think "two
customer's are looking at this" on your favorite hotel-booking site). The
simplest way to implement this is by having the frontend poll a backend
service for updates, but this doesn't scale well - a lot of extra traffic and
a single service that is coupled to all services that emit interesting
events.

The first problem is easy: to reduce traffic and get rid of potentially large
notification delays, you could also have your reverse proxy forward a
websocket connection, or something similar, to that backend service.

The approach so far works okay as long as you have a monolithic application,
but fails in a microservice environment: it's a single component coupled to
most services in your system as it asks them for updates - any change in any
other service will affect it. We can solve this problem by decoupling the
services using some kind of messaging service, like Kafka; now the
backend-for-frontends service simply listens to the Kafka stream, where all
other services publish their events to.

This is exactly what RIG does: it subscribes to Kafka topics, while holding
connections to all active frontends, forwarding events to the users they're
addressed to, all in a scalable way. And on top of that, it also handles
authorization, so your services don't have to care about that either.

For integrating the event stream into frontends, RIG supports several options
(and additional transports are
[easy to implement](https://hexdocs.pm/phoenix/Phoenix.Socket.Transport.html)):
- [Server-Sent Events (SSE)](https://en.wikipedia.org/wiki/Server-sent_events)
- [WebSocket](https://en.wikipedia.org/wiki/WebSocket)
  (best implemented using the
  [official JS library of the Phoenix web framework](https://www.npmjs.com/package/phoenix))
- HTTP long-polling

## Design goals

- Handling of huge numbers of active frontend connections simultaneously
- Easily and massively horizontally scalable
- Minimal impact on frontend code using open and established standards to
  choose from (see transports above)
- Be resilient to faults
- Easy to use, simple to deploy (so far we managed to get away without
  external dependencies)