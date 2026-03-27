# PRD Task Breakdown

## Purpose

This document converts [PRD.md](<path_to_your_project>/PRD.md) into an execution-oriented task breakdown for the current codebase.

It is intended to answer:

- what is already implemented
- what still blocks MVP completion
- how work should be split across product, Flutter, API, and QA
- what order the team should execute in

The executable QA checklist lives in [mvp-acceptance-checklist.md](<path_to_your_project>/docs/mvp-acceptance-checklist.md).

## Scope Baseline

### MVP P0 from PRD

- Authentication
- User profile
- Game feed
- Search and filters
- Game detail
- Create game
- Join/request to join
- My games

### P1 from PRD

- Push notifications
- Host approval mode improvements
- In-app chat or contact handoff
- Cancel / leave flow polish
- Reporting / blocking
- Saved filters / favorite venues

## Current Project Status

### Already in repo and usable

- Flutter app shell and main navigation
- Game discovery feed
- Game detail page
- Create game page
- My games page
- Join request review page
- Auth register/login/profile update flow
- API routes for auth, games, join requests, my games, user profile
- Prisma schema and seed data
- Integration tests for auth/profile and join flow
- WSL local debug and Docker API debug setup

### Still incomplete or not production-ready

- Guest-specific browsing policy is not explicitly separated from logged-in preview mode
- Profile completeness and onboarding flow are still thin
- Contact handoff and messaging policy are incomplete
- Push notification delivery is not completed end-to-end
- Reporting / blocking is missing
- Saved filters and favorite venues are missing
- Product-level acceptance checklist is not yet documented per feature

## Workstreams

## 1. Product And Spec

### Goal

Close the gap between PRD intent and current implementation details so engineering is not guessing on edge cases.

### Owner

- PM / Product owner

### Tasks

- Define guest mode behavior:
  - which fields guests can see in feed and detail
  - whether join CTA is hidden or redirects to login
- Freeze the MVP release scope:
  - confirm which P1 items are excluded from the next release
- Define contact visibility policy:
  - when phone number or LINE ID becomes visible
  - what happens for rejected, withdrawn, or cancelled requests
- Define cancellation rules:
  - host cancel game
  - player withdraw
  - what notification or status updates are required
- Define onboarding minimum:
  - required fields at registration
  - optional fields deferred to profile edit
- Lock the MVP assumptions used by QA:
  - guests can browse feed and detail without signing in
  - protected actions show auth-required behavior instead of failing silently
  - in MVP there is no in-app chat
  - contact handoff is limited to authenticated and relevant participants
  - rejected, withdrawn, or cancelled requests do not unlock contact access
  - host cancellation is terminal for new joins
  - approved player withdrawal returns the reserved spot

### Deliverables

- feature scope sheet
- release checklist
- guest/auth/contact policy notes
- executable MVP acceptance checklist

### Exit Criteria

- no open ambiguity on guest access, contact exposure, or cancel flow
- QA can run the acceptance checklist without needing product clarification

## 2. Flutter App

### Goal

Bring the current UI from demo-capable to MVP-complete and reviewable.

### Owner

- Flutter engineer

### Tasks

- Guest and auth UX
  - add explicit unauthenticated states where needed
  - redirect protected actions to sign-in cleanly
  - remove accidental reliance on preview-only seeded user behavior
- Profile and onboarding
  - improve profile defaults and validation
  - make skill level guidance align with PRD definitions
  - clarify preferred city/district editing flow
- Discovery and detail polish
  - verify Taiwan city/district labels and localization direction
  - verify empty state, loading state, and error state copy
  - ensure fee, vacancy, and level filters match PRD wording
- Create and join flows
  - validate field constraints before submit
  - improve host approval mode clarity in UI
  - add clearer withdraw / leave / cancelled state handling
- MVP review readiness
  - browser preview visual check on desktop and mobile width
  - Flutter web debug check
  - widget and integration test expansion around auth and create flows

### Deliverables

- polished Flutter screens for all P0 flows
- updated widget tests
- acceptance screenshots or review notes

### Exit Criteria

- a reviewer can complete discover, create, join, approve/reject, and profile flows without hidden setup knowledge

## 3. API And Domain Logic

### Goal

Make backend behavior consistent with PRD rules and safe for MVP launch.

### Owner

- API engineer

### Tasks

- Auth and profile hardening
  - verify register rules require at least one of email or phone
  - verify `/auth/me` and `/users/me` response shape is stable
  - review LINE login fallback and local-dev behavior
- Games domain
  - verify create/update/status constraints
  - verify date and timezone logic for Taiwan use case
  - verify `availableSpots` transitions are always transactional
- Join request domain
  - verify AUTO vs MANUAL behaviors fully match PRD
  - verify approve/reject/withdraw edge cases
  - verify host-only access for join request review
- Me endpoints
  - verify joined vs created list semantics
  - verify cancelled or completed games behavior
- Operational readiness
  - keep debug scripts and test scripts aligned
  - add missing route/service tests for uncovered edge cases

### Deliverables

- stable API behavior for all P0 flows
- expanded integration coverage
- documented edge-case decisions

### Exit Criteria

- no known inconsistency between PRD rules and API behavior on P0 features

## 4. Infra And Dev Experience

### Goal

Keep local development, preview, and testing reproducible for every engineer.

### Owner

- Infra / full-stack engineer

### Tasks

- keep `.env`, docker compose, and debug tasks aligned
- keep shell scripts on LF line endings
- verify WSL local debug setup remains valid
- verify browser preview stack remains usable at `:8080`
- add a short runbook for first-time setup if the team is larger than one engineer

### Deliverables

- stable local debug flow
- stable preview flow
- no hidden machine-specific setup assumptions
- seeded demo runbook linked from the root README and acceptance checklist

### Exit Criteria

- a new engineer can get API, DB, and Flutter web running from docs alone
- a reviewer can launch a seeded demo from the repo root without guessing which script to run

## 5. QA And Acceptance

### Goal

Turn PRD outcomes into a repeatable acceptance checklist instead of ad hoc manual testing.

### Owner

- QA or feature owner

### Tasks

- Build P0 acceptance scenarios:
  - guest browses feed
  - player registers and updates profile
  - host creates game
  - player joins AUTO game
  - player requests MANUAL game
  - host approves and rejects requests
  - player checks My Games
- Add regression checklist for:
  - capacity control
  - duplicate join prevention
  - withdraw behavior
  - unauthenticated access behavior
  - browser preview and Flutter web debug
- Track test data assumptions:
  - seeded accounts
  - seeded games
  - test database reset flow
- Keep acceptance language aligned with [mvp-acceptance-checklist.md](<path_to_your_project>/docs/mvp-acceptance-checklist.md)

### Deliverables

- MVP acceptance checklist
- regression checklist
- test data notes

### Exit Criteria

- every P0 story in PRD maps to at least one executable acceptance scenario
- checklist includes guest browse, auth, create, AUTO join, MANUAL request, approve/reject, withdraw, my games, and preview review path

## Recommended Execution Order

### Phase 1: Spec Lock

- finalize guest behavior
- finalize contact visibility policy
- finalize cancel / withdraw rules

### Phase 2: Backend Rule Hardening

- close auth/profile/game/join edge cases
- fill integration test gaps
- keep API contract stable

### Phase 3: Flutter MVP Finish

- align all user-facing flows with finalized backend behavior
- polish loading, error, and unauthenticated states
- complete mobile and browser review passes

### Phase 4: Acceptance And Release Prep

- execute QA checklist
- verify preview and debug environments
- freeze MVP scope

## Suggested Team Split

### Track A: Product + QA

- guest policy
- contact policy
- cancel policy
- acceptance checklist

### Track B: API + Infra

- domain rule hardening
- test coverage
- local debug and preview reliability

### Track C: Flutter

- auth UX
- create/join/my games polish
- review fixes from QA

## Feature-by-Feature Checklist

| Feature | Current Status | Main Owner | Next Step |
| --- | --- | --- | --- |
| Auth | Partially complete | API + Flutter | align onboarding, validation, guest redirects |
| Profile | Partially complete | Flutter + API | improve completeness and skill-level guidance |
| Game Feed | Usable | Flutter + API | polish filters, empty states, localization |
| Game Detail | Usable | Flutter + API | finalize guest/contact visibility rules |
| Create Game | Usable | Flutter + API | improve validation and acceptance checklist |
| Join / Approval | Usable | API + Flutter | verify all edge cases and cancellation paths |
| My Games | Usable | Flutter + API | verify semantics for all statuses |
| Notifications | Incomplete | API + Flutter | defer or scope tightly as post-MVP |
| Reporting / Blocking | Missing | Product + API | keep out of MVP unless scope changes |
| Saved Filters / Favorites | Missing | Flutter + API | keep out of MVP unless scope changes |

## Definition Of MVP Done

The MVP can be considered done when all of the following are true:

- all P0 stories in `PRD.md` are covered by implemented UI and API behavior
- integration tests cover auth, create, join, approve/reject, withdraw, and my games
- guest and authenticated behavior is clearly defined and implemented
- local debug, preview, and seeded review flows work from documentation
- QA can run through the acceptance checklist without engineer intervention
