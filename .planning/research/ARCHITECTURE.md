# Architecture: Alan Lost & Found Application

**Domain:** Alan model-driven platform application
**Researched:** 2026-04-14
**Confidence:** HIGH (derived from direct analysis of platform syntax docs, current model, migration reference, and connector reference in _ref/)

---

## Collection Dependency Graph

The Alan rule is hard: **referenced collections must be defined before referencing collections**.
References flow one way — the graph must be acyclic at the definition-order level.

```
Users (no deps)
  └──> Passwords (refs Users)

Locations (no deps)

Item Categories (no deps)

Staff (refs Users)
  └──> Found Items (refs Item Categories, Locations, Staff)
        └──> Matches (refs Found Items, Loss Reports, Staff)

Loss Reports (refs Item Categories, Locations) [no Staff ref — anonymous]
  └──> Matches (refs Found Items, Loss Reports, Staff)

Dashboard (refs Found Items, Loss Reports, Matches via derived counts)
```

**Cycle check:** No cycles. Matches is the terminal node — it references upward but nothing references Matches (except via reference-sets on Found Items / Loss Reports).

---

## Required Definition Order in application.alan

Collections must appear in this exact sequence inside `root { }`:

```
1. Locations             (no refs to other collections)
2. Item Categories       (no refs to other collections)
3. Users                 (no refs to other collections)
4. Passwords             (refs Users)
5. Staff                 (refs Users)
6. Loss Reports          (refs Item Categories, Locations — no Staff ref needed for anonymous filing)
7. Found Items           (refs Item Categories, Locations, Staff)
8. Matches               (refs Found Items, Loss Reports, Staff)
9. Dashboard group       (derived counts — no new refs, but must come after the counted collections)
```

**Why Loss Reports before Found Items:** Loss Reports has no Staff reference (anonymous filing). Found Items does. Defining Loss Reports earlier keeps its dependency surface minimal and matches the logical model (a report can exist before any item is logged). Matches needs both, so it comes last.

**Why Staff before Found Items (not Users):** Found Items references `Logged By` which should point to Staff, not Users. Staff references Users (for login identity linkage). This means Staff sits between Users/Passwords and Found Items in the order.

---

## Users Block Design

The application requires **mixed authentication**: staff log in with passwords; passengers file loss reports without any account.

```alan
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
```

**Critical:** `anonymous` must be present. Without it, the Loss Reports creation form is inaccessible to passengers. The current model in application.alan is missing `anonymous`.

---

## Collection Designs

### Locations (Position 1)

No dependencies. Simple lookup table for airport zones.

```alan
'Locations': collection ['Location ID'] {
    'Location ID': text
    'Name': text @identifying
    'Terminal': stategroup (
        'Terminal 1' { }
        'Terminal 2' { }
        'Terminal 3' { }
        'Terminal 4' { }
        'Non-Schengen' { }
        'Landside' { }
    )
    'Zone': text
    'Description': text
}
```

### Item Categories (Position 2)

No dependencies. Drives retention policy and priority inheritance in Found Items.

```alan
'Item Categories': collection ['Category ID'] {
    'Category ID': text
    'Name': text @identifying
    'Retention Days': number 'days'
    'Priority': stategroup (
        'Low' { }
        'Standard' { }
        'High' { }
        'Critical' { }
    )
}
```

### Users (Position 3)

Authentication identity only. Staff collection provides role/operational data.

```alan
'Users': collection ['User'] {
    'User': text
    'Full Name': text @identifying
    'Email': text @validate: "[^@\\s]+@[^@\\s]+\\.[^@\\s]+"
    'Active': stategroup (
        'Yes' { }
        'No' { }
    )
}
```

**Note:** Role moves to Staff. Users is kept minimal — it is the authentication identity record only.

### Passwords (Position 4)

References Users. Required by the `dynamic:` users block.

```alan
'Passwords': collection ['User'] {
    'User': text -> ^ .'Users'[]
    'Data': group {
        'Password': text
        'Active': stategroup (
            'Yes' { }
            'No' { }
        )
    }
}
```

### Staff (Position 5)

References Users (for login linkage). Carries role, operational data, and reference-sets for activity tracking.

```alan
'Staff': collection ['Staff ID'] {
    'Staff ID': text
    'User Account': text -> ^ .'Users'[]
    'Full Name': text @identifying
    'Role': stategroup (
        'Admin' { }
        'Supervisor' { }
        'Desk Agent' { }
    )
    'Active': stategroup (
        'Yes' { }
        'No' { }
    )
    // Reference sets (defined after Found Items and Matches exist)
    'Items Logged': reference-set -> downstream ^ .'Found Items'* .'Logged By'
        = inverse >'Logged By'
    'Matches Proposed': reference-set -> downstream ^ .'Matches'* .'Proposed By'
        = inverse >'Proposed By'
    // Derived activity counts from reference sets
    'Items Logged Count': number 'units' = count <'Items Logged'*
    'Matches Proposed Count': number 'units' = count <'Matches Proposed'*
}
```

**Important:** Reference-sets on Staff use `downstream` and point forward to Found Items and Matches. These reference-sets are computed automatically — no migration entry needed. They appear in the Staff definition, but their correctness depends on Found Items and Matches being present in the same model.

### Loss Reports (Position 6)

References Item Categories and Locations. **No Staff reference** — filed anonymously.

```alan
'Loss Reports': collection ['Report ID'] {
    'Report ID': text
    'Category': text -> ^ .'Item Categories'[]
    'Description': text @identifying
    'Color': text
    'Brand': text
    'Date Lost': number 'date'
    'Date Filed': number 'date'
    'Location Lost': text -> ^ .'Locations'[]
    'Flight Number': text
    'Airline': text
    'Contact': group {
        'Name': text
        'Email': text @validate: "[^@\\s]+@[^@\\s]+\\.[^@\\s]+"
        'Phone': text
        'Language': stategroup (
            'English' { }
            'Dutch' { }
            'Other' { }
        )
    }
    'Status': stategroup (
        'Filed' { }
        'Matched' { }
        'Returned' { }
        'Closed' { }
    )
}
```

### Found Items (Position 7)

References Item Categories, Locations, and Staff (for `Logged By`).

```alan
'Found Items': collection ['Item ID'] {
    'Item ID': text
    'Category': text -> ^ .'Item Categories'[]
    'Description': text @identifying
    'Color': text
    'Brand': text
    'Location Found': text -> ^ .'Locations'[]
    'Location Stored': text -> ^ .'Locations'[]
    'Date Found': number 'date'
    'Date Logged': number 'date'
    'Finder Name': text
    'Logged By': text -> ^ .'Staff'[]
    'Photo': file
    'Internal Notes': text
    'Status': stategroup (
        'Logged' { }
        'Stored' { }
        'Matched' { }
        'Returned' { }
        'Donated' { }
        'Disposed' { }
    )
    // Priority inherited from Category
    'Priority': stategroup ( 'Low' { } 'Standard' { } 'High' { } 'Critical' { } )
        = switch >'Category'.'Priority' (
            | 'Low' => 'Low' ( )
            | 'Standard' => 'Standard' ( )
            | 'High' => 'High' ( )
            | 'Critical' => 'Critical' ( )
        )
}
```

**Note on Status:** The current model has only `Logged`, `Stored`, `Returned`. PROJECT.md requires `Matched`, `Donated`, `Disposed` as well. These must be added.

### Matches (Position 8)

References Found Items, Loss Reports, and Staff. Terminal collection in the dependency graph.

```alan
'Matches': collection ['Match ID'] {
    'Match ID': text
    'Found Item': text -> ^ .'Found Items'[]
    'Loss Report': text -> ^ .'Loss Reports'[]
    'Proposed By': text -> ^ .'Staff'[]
    'Date Proposed': number 'date'
    'Match Notes': text
    'Status': stategroup (
        'Proposed' { }
        'Confirmed' {
            'Confirmed By': text -> ^ ^ .'Staff'[]
            'Date Confirmed': number 'date'
        }
        'Rejected' {
            'Rejected By': text -> ^ ^ .'Staff'[]
            'Date Rejected': number 'date'
            'Rejection Reason': text
        }
    )
}
```

**Note:** `^ ^` navigates out of the state node and then out of the Matches entry to reach root. This is correct for intra-state references. The current model uses `^ ^` correctly here.

### Dashboard Group (Position 9)

Derived counts only. No base properties — nothing to migrate. Uses `@breakout` for performance (only queries when section is viewed).

```alan
'Dashboard': group @breakout {
    'Total Found Items': number 'units' = count ^ .'Found Items'*
    'Total Loss Reports': number 'units' = count ^ .'Loss Reports'*
    'Open Found Items': number 'units'
        = count ^ .'Found Items'* .'Status'?'Logged'
    'Items In Storage': number 'units'
        = count ^ .'Found Items'* .'Status'?'Stored'
    'Open Loss Reports': number 'units'
        = count ^ .'Loss Reports'* .'Status'?'Filed'
    'Pending Matches': number 'units'
        = count ^ .'Matches'* .'Status'?'Proposed'
}
```

---

## Numerical Types Block

The current model has a broken `'date'` definition using a conversion expression. The correct pattern (from application-language.md) is:

```alan
numerical-types
    'units'
    'days'
    'date' @date: date
```

**Do not use** `'date' in 'days' = 'date-time' + ...`. That conversion syntax is for defining arithmetic rules between units (e.g., product types), not for date formatting. Use `@date: date` annotation directly on the type.

---

## Permission Hierarchy Design

Alan permissions use `can-read` and `can-update` annotations at collection or root level. The three roles are Admin, Supervisor, and Desk Agent (all on Staff).

### Permission Pattern

```
can-read:   any user (anonymous can view categories, locations for filing)
can-update: depends on role and context
```

### Root Level

```alan
root {
    can-read: any user
    can-update: user .'Staff'?'Active'?'Yes'   // only active staff can update anything at root
```

Note: `can-update` at root level is the fallback. Collection-level permissions override this.

### Collection-Level Permissions

| Collection | Read | Create | Update |
|---|---|---|---|
| Locations | any user | Admin only | Admin only |
| Item Categories | any user | Admin only | Admin only |
| Users | authenticated (own entry) | Admin only | Admin only |
| Passwords | system (via auth) | system | system |
| Staff | authenticated staff | Admin only | Admin or self |
| Loss Reports | anonymous (own entry via contact) | any user | Staff (Supervisor+) |
| Found Items | authenticated staff | Desk Agent+ | Desk Agent (own) + Supervisor+ |
| Matches | authenticated staff | Desk Agent+ | Supervisor+ for confirm/reject |
| Dashboard | authenticated staff | n/a (derived) | n/a (derived) |

### Permission Syntax Examples

```alan
// Loss Reports — anonymous can create, staff can read all
'Loss Reports': collection ['Report ID'] {
    can-read: user .'Role'?'Admin'
              user .'Role'?'Supervisor'
              user .'Role'?'Desk Agent'
    can-update: user .'Role'?'Supervisor'
                user .'Role'?'Admin'
    // Note: anonymous creation requires the collection itself to allow anonymous writes
```

**Limitation to flag:** Alan's anonymous permission model controls whether anonymous users can create entries. Verify exact syntax for anonymous-create vs anonymous-read during phase execution. The `common-patterns.md` shows role-based patterns but not anonymous-create specifically.

---

## Migration Strategy

### First Deploy: from_empty with Seed Data

The application should deploy as a clean first install with pre-seeded demo data. The `from_empty` migration runs once on first deploy.

**Seed data required:**

| Collection | Entries to seed |
|---|---|
| Locations | 8-10 realistic Schiphol zones (Departure Hall 1, Gate D, Baggage Claim, etc.) |
| Item Categories | 6-8 categories (Electronics, Documents, Clothing, Bags, Jewellery, Keys, Other) |
| Users | 3-5 staff accounts (admin, supervisor, desk agents) |
| Passwords | Matching entries for each User with hashed passwords |
| Staff | 3-5 staff profiles linked to Users |
| Found Items | 5-8 demo items in various statuses |
| Loss Reports | 4-6 demo reports in various statuses |
| Matches | 2-3 demo matches (one confirmed, one proposed, one rejected) |

**Migration skeleton:**

```alan
root = root as $ (
    'Locations': collection = <! !> (
        = ( 'Location ID': text = "LOC001"  'Name': text = "Departure Hall 1" ... )
        = ( 'Location ID': text = "LOC002"  'Name': text = "Gate D" ... )
    )
    'Item Categories': collection = <! !> (
        = ( 'Category ID': text = "CAT001"  'Name': text = "Electronics"
            'Retention Days': number = 90
            'Priority': stategroup = 'High' ( ) )
    )
    'Users': collection = <! !> (
        = ( 'User': text = "admin"  'Full Name': text = "Admin User"
            'Email': text = "admin@schiphol.nl"  'Active': stategroup = 'Yes' ( ) )
    )
    'Passwords': collection = <! !> (
        = ( 'User': text = "admin"
            'Data': group = (
                'Password': text = "travis2003"
                'Active': stategroup = 'Yes' ( )
            ) )
    )
    'Staff': collection = <! !> (
        = ( 'Staff ID': text = "STF001"  'User Account': text = "admin"
            'Full Name': text = "Admin User"  'Role': stategroup = 'Admin' ( )
            'Active': stategroup = 'Yes' ( ) )
    )
    'Loss Reports': collection = <! !> ( )
    'Found Items': collection = <! !> ( )
    'Matches': collection = <! !> ( )
)
```

**Critical rules:**
- Every collection needs `<! !>` before `( )` — even empty ones
- Stategroup values: `stategroup = 'StateName' ( )`
- Group values: `group = ( ... )`
- Nested collections also need `<! !>`
- Key field must be first field in each entry
- Derived properties (Priority on Found Items, reference-sets on Staff, Dashboard counts) are NOT in migration — they recompute automatically

### Subsequent Deploys: from_release

After the first deploy, every model change requires a `from_release` migration. Generate it via `Alan: Generate Migration` in the IDE Command Palette. The auto-generated mapping handles unchanged properties; only additions, renames, and restructures need manual intervention.

---

## Connector Integration: Flights API

The flights API connector is Phase 10 (final phase). It is a **scheduled provider** that pulls live Schiphol flight data on a schedule and exposes it as a read-only dataset alongside the Lost & Found model.

### Integration Pattern

The connector sits outside the main model. It provides a `Flights` interface that the application can read.

**Connector type:** `provider scheduled` — polls an external flights API (e.g., Schiphol Public API or a mock) on a fixed interval (every 5 minutes).

**What it surfaces:**
- Flight number
- Airline
- Origin/destination
- Scheduled and actual times
- Terminal/gate

**How it connects to Lost Items:** Loss Reports already have `'Flight Number': text` and `'Airline': text` fields. The connector adds a `Flights` collection (read-only, provided by the connector) that staff can reference or view in context. No foreign key relationship is required in the model — the flight fields on Loss Reports are free text, which is appropriate since a passenger filing a report may not know the exact flight number format in the system.

**Connector location in file structure:**

```
systems/
  flights-connector/
    processor.alan        (scheduled provider, HTTP fetch, yield dataset)
    variables.alan        (API key, base URL)
    interface.alan        (shape of the Flights dataset)
```

**Wiring entry:**

```
systems
    'flights-connector': @'"systems/flights-connector"'
        mapping (
            'model': @'model'
        )
```

**Build order implication:** The connector is built and wired after the core model is complete and deployed. Adding it does not require changes to application.alan — it is an additive external system. This is why it is deferred to Phase 10.

---

## Build Order (Phase Sequence Rationale)

This order respects the dependency graph, manages risk, and produces a deployable application at each phase.

| Phase | What to Build | Why This Order |
|---|---|---|
| 1 | Fix users block (add anonymous), fix numerical-types, verify clean build | Foundation — everything else breaks if users block or types are wrong |
| 2 | Locations + Item Categories with seed data | No dependencies, easiest to get right, proves from_empty migration works |
| 3 | Users + Passwords + Staff with seed data | Auth layer — needed before Found Items can have a valid `Logged By` ref |
| 4 | Loss Reports (anonymous creation) | No Staff dep, tests anonymous access path in isolation |
| 5 | Found Items (staff-only) | Depends on Categories, Locations, Staff all being correct |
| 6 | Matches collection | Depends on Found Items and Loss Reports both being deployed and working |
| 7 | Dashboard group with derived counts | Depends on all operational collections |
| 8 | Reference-sets on Staff + activity counts | Depends on Found Items and Matches existing in the model |
| 9 | Permissions layer (role-based access) | Added last — easier to verify correctness when data is already populated |
| 10 | Flights API connector | Standalone additive system, does not touch core model |

---

## Known Issues in Current application.alan

| Issue | Location | Impact | Fix |
|---|---|---|---|
| Missing `anonymous` in users block | users block, line 1 | Passengers cannot file Loss Reports | Add `anonymous` before `dynamic:` |
| No Staff collection | Missing entirely | Found Items `Logged By` points to Users (wrong) | Add Staff collection at position 5 |
| `Logged By` refs Users not Staff | Found Items | Breaks intended role separation | Change ref to `^ .'Staff'[]` |
| `Proposed By` refs Users not Staff | Matches | Same issue | Change ref to `^ .'Staff'[]` |
| `Confirmed By` / `Rejected By` refs Users | Matches states | Same issue | Change refs to `^ ^ .'Staff'[]` |
| Found Items Status missing states | Found Items | Missing Matched, Donated, Disposed | Add to stategroup |
| Broken numerical-types for date | numerical-types | May cause parse errors | Replace with `'date' @date: date` |
| No permission blocks | Entire model | All users can read/write everything | Add can-read/can-update annotations |
| No reference-sets on Staff | Missing | No activity tracking counts | Add after Staff defined |
| Dashboard missing Pending Matches count | Dashboard | Incomplete metrics | Add count for Matches Proposed state |

---

## Quality Gate Verification

- [x] Collection ordering is dependency-correct — verified against definition order above
- [x] Reference graph is cycle-free — Matches is terminal, no collection references back to Matches
- [x] Build order respects dependencies — each phase only introduces collections whose dependencies are already deployed
- [x] Permission model is consistent — roles live on Staff, checked via `user` navigation
