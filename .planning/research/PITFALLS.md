# Alan Platform Pitfalls — Schiphol Lost & Found

**Project:** Alan Lost & Found (Schiphol)
**Researched:** 2026-04-14
**Source:** _ref/ docs, git history (40+ commits), memory/project_alan_lessons.md, CONTEXT.md

All pitfalls below are confirmed from actual failures in this project's git history, not speculation.

---

## CRITICAL Pitfalls

These caused hard build failures or silent corruption in previous agent attempts.

---

### PITFALL 1: Tab vs Space Indentation

**What goes wrong:** File is written with space indentation instead of tabs. Alan's parser gives cryptic errors unrelated to the actual indentation problem — agents then chase the wrong fix.

**Why it happens:** Every code editor defaults to spaces. Agents writing Alan files from scratch routinely use spaces. The error message does not say "wrong indentation" — it says something else entirely.

**Consequences:** Build fails with parse errors. Multiple commits chasing ghost bugs.

**Prevention:**
- Always write Alan files with hard tabs (`\t`), never spaces.
- When editing an existing file, Read it first and preserve the indentation character already in use.
- If in doubt: `cat -A file.alan | head -5` — tabs show as `^I`, spaces as nothing.

**Detection warning signs:**
- Build errors pointing to a line that looks syntactically correct.
- Errors like "unexpected token" on lines that look fine.
- Errors cascade after a line that was "cleanly added".

**Phase relevance:** Every phase — this applies to application.alan, migration files, wiring, and config files.

---

### PITFALL 2: Migration Empty Collection — `<! !>` Rule

**What goes wrong:** Agent writes `'Collection': collection = ( )` or forgets `<! !>` entirely.

**Exact error:** `error: expected keyword '<!'' but saw keyword '('`

**Why it happens:** This syntax is specific to migrations only. In application.alan, collections are defined differently. Agents conflate the two syntaxes.

**The three forms — memorise these:**

| Intent | Correct syntax |
|--------|----------------|
| Empty collection (no data) | `'Items': collection = <! !> none` |
| Seeded collection (with entries) | `'Items': collection = <! !> ( = ( ... ) = ( ... ) )` |
| Map from existing (from_release) | `'Items': collection = map $ .'Items'* as $'i' ( ... )` |

**Wrong forms that have appeared in this project:**
- `'Items': collection = ( )` — missing `<! !>`
- `'Items': collection = <! !> ( )` — `( )` is not `none`, and not a seeded entry — ambiguous/wrong
- `'Items': collection = none` — missing `<! !>`

**Prevention:**
- Before touching any migration.alan, re-read `_ref/migrations.md`.
- The rule is at the very top of that file in bold. It is the first thing to check.
- Never write a migration without running this through the checklist.

**Detection warning signs:**
- Any build error mentioning `expected keyword '<!''`
- Any error on the line of a collection definition inside a migration file.

**Phase relevance:** Every phase that adds a collection (Phases 1-9). High-risk in Phase 7 (seed data) where multiple nested collections are seeded in from_empty.

---

### PITFALL 3: application.alan File Structure

**What goes wrong:** The four top-level sections appear out of order, or collections are placed outside `root {}`, or `interfaces` is omitted entirely.

**Required order — never change this:**
```
users
interfaces
root {
    ...all collections and groups here...
}
numerical-types
```

**Why it happens:** Agents building from scratch sometimes put `users` last, omit `interfaces` (since it's empty), or put standalone collections at the top level. Alan accepts a partial build but the app renders wrong or empty.

**Consequences (confirmed from git history):** A previous agent reported "Phase 1-5 deployed and working" — but application.alan was structurally invalid. The app showed only Locations because Alan partially rendered despite errors. The agent never verified in the live app.

**Prevention:**
- Always Read application.alan before editing it.
- Check the four-section structure before adding anything.
- Even if `interfaces` has nothing in it, keep the `interfaces` keyword as a blank section.

**Detection warning signs:**
- App loads but shows fewer collections than the model defines.
- Build shows "0 0" (passes) but app navigation is missing sections.
- `users` appears anywhere other than line 1.

**Phase relevance:** All phases. Most dangerous in Phase 1 (first model edit after Phase 0).

---

### PITFALL 4: from_release `from/` Must Match Currently-Deployed State

**What goes wrong:** The `from_release/from/migration.alan` doesn't match the model that is actually deployed. It either shows the new model, an old model from two phases back, or a partially-complete model.

**Why it happens:** After each phase, the "from" snapshot must be manually updated to represent the previous phase's model. Agents forget to update it, or update it to the wrong state.

**Consequences:** Migration fails at deploy time. Error typically says a field in the from model doesn't exist in the actual data, or vice versa.

**The rule:**
- `from_release/from/migration.alan` = exact snapshot of what is CURRENTLY deployed (previous phase)
- `from_release/to/migration.alan` = maps old model to new model, new fields get defaults
- Derived properties are NOT included in either migration file (they recompute automatically)

**Prevention:**
- At the end of each successful deploy, update `from_release/from/migration.alan` to be a plain snapshot of the model just deployed. Do this BEFORE starting the next phase.
- The `from/` snapshot only needs base (non-derived) properties listed as `collection = <! !> ( )` — it doesn't need to map data, just declare the shape.

**Detection warning signs:**
- Deploy error mentioning "property not found" or "unexpected property" during migration.
- Build passes but deploy step fails with a migration error.

**Phase relevance:** Phases 1-9 (every phase after the first deploy).

---

### PITFALL 5: Wiring File Syntax

**What goes wrong:** wiring.alan is written using the wrong syntax variant. There are (at least) two different syntax forms that have appeared in this project, and the wrong one causes a build error.

**Confirmed broken form (caused multiple fix commits):**
```
systems
    'server': @'"systems/server"'
        mapping (
            'model': @'model'
        )
```

**Confirmed working form (current wiring.alan):**
```
systems
    'server': 'datastore'
        project / (
            'interfaces' / (
                'providing' / ( )
                'consuming' / ( )
            )
            'model' = provide 'model'
        )

    'sessions': 'session-manager'
        project / (
            'model' = bind 'server'::'authenticate'
        )

    'client': 'auto-webclient'
        project / (
            'model' = consume 'server'/'model'
        )

provided-connections
    'auth' = 'sessions'::'http'
    'client' = 'client'::'http'
```

Also broken: `provided-connections` with `@` paths (`'auth': @'sessions'/'http'`) — needs `=` assignment.

**Prevention:**
- Never rewrite wiring.alan from scratch.
- Read the current working wiring.alan before touching it.
- If wiring needs changing (Phase 10, connectors), add only the new system block rather than rewriting.

**Detection warning signs:**
- Build errors immediately after touching wiring.alan.
- Errors referencing system names or connection paths.
- Multiple sequential "fix wiring" commits in history (happened 6+ times previously).

**Phase relevance:** Phase 0 (initial), Phase 3 (auth), Phase 10 (connector). Do not touch wiring between these phases.

---

### PITFALL 6: settings.alan Key Format

**What goes wrong:** Agent writes settings.alan with the wrong key format for the auto-webclient version.

**Confirmed broken format:**
```
name: "Schiphol Lost & Found"
allow-user-creation: enabled
```

**Confirmed working format (current settings.alan):**
```
application creator: "Travis Arnold"
application name: "Schiphol Lost & Found"
allow anonymous user: disabled
enable csv actions: enabled
report limit: 10000
announcement: "" [ ]
language: "English"
engine language: english
generator: 'default'
```

Note: The current settings.alan in the repo uses slightly different keys from the wiring-and-deployment.md reference (which shows `"allow anonymous user":` quoted format). The unquoted `allow anonymous user:` form is the one that currently builds.

**Prevention:**
- Never rewrite settings.alan from scratch.
- Only change `allow anonymous user: enabled/disabled` when toggling anonymous access (Phase 3).
- Read the current file, make the targeted change, do not reformat.

**Detection warning signs:**
- Build error mentioning settings.alan or client system.
- App builds but shows wrong name or broken UI.

**Phase relevance:** Phase 3 (disable anonymous login). Otherwise, do not touch.

---

### PITFALL 7: sessions/config.alan Key Format

**What goes wrong:** Old key format used. This caused failures before Phase 0 was reset.

**Confirmed broken format:**
```
allow-user-creation: enabled
```

**Confirmed working format:**
```
password-authentication: disabled
user-creation: disabled
user-linking: disabled
```

**Prevention:**
- Only change `password-authentication: disabled` to `password-authentication: enabled` in Phase 3.
- Read current config.alan first, change only that one line.

**Phase relevance:** Phase 3 only.

---

### PITFALL 8: `@date` Annotation on Numerical Types

**What goes wrong:** Agent writes `'date' @date: date` as the numerical-types entry for a date type.

**Confirmed broken syntax:** `'date' @date: date`

**Correct current model uses the compound form:**
```alan
numerical-types
    'days'
    'date' in 'days'
        = 'date-time' + -43200 * 10 ^ 0 in 'seconds'
        @date
    'date-time': time-in-seconds in 'seconds' @date-time
    'seconds' @duration: seconds
```

The `@date` annotation goes on its own line, not inline with the type definition. Writing `@date: date` (with colon) causes a build error. This was confirmed in commit `883476a` ("Fix invalid @date annotation in numerical types").

**Prevention:**
- Copy the working numerical-types block from the current application.alan — do not write it from scratch.
- The `'date' @date: date` form (with colon) does not work in this version of Alan.

**Phase relevance:** Phase 4 (adds Found Items with date fields) — this is when date types are first introduced.

---

## Moderate Pitfalls

These cause confusion or wasted effort but not necessarily hard build failures.

---

### PITFALL 9: Reference Syntax — `[]` vs `*`

**What goes wrong:** Reference written as `text -> ^ .'Collection'* .'Key'` instead of `text -> ^ .'Collection'[]`.

**Why it happens:** `*` is the collection iteration syntax (for derived values, aggregations). `[]` is the reference/lookup syntax. They look similar and agents conflate them.

**Wrong:** `'Category': text -> ^ .'Item Categories'* .'Category ID'`
**Right:** `'Category': text -> ^ .'Item Categories'[]`

**Prevention:** The rule is in CONTEXT.md critical rules section. Check every reference property before committing.

**Phase relevance:** Phase 4 (Found Items adds first references to other collections), Phase 5 (Loss Reports), Phase 9 (Matches).

---

### PITFALL 10: Boolean Type Does Not Exist

**What goes wrong:** Agent uses `boolean`, `bool`, `true`, or `false` anywhere in the model.

**Prevention:** Replace every boolean with `stategroup ( 'Yes' { } 'No' { } )`. Alan has no boolean type. This is confirmed in CONTEXT.md and the application-language.md reference.

**Phase relevance:** Phase 3 (Users have Active field), Phase 8 (permissions logic).

---

### PITFALL 11: Deploy with "empty" After Data Exists

**What goes wrong:** Agent chooses "empty" instead of "migrate" when deploying after Phase 0. This wipes ALL data — all locations, categories, users, found items, etc.

**The rule:** `empty` = first deploy only (or intentional data wipe). `migrate` = all subsequent deploys.

**Why it happens:** Agent forgets the rule or assumes "empty" means "no migration needed".

**Consequences:** Permanent data loss. Users must re-enter all data.

**Prevention:** Default to "migrate". Only choose "empty" when the intent is explicitly to wipe and reseed (Phase 7 demo reset).

**Detection:** This cannot be detected after the fact — it's irreversible.

**Phase relevance:** Every phase after Phase 0. Highest risk in Phase 7 where "empty" is intentional for seeding — risk of triggering it accidentally after that.

---

### PITFALL 12: Alan Extension Does Not Activate After Window Reload

**What goes wrong:** After any IDE window reload, the Alan Build/Deploy/Fetch buttons in the status bar disappear. Playwright then fails to find them.

**Why it happens:** The Alan extension only activates when an `.alan` file is open in the editor. A reload closes all editors.

**Prevention:**
- After every IDE navigation or reload, open `application.alan` via Ctrl+P before running any Alan commands.
- Check `browser_snapshot` to verify the status bar shows the Alan buttons before clicking them.

**Phase relevance:** Every deploy session.

---

### PITFALL 13: xterm.js Terminal — `browser_type` Does Not Work

**What goes wrong:** Using `browser_type` to type into the IDE terminal. Nothing happens. The git pull never runs. Agent then proceeds to build stale code.

**Why it happens:** xterm.js listens to `keydown` events only. `browser_type` fires `input` events which xterm ignores entirely.

**Correct pattern (mandatory for all terminal commands):**
```javascript
await page.evaluate(() => {
  const xterms = document.querySelectorAll('.xterm-helper-textarea');
  xterms[xterms.length - 1].focus();
});
await page.keyboard.type('git pull');
await page.keyboard.press('Enter');
await page.waitForTimeout(6000);
```

**Prevention:** Use `browser_run_code` (not `browser_type`). The pattern is documented in both workflow.md and CONTEXT.md.

**Phase relevance:** Every deploy session — git pull step.

---

### PITFALL 14: Deploying Without a `git pull` in the IDE

**What goes wrong:** Agent edits files locally, pushes to GitHub, then builds and deploys — but skips the `git pull` in the IDE terminal. The IDE builds the old version of the code.

**Why it happens:** The IDE runs its own git clone of the repo. Local edits and GitHub pushes don't automatically appear in the IDE — it needs an explicit `git pull`.

**Consequences:** Build succeeds but deploys stale code. App appears not to have changed. Multiple re-deploys before root cause is found.

**Prevention:** Follow the full deploy loop in order: edit → commit+push → IDE git pull → Build → Deploy. Never skip the git pull step.

**Phase relevance:** Every deploy.

---

### PITFALL 15: Building Stale Due to src/ vs Root-Level Directory Split

**What goes wrong:** Alan Build reads from root-level `/models/`, `/migrations/`, `/systems/`, `/wiring/` directories in the IDE container. The GitHub repo has files in `src/`. After `git pull`, only `src/` is updated — root-level dirs may contain old versions.

**Current repo structure decision:** Phase 0 completed with restructure to root-level (commit `d2447a6`). Files should exist at root level AND in src/. But this must be verified on each deploy.

**Prevention:**
- After git pull in IDE, verify that root-level `models/model/application.alan` contains the expected content.
- If there is a mismatch, run: `cp -r src/models src/migrations src/systems src/wiring .`

**Phase relevance:** Every deploy until repo structure is fully confirmed correct.

---

## Minor Pitfalls

---

### PITFALL 16: versions.json Location

**What goes wrong:** versions.json is inside `src/` instead of at the project root. Alan extension cannot find the project.

**Consequence:** Alan extension does not activate. No Build/Deploy buttons appear.

**Prevention:** versions.json must be at `/home/coder/project/versions.json` in the IDE (project root, not src/ subdirectory). This is already committed to root of repo — just verify after git pull.

---

### PITFALL 17: Alan Show Dialog (Playwright)

**What goes wrong:** Using `Alan Show` to open the live app opens a VS Code dialog asking "Do you want code-server to open external website?" Playwright clicking on this dialog is unreliable.

**Prevention:** Never use `Alan Show`. Navigate directly to `https://app.alan-platform.com/Travis_Arnold/client/` via `browser_navigate`.

---

### PITFALL 18: Numerical Type — `number positive` Constraint

**What goes wrong:** Agent omits the `positive` keyword on counts or retention days, allowing negative numbers in a field where that makes no sense.

**Not a build error** — but causes bad data and confusing UI.

**Prevention:** Use `number positive 'units'` for fields that should never go negative (counts, retention days, quantities).

---

### PITFALL 19: Collection Ordering — References Must Come After Targets

**What goes wrong:** A collection that references another collection is defined before the referenced collection in application.alan.

**Example:** If `Found Items` references `Item Categories`, then `Item Categories` must appear before `Found Items` in the file.

**Current order in the working model (correct):**
1. Locations
2. Item Categories
3. Users
4. Passwords (references Users)
5. Found Items (references Locations, Item Categories, Users)
6. Loss Reports (references Locations, Item Categories)
7. Matches (references Found Items, Loss Reports, Users)
8. Dashboard (references Found Items, Loss Reports via count)

**Prevention:** Do not reorder collections. New collections that reference existing ones go after the ones they reference.

---

### PITFALL 20: Self-Reported Build Success Without Live App Verification

**What goes wrong:** Agent reports "deploy successful" based only on the build output, without navigating to the live app and verifying the new collections/fields appear.

**Confirmed failure (from project_alan_lessons.md):** A previous agent claimed Phases 1-5 were "deployed and working" when application.alan was structurally invalid. The build output was misleading.

**Prevention:** Every phase must end with navigation to `https://app.alan-platform.com/Travis_Arnold/client/` and a `browser_snapshot` that shows the expected navigation items and fields. Never mark a phase complete on build output alone.

---

## Phase-Specific Warning Table

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|----------------|------------|
| 0 | Repo structure / initial deploy | src/ vs root-level split, versions.json location | Verify root-level dirs after git pull |
| 1 | First model edit | application.alan structure broken | Read file first, check 4-section order |
| 2 | First new collection | from_release/from/ not updated | Update from/ snapshot immediately after Phase 1 deploys |
| 3 | Auth setup | settings.alan/config.alan wrong key format | Only change the one targeted key, read files first |
| 3 | Users collection | Passwords collection defined before Users | Keep Passwords after Users in file |
| 4 | Date numerical types | `@date: date` inline annotation form | Copy date numerical-types block from current working model |
| 4 | First references | `*` used instead of `[]` for references | Read reference syntax rule before writing |
| 5 | Loss Reports | from_release/from/ snapshot outdated | Update after every phase |
| 7 | Seed data | `<! !> ( )` used instead of correct seeded syntax | Re-read migrations.md before writing |
| 7 | Demo reset | "empty" deploy wipes later real data | Only use empty intentionally, add explicit step to document the intent |
| 8 | Permissions | Boolean-style conditions | Alan has no boolean — use stategroup comparisons |
| 9 | Matches references | `^ ^` navigation (nested stategroup refs) | Test reference navigation depth carefully |
| 10 | Wiring for connector | Wiring syntax variant | Add connector block to existing wiring, do not rewrite |

---

## Sources

- `_ref/migrations.md` — confirmed migration `<! !>` rules
- `_ref/application-language.md` — property types, reference syntax
- `_ref/workflow.md` — deploy loop, xterm.js interaction, IDE quirks
- `_ref/wiring-and-deployment.md` — wiring syntax reference
- `CONTEXT.md` — critical rules section
- `BUILD_PLAN.md` — phase-by-phase hard-won rules
- `memory/project_alan_lessons.md` — documented failure patterns from prior sessions
- Git history — 40+ commits analyzed, wiring failures in commits `cc39ab8`, `5327280`, `1266ba0`, `dceadb6`, `e7ae401`, `78581a7`, `523cf70`; @date annotation failure in `883476a`; structural failures in `d608b27`, `db3a9e1`
