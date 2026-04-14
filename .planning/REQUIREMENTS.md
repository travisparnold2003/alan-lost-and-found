# Requirements: Schiphol Lost & Found

**Defined:** 2026-04-14
**Core Value:** A fully working, deployed Alan application that demonstrates genuine understanding of Alan's patterns with realistic Schiphol airport data.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Foundation

- [ ] **FOUND-01**: Project restructured to root-level layout (no src/ wrapper)
- [ ] **FOUND-02**: Old broken files cleaned up (deploy logs, dist/, deploy.sh, alan binary)
- [ ] **FOUND-03**: application.alan has correct four-section structure (users/interfaces/root/numerical-types)
- [ ] **FOUND-04**: numerical-types uses correct @date: date annotation format
- [ ] **FOUND-05**: versions.json at project root with correct version pins (platform 2024.2, datastore 116, auto-webclient yar.15, session-manager 31)

### Reference Data

- [ ] **REF-01**: Locations collection with Location ID, Name, Terminal (stategroup), Zone, Description
- [ ] **REF-02**: Item Categories collection with Category ID, Name, Retention Days (number 'days'), Priority (stategroup: Critical/High/Standard/Low)

### Authentication

- [ ] **AUTH-01**: Users collection with username, role stategroup (Admin/Supervisor/Desk Agent), reference to Staff
- [ ] **AUTH-02**: Passwords collection with reference to Users, Data group (Password text, Active stategroup)
- [ ] **AUTH-03**: users section with both anonymous and dynamic password authentication
- [ ] **AUTH-04**: Session manager config with password-authentication enabled
- [ ] **AUTH-05**: Client settings with anonymous login enabled (for passenger access)

### Staff

- [ ] **STAFF-01**: Staff collection (separate from Users) with Staff ID, Full Name, Email, Phone, Role, Active status
- [ ] **STAFF-02**: Staff collection defined before Found Items and Matches in application.alan (collection ordering)

### Found Items

- [ ] **ITEM-01**: Found Items collection with Item ID, Category reference, Description, Color, Brand, Date Found, Location Found reference, Finder Name
- [ ] **ITEM-02**: Found Items has Logged By reference to Staff, Date Logged, Storage Location reference, Photo (file), Internal Notes
- [ ] **ITEM-03**: Found Items Status stategroup with states: Logged, Matched (with Match ID ref), Returned (with claimant/date/handler), Donated (with org/date/approver), Disposed (with date/reason/approver)
- [ ] **ITEM-04**: Derived 'Is Active' stategroup on Found Items (Yes for Logged/Matched, No for Returned/Donated/Disposed)

### Loss Reports

- [ ] **LOSS-01**: Loss Reports collection with Report ID, Category reference, Description, Color, Brand, Date Lost, Location Lost reference
- [ ] **LOSS-02**: Loss Reports has Flight Number, Airline, Date Filed, Contact group (Name, Email, Phone, Preferred Language stategroup)
- [ ] **LOSS-03**: Loss Reports Status stategroup: Open, In Progress, Matched (with Match ref), Resolved (with date/notes), Closed (with close reason stategroup)
- [ ] **LOSS-04**: Anonymous users can create Loss Reports without logging in (can-create: any user)
- [ ] **LOSS-05**: Derived 'Is Open' stategroup (Yes for Open/In Progress, No for Matched/Resolved/Closed)
- [ ] **LOSS-06**: Derived Priority stategroup inherited from referenced Category's priority

### Matches

- [ ] **MATCH-01**: Matches collection with Match ID, Found Item reference, Loss Report reference, Proposed By (Staff ref), Date Proposed, Match Notes
- [ ] **MATCH-02**: Matches Status stategroup: Proposed, Confirmed (with Confirmed By/Date/ID Document Type/Document Number), Rejected (with Rejected By/Date/Reason)
- [ ] **MATCH-03**: Only Supervisors and Admins can update Match status (can-update permission)

### Dashboard

- [ ] **DASH-01**: Dashboard group at root level with @breakout annotation
- [ ] **DASH-02**: Derived count: Items Currently in Storage (Found Items where Is Active = Yes)
- [ ] **DASH-03**: Derived count: Open Passenger Reports (Loss Reports where Is Open = Yes)
- [ ] **DASH-04**: Derived count: Matches Awaiting Confirmation (Matches where Status = Proposed)
- [ ] **DASH-05**: Derived count: Confirmed Returns (Matches where Status = Confirmed)
- [ ] **DASH-06**: Derived count: Active Staff Members (Staff where Active = Yes)

### Derived Values

- [ ] **DERIV-01**: Reference-set on Staff for items logged (inverse of Found Items.'Logged By')
- [ ] **DERIV-02**: Reference-set on Staff for matches proposed (inverse of Matches.'Proposed By')
- [ ] **DERIV-03**: Count aggregation on Staff reference-sets (Items Logged Count, Matches Proposed Count)
- [ ] **DERIV-04**: Derived display label on Found Items via concat (category + location + description summary)

### Permissions

- [ ] **PERM-01**: Root level: can-read any user, can-update user (logged in)
- [ ] **PERM-02**: Admin-only: create/update/delete Locations, Categories, Staff, Users
- [ ] **PERM-03**: All staff roles: create/update Found Items
- [ ] **PERM-04**: Anonymous + all staff: create Loss Reports; staff-only update
- [ ] **PERM-05**: All staff: create Matches; Supervisor/Admin only: update Matches
- [ ] **PERM-06**: Passwords: user can update own; Admin can update any

### Demo Data

- [ ] **DATA-01**: from_empty migration seeds 9 Locations (Schiphol terminals, piers, plaza, train station)
- [ ] **DATA-02**: from_empty migration seeds 12 Item Categories (passports, electronics, clothing, luggage, jewelry, medication, etc.)
- [ ] **DATA-03**: from_empty migration seeds 5 Staff members (Dutch names, schiphol.nl emails, mixed roles)
- [ ] **DATA-04**: from_empty migration seeds 4 Users + Passwords (root admin + 3 staff accounts, all with password reset)
- [ ] **DATA-05**: from_empty migration seeds 10 Found Items (realistic descriptions, mixed statuses)
- [ ] **DATA-06**: from_empty migration seeds 8 Loss Reports (realistic passenger reports, mixed statuses)
- [ ] **DATA-07**: from_empty migration seeds 3 Matches (one confirmed, two proposed)

### External Integration

- [ ] **EXT-01**: Flights connector as scheduled provider system type
- [ ] **EXT-02**: Connector fetches flight data from external API (Schiphol or aviation API)
- [ ] **EXT-03**: Flights collection or group populated by connector with flight number, airline, origin, destination, status
- [ ] **EXT-04**: Connector wired correctly in project.wiring with model binding

### Deployment

- [ ] **DEPLOY-01**: Application builds with 0 errors in Alan IDE
- [ ] **DEPLOY-02**: Application deploys successfully with "empty" (fresh seed data)
- [ ] **DEPLOY-03**: Live app accessible at app.alan-platform.com/Travis_Arnold/client/
- [ ] **DEPLOY-04**: Login works with root/welcome (forced password reset)
- [ ] **DEPLOY-05**: All collections visible in navigation after login
- [ ] **DEPLOY-06**: Anonymous loss report filing works without login
- [ ] **DEPLOY-07**: Dashboard shows correct non-zero counts from seed data

## v2 Requirements (Deferred)

- Derived match confidence score (complex multi-field arithmetic)
- Is Overdue flag based on retention date comparison (needs 'today' workaround)
- Email/SMS notifications via connector
- Custom webclient views
- Multi-language UI
- Photo upload management
- Return shipping label printing
- Duplicate item deduplication

## Out of Scope

- Custom CSS/JS -- auto-webclient only, per PROJECT.md
- Real passenger data / GDPR compliance -- fictional demo data only
- Mobile-specific layouts -- auto-webclient is adequate
- Email notifications -- high complexity, low Alan-specific value
- Full-text search -- rely on platform's native collection filtering

## Traceability

<!-- Updated by roadmapper -->

| Requirement | Phase | Status |
|-------------|-------|--------|
| (populated by roadmap) | | |
