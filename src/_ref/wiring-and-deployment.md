# Alan Wiring, Deployment, and Project Setup

## Project Layout (canonical template)

```
project/
├── _docs/                         # Optional documentation
├── deployments/
│   └── <env-name>/
│       ├── deployment.alan        # Target server URL, image config
│       └── default.data          # (generated on deploy)
├── interfaces/                    # Interface definitions (if consuming external APIs)
│   └── <name>/
│       └── interface.alan
├── migrations/
│   ├── from_empty/                # Used on FIRST deploy
│   │   ├── from/application.alan  # Empty stub model
│   │   ├── to -> ../../models/model/application.alan
│   │   └── migration.alan
│   └── from_release/              # Used on ALL subsequent deploys
│       ├── from/application.alan  # Auto-generated previous model snapshot
│       ├── to -> ../../models/model/application.alan
│       └── migration.alan
├── models/
│   └── model/
│       └── application.alan       # Main model
├── systems/
│   ├── server/                    # Datastore system
│   ├── client/
│   │   └── settings.alan          # UI/webclient config
│   ├── reporter/                  # Excel report system
│   └── sessions/
│       └── config.alan            # Auth config
├── wiring/
│   └── project.wiring
├── alan                           # Alan CLI (binary, not in git)
├── README.md                      # App URL after deploy
└── versions.json                  # Platform and system type versions
```

**Git ignore:** Always exclude `/deployments/` and `/.alan/` from version control. They are environment-specific.

---

## versions.json

Pins platform and system-type versions:

```json
{
    "project": "~5",
    "alan": "~7",
    "systems": {
        "datastore": "~116",
        "reporter": "~5",
        "webclient": "~yar.11.0",
        "auto-webclient": "~yar.11",
        "sessions": "~35",
        "file-service": "~3"
    }
}
```

Run **Alan Fetch** after changing versions.json to download the correct platform tools.

---

## Wiring File (project.wiring)

Describes what systems make up the project and how they interconnect:

```
interfaces {
	// Declare external interfaces if consumed:
	// 'ExternalSystem': @'"interfaces/external-system"'
}

models
	'model': @'"models/model"'

// External systems your project talks to
external systems {
	// 'ExternalAPI': interface 'ExternalSystem'
}

// Internal systems (active server components)
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

provided connections {
	// Expose connections to external consumers if needed
}
```

---

## Client Settings (systems/client/settings.alan)

Controls the auto-generated webclient:

```
"application creator": "Kjerner"
"application name": "My Application"
"allow anonymous user": disabled    // or: enabled
"enable csv actions": enabled       // CSV import/export buttons
"report limit": 10000
"language": "en"
"engine language": english          // or: dutch (affects sort, date formats)

// Optional: custom theme
"theme": (
	"brand": "#1a73e8"
	"foreground": "#202124"
	"background": "#ffffff"
)

// Optional: custom landing page
"has landing page": enabled (
	// configure landing page path here
)
```

---

## Session Manager (systems/sessions/config.alan)

```
password-authentication: enabled

// Optional: allow users to sign up themselves
// sign-up: enabled
// user-role: 'Standard' ( )    // default role on sign-up
```

---

## Deployment Config (deployments/<name>/deployment.alan)

Auto-generated on deploy. Contains:
- Target server URL
- Image configuration
- System bindings

**Do NOT commit deployment files.** Each developer/environment has their own. Add `/deployments/` to `.gitignore`.

---

## Deploy Workflow

### First-ever deploy (empty dataset)
1. `Alan Fetch` — download platform tools
2. `Alan Build` — compile and check
3. `Alan Deploy` → choose **empty**
4. Default credentials: `root` / `welcome` (forced reset on first login)

### Deploy after model changes
1. `Alan Build` — must succeed with 0 errors
2. `Alan: Generate Migration` (Command Palette) → select **from_release** option
3. Review and edit `migrations/from_release/migration.alan`
4. `Alan Deploy` → choose **migrate**
5. The system will run the migration on the live data (brief downtime ~1-2 min)

### If migration generates errors
- Check the migration.alan for missing property mappings
- Every base property in the old model must appear in migration
- Add derived properties to the OLD model snapshot if complex transformation is needed

---

## Interface Definitions (for external systems)

When another Alan app or external system needs to communicate with yours, define an interface:

```alan
// interfaces/supplier-api/interface.alan
root {
	'Products': collection ['SKU'] {
		'SKU': text
		'Name': text
		'Price': number 'eurocent'
	}

	'Update product price': command {
		'SKU': text
		'New price': number 'eurocent'
	}
}

numerical-types
	'eurocent'
```

Declare it in wiring and map it to your model in the datastore settings.

---

## Connector System

Add a connector when you need to integrate with external HTTP APIs, databases, or messaging systems.

Add to wiring:
```
systems
	'my-connector': @'"systems/my-connector"'
		mapping (
			'model': @'model'
		)
```

Create `systems/my-connector/`:
- `processor.alan` — main connector logic
- `variables.alan` — config variables (API keys, URLs)

### Connector Types
- **Scheduled provider** — runs on a timer, pushes data snapshots
- **Consumer** — reacts to model changes or events
- **Library** — exposes hooks for other systems

---

## Version Control Setup

```bash
# Initialize git
git init
git add -A
git commit -m "Initial Alan project"

# Add remote
git remote add origin git@github.com:org/repo.git
git push -u origin main

# .gitignore contents:
/.alan/
/deployments/
```

Local development: clone repo, use VS Code with the Alan extension (Kjerner.alan on Marketplace). Editing locally is fine; deployment MUST be done from the online IDE.

For SSH key setup:
```bash
ssh-keygen -t ed25519 -C "travis@example.com"
# Upload ~/.ssh/id_ed25519.pub to GitHub Settings → SSH Keys
```
