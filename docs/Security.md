# Security

## Overview

The platform is designed around a defence-in-depth approach.

No single mechanism is relied upon for correctness or security.

Instead, multiple independent layers work together:

- Authentication
- Authorization
- Database constraints
- Service-layer validation
- Atomic transactions
- Row-level locking
- Immutable financial records
- Audit trails

Each layer reinforces the others, ensuring financial operations remain correct even if another layer fails.

---

# Authentication

User authentication is handled by Devise.

Features include:

- secure password hashing
- authenticated sessions
- email confirmation
- password reset
- remember me functionality

Every protected route requires an authenticated user.

---

# Authorization

Authorization is implemented using Pundit.

Every resource has its own policy.

Examples include:

- DepositPolicy
- InvestmentPolicy
- WithdrawalPolicy
- ProfitRecordPolicy

Policies define:

- who may view a record
- who may modify a record
- which records appear in index pages

Policy scopes are used consistently for collection queries.

---

# Role-Based Access

Users have one of two roles.

| Role | Permissions |
|------|-------------|
| Member | Access only their own financial records |
| Admin | Platform-wide operational access |

Admin-only functionality is protected by two independent layers.

First:

`Admin::BaseController`

verifies that the current user is an administrator.

Second:

Pundit policies authorize the requested action.

This layered approach prevents accidental exposure of privileged operations.

---

# Record Ownership

Members never access records by raw ID alone.

Every member-facing controller uses:

- `policy_scope`
- `authorize`

or directly scopes through `current_user`.

This guarantees users can access only their own data.

Examples:

- deposits
- investments
- withdrawals
- profit records
- wallet activity

---

# Service Layer Validation

Business rules are enforced inside service objects.

Examples include:

- sufficient wallet balance
- investment eligibility
- duplicate daily profit prevention
- withdrawal state transitions
- completion eligibility

Controllers never duplicate these rules.

This ensures every execution path follows the same business logic.

---

# Database Constraints

The database protects structural integrity independently of application code.

Examples include:

- foreign keys
- NOT NULL constraints
- unique indexes
- composite unique indexes
- partial unique indexes

These constraints remain effective even if application code is bypassed.

---

# Atomic Transactions

Financial workflows involving multiple records execute inside database transactions.

Examples include:

- investment creation
- withdrawal submission
- withdrawal rejection
- daily profit generation
- investment completion

Either every change succeeds or none do.

Partial financial updates cannot occur.

---

# Row-Level Locking

Wallet balance mutations are protected using:

```ruby
wallet.with_lock
```

The lock is acquired before reading the wallet balance.

This guarantees:

- no race conditions
- no double spending
- serialized balance updates

Concurrent requests affecting the same wallet wait for the first transaction to complete before proceeding.

---

# Immutable Financial Records

Financial history is preserved through immutable records.

Examples include:

- ProfitRecord
- completed withdrawals
- completed investments

Records represent historical events rather than mutable state.

Existing financial records are never edited to change history.

---

# Snapshot Strategy

Investments snapshot plan values when created.

Copied values include:

- principal amount
- daily return rate
- duration

Future edits to investment plans never alter historical investments.

This preserves auditability.

---

# Audit Trail

Administrative actions are recorded.

Examples include:

Deposits

- reviewed_by_id
- approved_at
- rejected_at
- admin_notes

Withdrawals

- reviewed_by_id
- approved_at
- rejected_at
- completed_at
- transaction_hash
- admin_notes

These fields provide accountability for operational decisions.

---

# Financial Safety

Wallet balances are protected by multiple independent mechanisms.

1. Service validation

↓

2. Row-level locking

↓

3. Database transaction

↓

4. Database constraints

Only after every layer succeeds is a balance updated.

---

# SQL Injection Protection

Active Record parameter binding is used throughout the application.

Search functionality escapes wildcard characters using:

```ruby
sanitize_sql_like
```

Queries remain parameterized.

Raw SQL interpolation is avoided.

---

# Mass Assignment Protection

Controllers permit only explicitly allowed parameters.

Sensitive attributes such as:

- role
- wallet balances
- statuses
- timestamps
- reviewer fields

cannot be assigned through user input.

These values are controlled exclusively by services and administrators.

---

# Background Job Safety

Jobs contain no business logic.

Every financial decision is delegated to service objects.

This prevents scheduled execution from introducing alternate business paths.

Jobs also isolate failures on a per-record basis so one error cannot halt an entire batch.

---

# Financial Integrity Model

Every financial workflow follows the same pattern.

```
Request

↓

Authentication

↓

Authorization

↓

Service Validation

↓

Database Transaction

↓

Row-Level Lock (if wallet mutation)

↓

Database Constraints

↓

Commit
```

Each layer must succeed before money-related state changes.

---

# Security Principles

The platform is built around the following principles.

- Least privilege
- Explicit authorization
- Immutable financial history
- Atomic state transitions
- Concurrency safety
- Database-enforced integrity
- Single source of business logic
- Defence in depth

These principles guide every financial workflow implemented within the application.