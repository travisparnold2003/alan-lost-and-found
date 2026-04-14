# Research Summary — Schiphol Lost & Found

## Executive Summary

This is not a traditional web application. Alan v2024.2 generates the entire system -- database, UI, auth, permissions, and reporting -- from a single `application.alan` model file. There is no React, Node, Postgres, or REST API to design. The recommended approach is to build in strict collection dependency order: fix the broken foundation first (missing `anonymous` in users block, broken date annotation, missing Staff collection), then add collections incrementally, then layer derived values and permissions, and finally add the flights connector as an additive external system in Phase 10.

Rick will evaluate this demo through the lens of Alan mastery: reference-sets with bidirectional inverse aggregation, derived stategroups chained through reference navigation, role-based permissions at field granularity, and the connector integration. Pre-seeded realistic Schiphol demo data is non-negotiable -- an empty app at demo time produces zero impression.

The dominant risk is not architectural but syntactic. Alan gives misdirecting error messages for tab/space indentation, migration `<! !>` omissions, wiring file rewrites, and incorrect date annotations. All of these have occurred in this project's 40+ commit history. The universal mitigation: always read the current working file before editing, make targeted changes only, verify the live app (not just build output) after every deploy.

## Key Findings

**Stack:** Four system types, all pinned and deployed: datastore v116 (graph DB), auto-webclient yar.15 (generated UI), session-manager v31 (mixed auth), reporter v5 (Excel export). Flights connector deferred to Phase 10 as a scheduled provider.

**Features:**
- Table stakes: Found item logging with full status workflow, anonymous loss report filing, categories with retention, location tracking, staff roles, match confirmation, dashboard counts, pre-seeded data
- Differentiators: Reference-sets on Staff (activity counts), derived Is Overdue flag, priority inheritance via reference navigation, derived display labels, Loss Report status from confirmed Match, flights API connector
- Anti-features: Email notifications, photo uploads, multi-language, custom CSS -- all explicitly out of scope

**Architecture:** Strict acyclic dependency graph. Required definition order: Locations -> Item Categories -> Users -> Passwords -> Staff -> Loss Reports -> Found Items -> Matches -> Dashboard. Matches is the terminal node. Flights connector is fully additive -- no changes to application.alan.

**Known broken items in current model:** Missing `anonymous` in users block; no Staff collection (refs wrong); Found Items Status missing states; broken numerical-types date annotation; no permissions anywhere.

**Top pitfalls (all confirmed from git history):**
1. Tab vs space indentation -- causes cryptic misdirecting parse errors
2. Migration `<! !>` rule -- exact error: `expected keyword '<!''`
3. Wiring rewrite -- 6+ prior failures; add blocks, never replace
4. from_release/from/ snapshot not updated between phases
5. Deploy without git pull in IDE (xterm.js keyboard event requirement)
6. Self-reported build success without live app verification

## Roadmap Implications

Suggested phases: **10**

1. **Foundation Fixes** -- fix `anonymous`, numerical-types, structural skeleton before anything else
2. **Reference Tables + First Migration** -- Locations + Categories, proves from_empty works
3. **Auth Layer** -- Users, Passwords, Staff; auth must precede Found Items
4. **Loss Reports** -- anonymous filing, isolated test of anonymous access path
5. **Found Items** -- depends on Categories, Locations, Staff all correct
6. **Matches** -- terminal node, requires both Found Items and Loss Reports
7. **Dashboard + Seed Data** -- derived counts + from_empty reset with realistic Schiphol data
8. **Derived Values + Reference-Sets** -- Is Overdue, priority inheritance, Staff activity counts
9. **Permissions Layer** -- easiest to verify against populated data
10. **Flights API Connector** -- additive external system, Rick's "wow factor" feature

## Research Flags

Needs deeper research before planning: Phase 8 (reference-set inverse syntax, nodes/none pattern), Phase 9 (anonymous-create permission syntax), Phase 10 (connector processor + wiring).

Standard patterns (skip research-phase): Phase 1, Phase 2, Phase 3, Phase 7.

## Confidence

Overall: **HIGH** -- stack is confirmed deployed, pitfalls sourced from real failures in git history, architecture derived from direct doc analysis.

Gaps: Anonymous-create permission exact syntax; reference-set `downstream` exact syntax; Schiphol API availability (need fallback mock for Phase 10); src/ vs root-level directory split needs one-time verification.
