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
