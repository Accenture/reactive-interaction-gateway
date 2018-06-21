---
id: faq
title: Frequently Asked Questions
sidebar_label: FAQ
---

Feel free to open an issue/PR to add a new question or to suggest improvements to an existing one.

## What is RIG?

The Reactive Interaction Gateway (RIG) is an infrastructure component designed to allow bidirectional communication between frontends and backends of web/mobile apps. By maintaining active connections to all frontends available in a system, RIG allows backends to send events to frontends directly, without using mailboxes or polling. For more information, check out the [introduction](intro.md).

## Do I have to use or know anything about Elixir or Erlang?

No - if you know how to run a Docker container, you should feel right at home.
The configuration is done using environment variables; take a look at the [operator's guide](rig-ops-guide.md) to see all available settings.

There might be occasions, however, where a rudimentary familiarity with Erlang data structures might come in handy when interpreting error messages.

## What kind of state does RIG handle for me?

RIG handles connection state; it keeps track of which user has which devices connected where. Is uses this state to route outbound messages towards the users/devices/frontends.

Additionaly, RIG also keeps track of a JWT blacklist and its reverse-proxy/gateway API definitions.

RIG does not use disk storage - all state is kept in memory.

## So everything is stored in-memory. What happens if RIG goes down?

As long as there is another RIG node to connect to, restarted nodes are able to recover simply by connecting to any node in the existing cluster. If all nodes are down, RIG will start with an empty JWT blacklist and hydrate its API definitions from the supplied configuration file.

## How is RIG different to..

Probably biased comparisons to some similar (looking) products out there. Feel free to send a PR for clarifications and additions.

### AWS AppSync

[AppSync](https://aws.amazon.com/appsync/) is not only concerned with connection state like RIG is, but manages application state on top of that (AppSync looks similar to what could be built using a backend-for-frontend with [pouchdb](https://pouchdb.com/) with other data sources aggregated by the backend).

RIG, on the other hand, is concerned with the connection state and flow of data rather than data synchronization. For example, you could implement something similar to AppSync by having frontends send data updates to a backend service that applies conflict resolution according to business rules before pushing any resulting updates through RIG back to the frontends. Offline data synchronization could be done on the frontend by using a service worker that dumps the app state to that backend service as soon as the frontend comes back online. A setup like that has some nice properties:

- Frontend development built on standards with no SDK necessary.
- No coupling between RIG and data sources - AppSync requires Mapping Templates to map queries to data sources.
- Open source software, no vendor lock-in.

### API (Management) Gateways like [Apigee API Platform](https://apigee.com/api-management), [Tyk](https://tyk.io/) or [Kong](https://getkong.org/)?

They are great API Gateways, but they are not designed around handling asynchronous events. Note that RIG is often best used in _combination_ with an API Management solution that handles things like API key management and usage statistics.

### Serverless Event Gateway

While both are designed around the idea of being reactive to events, the [Event Gateway](https://serverless.com/event-gateway/) has been created with a different use case in mind, specializing on handling events across multiple cloud providers. RIG's focus is on handling the online state of users, with multiple devices per user, and the corresponding duplex connections. Consequently, RIG has a very strong focus on horizontal scalability, while maintaining some of the characteristics of a traditional API gateway. That said, if your architecture includes both, interactive UIs as frontends and serverless backends, perhaps running in different cloud environments, then you might even benefit from running both gateways in a complementary way.
