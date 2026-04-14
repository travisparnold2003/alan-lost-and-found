# Schiphol Lost & Found

## What This Is

A production-grade Lost & Found management system for Schiphol Airport, built on the Alan platform (model-driven declarative platform by Kjerner). Staff log found items, passengers file loss reports anonymously, supervisors confirm matches and authorize returns. This is a demo project to impress Rick (CEO of Kjerner/Alan) and prove Travis can build real Alan applications.

## Core Value

A fully working, deployed Alan application that demonstrates genuine understanding of Alan's patterns (collections, references, derived values, permissions, migrations, seed data) with realistic Schiphol airport data.

## Requirements

### Validated

(None yet -- ship to validate)

### Active

- [ ] Locations collection with terminal/zone/description fields
- [ ] Item Categories collection with retention days and priority levels
- [ ] Staff collection (separate from Users) with role-based access
- [ ] Users and Passwords collections for authentication
- [ ] Found Items collection with references to Categories, Locations, Staff
- [ ] Loss Reports collection with anonymous filing (no login required)
- [ ] Matches collection linking Found Items to Loss Reports
- [ ] Dashboard with live derived counts (items in storage, open reports, pending matches)
- [ ] Rich status workflows (Found Items: Logged/Matched/Returned/Donated/Disposed)
- [ ] Reference-sets on Staff for activity tracking (items logged count, matches proposed count)
- [ ] Derived stategroups (Is Active, Is Open, Priority inheritance from Category)
- [ ] Role-based permissions (Admin/Supervisor/Desk Agent)
- [ ] Mixed authentication (anonymous for passengers, password for staff)
- [ ] Pre-seeded demo data via from_empty migration (locations, categories, staff, users, items, reports, matches)
- [ ] External flights API connector for live flight data alongside lost items
- [ ] Full Playwright-automated deploy to live app at alan-platform.com

### Out of Scope

- Custom webclient views -- use auto-generated UI only
- Email notifications -- Alan connectors could do this but it's beyond demo scope
- Multi-language UI -- English only
- Mobile-specific layouts -- desktop auto-webclient is sufficient
- Real passenger data -- all data is fictional demo data

## Context

- **Platform:** Alan platform v2024.2, datastore v116, auto-webclient yar.15, session-manager v31
- **IDE:** Online IDE at coder.alan-platform.com/Travis_Arnold/
- **Live app:** app.alan-platform.com/Travis_Arnold/client/
- **GitHub:** github.com/travisparnold2003/alan-lost-and-found
- **Prior state:** Phase 0 was deployed (basic Locations, anonymous access). Subsequent agent attempts expanded the model but never successfully deployed beyond Phase 0. 20+ "fix" commits in git history from failed agent attempts.
- **Structural issue:** Repo had files duplicated in both src/ and root-level dirs. Decision: restructure to root-level only.
- **Reference docs:** Local _ref/ folder has Alan syntax docs but some may be outdated. Must verify against live alan-platform.com docs before building.
- **Rick connection:** Rick is CEO of Kjerner (company behind Alan). Travis is a new employee. This demo is to prove competence with the platform.

## Constraints

- **Platform:** Alan platform only -- no custom JS, no external databases, no React. Everything must be expressible in Alan's declarative model language.
- **Deploy target:** Must deploy and work at the live URL (app.alan-platform.com/Travis_Arnold/client/)
- **Tabs only:** Alan parser requires tab indentation. Spaces cause cryptic parse errors.
- **Collection ordering:** Referenced collections must be defined before referencing collections in application.alan.
- **No booleans:** Alan has no boolean type. Use stategroup ('Yes' {} 'No' {}) instead.
- **Migration syntax:** All collections in migration.alan require `<! !>` before `( )` or `none`.
- **IDE workflow:** Edit locally, git push, IDE git pull, Alan Build (must show 0 errors), Alan Deploy.
- **versions.json:** Must exist at project root for Alan extension to detect the project.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Full spec architecture (Staff + Users separate) | Shows understanding of Alan patterns like reference-sets and derived values. More impressive for Rick. | -- Pending |
| Anonymous Loss Reports + password auth for staff | Realistic airport scenario: passengers shouldn't need accounts to file a report. Demonstrates Alan's mixed auth. | -- Pending |
| Restructure repo to root-level (no src/ wrapper) | Eliminates copy step in IDE. Alan Build reads from root-level dirs directly. | -- Pending |
| Clean sweep of old broken files | 20+ failed agent commits created confusion. Fresh start from known-good state. | -- Pending |
| Pre-seeded demo data | App needs to look alive and impressive for Rick's demo. Empty app is underwhelming. | -- Pending |
| Include flights API connector (Phase 10) | Rick's "wow factor". Shows Alan can integrate with external systems. Higher complexity but worth the impression. | -- Pending |
| Deploy with "empty" (fresh start) | No valuable data to preserve. Clean deploy eliminates migration issues from broken prior state. | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -- still the right priority?
3. Audit Out of Scope -- reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-14 after initialization*
