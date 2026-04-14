# Phase 2: Reference Tables — Pattern Map

**Mapped:** 2026-04-14
**Files analyzed:** 2 (files to be modified)
**Analogs found:** 0 / 2

---

## No Analog Warning

The codebase is a Phase 1 skeleton only. `application.alan` has an empty `root {}`. Both migration files are stubs. There are no existing collections, no seeded migrations, and no completed models to draw patterns from. **Do not invent patterns.** All syntax below comes from `_ref/application-language.md` and `_ref/migrations.md` as verified in RESEARCH.md.

---

## File Classification

| File to Modify | Role | Data Flow | Closest Analog | Match Quality |
|----------------|------|-----------|----------------|---------------|
| `models/model/application.alan` | model | CRUD | none in codebase | no analog — use _ref/ syntax |
| `migrations/from_empty/to/migration.alan` | migration | batch (seed) | none in codebase | no analog — use _ref/ syntax |

---

## Files NOT to Touch

Confirmed read-only for Phase 2:

| File | Current State | Reason to Leave Alone |
|------|--------------|----------------------|
| `migrations/from_empty/from/migration.alan` | `root = root as $ ( )` | Correct "before" stub — from_empty has no prior state |
| `migrations/from_release/from/migration.alan` | `root = root as $ ( )` | No prior deployed model exists |
| `migrations/from_release/to/migration.alan` | `root = root as $ ( )` | Phase 2 deploys with "empty" not "migrate" |
| `wiring/wiring.alan` | Working wiring | No wiring changes needed in Phase 2 |
| `systems/client/settings.alan` | Correct settings | No settings changes needed in Phase 2 |
| `systems/client/annotations.alan` | Empty (intentional) | `@identifying` goes inline in application.alan, not here |
| `systems/sessions/config.alan` | Correct auth config | Auth not relevant to Phase 2 |

---

## Pattern Assignments

### `models/model/application.alan` (model, CRUD)

**Analog:** None. Pattern sourced from `_ref/application-language.md`.

**Current file state** (lines 1-17 — read before editing):
```alan
users
	anonymous

interfaces

root {
}

numerical-types
	'units'
	'days'
	'date' in 'days'
		= 'date-time' + -43200 * 10 ^ 0 in 'seconds'
		@date
	'date-time': time-in-seconds in 'seconds' @date-time
	'seconds' @duration: seconds
```

**What changes:** Replace the empty `root { }` block only. The `users`, `interfaces`, and `numerical-types` sections are correct and must not be touched.

**Collection pattern** (from `_ref/application-language.md`, E-commerce example):
```alan
root {
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
}
```

**Key syntax rules:**
- `collection ['Key Field Name']` — key field in square brackets
- `@identifying` is inline on the property line, no separate block: `'Name': text @identifying`
- Stategroup states use `{ }` (curly braces), not `( )` — the state body is a block
- `number 'days'` — the type name follows `number` with a space; `'days'` is already declared in numerical-types (line 11 of current file)
- Tab indentation throughout — no spaces

---

### `migrations/from_empty/to/migration.alan` (migration, batch/seed)

**Analog:** None. Pattern sourced from `_ref/migrations.md`.

**Current file state** (lines 1-3 — read before editing):
```alan
root = root as $ (
)
```

**What changes:** Replace the entire file content with a seeded migration for both collections.

**Migration pattern** (from `_ref/migrations.md`, seeded from_empty example):
```alan
root = root as $ (
	'Locations': collection = <! !> (
		= (
			'Location ID': text = "LOC001"
			'Name': text = "Departure Hall Terminal 2"
			'Terminal': stategroup = 'Terminal 2' ( )
			'Zone': text = "Departures"
			'Description': text = "Main departure area near check-in"
		)
		= (
			'Location ID': text = "LOC002"
			'Name': text = "Baggage Claim Terminal 1"
			'Terminal': stategroup = 'Terminal 1' ( )
			'Zone': text = "Arrivals"
			'Description': text = "Carousel area, belt 5-12"
		)
		= (
			'Location ID': text = "LOC003"
			'Name': text = "Schiphol Plaza"
			'Terminal': stategroup = 'Schiphol Plaza' ( )
			'Zone': text = "Central"
			'Description': text = "Central hub between terminals"
		)
	)
	'Item Categories': collection = <! !> (
		= (
			'Category ID': text = "CAT001"
			'Name': text = "Travel Documents"
			'Retention Days': number = 365
			'Priority': stategroup = 'Critical' ( )
		)
		= (
			'Category ID': text = "CAT002"
			'Name': text = "Electronics"
			'Retention Days': number = 90
			'Priority': stategroup = 'High' ( )
		)
		= (
			'Category ID': text = "CAT003"
			'Name': text = "Clothing & Bags"
			'Retention Days': number = 60
			'Priority': stategroup = 'Standard' ( )
		)
		= (
			'Category ID': text = "CAT004"
			'Name': text = "Jewellery & Valuables"
			'Retention Days': number = 180
			'Priority': stategroup = 'High' ( )
		)
	)
)
```

**Key syntax rules:**
- `<! !>` is mandatory before `(` on every collection — omitting it causes: `error: expected keyword '<!'' but saw keyword '('`
- Each entry is `= ( ... )` — no key prefix, just `=`
- Key field must be listed first inside each entry
- Stategroup value: `stategroup = 'StateName' ( )` — the trailing `( )` is required even for states with no sub-properties
- Number in migration: `number = 365` (bare — no type annotation). Do NOT write `number 'days' = 365`; the `'days'` annotation belongs only in application.alan
- Tab indentation throughout

---

## Shared Patterns

### Tab Indentation (applies to both files)
**Source:** `CLAUDE.md` project constraint + `_ref/PITFALLS.md` PITFALL 1
**Apply to:** Every line of both modified files
- Alan parser requires hard tabs (`\t`)
- Spaces cause cryptic parse errors unrelated to the actual syntax error location
- Verify with `cat -A filename` if unsure — tabs show as `^I`, spaces as spaces

### No `numerical-types` Changes (applies to application.alan)
**Source:** Current `models/model/application.alan` lines 10-17
**Apply to:** `application.alan` edit
- `'days'` is already declared at line 11
- `'date'`, `'date-time'`, `'seconds'` have complex formula-based definitions
- Editing this section risks breaking the date arithmetic — leave it verbatim

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `models/model/application.alan` | model | CRUD | No existing collections in project; first real model content |
| `migrations/from_empty/to/migration.alan` | migration | batch (seed) | No existing seeded migrations in project; first migration |

Both files must be written from `_ref/` documentation patterns, not from codebase analogs. The complete, verified content for both files is provided in the Pattern Assignments sections above and in RESEARCH.md Code Examples.

---

## Metadata

**Analog search scope:** All `.alan` files in project (10 files found via Glob)
**Files scanned:** 10
**Pattern extraction date:** 2026-04-14
**Codebase maturity:** Phase 1 skeleton — no reusable analogs exist yet

## PATTERNS COMPLETE
