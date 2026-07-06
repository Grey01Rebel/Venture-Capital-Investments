# Contributing

Thank you for your interest in contributing to Venture Capital Investments.

This project prioritises correctness, maintainability, and explicit architecture over rapid feature development. Before making changes, please read the project documentation, particularly:

- README.md
- ARCHITECTURE.md
- DATABASE.md
- SERVICES.md
- JOBS.md
- SECURITY.md

Understanding the architectural principles is essential before modifying the codebase.

---

# Development Philosophy

The project follows a strict separation of responsibilities.

Each layer has a clearly defined purpose.

| Layer | Responsibility |
|--------|----------------|
| Controllers | Authentication, authorization, parameter handling, delegation, rendering |
| Models | Associations, validations, scopes, simple derived methods |
| Services | Business workflows and financial state transitions |
| Jobs | Background orchestration only |
| Policies | Authorization rules |
| Views | Presentation only |
| Presenters | View composition where appropriate |

Business logic should exist in one place only.

---

# Before Opening a Pull Request

Please ensure:

- All tests pass.
- No business logic has been added to controllers.
- No financial mutations occur inside models or callbacks.
- Services remain single-purpose.
- New features follow the established architecture.
- Documentation is updated where appropriate.

---

# Coding Standards

## Controllers

Controllers should remain thin.

A typical action should:

1. authenticate
2. authorize
3. delegate to a service
4. redirect or render

Avoid calculations or workflow logic.

Good:

```ruby
result = WithdrawalRequestService.new(...).call

if result.success?
  redirect_to ...
else
  render :new
end
```

Avoid:

- balance calculations
- state transitions
- multi-model updates
- business validation

---

## Models

Models should contain:

- associations
- validations
- scopes
- enums
- lightweight derived methods

Avoid:

- financial workflows
- external API calls
- callbacks that mutate financial state

---

## Services

Every business workflow belongs in its own service object.

Services should:

- have one responsibility
- expose a single public `call` method
- return typed `Result` objects
- own all business rules for the workflow

Financial mutations should execute atomically.

Wallet mutations must acquire a row-level lock.

---

## Jobs

Jobs are orchestration only.

Jobs should:

- find records
- call a service
- log outcomes
- continue after failures

Jobs must never duplicate business rules.

---

## Policies

Every new resource should have:

- a policy
- a scope

Never bypass authorization for convenience.

---

# Testing

Every feature should include appropriate test coverage.

Depending on the change, this may include:

- model tests
- service tests
- policy tests
- controller tests
- integration tests
- system tests

Financial workflows should always include rollback and failure-path tests.

---

# Financial Workflows

Financial correctness takes precedence over convenience.

Every workflow involving money should:

- execute inside a transaction when multiple records change
- use row-level locking when mutating wallet balances
- preserve immutable financial history
- avoid duplicated business rules

Never bypass service objects for financial operations.

---

# Database Changes

When adding migrations:

- add foreign keys where appropriate
- prefer database constraints alongside model validations
- index commonly queried columns
- preserve historical data
- avoid destructive migrations without justification

---

# Documentation

Major architectural changes should be reflected in the documentation.

Possible updates include:

- ARCHITECTURE.md
- DATABASE.md
- SERVICES.md
- JOBS.md
- SECURITY.md
- ROADMAP.md
- DECISIONS.md

Documentation should explain *why* a decision was made, not simply *what* changed.

---

# Commit Messages

Use clear, descriptive commit messages.

Examples:

```
Add withdrawal completion service

Implement admin investment search

Protect wallet updates with row-level locking
```

Avoid vague messages such as:

```
Fix stuff

Updates

Changes
```

---

# Pull Requests

A pull request should include:

- summary of the change
- reasoning behind the implementation
- testing performed
- documentation updates (if applicable)

Smaller, focused pull requests are preferred over large multi-feature changes.

---

# Architectural Principles

The project is guided by the following principles:

- Thin controllers
- Rich service layer
- Explicit authorization
- Immutable financial records
- Atomic transactions
- Row-level locking
- Database-enforced integrity
- Single responsibility
- Separation of concerns

New code should reinforce these principles rather than introduce alternative patterns.

---

# Questions

When in doubt, follow the existing architecture rather than introducing a new abstraction.

Consistency is preferred over novelty.

If a new feature does not naturally fit the current architecture, document the reasoning before introducing a new pattern.