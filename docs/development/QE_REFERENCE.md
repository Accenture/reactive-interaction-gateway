# Quality Engineer — Reference Material

> Detailed sub-persona tool recommendations, extended test patterns, and full regression sprint protocol. Referenced by the QE agent file but kept separate to stay within the spawn truncation budget (10KB).

---

## Sub-Persona Tool Recommendations (Detailed)

### Performance QE Tools
- **Node/TypeScript:** autocannon, clinic.js, 0x flame graphs
- **Go:** pprof, benchstat, `go test -bench`
- **Frontend:** Lighthouse, Web Vitals, React Profiler
- **General:** k6, artillery

### SRE QE Tools
- **Go:** chaos testing patterns, fault injection in tests, `-race` flag
- **Node:** nock for dependency failure simulation, testcontainers
- **General:** timeout injection, connection drop simulation

### Security QE Tools
- **Node:** `npm audit`, snyk, eslint-plugin-security
- **Go:** `govulncheck`, gosec, staticcheck
- **General:** gitleaks, trufflehog, OWASP ZAP for APIs

### Resilience QE Tools
- **Go:** context cancellation testing, graceful shutdown verification
- **Node:** testcontainers for dependency simulation, AbortController testing
- **General:** network partition simulation, latency injection

### Data QE Tools
- **PostgreSQL:** pgTAP, migration test scripts, `pg_dump` diff
- **Node/Prisma:** migration dry-run, schema validation tests
- **Go/SQL:** sqlc compile checks, migration rollback tests
- **General:** data integrity assertion scripts, schema diff tools

### Visual QE Tools
- **React/Vue:** Storybook + Chromatic, Percy, Playwright visual comparisons
- **Mobile:** Maestro screenshots, platform-specific snapshot testing
- **TUI/CLI:** Golden file comparison for terminal output, Lip Gloss render assertions
- **General:** Axe-core for a11y, color contrast checkers, responsive viewport testing

---

## Extended Test Patterns — Integration, Resilience, Contract

Beyond unit tests, QE applies three additional test categories when the activation matrix triggers them. Full canonical patterns and code examples are in `docs/development/TESTING_PLAYBOOK.md` Sections 8.1-8.3.

### Integration Test Patterns

**When:** Any time 2+ modules interact, database access, message queue, external API calls.

**Sub-persona activation:** SRE QE (external deps), Data QE (database), Resilience QE (async/queue).

**Key principles:**
- Test the seam, not the internals — verify wiring and protocol, not business logic
- Use real dependencies where practical (testcontainers, in-memory DB) over mocks
- Each integration test independently runnable — no shared state
- Assert on behavior at the boundary (HTTP status, response shape, side effects)

### Resilience Test Patterns

**When:** External service integration, distributed communication, circuit breakers, retry logic, graceful shutdown.

**Sub-persona activation:** Resilience QE (primary), SRE QE (failure modes).

**Key principles:**
- Test each failure mode independently: timeout, connection refused, partial response, corrupt data
- Verify recovery behavior: system returns to healthy state after transient failure
- Test circuit breaker state transitions: closed -> open -> half-open -> closed
- Verify graceful shutdown: in-flight requests complete, connections drain, no data loss
- Test backpressure: what happens when downstream is slower than upstream

### Contract Test Patterns

**When:** Any shared API boundary, service consumed by multiple clients, public SDK/library API.

**Sub-persona activation:** Core QE (always), Security QE (if auth contracts).

**Key principles:**
- Consumer-driven: consumer defines the contract, provider verifies it
- Test request shape AND response shape
- Version contracts explicitly — breaking changes require version bump
- Schema validation tests catch drift between docs and behavior
- Backward compatibility: new fields additive, removed fields break consumers

---

## Bug Spiral Partnership — Full Protocol

### Severity Tiers

| Tier | Description | Protocol | CDR? |
|------|-------------|----------|------|
| **P0** | Production down, data loss, security vulnerability | Full: 5 Whys + Ishikawa + CDR | Mandatory |
| **P1** | Core feature broken, blocks sprint | Full: 5 Whys + Ishikawa + CDR | Mandatory |
| **P2** | Feature degraded, workaround exists | Quick: 5 Whys only | Optional |
| **P3** | Minor issue, edge case | Quick: 5 Whys only | Optional |
| **P4** | Trivial cosmetic | Fix directly, log finding | No |

### QE Responsibilities in Bug Spiral

1. **Technical context for 5 Whys:** evidence (code paths, test results, error logs) for each "why"
2. **Ishikawa participation (P0/P1):** contribute to Code, Data, Dependencies categories
3. **CDR authorship (P0/P1 mandatory):** write CDR documenting bug class recipe
4. **Prevention rule extraction:** each CDR becomes an enforceable QE checkpoint

### CDR Accumulation

CDRs accumulate in `docs/cdrs/CDR-QE-*.md`. Over time, these form institutional memory of bug classes — detection patterns, fix recipes, prevention rules.

---

## Regression Sprint — Full Process

**Trigger:** E2E pass rate drops below 80%, significant refactor, or before release candidate.

**Mandatory Process:**
1. Run baseline — record total tests, passed, failed, skipped
2. Categorize failures using parallel agents: Selector drift | API mock gap | Race condition | Real bug | Baseline drift | Env issue
3. Document Pass 1 findings in `docs/planning/retrospectives/REGRESSION-SPRINT-{N}-PASS1.md`
4. Fix in priority order: P0 systemic -> P1 auth/API -> P2 env/config -> P3 visual baselines (LAST)
5. Agent separation mandatory — QE writes fixes, Architect verifies against source
6. Andon principle — stop the line, diagnose root cause before retrying
7. Verify after each pass — run full suite, document delta
8. Update baselines ONLY after all functional fixes stable
9. Write final retro

See `docs/development/REGRESSION_SPRINT_PLAYBOOK.md` for full process.
