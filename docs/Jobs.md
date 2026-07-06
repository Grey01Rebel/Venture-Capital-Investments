# Jobs

## Overview

The platform uses background jobs to automate recurring financial workflows.

Jobs never contain business logic.

Their responsibility is limited to:

- selecting records to process
- invoking the appropriate service object
- logging the outcome
- isolating failures so one record never halts an entire batch

Every business decision remains inside the service layer.

---

# Design Principles

Every background job follows the same architecture.

- One job orchestrates one workflow.
- Jobs never calculate financial values.
- Jobs never mutate models directly.
- Jobs delegate all business rules to service objects.
- Jobs continue processing after individual failures.
- Jobs produce structured logs for operational visibility.

---

# Job Catalogue

## GenerateDailyProfitsJob

### Responsibility

Processes every active investment and generates one day's profit.

### Workflow

1. Find active investments.
2. Iterate using `find_each`.
3. Call `GenerateDailyProfitService`.
4. Log the outcome.
5. Continue processing regardless of individual failures.

### Delegates To

`GenerateDailyProfitService`

### Business Logic

None.

---

## CompleteInvestmentsJob

### Responsibility

Completes investments that have reached their end date.

### Workflow

1. Find active investments.
2. Iterate using `find_each`.
3. Call `CompleteInvestmentService`.
4. Log the outcome.
5. Continue processing remaining investments.

### Delegates To

`CompleteInvestmentService`

### Business Logic

None.

---

# Scheduling

Recurring jobs are configured declaratively in:

```text
config/recurring.yml
```

Current schedule:

| Job | Schedule |
|------|----------|
| GenerateDailyProfitsJob | Daily at 1:00 AM |
| CompleteInvestmentsJob | Daily at 2:00 AM |

The completion job intentionally runs after profit generation so that an investment receives its final day's profit before principal is returned.

---

# Failure Isolation

Jobs rescue unexpected exceptions on a per-record basis.

Processing continues even if one investment fails.

Example flow:

Investment A

↓

Success

Investment B

↓

Unexpected exception

↓

Logged

↓

Continue

Investment C

↓

Success

No single failure can halt an entire batch.

---

# Logging

Jobs emit three categories of log entries.

### Success

Business operation completed successfully.

Logged as:

```
INFO
```

---

### Expected Business Failure

Examples:

- investment already completed
- duplicate daily profit
- investment not yet eligible

Logged as:

```
WARN
```

These are expected outcomes handled by the service layer.

---

### Unexpected Failure

Unexpected exceptions are logged as:

```
ERROR
```

The exception is recorded and processing continues.

---

# Performance

Jobs iterate using:

```ruby
find_each
```

Benefits:

- constant memory usage
- suitable for large datasets
- avoids loading every record simultaneously

Associated records are eager-loaded where appropriate to prevent N+1 queries.

---

# Service Ownership

Jobs never duplicate business rules.

| Job | Service |
|------|---------|
| GenerateDailyProfitsJob | GenerateDailyProfitService |
| CompleteInvestmentsJob | CompleteInvestmentService |

Every financial decision belongs to the corresponding service object.

---

# Operational Flow

Recurring Scheduler

↓

Background Job

↓

Service Object

↓

Database Transaction

↓

Financial Records Updated

The scheduler decides **when** work runs.

The job decides **what** records to process.

The service decides **how** the business workflow executes.

---

# Future Expansion

Additional recurring workflows should follow the same pattern.

Examples:

- stale deposit cleanup
- notification delivery
- weekly reports
- audit verification
- archival tasks

Each workflow should receive its own job class.

Business rules should remain inside dedicated service objects.

---

# Architectural Guarantees

The job layer guarantees:

- no duplicated business logic
- memory-safe batch processing
- fault isolation
- structured operational logging
- clear separation between scheduling and business rules

Every background workflow in the application follows the same orchestration-first architecture.