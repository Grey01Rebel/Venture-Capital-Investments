# Architecture Decisions

This document records significant architectural decisions made during the development of Venture Capital Investments.

The purpose of these records is to explain **why** decisions were made, not merely **what** was implemented.

Each decision reflects the project's guiding principles:

- correctness over convenience
- explicitness over magic
- immutable financial history
- single responsibility
- separation of concerns

---

# ADR-001: Business Logic Lives in Service Objects

## Status

Accepted

## Context

Financial workflows often span multiple models and require complex validation, transactions, and error handling.

Embedding these workflows inside models or controllers would create tightly coupled code and make testing difficult.

## Decision

All business workflows are implemented as dedicated service objects.

Examples include:

- InvestmentCreationService
- GenerateDailyProfitService
- CompleteInvestmentService
- WithdrawalRequestService
- WithdrawalReviewService
- CompleteWithdrawalService

Each service:

- has one responsibility
- exposes a single public `call` method
- returns a typed `Result`
- owns all business rules for the workflow

## Consequences

Controllers remain thin.

Models remain focused on persistence.

Business rules have a single source of truth.

---

# ADR-002: Controllers Remain Thin

## Status

Accepted

## Context

Controllers naturally become bloated when they contain calculations or workflow logic.

## Decision

Controllers are responsible only for:

- authentication
- authorization
- parameter handling
- delegating to services
- rendering responses

No business calculations belong in controllers.

## Consequences

Controllers are predictable, easy to test, and consistent throughout the application.

---

# ADR-003: Financial Records Are Immutable

## Status

Accepted

## Context

Historical financial records should never change after creation.

Editing past transactions destroys auditability.

## Decision

Records such as ProfitRecord represent historical events.

Existing records are never modified to alter financial history.

Corrections are represented by new records or explicit state transitions.

## Consequences

Historical reporting remains trustworthy.

Audit trails remain intact.

---

# ADR-004: Investment Plans Are Snapshotted

## Status

Accepted

## Context

Investment plans may change over time.

Historical investments must continue reflecting the terms originally purchased.

## Decision

When an investment is created, the following values are copied from the plan:

- principal amount
- daily return rate
- duration

Future edits to the investment plan never affect existing investments.

## Consequences

Historical accuracy is preserved.

No recalculation is required.

---

# ADR-005: Jobs Contain No Business Logic

## Status

Accepted

## Context

Background execution should not introduce an alternative implementation of business rules.

## Decision

Jobs orchestrate only.

They:

- find records
- invoke services
- log outcomes

All business decisions remain inside services.

## Consequences

Scheduled execution behaves identically to manual execution.

---

# ADR-006: Wallet Mutations Use Row-Level Locking

## Status

Accepted

## Context

Concurrent requests affecting the same wallet could otherwise produce incorrect balances.

## Decision

Every wallet mutation acquires an exclusive database lock using:

```ruby
wallet.with_lock
```

The balance is:

1. read
2. validated
3. updated

inside the lock.

## Consequences

Concurrent wallet updates are serialized.

Double spending is prevented.

---

# ADR-007: BTC Is the Source of Truth

## Status

Accepted

## Context

Deposits and withdrawals occur on the Bitcoin network.

Exchange rates fluctuate continuously.

## Decision

Financial records store BTC values only.

No USD equivalent is stored.

Any fiat display is derived at presentation time.

## Consequences

Historical records remain currency-accurate.

No stale exchange-rate data exists.

---

# ADR-008: Derived Data Is Preferred Over Stored Aggregates

## Status

Accepted

## Context

Stored totals eventually drift from the records they summarize.

## Decision

Whenever practical, reporting values are derived directly from existing records.

Examples include:

- total profit earned
- investment progress
- remaining days
- dashboard statistics

Only balances requiring transactional correctness are stored.

## Consequences

The application maintains a single source of truth.

---

# ADR-009: Database Constraints Complement Model Validations

## Status

Accepted

## Context

Application validations can be bypassed.

The database must protect structural integrity independently.

## Decision

Critical rules are enforced at both levels.

Examples include:

- foreign keys
- unique indexes
- composite indexes
- NOT NULL constraints

## Consequences

Data integrity remains protected regardless of application code.

---

# ADR-010: Services Return Typed Results

## Status

Accepted

## Context

Business-rule failures are expected outcomes.

Using exceptions for expected failures complicates application flow.

## Decision

Services return typed `Result` objects.

A typical result contains:

- success?
- payload
- error message

Exceptions are reserved for truly unexpected failures.

## Consequences

Service consumers remain simple and predictable.

---

# ADR-011: Authorization Is Policy-Based

## Status

Accepted

## Context

Authorization logic scattered across controllers becomes difficult to maintain.

## Decision

Pundit policies define authorization.

Every resource has:

- a policy
- a scope

## Consequences

Authorization rules remain centralized and testable.

---

# ADR-012: Automation Uses Solid Queue

## Status

Accepted

## Context

Recurring profit generation and investment completion require reliable background execution.

## Decision

Rails' native Solid Queue backend is used.

Recurring execution is configured declaratively in:

```
config/recurring.yml
```

## Consequences

No external scheduling infrastructure is required.

The application remains aligned with the Rails ecosystem.

---

# ADR-013: Services Own Financial State Transitions

## Status

Accepted

## Context

Financial state transitions must never occur implicitly.

## Decision

Only dedicated services may change financial state.

Examples include:

- pending → approved
- approved → completed
- active → completed

Models expose state only.

Services control transitions.

## Consequences

Financial behaviour remains explicit and traceable.

---

# ADR-014: Architecture Evolves Incrementally

## Status

Accepted

## Context

Large feature releases increase risk and reduce review quality.

## Decision

The application is developed through small, milestone-based increments.

Each milestone:

- introduces one cohesive capability
- preserves existing architecture
- maintains full test coverage

## Consequences

The system remains stable throughout development.

Architectural quality is maintained as the application grows.

---

# ADR-015: Deposit Review Extracted Into DepositReviewService

## Status

Accepted

## Context

`Deposit#approve!` and `Deposit#reject!` originally orchestrated the full approval workflow directly on the model: transitioning status, opening a transaction, invoking `InvestmentCreationService`, and rolling back on failure. This violated ADR-013 (services own financial state transitions) by placing workflow orchestration in the model rather than a dedicated service, and left `Deposit` responsible for both its own state and the resulting investment's creation.

This became a blocker to Milestone 11 (Communication): notification delivery is a workflow-level concern, and the model was not an appropriate place to add it.

## Decision

`DepositReviewService` now owns the deposit review workflow, mirroring the existing `WithdrawalReviewService`.

- `Deposit#approve!` and `Deposit#reject!` are reduced to pure state transitions: they update status, timestamps, reviewer, and notes, and nothing else.
- `DepositReviewService` calls these transition methods, invokes `InvestmentCreationService` on approval, and rolls back the transition if investment creation fails.
- `Admin::DepositsController` delegates to `DepositReviewService` rather than calling the model directly.

## Consequences

The deposit workflow is now consistent with ADR-013 and with the withdrawal review pattern. `DepositReviewService` is the natural extension point for the deposit notification emails introduced in Milestone 11.

---

# ADR-016: Withdrawal Notifications Are Scoped to Completion Only

## Status

Accepted

## Context

Withdrawals move through pending → approved/rejected → completed. Deposit notifications (ADR-015) cover both terminal review outcomes, but a withdrawal's approval is an internal administrative step, not a change the member's funds have actually undergone — the funds were already reserved at submission time. Completion is the point at which BTC actually leaves the platform.

## Decision

Only the pending → completed transition sends an email, via `WithdrawalMailer#completed`, triggered from `CompleteWithdrawalService`. Approval and rejection do not send notifications in this milestone.

## Consequences

Members are notified about the event with real financial consequence — money moving — without added noise for an intermediate administrative step. If member feedback later shows rejection notifications are needed (e.g. to explain why reserved funds were returned), that can be added to `WithdrawalReviewService` without revisiting this decision for completion.

---

# ADR-017: Investment Lifecycle Notifications Are Scoped to Completion Only

## Status

Accepted

## Context

An investment's lifecycle produces two kinds of events: a daily profit credit (`GenerateDailyProfitService`, once per investment per day for the full `duration_days`) and a single completion event (`CompleteInvestmentService`, once, at maturity, when principal returns to the wallet).

Emailing every daily profit credit individually would mean a member with several concurrent investments receiving multiple emails every day for the life of each investment — this creates notification fatigue and works against the product rather than for it. A periodic digest (e.g. weekly) is a reasonable alternative, but it is architecturally distinct from a per-transition mailer hook: it requires its own scheduled job and a cadence decision, rather than a single `deliver_later` call from the service that already owns the transition. That work is deferred to be scoped alongside the roadmap's notification-preferences milestone item, where cadence naturally belongs as a preference rather than a fixed decision.

Investment creation is already covered by `DepositMailer#approved` (ADR-015) and is not a separate event here.

## Decision

Only investment completion sends an email, via `InvestmentMailer#completed`, triggered from `CompleteInvestmentService`. Daily profit credits do not send individual emails. Internal skip/failure conditions inside `GenerateDailyProfitService` and `CompleteInvestmentService` (missing wallet, not yet eligible, duplicate profit date) remain logged only and are never surfaced to members, since these are transient and self-resolving on the next scheduled run.

## Consequences

Members are notified about the two events with genuine, discrete financial significance — an investment being created and an investment maturing — without daily noise. The daily-profit digest remains a known, deferred piece of future work rather than an implicit gap.

---

# ADR-018: CSP style-src Permits unsafe-inline

## Status

Accepted

## Context

Milestone 13 Phase 1 introduced an application-wide Content-Security-Policy. `script-src` can be fully locked down to `'self'` plus a per-session nonce, since the application has no inline `<script>` tags outside of importmap's own nonce-covered output.

`style-src` is different. `app/views/investments/show.html.erb` sets an inline `style="width: X%"` attribute to render a progress bar. CSP nonces apply to `<style>` elements and to tags Rails explicitly marks with `nonce: true` — they do not apply to arbitrary `style=""` attributes on ordinary elements. There is no nonce-based way to permit this one inline style without also permitting all inline styles.

## Decision

`style-src` includes `'self' 'unsafe-inline'`. This is a narrower compromise than leaving CSP unconfigured entirely, and `script-src` — the directive with the more severe XSS blast radius — remains strict.

The alternative was refactoring the progress bar to use a CSS custom property set via a nonce-covered `<style>` tag, closing the gap entirely. That refactor was deliberately not bundled into a security-headers phase: it touches application view rendering, which is out of scope for a phase intended to be config-only and low-risk, and its correctness can't be verified through the automated test suite (CSP violations aren't visible to Capybara/system tests) — it would need a manual browser check regardless of when it's done.

## Consequences

An attacker able to inject an inline `style` attribute (a narrower, lower-severity primitive than inline script) would not be blocked by CSP alone. This is judged an acceptable, explicitly-documented trade-off rather than an oversight. Closing it — by refactoring the one affected view — is a candidate for a small follow-up, not a blocker to shipping the rest of the header policy.

---

# ADR-019: Permissions-Policy Is Set Explicitly, Not via Rails' `config.permissions_policy`

## Status

Accepted

## Context

Milestone 13 Phase 1 originally configured `config/initializers/permissions_policy.rb` using Rails' documented `Rails.application.config.permissions_policy` API — the standard, framework-recommended mechanism.

Test verification against a real request showed the header never appeared. Investigation traced this to a known, filed Rails bug: [rails/rails#48878](https://github.com/rails/rails/issues/48878). `ActionDispatch::PermissionsPolicy::Middleware`, despite its name, hardcodes its header constant to the legacy `Feature-Policy` name and the legacy semicolon-separated value syntax (`camera 'none'`) — not the modern `Permissions-Policy` header and its `camera=()` structured-field syntax. This is intentional legacy behavior on Rails' part (per the middleware's own source comment), not a misconfiguration on this application's side. `Feature-Policy` has had no browser support since roughly 2021; relying on this Rails mechanism would have shipped a security control that appears configured but provides no actual browser-side protection.

## Decision

`config/initializers/permissions_policy.rb` is removed. The real `Permissions-Policy` header is set explicitly in `ApplicationController` via an `after_action`, bypassing Rails' framework helper entirely:

```ruby
PERMISSIONS_POLICY = "camera=(), microphone=(), geolocation=(), usb=(), payment=(), fullscreen=()"
after_action :set_permissions_policy_header
```

This is a controller-level `after_action` for a cross-cutting HTTP-response concern, not a model callback governing financial state — it does not conflict with the project's restriction on callbacks for financial workflows.

## Consequences

The header now matches what current browsers actually parse and enforce, verified directly rather than assumed. Any future Rails upgrade that fixes rails/rails#48878 would make this explicit `after_action` redundant with the framework default; at that point either can be removed in favor of the other, but there's no harm in the explicit version persisting alongside a fixed framework default.

---

# Decision Process

New architectural decisions should be documented when they:

- introduce a new pattern
- change an existing architectural rule
- affect financial correctness
- alter long-term maintainability
- establish a new convention

Small implementation details do not require a decision record.

This document exists to preserve the reasoning behind the architecture so future contributors understand not only how the system works, but why it was designed this way.