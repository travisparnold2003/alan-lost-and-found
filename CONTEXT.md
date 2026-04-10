# Alan Project — Layer 2
**Load after: CLAUDE.md → CONTEXT.md → this file**
**Also load:** `_ref/alan-skill-readme.md` + `_ref/workflow.md`

---

## What this workspace is for
Building a lost & found application on the Alan platform as a demo project. Two purposes: (1) learn the Alan platform, (2) impress Rick (CEO of Kjerner) for a potential job.

---

## URLs

| Thing | URL |
|-------|-----|
| Online IDE | https://coder.alan-platform.com/Travis_Arnold/?folder=/home/coder/project |
| Deployed App | https://app.alan-platform.com/Travis_Arnold/client/ |
| GitHub Repo | https://github.com/travisparnold2003/alan-lost-and-found |
| Alan Docs | https://alan-platform.com/docs/ |

IDE password: `travis2003`

---

## Folder Structure

```
alan-project/
├── CONTEXT.md          ← this file (Layer 2)
├── src/                ← live Alan source code (cloned from GitHub)
│   ├── models/model/application.alan       ← DATA MODEL — read this first
│   ├── systems/client/settings.alan        ← app name, theme, anonymous login
│   ├── systems/sessions/config.alan        ← password auth on/off
│   ├── wiring/wiring.alan                  ← system wiring
│   ├── migrations/from_empty/migration.alan  ← first-ever deploy seed data
│   ├── migrations/from_release/migration.alan ← schema migration (subsequent deploys)
│   ├── deployments/                        ← deployment configs (don't touch)
│   └── versions.json                       ← pinned Alan system versions
├── _ref/               ← Alan platform reference docs (Layer 3)
│   ├── alan-skill-readme.md   ← START HERE — platform overview
│   ├── workflow.md            ← how to deploy, Chrome automation, token tips
│   ├── application-language.md
│   ├── migrations.md          ← CRITICAL: read before touching any migration
│   ├── wiring-and-deployment.md
│   ├── connectors.md
│   ├── ui-annotations.md
│   └── common-patterns.md
└── output/             ← plans, notes, artifacts per session
    ├── PRD-lost-and-found.md
    └── build-plan.md
```

---

## Current State (April 2026)

**FRESH START — Phase 0.** Previous agent left broken code. Application has been reset to minimal working state.

**What's deployed (or will be on next deploy):** A minimal app with just a `Locations` collection. Application builds correctly. Ready to deploy Phase 0.

**What was wrong with the previous code:**
- `application.alan` was missing `interfaces`, `root {}` wrapper, `numerical-types`
- `users` block was at the bottom of the file (must be at top)
- Used `boolean` type (doesn't exist in Alan — use stategroup Yes/No)
- Used wrong reference syntax `.'Collection'* .'Key'` instead of `.'Collection'[]`
- Used wrong settings file format

**Use BUILD_PLAN_V2.md** — not BUILD_PLAN.md. V2 is the authoritative plan.

**Next step: Phase 0 — Deploy and verify the minimal app works**

---

## How to Start a Session

1. Read this CONTEXT.md
2. Read `BUILD_PLAN_V2.md` — this is the authoritative step-by-step plan (replaces old BUILD_PLAN.md)
3. Read `_ref/workflow.md` — CRITICAL for Chrome automation and deploy loop
4. Read `_ref/application-language.md` — Alan syntax reference
5. Read `src/models/model/application.alan` — current data model
6. Run browser health check (Step C in BUILD_PLAN_V2.md) BEFORE anything else
7. Build one phase at a time — never skip ahead

---

## Development Pipeline (brief)

**Edit locally → git commit + push → IDE: git pull → Alan Build → Alan Deploy → verify app**

Full details in `_ref/workflow.md`.

---

## Critical Rules (hard-won — never break these)

1. **application.alan structure is sacred.** This order never changes:
   ```
   users
   interfaces
   root { ... all collections and groups go here ... }
   numerical-types
   ```

2. **Reference syntax:** `text -> ^ .'CollectionName'[]` — NOT `.'Collection'* .'Key'`

3. **No boolean type.** Use `stategroup ( 'Yes' { } 'No' { } )` instead.

4. **Empty migration collection:** `<! !> none` — NOT `<! !> ( )`
   Seeded collection entry: `<! !> = ( 'Field': text = "value" )`

5. **from_release/from/** must match what's CURRENTLY deployed (snapshot of previous state).
   from_release/to/ maps old → new with defaults for new fields.

6. **First deploy: "empty". All subsequent: "migrate".** "empty" after data exists WIPES ALL DATA.

7. **Build must show `" 0  0"` before deploying.** Never deploy with errors.

8. **settings.alan format** (match exactly):
   ```
   application creator: "Travis Arnold"
   application name: "Schiphol Lost & Found"
   anonymous login: enabled
   csv actions: enabled
   report limit: 10000
   announcement: "" [ ]
   language: "English"
   engine language: english
   generator: 'default'
   ```

9. **sessions/config.alan format** (match exactly):
   ```
   password-authentication: disabled
   user-creation: disabled
   user-linking: disabled
   ```
   (Change password-authentication to enabled when adding user auth in Phase 3)

---

## Reference Files (`_ref/`)

| File | Contents | Load when... |
|------|----------|-------------|
| `alan-skill-readme.md` | Platform overview, IDE workflow, project structure | Start of any session |
| `workflow.md` | Chrome automation, deploy loop, token-efficient approach | Every session (mandatory) |
| `application-language.md` | Full model syntax — types, stategroups, collections, permissions | Writing application.alan |
| `migrations.md` | Migration syntax, `<! !>` rules, common patterns | ANY migration work |
| `wiring-and-deployment.md` | Wiring, deployment, system setup | Deployment or wiring work |
| `connectors.md` | Connector/interface syntax | Phase 6 — external integrations |
| `ui-annotations.md` | UI annotations and auto-webclient settings | UI/frontend work |
| `common-patterns.md` | Forum-proven solutions for common problems | Stuck on something |

## When Local Ref Docs Don't Have the Answer

If `_ref/` doesn't cover something, go online in this order:

1. **Docs:** https://alan-platform.com/docs/
2. **FAQ:** https://alan-platform.com/faq/
3. **Forum:** https://forum.alan-platform.com/

**MANDATORY after finding an answer online:** Update the relevant `_ref/` file with what you learned. If no existing file fits, add a new section to `common-patterns.md`. This keeps Claude's knowledge persistent across sessions — do not skip this step.

---

## Important Notes
- Rick will look at this code — quality and understanding of Alan's patterns matters
- The goal is to show genuine understanding, not just copied examples
- Keep scope focused: build something complete and clean rather than half-built
- All code changes go in `src/` and get pushed to GitHub

---

*Last updated: 2026-04-10 — full reset, fresh start from Phase 0, all broken code removed*
