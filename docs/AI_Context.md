# AI Context

This document exists to rapidly onboard AI assistants to the Venture Capital Investments codebase.

It explains the architectural philosophy, coding conventions, and non-negotiable rules that should guide every implementation.

Read this document before suggesting changes to the project.

---

# Project Overview

Venture Capital Investments is a Ruby on Rails 8 application that manages the complete lifecycle of Bitcoin-denominated investment plans.

The application supports:

- user authentication
- investment plans
- deposit submission and review
- automatic investment creation
- automated daily profit generation
- automated investment completion
- withdrawal submission and review
- administrative reporting
- background processing
- financial reporting

The project is intentionally backend-focused and emphasizes correctness, maintainability, and explicit architecture over rapid feature development.

---

# Core Philosophy

Every implementation should reinforce these principles.

1. Thin controllers
2. Rich service layer
3. Explicit authorization
4. Immutable financial history
5. Atomic financial workflows
6. Database-enforced integrity
7. Single responsibility
8. Separation of concerns
9. Test-first development
10. Readability over cleverness

Never trade architectural quality for shorter code.

---

# Layer Responsibilities

## Controllers

Controllers are intentionally thin.

Responsibilities:

- authenticate
- authorize
- validate parameters
- call one service when appropriate
- redirect or render

Controllers must not:

- calculate balances
- mutate multiple models
- contain business rules
- perform financial calculations

---

## Models

Models contain only:

- associations
- validations
- enums
- scopes
- lightweight derived methods

Models should not:

- orchestrate workflows
- update wallets
- perform approvals
- send emails
- call external services

Avoid callbacks for financial behaviour.

---

## Services

Every business workflow belongs in a dedicated service object.

Each service should:

- expose one public `call` method
- have one responsibility
- return a typed `Result`
- own all business rules
- remain independently testable

Expected business-rule failures return failure results rather than raising exceptions.

---

## Jobs

Jobs orchestrate only.

Jobs should:

- query records
- invoke services
- log outcomes
- continue after individual failures

Jobs must never duplicate business rules.

---

## Policies

Every resource has:

- a policy
- a policy scope

Never bypass authorization.

---

## Presenters

Presenters compose view data.

They should never contain business rules.

---

# Financial Rules

These are non-negotiable.

## Immutable Ledger

ProfitRecord entries represent historical financial events.

Never modify them after creation.

---

## Wallet Safety

Every wallet mutation must occur inside:

```ruby
wallet.with_lock do
```

The balance must be:

1. read
2. validated
3. updated

inside the same lock.

Never read a wallet balance outside the lock before making financial decisions.

---

## Transactions

Whenever multiple records change together:

- use a database transaction
- either everything succeeds
- or everything rolls back

Never leave partial financial updates.

---

## BTC Is the Source of Truth

Financial records store BTC values only.

Do not introduce stored USD values.

Fiat conversions belong only in presentation.

---

## Historical Accuracy

Investment plans may change.

Investments must preserve:

- principal
- duration
- daily return rate

by snapshotting values during creation.

Never recalculate historical investments from the current plan.

---

# Existing Service Objects

The following workflows already exist.

- InvestmentCreationService
- GenerateDailyProfitService
- CompleteInvestmentService
- WithdrawalRequestService
- WithdrawalReviewService
- CompleteWithdrawalService

Before introducing a new service, check whether an existing one should be extended.

---

# Existing Jobs

Current background jobs:

- GenerateDailyProfitsJob
- CompleteInvestmentsJob

Jobs call services.

Services contain business logic.

---

# Existing Architectural Patterns

Maintain consistency with existing code.

Examples:

- typed Result objects
- policy scopes
- row-level locking
- service-per-workflow
- thin controllers
- immutable records
- ActiveRecord scopes
- explicit transactions

Avoid introducing alternative patterns unless there is a compelling architectural reason.

---

# Testing Philosophy

Every feature should include appropriate tests.

Possible test types:

- model
- service
- policy
- controller
- integration
- job
- system

Financial workflows must include:

- success path
- failure path
- rollback behaviour
- authorization
- edge cases

No feature is considered complete without tests.

---

# Documentation

Major architectural changes should update the relevant documentation.

Possible files include:

- README.md
- ARCHITECTURE.md
- DATABASE.md
- SERVICES.md
- JOBS.md
- SECURITY.md
- CONTRIBUTING.md
- ROADMAP.md
- DECISIONS.md

Documentation should explain both implementation and reasoning.

---

# When Proposing Changes

Before suggesting a new abstraction, ask:

- Does an existing pattern already solve this?
- Does this duplicate business logic?
- Does it preserve single responsibility?
- Does it improve readability?
- Is it independently testable?
- Does it preserve financial correctness?

If the answer to any of these is "no," reconsider the design.

---

# Current Project Status

Completed milestones:

- Authentication
- Wallets
- Investment plans
- Deposit workflow
- Deposit review
- Investment lifecycle
- Profit engine
- Reporting
- Automation
- Withdrawal lifecycle
- Administrative operations

The platform already supports the complete financial lifecycle.

Future work focuses primarily on:

- communication
- platform hardening
- production deployment

---

# AI Expectations

When contributing to this project:

Prefer consistency over novelty.

Follow established patterns rather than introducing new ones.

Do not move business logic into controllers or models.

Do not replace explicit code with metaprogramming.

Do not recommend callbacks for financial workflows.

Do not duplicate business rules across layers.

If a proposed change requires a new architectural pattern, explain why the existing architecture is insufficient before introducing it.

The architecture is considered a long-term asset.

Every contribution should preserve and strengthen it.