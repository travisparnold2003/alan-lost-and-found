# Alan Project — Workflow & Chrome Automation

**Load this at the start of every session.**

---

## How the Full Loop Works

```
Edit src/ locally
  → git commit + git push
    → IDE: git pull
      → Alan Build (check for errors)
        → Alan Deploy (choose migrate or empty)
          → verify live app
```

All steps after "git push" happen via the **persistent browser server**.

---

## Persistent Browser Server

A Node.js HTTP server that keeps Chrome open and accepts commands.

**Location:** `C:\Users\Travis Arnold\AppData\Local\Temp\alan-automation\browser-server.js`

### Start-of-Session Procedure (ALWAYS follow this)

The browser server from a PREVIOUS session may still be holding port 3333 with a dead browser page. Do NOT trust a URL response — always validate the page is alive.

**Step 1 — Health check (try a goto, not just url):**
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://app.alan-platform.com/Travis_Arnold/client/"}'
```

- If you get `{"url":...}` back → browser is alive, proceed.
- If you get `{"error":"page.goto: Target page...closed"}` OR connection refused → browser is dead, go to Step 2.

**Step 2 — Kill the old server process (use PowerShell, not pkill):**

`pkill` does NOT kill Windows node processes. Use PowerShell:
```bash
powershell.exe -Command "Get-NetTCPConnection -LocalPort 3333 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess"
# Then kill it:
powershell.exe -Command "Stop-Process -Id <PID> -Force"
sleep 2
```

**Step 3 — Start a fresh server:**
```bash
node "C:\Users\Travis Arnold\AppData\Local\Temp\alan-automation\browser-server.js" &
sleep 8
# Verify it's up and browser is alive:
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://app.alan-platform.com/Travis_Arnold/client/"}'
```

**NEVER restart the browser server mid-session** — you'll lose the login session and need to re-authenticate.

---

## Browser Server API

All commands: `POST http://localhost:3333/cmd` with JSON body `{"action": "...", ...params}`

| Action | Params | Returns | Use for |
|--------|--------|---------|---------|
| `url` | — | `{url}` | check current page |
| `goto` | `url` | `{url, title}` | navigate |
| `click` | `selector` | `{ok}` | click element |
| `clickText` | `selector, text` | `{ok}` | click element containing text |
| `fill` | `selector, value` | `{ok}` | fill input |
| `type` | `text` | `{ok}` | type text (keyboard) |
| `press` | `key` | `{ok}` | press key (e.g. "Enter") |
| `wait` | `ms` | `{ok}` | wait N milliseconds |
| `waitFor` | `selector` | `{ok}` | wait for element |
| `getText` | `selector` | `{texts:[]}` | read text from elements |
| `eval` | `script` | `{result}` | run JS in page |
| `screenshot` | `path` | `{path}` | take screenshot (use sparingly!) |

### Important selectors

| What | Selector |
|------|----------|
| Error count in status bar | `.statusbar-item[id*="problems"]` |
| Status bar buttons | `.statusbar-item` (filter by text) |
| Alan Build button | `clickText(".statusbar-item", "Alan Build")` |
| Alan Deploy button | `clickText(".statusbar-item", "Alan Deploy")` |
| Alan Show button | `clickText(".statusbar-item", "Alan Show")` |
| Deploy dialog options | `.monaco-list-row` |
| Output panel text | `[id="workbench.panel.output"] .view-lines` |
| IDE terminal | `.terminal.xterm.focus` |
| Navigation items in app | `div.navigation-item >> text=Airlines` |

---

## Token-Efficient Deploy Loop

**RULE: Use text-based checks, not screenshots. Screenshots only when debugging a visual problem.**

### Step 1 — Edit files locally
Edit in `src/` using the Read/Edit tools. No browser needed.

### Step 2 — Commit and push
```bash
cd "c:/Users/Travis Arnold/Documents/Claude/Projects/alan-project/src"
git add -A && git commit -m "description" && git push
```

### Step 3 — IDE: git pull
```bash
# Open terminal in IDE (Ctrl+Backtick) then:
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://coder.alan-platform.com/Travis_Arnold/?folder=/home/coder/project"}'

# Type in terminal:
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"click","selector":".terminal.xterm.focus"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"type","text":"git pull\n"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":5000}'
```

### Step 4 — Alan Build (TEXT check, no screenshot)
```bash
# Click Alan Build
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"clickText","selector":".statusbar-item","text":"Alan Build"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":15000}'

# Check error count — should return {"texts":[" 0  0"]}
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".statusbar-item[id*=\"problems\"]"}'
```

If errors: read the output panel TEXT (not screenshot):
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":"[id=\"workbench.panel.output\"] .view-lines"}'
```

### Step 5 — Alan Deploy
```bash
# Click Alan Deploy
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"clickText","selector":".statusbar-item","text":"Alan Deploy"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":2000}'

# Read available options (text, no screenshot)
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".monaco-list-row"}'

# Click the right option (migrate = preserve data, empty = wipe and reseed)
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"clickText","selector":".monaco-list-row","text":"migrate"}'

# Wait for deploy (~30-40 seconds)
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":35000}'

# Check output for "Done"
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":"[id=\"workbench.panel.output\"] .view-lines"}'
```

### Step 6 — Verify App (text check)
```bash
# Navigate directly to the app (don't click Alan Show — it triggers a popup dialog)
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"goto","url":"https://app.alan-platform.com/Travis_Arnold/client/"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":3000}'

# Read nav items to confirm model loaded correctly
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".navigation-item"}'

# Click a collection to check data
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"click","selector":"div.navigation-item >> text=Airlines"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":1500}'

# Check if data is there (read the table text)
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"getText","selector":".content"}'
```

---

## When to Screenshot

Only take a screenshot when:
- You're getting an error you can't diagnose from text
- You need to see a UI element you can't find by selector
- You want to show Travis a visual confirmation

```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"screenshot","path":"C:/Users/Travis Arnold/AppData/Local/Temp/alan-automation/screen.png"}'
```
Then read it with the Read tool.

---

## Alan Show vs Direct Navigation

**Problem:** `Alan Show` opens a VS Code dialog "Do you want code-server to open external website?" — you can't click the button via Playwright (strict mode issues).

**Solution:** Skip `Alan Show` entirely. Navigate directly to the app URL:
```
https://app.alan-platform.com/Travis_Arnold/client/
```

---

## Login (if session expired)

If the IDE shows a login page:
```bash
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"fill","selector":"input[type=\"password\"]","value":"travis2003"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"click","selector":"input[type=\"submit\"]"}'
curl -s -X POST http://localhost:3333/cmd -H "Content-Type: application/json" \
  -d '{"action":"wait","ms":3000}'
```

---

## Git Status in IDE

If `git pull` fails due to local modifications (IDE made changes):
```bash
# In the IDE terminal:
git fetch origin && git reset --hard origin/main
```

This discards any IDE-side modifications and syncs to the remote. Safe because all real changes are committed from the LOCAL `src/` folder.

---

## "migrate" vs "empty" Decision Table

| Situation | Use |
|-----------|-----|
| Very first deploy ever | `empty` |
| Re-deploy after wiping all data (fresh start) | `empty` |
| Deploy after changing the model (normal workflow) | `migrate` |
| Deploy after Phase 1 seed data didn't load | `empty` (one more time) |

**WARNING: "empty" deletes ALL user-entered data. After Phase 1, always use "migrate" unless deliberately resetting.**

---

## Phase 2 Deploy Notes

Phase 2 adds Users/Passwords. The from_release migration will need to:
1. Map all existing Phase 1 collections (pass-through)
2. Add empty `'Users'`, `'Passwords'`, `'Access Types'` collections

The from_release/from/application.alan must be updated using "Alan: Generate Migration" in the Command Palette after switching to "from_release" as the source.

---

*Last updated: 2026-04-08*
