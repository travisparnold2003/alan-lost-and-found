# Alan Project — MCP Rules

**Load after: CLAUDE.md → CONTEXT.md → this file**

---

## MCP Usage in This Workspace

| MCP | When to use |
|-----|-------------|
| **playwright** | Every session — mandatory. Follow the browser health check in `_ref/workflow.md` before any build/deploy. Use playwright to control the Alan IDE, run builds, trigger deploys, check the live app. |
| **context7** | Before writing any Alan model syntax, migrations, or wiring. Also use for any JS/TS if connectors are involved. |
| **github** | Committing and pushing code after every working change. Check diff before committing. Push before deploying — the IDE uses the git version. |
| **filesystem** | Reading `src/` files (application.alan, migrations, wiring). Always read the current model before making changes. |
| **sequential-thinking** | Before writing any migration. Migrations are the highest-risk operation — think through the full chain before touching a file. |
| **fetch** | When `_ref/` doesn't have the answer: Alan docs → FAQ → forum (in that order). Save findings back to `_ref/` after. |
| **memory** | Save phase completions, key decisions, hard-won findings. Read at session start for context on current phase. |

## Playwright-Specific Rules (Alan IDE)

- Always check the Alan Build status bar shows `" 0  0"` before deploying
- Use `getText` and `eval` for feedback — not screenshots (token cost)
- Only screenshot when there's a visual error to debug
- IDE password: `travis2003`

---

*Last updated: 2026-04-08*

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Schiphol Lost & Found**

A production-grade Lost & Found management system for Schiphol Airport, built on the Alan platform (model-driven declarative platform by Kjerner). Staff log found items, passengers file loss reports anonymously, supervisors confirm matches and authorize returns. This is a demo project to impress Rick (CEO of Kjerner/Alan) and prove Travis can build real Alan applications.

**Core Value:** A fully working, deployed Alan application that demonstrates genuine understanding of Alan's patterns (collections, references, derived values, permissions, migrations, seed data) with realistic Schiphol airport data.

### Constraints

- **Platform:** Alan platform only -- no custom JS, no external databases, no React. Everything must be expressible in Alan's declarative model language.
- **Deploy target:** Must deploy and work at the live URL (app.alan-platform.com/Travis_Arnold/client/)
- **Tabs only:** Alan parser requires tab indentation. Spaces cause cryptic parse errors.
- **Collection ordering:** Referenced collections must be defined before referencing collections in application.alan.
- **No booleans:** Alan has no boolean type. Use stategroup ('Yes' {} 'No' {}) instead.
- **Migration syntax:** All collections in migration.alan require `<! !>` before `( )` or `none`.
- **IDE workflow:** Edit locally, git push, IDE git pull, Alan Build (must show 0 errors), Alan Deploy.
- **versions.json:** Must exist at project root for Alan extension to detect the project.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## This Is Not a Traditional Stack
## Pinned Versions (versions.json)
## System Types
### datastore — version 116 | HIGH confidence
- Persists all collection data (Locations, Categories, Staff, Users, Found Items, Loss Reports, Matches)
- Enforces referential integrity (referenced collections must exist before referencing ones)
- Computes all derived values (counts, status derivations, reference-sets) server-side
- Enforces all `can-read`, `can-update`, `can-create`, `can-delete` permissions
- Runs `command` blocks atomically
### auto-webclient — version yar.15 | HIGH confidence
- Renders all collections as sortable, filterable tables
- Handles anonymous login (passengers filing reports) and password login (staff)
- Renders stategroup state transitions as UI buttons
- Auto-generates forms for `command` parameters
- Provides built-in CSV export and Excel report buttons
### session-manager — version 31 | HIGH confidence
- Validates username + password against `Passwords` collection
- Issues session tokens
- Supports anonymous (no login) and dynamic (password) users in the same app
### reporter — version 5 | MEDIUM confidence
- Generates `.xlsx` files for any collection on demand
- Appears as an export button in the auto-webclient automatically
## Wiring Configuration
## Connector Strategy — Flights API (Phase 10)
- Flights data is external read-only — pull on a schedule, not push
- The Schiphol API (or any public flights REST API) is polled periodically; no webhook is available for general queries
- Scheduled provider yields a snapshot dataset into the model — the datastore derives values from it
- `network::http` — HTTP requests
- `unicode::import` / `unicode::export` — text encoding
- `calendar::now` / `calendar::today` — timestamps
- `plural::sort`, `plural::filter`, `plural::first` — set operations
- `data::base64 encode/decode` — binary encoding
## What NOT to Use
| Excluded | Why |
|----------|-----|
| React / Next.js | Not applicable — Alan generates the UI |
| PostgreSQL / MongoDB | Not applicable — Alan has its own graph datastore |
| Node.js / Express | Not applicable — Alan handles server logic in the model |
| Custom JavaScript | Out of project scope; Alan is non-Turing-complete by design |
| Library connector | Only needed when exposing Alan as an API endpoint for another system; not required here |
| Consumer connector (Phase 1-9) | Only needed for reacting to model changes and pushing out. Flights is a pull, not a push. |
| file-service system type | File storage for uploads. Not needed — Lost & Found items described in text, no photo upload required in scope. |
| sign-up in session config | Passengers don't need accounts. Anonymous access covers the passenger flow. |
## Confidence Assessment
| Component | Version | Confidence | Source |
|-----------|---------|------------|--------|
| Platform version | 2024.2 | HIGH | versions.json + PROJECT.md |
| datastore | 116 | HIGH | versions.json + workflow.md (deployed and working) |
| auto-webclient | yar.15 | HIGH | versions.json + workflow.md (deployed and working) |
| session-manager | 31 | HIGH | versions.json + workflow.md (deployed and working) |
| reporter | 5 | MEDIUM | wiring-and-deployment.md example; not explicitly pinned in versions.json |
| flights connector approach | scheduled provider | MEDIUM | connectors.md pattern; Phase 10 not yet built |
## Sources
- `versions.json` — authoritative version pins for this project
- `_ref/wiring-and-deployment.md` — system types, wiring syntax, versions.json format
- `_ref/alan-skill-readme.md` — platform overview, system type roles, wiring syntax
- `_ref/connectors.md` — connector types, processor syntax, available standard libraries
- `_ref/workflow.md` — confirms live deployed versions, deploy loop
- `.planning/PROJECT.md` — project requirements, constraints, out-of-scope decisions
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
