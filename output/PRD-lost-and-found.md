# Schiphol Lost & Found — PRD
*Last updated: 2026-04-08*

---

## 1. What we're building

A staff-facing + public-facing Lost & Found management system for Schiphol Airport. Staff log found items; passengers report lost items. The system matches them, tracks status, and closes cases. Built on the Alan platform to demonstrate advanced proficiency.

---

## 2. Users & Roles

| Role | Who they are | What they can do |
|------|-------------|-----------------|
| Anonymous | Any passenger (not logged in) | Submit a lost item report. View their own report via a reference code. |
| Staff | Airport Lost & Found desk employees | Log found items, match reports to found items, update statuses |
| Supervisor | Senior L&F staff | Everything Staff can + escalate unclaimed items (Donate/Dispose), see all stats |
| Admin | System admin | Full access, manage users, manage reference data |

---

## 3. Core Data

### Reference Data (admin-managed)
- **Terminals** — T1, T2, T3, Pier H, Pier D, Pier E, Pier B/C, Schengen Hall, Non-Schengen Hall
- **Locations** — specific spots per terminal (gate, baggage reclaim, security, lounge, toilet, restaurant, etc.)
- **Item Categories** — Electronics, Bags & Luggage, Documents & Cards, Clothing & Accessories, Jewellery, Children's Items, Sports Equipment, Other
- **Item Subcategories** — per category (e.g. Electronics → Phone, Laptop, Headphones, Charger, Tablet, Camera)
- **Airlines** — KLM, Transavia, easyJet, British Airways, Lufthansa, etc. (used in connector)

### Lost Reports (public-facing)
A passenger submits this when they've lost something.

| Field | Type | Notes |
|-------|------|-------|
| Report ID | text (key) | Auto-generated (e.g. LR-20240408-001) |
| Category | reference → Item Categories | |
| Subcategory | reference → Subcategories | filtered to chosen category |
| Description | text (multi-line) | Colour, brand, distinguishing features |
| Location Lost | reference → Locations | Where they think they lost it |
| Date Lost | number 'date' | |
| Flight Number | text | Optional — links to flight connector |
| Passenger Name | text | |
| Contact Email | text | |
| Contact Phone | text | |
| Status | stategroup | Open → Matched → Claimed → Closed |
| Matched Item | optional reference → Found Items | filled when matched |
| Days Open | derived number | today - date lost |

### Found Items (staff-facing)
Staff log this when an item is handed in or found.

| Field | Type | Notes |
|-------|------|-------|
| Item ID | text (key) | Auto-generated (e.g. FI-20240408-001) |
| Category | reference → Item Categories | |
| Subcategory | reference → Subcategories | |
| Description | text (multi-line) | |
| Location Found | reference → Locations | |
| Date Found | number 'date' | |
| Storage Location | text | Where it's physically stored in the L&F office |
| Photo | file | Optional photo of the item |
| Found By (Staff) | reference → Users | Who logged it |
| Flight Number | text | Optional — from connector |
| Airline | derived text | From connector lookup |
| Status | stategroup | Logged → Matched → Claimed → Donated → Disposed |
| Matched Report | optional reference → Lost Reports | inverse of above |
| Days in Storage | derived number | today - date found |

### Statistics (derived, supervisor/admin view)
- Total open lost reports
- Total unmatched found items
- Match rate (% matched)
- Avg days to match
- Items by category (breakdown)
- Items unclaimed > 90 days (disposal candidates)

---

## 4. Commands

| Command | Who | What it does |
|---------|-----|-------------|
| `Match Item to Report` | Staff | Links a Found Item to a Lost Report. Sets both statuses to 'Matched'. Notifies passenger. |
| `Mark as Claimed` | Staff | Passenger collected item. Sets both to 'Claimed'. Closes case. |
| `Escalate: Donate` | Supervisor | Item unclaimed > 90 days. Sets Found Item to 'Donated'. |
| `Escalate: Dispose` | Supervisor | Item unclaimed, damaged, or unsanitary. Sets to 'Disposed'. |
| `Reopen Report` | Staff | Resets a matched/claimed report to 'Open' if match was wrong. |

---

## 5. Connector: Schiphol Flight Info

A simulated connector that, given a flight number, returns:
- Airline name
- Origin/destination
- Terminal

Used to auto-populate airline and terminal info when staff logs a found item or passenger submits a lost report. Since there's no public Schiphol API, we'll simulate this with a stub (static JSON or a simple external endpoint we control).

**Why include it:** Connectors are an advanced Alan feature. Including one — even a stub — shows you understand the full platform architecture.

---

## 6. UI / Annotations

- `@identifying` on Item ID, Report ID, Description (so Alan shows them in reference pickers)
- `@breakout` on Description, Photo, and sub-collections (prevent slow list loading)
- `@small` on subcollections that are always loaded inline
- `@default: now` on date fields
- `@multi-line` on Description fields
- `@validate` on email/phone fields
- Custom theme: Schiphol yellow/dark colour scheme
- Language: English

---

## 7. Permissions Summary

| Collection | Anonymous | Staff | Supervisor | Admin |
|-----------|-----------|-------|-----------|-------|
| Lost Reports | can-create | can-read, can-update | can-read, can-update, can-delete | full |
| Found Items | can-read | can-create, can-update | full | full |
| Users | — | can-read own | can-read | full |
| Reference Data | can-read | can-read | can-read | full |
| Statistics | — | can-read | can-read | full |

---

## 8. Fabricated Seed Data

We'll build a migration-based seed (or manual data entry guide) with:
- 5 terminals / ~20 locations
- 8 categories / ~30 subcategories
- 8 airlines
- 5 users (1 admin, 2 staff, 1 supervisor, 1 test passenger)
- ~15 found items (mix of categories, statuses)
- ~20 lost reports (mix of statuses, some matched to found items)

---

## 9. Out of scope

- Email notifications (connector placeholder only)
- Passenger portal login (anonymous submission is enough)
- Mobile-specific layout (Alan's webclient is responsive by default)
- Real Schiphol API integration

---

*Owner: Travis Arnold | Platform: Alan (Kjerner) | Purpose: Rick/Kjerner demo*
