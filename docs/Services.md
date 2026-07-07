# Services

## Overview

The application's business logic lives entirely within service objects.

Controllers authenticate users, authorize actions, collect input, and delegate work to services. Models define the structure of the domain through associations, validations, scopes, and small derived methods. Background jobs orchestrate services without containing business rules.

Every financial workflow has exactly one service object responsible for executing it.

---

# Design Principles

All services follow the same conventions.

- One service owns one business workflow.
- Services never render views or redirect requests.
- Services are framework-independent beyond Active Record.
- Expected business-rule failures return typed `Result` objects.
- Unexpected failures raise exceptions and roll back transactions.
- Financial mutations execute atomically.
- Wallet mutations always acquire a row-level lock.

---

# Service Contract

Every service exposes a single public entry point:

```ruby
call
```

The constructor accepts the required domain objects or primitive values.

Example:

```ruby
WithdrawalRequestService.new(user:, amount:, btc_address:)
```

The service performs all business validation internally.

Controllers should not duplicate service validation.

---

# Result Objects

Each service returns a typed `Result` object.

A typical result contains:

- success?
- payload (when applicable)
- error message

Expected business failures never raise exceptions.

Example:

```ruby
result = WithdrawalRequestService.new(...).call

if result.success?
  ...
else
  flash[:alert] = result.error
end
```

This produces predictable controller logic throughout the application.

---

# Service Catalogue

## DepositReviewService

### Responsibility

Handles administrator approval and rejection of a deposit.

### Approval

- transitions the deposit to approved via `Deposit#approve!`
- invokes `InvestmentCreationService` to create the resulting investment
- rolls back the approval if investment creation fails, leaving the deposit pending

### Rejection

- transitions the deposit to rejected via `Deposit#reject!`
- performs no wallet or investment mutation

### Does Not

- mutate wallet balances
- duplicate `InvestmentCreationService`'s business rules

`Deposit#approve!` and `Deposit#reject!` remain pure state-transition methods on the model. `DepositReviewService` is the sole caller responsible for orchestrating the full approval workflow, mirroring how `WithdrawalReviewService` owns the withdrawal review workflow.

---

## InvestmentCreationService

### Responsibility

Creates an investment from an approved deposit.

### Inputs

- Deposit

### Performs

- validates deposit state
- snapshots plan values
- creates investment

### Does Not

- update wallet balances
- calculate profits
- complete investments

---

## GenerateDailyProfitService

### Responsibility

Generates one day's profit for one investment.

### Inputs

- Investment
- Profit date

### Performs

- validates investment eligibility
- prevents duplicate profit generation
- creates ProfitRecord
- credits wallet profit
- updates wallet totals

### Guarantees

Exactly one profit record per investment per day.

---

## CompleteInvestmentService

### Responsibility

Completes an investment after its term ends.

### Inputs

- Investment

### Performs

- validates completion eligibility
- returns principal
- marks investment completed

### Does Not

- generate profit
- create deposits
- modify investment plans

---

## WithdrawalRequestService

### Responsibility

Creates a withdrawal request.

### Inputs

- User
- BTC amount
- Bitcoin address

### Performs

- validates amount
- validates available balance
- reserves funds
- creates withdrawal

### Wallet Behaviour

Acquires a row-level lock before reading or writing the wallet.

---

## WithdrawalReviewService

### Responsibility

Handles administrator approval and rejection.

### Approval

- marks withdrawal approved
- records reviewer
- records notes

No wallet mutation occurs.

### Rejection

- restores reserved funds
- marks withdrawal rejected
- records reviewer

Wallet restoration executes atomically.

---

## CompleteWithdrawalService

### Responsibility

Marks an approved withdrawal as completed.

### Inputs

- Withdrawal
- Transaction hash

### Performs

- validates approval status
- validates transaction hash
- records completion
- stores blockchain transaction hash

No wallet mutation occurs.

---

# Transactions

Financial services use database transactions whenever multiple models change together.

Examples:

- withdrawal creation
- withdrawal rejection
- investment creation
- daily profit generation
- investment completion

Single-record updates do not introduce unnecessary transactions.

---

# Row-Level Locking

Every wallet mutation occurs inside:

```ruby
wallet.with_lock
```

The lock is acquired before reading the balance.

This guarantees:

- no race conditions
- no double spending
- serialized balance updates

Services that never touch wallets do not acquire locks.

---

# Error Handling

Expected failures return Result objects.

Examples:

- insufficient balance
- duplicate daily profit
- investment already completed
- withdrawal already approved

Unexpected failures raise exceptions and trigger transaction rollback.

---

# Service Ownership

Every financial workflow has one owner.

| Workflow | Service |
|----------|---------|
| Investment creation | InvestmentCreationService |
| Daily profit | GenerateDailyProfitService |
| Investment completion | CompleteInvestmentService |
| Withdrawal submission | WithdrawalRequestService |
| Withdrawal review | WithdrawalReviewService |
| Withdrawal completion | CompleteWithdrawalService |

Jobs, controllers, and models delegate to these services.

No workflow has multiple implementations.

---

# Architectural Guarantees

The service layer guarantees:

- business rules are implemented once
- controllers remain thin
- jobs remain orchestration-only
- financial mutations are atomic
- wallet updates are concurrency-safe
- business behaviour is independently testable

Every new financial workflow added to the platform should follow the same architectural pattern established by the existing services.