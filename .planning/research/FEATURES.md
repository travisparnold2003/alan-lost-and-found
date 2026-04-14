# Feature Landscape — Schiphol Lost & Found (Alan Platform)

**Domain:** Airport Lost & Found Management System
**Researched:** 2026-04-14
**Platform constraint:** Everything must be expressible in Alan's declarative model. No custom JS. Auto-generated webclient only.

---

## Table Stakes

Features users expect from any credible L&F system. Missing = product feels incomplete or unprofessional.

| Feature | Why Expected | Complexity | Alan Pattern |
|---------|--------------|------------|--------------|
| Found item logging | Core function — staff log what's found | Low | Collection with text, number 'date', stategroup for status |
| Item status workflow | Items move through lifecycle (Logged → Matched → Returned / Donated / Disposed) | Low | Stategroup on Found Items with nested state properties |
| Loss report filing | Passengers need to report what they've lost | Low | Separate collection, anonymous access for passengers |
| Item categorisation | Classify by type (Electronics, Clothing, Documents, etc.) with different retention rules per category | Low | Categories collection referenced by Found Items |
| Location tracking | Record where item was found (Terminal, Gate, Zone) | Low | Locations collection with terminal/zone fields |
| Staff identity on items | Who logged it, who confirmed the match | Low | Reference to Staff collection; @default: user for auto-assign |
| Match confirmation workflow | Supervisor reviews match, authorises return | Medium | Matches collection linking Found Items to Loss Reports; status stategroup on Match |
| Retention period enforcement | Categories define how long items are kept (e.g. valuables: 90 days, food: 1 day) | Medium | Derived date on Found Item = logged date + category retention days; derived stategroup 'Is Overdue' |
| Dashboard with live counts | Items in storage, open reports, pending matches — managers need this at a glance | Medium | Derived counts at root level using count + filter patterns |
| Role-based access | Admin / Supervisor / Desk Agent see and can do different things | Medium | Permissions using user stategroup roles; can-read/can-update per collection |
| Item description fields | Colour, brand, distinguishing marks — without this matching is impossible | Low | Text fields + stategroup for colour/type where dropdown-style UX needed |
| Anonymous passenger access | Passengers must file reports without creating accounts | Low | Mixed auth: anonymous + password. Loss Reports under anonymous access |

---

## Differentiators

Features that go beyond what's expected. These are the ones that show Alan mastery and impress Rick.

| Feature | Value Proposition | Complexity | Alan Pattern | Rick Impact |
|---------|-------------------|------------|--------------|-------------|
| Derived priority inheritance | Found Item auto-inherits priority level from its Category (e.g. Passport = High, Newspaper = Low) — no manual entry | Low | Derived stategroup via switch on referenced category's priority field | Shows reference + derived values chaining |
| Derived 'Is Overdue' flag | System auto-flags items past their retention deadline — no manual checking | Medium | Derived stategroup = switch (today - logged date) compare (category.'Retention Days') — requires 'today' workaround or static threshold | Shows derived stategroup based on numeric comparison |
| Reference-sets for staff activity tracking | Staff profile shows count of items logged, matches proposed, matches confirmed — live, auto-calculated | Medium | reference-set on Staff collection, then count aggregation | Directly demonstrates Alan's unique reference-set + derived aggregate pattern — rarely seen |
| Flights API connector | Live Schiphol flight data displayed alongside lost items — passengers link items to their flight | High | Connector with HTTP interface, wiring, processor.alan | "Wow factor" — shows Alan's full-stack integrations. Rick explicitly wanted this per PROJECT.md |
| Derived match confidence score | Auto-computed match quality: same category + same location zone + date overlap = higher score | High | Derived number on Matches using switch + add on matching criteria | Shows complex multi-field derived arithmetic |
| Supervisor-only match confirmation | Match can only be finalised by a Supervisor or Admin — prevents desk agents approving their own items | Low | can-update on Match 'Status' field: user .'Role'?'Supervisor' or .'Role'?'Admin' | Clean permission pattern demonstration |
| Item count by category dashboard | Live breakdown of storage occupancy — "12 Electronics in storage, 3 Documents past retention" | Medium | count with filter by category reference + status filter | Shows filtered aggregation across cross-referenced collections |
| Pre-seeded realistic Schiphol demo data | App launches with real-feeling data: Terminal 1 locations, KLM flight items, Dutch staff names, plausible item descriptions | Medium | from_empty migration with seed data; requires careful migration.alan construction | Makes demo convincing in 30 seconds. Empty app = zero impression |
| Derived label on Found Item | Auto-computed display name like "Blue Passport – Gate D7 – KL447" combining category, location, and description | Low | Derived text = concat fields | Small touch but makes auto-webclient table views instantly readable |
| Loss report status propagation | When a match is confirmed, Loss Report auto-updates to 'Matched' status — passenger could check status | Medium | Derived stategroup on Loss Report = switch on existence of confirmed Match referencing it, via reference-set | Shows inverse reference-set driving a derived state |

---

## Anti-Features

Things to deliberately NOT build for this demo. Scope discipline matters — these would cost time without adding Alan-specific impressiveness.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Email/SMS notifications to passengers | Alan connectors could do this but it requires connector setup, external SMTP/Twilio wiring, and secrets management. High complexity, low Alan-specific value | Show match status via read-only Loss Report status in the app — passengers could query it |
| Custom webclient views / CSS | PROJECT.md explicitly out of scope. Auto-webclient is the point — it proves Alan generates real UI | Use @identifying, @breakout, @small, @description annotations to make auto-UI as clean as possible |
| Photo uploads on items | Alan supports `file` type but the demo data is all text-based; photo management adds infrastructure noise | Use detailed text descriptions + colour stategroup instead |
| Multi-language support | English only per PROJECT.md | — |
| Real passenger data / GDPR features | Demo data only. Real data handling is a compliance rabbit hole | Use fictional names and plausible but fake flight numbers |
| Return shipping label printing | Requires external printing integration, not an Alan pattern demonstration | Return is marked in system by status change — staff handles physical handover |
| Duplicate found items deduplication | Would require complex matching logic; overkill for demo | Staff training on lookup before logging covers this operationally |
| Mobile-specific UI | Auto-webclient is desktop-optimised; mobile is adequate as-is | Use @breakout on detail sections to keep list views clean |
| Complex search / full-text search | Alan's auto-webclient has built-in filter/search on collections | Rely on platform's native collection filtering |

---

## Feature Dependencies

```
Categories (with retention days, priority) 
    → Found Items (references Categories)
        → Matches (references Found Items)
            → Loss Reports (referenced by Matches)
                → derived 'Is Matched' on Loss Report

Locations (terminal, zone, description)
    → Found Items (references Locations)

Users + Passwords
    → Staff (references Users for auth identity)
        → Found Items (logged by Staff reference)
        → Matches (confirmed by Staff reference)
        → reference-sets on Staff for activity counts

Flights API Connector (Phase 10 / optional)
    → Found Items (optional flight reference text field)
```

---

## MVP (Phase-Ordered) Recommendation

### Must-ship (app is not real without these)
1. Locations collection — terminal/zone/description
2. Categories collection — name, retention days, priority stategroup
3. Found Items collection — with references to Categories and Locations, status workflow, date logged
4. Loss Reports collection — anonymous filing, contact text fields, item description
5. Staff + Users + Passwords collections — role-based access
6. Matches collection — links Found Item to Loss Report, confirmation status
7. Dashboard derived counts at root — items in storage, open reports, pending matches
8. Pre-seeded demo data — makes the app feel alive

### Build after core works (Alan mastery demonstration layer)
9. Reference-sets on Staff for activity counts — count of items logged, matches confirmed
10. Derived 'Is Overdue' on Found Items — retention enforcement
11. Derived priority inheritance from Category to Found Item
12. Derived label on Found Item (concat display name)
13. Loss Report derived status from confirmed Match (via reference-set)
14. Supervisor-only match confirmation permissions

### Defer until core is stable (high complexity, optional wow)
15. Flights API connector — highest impression value but highest risk; build last
16. Derived match confidence score — complex arithmetic; adds value but not required

---

## Alan Pattern Opportunities Summary

This is the view Rick will evaluate the code through. Each pattern demonstrates Alan mastery.

| Pattern | Where Used | Why It Impresses |
|---------|------------|-----------------|
| Mixed authentication (anonymous + password) | Passengers vs Staff | Realistic; not every Alan app needs this |
| reference-set + count aggregation | Staff activity tracking | Alan's unique bidirectional inverse — rarely used by beginners |
| Derived stategroup from collection filter | 'Is Matched' on Loss Report | nodes/none pattern; shows declarative reactive state |
| Derived stategroup from numeric comparison | 'Is Overdue' on Found Items | switch compare — shows derived logic beyond simple lookups |
| Chained derived values (category → item) | Priority inheritance | Demonstrates reference navigation in derived expressions |
| Role-based can-update on specific field | Supervisor-only match confirmation | Granular permission model; shows business rule enforcement |
| Commands for locked user assignment | Logging items auto-assigns current staff | Shows command pattern vs @default |
| concat derived text | Found Item display label | Small but makes auto-webclient significantly more readable |
| HTTP connector + wiring | Flights API | Full-stack integration; shows Alan beyond just data modelling |
| from_empty migration with seed data | Demo data | Shows migration file fluency — often where beginners get stuck |

---

## Sources

- [Schiphol Lost and Found Service (actual system)](https://schiphollostandfound.com/org/ams)
- [How to Choose Lost and Found Software for Your Airport — 24/7 Software](https://www.247software.com/blog/how-to-choose-lost-and-found-software-for-your-airport)
- [Lost and Found Software for Airports: 5 Things to Look For — RepoApp](https://www.repoapp.com/lost-and-found-software-for-airports-blog/)
- [The Ultimate Guide to Lost and Found Software — LiffHappens](https://www.liffhappens.com/the-ultimate-guide-to-lost-and-found-software/)
- [ReclaimHub — Lost Property Management Software](https://reclaimhub.com/)
- [Lostings — Airport Lost and Found Inventory Management](https://www.lostings.com/airport-lost-and-found-software/)
- Alan Platform skill reference: `_ref/alan-skill-readme.md`, `_ref/application-language.md`, `_ref/common-patterns.md`
- Project context: `.planning/PROJECT.md`
