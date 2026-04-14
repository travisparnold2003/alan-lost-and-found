# Phase 2 Context: Reference Tables

**Phase:** 2 — Reference Tables  
**Date:** 2026-04-14  
**Status:** Ready to plan

---

## Phase Goal

Locations and Item Categories are defined and navigable in the live app, proving from_empty migration works.

---

## Canonical Refs

- `.planning/REQUIREMENTS.md` — REF-01, REF-02
- `.planning/ROADMAP.md` — Phase 2 success criteria
- `.planning/research/PITFALLS.md` — migration `<! !>` rule, tab indentation
- `.planning/phases/01-foundation/01-CONTEXT.md` — Phase 1 decisions (tab indentation, numerical-types)
- `_ref/application-language.md` — Alan collection + stategroup syntax
- `_ref/wiring-and-deployment.md` — migration syntax

---

## Decisions

### 1. Locations collection definition

**Fields (exact):**
```
'Locations': collection ['Location ID'] {
    'Location ID': text
    'Name': text @identifying
    'Terminal': stategroup (
        'Terminal 1' { }
        'Terminal 2' { }
        'Terminal 3' { }
        'Pier' { }
        'Schiphol Plaza' { }
        'Train Station' { }
        'Other' { }
    )
    'Zone': text
    'Description': text
}
```

**Terminal stategroup rationale:** Schiphol has 3 terminals (not 4 — old code was wrong). Non-terminal areas (Pier, Plaza, Train Station) are common lost-and-found locations. `'Other'` handles edge cases.

### 2. Item Categories collection definition

**Fields (exact):**
```
'Item Categories': collection ['Category ID'] {
    'Category ID': text
    'Name': text @identifying
    'Retention Days': number 'days'
    'Priority': stategroup (
        'Critical' { }
        'High' { }
        'Standard' { }
        'Low' { }
    )
}
```

**Priority order:** Critical → High → Standard → Low (descending urgency, matches REQUIREMENTS REF-02).

### 3. Collection ordering in application.alan

**Decision:** Locations before Item Categories.

**Why:** Item Categories has no references to other collections, so ordering between the two doesn't technically matter. Alphabetical or domain-logical order both work. Locations first matches the dependency order for later phases (Found Items references both).

### 4. from_empty migration: minimal seed data

**Decision:** Seed 3 Locations + 4 Item Categories in the from_empty migration for Phase 2.

**Why:** Confirms migration `<! !>` syntax is correct AND gives visible records in the live app to verify Phase 2 deployed correctly. Full 9 locations / 12 categories added in Phase 9.

**Seed Locations (3):**
```
LOC001 | Departure Hall Terminal 2 | Terminal 2 | Departures | Main departure area near check-in
LOC002 | Baggage Claim Terminal 1  | Terminal 1 | Arrivals   | Carousel area, belt 5-12
LOC003 | Schiphol Plaza           | Schiphol Plaza | Central | Central hub between terminals
```

**Seed Item Categories (4):**
```
CAT001 | Travel Documents  | 365 | Critical
CAT002 | Electronics       |  90 | High
CAT003 | Clothing & Bags   |  60 | Standard
CAT004 | Jewellery & Valuables | 180 | High
```

**Migration syntax reminder (CRITICAL):**
- Every collection requires `<! !>` before `(` or `none`
- Tabs only — no spaces
- Stategroup values: `stategroup = 'Terminal 2' ( )`
- Number with type: `number 'days' = 365`

### 5. from_release migration

**Decision:** from_release/from stays as empty `root = root as $ ( )`. from_release/to also stays empty — there is no prior deployed model to migrate forward from. We will deploy fresh with "empty".

### 6. No annotations.alan changes needed

**Decision:** Leave `systems/client/annotations.alan` untouched. The `@identifying` annotation in application.alan is sufficient for the auto-webclient to show Name as the primary label. No custom phrases needed for Phase 2.

---

## Pre-answered (carried from Phase 1)

- **Tab indentation ONLY** — spaces cause cryptic parse errors
- **numerical-types unchanged** — correct formula-based format, no edits
- **wiring untouched** — working, no changes needed for Phase 2
- **versions.json untouched** — correct pins

---

## Success Criteria (from ROADMAP.md)

1. Locations collection visible in auto-webclient with Terminal stategroup, Zone, Description
2. Item Categories collection visible with Retention Days (number 'days') and Priority stategroup
3. from_empty migration runs without errors, IDE shows successful deploy
4. Both collections navigable and records can be created/edited in the live app

---

## Deferred Ideas

None raised during discussion.
