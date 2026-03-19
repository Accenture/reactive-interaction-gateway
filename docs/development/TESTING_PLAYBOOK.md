# Testing Playbook

**Owner:** QE Agent
**Status:** Initial (v2.0 workflow upgrade) — living document, updated each sprint

---

## Purpose

This playbook defines the testing contract for the project. It specifies what tests are expected for each type of work, provides canonical patterns, and establishes the QE feedback loop that keeps coverage evolving with the codebase.

---

## 1. Coverage Contract

Every work item must ship with tests appropriate to its type. The QE agent enforces this at sprint close.

### 1.1 By Work Item Type

| Work Item Type | Required Tests | Framework | Example |
|---|---|---|---|
| **New NestJS service** | Unit tests for public API + error paths + edge cases | Jest | `calculator.service.spec.ts` |
| **New controller** | Controller endpoint tests (auth, validation, responses) | Jest | `my.controller.spec.ts` |
| **New pure engine** | Unit tests for all exported functions + boundary cases | Jest | `my.engine.spec.ts` |
| **New page component** | Page render + key interactions + skeleton state | Vitest | `MyPage.test.tsx` |
| **New component (with logic)** | Component test: render, interaction, state | Vitest | `MyChart.test.tsx` |
| **New React component (pure display)** | Add to skip registry with justification | — | — |
| **New Go function** | Table-driven tests with boundary cases | Go testing | `engine_test.go` |
| **New chat tool** | Integration test via chat service mock | Jest | `chat.integration.spec.ts` |
| **New Prisma model** | Migration test (migrate + generate), service CRUD test | Jest | — |
| **New shared type** | Build verification (`pnpm --filter @{project}/shared build`) | — | — |
| **Bug fix** | Regression test proving the fix (test should fail without fix) | Varies | — |
| **New E2E user journey** | Playwright test + happy path | Playwright | `scenario-flow.spec.ts` |

### 1.2 What Does NOT Need a Test

- Thin UI wrappers with zero custom logic (e.g., a Card that just passes props to shadcn)
- Icon components and static SVG wrappers
- Type definitions and constants files
- CSS-only / Tailwind-only changes
- Prisma schema changes alone (migration is the test)
- NestJS module registration files (`*.module.ts`) with no custom logic

### 1.3 Minimum Bar

A sprint cannot close with:
- A new service that has zero tests
- A new controller with no endpoint tests
- A new component with branching logic that has zero tests
- A new chat tool with no integration test
- A new Go function with no table-driven test
- A regression fix with no regression test

---

## 1b. Test Pyramids by Project Type

After Blueprint locks the tech stack and commits a **Project Type** field, QE selects the matching pyramid below. Ratios are guidelines — adjust based on project-specific risk profile.

| Project Type | Unit : Integration : E2E | Focus | Coverage Target |
|-------------|--------------------------|-------|-----------------|
| CLI tool (Go/Rust/Python) | 70:25:5 | Table-driven units, cmd integration | 80%+ unit, 60%+ cmd |
| Web API (Node/Go/Python) | 60:30:10 | Service units, route integration, contract | 80%+ service, 70%+ route |
| SPA frontend (React/Vue) | 50:30:20 | Component tests, interaction, E2E journeys | 70%+ component |
| Full-stack (Next.js/SvelteKit) | 40:35:25 | All layers, API integration, E2E | 70%+ per layer |
| Library/SDK | 85:15:0 | Exhaustive unit, public API integration | 90%+ unit |
| Mobile (RN/Flutter) | 50:30:20 | Widget tests, integration, device E2E | 70%+ widget |
| Foundational component/Envoy | 30:50:20 | Integration + resilience heavy | 60%+ integration |

### Foundational Component — Infrastructure Causality Chain

For foundational components (proxies, gateways, message brokers, sidecars), test each failure scenario:

- [ ] **Circuit breaker** — Opens under sustained failure, half-opens correctly, closes on recovery
- [ ] **Node failure** — Handles peer unavailability gracefully
- [ ] **Backpressure** — Signals capacity limits to upstream, doesn't crash under overload
- [ ] **Load behavior** — Degrades gracefully (not cliff-edge) under 2x-10x expected load
- [ ] **Graceful shutdown** — In-flight requests complete, connections drain, state persists
- [ ] **Hot-reload** — Config changes apply without restart, no request drops
- [ ] **Connection pool exhaustion** — Recovers when pool exhausted, doesn't leak connections
- [ ] **Partition tolerance** — Handles network partitions per design intent

### Visual Testing Layer (UI-Facing Projects)

For projects with a user interface (SPA, Full-Stack, Mobile, TUI), Visual QE adds a cross-cutting test layer alongside the pyramid:

| Visual Test Type | Purpose | When |
|-----------------|---------|------|
| Screenshot regression | Catch unintended visual changes | Every UI component change |
| Component state matrix | Verify all visual states render correctly (loading, empty, error, overflow, truncation) | New component, component redesign |
| Design token compliance | Colors, spacing, typography match design system | Theme changes, new components |
| Responsive breakpoints | Layout correct at each defined breakpoint | Layout work, new pages |
| Accessibility visual | Contrast ratios, focus indicators, touch targets, motion preferences | Every UI component |

Visual testing is not a replacement for functional testing — it runs alongside it. Visual QE sub-persona owns this layer; CX Designer provides the design criteria that Visual QE tests against.

### Blueprint-to-QE Handoff

Blueprint MUST include a QE Handoff section:

```markdown
## QE Handoff

**Project Type:** {CLI | Web API | SPA | Full-Stack | Library | Mobile | Foundational Component}
**Primary Language:** {language}
**Test Framework:** {framework}
**Key Risk Areas:** {areas where testing effort should concentrate}
```

QE uses this to select the pyramid, activate relevant sub-personas, and set coverage targets.

---

## 2. Test Patterns Catalog

### 2.1 NestJS Service Test (Jest)

```typescript
import { Test } from '@nestjs/testing';
import { MyService } from './my.service';
import { PrismaService } from '../shared/prisma.service';

describe('MyService', () => {
  let service: MyService;
  let prisma: jest.Mocked<PrismaService>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        MyService,
        {
          provide: PrismaService,
          useValue: {
            myModel: {
              findMany: jest.fn(),
              create: jest.fn(),
            },
          },
        },
      ],
    }).compile();

    service = module.get(MyService);
    prisma = module.get(PrismaService);
  });

  it('does the thing', async () => {
    prisma.myModel.findMany.mockResolvedValue([/* ... */]);
    const result = await service.doThing();
    expect(result).toEqual(/* ... */);
  });
});
```

**Note:** For services with `@Optional()` dependencies, prefer manual construction (`new MyService(mock1, mock2)`) over NestJS test module to avoid silent `null` injection.

### 2.2 Pure Engine Test (Jest)

```typescript
import Decimal from 'decimal.js';
import { myPureFunction } from './my.engine';

describe('myPureFunction', () => {
  it.each([
    { input: new Decimal('100'), expected: new Decimal('110') },
    { input: new Decimal('0'), expected: new Decimal('0') },
    { input: new Decimal('-50'), expected: new Decimal('-55') },
  ])('computes correctly for $input', ({ input, expected }) => {
    expect(myPureFunction(input).toNumber()).toBeCloseTo(expected.toNumber());
  });
});
```

### 2.3 React Component Test (Vitest)

```typescript
import { renderWithProviders } from '@/test/render-with-providers';
import { screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { MyComponent } from '../MyComponent';

// Mock matchMedia for chart components
Object.defineProperty(window, 'matchMedia', {
  value: vi.fn().mockImplementation((query) => ({
    matches: false, media: query,
    addEventListener: vi.fn(), removeEventListener: vi.fn(),
  })),
});

describe('MyComponent', () => {
  it('renders with props', () => {
    renderWithProviders(<MyComponent data={mockData} />);
    expect(screen.getByText('Expected Text')).toBeInTheDocument();
  });
});
```

**Utilities:** Use `apps/web/src/test/render-with-providers.tsx` (renderWithProviders + renderWithRoute) and `apps/web/src/test/mock-recharts.tsx` (shared Recharts mock).

### 2.4 Go Table-Driven Test

```go
func TestMyFunction(t *testing.T) {
    tests := []struct {
        name     string
        input    decimal.Decimal
        expected decimal.Decimal
    }{
        {"positive", decimal.NewFromFloat(100), decimal.NewFromFloat(110)},
        {"zero", decimal.NewFromFloat(0), decimal.NewFromFloat(0)},
        {"negative", decimal.NewFromFloat(-50), decimal.NewFromFloat(-55)},
    }

    for i := range tests {
        t.Run(tests[i].name, func(t *testing.T) {
            result := MyFunction(tests[i].input)
            if !result.Equal(tests[i].expected) {
                t.Errorf("got %s, want %s", result, tests[i].expected)
            }
        })
    }
}
```

**Note:** Use `for i := range` with `tests[i]` to avoid gocritic rangeValCopy on large structs.

### 2.5 Playwright E2E Test

```typescript
import { test, expect } from '@playwright/test';

test.describe('Scenario Flow', () => {
  test('user can create and view a scenario', async ({ page }) => {
    await page.goto('/scenarios');
    await expect(page.getByText('Scenarios')).toBeVisible();
    // ... interact and assert
  });
});
```

---

## 3. QE Agent Protocol

### 3.1 Sprint Close Audit (Mandatory)

After all code is committed for a sprint, the QE agent runs a **coverage audit**:

1. **Scan** — identify all new/modified source files in the sprint diff
2. **Classify** — map each file to a work item type (service, controller, engine, component, etc.)
3. **Check** — verify the Coverage Contract (Section 1) is satisfied for each file
4. **Report** — produce a gap list with severity and suggested remediation

If gaps exist:
- P0 gaps are sprint-blocking (must fix before close)
- P1 gaps are carryforward items in DELIVERY_PLAN.md

### 3.2 Retro Feedback Loop

When a bug is found:

1. **Trace** — which module/component? Was there a test that should have caught it?
2. **Diagnose** — is this a gap in the Coverage Contract, or was the contract correct but not enforced?
3. **Update** — if the contract is missing a case, update Section 1 to prevent recurrence
4. **Remediate** — add the missing test to the current sprint or next sprint's backlog
5. **Log** — record the incident in the retro as a "coverage miss" with root cause

### 3.3 In-Sprint Advisory

During active development, the QE agent:
- Reviews new services/components for testability (flag if hard to test = probably hard to maintain)
- Suggests test-friendly patterns (pure function extraction, DI, `@Optional()` handling)
- Identifies when a "pure display" component has grown logic and should be promoted from the skip registry

---

## 4. Skip Registry

Components explicitly not tested, with justification. Reviewed each sprint — if a component gains logic, QE flags for promotion.

| Component | Module | Justification | Last Reviewed |
|---|---|---|---|
| _Empty — populate during first audit_ | | | |

---

## 5. CI Integration

| Test Layer | CI Job | Local Command | Behavior |
|---|---|---|---|
| API (Jest) | `api-test` | `pnpm --filter @{project}/api test` | Must pass |
| Web (Vitest) | `web-test` | `pnpm --filter @{project}/web test` | Must pass |
| Shared (Vitest) | `web-test` | `pnpm --filter @{project}/shared test` | Must pass |
| Go | `go` | `cd apps/engine && go test ./...` | Must pass |
| E2E (Playwright) | `e2e` | `pnpm e2e` | continue-on-error |
| Typecheck | `lint-typecheck` | `make typecheck` | Must pass (CI Node 22; local Node 24 may crash) |
| Lint | `lint-typecheck` | `make lint` | Must pass |

---

## 6. Test Data Conventions

- **Decimal precision:** Use `decimal.js` / `shopspring/decimal` for all financial values. Never use floating-point arithmetic in tests for cost comparisons.
- **UUIDs:** Use deterministic UUIDs in factories (e.g., `'test-scenario-001'`)
- **Timestamps:** Use fixed dates, not `Date.now()`
- **Cost values:** Use realistic domain data relevant to your project
- **Mock patterns:** `jest.mockResolvedValue` (not `mockResolvedValueOnce`) for parallel-executed code paths

---

## 7. Known Gotchas

- **`@Optional()` DI in tests:** NestJS `@Optional()` + `Test.createTestingModule` can silently inject `null`. Prefer manual construction for optional deps.
- **AI SDK mocking:** v6 uses `stopWhen: stepCountIs(n)` — mock `stepCountIs` in all test files that mock `'ai'`.
- **Vitest OOM:** react-router 7 `Navigate` creates persistent state. Mock `Navigate` to `<div>` stub in test.
- **matchMedia:** Any test rendering Recharts charts needs `Object.defineProperty(window, 'matchMedia', ...)` mock.
- **`npx jest` fails in monorepo apps:** Always use `pnpm --filter @{project}/api test` — direct jest invocation may hit Babel parse errors.

---

## 8. Extended Test Patterns — Integration, Resilience, Contract

These patterns extend the test pyramid with specialized test categories. QE sub-personas activate these based on the activation matrix in `qe.md`.

### 8.1 Integration Test Patterns

Integration tests verify that modules work together correctly at their boundaries. They test wiring, protocols, and data flow — not business logic (that's unit tests).

**NestJS Service Integration (Jest + real module wiring):**

```typescript
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../app.module';

describe('UserController (integration)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule], // real module graph, not mocked
    }).compile();
    app = module.createNestApplication();
    await app.init();
  });

  afterAll(() => app.close());

  it('POST /users creates user and returns 201', async () => {
    const res = await request(app.getHttpServer())
      .post('/users')
      .send({ name: 'Ada Lovelace', email: 'ada@example.com' })
      .expect(201);

    expect(res.body).toMatchObject({
      id: expect.any(String),
      name: 'Ada Lovelace',
    });
  });
});
```

**Go Integration with testcontainers:**

```go
func TestUserRepository_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    ctx := context.Background()
    pgContainer, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
    )
    require.NoError(t, err)
    defer pgContainer.Terminate(ctx)

    connStr, _ := pgContainer.ConnectionString(ctx)
    repo, _ := NewUserRepository(connStr)

    user, err := repo.Create(ctx, "Ada Lovelace", "ada@example.com")
    require.NoError(t, err)
    assert.Equal(t, "Ada Lovelace", user.Name)

    found, err := repo.FindByID(ctx, user.ID)
    require.NoError(t, err)
    assert.Equal(t, user.ID, found.ID)
}
```

**React Integration with MSW (Mock Service Worker):**

```typescript
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';
import { render, screen, waitFor } from '@testing-library/react';
import { UserList } from './UserList';

const server = setupServer(
  http.get('/api/users', () =>
    HttpResponse.json([{ id: '1', name: 'Ada Lovelace' }])
  )
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('renders users from API', async () => {
  render(<UserList />);
  await waitFor(() => {
    expect(screen.getByText('Ada Lovelace')).toBeInTheDocument();
  });
});

test('renders error state when API fails', async () => {
  server.use(http.get('/api/users', () => HttpResponse.error()));
  render(<UserList />);
  await waitFor(() => {
    expect(screen.getByText(/error/i)).toBeInTheDocument();
  });
});
```

### 8.2 Resilience Test Patterns

Resilience tests verify that the system behaves correctly when things go wrong. Each failure mode gets its own test.

**Timeout injection (Go):**

```go
func TestClient_Timeout(t *testing.T) {
    // Server that never responds
    slowServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        time.Sleep(10 * time.Second)
    }))
    defer slowServer.Close()

    client := NewAPIClient(slowServer.URL, WithTimeout(100*time.Millisecond))
    _, err := client.FetchData(context.Background())

    require.Error(t, err)
    assert.True(t, errors.Is(err, context.DeadlineExceeded) || os.IsTimeout(err))
}
```

**Dependency failure simulation (Node + nock):**

```typescript
import nock from 'nock';

describe('PaymentService resilience', () => {
  afterEach(() => nock.cleanAll());

  it('returns fallback when payment provider is down', async () => {
    nock('https://payments.example.com')
      .post('/charge')
      .replyWithError('ECONNREFUSED');

    const result = await paymentService.charge({ amount: 100 });
    expect(result.status).toBe('queued'); // graceful degradation
    expect(result.retryAt).toBeDefined();
  });

  it('retries on 503 with backoff', async () => {
    nock('https://payments.example.com')
      .post('/charge').reply(503)  // first attempt fails
      .post('/charge').reply(200, { id: 'pay_123' }); // retry succeeds

    const result = await paymentService.charge({ amount: 100 });
    expect(result.status).toBe('completed');
  });
});
```

**Circuit breaker test (Go):**

```go
func TestCircuitBreaker_StateTransitions(t *testing.T) {
    cb := NewCircuitBreaker(Threshold(3), Timeout(1*time.Second))
    failingOp := func() error { return errors.New("service unavailable") }

    // Closed -> Open (after threshold failures)
    for i := 0; i < 3; i++ {
        cb.Execute(failingOp)
    }
    assert.Equal(t, StateOpen, cb.State())

    // Open -> rejects immediately
    err := cb.Execute(func() error { return nil })
    assert.ErrorIs(t, err, ErrCircuitOpen)

    // Open -> Half-Open (after timeout)
    time.Sleep(1100 * time.Millisecond)
    assert.Equal(t, StateHalfOpen, cb.State())

    // Half-Open -> Closed (on success)
    err = cb.Execute(func() error { return nil })
    assert.NoError(t, err)
    assert.Equal(t, StateClosed, cb.State())
}
```

### 8.3 Contract Test Patterns

Contract tests verify that API boundaries match agreed-upon schemas. They catch breaking changes before they reach consumers.

**Consumer-driven contract (Pact-style pattern):**

```typescript
// Consumer side: define what I expect from the provider
describe('UserAPI contract (consumer)', () => {
  it('GET /users/:id returns user shape', async () => {
    // Define the expected interaction
    const expectedUser = {
      id: Matchers.string(),
      name: Matchers.string(),
      email: Matchers.email(),
      createdAt: Matchers.iso8601DateTime(),
    };

    const response = await apiClient.getUser('user-123');
    expect(response).toMatchSchema(expectedUser);
  });
});
```

**Schema validation test (JSON Schema / Zod):**

```typescript
import { z } from 'zod';

const UserResponseSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(['admin', 'user', 'viewer']),
});

describe('User API schema', () => {
  it('GET /users/:id matches schema', async () => {
    const response = await request(app).get('/users/test-user-001').expect(200);
    const result = UserResponseSchema.safeParse(response.body);
    expect(result.success).toBe(true);
  });

  it('POST /users validates required fields', async () => {
    const response = await request(app)
      .post('/users')
      .send({ name: '' }) // missing required fields
      .expect(400);
    expect(response.body.errors).toBeDefined();
  });
});
```

**Backward compatibility check (Go):**

```go
func TestAPI_BackwardCompatibility(t *testing.T) {
    // v1 response shape must still work
    v1Fields := []string{"id", "name", "email"}
    resp := httptest.NewRecorder()
    handler.ServeHTTP(resp, httptest.NewRequest("GET", "/api/v1/users/1", nil))

    var body map[string]interface{}
    json.NewDecoder(resp.Body).Decode(&body)

    for _, field := range v1Fields {
        _, exists := body[field]
        assert.True(t, exists, "v1 field %q missing from response", field)
    }
}
```

**Cross-reference:** QE sub-persona activation for these patterns is defined in `qe.md` Activation Matrix.

---

## 9. Spec-Driven Test Scaffolding (Pre-Build)

Test skeletons are generated from spec acceptance criteria BEFORE implementation begins. This is the testing left-shift — the test contract exists before any production code is written.

### 9.1 AC-to-Test Mapping

Each acceptance criterion maps to one test case. The mapping determines which test layer (unit/integration/e2e) based on the AC's scope:

| AC Scope | Test Layer | Rationale |
|----------|-----------|-----------|
| Single function/method behavior | Unit | Isolated logic, fast feedback |
| Two+ modules interacting | Integration | Wiring verification |
| User-visible journey or multi-step flow | E2E | End-to-end behavior |
| API endpoint behavior | Integration | Request/response contract |
| Visual state or appearance | Visual (snapshot) | Design compliance |

### 9.2 Worked Example

**Spec: SPEC-AUTH-001 — User Authentication**

```
AC-1: Given valid credentials, the system returns a JWT with 24-hour expiry
AC-2: Given invalid credentials, the system returns 401 with error message
AC-3: Given an expired JWT, protected endpoints return 403
AC-4: Given a valid JWT, the user's profile is accessible at GET /me
```

**Generated test skeletons:**

`tests/unit/auth/auth-service.test.ts` (AC-1, AC-2 — unit layer):
```typescript
import { describe, it } from 'vitest';
// import { AuthService } from '@/modules/auth/auth.service';

describe('AuthService', () => {
  it('AC-1: returns JWT with 24h expiry on valid credentials', async () => {
    // TODO: implement after build
    // Given: registered user with email "test@example.com" and valid password
    // When: authenticate(email, password)
    // Then: returns JWT where decoded.exp = now + 86400s
  });

  it('AC-2: returns 401 with error on invalid credentials', async () => {
    // TODO: implement after build
    // Given: registered user with email "test@example.com"
    // When: authenticate(email, wrongPassword)
    // Then: throws UnauthorizedError with message
  });
});
```

`tests/integration/auth/auth-endpoints.test.ts` (AC-3, AC-4 — integration layer):
```typescript
import { describe, it } from 'vitest';

describe('Auth endpoints (integration)', () => {
  it('AC-3: returns 403 for expired JWT on protected endpoints', async () => {
    // TODO: implement after build
    // Given: JWT with exp in the past
    // When: GET /me with expired JWT in Authorization header
    // Then: 403 response
  });

  it('AC-4: returns user profile at GET /me with valid JWT', async () => {
    // TODO: implement after build
    // Given: valid JWT for user "test@example.com"
    // When: GET /me with JWT in Authorization header
    // Then: 200 with { id, name, email } matching the authenticated user
  });
});
```

### 9.3 Skeleton Rules

1. **One test per AC** — not one test per FR. ACs are the testable unit.
2. **TODO markers, not stubs** — `// TODO: implement after build` with the AC text as a comment. Never `expect(true).toBe(true)`.
3. **Correct file paths** — place skeletons in the right layer directory based on AC-to-test mapping.
4. **Import comments** — comment out the imports (modules don't exist yet). Include the expected import path from the spec's Design section.
5. **Commit before build** — skeletons are committed as part of the spec finalization, not during build.
6. **Spec Design section required** — if the spec has no Design section, QE flags to Product. Skeletons need module structure to generate meaningful paths and imports.

### 9.4 Anti-Patterns

- Writing implementation in skeletons (defeats the purpose — the skeleton is the contract, not the test)
- Creating stubs that "pass" with trivial assertions (hides coverage gaps)
- Generating one giant test file instead of layer-appropriate files (defeats pyramid)
- Skipping the skeleton step because "we'll write tests during build" (loses the left-shift benefit)

### 9.5 Automation Roadmap

The `dde scaffold-tests SPEC-{ID}` command (Sprint 11) will automate skeleton generation. Until then, QE generates skeletons manually following this pattern. Resilience QE activates for 8.2 patterns, SRE QE for external dependency integration (8.1), Core QE always present for contract tests (8.3).

---

_This playbook is a living document. The QE agent updates it as patterns evolve, new test types emerge, or coverage misses are identified._
