# Roadmap

This document records the evolution of Venture Capital Investments.

The project has been developed incrementally, with each milestone introducing a cohesive piece of functionality while preserving the architectural principles established from the beginning.

Completed milestones represent production-ready functionality. Planned milestones represent future enhancements rather than unfinished core features.

---

# Guiding Principles

Every milestone follows the same philosophy.

- Small, focused increments
- Test-first development
- Thin controllers
- Service-oriented business logic
- Immutable financial records
- Atomic financial workflows
- Comprehensive automated testing

Each milestone is considered complete only when all tests pass and the architecture remains consistent.

---

# Completed Milestones

## Milestone 1 – Authentication & Wallet Foundation ✅

Established the application's core user infrastructure.

Implemented:

- Devise authentication
- Email confirmation
- Wallet auto-creation
- Member dashboard
- Wallet balances
- Navigation foundation

This milestone created the identity layer required for every subsequent feature.

---

## Milestone 2 – Investment Plans ✅

Introduced investment products available to members.

Implemented:

- InvestmentPlan model
- Investment plan catalogue
- Plan detail pages
- Administrative management foundation

No financial workflows existed yet—plans served as static investment products.

---

## Milestone 3 – Deposit Submission ✅

Introduced the first financial workflow.

Implemented:

- Deposit model
- Member deposit submission
- Bitcoin transaction hash recording
- Deposit status tracking
- Member deposit history

Deposits remained pending until administrative review.

---

## Milestone 4 – Admin Deposit Review ✅

Completed the deposit approval lifecycle.

Implemented:

- Administrator review interface
- Deposit approval
- Deposit rejection
- Audit trail
- Admin notes
- Role-based administration

Approval became the gateway into investment creation.

---

## Milestone 5 – Investment Lifecycle Foundation ✅

Connected deposits to active investments.

Implemented:

- Investment model
- InvestmentCreationService
- Historical plan snapshotting
- Investment tracking

Approved deposits now create investments atomically.

---

## Milestone 6 – Automated Profit Engine ✅

Implemented the platform's financial engine.

Implemented:

- ProfitRecord ledger
- GenerateDailyProfitService
- GenerateDailyProfitsJob
- CompleteInvestmentService
- CompleteInvestmentsJob
- Solid Queue recurring scheduling

The complete investment lifecycle became fully automated.

---

## Milestone 7 – Member Reporting ✅

Added visibility into investment activity.

Implemented:

- Profit history
- Investment performance metrics
- Dashboard portfolio overview
- Wallet activity feed

All reporting is derived from immutable financial records.

---

## Milestone 8 – Automation & Scheduling ✅

Connected background services to recurring execution.

Implemented:

- Declarative recurring schedules
- Automated daily profit generation
- Automated investment completion

No manual intervention is required after deposit approval.

---

## Milestone 9 – Withdrawal Lifecycle ✅

Implemented the complete withdrawal workflow.

Implemented:

- Withdrawal requests
- Fund reservation
- Administrator approval
- Administrator rejection
- Withdrawal completion
- Blockchain transaction recording

BTC remains the sole source of truth throughout the withdrawal lifecycle.

---

## Milestone 10 – Administrative Operations ✅

Improved platform administration and operational tooling.

Implemented:

- Admin operations dashboard
- Platform metrics
- Search
- Pagination
- Investment administration
- Wallet row-level locking
- Platform hardening

The platform is now operationally complete for day-to-day administration.

---

# Current Status

The application now supports the complete investment lifecycle.

```
Registration

↓

Deposit

↓

Admin Review

↓

Investment Creation

↓

Daily Profit

↓

Investment Completion

↓

Withdrawal Request

↓

Admin Approval

↓

Blockchain Payment

↓

Withdrawal Completion
```

Every financial mutation is:

- authenticated
- authorized
- transactional
- audited
- concurrency-safe

---

# Planned Milestones

## Milestone 11 – Communication

Status: In Progress

Planned features:

- Transactional emails
- Deposit notifications
- Withdrawal notifications
- Investment lifecycle notifications
- Background email delivery
- Notification preferences

This milestone improves communication without changing financial workflows.

### Phase 1 — Deposit Notifications

Before adding deposit notification emails, the deposit review workflow was refactored to comply with ADR-013 (see `docs/Decisions.md`, ADR-015): `DepositReviewService` now owns approval/rejection orchestration, and `Deposit#approve!`/`#reject!` are reduced to pure state transitions. This gives the upcoming `DepositMailer` a proper, service-level place to hook into via `deliver_later`, matching how `WithdrawalReviewService` already owns the withdrawal workflow.

Refactor status: ✅ complete, confirmed by full test suite (625 unit/integration + 111 system tests, all passing).
`DepositMailer` (approved/rejected notifications): ✅ implemented and verified (633 unit/integration + 111 system tests, all passing).

### Phase 2 — Withdrawal Notifications

Scoped to the completion transition only (see `docs/Decisions.md`, ADR-016) — approval and rejection are administrative steps, not the moment funds actually move. No orchestration refactor was needed: `CompleteWithdrawalService` already owned the completion transition, so `WithdrawalMailer#completed` was wired directly into it via `deliver_later`.

Status: ✅ implemented and verified (639 unit/integration + 111 system tests, all passing).

### Phase 3 — Investment Completion Notifications

Scoped to the completion transition only (see `docs/Decisions.md`, ADR-017) — daily profit credits are deliberately not emailed individually to avoid notification fatigue, and investment creation is already covered by `DepositMailer#approved` (ADR-015). No orchestration refactor was needed: `CompleteInvestmentService` already owned the completion transition, so `InvestmentMailer#completed` was wired directly into it via `deliver_later`, fired after the wallet lock releases.

The daily-profit digest is explicitly deferred and will be scoped alongside the notification-preferences roadmap item, since cadence (weekly/daily/off) is itself a preference rather than a fixed decision.

Status: ✅ implemented and verified (647 unit/integration + 111 system tests, all passing).

### Milestone 11 Summary

Transactional notifications are complete: deposit approval/rejection (Phase 1), withdrawal completion (Phase 2), and investment completion (Phase 3). Notification preferences and the daily-profit digest remain open, deferred items — see ADR-016 and ADR-017 in `docs/Decisions.md` for the reasoning behind each scoping decision made along the way.

---

## Milestone 12 – Public API (Optional)

Potential future functionality:

- REST API
- API authentication
- JSON serialization
- Rate limiting
- API documentation

This milestone is optional and will only be implemented if external integrations or mobile applications become necessary.

---

## Milestone 13 – Platform Hardening

Planned improvements:

- Two-factor authentication
- Audit logging
- Security headers
- Monitoring
- Error reporting
- Performance optimisation
- Operational tooling

Focus shifts from features to production readiness.

---

## Milestone 14 – Production Deployment

Final production preparation.

Planned work:

- Production deployment
- CI/CD pipeline
- Environment configuration
- SSL
- Backups
- Infrastructure documentation
- Operational runbooks

This milestone marks the transition from development to production.

---

# Future Possibilities

Potential long-term enhancements include:

- Referral programme
- Multi-currency support
- Cryptocurrency price feeds
- Administrative reporting exports
- Investor analytics
- Portfolio charts
- Mobile application
- Public API integrations

These ideas remain intentionally outside the current scope.

---

# Project Philosophy

Features are added only when they preserve the existing architecture.

New functionality should:

- strengthen existing patterns
- avoid duplicating business logic
- remain independently testable
- favour explicitness over cleverness
- preserve financial correctness

Architecture is treated as a long-term asset rather than an afterthought.

---

# Progress Summary

| Milestone | Status |
|------------|--------|
| Milestone 1 – Authentication & Wallet Foundation | ✅ Complete |
| Milestone 2 – Investment Plans | ✅ Complete |
| Milestone 3 – Deposit Submission | ✅ Complete |
| Milestone 4 – Admin Deposit Review | ✅ Complete |
| Milestone 5 – Investment Lifecycle Foundation | ✅ Complete |
| Milestone 6 – Automated Profit Engine | ✅ Complete |
| Milestone 7 – Member Reporting | ✅ Complete |
| Milestone 8 – Automation & Scheduling | ✅ Complete |
| Milestone 9 – Withdrawal Lifecycle | ✅ Complete |
| Milestone 10 – Administrative Operations | ✅ Complete |
| Milestone 11 – Communication | 🔄 In Progress |
| Milestone 12 – Public API (Optional) | 🔶 Optional |
| Milestone 13 – Platform Hardening | ⏳ Planned |
| Milestone 14 – Production Deployment | ⏳ Planned |