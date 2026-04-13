# Alan Lost & Found - Deploy Guide (Live IDE)

**Status:** Deployment infrastructure hardened locally and pushed to GitHub. This guide covers the final steps in the live IDE.

## What Was Fixed Locally

✅ **Launcher (`alan` script):** Added missing `package`, `connect` commands and fetch fallback logic  
✅ **Deploy script (`deploy.sh`):** New tracked entrypoint with deterministic logging  
✅ **.gitattributes:** LF line-ending enforcement for shell scripts  
✅ **All changes pushed to GitHub:** commit 64d6ebe

---

## Steps to Complete Deployment in Live IDE

### 1. Pull Latest Changes
```bash
cd /home/coder/project
git pull
```

Expected: Should see 2 new files:
- `.gitattributes`
- `deploy.sh` (executable)

---

### 2. Clean and Verify State

```bash
# Show current status
git status

# If dirty, clean working tree
git clean -fd
git checkout -- .

# Verify clean state
git status  # Should show: "nothing to commit, working tree clean"
```

---

### 3. Run Hard Reset (if needed)

If the project still has parse/wiring errors from prior runs:

```bash
# Completely reset to GitHub state
git reset --hard HEAD
git clean -fdx

# Re-pull to ensure sync
git pull
```

---

### 4. Execute Deployment

```bash
cd /home/coder/project
./deploy.sh migrate
```

### What This Does:
1. **Runs `./alan fetch`** → downloads/verifies platform tools, falls back to cached if network fails
2. **Runs `./alan build`** → compiles project to `dist/project.pkg`
3. **Runs `./alan deploy migrate`** → applies data migration and deploys

### Expected Output:
```
START <timestamp>
PWD /home/coder/project
MODE migrate
STEP_START fetch
STEP_OK fetch
STEP_START build
STEP_OK build
STEP_START deploy
STEP_OK deploy
END <timestamp>
EXIT_CODE 0
```

---

### 5. Check Deployment Logs

Logs are written to two files:

```bash
# Latest run (tail this during execution)
tail -f output/DEPLOY_RUN_latest.txt

# Timestamped archive (for troubleshooting)
ls -la output/DEPLOY_RUN_*.txt
cat output/DEPLOY_RUN_latest.txt
```

---

### 6. Verify App Is Live

After successful deploy:

```bash
# Open the browser and check for the app URL
# Look for a line like:
# "App available at: https://..."
```

Or check the Alan output panel in VS Code status bar:
- Click **"Alan Show"** button to open the deployed app

---

## Troubleshooting

### If Fetch Fails:
- `deploy.sh` automatically continues with cached tools
- Exit code will still be 0 if build tools exist

### If Build Fails:
- Check wiring syntax: `/home/coder/project/wiring/wiring.alan`
- Check model: `/home/coder/project/models/model/application.alan`
- Run `./alan build` directly to see full error details

### If Deploy Fails:
- Check migration syntax: `migrations/from_release/migration.alan`
- Verify `deployments/migrate/` folder exists
- Check Alan Deploy panel in VS Code for detailed error

### If Exit Code Is Non-Zero:
- One of the three steps (fetch/build/deploy) failed
- Check `output/DEPLOY_RUN_latest.txt` for which STEP_START/STEP_OK didn't complete
- Scroll down to see the actual error from that step

---

## Key Files

| File | Purpose |
|------|---------|
| `deploy.sh` | Orchestrator script (tracked, executable) |
| `alan` | Command router (fetch/build/package/connect/deploy) |
| `dist/project.pkg` | Build output artifact |
| `output/DEPLOY_RUN_latest.txt` | Live deployment log |
| `versions.json` | Platform version pinning |
| `wiring/wiring.alan` | System wiring definition |

---

## Summary

The deployment flow is now hardened with:
- ✅ Tracked deploy entrypoint (won't get deleted by `git clean`)
- ✅ Deterministic logging with explicit step markers
- ✅ Fallback to cached tools if fetch fails
- ✅ Clear exit codes and success/failure detection

**Next action:** In the live IDE, pull latest, run `./deploy.sh migrate`, and check the output log.
