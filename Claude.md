# CLAUDE.md

This repository contains a Ruby on Rails 8 application implementing a Bitcoin-denominated investment platform.

Before making changes, understand and preserve the existing architecture.

For full architectural documentation, see:

- README.md
- ARCHITECTURE.md
- DATABASE.md
- SERVICES.md
- JOBS.md
- SECURITY.md
- DECISIONS.md
- ROADMAP.md
- AI_CONTEXT.md

---

# Primary Objective

Maintain architectural consistency.

Do not optimize for fewer lines of code.

Optimize for correctness, readability, and maintainability.

---

# Non-Negotiable Rules

## Controllers

Controllers remain thin.

Controllers may:

- authenticate
- authorize
- validate parameters
- delegate to services
- redirect or render

Controllers must never contain business logic.

---

## Models

Models contain:

- associations
- validations
- enums
- scopes
- lightweight derived methods

Do not introduce callbacks for financial workflows.

---

## Services

Business workflows belong in service objects.

Every service should:

- expose a single `call` method
- have one responsibility
- return a typed `Result`
- own business rules

Do not move service logic into models or controllers.

---

## Jobs

Jobs orchestrate only.

Jobs:

- query records
- invoke services
- log outcomes

Jobs never perform calculations or financial mutations directly.

---

## Financial Safety

Every wallet mutation must occur inside:

```ruby
wallet.with_lock do
```

Read, validate, and update balances only inside the lock.

Never bypass this rule.

---

## Transactions

Whenever multiple records change together:

- use database transactions
- guarantee atomicity
- avoid partial updates

---

## Immutable Records

Never modify historical financial records.

Profit records represent immutable ledger entries.

Investment plan values are snapshotted.

Historical data must remain historically correct.

---

# Existing Patterns

Follow the existing conventions.

Use:

- service objects
- Pundit policies
- typed Result structs
- ActiveRecord scopes
- explicit transactions
- row-level locking

Avoid introducing new patterns unless clearly justified.

---

# Testing

Every feature must include tests.

Typical additions include:

- model tests
- service tests
- policy tests
- controller tests
- job tests
- integration tests
- system tests

Financial workflows must include rollback tests.

Never consider work complete without tests passing.

---

# Documentation

Whenever architecture changes, update the relevant documentation.

Possible files:

- README.md
- docs/ARCHITECTURE.md
- docs/DATABASE.md
- docs/SERVICES.md
- docs/JOBS.md
- docs/SECURITY.md
- docs/DECISIONS.md
- docs/ROADMAP.md

---

# Coding Style

Prefer explicit code.

Prefer readability over cleverness.

Avoid unnecessary abstractions.

Keep methods focused.

Keep responsibilities isolated.

Match the style already established throughout the repository.

---

# Before Suggesting Changes

Ask:

- Does this preserve the existing architecture?
- Does it duplicate business logic?
- Does it belong in a service instead?
- Does it preserve financial correctness?
- Does it remain independently testable?

If not, redesign the solution before implementation.

---

# Current State

The application currently implements:

- authentication
- wallets
- investment plans
- deposit workflow
- investment lifecycle
- automated profit generation
- automated investment completion
- withdrawal workflow
- member reporting
- admin operations dashboard

The architecture is considered stable.

Future work should extend it without changing its underlying principles.