# README

# Venture Capital Investments

A Ruby on Rails 8 investment platform that manages the full lifecycle of Bitcoin investment plans, from deposit submission through daily profit generation and withdrawal processing.

## Overview

Venture Capital Investments is a backend-focused Rails application demonstrating production-quality architecture across a multi-role financial domain. The platform handles user authentication, role-based authorization, an investment lifecycle driven by service objects, automated background processing via Solid Queue, and a complete admin review workflow for both deposits and withdrawals.

The codebase prioritises correctness over cleverness: thin controllers, explicit service objects, immutable financial records, atomic transactions with row-level locking, and comprehensive test coverage across unit, integration, and system layers.

## Features

### Authentication

- User registration with email confirmation via Devise
- Secure session management
- Role-based access control (member and admin roles)

### Investment Management

- Tiered investment plans with configurable principal amounts, daily return rates, and durations
- Automatic investment creation on deposit approval via `InvestmentCreationService`
- Investment performance tracking derived from profit records (days paid, remaining days, total earned)
- Automatic investment completion with principal return via `CompleteInvestmentService`

### Wallet

- Wallet auto-created for every user on registration
- Tracks available balance, total deposited, total withdrawn, and total profit
- All balance mutations are atomic and protected by row-level locking
- Wallet activity ledger derived from profit records and completed investments

### Deposits

- Members submit deposit requests referencing a chosen investment plan
- Bitcoin transaction hash submitted for admin verification
- Admin review workflow with approve and reject actions
- Investment created automatically on approval within a single database transaction

### Withdrawals

- Members submit withdrawal requests denominated in BTC
- Funds reserved immediately on submission by debiting `available_balance`
- Admin review workflow with approve, reject, and complete actions
- Rejected withdrawals restore reserved funds atomically
- Completed withdrawals record the on-chain transaction hash as an audit trail

### Administration

- Dedicated admin operations dashboard with platform-wide metrics
- Admin deposit review with search, status filtering, and pagination
- Admin withdrawal review with search, status filtering, and pagination
- Admin investments index with search, status filtering, and pagination

### Automation

- Daily profit generation runs automatically on a recurring schedule
- Investment completion runs automatically on a recurring schedule
- Both jobs orchestrate only — all business logic remains in service objects
- Scheduling configured declaratively in `config/recurring.yml` using Solid Queue

### Reporting

- Member dashboard with wallet metrics and investment overview
- Profit history page showing all profit records for the authenticated user
- Wallet activity feed combining profit credits and principal returns
- Investment show page with performance metrics
- Admin operations dashboard with aggregate financial totals and recent activity

### Security

- Row-level locking (`SELECT ... FOR UPDATE`) on all wallet balance mutations
- Pundit policies enforce record ownership for every member-facing resource
- Admin routes protected by a dedicated `Admin::BaseController` with role verification
- Atomic transactions wrap all multi-model financial state changes
- Immutable financial records: profit records and wallet entries are append-only

## Architecture Highlights

**Thin controllers**
Controllers are responsible for authentication, authorization, delegating to services, and rendering. Business logic does not appear in controllers. A typical create action calls one service, checks the result, and redirects.

**Service objects**
All business workflows live in `app/services`. Each service accepts domain objects, applies business rules, mutates state within a transaction, and returns a typed `Result` struct with `success?`, a payload, and an error message. Services never raise for expected business-rule failures.

**Policy-based authorization**
Pundit policies govern every resource. Members may only access their own records. Admin access is granted at the controller level via `Admin::BaseController` and refined per action in individual policies. Policy scopes are used consistently in index actions.

**Jobs as orchestration**
Background jobs contain no business logic. `GenerateDailyProfitsJob` iterates active investments and calls `GenerateDailyProfitService` for each one. `CompleteInvestmentsJob` iterates eligible investments and calls `CompleteInvestmentService`. Per-record rescue blocks ensure one failure never halts an entire batch.

**Immutable financial ledger**
`ProfitRecord` entries are created and never modified. Wallet balances are derived from or updated alongside these records. No financial record is edited or destroyed after creation. Historical accuracy is preserved by copying plan values into investment records at creation time.

**Row-level locking**
Every service that mutates a wallet balance acquires an exclusive row-level lock via `wallet.with_lock` before reading or writing. The balance is read, validated, and updated within the same lock scope, preventing concurrent mutations from producing incorrect totals.

## Technology Stack

| Component | Technology |
|---|---|
| Language | Ruby 3.4.x |
| Framework | Rails 8 |
| Database | PostgreSQL |
| Frontend | Turbo, Stimulus, Tailwind CSS v4 |
| Authentication | Devise |
| Authorization | Pundit |
| Background Jobs | Solid Queue |
| Pagination | Pagy |
| Testing | Minitest |

## Installation

```bash
git clone https://github.com/your-username/venture-capital-investments.git
cd venture-capital-investments
bundle install
rails db:create
rails db:migrate
rails db:seed
bin/dev
```

The application will be available at `http://localhost:3000`.

## Running Tests

Run the full unit and integration test suite:

```bash
rails test
```

Run the system test suite:

```bash
rails test:system
```

Run both in sequence:

```bash
rails test && rails test:system
```

The test suite covers models, services, jobs, policies, controllers, and system flows. As of the current release, over 700 tests pass with zero failures.

## Background Jobs

Solid Queue is used as the job backend. Jobs are enqueued and processed via `bin/jobs`, which starts the Solid Queue supervisor.

Recurring jobs are configured in `config/recurring.yml`:

- **GenerateDailyProfitsJob** runs daily and credits profit to all active investments
- **CompleteInvestmentsJob** runs daily and closes investments that have reached their end date

No manual invocation is required in production. Both jobs can also be triggered manually via the Rails console for operational purposes.

## Project Structure

app/
services/       Business logic. One class per workflow. Returns typed Result structs.
jobs/           Background job orchestration. No business logic.
policies/       Pundit authorization policies. One policy per resource.
presenters/     Plain Ruby value objects for view composition (e.g. WalletActivityEntry).
models/         ActiveRecord models with validations, associations, and scopes.
No financial workflow logic in callbacks.

## Documentation

The following documentation files accompany this project:

- `docs/ARCHITECTURE.md` — system design, layer responsibilities, and data flow
- `docs/DATABASE.md` — schema overview, indexing decisions, and financial record design
- `docs/SERVICES.md` — service object catalogue with input, output, and responsibility descriptions
- `docs/JOBS.md` — background job inventory and scheduling configuration
- `docs/SECURITY.md` — authorization model, locking strategy, and financial safety guarantees
- `docs/DEPLOYMENT.md` — environment configuration, Solid Queue setup, and production considerations
- `docs/ROADMAP.md` — completed milestones and planned future work
- `docs/CONTRIBUTING.md` — development setup, conventions, and pull request process
- `docs/DECISIONS.md` — architecture decision records for significant design choices

## Roadmap

**Completed**

| Milestone | Scope |
|---|---|
| 1 | Authentication, wallets, and member dashboard |
| 2 | Investment plans |
| 3 | Deposit submission workflow |
| 4 | Admin deposit review |
| 5 | Investment creation service |
| 6 | Profit record ledger, daily profit service, and background job |
| 7 | Member-facing reporting: profit history, investment performance, wallet activity |
| 8 | Automated scheduling via Solid Queue recurring tasks |
| 9 | Withdrawal lifecycle: submission, admin review, and completion |
| 10 | Admin operations dashboard, search and pagination, and platform hardening |

**In progress**

Documentation is ongoing. The additional markdown documents listed above are being written to accompany the existing implementation.

**Planned**

- Communication: transactional email for lifecycle events
- Security: audit logging, two-factor authentication
- UX: improved member onboarding and mobile layout refinement
- Deployment: containerisation and production environment documentation

## License

MIT License. See `LICENSE` for details.