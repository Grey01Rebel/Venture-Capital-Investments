# ARCHITECTURE

# Venture Capital Investments Architecture

## Philosophy

This application follows a layered architecture designed around one primary goal:

> Financial correctness takes priority over convenience.

Every architectural decision exists to ensure that money can never be created, lost, duplicated, or mutated unexpectedly.

The codebase intentionally favours explicitness over clever abstractions. Responsibilities are kept small, predictable, and isolated.

Core principles:

- Thin controllers
- Fat service layer
- Simple ActiveRecord models
- Immutable financial records
- Explicit authorization
- Atomic financial operations
- Single source of truth
- Database-enforced integrity

---

# Layer Responsibilities

```
Browser
    │
    ▼
Controllers
    │
    ▼
Policies
    │
    ▼
Service Objects
    │
    ▼
Models
    │
    ▼
PostgreSQL
```

Every request flows downward.

Business logic never flows upward.

---

# Controllers

Controllers coordinate requests.

Their responsibilities are intentionally limited.

Controllers may:

- authenticate users
- authorize users
- load records
- call one service
- redirect or render

Controllers never:

- calculate balances
- change investment states
- update wallets
- perform financial calculations
- implement business rules

Example:

```
WithdrawalsController#create

↓

WithdrawalRequestService.call(...)

↓

redirect
```

The controller is orchestration only.

---

# Models

Models represent data.

Models contain only:

- associations
- validations
- scopes
- small derived methods

Examples include:

- total_profit_earned
- remaining_days
- active scope
- completed scope

Models never:

- update wallets
- create investments
- complete withdrawals
- generate profits
- perform transactions

Financial workflows never exist inside callbacks.

No lifecycle callbacks mutate money.

---

# Service Objects

Every financial workflow lives inside a dedicated service object.

Examples:

- InvestmentCreationService
- GenerateDailyProfitService
- CompleteInvestmentService
- WithdrawalRequestService
- WithdrawalReviewService
- CompleteWithdrawalService

Each service owns exactly one workflow.

Each service:

- validates business rules
- acquires locks when required
- starts transactions
- mutates records
- returns a typed Result object

Services never render views.

Services never know about HTTP.

Services are reusable from:

- controllers
- jobs
- console
- future APIs

---

# Result Objects

Services never raise exceptions for expected failures.

Instead they return:

```
Result.new(
  success?,
  payload,
  error
)
```

Typical failures include:

- insufficient balance
- already approved
- already completed
- duplicate daily profit
- invalid status

Unexpected failures are allowed to raise naturally.

---

# Mailers

Transactional emails are dispatched from services, never from models or controllers.

A service that owns a state transition (for example `DepositReviewService`) enqueues the corresponding mailer via `deliver_later` only after its transaction has committed successfully. This avoids a background job attempting to reference a record that never persisted.

Mailers themselves contain no business logic — they read already-decided state off the record they're given and render it.

---

# Policies

Authorization uses Pundit.

Every resource has:

- Policy
- Policy::Scope

Controllers always use:

```
authorize record
```

or

```
policy_scope(Model)
```

Members only access their own records.

Admins access all records where appropriate.

Authorization is never implemented inside controllers.

---

# Background Jobs

Jobs contain zero business logic.

Jobs perform three responsibilities only:

1. load records
2. call services
3. log outcomes

Example:

```
Investment.active.find_each do |investment|
    GenerateDailyProfitService.call(investment)
end
```

Jobs never:

- calculate profit
- update balances
- modify investments directly

Those responsibilities belong to services.

---

# Financial Ledger

Financial history is immutable.

Examples:

- ProfitRecord
- Deposit
- Withdrawal

Historical records are never edited.

Instead new records represent new events.

Historical accuracy is preserved permanently.

---

# Wallet Design

Wallet balances represent current state.

Financial records represent historical state.

Wallet values change.

Ledger entries do not.

Example:

```
ProfitRecord

↓

wallet.available_balance += amount

↓

ProfitRecord remains unchanged forever
```

Wallets provide fast reads.

Ledger records provide auditability.

---

# Atomic Transactions

Every workflow affecting multiple records executes inside one transaction.

Example:

Withdrawal rejection:

```
transaction

restore wallet balance

update withdrawal status

commit
```

If any operation fails:

everything rolls back.

No partial financial state is ever committed.

---

# Row-Level Locking

Every wallet mutation uses:

```
wallet.with_lock
```

The lock guarantees:

- fresh balance
- serialized writes
- no race conditions

Balance validation always occurs inside the lock.

Example:

```
wallet.with_lock do

    verify balance

    debit wallet

    create withdrawal

end
```

Reading before acquiring the lock is intentionally avoided.

---

# Derived Data

The application avoids duplicated data whenever possible.

Example:

Investment performance:

```
days_paid

↓

COUNT(profit_records)
```

rather than

```
investments.days_paid
```

Similarly:

```
total_profit_earned

↓

SUM(profit_records.amount)
```

instead of storing totals.

Stored values exist only when required for performance or historical accuracy.

---

# Snapshot Data

Some values intentionally duplicate information.

Example:

Investment stores:

- principal_amount
- duration_days
- daily_return_rate

even though those exist on InvestmentPlan.

Why?

Plans may change later.

Historical investments must remain accurate forever.

Snapshotting preserves history.

---

# Automation Pipeline

Investment lifecycle:

```
Deposit

↓

Admin Approval

↓

InvestmentCreationService

↓

Investment

↓

GenerateDailyProfitsJob

↓

GenerateDailyProfitService

↓

ProfitRecord

↓

Wallet Credit

↓

CompleteInvestmentsJob

↓

CompleteInvestmentService

↓

Principal Returned

↓

Completed Investment
```

Withdrawal lifecycle:

```
Withdrawal Request

↓

WithdrawalRequestService

↓

Funds Reserved

↓

Admin Approval

↓

WithdrawalReviewService

↓

Approved Withdrawal

↓

Bitcoin Sent

↓

CompleteWithdrawalService

↓

Completed Withdrawal
```

Every transition has exactly one owner.

---

# Search

Admin searching executes entirely in SQL.

Pattern:

```
Model.search_by_term(term)
```

Searches never:

- load full tables
- filter in Ruby

Search remains database-driven.

---

# Pagination

Administrative indexes use Pagy.

Benefits:

- bounded queries
- low memory usage
- predictable response time

Pagination exists only in presentation.

Business logic remains unaffected.

---

# Error Handling

Expected failures return Result objects.

Unexpected failures raise exceptions.

Controllers display friendly messages using returned errors.

Database exceptions roll back transactions automatically.

---

# Testing Strategy

The project uses several layers of testing.

Model tests

- validations
- scopes
- derived methods

Service tests

- business rules
- transactions
- rollback behaviour

Policy tests

- authorization
- scopes

Controller tests

- request flow
- rendering
- redirects

Job tests

- orchestration
- logging
- service invocation

System tests

- complete user workflows

Every financial workflow is tested independently and end-to-end.

---

# Design Principles

The architecture follows these rules consistently.

Controllers coordinate.

Services decide.

Models represent.

Policies authorize.

Jobs orchestrate.

Database enforces integrity.

Money moves in one place only.

Every workflow has one owner.

History is immutable.

Correctness is preferred over cleverness.
# Architectural Rules

The following rules apply throughout the codebase.

1. Controllers never contain business logic.

2. Financial workflows always live inside service objects.

3. Service objects own every state transition.

4. Models contain validations, associations, scopes, and small derived methods only.

5. Background jobs orchestrate services and never duplicate business rules.

6. Every multi-model financial operation executes inside a database transaction.

7. Every wallet mutation acquires a row-level lock before reading the balance.

8. Authorization is enforced through Pundit policies and policy scopes.

9. Historical financial records are immutable.

10. Derived values are preferred over stored aggregates whenever historical records already exist.

11. Snapshot data is stored only when historical accuracy requires it.

12. Database constraints enforce integrity alongside application validations.

13. Expected business failures return typed Result objects rather than raising exceptions.

14. Every financial workflow has exactly one owner.

15. There must never be two code paths capable of performing the same financial mutation.