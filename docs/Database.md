# Database Design

## Philosophy

The database is the foundation of the platform's financial correctness.

The schema is designed around four principles:

- Financial records are immutable.
- Database constraints complement application validations.
- Historical accuracy is preserved through snapshotting.
- The database remains the final source of truth for integrity.

Business rules belong in service objects, while the database enforces structural correctness through foreign keys, unique indexes, NOT NULL constraints, and transactional guarantees.

---

# Core Domain

The platform revolves around the following domains:

User
│
├── Wallet
├── Deposits
├── Investments
├── Profit Records
└── Withdrawals

InvestmentPlan

Admin users review deposits and withdrawals but never own financial records.

---

# Users

Stores authentication and authorization information.

Key fields:

- email
- encrypted_password
- role

Role is implemented as an integer enum.

member = 0

admin = 1

---

# Wallets

Each user owns exactly one wallet.

Purpose:

Tracks financial balances.

Fields

- available_balance
- total_deposited
- total_withdrawn
- total_profit

Only available_balance changes during normal platform operations.

The remaining totals exist as reporting values.

Every wallet mutation occurs inside a row-level lock.

---

# Investment Plans

Investment plans are templates.

They define:

- principal amount
- duration
- daily return rate

Plans are never linked dynamically after an investment begins.

Their values are copied into the investment record.

This preserves historical accuracy.

---

# Deposits

Represents a member's funding request.

Lifecycle

Pending

↓

Approved

↓

Investment created

or

Rejected

Important fields

- transaction_hash
- status
- approved_at
- rejected_at
- reviewed_by_id

Deposits never modify wallet balances directly.

Approval triggers InvestmentCreationService.

---

# Investments

Represents an active investment contract.

Snapshot fields:

- principal_amount
- duration_days
- daily_return_rate

These values are copied from InvestmentPlan at creation time.

This guarantees historical accuracy if plans later change.

Lifecycle

Active

↓

Completed

Completion returns principal.

---

# Profit Records

ProfitRecord is an immutable ledger.

Each row represents one day's profit for one investment.

Important constraint

Unique index:

(investment_id, profit_date)

This guarantees exactly one profit payment per investment per day.

Profit records are never updated.

Never deleted.

Never recalculated.

---

# Withdrawals

Represents BTC withdrawals.

Amounts are stored as

decimal(20,8)

The ledger remains BTC-denominated.

Lifecycle

Pending

↓

Approved

↓

Completed

or

Rejected

Rejected withdrawals restore reserved funds.

Completed withdrawals record the blockchain transaction hash.

---

# Snapshot Strategy

The platform snapshots values only when historical accuracy requires it.

Examples

Investment stores

- principal_amount
- duration_days
- daily_return_rate

instead of reading them from InvestmentPlan.

This prevents historical investments from changing when plans are edited.

---

# Derived Data

Values are derived whenever historical records already exist.

Examples

Investment

- days_paid
- remaining_days
- total_profit_earned

Dashboard

- total invested
- total profit

Wallet activity

- generated from ProfitRecord and Investment

No duplicated aggregate columns exist.

---

# Constraints

The schema uses database constraints alongside Rails validations.

Examples

Foreign keys

Unique indexes

Partial unique indexes

NOT NULL constraints

Examples include

- one investment per deposit
- one profit record per investment per day
- unique completed transaction hashes

These constraints prevent data corruption even if application code is bypassed.

---

# Financial Integrity

Every multi-model financial operation executes inside a database transaction.

Wallet mutations additionally acquire a row-level lock.

The combination of

transactions

+

SELECT FOR UPDATE

ensures balances remain correct under concurrent requests.

---

# Indexing Strategy

Indexes are added to support the application's primary query patterns.

Examples

status

user_id

created_at

completed_at

Foreign keys

Composite unique indexes

Partial unique indexes

Search queries currently use PostgreSQL ILIKE.

If search volume grows substantially, pg_trgm indexes or full-text search can be introduced without altering the domain model.

---

# Source of Truth

The database is the final authority for financial correctness.

Application validations improve user experience.

Database constraints guarantee integrity.

When the two overlap, the database always wins.