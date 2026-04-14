# Roadmap: Schiphol Lost & Found

## Overview

Build a production-grade Lost & Found management system on the Alan platform, starting from a broken repository and ending with a fully deployed, demo-ready application at app.alan-platform.com/Travis_Arnold/client/. Phases follow the strict collection dependency order required by Alan's acyclic reference graph: fix the foundation first, add collections in dependency order, then layer derived values, permissions, seed data, and finally the flights connector as an additive wow-factor integration.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Clean the broken repo and establish a correct structural skeleton
- [ ] **Phase 2: Reference Tables** - Add Locations and Item Categories with a working from_empty migration
- [ ] **Phase 3: Auth + Staff** - Add Users, Passwords, Staff, and configure mixed authentication
- [ ] **Phase 4: Loss Reports** - Add anonymous Loss Report filing as an isolated end-to-end test
- [ ] **Phase 5: Found Items** - Add Found Items with full status workflow and derived active flag
- [ ] **Phase 6: Matches** - Add the Matches terminal collection with confirmation workflow
- [ ] **Phase 7: Dashboard + Derived Values** - Add dashboard counts and Staff reference-set aggregations
- [ ] **Phase 8: Permissions** - Layer role-based permissions across all collections
- [ ] **Phase 9: Demo Data + Deploy** - Seed realistic Schiphol data and verify the live application end-to-end
- [ ] **Phase 10: Flights Connector** - Add the flights API connector as a fully additive external system

## Phase Details

### Phase 1: Foundation
**Goal**: The repository is clean and application.alan has a correct structural skeleton that builds with 0 errors
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05
**Success Criteria** (what must be TRUE):
  1. No src/ directory exists; all Alan project files live at root level (model/, migrations/, wiring/, etc.)
  2. No legacy broken files exist (deploy.sh, alan binary, dist/, old deploy logs)
  3. application.alan contains the four required sections (users, interfaces, root, numerical-types) with no parse errors
  4. numerical-types uses the correct @date: date annotation (not the broken prior format)
  5. versions.json exists at project root with correct platform 2024.2 / datastore v116 / auto-webclient yar.15 / session-manager 31 pins; Alan IDE shows 0 build errors
**Plans**: TBD

### Phase 2: Reference Tables
**Goal**: Locations and Item Categories are defined and navigable in the live app, proving from_empty migration works
**Depends on**: Phase 1
**Requirements**: REF-01, REF-02
**Success Criteria** (what must be TRUE):
  1. Locations collection is visible in the auto-webclient with Terminal stategroup, Zone, and Description fields
  2. Item Categories collection is visible with Retention Days (number 'days') and Priority stategroup (Critical/High/Standard/Low)
  3. from_empty migration runs without errors and the IDE shows a successful deploy
  4. Both collections can be navigated and records can be created/edited in the live app
**Plans**: TBD

### Phase 3: Auth + Staff
**Goal**: Staff can log in with a password, anonymous access is enabled for passengers, and the Staff collection is fully defined
**Depends on**: Phase 2
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, STAFF-01, STAFF-02
**Success Criteria** (what must be TRUE):
  1. Users collection and Passwords collection exist with correct references and role stategroup (Admin/Supervisor/Desk Agent)
  2. Staff collection exists, is defined before Found Items in application.alan, and has all required fields
  3. users section in application.alan includes both anonymous access and dynamic password authentication
  4. session-manager config has password-authentication enabled and client settings allow anonymous login
  5. A staff user can log in via the webclient login form; an unauthenticated visitor can access the anonymous interface
**Plans**: TBD

### Phase 4: Loss Reports
**Goal**: A passenger can file a Loss Report without logging in and see it confirmed in the live app
**Depends on**: Phase 3
**Requirements**: LOSS-01, LOSS-02, LOSS-03, LOSS-04, LOSS-05, LOSS-06
**Success Criteria** (what must be TRUE):
  1. Loss Reports collection exists with all fields: Report ID, Category ref, Description, Color, Brand, Date Lost, Location ref, Flight Number, Airline, Date Filed, Contact group (Name/Email/Phone/Preferred Language)
  2. Status stategroup has all five states: Open, In Progress, Matched, Resolved, Closed (with close reason)
  3. An anonymous (not logged in) user can successfully create a Loss Report via the webclient
  4. Derived Is Open stategroup correctly shows Yes for Open/In Progress and No for Matched/Resolved/Closed
  5. Derived Priority stategroup on Loss Reports reflects the referenced Category's priority value
**Plans**: TBD

### Phase 5: Found Items
**Goal**: Staff can log a found item with a full status workflow visible in the live app
**Depends on**: Phase 4
**Requirements**: ITEM-01, ITEM-02, ITEM-03, ITEM-04
**Success Criteria** (what must be TRUE):
  1. Found Items collection exists with all fields: Item ID, Category ref, Description, Color, Brand, Date Found, Location Found ref, Finder Name, Logged By (Staff ref), Date Logged, Storage Location ref, Photo, Internal Notes
  2. Status stategroup has all five states: Logged, Matched (with Match ID), Returned (with claimant/date/handler), Donated (with org/date/approver), Disposed (with date/reason/approver)
  3. Derived Is Active stategroup correctly shows Yes for Logged/Matched and No for Returned/Donated/Disposed
  4. A logged-in staff member can create a new Found Item entry and set its status in the live app
**Plans**: TBD
**UI hint**: yes

### Phase 6: Matches
**Goal**: A supervisor can propose and confirm a match between a found item and a loss report in the live app
**Depends on**: Phase 5
**Requirements**: MATCH-01, MATCH-02, MATCH-03
**Success Criteria** (what must be TRUE):
  1. Matches collection exists with Match ID, Found Item ref, Loss Report ref, Proposed By (Staff ref), Date Proposed, Match Notes
  2. Status stategroup has three states: Proposed, Confirmed (with Confirmed By/Date/ID Document Type/Document Number), Rejected (with Rejected By/Date/Reason)
  3. A staff member can create a new Match record in the live app
  4. Only Supervisor and Admin roles can update a Match's status (Desk Agent cannot)
**Plans**: TBD

### Phase 7: Dashboard + Derived Values
**Goal**: The dashboard shows live correct counts and Staff records display activity aggregations
**Depends on**: Phase 6
**Requirements**: DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06, DERIV-01, DERIV-02, DERIV-03, DERIV-04
**Success Criteria** (what must be TRUE):
  1. Dashboard group appears as a breakout section in the webclient with all six derived counts visible
  2. Items Currently in Storage count reflects Found Items where Is Active = Yes
  3. Open Passenger Reports count reflects Loss Reports where Is Open = Yes
  4. Matches Awaiting Confirmation and Confirmed Returns counts update when Matches status changes
  5. Each Staff record shows Items Logged Count and Matches Proposed Count that update when related records are added
  6. Found Items display a derived label combining category, location, and description
**Plans**: TBD
**UI hint**: yes

### Phase 8: Permissions
**Goal**: Role-based permissions are enforced across all collections — Admins can do everything, Desk Agents have limited write access, and anonymous users can only file Loss Reports
**Depends on**: Phase 7
**Requirements**: PERM-01, PERM-02, PERM-03, PERM-04, PERM-05, PERM-06
**Success Criteria** (what must be TRUE):
  1. Root-level permissions: any user can read, only logged-in users can update
  2. Only Admin role can create/update/delete Locations, Categories, Staff, and Users
  3. All staff roles (Admin/Supervisor/Desk Agent) can create and update Found Items
  4. Anonymous users can create Loss Reports; only staff can update them
  5. All staff can create Matches; only Supervisor and Admin can update Match status
  6. A user can update their own password; Admins can update any user's password
**Plans**: TBD

### Phase 9: Demo Data + Deploy
**Goal**: The live app is fully deployed with realistic Schiphol seed data and every user workflow verified end-to-end
**Depends on**: Phase 8
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04, DATA-05, DATA-06, DATA-07, DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04, DEPLOY-05, DEPLOY-06, DEPLOY-07
**Success Criteria** (what must be TRUE):
  1. from_empty migration seeds all reference data: 9 Schiphol locations, 12 item categories, 5 Dutch-named staff, 4 users with passwords
  2. from_empty migration seeds 10 Found Items, 8 Loss Reports, and 3 Matches (one confirmed, two proposed) with realistic data
  3. Live app at app.alan-platform.com/Travis_Arnold/client/ is accessible; login with root/welcome works and forces password reset
  4. All collections appear in the webclient navigation after login; Dashboard shows non-zero counts from seed data
  5. An unauthenticated visitor can file a Loss Report without creating an account
  6. Alan IDE shows 0 build errors and 0 deploy errors after fresh "empty" deploy
**Plans**: TBD

### Phase 10: Flights Connector
**Goal**: A flights API connector runs alongside the app and populates a Flights collection with live flight data — no changes to the core application.alan model
**Depends on**: Phase 9
**Requirements**: EXT-01, EXT-02, EXT-03, EXT-04
**Success Criteria** (what must be TRUE):
  1. A connector exists as a scheduled provider system type in the project
  2. Connector fetches flight data from an external API (Schiphol or aviation fallback) and populates a Flights collection
  3. Connector is wired correctly in project.wiring with model binding; Alan IDE shows 0 errors after connector is added
  4. Flight records are visible in the deployed live app alongside lost-and-found data
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/? | Not started | - |
| 2. Reference Tables | 0/? | Not started | - |
| 3. Auth + Staff | 0/? | Not started | - |
| 4. Loss Reports | 0/? | Not started | - |
| 5. Found Items | 0/? | Not started | - |
| 6. Matches | 0/? | Not started | - |
| 7. Dashboard + Derived Values | 0/? | Not started | - |
| 8. Permissions | 0/? | Not started | - |
| 9. Demo Data + Deploy | 0/? | Not started | - |
| 10. Flights Connector | 0/? | Not started | - |
