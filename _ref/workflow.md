# Alan Project — Workflow & Playwright MCP Guide

**Load this at the start of every session.**

---

## How the Full Loop Works

```
Edit src/ locally
  → git commit + git push
    → IDE: git pull (via Playwright)
      → Alan Fetch (first time per session)
        → Alan Build (check for " 0  0")
          → Alan Deploy (choose migrate or empty)
            → verify live app
```

---

## Playwright MCP — How to Use

The IDE is controlled via the **Playwright MCP** tools. No curl commands, no browser-server.js.

| Task | Tool | Notes |
|------|------|-------|
| Navigate to a URL | `browser_navigate` | |
| Click a button | `browser_click` | Use accessibility snapshot to find refs |
| Read page text | `browser_snapshot` | Returns accessibility tree — use this instead of screenshots |
| Type in a field | `browser_type` | Works for normal inputs |
| Type in xterm terminal | `browser_run_code` | **Special — see section below** |
| Take screenshot | `browser_take_screenshot` | Only when debugging visual issues |

### CRITICAL: xterm.js Terminal Interaction

`browser_type` does NOT work in the xterm.js terminal. Only `browser_run_code` with `page.keyboard.type()` works because xterm listens to `keydown` events, not `input` events.

**Always use this pattern for terminal commands:**
```javascript
// In browser_run_code:
await page.evaluate(() => {
  const xterms = document.querySelectorAll('.xterm-helper-textarea');
  xterms[xterms.length - 1].focus();
});
await page.keyboard.type('your command here');
await page.keyboard.press('Enter');
await page.waitForTimeout(5000); // wait for command to complete
```

### Alan Extension Activation

After any window reload, the Alan Fetch/Build/Deploy buttons only appear if an `.alan` file is open. Always open `application.alan` via Ctrl+P before attempting any Alan commands.

---

## Start-of-Session Procedure

1. Navigate to IDE: `https://coder.alan-platform.com/Travis_Arnold/?folder=/home/coder/project`
2. Log in with password `travis2003` if prompted
3. Open `application.alan` (Ctrl+P → type `application.alan` → Enter) — activates Alan extension
4. Verify Alan Fetch/Build/Deploy buttons appear in the status bar
5. If any reload happened, re-open `application.alan` before proceeding

---

## Full Deploy Loop (use every time)

### Step A — Edit files locally
Edit in `src/` using the Read/Edit tools. No browser needed.

### Step B — Commit and push
```bash
cd "c:/Users/Travis Arnold/Documents/Claude/Projects/alan-project/src"
git add -A && git commit -m "Phase X: description" && git push
```

### Step C — Alan Fetch (first time per session only)
- Needed to download the `alan` binary the first time
- Click Alan Fetch in the status bar via `browser_click`
- Wait ~10 seconds

### Step D — Git pull in IDE terminal
```javascript
// browser_run_code:
await page.evaluate(() => {
  const xterms = document.querySelectorAll('.xterm-helper-textarea');
  xterms[xterms.length - 1].focus();
});
await page.keyboard.type('git pull');
await page.keyboard.press('Enter');
await page.waitForTimeout(6000);
```

If `git pull` fails due to local modifications:
```javascript
await page.keyboard.type('git fetch origin && git reset --hard origin/main');
await page.keyboard.press('Enter');
await page.waitForTimeout(8000);
```

### Step E — Alan Build
- Click Alan Build button in status bar
- Wait ~15 seconds
- Check status bar shows `" 0  0"` — read via `browser_snapshot`
- **Never deploy with errors**

If you see errors, read the output panel via `browser_snapshot`.

### Step F — Alan Deploy
- Click Alan Deploy in status bar
- A dropdown appears — choose "migrate" or "empty" (see table below)
- Wait ~35 seconds for deploy to complete
- Check output panel for "Done"

### Step G — Verify live app
Navigate to `https://app.alan-platform.com/Travis_Arnold/client/`
Read the navigation items via `browser_snapshot`.

---

## "migrate" vs "empty" Decision Table

| Situation | Use |
|-----------|-----|
| Very first deploy ever | `empty` |
| Re-deploy after full data wipe (fresh start) | `empty` |
| Any normal model change after Phase 0 | `migrate` |
| Something went badly wrong, starting over | `empty` (wipes ALL data) |

**WARNING: "empty" deletes ALL user-entered data. After Phase 0, always use "migrate" unless deliberately resetting.**

---

## Reading File Contents via IDE

xterm.js renders on canvas — terminal output can't be read via DOM. To verify file contents after editing in the terminal:

1. Open file in editor: Ctrl+P → filename → Enter
2. Read `.view-line` elements via `browser_snapshot` or `browser_evaluate`:
   ```javascript
   // browser_run_code:
   const lines = await page.$$eval('.view-line', els => els.map(e => e.textContent));
   return lines.join('\n');
   ```

---

## Alan Show vs Direct Navigation

**Problem:** `Alan Show` opens a VS Code dialog "Do you want code-server to open external website?" — clicking it via Playwright is unreliable.

**Solution:** Skip `Alan Show`. Navigate directly:
```
https://app.alan-platform.com/Travis_Arnold/client/
```

---

## versions.json

Must exist at project root (`/home/coder/project/versions.json`) for Alan extension to find the project. Now committed to GitHub — will be present after `git pull`.

Format:
```json
{"platform version": "2024.2", "system types": {"auto-webclient": {"version": "yar.15"}, "datastore": {"version": "116"}, "session-manager": {"version": "31"}}}
```

---

## Token-Efficient Approach

- Use `browser_snapshot` (accessibility tree) instead of screenshots
- Only screenshot when debugging a visual problem
- Read file content via editor view-lines, not terminal output
- Verify state in the live app — don't trust self-reports

---

*Last updated: 2026-04-10 — Rewritten to use Playwright MCP. Old browser-server.js approach removed.*
