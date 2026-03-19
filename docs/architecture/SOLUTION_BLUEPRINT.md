# Solution Blueprint — Reactive Interaction Gateway (RIG)

**Version:** 0.1.0
**Author:** Architect persona
**Status:** Draft

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Context](#2-system-context)
3. [Architecture Overview](#3-architecture-overview)
4. [Service Architecture](#4-service-architecture)
5. [Data Architecture](#5-data-architecture)
6. [API Contracts](#6-api-contracts)
7. [Event Architecture](#7-event-architecture)
8. [Security Architecture](#8-security-architecture)
9. [Observability Architecture](#9-observability-architecture)
10. [Deployment Architecture](#10-deployment-architecture)
11. [Quality Architecture](#11-quality-architecture)
12. [SRE Tooling](#12-sre-tooling)

---

## 1. Executive Summary

### Purpose

RIG is a bidirectional event-driven API gateway that routes client HTTP requests to backend microservices and pushes backend events to connected frontend clients. It targets platform engineers, backend developers, and DevOps teams building event-driven architectures on Kafka, NATS, or AWS Kinesis.

### Key Constraints

| Constraint | Description | Impact |
| --- | --- | --- |
| Elixir/OTP ecosystem | Must remain on BEAM VM; leverage OTP supervision, distribution, and concurrency | All architectural decisions must work within OTP idioms; no sidecar process model (except legacy Kinesis) |
| Backward compatibility | Existing v3 API contracts and configuration must continue to work | New features added alongside existing API versions; deprecation with migration path |
| Open-source sustainability | Accenture-sponsored OSS with limited contributor bandwidth | Minimize operational complexity; prefer batteries-included over plugin architecture |

### Success Metrics

| Metric | Target | Measurement |
| --- | --- | --- |
| Event routing latency (p99) | <5ms at 10k concurrent connections | Artillery load tests against staging |
| Connection capacity per node | 50k+ concurrent WebSocket connections | Load test with connection-only clients |
| Test coverage | >85% line coverage | ExCoveralls in CI |
| Startup time | <5s to healthy | Health check timing in integration tests |
| Zero-downtime deploy | 0 dropped connections during rolling update | K8s rolling update integration test |

---

## 2. System Context

### Actors

| Actor | Description | Primary Interactions |
| --- | --- | --- |
| Frontend Client | Browser, mobile app, or IoT device | Opens WS/SSE connection, sends HTTP requests, subscribes to events |
| Backend Service | Microservice producing events and handling requests | Receives proxied requests from RIG, publishes events to message brokers |
| Platform Engineer | Sets up and configures RIG | Uses management API, configures env vars, deploys via K8s/Helm |
| DevOps/SRE | Operates RIG in production | Monitors metrics, traces, logs; manages deployments |

### External Systems

| System | Purpose | Integration Type |
| --- | --- | --- |
| Apache Kafka | Primary event stream / message broker | Consumer (Brod) + Producer |
| NATS | Lightweight messaging alternative | Subscriber (Gnat) + Publisher |
| AWS Kinesis | AWS-native event streaming | Consumer (ex_aws + Java KCL sidecar) |
| Confluent Schema Registry | Avro schema management for Kafka | HTTP REST client (Schema validation) |
| Jaeger / Zipkin | Distributed tracing backends | OpenCensus/OpenTelemetry exporter |
| Prometheus | Metrics collection | HTTP scrape endpoint (/metrics) |

### System Context Diagram

```
[Frontend Clients] --WS/SSE/HTTP--> [RIG Gateway] --HTTP--> [Backend Services]
       ^                                 |   |
       |                                 |   +--Kafka/NATS/Kinesis--> [Message Brokers]
       |                                 |                                    |
       +---------- events ---------------+                                    |
                                         |<---------- events -----------------+
                                         |
                                    [Prometheus] [Jaeger]
```

---

## 3. Architecture Overview

### Architecture Style

**Event-driven modular monolith** (Elixir umbrella application). Multiple OTP applications in a single BEAM VM, communicating via in-process message passing and Phoenix.PubSub. External communication via HTTP and message broker protocols.

This is NOT a microservice — it is a single deployable unit with internal modularity. The umbrella structure provides compile-time boundaries between concerns without the operational overhead of separate services.

### Technology Stack

| Layer | Technology | Rationale |
| --- | --- | --- |
| **Language** | Elixir 1.17+ (Erlang/OTP 27) | Current stable; pattern matching improvements, better error messages, type system progress |
| **Framework** | Phoenix 1.7 (target upgrade) | LiveDashboard improvements, verified routes, Bandit HTTP server option |
| **HTTP Server** | Bandit (target) / Cowboy (current) | Bandit is pure-Elixir, better telemetry integration; Cowboy as fallback |
| **Message Brokers** | Brod (Kafka), Gnat (NATS), ex_aws (Kinesis) | Existing, proven integrations |
| **Serialization** | Jason (JSON), erlavro (Avro) | Standard choices, well-maintained |
| **Auth** | Joken 2.x (target upgrade from 1.x) | Modern JWT, JOSE-based, configurable strategies |
| **Tracing** | OpenTelemetry (target, replacing OpenCensus) | OpenCensus is EOL; OpenTelemetry is the successor |
| **Metrics** | Prometheus (via telemetry_metrics_prometheus) | Existing, standard |
| **Release** | mix release (replacing Distillery) | Built-in since Elixir 1.9; Distillery is deprecated |

### C4 Container Diagram

```
[Frontend SPA/Mobile]
        |
        | WS / SSE / HTTP
        v
+--[RIG BEAM VM]------------------------------------------+
|                                                          |
|  [Inbound Gateway Web]  <-- Phoenix Endpoints            |
|       |                                                  |
|       v                                                  |
|  [Inbound Gateway]  -- API Proxy (route matching)        |
|       |                                                  |
|       +-- sync HTTP --> [Backend Services]               |
|       +-- async ------> [Kafka/NATS Producer]            |
|                                                          |
|  [Outbound Gateway]  -- Event Stream Consumers           |
|       |                                                  |
|       +-- Kafka Consumer (Brod)                          |
|       +-- NATS Subscriber (Gnat)                         |
|       +-- Kinesis Consumer (ex_aws)                      |
|       |                                                  |
|       v                                                  |
|  [Event Filter]  -- Subscription Matching Engine         |
|       |                                                  |
|       v                                                  |
|  [Connection Manager]  -- WS/SSE/Long-poll Sessions      |
|       |                                                  |
|       v                                                  |
|  [Client Connections]  --> Push events to clients         |
|                                                          |
|  [Management API]  -- Runtime configuration (v2/v3)      |
|  [Metrics/Tracing]  -- Prometheus + OpenTelemetry        |
+----------------------------------------------------------+
```

### Key Architecture Decisions

| ADR | Decision | Rationale |
| --- | --- | --- |
| ADR-001 | Upgrade to Elixir 1.17+ / OTP 27 | Current Elixir 1.11 is 5 years old; need security patches, performance improvements, ecosystem compatibility |
| ADR-002 | Replace Distillery with mix release | Distillery is deprecated; mix release is built-in, simpler, and actively maintained |
| ADR-003 | Migrate from OpenCensus to OpenTelemetry | OpenCensus is end-of-life; OpenTelemetry is the merged successor standard |
| ADR-004 | Upgrade Joken 1.x to Joken 2.x | Joken 1.x is unmaintained; 2.x has better JOSE support and configurable strategies |
| ADR-005 | Keep umbrella application structure | Provides good module boundaries without operational complexity of separate deployments |
| ADR-006 | Target Bandit as HTTP server option | Pure-Elixir HTTP server with better Telemetry integration; keep Cowboy as proven fallback |

---

## 4. Service Architecture

### OTP Application Inventory

| Application | Responsibility | Key Modules | Supervision |
| --- | --- | --- | --- |
| `rig` | Core framework: subscriptions, event filter, JWT, sessions | `EventFilter`, `Subscription`, `JWT`, `Session`, `DistributedSet` | Root supervisor with per-concern children |
| `rig_inbound_gateway` | Client-to-backend request routing | `Proxy`, `ApiProxy.Handler.{Http,Kafka,Kinesis,Nats}` | Proxy worker pool |
| `rig_inbound_gateway_web` | Phoenix HTTP endpoints (client-facing) | `Endpoint`, `Router`, controllers | Phoenix endpoint supervisor |
| `rig_outbound_gateway` | Backend-to-client event forwarding | Stream consumers, `KinesisToFilter` | Per-broker consumer supervisors |
| `rig_api` | Management API (internal) | v2/v3 controllers | Separate endpoint supervisor |
| `rig_kafka` | Kafka consumer/producer | Brod-based consumers/producers | Brod supervisor tree |
| `rig_metrics` | Prometheus metrics | `PrometheusExporter`, telemetry handlers | Telemetry attachment at startup |
| `rig_cloud_events` | CloudEvents parsing/validation | `Parser.{PartialV0, V0, V04, V1}` | Stateless (no supervision needed) |

### Module Architecture

#### Core (`rig`)

**Responsibility:** Event routing engine, subscription management, authentication primitives

```
lib/rig/
├── application.ex          # OTP application entry point
├── event_filter.ex         # Central event matching engine
├── event_filter/           # Filter internals (sup, server, match)
├── subscription.ex         # Subscription data model
├── subscriptions/          # Subscription management
├── connection/             # WS/SSE connection handling
├── session/                # Session lifecycle
├── jwt.ex                  # JWT validation & claim extraction
├── authorization_check/    # Auth middleware
├── distributed_set.ex      # Distributed ETS for blacklist
├── event_stream/           # Stream-to-filter adapters
├── sources/                # HTTP event source
├── tracing/                # Distributed tracing context
└── plug/                   # HTTP middleware components
```

#### Inbound Gateway (`rig_inbound_gateway`)

**Responsibility:** API proxy — routes client requests to backend services

```
lib/rig_inbound_gateway/
├── proxy.ex                # Route definition management
├── events.ex               # Event publishing from HTTP
├── api_proxy/
│   ├── handler/
│   │   ├── http.ex         # Sync HTTP proxy handler
│   │   ├── kafka.ex        # Async Kafka handler
│   │   ├── kinesis.ex      # Async Kinesis handler
│   │   └── nats.ex         # Async NATS handler
│   ├── auth/               # Per-request auth handlers
│   └── presence_handler.ex # Distributed state
└── request_logger/         # Request logging to streams
```

---

## 5. Data Architecture

### Data Stores

| Store | Technology | Purpose | Data Types |
| --- | --- | --- | --- |
| ETS (Connection State) | Erlang Term Storage | Active connections, sessions, subscriptions | In-memory, per-node, process-owned |
| ETS (Blacklist) | Distributed ETS | Revoked JWT token hashes | Replicated across cluster nodes |
| ETS (API Definitions) | Erlang Term Storage | Route configurations | Loaded from config or management API |
| ETS (Memoize Cache) | Erlang Term Storage | Cached computation results | TTL-based expiry |

### Data Models

**Core entities and their lifecycle:**

```
API Definition (persistent config)
  └── loaded at startup or via management API
  └── defines: path, method, target, response_mode, auth_type

Connection (ephemeral, per-client)
  ├── transport: :websocket | :sse | :longpoll
  ├── session: Session
  └── subscriptions: [Subscription]

Session (ephemeral, JWT-bound)
  ├── jwt_claims: map
  ├── connected_at: datetime
  └── node: atom (which BEAM node)

Subscription (ephemeral, per-connection)
  ├── event_type: string
  └── constraints: [[{field_path, op, value}]]  # CNF

Event (transient, from broker)
  ├── cloud_events envelope
  ├── data: map
  └── matched via EventFilter against Subscriptions
```

### Data Flow

```
[Message Broker] --consume--> [Stream Consumer] --parse--> [CloudEvents Parser]
     --route--> [EventFilter] --match--> [Subscription Match]
     --deliver--> [Connection] --push--> [Client]
```

---

## 6. API Contracts

### Client-Facing Endpoints (Inbound Gateway Web)

| Method | Path | Purpose | Auth |
| --- | --- | --- | --- |
| GET | /_rig/v1/connection/sse | SSE event stream connection | JWT (configurable) |
| GET | /_rig/v1/connection/ws | WebSocket upgrade | JWT (configurable) |
| POST | /_rig/v1/connection/longpolling | Long-polling connection | JWT (configurable) |
| POST | /_rig/v1/events | Publish event via HTTP | JWT |
| * | /\* (proxy routes) | Proxied to backend per API definitions | Per-route config |

### Management API

| Method | Path | Purpose | Auth |
| --- | --- | --- | --- |
| GET | /v3/apis | List API definitions | Internal |
| POST | /v3/apis | Create API definition | Internal |
| PUT | /v3/apis/:id | Update API definition | Internal |
| DELETE | /v3/apis/:id | Delete API definition | Internal |
| GET | /v3/sessions | List active sessions | Internal |
| DELETE | /v3/session-blacklist/:jti | Blacklist a JWT | Internal |
| GET | /v3/subscriptions | List subscriptions | Internal |

### Health & Metrics

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /health | Liveness probe |
| GET | /metrics | Prometheus metrics |
| GET | /dashboard | Phoenix LiveDashboard (dev/staging) |

---

## 7. Event Architecture

### Event Format

RIG uses **CloudEvents v1.0** as the standard event envelope:

```json
{
  "specversion": "1.0",
  "type": "com.example.order.completed",
  "source": "/orders-service",
  "id": "unique-event-id",
  "time": "2026-03-18T12:00:00Z",
  "datacontenttype": "application/json",
  "data": {
    "order_id": "ORD-123",
    "customer_id": "CUST-456",
    "total": 99.99
  }
}
```

### Event Sources (Consumers)

| Source | Consumer Library | Configuration | Deserialization |
| --- | --- | --- | --- |
| Kafka | Brod ~3.9 | Topics, consumer group, partition strategy | JSON or Avro (Schema Registry) |
| NATS | Gnat ~1.0 | Subjects, queue groups | JSON |
| Kinesis | ex_aws + KCL | Streams, shard iterator | JSON |
| HTTP | Phoenix endpoint | POST /_rig/v1/events | JSON (CloudEvents) |

### Event Routing Pipeline

```
Source Consumer
    ↓
CloudEvents Parser (normalize to v1.0)
    ↓
EventFilter (match against all active subscriptions)
    ↓ (fan-out to matching connections)
Connection Delivery (WS frame / SSE data / long-poll response)
```

---

## 8. Security Architecture

### Authentication

- **JWT validation** on connection establishment and (optionally) per-request
- Supports RS256, HS256, and configurable algorithms via Joken
- JWT secret/key configurable via environment variables
- Token claims extracted for auto-subscription creation

### Authorization

- **Per-route auth configuration** — each API definition specifies auth requirements
- **Token blacklisting** — distributed ETS set, replicated across cluster nodes
- Blacklist entries added via management API, effective immediately cluster-wide

### Data Protection

- HTTPS/TLS termination (typically at load balancer, configurable in RIG)
- No PII stored at rest — RIG is a pass-through; events and requests are transient
- JWT secrets managed via environment variables (not committed to config)
- Structured logging scrubs sensitive headers

### Security Checklist

- [x] JWT authentication on connection endpoints
- [x] Configurable auth per API route
- [x] Token blacklisting for session revocation
- [x] CORS configurable per deployment
- [x] Rate limiting on connection endpoints (ExRated)
- [ ] Security headers audit (CSP, HSTS) — v4 hardening
- [ ] JWT key rotation support — v4 enhancement
- [ ] mTLS for inter-node communication — evaluate

---

## 9. Observability Architecture

### Three Pillars

| Pillar | Current | Target (v4) | Purpose |
| --- | --- | --- | --- |
| **Metrics** | Prometheus (prometheus_ex) | Prometheus (telemetry_metrics_prometheus) | Connection counts, event throughput, proxy latency |
| **Tracing** | OpenCensus (Jaeger/Zipkin) | OpenTelemetry (opentelemetry_api + exporters) | Request/event flow across RIG and backends |
| **Logging** | LoggerJSON (JSON/GCL formats) | LoggerJSON + correlation IDs | Structured logs with trace correlation |

### Key Metrics

| Metric | Type | Labels | Purpose |
| --- | --- | --- | --- |
| `rig_connections_active` | Gauge | transport, node | Current connected clients |
| `rig_events_received_total` | Counter | source, event_type | Events consumed from brokers |
| `rig_events_delivered_total` | Counter | transport, event_type | Events pushed to clients |
| `rig_proxy_request_duration` | Histogram | method, path, status | Inbound proxy latency |
| `rig_subscriptions_active` | Gauge | — | Current active subscriptions |
| `rig_blacklist_size` | Gauge | — | Blacklisted token count |

### Dashboards

| Dashboard | Purpose | Key Panels |
| --- | --- | --- |
| RIG Overview | Operational health | Connections, event rate, error rate, latency histograms |
| Event Pipeline | Event flow monitoring | Per-source throughput, filter match rate, delivery latency |
| Proxy Performance | Request routing | Request rate, latency percentiles, upstream error rates |

---

## 10. Deployment Architecture

### Environments

| Environment | Purpose | Infrastructure |
| --- | --- | --- |
| Local | Development | `iex -S mix phx.server` or Docker Compose |
| Test | CI pipeline | Docker Compose (Kafka + NATS + RIG) |
| Staging | Pre-production | Kubernetes (Helm v3) |
| Production | Live | Kubernetes (Helm v3) + load balancer |

### Infrastructure Diagram

```
[Load Balancer (L7 — WebSocket aware)]
    |
    +-- [RIG Pod 1] --+
    |                  |-- [Erlang Distribution] -- cluster formation
    +-- [RIG Pod 2] --+
    |                  |
    +-- [RIG Pod N] --+
                       |
                  [Kafka Cluster]
                  [NATS Cluster]
                  [Prometheus]
                  [Jaeger Collector]
```

### Health Checks

| Probe | Endpoint | Expected | Timeout |
| --- | --- | --- | --- |
| Liveness | /health | 200 OK | 5s |
| Readiness | /health | 200 OK (+ broker connectivity) | 10s |
| Startup | /health | 200 OK | 30s |

### Helm Chart Structure

```
deployment/helm/reactive-interaction-gateway/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── hpa.yaml
│   └── ingress.yaml
```

---

## 11. Quality Architecture

### Test Pyramid

| Layer | Purpose | Target Coverage | Framework |
| --- | --- | --- | --- |
| Unit | Module logic, pure functions | 90%+ | ExUnit |
| Property | Invariant verification | Critical paths (EventFilter, subscriptions) | StreamData |
| Integration | OTP application interactions | All inter-app boundaries | ExUnit + Mox |
| System | Full deployment smoke test | Golden paths | Docker Compose + HTTP assertions |
| Load | Performance under stress | p99 latency, connection limits | Artillery |

### Quality Gates

- All ExUnit tests pass
- Dialyzer type check clean (zero warnings)
- Credo static analysis clean
- ExCoveralls coverage thresholds met (>85%)
- No compiler warnings (`--warnings-as-errors`)
- Docker image builds successfully

### QE Handoff

| Field | Value |
| --- | --- |
| Project Type | Library/Framework (event-driven infrastructure) |
| Primary Language | Elixir |
| Test Framework | ExUnit + Mox + StreamData |
| Key Risk Areas | Event routing correctness (subscription matching), connection lifecycle (WS/SSE state), JWT validation edge cases, distributed state (blacklist, cluster), message broker integration reliability |

---

## 12. SRE Tooling

### Observability

- **Tracing:** OpenTelemetry (target) — replacing OpenCensus. Exporters for Jaeger and Zipkin. W3C Trace Context propagation across HTTP and message broker boundaries.
- **Metrics:** Prometheus via telemetry_metrics_prometheus. Custom metrics for connections, events, proxy operations, subscriptions.
- **Logging:** Structured JSON logging via LoggerJSON. Google Cloud Logger format support. Correlation IDs from trace context.

### Test Infrastructure

- **Test harness:** ExUnit + Mox for behavior mocking + StreamData for property-based testing
- **Integration test environment:** Docker Compose with Kafka, NATS, and RIG. Existing `integration_tests/` directory with separate mix project.
- **Load/stress testing:** Artillery (existing `performance_tests/` directory). Targets: 10k concurrent WS connections, event throughput saturation.

### Debugging & Introspection

- **Local debugging:** IEx shell with `iex -S mix` — full BEAM introspection (`:observer`, `:recon`, process inspection)
- **Production debugging:** `:recon` and `:observer_cli` for runtime BEAM analysis. Phoenix LiveDashboard for web-based introspection. Structured log queries with trace correlation.
- **Profiling:** `:fprof` and `:eprof` for Erlang profiling. `:recon_trace` for production-safe tracing.

---

## Appendix

### Glossary

| Term | Definition |
| --- | --- |
| CloudEvents | CNCF specification for describing event data in a common way |
| EventFilter | RIG's core subscription matching engine |
| CNF | Conjunctive Normal Form — how subscription constraints are composed |
| JSON Pointer | RFC 6901 — notation for identifying specific values in JSON |
| Pseudo-synchronous | Pattern where async request/response is made transparent to the client |
| Distributed Set | ETS table replicated across Erlang cluster nodes for blacklist |

### References

| Document | Purpose |
| --- | --- |
| `docs/architecture.md` | Original architecture documentation |
| `docs/event-subscription.md` | Event subscription deep-dive |
| `docs/api-gateway.md` | API gateway patterns |
| `docs/distributed-tracing.md` | Tracing implementation guide |
| `docs/scaling.md` | Scaling considerations |
| CloudEvents Spec v1.0 | https://cloudevents.io |

---

_Blueprint Version: 0.1.0 | Last Updated: 2026-03-18_
