# Agent Task: Build Schiphol Lost & Found System in Alan

## Your Role & Context

You are building a production-grade **Lost & Found Management System** for Schiphol Airport in the Alan platform. This is a demo for the CEO of Kjerner (the company that built Alan), so it must be polished, impressive, and fully functional.

The developer is Travis Arnold, a new Kjerner employee. His online Alan IDE is at:
`https://coder.alan-platform.com/travis_arnold/?folder=/home/coder/project`

You have Chrome browser access to this IDE. You will replace the existing demo model completely and deploy a new, fully working application with dummy data.

---

## Mandatory Reading Before You Start

Read the Alan skill at `/sessions/awesome-funny-shannon/alan-skill/SKILL.md` and all its reference files before writing a single line of code. Pay particular attention to:
- `references/application-language.md` — full syntax reference
- `references/common-patterns.md` — critical gotchas (decimals bug, tab-only rule, reference ordering)
- `references/migrations.md` — migration syntax for the from_empty deploy
- `references/wiring-and-deployment.md` — deploy workflow

**Critical rules you must never forget:**
1. Indentation MUST use tabs, never spaces. Even one space causes a cryptic parse error.
2. Collections that are referenced by other collections MUST be defined first in the model.
3. Every `number` property needs a unit declared in `numerical-types`.
4. Permissions are cumulative — a child permission cannot exceed its parent's.
5. `^` navigates to parent node. From inside a collection entry, `^` goes to root (if the collection is directly under root).

---

## System Overview

The system manages lost items at Schiphol Airport. Key workflows:
1. **Staff** log found items at the L&F desk
2. **Passengers** file loss reports (works without login — anonymous access)
3. **Staff** propose a match between a found item and a loss report
4. **Supervisors** confirm the match after verifying identity, which closes both records
5. **Supervisors** archive items that are never claimed (donate or dispose)

---

## Step 1 — Write the Application Model

Open the file `models/model/application.alan` in the IDE. Select ALL content and replace it entirely with the model below.

**Use the IDE terminal to write the file directly for reliability:**
1. Open terminal in code-server: press Ctrl+` (backtick)
2. Run: `cat > /home/coder/project/models/model/application.alan << 'ALANEOF'`
3. Paste the model content
4. Type `ALANEOF` on a new line and press Enter

Here is the complete `application.alan`:

```
users
	anonymous
	dynamic: .'Users'
		passwords: .'Passwords'
			password-value: .'Data'.'Password'
			password-status: .'Data'.'Active' (
				| active => 'Yes' ( )
				| reset => 'No' ( )
			)
		password-initializer: (
			'Data' = ( )
		)

interfaces

root {
	can-read: any user
	can-update: user

	// ── 1. LOOKUP TABLES ─────────────────────────────────────────────────
	// These must be defined BEFORE Found Items, Loss Reports, and Matches
	// because those collections reference them.

	'Locations': collection ['Location ID'] {
		can-create: user .'Role'?'Admin'
		can-update: user .'Role'?'Admin'
		can-delete: user .'Role'?'Admin'

		'Location ID': text
		'Name': text @identifying
		'Terminal': stategroup (
			'Terminal 2' { }
			'Terminal 3' { }
			'Pier B' { }
			'Pier C' { }
			'Pier D' { }
			'Pier E' { }
			'Pier F' { }
			'Schiphol Plaza' { }
			'Lounges' { }
			'Parking Garage' { }
			'Train Station' { }
			'Arrivals Hall' { }
			'Departures Hall' { }
			'Security' { }
			'Other' { }
		)
		'Zone': text
		'Description': text
	}

	'Categories': collection ['Category ID'] {
		can-create: user .'Role'?'Admin'
		can-update: user .'Role'?'Admin'
		can-delete: user .'Role'?'Admin'

		'Category ID': text
		'Name': text @identifying
		'Retention Days': number 'days' @min: 1 @max: 365
		'Priority': stategroup (
			'Critical' { }
			'High' { }
			'Standard' { }
			'Low' { }
		)
	}

	// ── 2. STAFF ──────────────────────────────────────────────────────────
	// Defined before Users (Users reference Staff)
	// and before Found Items and Matches (which reference Staff)

	'Staff': collection ['Staff ID'] {
		can-create: user .'Role'?'Admin'
		can-update: user .'Role'?'Admin'
		can-delete: user .'Role'?'Admin'

		'Staff ID': text
		'Full Name': text @identifying
		'Email': text @validate: "[^@]+@[^.]+\..+"
		'Phone': text
		'Role': stategroup (
			'Desk Agent' { }
			'Supervisor' { }
			'Admin' { }
		)
		'Active': stategroup (
			'Yes' { }
			'No' { }
		) @default: 'Yes' ( )

		// Reference-set aggregations: count items logged and matches proposed by this staff member
		'Logged Item Refs': reference-set -> downstream ^ .'Found Items'* .'Logged By' = inverse >'Logged By'
		'Items Logged Count': number 'units' = count <'Logged Item Refs'*

		'Proposed Match Refs': reference-set -> downstream ^ .'Matches'* .'Proposed By' = inverse >'Proposed By'
		'Matches Proposed Count': number 'units' = count <'Proposed Match Refs'*
	}

	// ── 3. USERS & PASSWORDS ──────────────────────────────────────────────

	'Users': collection ['User'] {
		can-read: user .'Role'?'Admin'
		          user == ^
		can-create: user .'Role'?'Admin'
		can-delete: user .'Role'?'Admin'

		'User': text
		'Role': stategroup (
			'Desk Agent' { }
			'Supervisor' { }
			'Admin' { }
		)
		'Staff Member': text -> ^ .'Staff'[]
	}

	'Passwords': collection ['User'] {
		can-read: user == ^
		can-update: user .'Role'?'Admin'
		            user == ^

		'User': text
		'Data': group {
			'Password': text
			'Active': stategroup (
				'Yes' { }
				'No' { }
			)
		}
	}

	// ── 4. FOUND ITEMS ────────────────────────────────────────────────────
	// Defined before Matches (Matches reference Found Items)

	'Found Items': collection ['Item ID'] {
		can-read: user
		can-create: user .'Role'?'Desk Agent'
		            user .'Role'?'Supervisor'
		            user .'Role'?'Admin'
		can-update: user .'Role'?'Desk Agent'
		            user .'Role'?'Supervisor'
		            user .'Role'?'Admin'

		'Item ID': text @identifying
		'Category': text -> ^ .'Categories'[]
		'Description': text @description: "Detailed physical description of the item"
		'Color': text
		'Brand or Maker': text
		'Date Found': number 'date' @default: now
		'Location Found': text -> ^ .'Locations'[]
		'Finder Name': text @description: "Name of the person who handed in the item"
		'Logged By': text -> ^ .'Staff'[]
		'Date Logged': number 'date' @default: now
		'Storage Location': text -> ^ .'Locations'[]
		'Photo': file
		'Internal Notes': text

		'Status': stategroup (
			'Logged' { }
			'Matched' {
				'Match ID': text -> ^ ^ .'Matches'[]
			}
			'Returned' {
				'Claimant Name': text
				'Return Date': number 'date'
				'Handled By': text -> ^ ^ .'Staff'[]
			}
			'Donated' {
				'Organisation': text
				'Donation Date': number 'date'
				'Approved By': text -> ^ ^ .'Staff'[]
			}
			'Disposed' {
				'Disposal Date': number 'date'
				'Reason': text
				'Approved By': text -> ^ ^ .'Staff'[]
			}
		)

		// Derived: used by Dashboard to count active (not yet resolved) items
		'Is Active': stategroup (
			'Yes' { }
			'No' { }
		) = switch .'Status' (
			| 'Logged' => 'Yes' ( )
			| 'Matched' => 'Yes' ( )
			| 'Returned' => 'No' ( )
			| 'Donated' => 'No' ( )
			| 'Disposed' => 'No' ( )
		)
	}

	// ── 5. LOSS REPORTS ───────────────────────────────────────────────────
	// Defined before Matches (Matches reference Loss Reports)
	// can-create: any user  allows anonymous passengers to file reports

	'Loss Reports': collection ['Report ID'] {
		can-read: user
		can-create: any user
		can-update: user .'Role'?'Desk Agent'
		            user .'Role'?'Supervisor'
		            user .'Role'?'Admin'

		'Report ID': text @identifying
		'Category': text -> ^ .'Categories'[]
		'Item Description': text
		'Color': text
		'Brand or Maker': text
		'Date Lost': number 'date'
		'Location Lost': text -> ^ .'Locations'[]
		'Flight Number': text
		'Airline': text
		'Date Filed': number 'date' @default: now

		'Contact': group {
			'Full Name': text
			'Email': text @validate: "[^@]+@[^.]+\..+"
			'Phone': text
			'Preferred Language': stategroup (
				'English' { }
				'Dutch' { }
				'German' { }
				'French' { }
				'Spanish' { }
				'Other' { }
			)
		}

		'Status': stategroup (
			'Open' { }
			'In Progress' { }
			'Matched' {
				'Match': text -> ^ ^ .'Matches'[]
			}
			'Resolved' {
				'Resolution Date': number 'date'
				'Notes': text
			}
			'Closed' {
				'Close Reason': stategroup (
					'Passenger Withdrew' { }
					'Time Expired' { }
					'Duplicate Report' { }
				)
			}
		)

		// Derived priority mirrors the category priority — shows urgency in list view
		'Priority': stategroup (
			'Critical' { }
			'High' { }
			'Standard' { }
			'Low' { }
		) = switch >'Category'.'Priority' (
			| 'Critical' => 'Critical' ( )
			| 'High' => 'High' ( )
			| 'Standard' => 'Standard' ( )
			| 'Low' => 'Low' ( )
		)

		// Derived: used by Dashboard to count open reports
		'Is Open': stategroup (
			'Yes' { }
			'No' { }
		) = switch .'Status' (
			| 'Open' => 'Yes' ( )
			| 'In Progress' => 'Yes' ( )
			| 'Matched' => 'No' ( )
			| 'Resolved' => 'No' ( )
			| 'Closed' => 'No' ( )
		)
	}

	// ── 6. MATCHES ────────────────────────────────────────────────────────
	// Links a Found Item to a Loss Report

	'Matches': collection ['Match ID'] {
		can-read: user
		can-create: user .'Role'?'Desk Agent'
		            user .'Role'?'Supervisor'
		            user .'Role'?'Admin'
		can-update: user .'Role'?'Supervisor'
		            user .'Role'?'Admin'

		'Match ID': text @identifying
		'Found Item': text -> ^ .'Found Items'[]
		'Loss Report': text -> ^ .'Loss Reports'[]
		'Proposed By': text -> ^ .'Staff'[]
		'Date Proposed': number 'date' @default: now
		'Match Notes': text

		'Status': stategroup (
			'Proposed' { }
			'Confirmed' {
				'Confirmed By': text -> ^ ^ .'Staff'[]
				'Confirmation Date': number 'date'
				'Identity Document Type': stategroup (
					'Passport' { }
					'Drivers Licence' { }
					'National ID Card' { }
					'Other' { }
				)
				'Document Number': text
				'Claimant Signature': text @description: "Signature reference or confirmation code"
			}
			'Rejected' {
				'Rejected By': text -> ^ ^ .'Staff'[]
				'Rejection Date': number 'date'
				'Rejection Reason': text
			}
		)
	}

	// ── 7. DASHBOARD ─────────────────────────────────────────────────────
	// Summary statistics. @breakout means it only loads when expanded — good performance.

	'Dashboard': group @breakout {
		'Items Currently in Storage': number 'units' = count .'Found Items'* .'Is Active'?'Yes'
		'Open Passenger Reports': number 'units' = count .'Loss Reports'* .'Is Open'?'Yes'
		'Matches Awaiting Confirmation': number 'units' = count .'Matches'* .'Status'?'Proposed'
		'Confirmed Returns': number 'units' = count .'Matches'* .'Status'?'Confirmed'
		'Active Staff Members': number 'units' = count .'Staff'* .'Active'?'Yes'
		'Critical Items in Storage': number 'units' = count .'Found Items'* .'Is Active'?'Yes'
	}
}

numerical-types
	'units'
	'days'
	'date' @date: date
	'minutes' @duration: minutes
```

---

## Step 2 — Update the from_empty Migration

Open `migrations/from_empty/migration.alan` and replace its content with:

```
root = (
	'Locations': collection = { }
	'Categories': collection = { }
	'Staff': collection = { }
	'Users': collection = { }
	'Passwords': collection = { }
	'Found Items': collection = { }
	'Loss Reports': collection = { }
	'Matches': collection = { }
)
```

**Note:** Derived properties (`Is Active`, `Is Open`, `Priority`, `Dashboard`, all reference-sets and their counts) are NOT listed in the migration — Alan recomputes them automatically.

---

## Step 3 — Update Client Settings

Open `systems/client/settings.alan` and ensure it contains at minimum:

```
"application creator": "Kjerner"
"application name": "Schiphol Lost & Found"
"allow anonymous user": enabled
"enable csv actions": enabled
"language": "en"
"engine language": english
```

If the file has other content, preserve existing settings and update/add the lines above.

---

## Step 4 — Ensure Sessions Config is Correct

Open `systems/sessions/config.alan`. It should contain:
```
password-authentication: enabled
```

---

## Step 5 — Build & Fix All Errors

Click **Alan Build** (bottom-left of the IDE).

Read the **Problems** panel (View → Problems or the error count in the status bar). Fix every error before proceeding. Common errors to expect and how to fix them:

- **"expected tab, found space"** — Replace spaces with tabs in the affected line
- **"unknown property"** — Check the property name and navigation path; count `^` carefully
- **"reference target not found"** — The referenced collection may be out of order (moved below the referencing collection)
- **"type mismatch"** — Usually a unit mismatch in numerical types

Repeat Build → Fix until the Problems panel shows 0 errors and 0 warnings.

---

## Step 6 — Deploy Fresh

Click **Alan Deploy** (bottom-left). When prompted for deploy type, select **empty** (this wipes the old demo data and starts fresh — that is intentional).

Wait for the deploy to complete (status updates in the IDE terminal).

---

## Step 7 — First Login & Password Reset

Click **Alan Show** to open the app.

Log in with:
- Username: `root`
- Password: `welcome`

The system will force a password reset. Set a new password for root (something memorable, e.g. `Schiphol2026!`). Note it down.

---

## Step 8 — Enter Dummy Data

Enter ALL of the following data via the app UI. Do it in the ORDER listed — some entries reference earlier ones.

### 8a. Locations (Admin → Locations)

| Location ID | Name | Terminal | Zone | Description |
|-------------|------|----------|------|-------------|
| LOC-001 | Gate D57 Area | Pier D | Airside | Near KLM gates, pre-boarding area |
| LOC-002 | Arrivals Belt 3 | Arrivals Hall | Landside | Baggage carousel 3 |
| LOC-003 | Security Checkpoint T2 | Security | Airside | Passenger security screening zone |
| LOC-004 | Schiphol Plaza Main | Schiphol Plaza | Landside | Central shopping area, ground floor |
| LOC-005 | Business Lounge B-North | Lounges | Airside | KLM Crown Lounge, Pier B north |
| LOC-006 | Gate E18 Waiting Area | Pier E | Airside | Seating area near E18 |
| LOC-007 | Train Station Platform 1 | Train Station | Landside | Intercity platform, level -1 |
| LOC-008 | L&F Desk | Arrivals Hall | Landside | Main Lost & Found counter |
| LOC-009 | Departures Hall T3 | Departures Hall | Landside | Check-in zone, Terminal 3 |

### 8b. Categories (Admin → Categories)

| Category ID | Name | Retention Days | Priority |
|-------------|------|----------------|----------|
| CAT-001 | Passports & ID Documents | 365 | Critical |
| CAT-002 | Electronics - Phones & Tablets | 90 | High |
| CAT-003 | Electronics - Laptops & Cameras | 90 | High |
| CAT-004 | Wallets & Purses | 90 | High |
| CAT-005 | Keys & Access Cards | 60 | High |
| CAT-006 | Clothing & Accessories | 30 | Standard |
| CAT-007 | Luggage & Bags | 90 | Standard |
| CAT-008 | Jewelry & Watches | 180 | High |
| CAT-009 | Medication & Medical Equipment | 30 | Critical |
| CAT-010 | Children's Items & Toys | 30 | Standard |
| CAT-011 | Umbrellas | 14 | Low |
| CAT-012 | Books & Stationery | 14 | Low |

### 8c. Staff (Admin → Staff)

| Staff ID | Full Name | Email | Phone | Role |
|----------|-----------|-------|-------|------|
| S-001 | Emma van der Berg | emma@schiphol.nl | +31-6-1234-5678 | Supervisor |
| S-002 | Lars Janssen | lars@schiphol.nl | +31-6-2345-6789 | Desk Agent |
| S-003 | Aisha Bakker | aisha@schiphol.nl | +31-6-3456-7890 | Desk Agent |
| S-004 | Mark de Vries | mark@schiphol.nl | +31-6-4567-8901 | Admin |
| S-005 | Julia Smit | julia@schiphol.nl | +31-6-5678-9012 | Desk Agent |

### 8d. Users (Admin → Users)

Create these user accounts:

| User | Role | Staff Member |
|------|------|--------------|
| emma | Supervisor | S-001 (Emma van der Berg) |
| lars | Desk Agent | S-002 (Lars Janssen) |
| admin | Admin | S-004 (Mark de Vries) |

After creating each user, you will also need to create their password entries in the **Passwords** collection with Active: Yes.

### 8e. Found Items (Admin → Found Items)

Enter these 10 items, all with Status = **Logged** initially (you will update statuses after creating Matches):

| Item ID | Category | Description | Color | Brand/Maker | Date Found | Location Found | Finder Name | Logged By | Storage Location |
|---------|----------|-------------|-------|-------------|-----------|----------------|-------------|-----------|-----------------|
| ITEM-001 | CAT-001 | Dutch passport found in seat pocket at gate D57, dark blue cover | Blue | N/A | 2026-03-25 | LOC-001 | KLM Boarding Staff | S-002 | LOC-008 |
| ITEM-002 | CAT-002 | Black Samsung Galaxy S24 phone, no case, screen saver with dog photo | Black | Samsung | 2026-03-26 | LOC-003 | Security Officer | S-002 | LOC-008 |
| ITEM-003 | CAT-007 | Large red Samsonite suitcase, broken right wheel, name tag missing | Red | Samsonite | 2026-03-24 | LOC-002 | Baggage Staff | S-003 | LOC-008 |
| ITEM-004 | CAT-004 | Brown leather bifold wallet, contains multiple bank cards, no ID | Brown | Unknown | 2026-03-28 | LOC-004 | Shop Staff | S-002 | LOC-008 |
| ITEM-005 | CAT-006 | Grey Nike hoodie, size L, no name tag | Grey | Nike | 2026-03-27 | LOC-006 | Passenger | S-003 | LOC-008 |
| ITEM-006 | CAT-003 | Apple MacBook Pro 14-inch silver, Amsterdam canal sticker on lid | Silver | Apple | 2026-03-28 | LOC-005 | Lounge Staff | S-001 | LOC-008 |
| ITEM-007 | CAT-008 | Gold wedding ring, inscription inside reads M & A 2019 | Gold | Unknown | 2026-03-29 | LOC-006 | Passenger | S-003 | LOC-008 |
| ITEM-008 | CAT-011 | Black telescopic umbrella, no distinguishing features | Black | Unknown | 2026-03-27 | LOC-007 | Train Staff | S-002 | LOC-008 |
| ITEM-009 | CAT-002 | White Apple AirPods in charging case, Jan K written on case in marker | White | Apple | 2026-03-29 | LOC-003 | Security Officer | S-003 | LOC-008 |
| ITEM-010 | CAT-001 | German passport, black cover, young woman photo, found near train gates | Black | N/A | 2026-03-30 | LOC-007 | Passenger | S-001 | LOC-008 |

### 8f. Loss Reports (Admin → Loss Reports)

Enter these 8 reports, all with Status = **Open** initially:

| Report ID | Category | Description | Color | Date Lost | Location Lost | Flight | Airline | Contact Name | Contact Email | Contact Phone | Language |
|-----------|----------|-------------|-------|-----------|---------------|--------|---------|--------------|---------------|---------------|----------|
| REP-001 | CAT-002 | Black Samsung phone Galaxy S24, lost at security | Black | 2026-03-26 | LOC-003 | KL1045 | KLM | Jan de Wit | jan.dewit@gmail.com | +31-6-8765-4321 | Dutch |
| REP-002 | CAT-003 | MacBook Pro 14 silver, Amsterdam sticker on lid, charger in same bag | Silver | 2026-03-28 | LOC-005 | BA432 | British Airways | Sarah Johnson | s.johnson@gmail.com | +44-79-1234-5678 | English |
| REP-003 | CAT-007 | Large red Samsonite suitcase, right wheel broken | Red | 2026-03-24 | LOC-002 | AF1776 | Air France | Pierre Dubois | p.dubois@mail.fr | +33-6-0123-4567 | French |
| REP-004 | CAT-004 | Brown leather wallet, credit cards and 40 euros cash inside | Brown | 2026-03-28 | LOC-004 | TK1984 | Turkish Airlines | Mehmet Kaya | m.kaya@hotmail.com | +90-555-123-4567 | English |
| REP-005 | CAT-008 | Gold wedding ring, lost while removing at security, initials M and A inside | Gold | 2026-03-29 | LOC-003 | LH456 | Lufthansa | Anna Mueller | a.mueller@gmail.com | +49-152-0123-4567 | German |
| REP-006 | CAT-001 | Dutch passport, left in seat pocket after KLM flight from London Heathrow | Blue | 2026-03-25 | LOC-001 | KL1007 | KLM | Thomas Visser | t.visser@outlook.com | +31-6-8765-0000 | Dutch |
| REP-007 | CAT-002 | White Apple AirPods, Jan K written on case | White | 2026-03-29 | LOC-003 | LO231 | LOT Polish | Jan Kowalski | j.kowalski@gmail.com | +48-501-234-567 | English |
| REP-008 | CAT-001 | German passport, lost during transit from Frankfurt | Black | 2026-03-30 | LOC-007 | LH201 | Lufthansa | Klaus Weber | k.weber@email.de | +49-176-1234-5678 | German |

### 8g. Matches (Admin → Matches)

Create 3 matches:

| Match ID | Found Item | Loss Report | Proposed By | Match Notes |
|----------|-----------|-------------|-------------|-------------|
| MATCH-001 | ITEM-002 | REP-001 | S-001 (Emma) | Category, color, and location all match. Phone model confirmed by description. |
| MATCH-002 | ITEM-006 | REP-002 | S-002 (Lars) | MacBook Pro with Amsterdam sticker — very distinctive, high confidence match. |
| MATCH-003 | ITEM-007 | REP-005 | S-003 (Aisha) | Gold ring with M&A 2019 inscription matches passenger description exactly. |

### 8h. Update Statuses

Now update records to reflect the workflow:

**Confirm MATCH-001** (Status → Confirmed):
- Confirmed By: S-001 (Emma van der Berg)
- Confirmation Date: 2026-03-27
- Identity Document Type: Passport
- Document Number: NL-B4A12345

**Update ITEM-002** → Status: Returned:
- Claimant Name: Jan de Wit
- Return Date: 2026-03-27
- Handled By: S-001

**Update REP-001** → Status: Resolved:
- Resolution Date: 2026-03-27
- Notes: Item returned to passenger after identity verification.

**Update ITEM-003** → Status: Returned:
- Claimant Name: Pierre Dubois
- Return Date: 2026-03-26
- Handled By: S-003

**Update REP-003** → Status: Resolved:
- Resolution Date: 2026-03-26
- Notes: Passenger collected suitcase at L&F desk after identifying it from baggage belt area.

**Update ITEM-006** → Status: Matched (Match ID: MATCH-002)

**Update REP-002** → Status: Matched (Match: MATCH-002)

**Update ITEM-007** → Status: Matched (Match ID: MATCH-003)

**Update REP-005** → Status: In Progress

**Update ITEM-008** → Status: Donated:
- Organisation: Rode Kruis (Red Cross) Schiphol
- Donation Date: 2026-03-28
- Approved By: S-001

---

## Step 9 — Verify & Test

Work through this checklist in the app UI (use Alan Show to open it):

1. **Dashboard:** Open the Dashboard group and confirm all 5 counters show non-zero numbers. Expected: ~5 items in storage, ~5 open reports, 2 proposed matches, 1 confirmed return, 5 active staff.

2. **Found Items list:** Confirm 10 items show. Confirm statuses are a mix (Logged, Matched, Returned, Donated).

3. **Loss Reports list:** Confirm 8 reports with visible Priority labels (Critical for passport reports, High for electronics).

4. **Matches list:** Confirm 3 matches — MATCH-001 Confirmed, MATCH-002 and MATCH-003 Proposed.

5. **Staff list:** Click on Emma van der Berg — confirm `Items Logged Count` and `Matches Proposed Count` show correct numbers.

6. **Reference navigation:** In MATCH-002, click on the Found Item reference — confirm it navigates to ITEM-006. Click the Loss Report reference — confirm it goes to REP-002.

7. **Anonymous filing test:** Open a private/incognito browser window, navigate to the app URL, and attempt to file a new loss report without logging in. It should work.

8. **Permission test:** Log in as `lars` (Desk Agent) — confirm Lars can create Found Items but cannot confirm Matches (that requires Supervisor or Admin).

---

## Step 10 — Done Criteria

You are done ONLY when:
- [ ] Alan Build shows 0 errors
- [ ] All 10 found items are visible in the app
- [ ] All 8 loss reports are visible in the app
- [ ] All 3 matches are visible with correct statuses
- [ ] Dashboard counters are non-zero and correct
- [ ] Anonymous loss report filing works in an incognito window
- [ ] Staff reference-set counts on Emma's profile are correct
- [ ] No JavaScript console errors in the browser when viewing the app

If you encounter build errors at any point, fix them before proceeding to deploy. If you encounter data entry errors (e.g., a reference cannot be found), check that the referenced entry was created first and that the ID matches exactly.

---

## Notes on Handling Errors

**Build error: "cannot resolve reference"** — The navigation path is wrong. Re-read the `^` depth: from inside a collection entry, one `^` reaches root if the collection is directly under root.

**Build error: "already defined"** — Duplicate property name in the same scope. Rename one.

**Build error on reference-set** — The path `^ .'Found Items'* .'Logged By'` must exactly match where the referencing property lives. Verify the collection name and property name match the model exactly.

**UI error: reference dropdown is empty** — The referenced collection has no entries yet. Create entries in the referenced collection first.

**Deploy fails** — Check the IDE terminal output for specific error messages. The most common cause is the migration file being out of sync with the model. If needed, update `migrations/from_empty/migration.alan` to add any missing collections.
