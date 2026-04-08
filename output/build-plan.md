# Schiphol Lost & Found — Build Plan (Revised)
*Last updated: 2026-04-08 (Session 2 — revised to match richer project-spec)*

---

## Overview

6 phases. Each phase produces a working (deployable) app.
Every phase ends with: Build → Generate Migration → Deploy → Test → commit to GitHub.

The model follows `_ref/project-spec.md` as the authoritative spec.

---

## Phase 1b — Foundation Rebuild ← CURRENT

**Why 1b?** Phase 1 deployed with wrong collection names (Airlines, Terminals, Item Categories). Since data is empty, we replace the whole model cleanly with an "empty" deploy.

**Goal:** Core lookup tables matching the spec schema.

**Model:**
```
root {
  'Locations'  collection ['Location ID'] — name, terminal (stategroup), zone, description
  'Categories' collection ['Category ID'] — name, retention days, priority (stategroup)
}
```

**Files:**
- `models/model/application.alan` — replace with new schema
- `migrations/from_empty/migration.alan` — empty collections (no seeding)
- `migrations/from_release/from/application.alan` — reset to empty stub

**Deploy:** "empty" (data is empty anyway, safe to wipe)

**Done when:** App deploys, Locations and Categories are visible in nav.

---

## Phase 2 — Staff + Users + Auth

**Goal:** Working login system with three roles. Staff directory.

**Model adds:**
```
'Staff'     collection ['Staff ID'] — full name, email, phone, role stategroup, active stategroup
'Users'     collection ['User']     — role stategroup, staff member ref
'Passwords' collection ['User']     — Data group (password text, active stategroup)
```

**Users block changes:**
```
users
  anonymous
  dynamic: .'Users'
    passwords: .'Passwords'
      password-value: .'Data'.'Password'
      password-status: .'Data'.'Active' ( active => 'Yes' | reset => 'No' )
    password-initializer: ( 'Data' = ( ) )
```

**Permissions:**
- Root: `can-read: any user`, `can-update: user`
- Locations/Categories: `can-create/update/delete: user .'Role'?'Admin'`
- Users: `can-read/create/delete: user .'Role'?'Admin'` + `can-read: user == ^`
- Passwords: `can-read/update: user .'Role'?'Admin'` + `user == ^`

**Files:**
- `application.alan` — add Staff, Users, Passwords; update users block; add permissions
- `sessions/config.alan` — enable password-authentication
- `migrations/from_release/migration.alan` — pass through Phase 1b + add 3 empty collections

**Deploy:** "migrate"

**Done when:** Login screen appears. Can create admin user, log in, see Staff list.

---

## Phase 3 — Found Items + Loss Reports

**Goal:** The two core operational collections. Full rich schema from spec.

**Model adds:**
```
'Found Items'  collection ['Item ID'] — category, description, color, brand, date found,
                                        location found/storage, finder name, logged by (staff ref),
                                        photo (file), internal notes,
                                        Status stategroup (Logged/Matched/Returned/Donated/Disposed),
                                        Is Active derived stategroup

'Loss Reports' collection ['Report ID'] — category, description, color, brand, date lost/filed,
                                          location lost, flight number, airline (text),
                                          Contact group (name, email, phone, language),
                                          Status stategroup (Open/In Progress/Matched/Resolved/Closed),
                                          Priority derived from category,
                                          Is Open derived stategroup
```

**Permissions:**
- Found Items: `can-read: user`, `can-create/update: user .'Role'?'Desk Agent'` (+ Supervisor + Admin)
- Loss Reports: `can-read: user`, `can-create: any user` (anonymous passengers), `can-update: user` (staff)

**Files:**
- `application.alan` — add Found Items, Loss Reports
- `migrations/from_release/migration.alan` — pass through all + 2 new empty collections

**Deploy:** "migrate"

**Done when:** Staff can log a found item. Anyone (anonymous) can file a loss report.

---

## Phase 4 — Matches

**Goal:** Link Found Items ↔ Loss Reports. Confirmation workflow.

**Model adds:**
```
'Matches' collection ['Match ID'] — found item ref, loss report ref, proposed by (staff ref),
                                    date proposed, match notes,
                                    Status stategroup (Proposed / Confirmed / Rejected)
                                    — Confirmed state: confirmed by, date, ID doc type, doc number, signature
                                    — Rejected state: rejected by, date, rejection reason
```

**Permissions:**
- `can-read: user`
- `can-create: user .'Role'?'Desk Agent'` (+ Supervisor + Admin)
- `can-update: user .'Role'?'Supervisor'` (+ Admin) — only supervisors confirm/reject

**Files:**
- `application.alan` — add Matches
- `migrations/from_release/migration.alan`

**Deploy:** "migrate"

**Done when:** Staff can propose a match. Supervisor can confirm/reject.

---

## Phase 5 — Dashboard + Staff Reference Sets + UI Polish

**Goal:** Live stats, staff productivity counts, Schiphol branding.

**Model adds:**
- `Dashboard`: group @breakout with 6 derived counts
- Staff gets reference-sets + counts: `'Logged Item Refs'`, `'Items Logged Count'`, `'Proposed Match Refs'`, `'Matches Proposed Count'`

**UI polish:**
- `@breakout` on Dashboard, descriptions, long text fields
- `@default: now` on date fields
- `@validate` on email fields
- `@identifying` on name fields
- `@description` on complex fields

**Settings:**
- `systems/client/settings.alan` — confirm name is "Schiphol Lost & Found"

**Files:**
- `application.alan` — add Dashboard group + Staff reference-sets
- `migrations/from_release/migration.alan`
- `systems/client/settings.alan`

**Deploy:** "migrate"

**Done when:** Dashboard shows live counts. Staff profile shows items logged + matches proposed.

---

## Phase 6 — Connector: Flight Info Lookup

**Goal:** Enter a flight number → connector fills in Airline name.

**Plan:**
- Add `'Flight Lookup'` group to Found Items with `'Airline Lookup'` derived/connector field
- Create `systems/flight-connector/` with processor that watches for Flight Number changes
- Wire in `wiring.alan`
- Use a stub/mock endpoint

**Files:**
- `application.alan`, `wiring.alan`, new connector system

**Deploy:** "migrate"

**Done when:** Entering a flight number auto-fills the airline.

---

## Phase 7 — Seed Data

**Goal:** Populate with realistic dummy data (from `_ref/project-spec.md` Step 8).

**Enter via UI in this order:**
1. Locations (9 entries)
2. Categories (12 entries)
3. Staff (5 entries)
4. Users (3 entries) + Passwords
5. Found Items (10 entries)
6. Loss Reports (8 entries)
7. Matches (3 entries)
8. Update statuses (return/confirm/resolve records as per spec)

**Done when:** Dashboard shows non-zero counters. App looks like a real system.

---

## File Change Summary

| Phase | Files Changed |
|-------|--------------|
| 1b | application.alan, from_empty/migration.alan, from_release/from/application.alan |
| 2 | application.alan, from_release/migration.alan, sessions/config.alan |
| 3 | application.alan, from_release/migration.alan |
| 4 | application.alan, from_release/migration.alan |
| 5 | application.alan, from_release/migration.alan, settings.alan |
| 6 | application.alan, wiring.alan, new connector system |
| 7 | Data entry (no code changes) |

---

## Deploy Sequence (every phase)

```
1. Edit application.alan (and other files) locally
2. git commit + push
3. IDE: git pull
4. Alan Build → fix errors until " 0  0"
5. Alan: Generate Migration (Command Palette) → select from_release
6. Review + edit migration.alan (add new empty collections)
7. Alan Deploy → "migrate" (or "empty" for Phase 1b)
8. Navigate to app URL, verify
9. git commit + push final state
```

---

## Status

- [x] Phase 1  — Wrong schema, empty data (superseded by 1b)
- [x] Phase 1b — Foundation rebuild 
- [x] Phase 2  — Staff + Users + Auth
- [ ] Phase 3  — Found Items + Loss Reports
- [ ] Phase 4  — Matches
- [ ] Phase 5  — Dashboard + Polish
- [ ] Phase 6  — Connector
- [ ] Phase 7  — Seed Data

---

*Owner: Travis Arnold | Revised: 2026-04-08*
