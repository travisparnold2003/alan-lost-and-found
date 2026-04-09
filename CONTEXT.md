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

**Phase 1 is deployed.** App is live at `app.alan-platform.com/Travis_Arnold/client/`.

**Collections are EMPTY** — all reference data (Airlines, Terminals, Locations, Item Categories) needs to be entered manually via the UI. This is intentional for now; bulk seed data entry is Phase 7.

**Confirmed finding:** The `= ( ... )` literal entry syntax in `from_empty/migration.alan` does NOT actually insert rows into the deployed app. It builds without error but data stays empty. Do not waste time trying to fix the from_empty seeding — it doesn't work this way. Seed data will be entered manually in Phase 7.

**Next step: Phase 2 — Users & Auth**

---

## How to Start a Session

1. Read this CONTEXT.md
2. Read `_ref/workflow.md` — CRITICAL for how the Chrome automation works (especially the Start-of-Session browser health check)
3. Read `_ref/alan-skill-readme.md` — platform overview
4. Read `src/models/model/application.alan` — current data model
5. Check `output/build-plan.md` for next phase
6. Follow the browser server start-of-session procedure in `_ref/workflow.md` BEFORE anything else
7. Build

---

## Development Pipeline (brief)

**Edit locally → git commit + push → IDE: git pull → Alan Build → Alan Deploy → verify app**

Full details in `_ref/workflow.md`.

---

## Critical Rules (hardest-won lessons from session 1)

1. **ALL collections in migration.alan require `<! !>` before `( )`** — even empty ones. `collection = ( )` is WRONG. `collection = <! !> ( )` is correct. This applies to BOTH from_empty AND from_release migrations.

2. **from_release/from/application.alan** must match what's currently deployed. If you add a new collection to application.alan, you MUST use "Alan: Generate Migration" to update this file — or manually update it to match the PREVIOUS deployed model (not the new one).

3. **The deploy uses the git version** — always commit and push before deploying. Local changes that aren't pushed will be ignored.

4. **"empty" vs "migrate" in deploy dialog:**
   - First ever deploy: choose "empty" (uses from_empty migration, seeds data)
   - All subsequent deploys: choose "migrate" (uses from_release migration, preserves data)
   - Using "empty" after data exists WIPES ALL DATA

5. **Alan Build must show `" 0  0"` in status bar** before deploying. Deploy with errors will fail silently.

6. **Do NOT use screenshots for every step** — use `getText` and `eval` for text-based feedback. Screenshots are expensive tokens. Only screenshot when there's a visual error to debug.

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

*Last updated: 2026-04-08 (Session 2 — Phase 1 deployed, seed data finding)*
