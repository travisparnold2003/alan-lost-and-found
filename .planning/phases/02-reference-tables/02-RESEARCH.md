# Phase 2: Reference Tables — Research

**Researched:** 2026-04-14
**Domain:** Alan application.alan collection syntax + from_empty migration seeding
**Confidence:** HIGH — all findings verified against _ref/ docs and current codebase files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

1. **Locations collection** — exact field spec locked (Location ID key, Name @identifying, Terminal stategroup with 7 states, Zone text, Description text)
2. **Item Categories collection** — exact field spec locked (Category ID key, Name @identifying, Retention Days number 'days', Priority stategroup Critical/High/Standard/Low)
3. **Collection ordering** — Locations before Item Categories in application.alan
4. **Seed data** — 3 Locations + 4 Item Categories in from_empty/to/migration.alan
5. **from_release migration** — stays as empty `root = root as $ ( )` — no prior deployed model
6. **annotations.alan unchanged** — @identifying in application.alan is sufficient, no custom phrases
7. **Tab indentation only** — no spaces, no exceptions
8. **Wiring untouched** — no wiring changes in Phase 2
9. **versions.json untouched** — correct pins, no changes
10. **numerical-types unchanged** — already correct, no edits

### Claude's Discretion

None identified in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)

None raised during discussion.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REF-01 | Locations collection with Location ID, Name, Terminal (stategroup), Zone, Description | Syntax verified in application-language.md; stategroup format confirmed; @identifying placement confirmed |
| REF-02 | Item Categories collection with Category ID, Name, Retention Days (number 'days'), Priority (stategroup: Critical/High/Standard/Low) | number 'days' syntax confirmed; 'days' numerical type already in current application.alan; migration number syntax confirmed |
</phase_requirements>

---

## Summary

Phase 2 adds two reference table collections to application.alan and seeds them via from_empty migration. All syntax decisions are already locked in CONTEXT.md and verified by the _ref/ documentation in this session.

The current application.alan is a clean skeleton: 4 correct sections (users/interfaces/root/numerical-types), root is empty, and the numerical-types block already includes `'days'` — which means `number 'days'` on Retention Days will resolve immediately with zero additional changes to numerical-types.

The from_empty/to/migration.alan is the primary risk surface. It currently contains only `root = root as $ ( )` and must be expanded with two seeded collections. The `<! !>` rule and the stategroup value syntax in migrations are the two most likely failure points.

**Primary recommendation:** Write application.alan collections first, verify syntax, then write the migration. Never write them in a single step — catching a syntax error in the model before touching the migration avoids compound failures.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Locations data model | datastore v116 | — | Collection persistence is datastore's job |
| Item Categories data model | datastore v116 | — | Same |
| UI rendering (tables, forms, navigation) | auto-webclient yar.15 | — | Auto-generated from model; no manual UI code |
| @identifying label in dropdowns | auto-webclient yar.15 | — | Webclient reads @identifying annotation to set display label |
| Seed data (from_empty) | datastore v116 | — | Migration runs on first deploy, datastore processes it |
| from_release migration | datastore v116 | — | Currently empty (no prior model), stays empty |

---

## Standard Stack

This phase uses zero new libraries. The project stack is fixed:

| System | Version | Role |
|--------|---------|------|
| datastore | ~116 | Persists collections, runs migrations |
| auto-webclient | ~yar.15 | Renders collections as navigable tables |
| session-manager | ~31 | Unchanged — auth not relevant to Phase 2 |

**No npm install. No new dependencies. No changes to versions.json.**

---

## Architecture Patterns

### File Structure for Phase 2

Only two files change:

```
models/model/application.alan        ← add Locations + Item Categories to root {}
migrations/from_empty/to/migration.alan  ← replace stub with seeded collections
```

No other files touched.

### Pattern 1: Collection with Stategroup Field

**Verified syntax** from `_ref/application-language.md` (E-commerce example, Products collection):

```alan
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

Key rules confirmed:
- `collection ['Key']` — key field name in square brackets [VERIFIED: application-language.md]
- `@identifying` goes inline on the property line, no colon, no block — `'Name': text @identifying` [VERIFIED: application-language.md + ui-annotations.md]
- Stategroup states use `{ }` (curly braces), not `( )` — state body is a block [VERIFIED: application-language.md]
- Tab indentation throughout [VERIFIED: CLAUDE.md project constraint]

### Pattern 2: number with Named Numerical Type

**Verified syntax** from `_ref/application-language.md`:

```alan
'Retention Days': number 'days'
```

The `'days'` type is already declared in the current `numerical-types` section of application.alan (confirmed by reading the file). No changes to numerical-types needed. [VERIFIED: models/model/application.alan line 11]

Current numerical-types block (do not touch):
```alan
numerical-types
	'units'
	'days'
	'date' in 'days'
		= 'date-time' + -43200 * 10 ^ 0 in 'seconds'
		@date
	'date-time': time-in-seconds in 'seconds' @date-time
	'seconds' @duration: seconds
```

### Pattern 3: from_empty Migration with Seeded Collections

**Verified syntax** from `_ref/migrations.md` (seeded example):

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
	)
	'Item Categories': collection = <! !> (
		= (
			'Category ID': text = "CAT001"
			'Name': text = "Travel Documents"
			'Retention Days': number = 365
			'Priority': stategroup = 'Critical' ( )
		)
	)
)
```

Rules confirmed:
- `<! !>` required before `(` — no exceptions [VERIFIED: migrations.md CRITICAL RULE header]
- Each entry is `= ( ... )` [VERIFIED: migrations.md from_empty pattern]
- Stategroup value syntax: `stategroup = 'StateName' ( )` [VERIFIED: migrations.md line 239]
- Number with type in migration: **just `number = 365`** — the numerical type annotation is NOT repeated in migration syntax [VERIFIED: migrations.md number mapping syntax]
- Key field must be first in entry [VERIFIED: migrations.md "key field must be first"]

**Critical finding on number type in migrations:** The migration syntax is `'Retention Days': number = 365` — NOT `'Retention Days': number 'days' = 365`. The `'days'` annotation belongs only in application.alan. Migrations use bare `number`. [VERIFIED: migrations.md — "Number mapping: `'Price': number = $ .'Price'`"]

### Pattern 4: from_empty/from Stub

The `from_empty/from/migration.alan` represents the "before" state — which is truly empty (no model). Current content is correct and must NOT be changed:

```alan
root = root as $ (
)
```

[VERIFIED: current file at migrations/from_empty/from/migration.alan]

### Pattern 5: from_release Migration — Stays Empty

Decision from CONTEXT.md: from_release/from and from_release/to both stay as `root = root as $ ( )`. There is no prior deployed model to migrate from. Deploy will use "empty" not "migrate". [VERIFIED: CONTEXT.md Decision 5]

### Anti-Patterns to Avoid

- **`stategroup = 'Terminal 2'` without `( )`** — the `( )` after the state name is mandatory even when the state has no sub-properties [VERIFIED: migrations.md stategroup syntax]
- **`'Retention Days': number 'days' = 365`** — do NOT include the type name in migration; it belongs only in application.alan
- **Spaces instead of tabs** — will cause cryptic parse errors unrelated to actual location [VERIFIED: PITFALLS.md PITFALL 1]
- **Missing `<! !>` before `(`** — exact error: `expected keyword '<!'' but saw keyword '('` [VERIFIED: PITFALLS.md PITFALL 2]
- **`<! !> none`** — correct for empty collection with no seed data; wrong here since we are seeding [VERIFIED: PITFALLS.md table]
- **Touching numerical-types** — 'days' is already declared; editing this section risks breaking the date/date-time definitions [VERIFIED: current application.alan]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| UI for navigating collections | Custom React/JS | auto-webclient renders tables automatically |
| Form for creating/editing records | Custom forms | auto-webclient generates forms from model |
| Display label in reference dropdowns | Custom logic | `@identifying` annotation — webclient reads it |
| Seed data loader | Custom import script | from_empty migration runs at deploy time |

---

## Common Pitfalls

### Pitfall 1: `<! !>` Omission in Migration
**What goes wrong:** Writing `'Locations': collection = ( )` instead of `'Locations': collection = <! !> ( ... )`
**Why it happens:** application.alan and migration.alan use completely different syntax for collections. Agents conflate them.
**Exact error:** `error: expected keyword '<!'' but saw keyword '('`
**Prevention:** The `<! !>` comes from the migrations.md file's critical rule header — it is the first thing in that file. Re-read before writing.
[VERIFIED: PITFALLS.md PITFALL 2, migrations.md]

### Pitfall 2: Number Type Annotation in Migration
**What goes wrong:** Writing `'Retention Days': number 'days' = 365` in migration.alan
**Why it happens:** The application.alan syntax uses `number 'days'` so agents carry that pattern into the migration.
**What happens:** Likely a parse error or unexpected token on the `'days'` token.
**Prevention:** Migration number syntax is bare `number = value`. The type annotation only belongs in application.alan.
[VERIFIED: migrations.md number mapping section]

### Pitfall 3: Stategroup Entry Missing `( )` in Migration
**What goes wrong:** Writing `'Terminal': stategroup = 'Terminal 2'` without the trailing `( )`
**Why it happens:** The state body is empty so it seems redundant.
**Prevention:** The `( )` is syntactically required even for states with no sub-properties. Pattern: `stategroup = 'StateName' ( )`
[VERIFIED: migrations.md stategroup section]

### Pitfall 4: Tab Indentation
**What goes wrong:** Any whitespace indented with spaces (2 or 4) instead of hard tabs.
**Why it happens:** Every tool defaults to spaces. Alan parser gives misdirecting errors.
**Prevention:** Write with `\t` explicitly. Check with `cat -A` if unsure.
[VERIFIED: PITFALLS.md PITFALL 1]

### Pitfall 5: @identifying Placement
**What goes wrong:** Putting `@identifying` in annotations.alan instead of inline in application.alan.
**Why it happens:** Some annotation systems use separate files.
**The truth:** `@identifying` is an inline annotation on the property line in application.alan. annotations.alan is for system-level overrides and is intentionally left empty in this project.
[VERIFIED: ui-annotations.md, CONTEXT.md Decision 6]

### Pitfall 6: Editing from_release When Deploying with "empty"
**What goes wrong:** Spending time updating from_release/from/migration.alan when the deploy strategy for Phase 2 is "empty" (not "migrate").
**Why it happens:** Confusion about which migration runs when.
**The truth:** Phase 2 deploys with "empty" — only from_empty/to/migration.alan is used. from_release is irrelevant until a subsequent deploy uses "migrate".
[VERIFIED: CONTEXT.md Decision 5, wiring-and-deployment.md deploy workflow]

---

## Code Examples

### Complete application.alan after Phase 2

```alan
users
	anonymous

interfaces

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

numerical-types
	'units'
	'days'
	'date' in 'days'
		= 'date-time' + -43200 * 10 ^ 0 in 'seconds'
		@date
	'date-time': time-in-seconds in 'seconds' @date-time
	'seconds' @duration: seconds
```

Source: application-language.md (collection + stategroup patterns), current application.alan (numerical-types block — copy verbatim)

### Complete from_empty/to/migration.alan after Phase 2

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

Source: migrations.md (seeded from_empty pattern), CONTEXT.md (exact seed data values)

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `number = 365` (bare, no type annotation) is the correct migration syntax for `number 'days'` fields | Code Examples | Migration parse error; easy to catch at build time |

All other claims in this research are verified against _ref/ documentation or the current codebase files.

---

## Open Questions

None blocking Phase 2.

The one assumption (A1) is low-risk: if `number 'days' = 365` turns out to be accepted in migration syntax, it would still work. If it fails, the fix is trivial (remove `'days'`). The build output will make the failure immediately obvious.

---

## Environment Availability

Step 2.6: SKIPPED — Phase 2 is pure file edits. No external tools, services, or CLIs required beyond what is already confirmed working from Phase 1 (git, Alan IDE via Playwright, GitHub push).

---

## Validation Architecture

No automated test framework applies to Alan model files. Validation is runtime:

### Phase Gate Checklist (manual)
| Check | Method | Pass Condition |
|-------|--------|---------------|
| Build clean | Alan Build in IDE | Status bar shows `" 0  0"` |
| Migration runs | Alan Deploy → empty | No migration errors in output |
| Locations visible | Navigate live app | Collection appears in navigation |
| Item Categories visible | Navigate live app | Collection appears in navigation |
| Seed records present | Open each collection | 3 Locations, 4 Item Categories listed |
| Records editable | Create/edit one record | Save succeeds without error |
| @identifying works | Open a record from nav | Name shown as label not Location ID |

**Alan Build command:** Playwright click on Build button in status bar after opening application.alan via Ctrl+P.
**Live app URL:** `https://app.alan-platform.com/Travis_Arnold/client/`

---

## Security Domain

Not applicable to Phase 2. Phase 2 adds reference data collections with no authentication changes, no permission rules, and no user-facing auth flows. Security layer is Phase 8.

---

## Project Constraints (from CLAUDE.md)

| Constraint | Applies to Phase 2 |
|------------|-------------------|
| Tab indentation only | YES — both files written with hard tabs |
| Migration `<! !>` rule | YES — both collections in from_empty require it |
| Wiring untouched | YES — no wiring changes |
| Verify live app after deploy, not just build | YES — navigate to live URL, check navigation |
| Playwright xterm.js: use keyboard.type not browser_type | YES — git pull step in IDE terminal |
| Git push before IDE git pull | YES — standard deploy loop |
| Open application.alan via Ctrl+P before any Build/Deploy | YES — activates Alan extension |
| Deploy choice: "empty" not "migrate" | YES — Phase 2 is first real deploy; use empty |

---

## Sources

### Primary (HIGH confidence)
- `_ref/migrations.md` — `<! !>` rule, seeded collection syntax, number mapping, stategroup value syntax, from_empty pattern
- `_ref/application-language.md` — collection definition, stategroup syntax, number type annotation, @identifying placement
- `_ref/ui-annotations.md` — @identifying annotation confirmed as inline, not in annotations.alan
- `models/model/application.alan` — confirmed 'days' already in numerical-types; confirmed 4-section structure correct
- `migrations/from_empty/from/migration.alan` — confirmed correct stub format (do not change)
- `migrations/from_empty/to/migration.alan` — confirmed current state (stub only, needs seeding)
- `.planning/phases/02-reference-tables/02-CONTEXT.md` — locked decisions, exact field specs, exact seed data

### Secondary (MEDIUM confidence)
- `_ref/wiring-and-deployment.md` — deploy workflow (empty vs migrate), migration folder structure
- `.planning/research/PITFALLS.md` — confirmed failure patterns from 40+ commits

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- application.alan collection syntax: HIGH — verified directly in application-language.md with matching examples
- Migration seeded syntax: HIGH — verified in migrations.md with near-identical example
- number type in migrations (bare vs annotated): MEDIUM — verified by implication from migrations.md examples which all use bare `number`; exact failure mode if wrong is easy to detect
- @identifying placement: HIGH — confirmed in both application-language.md and ui-annotations.md
- 'days' type availability: HIGH — confirmed in current application.alan file

**Research date:** 2026-04-14
**Valid until:** Stable (Alan syntax does not change between deploys; valid until platform version is bumped)
