# Alan Lost & Found — Build Plan V2
## For AI agents on basic models. Read every word before touching any file.

---

## CRITICAL RULES — READ BEFORE ANYTHING ELSE

1. **One phase at a time.** Complete Phase N fully (build + deploy + verify) before touching Phase N+1.
2. **Never skip verification.** Each phase ends with a manual check in the live app. If it doesn't work, fix it before continuing.
3. **application.alan structure is sacred.** This order never changes:
   ```
   users
   interfaces
   root { }
   numerical-types
   ```
4. **Reference syntax:** `text -> ^ .'CollectionName'[]` — NOT `.'Collection'* .'Key'`
5. **No boolean type in Alan.** Use `stategroup ( 'Yes' { } 'No' { } )` instead.
6. **Empty migration:** `<! !> none` — NOT `<! !> ( )`
7. **Seeded entry:** `<! !> = ( 'Field': text = "value" )`
8. **Deploy flow:** edit locally → commit+push → IDE: git pull → Alan Build (wait for "0  0") → Alan Deploy
9. **First deploy ever: choose "empty".** All subsequent deploys: choose "migrate".
10. **Build must show "0  0" in status bar before deploying.** Never deploy with errors.

---

## Working Reference
- **Online IDE:** https://coder.alan-platform.com/Travis_Arnold/?folder=/home/coder/project
- **Live app:** https://app.alan-platform.com/Travis_Arnold/client/
- **GitHub repo:** https://github.com/travisparnold2003/alan-lost-and-found
- **IDE password:** `travis2003`
- **Local src path:** `C:\Users\Travis Arnold\Documents\Claude\Projects\alan-project\src`

---

## How to Deploy (every single time — do not skip steps)

### Step A — Edit local files
Use the Edit/Write tools to change files inside the `src/` folder locally.

### Step B — Commit and push
```bash
cd "C:\Users\Travis Arnold\Documents\Claude\Projects\alan-project\src"
git add -A
git commit -m "Phase X: brief description"
git push
```

### Step C — Git pull in IDE
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://coder.alan-platform.com/Travis_Arnold/?folder=/home/coder/project"}'
# Wait 3 seconds, then click terminal:
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"click","selector":".terminal.xterm.focus"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"type","text":"git pull\n"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":6000}'
```

### Step D — Alan Build
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"clickText","selector":".statusbar-item","text":"Alan Build"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":15000}'
# CHECK — must return {"texts":[" 0  0"]}. If not, read errors and fix first.
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".statusbar-item[id*=\"problems\"]"}'
```

If errors, read the output panel:
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":"[id=\"workbench.panel.output\"] .view-lines"}'
```

### Step E — Alan Deploy
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"clickText","selector":".statusbar-item","text":"Alan Deploy"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":2000}'
# Read available options:
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".monaco-list-row"}'
# Click the correct option (see note below):
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"clickText","selector":".monaco-list-row","text":"empty"}'
# Wait for deploy (30-40 seconds):
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":40000}'
# Check deploy succeeded:
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":"[id=\"workbench.panel.output\"] .view-lines"}'
```

**"empty" vs "migrate":**
| Situation | Choose |
|-----------|--------|
| Phase 0 first deploy | **empty** |
| Phase 0 re-deploy (if broken) | **empty** |
| Phase 1 and all later phases | **migrate** |
| Something went badly wrong, starting over | **empty** (wipes all data) |

### Step F — Verify in live app
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://app.alan-platform.com/Travis_Arnold/client/"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":3000}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".navigation-item"}'
```

### Browser server health check (start of EVERY session)
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://app.alan-platform.com/Travis_Arnold/client/"}'
```
- Returns `{"url":...}` → browser alive, proceed
- Returns error or connection refused → kill old server and restart:
```bash
powershell.exe -Command "Get-NetTCPConnection -LocalPort 3333 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess"
# Then: powershell.exe -Command "Stop-Process -Id <PID> -Force"
node "C:\Users\Travis Arnold\AppData\Local\Temp\alan-automation\browser-server.js" &
# Wait 8 seconds, then retry health check
```

---

## Phase 0 — Absolute Minimum (deploy something that works)

**Goal:** A live app with one collection (Locations) that you can open in a browser and add records to.

**Files to read first:**
- `src/models/model/application.alan` (already written for you)
- `src/migrations/from_empty/to/migration.alan` (already written for you)

**What's already written:**
`src/models/model/application.alan`:
```alan
users
	anonymous

interfaces

root {
	'Locations': collection ['Location ID'] {
		'Location ID': text
		'Name': text @identifying
	}
}

numerical-types
```

`src/migrations/from_empty/to/migration.alan`:
```alan
root = root as $ (
	'Locations': collection = <! !> none
)
```

**Steps:**
1. Read `src/models/model/application.alan` — confirm it looks exactly like above.
2. Read `src/migrations/from_empty/to/migration.alan` — confirm it looks exactly like above.
3. Run browser health check.
4. Run Steps B → F (deploy with **"empty"**).
5. In the live app, check the navigation bar shows "Locations".
6. Click Locations. Try adding a new location (enter Location ID and Name, save).
7. **STOP. Verify the record saved.** If it did, Phase 0 is complete.

**Phase 0 success criteria:**
- [ ] App loads in browser
- [ ] Navigation shows "Locations"
- [ ] Can create a new location record
- [ ] Record persists after page refresh

---

## Phase 1 — Location Fields (add Terminal, Zone, Description)

**Goal:** Locations collection has all the fields it needs.

**BEFORE editing:** Read `src/models/model/application.alan` first.

**Edit `src/models/model/application.alan`** — replace the Locations collection with:
```alan
	'Locations': collection ['Location ID'] {
		'Location ID': text
		'Name': text @identifying
		'Terminal': stategroup (
			'Terminal 1' { }
			'Terminal 2' { }
			'Terminal 3' { }
			'Terminal 4' { }
		)
		'Zone': text
		'Description': text
	}
```

**Update migrations** — since we're adding NEW fields to an existing collection, we use "migrate" (preserves existing Locations data).

`src/migrations/from_release/from/migration.alan` — leave unchanged (Phase 0 snapshot).

`src/migrations/from_release/to/migration.alan` — update to map new fields with defaults:
```alan
root = root as $ (
	'Locations': collection = map $ .'Locations'* as $'l' (
		'Location ID': text = $'l' .'Location ID'
		'Name': text = $'l' .'Name'
		'Terminal': stategroup = 'Terminal 1' ( )
		'Zone': text = ""
		'Description': text = ""
	)
)
```

**Also update `from_release/from/migration.alan`** — it must now reflect what Phase 0 looked like:
```alan
root = root as $ (
	'Locations': collection = <! !> ( )
)
```
(This file should already be correct from the reset.)

**Steps:**
1. Edit `application.alan` to add the three new fields.
2. Edit `from_release/to/migration.alan` to add the three fields with defaults.
3. Commit and push.
4. Deploy with **"migrate"** (NOT "empty" — you'd lose any Locations you added in Phase 0).
5. Open app. Go to Locations. Check existing locations now show Terminal/Zone/Description fields.
6. Add a new location. Fill all fields. Save. Verify it works.

**Phase 1 success criteria:**
- [ ] Existing Location records still there
- [ ] Each location now shows Terminal, Zone, Description fields
- [ ] Can set Terminal to different terminal values
- [ ] Can edit and save a location with all fields

---

## Phase 2 — Categories Collection

**Goal:** Add an Item Categories collection so items can be categorized.

**Edit `application.alan`** — add Categories after Locations inside `root { }`:
```alan
	'Item Categories': collection ['Category ID'] {
		'Category ID': text
		'Name': text @identifying
		'Retention Days': number 'days'
		'Priority': stategroup (
			'Low' { }
			'Standard' { }
			'High' { }
			'Critical' { }
		)
	}
```

**Add to `numerical-types`** section (at the bottom of the file):
```alan
numerical-types
	'days'
```

**Update `from_release/from/migration.alan`** — now represents Phase 1 state:
```alan
root = root as $ (
	'Locations': collection = <! !> ( )
)
```
(No change needed — still just Locations.)

**Update `from_release/to/migration.alan`** — add the new collection:
```alan
root = root as $ (
	'Locations': collection = map $ .'Locations'* as $'l' (
		'Location ID': text = $'l' .'Location ID'
		'Name': text = $'l' .'Name'
		'Terminal': stategroup = $ .'Locations'* .'Terminal' (
			'Terminal 1': $ .'Terminal'?'Terminal 1' ( )
			'Terminal 2': $ .'Terminal'?'Terminal 2' ( )
			'Terminal 3': $ .'Terminal'?'Terminal 3' ( )
			'Terminal 4': $ .'Terminal'?'Terminal 4' ( )
		)
		'Zone': text = $'l' .'Zone'
		'Description': text = $'l' .'Description'
	)
	'Item Categories': collection = <! !> none
)
```

Wait — this gets complicated. SIMPLER approach for Phase 2 migration:

```alan
root = root as $ (
	'Locations': collection = map $ .'Locations'* as $'l' (
		'Location ID': text = $'l' .'Location ID'
		'Name': text = $'l' .'Name'
		'Terminal': stategroup = $'l' .'Terminal' (
			'Terminal 1': $'l' .'Terminal'?'Terminal 1' ( )
			'Terminal 2': $'l' .'Terminal'?'Terminal 2' ( )
			'Terminal 3': $'l' .'Terminal'?'Terminal 3' ( )
			'Terminal 4': $'l' .'Terminal'?'Terminal 4' ( )
		)
		'Zone': text = $'l' .'Zone'
		'Description': text = $'l' .'Description'
	)
	'Item Categories': collection = <! !> none
)
```

**Steps:**
1. Edit `application.alan` — add Item Categories collection and `'days'` to numerical-types.
2. Edit `from_release/to/migration.alan` — add `'Item Categories': collection = <! !> none` to it.
3. Commit and push.
4. Deploy with **"migrate"**.
5. Verify app shows both "Locations" and "Item Categories" in navigation.
6. Add a few categories (Electronics, Clothing, Documents). Check Priority dropdown works.

**Phase 2 success criteria:**
- [ ] Locations still intact
- [ ] Item Categories appears in navigation
- [ ] Can create categories with Name, Retention Days (number), Priority (dropdown)

---

## Phase 3 — Users & Authentication

**Goal:** Add user accounts and login. Three roles: Admin, Supervisor, Desk Agent.

**Edit `application.alan`** — change `users` section at the TOP of the file:
```alan
users
	dynamic: .'Users'
		passwords: .'Passwords'
			password-value: .'Data'.'Password'
			password-status: .'Data'.'Active' (
				| active => 'Yes' ( )
				| reset  => 'No' ( )
			)
			password-initializer: (
				'Data' = ( )
			)
```

**Add to `root { }` block** (before Locations):
```alan
	'Users': collection ['User'] {
		'User': text
		'Full Name': text @identifying
		'Email': text @validate: "[^@\\s]+@[^@\\s]+\\.[^@\\s]+"
		'Role': stategroup (
			'Admin' { }
			'Supervisor' { }
			'Desk Agent' { }
		)
		'Active': stategroup (
			'Yes' { }
			'No' { }
		)
	}
	'Passwords': collection ['User'] {
		'User': text -> ^ .'Users'[]
		'Data': group {
			'Password': text
			'Active': stategroup (
				'Yes' { }
				'No' { }
			)
		}
	}
```

**Edit `systems/sessions/config.alan`**:
```
password-authentication: enabled
user-creation: disabled
user-linking: disabled
```

**Edit `systems/client/settings.alan`** — change anonymous login line:
```
anonymous login: disabled
```

**Update `from_release/from/migration.alan`** — represents Phase 2 state (Locations + Item Categories):
```alan
root = root as $ (
	'Locations': collection = <! !> ( )
	'Item Categories': collection = <! !> ( )
)
```

**Update `from_release/to/migration.alan`**:
```alan
root = root as $ (
	'Users': collection = <! !> = (
		'User': text = "root"
		'Full Name': text = "System Administrator"
		'Email': text = "admin@lostandfound.system"
		'Role': stategroup = 'Admin' ( )
		'Active': stategroup = 'Yes' ( )
	)
	'Passwords': collection = <! !> = (
		'User': text = "root"
		'Data': group = (
			'Password': text = "welcome"
			'Active': stategroup = 'No' ( )
		)
	)
	'Locations': collection = map $ .'Locations'* as $'l' (
		'Location ID': text = $'l' .'Location ID'
		'Name': text = $'l' .'Name'
		'Terminal': stategroup = $'l' .'Terminal' (
			'Terminal 1': $'l' .'Terminal'?'Terminal 1' ( )
			'Terminal 2': $'l' .'Terminal'?'Terminal 2' ( )
			'Terminal 3': $'l' .'Terminal'?'Terminal 3' ( )
			'Terminal 4': $'l' .'Terminal'?'Terminal 4' ( )
		)
		'Zone': text = $'l' .'Zone'
		'Description': text = $'l' .'Description'
	)
	'Item Categories': collection = map $ .'Item Categories'* as $'c' (
		'Category ID': text = $'c' .'Category ID'
		'Name': text = $'c' .'Name'
		'Retention Days': number 'days' = $'c' .'Retention Days'
		'Priority': stategroup = $'c' .'Priority' (
			'Low': $'c' .'Priority'?'Low' ( )
			'Standard': $'c' .'Priority'?'Standard' ( )
			'High': $'c' .'Priority'?'High' ( )
			'Critical': $'c' .'Priority'?'Critical' ( )
		)
	)
)
```

**IMPORTANT — Password is set as 'No' (reset state).** On first login, Alan will prompt user to set a new password. Login with username `root`, password `welcome`, then set new password.

**Steps:**
1. Edit all files above.
2. Commit and push.
3. Deploy with **"migrate"**.
4. Open app — should now show a login screen.
5. Login: User = `root`, Password = `welcome`.
6. Should be prompted to set a new password. Set it to something you'll remember.
7. After login, verify you can see Locations and Item Categories.

**Phase 3 success criteria:**
- [ ] App shows login screen (no anonymous access)
- [ ] Can login with root / welcome → forced to set new password
- [ ] After login, previous data (Locations, Categories) still there
- [ ] Can add more users via the Users collection

---

## Phase 4 — Found Items (Basic)

**Goal:** Staff can log a found item with basic fields.

**Edit `application.alan`** — add to `root { }` after Item Categories:
```alan
	'Found Items': collection ['Item ID'] {
		'Item ID': text
		'Category': text -> ^ .'Item Categories'[]
		'Description': text @identifying
		'Location Found': text -> ^ .'Locations'[]
		'Date Found': number 'date'
		'Status': stategroup (
			'Logged' { }
			'Stored' { }
			'Returned' { }
		)
	}
```

**Add to `numerical-types`**:
```alan
	'date' in 'days'
		= 'date-time' + -43200 * 10 ^ 0 in 'seconds'
		@date
	'date-time': time-in-seconds in 'seconds' @date-time
	'days'
		= 'seconds' / 86400 * 10 ^ 0
	'seconds' @duration: seconds
```

Wait — `'days'` is already defined. Only add the types that aren't already there. Here's the complete `numerical-types` section after Phase 4:
```alan
numerical-types
	'days'
	'date' in 'days'
		= 'date-time' + -43200 * 10 ^ 0 in 'seconds'
		@date
	'date-time': time-in-seconds in 'seconds' @date-time
	'seconds' @duration: seconds
```

**Update migrations** — add Found Items to from_release/to, update from_release/from to Phase 3 state:

`from_release/from/migration.alan`:
```alan
root = root as $ (
	'Users': collection = <! !> ( )
	'Passwords': collection = <! !> ( )
	'Locations': collection = <! !> ( )
	'Item Categories': collection = <! !> ( )
)
```

`from_release/to/migration.alan`:
```alan
root = root as $ (
	'Users': collection = map $ .'Users'* as $'u' (
		'User': text = $'u' .'User'
		'Full Name': text = $'u' .'Full Name'
		'Email': text = $'u' .'Email'
		'Role': stategroup = $'u' .'Role' (
			'Admin': $'u' .'Role'?'Admin' ( )
			'Supervisor': $'u' .'Role'?'Supervisor' ( )
			'Desk Agent': $'u' .'Role'?'Desk Agent' ( )
		)
		'Active': stategroup = $'u' .'Active' (
			'Yes': $'u' .'Active'?'Yes' ( )
			'No': $'u' .'Active'?'No' ( )
		)
	)
	'Passwords': collection = map $ .'Passwords'* as $'p' (
		'User': text = $'p' .'User'
		'Data': group = $'p' .'Data' (
			'Password': text = $'p' .'Data'.'Password'
			'Active': stategroup = $'p' .'Data'.'Active' (
				'Yes': $'p' .'Data'.'Active'?'Yes' ( )
				'No': $'p' .'Data'.'Active'?'No' ( )
			)
		)
	)
	'Locations': collection = map $ .'Locations'* as $'l' (
		'Location ID': text = $'l' .'Location ID'
		'Name': text = $'l' .'Name'
		'Terminal': stategroup = $'l' .'Terminal' (
			'Terminal 1': $'l' .'Terminal'?'Terminal 1' ( )
			'Terminal 2': $'l' .'Terminal'?'Terminal 2' ( )
			'Terminal 3': $'l' .'Terminal'?'Terminal 3' ( )
			'Terminal 4': $'l' .'Terminal'?'Terminal 4' ( )
		)
		'Zone': text = $'l' .'Zone'
		'Description': text = $'l' .'Description'
	)
	'Item Categories': collection = map $ .'Item Categories'* as $'c' (
		'Category ID': text = $'c' .'Category ID'
		'Name': text = $'c' .'Name'
		'Retention Days': number 'days' = $'c' .'Retention Days'
		'Priority': stategroup = $'c' .'Priority' (
			'Low': $'c' .'Priority'?'Low' ( )
			'Standard': $'c' .'Priority'?'Standard' ( )
			'High': $'c' .'Priority'?'High' ( )
			'Critical': $'c' .'Priority'?'Critical' ( )
		)
	)
	'Found Items': collection = <! !> none
)
```

**Steps:**
1. Edit `application.alan` — add Found Items collection and date numerical-types.
2. Update migrations as above.
3. Commit and push.
4. Deploy with **"migrate"**.
5. Verify "Found Items" appears in navigation.
6. Create a Found Item — select a Category and Location from dropdowns, enter Description, set Date Found and Status.
7. Verify it saves.

**Phase 4 success criteria:**
- [ ] Found Items in navigation
- [ ] Category dropdown shows categories entered in Phase 2
- [ ] Location Found dropdown shows locations entered in Phase 1
- [ ] Can create and save a Found Item record
- [ ] Status dropdown shows Logged/Stored/Returned

---

## Phase 5 — Loss Reports (Basic)

**Goal:** Public users can file a loss report. Same pattern as Phase 4.

**Edit `application.alan`** — add after Found Items:
```alan
	'Loss Reports': collection ['Report ID'] {
		'Report ID': text
		'Category': text -> ^ .'Item Categories'[]
		'Description': text @identifying
		'Location Lost': text -> ^ .'Locations'[]
		'Date Lost': number 'date'
		'Owner Name': text
		'Owner Email': text @validate: "[^@\\s]+@[^@\\s]+\\.[^@\\s]+"
		'Status': stategroup (
			'Filed' { }
			'Matched' { }
			'Returned' { }
			'Closed' { }
		)
	}
```

**Update migrations** (same pattern as Phase 4 — just add Loss Reports to the to migration):
```alan
	'Loss Reports': collection = <! !> none
```

Add this line to the end of the `root = root as $ (...)` block in `from_release/to/migration.alan`.

Also update `from_release/from/migration.alan` to reflect the Phase 4 state (add Found Items).

**Steps:**
1. Edit application.alan — add Loss Reports.
2. Update from_release/from/ to include Found Items (Phase 4 state).
3. Add Loss Reports entry to from_release/to/ migration.
4. Commit + push → deploy "migrate".
5. Verify Loss Reports in navigation.
6. File a test loss report. Check Category and Location dropdowns work.

**Phase 5 success criteria:**
- [ ] Loss Reports in navigation
- [ ] Can file a loss report with all fields
- [ ] Dropdowns reference correct Categories and Locations

---

## Phase 6 — Dashboard (Live Counts)

**Goal:** A Dashboard group that shows live counts — no manual entry needed, fully automatic.

**Edit `application.alan`** — add a Dashboard group INSIDE `root { }`, after all collections:
```alan
	'Dashboard': group @breakout {
		'Total Found Items': number 'units' = count ^ .'Found Items'*
		'Total Loss Reports': number 'units' = count ^ .'Loss Reports'*
		'Open Found Items': number 'units' = count ^ .'Found Items'* .'Status'?'Logged'
		'Open Loss Reports': number 'units' = count ^ .'Loss Reports'* .'Status'?'Filed'
	}
```

**Add to numerical-types**:
```alan
	'units'
```

**Update migrations** (same pattern — Dashboard group has only derived values, no data to migrate):
In `from_release/to/migration.alan`, the Dashboard group does NOT need a migration entry because it contains only derived/computed values. Just update the from snapshot to Phase 5 state.

**Steps:**
1. Edit application.alan — add Dashboard group with derived counts.
2. Add `'units'` to numerical-types.
3. Update migrations.
4. Commit + push → deploy "migrate".
5. Open app — click Dashboard in navigation.
6. Add a Found Item. Come back to Dashboard. Verify "Total Found Items" count went up by 1.

**Phase 6 success criteria:**
- [ ] Dashboard appears in navigation
- [ ] Counts update in real-time as records are added
- [ ] Open counts correctly filter by status

---

## Phase 7 — Seed Data via Migrations

**Goal:** Have real-looking sample data so the app looks good for a demo.

**Edit `src/migrations/from_empty/to/migration.alan`** — add seed data:
```alan
root = root as $ (
	'Locations': collection = <! !> (
		= ( 'Location ID': text = "LOC001"  'Name': text = "Departure Hall - Terminal 2"  'Terminal': stategroup = 'Terminal 2' ( )  'Zone': text = "Departure"  'Description': text = "Main departure area" )
		= ( 'Location ID': text = "LOC002"  'Name': text = "Baggage Claim - Terminal 1"  'Terminal': stategroup = 'Terminal 1' ( )  'Zone': text = "Arrivals"  'Description': text = "Baggage carousel area" )
		= ( 'Location ID': text = "LOC003"  'Name': text = "Security North - Terminal 3"  'Terminal': stategroup = 'Terminal 3' ( )  'Zone': text = "Security"  'Description': text = "North security checkpoint" )
		= ( 'Location ID': text = "LOC004"  'Name': text = "Lounge B - Terminal 2"  'Terminal': stategroup = 'Terminal 2' ( )  'Zone': text = "Airside"  'Description': text = "Business class lounge" )
		= ( 'Location ID': text = "LOC005"  'Name': text = "Gate D14"  'Terminal': stategroup = 'Terminal 2' ( )  'Zone': text = "Airside"  'Description': text = "Schengen gate area" )
	)
	'Item Categories': collection = <! !> (
		= ( 'Category ID': text = "CAT001"  'Name': text = "Electronics"  'Retention Days': number 'days' = 30  'Priority': stategroup = 'High' ( ) )
		= ( 'Category ID': text = "CAT002"  'Name': text = "Clothing & Accessories"  'Retention Days': number 'days' = 60  'Priority': stategroup = 'Standard' ( ) )
		= ( 'Category ID': text = "CAT003"  'Name': text = "Documents & ID"  'Retention Days': number 'days' = 365  'Priority': stategroup = 'Critical' ( ) )
		= ( 'Category ID': text = "CAT004"  'Name': text = "Luggage & Bags"  'Retention Days': number 'days' = 90  'Priority': stategroup = 'Standard' ( ) )
		= ( 'Category ID': text = "CAT005"  'Name': text = "Jewellery & Valuables"  'Retention Days': number 'days' = 180  'Priority': stategroup = 'High' ( ) )
	)
	'Users': collection = <! !> (
		= ( 'User': text = "root"  'Full Name': text = "System Administrator"  'Email': text = "admin@lostandfound.ams"  'Role': stategroup = 'Admin' ( )  'Active': stategroup = 'Yes' ( ) )
		= ( 'User': text = "sarah.jones"  'Full Name': text = "Sarah Jones"  'Email': text = "sarah.jones@schiphol.nl"  'Role': stategroup = 'Supervisor' ( )  'Active': stategroup = 'Yes' ( ) )
		= ( 'User': text = "mike.chen"  'Full Name': text = "Mike Chen"  'Email': text = "mike.chen@schiphol.nl"  'Role': stategroup = 'Desk Agent' ( )  'Active': stategroup = 'Yes' ( ) )
		= ( 'User': text = "anna.kraft"  'Full Name': text = "Anna Kraft"  'Email': text = "anna.kraft@schiphol.nl"  'Role': stategroup = 'Desk Agent' ( )  'Active': stategroup = 'Yes' ( ) )
	)
	'Passwords': collection = <! !> (
		= ( 'User': text = "root"  'Data': group = ( 'Password': text = "welcome"  'Active': stategroup = 'No' ( ) ) )
		= ( 'User': text = "sarah.jones"  'Data': group = ( 'Password': text = "welcome"  'Active': stategroup = 'No' ( ) ) )
		= ( 'User': text = "mike.chen"  'Data': group = ( 'Password': text = "welcome"  'Active': stategroup = 'No' ( ) ) )
		= ( 'User': text = "anna.kraft"  'Data': group = ( 'Password': text = "welcome"  'Active': stategroup = 'No' ( ) ) )
	)
	'Found Items': collection = <! !> none
	'Loss Reports': collection = <! !> none
)
```

**IMPORTANT:** The seed data only loads when you deploy with **"empty"**. This wipes all existing data. Only do this if you're doing a fresh demo reset. For normal development, keep using "migrate".

**Steps:**
1. Edit from_empty/to/migration.alan with seed data above.
2. Commit + push.
3. Deploy with **"empty"** (intentional data wipe — loads seed data).
4. Login with root / welcome → set new password.
5. Verify all 5 locations, 5 categories, 4 users are there.
6. Log a Found Item, file a Loss Report. Check Dashboard counts.

**Phase 7 success criteria:**
- [ ] 5 sample locations pre-loaded
- [ ] 5 sample categories pre-loaded
- [ ] 4 sample users pre-loaded (all with welcome password, require reset)
- [ ] Dashboard shows correct counts as you add items

---

## Phase 8 — Role-Based Permissions

**Goal:** Limit what each user type can do.
- Admin: full access
- Supervisor: can see and manage everything, cannot manage Users
- Desk Agent: can log found items and file reports, cannot confirm matches

**Add permissions to `application.alan`** collections:

On the Found Items collection:
```alan
	'Found Items': collection ['Item ID']
		can-create: user
	{
		can-update: user .'Role'?'Admin' || user .'Role'?'Supervisor'
		...
	}
```

On the Users collection:
```alan
	'Users': collection ['User'] {
		can-create: user .'Role'?'Admin'
		can-update: user .'Role'?'Admin'
		...
	}
```

Refer to the battery passport's application.alan for exact permission syntax patterns — it uses `can-read`, `can-update`, `can-create`, `can-execute` with `user .'Field'?'State'` conditions.

---

## Phase 9 — Matching System

**Goal:** Staff can propose and confirm matches between Lost reports and Found items.

Add a Matches collection:
```alan
	'Matches': collection ['Match ID'] {
		'Match ID': text
		'Found Item': text -> ^ .'Found Items'[]
		'Loss Report': text -> ^ .'Loss Reports'[]
		'Proposed By': text -> ^ .'Users'[]
		'Date Proposed': number 'date'
		'Notes': text
		'Status': stategroup (
			'Proposed' { }
			'Confirmed' {
				'Confirmed By': text -> ^ ^ .'Users'[]
				'Date Confirmed': number 'date'
			}
			'Rejected' {
				'Rejected By': text -> ^ ^ .'Users'[]
				'Date Rejected': number 'date'
				'Reason': text
			}
		)
	}
```

---

## Phase 10 — Flights API Integration (Bonus)

**Goal:** Show live flight data alongside lost items for Rick's "wow factor".

This phase requires adding a **connector** to an external flights API (e.g. AviationStack or OpenSky Network).

Steps:
1. Choose a free flights API with a simple REST endpoint
2. Read `_ref/connectors.md` for Alan connector syntax
3. Add a connector system to `wiring.alan`
4. Add a `Flights` group to application.alan that consumes the connector
5. Link active Loss Reports to flight numbers from the API

This phase is complex — only attempt after Phases 0-9 are all working.

---

## Migration Pattern Quick Reference

Every time you add a collection or field:

1. **Add to `application.alan`**
2. **Update `from_release/from/migration.alan`** → make it match the PREVIOUS phase's model
3. **Update `from_release/to/migration.alan`** → add the new collection/field with a default
4. **Deploy with "migrate"**

For new collections: `'New Collection': collection = <! !> none`
For new text fields: `'New Field': text = ""`
For new number fields: `'New Number': number 'units' = 0`
For new stategroup fields: `'New Status': stategroup = 'DefaultState' ( )`
For new group fields: `'New Group': group = ( 'SubField': text = "" )`

---

*Last updated: 2026-04-10 — complete rewrite after agent left broken code*
