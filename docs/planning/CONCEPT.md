---
type: artifact
name: Concept Document
phase: Concept
produces: Project concept document
---

# Concept — Reactive Interaction Gateway (RIG)

**Phase:** DDE Phase 2 — Concept
**Status:** Draft
**Date:** 2026-03-18
**Vision:** [VISION.md](VISION.md)

---

## 1. The Nucleus

RIG is a **bidirectional event-driven API gateway** — the single infrastructure component that routes client requests to backends AND pushes backend events to the right connected clients. Remove this bidirectionality and you have two separate systems (an API gateway + a push notification service) that don't share auth, sessions, or connection state. The nucleus is the unification: one gateway, both directions, shared context.

---

## 2. Core Capabilities

Six capabilities form the minimum viable product. Each is essential; none can be cut without undermining the nucleus.

### 2.1 Inbound Request Routing (API Proxy)

Routes client HTTP requests to backend services using configurable API definitions. Supports synchronous (HTTP proxy), asynchronous (fire-and-forget to Kafka/NATS), and pseudo-synchronous (async send, wait for response event) modes.

**What it does:**
- Matches incoming requests to backend targets via path/method rules
- Proxies requests with header forwarding, auth token pass-through
- Supports multiple response modes per endpoint

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| Client sends HTTP request | RIG matches route, forwards to backend | Client receives response (sync) or 202 Accepted (async) |
| API definition updated via management API | Proxy reloads routing table | New routes active immediately, no restart |

### 2.2 Outbound Event Push

Consumes events from message brokers (Kafka, NATS, Kinesis) and pushes them to connected clients based on their subscriptions.

**What it does:**
- Subscribes to configured event stream topics
- Matches incoming events against client subscriptions using JSON Pointer extractors
- Delivers matched events to clients over their active connection (WebSocket, SSE, long-polling)

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| Event arrives on Kafka topic | EventFilter matches against all active subscriptions | Matching clients receive the event in real-time |
| Client disconnects | Subscriptions cleaned up | No stale delivery attempts |

### 2.3 Client Connection Management

Manages persistent connections from frontend clients over WebSocket, Server-Sent Events (SSE), and HTTP long-polling. Handles connection lifecycle, heartbeats, and reconnection.

**What it does:**
- Accepts WebSocket upgrades, SSE connections, and long-poll requests
- Maintains session state per connected client
- Supports JWT-based session identification

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| Client opens WebSocket | Connection established, JWT validated, subscriptions activated | Client ready to receive events |
| Connection lost | Session state retained briefly for reconnection | Client can resume without re-subscribing |

### 2.4 Subscription & Event Filtering

Allows clients to declare interest in specific event types or event field values. The EventFilter matches incoming events against subscriptions using constraint-based matching.

**What it does:**
- Clients create subscriptions with field-level constraints (e.g., `user_id = "abc"`)
- Constraints use JSON Pointer paths for field extraction from CloudEvents
- Conjunctive normal form for complex matching (AND/OR combinations)

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| Client subscribes to `order.completed` where `customer_id = X` | Subscription registered in EventFilter | Only matching events delivered to this client |
| JWT claims extracted | Auto-subscriptions created from token claims | Client receives events for their identity without explicit subscribe |

### 2.5 Authentication & Authorization

JWT-based authentication for both inbound requests and outbound connections. Supports token blacklisting for session revocation.

**What it does:**
- Validates JWT tokens on connection and per-request
- Extracts claims for subscription auto-creation
- Maintains a distributed blacklist for revoked tokens
- Supports multiple JWT algorithms and key sources

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| Client presents JWT | Token validated, claims extracted | Session bound to identity |
| Token added to blacklist via API | Distributed set updated | All nodes reject the token immediately |

### 2.6 Observability & Operations

Production-grade monitoring, tracing, and logging for both HTTP and event traffic.

**What it does:**
- Prometheus metrics for connections, events, proxy operations
- Distributed tracing with W3C Trace Context propagation
- Structured JSON logging with correlation IDs
- Health check endpoints for orchestrators

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| Prometheus scrapes /metrics | Metrics exported | Dashboards and alerts work |
| Request enters RIG | Trace context extracted/created, propagated to backend | End-to-end tracing across the event pipeline |

---

## 3. User Journey

The primary user journey: a platform engineer sets up RIG to bridge their frontend app and backend microservices.

### 3.1 Deploy & Configure

**User intent:** Get RIG running and connected to their message broker
**Experience:** Pull Docker image, set environment variables for Kafka/NATS connection, JWT secret, and upstream backends. Start RIG. Health check confirms connectivity.
**Output:** RIG running, connected to message broker, management API accessible

### 3.2 Define API Routes

**User intent:** Route frontend requests through RIG to their backend services
**Experience:** POST to RIG's management API with route definitions (path, method, target URL, response mode). Routes activate immediately.
**Output:** Frontend can make requests through RIG to any configured backend

### 3.3 Connect Frontend Clients

**User intent:** Establish real-time connections for event delivery
**Experience:** Frontend opens a WebSocket (or SSE/long-poll) connection to RIG with a JWT token. RIG validates the token and establishes the session.
**Output:** Client connected, identified, ready for subscriptions

### 3.4 Subscribe to Events

**User intent:** Receive specific events relevant to this client
**Experience:** Client sends subscription message over WebSocket (or via API) specifying event type and field constraints. Alternatively, JWT claims auto-create subscriptions.
**Output:** Client receives only the events matching their subscriptions

### 3.5 End-to-End Event Flow

**User intent:** Backend emits an event and the right clients receive it
**Experience:** Backend publishes event to Kafka topic. RIG consumes it, matches against subscriptions, delivers to matching connected clients. Frontend receives the event in under 5ms.
**Output:** Real-time bidirectional communication working, no custom code needed

---

## 4. Information Architecture

| Entity | Description | Relationships |
|--------|-------------|---------------|
| **API Definition** | Route configuration (path, method, target, response mode) | Loaded by Proxy, managed via Management API |
| **Connection** | Persistent client connection (WS/SSE/long-poll) | Has Session, has Subscriptions |
| **Session** | Authenticated client identity derived from JWT | Bound to Connection, has Claims |
| **Subscription** | Event interest declaration with constraints | Owned by Session, evaluated by EventFilter |
| **Event** | CloudEvents-formatted message from broker | Consumed from Topic, matched against Subscriptions |
| **Topic** | Message broker channel (Kafka topic, NATS subject) | Produces Events, configured per broker |
| **Blacklist Entry** | Revoked JWT token hash | Distributed across nodes, checked at auth |

---

## 5. Key Interactions

### 5.1 Pseudo-Synchronous Request/Response

**Context:** Client needs a response from an async backend (e.g., request goes to Kafka, response comes back as an event).
**Flow:**
1. Client sends HTTP request to RIG
2. RIG publishes request to Kafka with a correlation ID
3. RIG creates a temporary subscription for the correlation ID
4. Backend processes request, publishes response event to Kafka
5. RIG matches response event, delivers to waiting client request
6. Client receives HTTP response (transparent — looks like sync to the client)

**Edge cases:**
- Backend doesn't respond within timeout → RIG returns 408 or configurable error
- Multiple response events for same correlation ID → first one wins, others discarded

### 5.2 Subscription with JWT Auto-Extraction

**Context:** Client connects with a JWT containing user identity claims.
**Flow:**
1. Client connects with JWT
2. RIG validates JWT, extracts configured claim fields (e.g., `sub`, `user_id`)
3. Auto-subscriptions created: client receives events where extracted fields match
4. Client can add additional explicit subscriptions

**Edge cases:**
- JWT expires during active connection → configurable behavior (disconnect or allow)
- Claims change on token refresh → subscriptions updated

---

## 6. Constraints & Trade-offs

| Trade-off | Chose | Over | Rationale |
|-----------|-------|------|-----------|
| Elixir/OTP | Keep existing stack | Rewrite in Go/Rust | Existing codebase is solid, OTP concurrency model is ideal for this use case, team has expertise |
| Umbrella app | Keep current structure | Single app | Separation of concerns is clear, refactoring risk outweighs benefits for v4 |
| CloudEvents | First-class support | Custom event format | Industry standard, interoperability with ecosystem |
| ETS for runtime state | Keep | External state store (Redis) | Lower latency, simpler ops, OTP-native; trade-off is single-node scope (solved by Erlang distribution) |
| Modernize incrementally | Yes | Big-bang rewrite | Lower risk, maintain backward compatibility, deliver value continuously |

---

## 7. Open Questions for Blueprint Phase

1. Which deprecated dependencies are most critical to replace first (Distillery, OpenCensus, Joken 1.x)?
2. How should the Kinesis integration evolve — keep JVM sidecar, replace with pure Erlang, or deprecate?
3. What's the target Elixir/OTP version, and what breaking changes does the upgrade introduce?
4. Should we add OpenAPI/AsyncAPI spec generation from route definitions?
5. How do we handle graceful connection draining during rolling deployments?

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Dependency upgrades introduce breaking changes | High | Medium | Incremental upgrade path, comprehensive test coverage first |
| Erlang/OTP version jump breaks NIFs or ports | Medium | High | Test Kinesis Java client bridge early, have fallback plan |
| Community engagement doesn't materialize | Medium | Low | Project is valuable regardless; internal team can sustain |
| Backward-incompatible API changes alienate existing users | Low | High | Strict semver, migration guides, v3 compatibility layer if needed |
| Performance regression during modernization | Medium | Medium | Establish baseline benchmarks before changes, run load tests in CI |

---

## Next Steps

1. ~~**Contrarian challenge session**~~ — N/A (existing project retrofit — Concept describes the system as it exists, not a speculative design)
2. **Solution Blueprint** — Done: [SOLUTION_BLUEPRINT.md](../architecture/SOLUTION_BLUEPRINT.md)
3. **Initial ADRs** — Outlined in Blueprint (ADR-001 through ADR-006); formal ADR files to be created in Sprint 1

---

_This is a living document. Update as understanding deepens._
