---
id: architecture
title: Architecture
sidebar_label: Architecture
---

When we've designed the initial version of RIG back in 2016, we had a very specific set of problems in mind. Our mission back then was to redesign banking with state-of-the-art patterns, principles and tools - full-stack. Not surprisingly, we went for microservices, but we also wanted some sort of near real-time information flow from (potentially) _all_ those services to our web and mobile frontends. We quickly realized that there was no open-source, off-the-shelf solution for this, despite the fact that we were not the only ones with this requirement. We've started asking around internally and at conferences. The solution we heard most often was to use an existing backend-for-frontend service (a dedicated service for handling client requests that acts on behalf of those clients towards other backend services) and turn it into a WebSocket endpoint for frontends. We've also met someone who apparently implemented a solution using Lua scripts running on their Nginx reverse proxy - probably a nice implementation, but hardly scalable.

We weren't happy with any of those solutions - they seemed kind of hacky and couldn't address all our goals.

## The Problem

RIG tackles a set of (seemingly unrelated) problems:

- Frontends must be able to react to any back-end event, regardless of the producing service.
- The design must support a large number of microservices, so polling for updates is not an option.
- Microservices must remain stateless and not be concerned with frontend connections, so a long running connection between frontend and microservice is not an option either.
- Exposing backend events requires some sort of authorization mechanism. Especially in the banking domain, it is import to be able to kick out a logged-in user immediately (for example, when fraud is suspected).

Why not introduce (connection) state for microservices? Two reasons. First, it makes re-deployment harder, unless you don't care about breaking client connections everytime you ship an update. More importantly, however, handling connection state introduces a scalability issue: assuming all frontends hold connections to all microservices, then all services need to be scaled out at the same time as soon as the number of connections exceeds the number of available TCP sockets.

## Event-Driven Architecture and the UI

Forwarding events to frontends enables and event-driven UX design, effectively extending the idea of [event-driven architecture](https://en.wikipedia.org/wiki/Event-driven_architecture) to the UI.

We believe that hiding asynchronism by turning it into a fake synchronous process is an anti-pattern. For example, sending money from one bank account to another doesn't happen instantaneously, but with at least two events: "transfer requested" and "transfer completed" (or "transfer failed"). Acknowledging this when designing the UI leads to a more natural user experience and less loading indicators.

On the other hand, it is also known that doing the opposite is an anti-pattern as well. For example, submitting a request form to send money around is very likely a synchronous action on the frontend - even though the actual transfer won't be completed immediately, the client typically wants to know whether the request got accepted or not. While it would work to model this with a "request form submitted" event, it introduces unnecessary complexity: waiting for the response, as well as reacting to not having received a response within a selected time frame, is arguably harder to implement than simply using a synchronous (HTTP) request instead.

Consequently, we've settled on the rather pragmatic approach of combining synchronous requests with synchronous _and_ asynchronous responses, depending on the use case at hand.

With that in mind, adding a reverse-proxy ("API Gateway") capability to RIG seemed like a natural extension. After all, RIG already dealt with sessions (and blacklisting them) and it made sense to employ the same checks for synchronous requests towards the backend.

## Dealing with Connection Loss

When frontends rely on events to update their state, they must either never miss an event, or they must be able to deal with lost events. Clearly, never missing an event is not possible (lossy mobile connections, network roaming, etc.). So the question is: how to notice and react to lost events?

### Notice lost events on a Server-Sent Events connection

Your frontend should be able to notice lost events quite easily:

- The [`EventSource` interface offers an `onerror` callback](https://html.spec.whatwg.org/multipage/server-sent-events.html#handler-eventsource-onerror) that can be used to find out about network errors.
- Whenever a connection is (re-)established, RIG emits an event of type "rig.connection.create".

Make sure you handle both the callback and RIG's event.

### React to lost events

As soon as the (SSE) connection to RIG has been (re-)established, the frontend should setup any manual subscriptions with RIG and use HTTP calls towards back-end services to refresh its state. After that, incoming events can be applied to the local state.

When the response to a synchronous request interleaves with incoming events, it may become tricky to infer the state your frontend should be in. Unfortunately, how to solve this problem pretty much depends on the domain and types of events you're dealing with, so there is no silver-bullet solution. Ideas that could work for you:

- When sourcing events on the frontend, deduplicate events by their event ID (per source/producer).
- Have the producer add a timestamp to the synchronous response and compare that to the event's time field (per source/producer).
- Don't use events for updating the state, but rather as a trigger for fetching the newest data from the source/producer service using an HTTP call.

Likely you'll need to apply different patterns for different events and data in your application.

## Providing a Synchronous API for Asynchronous Back-End Services

The good old public REST API is still common, so you cannot always rely on Server-Sent Events or WebSocket to communicate asynchronous events. Going back to the previous example of sending money from one bank account to another, an external service that triggers such a transfer through your RESTful web interface might indeed want to wait for the whole process to complete, regardless of how many events and services are actually involved. That's exactly what we've described as an anti-pattern above, but for a public API there's little we can do about it.

To support this use case, RIG is able to "convert" HTTP calls to Kafka events. Optionally, RIG also waits for a corresponding response event from a Kafka topic. Using the example again, this might look like this:

1. The third-party client sends an HTTP request to RIG
2. RIG produces a request event to a Kafka topic, adding a correlation ID representing the client connection
3. A service picks up the request and emits a "processed" event, retaining RIG's correlation ID
4. RIG listens on a Kafka topic for events that have a correlation ID set, picks up the "processed" event and sends it as a response down the still-open HTTP connection to the waiting third-party client.
