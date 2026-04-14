# Technology Stack — Schiphol Lost & Found (Alan Platform)

**Project:** alan-lost-and-found
**Researched:** 2026-04-14
**Platform:** Alan v2024.2 by Kjerner (model-driven declarative, not a traditional web stack)

---

## This Is Not a Traditional Stack

Alan generates the entire application — database, web UI, auth, SQL sync, Excel export — from a single `application.alan` model file. There is no React, no Node, no Postgres, no REST API to design. The "stack" decision is which Alan system types to wire together and at what versions.

---

## Pinned Versions (versions.json)

These are the live, working versions currently pinned in the project. They match what is deployed and known to work at `app.alan-platform.com/Travis_Arnold/client/`.

```json
{
    "platform version": "2024.2",
    "system types": {
        "auto-webclient": {"version": "yar.15"},
        "datastore": {"version": "116"},
        "session-manager": {"version": "31"}
    }
}
```

**Do not change these versions without a deliberate Alan Fetch cycle.** The wiring doc examples show older illustrative versions (yar.11, sessions ~35) — the versions.json above is ground truth.

---

## System Types

### datastore — version 116 | HIGH confidence

**What it is:** The Alan graph database engine. Stores all collections, enforces references, computes derived values, runs commands, applies permissions.

**Why v116:** This is the version confirmed deployed and working for this project. It is the current stable release for Alan v2024.2.

**Responsibilities:**
- Persists all collection data (Locations, Categories, Staff, Users, Found Items, Loss Reports, Matches)
- Enforces referential integrity (referenced collections must exist before referencing ones)
- Computes all derived values (counts, status derivations, reference-sets) server-side
- Enforces all `can-read`, `can-update`, `can-create`, `can-delete` permissions
- Runs `command` blocks atomically

**Do not use:** There is no alternative datastore — this is the only option in Alan.

---

### auto-webclient — version yar.15 | HIGH confidence

**What it is:** Alan's auto-generated web UI. Renders every collection, stategroup, reference, and command in the model as a responsive browser interface. No custom frontend code required or permitted for this project.

**Why yar.15:** The current pinned version for this project. Later than the illustrative yar.11 example in the wiring docs. Provides the UI annotations (`@identifying`, `@breakout`, `@small`, `@hidden`, `@description`) used throughout the model.

**Responsibilities:**
- Renders all collections as sortable, filterable tables
- Handles anonymous login (passengers filing reports) and password login (staff)
- Renders stategroup state transitions as UI buttons
- Auto-generates forms for `command` parameters
- Provides built-in CSV export and Excel report buttons

**Configuration file:** `systems/client/settings.alan`

Key settings for Lost & Found:
```
"allow anonymous user": enabled     // passengers can file without login
"application name": "Schiphol Lost & Found"
"language": "en"
"engine language": english
```

**Do not use custom CSS or JS.** Out of scope. Auto-webclient handles everything. Any UI customisation goes through `settings.alan` and model annotations only.

---

### session-manager — version 31 | HIGH confidence

**What it is:** Handles authentication. Validates passwords, manages sessions, issues tokens to the datastore.

**Why v31:** Confirmed working version in this project. The wiring doc shows a newer v35 as an illustrative example but the project versions.json pins v31 and it is deployed and functional.

**Responsibilities:**
- Validates username + password against `Passwords` collection
- Issues session tokens
- Supports anonymous (no login) and dynamic (password) users in the same app

**Configuration file:** `systems/sessions/config.alan`

Required setting:
```
password-authentication: enabled
```

**Mixed auth model for Lost & Found:** The `application.alan` users block uses `dynamic` (staff password auth) while the auto-webclient has anonymous login enabled. This lets passengers submit Loss Reports without accounts while staff must log in to access Found Items management and Matches.

First-deploy credentials: username `root`, password `welcome` (forced reset on first login).

---

### reporter — version 5 | MEDIUM confidence

**What it is:** Generates downloadable Excel reports from model data.

**Why include it:** Low-cost addition (already in the standard wiring template). Provides Excel/CSV export buttons that Alan staff or airport supervisors would naturally expect. Version 5 is the current standard.

**Responsibilities:**
- Generates `.xlsx` files for any collection on demand
- Appears as an export button in the auto-webclient automatically

**Configuration:** No configuration file needed. Declared in wiring only.

---

## Wiring Configuration

Standard wiring for this project (`wiring/project.wiring`):

```
interfaces { }

models
	'model': @'"models/model"'

systems
	'server': @'"systems/server"'
		mapping (
			'model': @'model'
		)
	'client': @'"systems/client"'
		mapping (
			'model': @'model'
		)
	'reporter': @'"systems/reporter"'
		mapping (
			'model': @'model'
		)
	'sessions': @'"systems/sessions"'
		mapping (
			'model': @'model'
		)
```

**No external systems block needed** until the flights API connector phase (Phase 10 in project spec).

---

## Connector Strategy — Flights API (Phase 10)

The flights API integration is explicitly scoped to Phase 10 as the "wow factor" feature for Rick.

**Approach: Scheduled Provider connector**

Use a `scheduled provider` connector, not a consumer or library hook. Rationale:
- Flights data is external read-only — pull on a schedule, not push
- The Schiphol API (or any public flights REST API) is polled periodically; no webhook is available for general queries
- Scheduled provider yields a snapshot dataset into the model — the datastore derives values from it

**Connector structure:**
```
systems/
  flights-connector/
    processor.alan     -- scheduled HTTP pull from flights API
    variables.alan     -- API key, base URL
```

**Wiring addition for Phase 10:**
```
systems
	'flights-connector': @'"systems/flights-connector"'
		mapping (
			'model': @'model'
		)
```

**Processor pattern (scheduled provider):**
```
provider scheduled
	dataset: from main routine
	main routine
	do {
		let $'api-key' = ^ $'API key'
		let $'response' = call 'network'::'http' with (
			$'url' = concat ( ^ $'Base URL' , "/flights?flightDirection=A&app_key=" , $'api-key' )
			$'method' = "GET"
			$'headers' = { "Accept": "application/json" }
		)
		let $'body' = $'response'.'body' get || throw "No response body"
		let $'text' = $'body' => call 'unicode'::'import' with ( $'encoding' = "UTF-8" )
		let $'data' = $'text' => parse as JSON
		// walk $'data' and yield snapshot
	}
	command handlers { }
```

**Standard libraries available in processor (no external packages needed):**
- `network::http` — HTTP requests
- `unicode::import` / `unicode::export` — text encoding
- `calendar::now` / `calendar::today` — timestamps
- `plural::sort`, `plural::filter`, `plural::first` — set operations
- `data::base64 encode/decode` — binary encoding

**Defer connector to Phase 10.** Adding it before the core model is stable creates unnecessary wiring complexity and a harder migration path.

---

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

---

## Confidence Assessment

| Component | Version | Confidence | Source |
|-----------|---------|------------|--------|
| Platform version | 2024.2 | HIGH | versions.json + PROJECT.md |
| datastore | 116 | HIGH | versions.json + workflow.md (deployed and working) |
| auto-webclient | yar.15 | HIGH | versions.json + workflow.md (deployed and working) |
| session-manager | 31 | HIGH | versions.json + workflow.md (deployed and working) |
| reporter | 5 | MEDIUM | wiring-and-deployment.md example; not explicitly pinned in versions.json |
| flights connector approach | scheduled provider | MEDIUM | connectors.md pattern; Phase 10 not yet built |

---

## Sources

- `versions.json` — authoritative version pins for this project
- `_ref/wiring-and-deployment.md` — system types, wiring syntax, versions.json format
- `_ref/alan-skill-readme.md` — platform overview, system type roles, wiring syntax
- `_ref/connectors.md` — connector types, processor syntax, available standard libraries
- `_ref/workflow.md` — confirms live deployed versions, deploy loop
- `.planning/PROJECT.md` — project requirements, constraints, out-of-scope decisions
