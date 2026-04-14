# Phase 1 Context: Foundation

**Phase:** 1 — Foundation  
**Date:** 2026-04-14  
**Status:** Ready to plan

---

## Phase Goal

The repository is clean and `application.alan` has a correct structural skeleton that builds with 0 errors.

---

## Canonical Refs

- `.planning/REQUIREMENTS.md` — FOUND-01 through FOUND-05
- `.planning/ROADMAP.md` — Phase 1 success criteria
- `.planning/research/PITFALLS.md` — prior failure patterns (tab/space, wiring rewrite, etc.)
- `.planning/research/SUMMARY.md` — architecture overview and top pitfalls
- `_ref/application-language.md` — Alan syntax reference
- `_ref/wiring-and-deployment.md` — versions.json format and wiring syntax
- `alan-project/CLAUDE.md` — project-level constraints and MCP rules

---

## Decisions

### 1. Repo restructure: root-level only, delete src/

**Decision:** Delete `src/` entirely. Keep root-level dirs (`models/`, `migrations/`, `systems/`, `wiring/`).

**Why:** `src/` is an exact duplicate of root-level dirs (confirmed by diff — all files identical). Alan IDE reads from root-level dirs directly. The `src/` wrapper was causing confusion and never served a purpose in this project.

**Files to delete (src/ and legacy):**
- `src/` directory (entire tree — all identical to root)
- `alan` (binary in project root)
- `deploy.sh` (legacy deploy script)
- `deployments/` (deploy logs)
- `dist/` (compiled output)
- `output/` (prior agent output)
- `CONTEXT.md` (root-level — prior agent artifact, not GSD context)
- `BUILD_PLAN.md` (superseded by GSD planning docs)
- `systems/server/` (empty legacy interfaces dir — only in root, not in src)

**Files to keep (root-level):**
- `models/model/application.alan`
- `migrations/from_empty/to/migration.alan`
- `migrations/from_release/from/migration.alan`
- `systems/client/settings.alan`
- `systems/sessions/config.alan`
- `wiring/wiring.alan`
- `versions.json`
- `.planning/` (GSD planning docs)
- `_ref/` (Alan syntax reference files)
- `CLAUDE.md` (project instructions)

### 2. application.alan: wipe to empty skeleton

**Decision:** Replace `application.alan` content with a minimal correct skeleton — 4 required sections, empty `root {}`, `anonymous` in users block, correct numerical-types.

**Why:** Current content is based on the old simplified BUILD_PLAN (wrong architecture: no Staff collection, wrong field sets, wrong collection ordering). Carrying it forward would mean Phase 2+ are patching wrong definitions. Clean slate is safer and Phase 2 builds fresh from project-spec.

**Target skeleton:**
```
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

**Important — tabs only:** Alan parser requires tab indentation. Spaces cause cryptic parse errors. Every indent in application.alan MUST be a tab character.

### 3. numerical-types format: KEEP current formula

**Decision:** Do NOT change the current `numerical-types` format. The existing formula-based `'date' in 'days' = 'date-time' + -43200 * 10 ^ 0 in 'seconds' @date` is the CORRECT format for datastore v116.

**Why:** FOUND-04 requirement was written before research confirmed this. The research (SUMMARY.md, PITFALLS.md) confirmed the current format is correct for the pinned versions. The `@date: date` format referenced in FOUND-04 is for a different Alan version.

**Status of FOUND-04:** Already satisfied — no change required.

### 4. versions.json: already correct

**Decision:** No change needed. Current `versions.json` already has the correct pins:
- platform: 2024.2
- datastore: 116
- auto-webclient: yar.15
- session-manager: 31

**Status of FOUND-05:** Already satisfied — no change required.

### 5. Migration files: reset to empty skeleton

**Decision:** Both migration files (`from_empty/to/migration.alan` and `from_release/from/migration.alan`) should be reset to match the empty skeleton. With an empty `root {}`, the migrations need empty bodies too.

**from_empty migration:** Set to empty (no collections to seed yet — seed data comes in Phase 9).
**from_release migration:** Set to empty forward-mapping (no collections exist yet).

### 6. Wiring file: leave untouched

**Decision:** Do NOT modify `wiring/wiring.alan`. The existing wiring is correct and was working in the deployed Phase 0 app.

**Why:** 6+ prior wiring rewrite failures. The wiring doesn't need to change for Phase 1 — it references the model but doesn't care about content, only structure.

### 7. client/settings.alan: leave untouched for Phase 1

**Decision:** Leave `systems/client/settings.alan` as-is for Phase 1. Anonymous user enabling (`allow anonymous user: enabled`) comes in Phase 3 when authentication is wired up.

**Why:** The settings file correctly references the app metadata. Auth config belongs with the auth phase.

---

## Pre-answered (not gray areas)

- **Tab indentation:** MANDATORY. No spaces anywhere in Alan files. (PROJECT.md constraint)
- **No booleans:** Use stategroup where boolean needed. (PROJECT.md constraint)
- **Migration `<! !>` rule:** Required before `( )` or `none` on collections. (PITFALLS.md)
- **Wiring: add only, never replace.** (PITFALLS.md — 6+ prior failures)

---

## Success Criteria (from ROADMAP.md)

1. No `src/` directory exists; all Alan project files live at root level
2. No legacy broken files exist (`deploy.sh`, `alan` binary, `dist/`, `deployments/`, old logs)
3. `application.alan` contains the four required sections (users, interfaces, root, numerical-types) with no parse errors
4. numerical-types uses the correct format (confirmed: formula-based format is correct, no change needed)
5. `versions.json` exists at project root with correct version pins (confirmed: already correct)
6. Alan IDE shows 0 build errors after the restructure

---

## Deferred Ideas

None raised during discussion.
