---
type: artifact
name: Vision Document
phase: Vision
produces: Project vision document
---

# Vision — Reactive Interaction Gateway (RIG)

**Phase:** DDE Phase 1 — Vision
**Status:** Draft
**Date:** 2026-03-18

---

## Problem Statement

Modern microservice architectures need bidirectional, real-time communication between frontend clients and backend services. Today's solutions fall short:

1. **Direct client-to-service coupling** — Frontends call backend services directly, creating tight coupling, exposing internal topology, and requiring clients to know which service owns which data. Every new service means frontend changes.

2. **Polling-based approaches** — Clients poll for updates, wasting bandwidth, introducing latency, and creating unnecessary load on backends. Real-time experiences (notifications, live dashboards, collaborative editing) become expensive hacks built on top of request/response.

3. **Custom WebSocket/SSE implementations per service** — Each team builds their own real-time push mechanism, duplicating auth logic, connection management, and event routing. No standard event format, no centralized subscription management, no unified observability.

4. **Traditional API gateways (Kong, Envoy, etc.)** — Handle inbound request routing well but have no concept of event-driven outbound push. They solve half the problem — the request/response half — and leave the event-driven half to each team.

---

## Vision

RIG is the **event-driven API gateway** that sits between frontends and microservices, handling both directions of communication through a single, unified layer. Inbound: it routes client requests to the right backend (synchronously or via message brokers). Outbound: it consumes events from Kafka, NATS, or Kinesis and pushes them to the right connected clients based on their subscriptions — over WebSocket, SSE, or long-polling.

The key insight is that **API routing and event routing belong together**. A client that makes a request and a client that subscribes to events are the same client, with the same auth token, the same session, and the same connection. RIG unifies these concerns in a single gateway that speaks both HTTP and event streams, with JWT-based auth, subscription-based event filtering, CloudEvents support, and distributed tracing out of the box.

Built on Erlang/OTP, RIG is inherently fault-tolerant and massively concurrent — designed to handle tens of thousands of persistent connections per node while maintaining sub-millisecond event routing latency.

---

## Who It's For

### Primary Audience

- **Platform engineers** building event-driven microservice architectures who need a unified gateway for both request/response and event push patterns
- **Backend developers** who want to emit events to message brokers and have them automatically delivered to the right connected clients without building custom WebSocket infrastructure

### What They Have in Common

- Building on microservice or event-driven architectures
- Need real-time updates pushed to frontends without polling
- Want to decouple frontend clients from backend service topology

### Secondary Audience

- **DevOps/SRE teams** operating microservice platforms who need unified observability across HTTP and event traffic
- **Frontend developers** who want a simple, consistent API for both requests and real-time subscriptions

---

## Why Now

1. **Event-driven architectures are mainstream** — Kafka, NATS, and cloud event buses are standard infrastructure. The gap between "events exist in the backend" and "events reach the frontend" remains unsolved by most API gateways.

2. **AI-native development enables revitalization** — RIG has a solid, proven architecture but has been in maintenance mode. DDE's agent-driven development can systematically modernize the codebase, upgrade dependencies, and add missing capabilities at a pace that wasn't feasible with limited contributor bandwidth.

3. **CloudEvents and AsyncAPI standardization** — The event ecosystem has matured with standards that RIG was ahead of. Deepening CloudEvents support and adding AsyncAPI documentation makes RIG the reference implementation for event-driven API gateways.

---

## What Success Looks Like

### User Outcomes

- Platform teams can deploy RIG and have bidirectional client-service communication working in under an hour
- Backend developers emit events to Kafka/NATS and clients receive them in real-time without any custom WebSocket code
- Zero-downtime deployments with no dropped connections or lost events

### Technical Outcomes

- Modern Elixir/OTP stack (current Elixir and Erlang versions)
- Comprehensive test coverage (unit, integration, property-based)
- Full CloudEvents v1.0 compliance
- Sub-millisecond event routing latency at 10k+ concurrent connections per node
- Production-grade observability (metrics, tracing, structured logging)

### Success Metrics

| Category | Metric | Target | How Measured |
| -------- | ------ | ------ | ------------ |
| Adoption | GitHub stars growth | 2x current over 12 months | GitHub API |
| Quality | Test coverage | >85% line coverage | ExCoveralls |
| Performance | Event routing latency (p99) | <5ms at 10k connections | Artillery load tests |
| Reliability | Connection drop rate during deploys | 0% | Integration tests |
| Developer Experience | Time to first event delivery | <30 minutes from git clone | Tutorial walkthrough |

---

## Scope Boundaries

### In Scope (v4 — Next Major)

- Upgrade to current Elixir/OTP versions
- Modernize dependency chain (replace deprecated libraries)
- Strengthen CloudEvents v1.0 compliance
- Improve developer experience (better docs, examples, error messages)
- Harden security (audit auth flow, update JWT handling)
- Expand test coverage with property-based testing
- Production deployment hardening (graceful shutdown, connection draining)

### Out of Scope (v4)

- GraphQL subscription support — deferred until core modernization complete
- gRPC bidirectional streaming — evaluate after v4 stabilization
- Multi-tenancy — would require significant architectural changes
- Built-in UI/dashboard — RIG is headless infrastructure

### Deferred Decisions

| Decision | Leaning | Decide By |
| -------- | ------- | --------- |
| Replace Distillery with mix release | Yes — Distillery is deprecated | Blueprint |
| Add OpenTelemetry (replace OpenCensus) | Yes — OpenCensus is EOL | Blueprint |
| NATS JetStream support | Likely yes | Specification |
| WebTransport support | Evaluate feasibility | Post-v4 |

---

## Open Questions for Concept Phase

1. What is the minimum viable modernization — which dependency upgrades are blocking vs. nice-to-have?
2. How do we handle the Kinesis Java client dependency (currently a JVM sidecar)?
3. Should we restructure the OTP application tree, or keep the current multi-app umbrella?
4. What's the migration path for existing v3 deployments to v4?

---

## Next Steps

1. ~~**Contrarian challenge session**~~ — N/A (existing project retrofit — Vision derived from codebase analysis, not speculative design)
2. **Concept document** — Done: [CONCEPT.md](CONCEPT.md)
3. **Solution Blueprint** — Done: [SOLUTION_BLUEPRINT.md](../architecture/SOLUTION_BLUEPRINT.md)

---

_This is a living document. Update as understanding deepens._
