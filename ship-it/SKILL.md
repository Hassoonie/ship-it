---
name: ship-it
description: "This skill should be used when the user wants to go from idea to MVP, says 'build this', 'ship it', 'create an app', 'build me a product', 'idea to MVP', 'make this real', 'full build', 'zero to one', or provides a product idea and expects autonomous end-to-end execution. Orchestrates research, planning, and building to ship complete working software from a single prompt."
version: 2.0.0
---

# Ship It — Idea to MVP Orchestrator

Autonomous end-to-end product builder. Takes a single idea and ships a working MVP by orchestrating research, planning, and iterative execution with built-in guardrails against the 10 most common AI agent failure modes.

## Core Principles

1. **Walking skeleton first** — Get the thinnest end-to-end slice working before adding features
2. **One feature at a time** — Implement, test, commit. Never juggle multiple incomplete features
3. **Immutable scope** — Features are tracked in `features.json`; agent can only flip `passes` status, never modify what needs building
4. **Checkpoint everything** — Git commit after each feature. Write progress files. Enable clean restarts
5. **Re-ground regularly** — Re-read `features.json` + `PROJECT.md` every 3 features to prevent context drift

## The Pipeline

Five phases, executed in order. Each feeds the next.

```
INTAKE → RESEARCH → PLAN → BUILD → SHIP
  (1)      (2)       (3)    (4)     (5)
```

---

### Phase 1: INTAKE

Gather context through threaded questioning. Extract what the user's prompt already answers — only ask what's genuinely ambiguous.

<questioning_strategy>

**Step 1 — Extract from prompt.** Parse the user's message for: product type, features, users, tech preferences, scale. Note what's answered vs. unknown.

**Step 2 — Open question (freeform, no AskUserQuestion):**
If the prompt is vague, ask: "Tell me more about what this looks like when it's working — what does a user do from start to finish?"

**Step 3 — Thread follow-up (AskUserQuestion):**
Based on their response, probe what they mentioned. Header: relevant topic. Options: 2-3 interpretations + "Something else".

**Step 4 — Core (AskUserQuestion):**
"If you could only nail ONE thing in v1, what would it be?"
Options: key aspects mentioned + "All equally important"

**Step 5 — Boundaries (AskUserQuestion):**
"What's explicitly NOT in v1?"
Options: tempting features to cut + "Nothing specific" + "Let me list them"

**Step 6 — Decision gate (AskUserQuestion):**
"Ready to build, or want to explore more?"
Options: "Start building" / "Ask more questions" / "Let me add context"
Loop back to Step 3 if not ready.

</questioning_strategy>

**SKIP RULE**: If the user's original prompt clearly specifies what to build, who uses it, and key features — skip to the decision gate. Do not re-ask answered questions.

After intake, run `scripts/init-project.sh` and print:
```
SHIP-IT v2 ENGAGED — Building [Project Name]
Pipeline: Research → Plan → Build → Ship
Mode: Autonomous with guardrails
```

---

### Phase 2: RESEARCH

Gather technical knowledge. Launch exactly 3 parallel Task agents (max 3-4 agents per workflow to avoid coordination overhead):

**Agent 1 — Documentation (Context7):**
Resolve library IDs with `resolve-library-id`, then query setup patterns, core APIs, auth patterns, database integration with `query-docs`. Focus on practical code examples.

**Agent 2 — Codebase (Explore):**
If existing code detected (brownfield), map architecture, conventions, utilities, dependencies. If greenfield, skip and return "No existing code."

**Agent 3 — Ecosystem (WebSearch):**
Search for best practices, common pitfalls, required third-party services for this specific product type. Return actionable recommendations only.

**Output:** Compile into `.planning/RESEARCH.md`. See `references/pipeline-phases.md` for template.

**Research Skip Rule:** For standard web dev (CRUD, auth, REST APIs, forms) with well-known patterns, compress research to 2 minutes. Deep research only for niche domains (3D, audio, ML, real-time, game dev, shaders).

---

### Phase 3: PLAN

Generate the implementation plan, then critique it before executing.

**Step 3.1 — Create PROJECT.md**
Write `.planning/PROJECT.md` with requirements categorized as:
- **Validated**: Confirmed by user (from intake)
- **Active**: Derived hypotheses (from research) — treated as guesses until shipped
- **Out of Scope**: Explicit non-goals with reasoning

**Step 3.2 — Generate features.json (Immutable Scope Contract)**
Create `.planning/features.json` enumerating ALL required features with pass/fail status:
```json
{
  "features": [
    { "id": "F001", "name": "User authentication", "passes": false },
    { "id": "F002", "name": "Dashboard page", "passes": false }
  ]
}
```
**IRON RULE**: During build, the agent may ONLY change `passes` from `false` to `true`. Never add, remove, or rename features. This prevents silent scope creep and requirement dropping.

**Step 3.3 — Create Roadmap**
Structure as a walking skeleton + feature layers:

1. **Skeleton**: Project scaffold + auth + one blank page + one API endpoint + end-to-end verification
2. **Data Layer**: Database schema, models, seed data
3. **Feature 1**: First core feature (highest priority from intake)
4. **Feature 2**: Second core feature
5. **Feature N**: Additional features (one phase per feature)
6. **Polish**: Error handling, loading states, edge cases
7. **Ship**: Build verification, deployment config

Write `.planning/ROADMAP.md` and `.planning/STATE.md`.

**Step 3.4 — Meta-Prompt Critique**
Before executing, review the plan: "Does this roadmap cover all features in features.json? Are phases ordered by dependency? Are there any gaps?" Fix issues found. This self-critique step catches 40% of planning errors before they become build errors.

**Step 3.5 — Plan Each Phase**
For each phase, create `.planning/phases/[N]-[name]/PLAN.md` with specific files, tasks, and verification steps. Keep plans to 2-3 tasks each (GSD pattern — small plans execute reliably).

**Step 3.6 — Launch Briefing (Print Before Executing)**

After all planning is complete, print a launch briefing. This is the last thing the user sees before autonomous execution begins. Make it visually clear and informative:

```
╔══════════════════════════════════════════════════════════════╗
║                    SHIP-IT LAUNCH BRIEFING                  ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Project:  [Name]                                            ║
║  Stack:    [Framework] + [DB] + [Auth] + [Styling]           ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  EXECUTION PLAN                                              ║
║                                                              ║
║  Phase 1: Skeleton .............. ~[N] files  [■□□□□□□□□□]   ║
║  Phase 2: Data Layer ........... ~[N] files  [□□□□□□□□□□]   ║
║  Phase 3: [Feature 1] ......... ~[N] files  [□□□□□□□□□□]   ║
║  Phase 4: [Feature 2] ......... ~[N] files  [□□□□□□□□□□]   ║
║  Phase 5: Polish ............... ~[N] files  [□□□□□□□□□□]   ║
║  Phase 6: Ship ................. ~[N] files  [□□□□□□□□□□]   ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  ESTIMATES                                                   ║
║                                                              ║
║  Total Features:  [N]                                        ║
║  Est. Files:      [N]-[N]                                    ║
║  Est. API Cost:   ~$[X.XX] (based on [scope] complexity)     ║
║  Confidence:      [High/Medium/Low] — [one-line reasoning]   ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  WHAT I NEED FROM YOU                                        ║
║                                                              ║
║  • [Any env vars, API keys, or accounts needed]              ║
║  • [Any design assets or content needed]                     ║
║  • [Any decisions that were deferred]                        ║
║  • Nothing else — I'll handle the rest autonomously          ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Starting autonomous execution now...                        ║
║  I'll build everything and check back when it's done.        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

**Cost estimation heuristic:**
- Micro (3-4 phases, 5-15 files): ~$0.50-2
- Small (4-5 phases, 10-25 files): ~$2-5
- Medium (5-7 phases, 25-60 files): ~$5-15
- Large (7-9 phases, 50-120 files): ~$15-40
- XL (8-12 phases, 80-200 files): ~$40-100+

Base on: number of phases × average tasks × estimated tokens per task. Be honest — over-promise is worse than over-estimate.

**Confidence assessment:**
- **High**: Standard CRUD/SaaS with well-known patterns, clear requirements
- **Medium**: Novel product type or complex integrations, some ambiguity
- **Low**: Niche domain, unclear requirements, experimental tech stack

After printing the briefing, immediately begin Phase 4 BUILD. Do NOT wait for user confirmation — the briefing is informational, not a gate.

---

### Phase 4: BUILD

The core execution phase. Follows the Checkpoint-Validate-Continue pattern.

<execution_loop>

**For each feature in ROADMAP (one at a time):**

1. **RE-GROUND**: Read `features.json` + `PROJECT.md` + `STATE.md` to prevent context drift
2. **READ PLAN**: Load the phase PLAN.md
3. **ROUTE STRATEGY**: Determine execution approach:
   - **Strategy A (Autonomous)**: No decision points → spawn Task agent for entire phase
   - **Strategy B (Segmented)**: Has verification checkpoints → segment between checkpoints, spawn agent per segment
   - **Strategy C (Sequential)**: Has architecture decisions → execute in main context sequentially
4. **IMPLEMENT**: Write complete, production-quality code. No TODOs, no placeholders, no "implement later"
5. **VALIDATE**: Run build + tests. If tests fail, fix before proceeding. Never skip.
6. **COMMIT**: `git add` specific files only (never `git add .`). Format: `feat(phase-N): description`
7. **UPDATE**: Mark feature as `passes: true` in `features.json`. Update `STATE.md`
8. **CHECK CONTEXT**: If context usage feels heavy (many files read/written), write progress to `STATE.md` and consider compacting

</execution_loop>

<deviation_rules>

When unexpected issues arise during execution:

1. **Bugs discovered** → Fix immediately, document in summary (auto — no permission needed)
2. **Missing critical code** (security, validation, error handling) → Add immediately (auto)
3. **Blocking issues** (missing deps, import errors, build failures) → Fix immediately (auto)
4. **Architectural changes** (new tables, schema changes, framework switches) → STOP and ask user
5. **Nice-to-have enhancements** → Log to `.planning/ISSUES.md`, continue without implementing

Rules 1-3 are autonomous. Rule 4 requires user input. Rule 5 is deferred.

</deviation_rules>

**Walking Skeleton Verification (after Phase 1 "Skeleton"):**
Before building any features, verify the skeleton works end-to-end:
- App starts without errors
- Auth flow completes (login/logout)
- One page renders
- One API endpoint responds
- Database connects

Only proceed to features after skeleton is verified.

**When to Use Ralph Loop:**
After all features pass in `features.json`, invoke for polish:
```
/ralph-loop "All features in features.json pass. Now verify end-to-end: start dev server, test each feature manually, fix UI issues, improve error handling and loading states. Stop when everything works smoothly." --max-iterations 5
```

---

### Phase 5: SHIP

**Step 5.1 — Final Verification**
- All features in `features.json` show `passes: true`
- Build completes with zero errors
- Dev server starts cleanly
- Core user flow works end-to-end

**Step 5.2 — Deployment Config**
Generate deployment config based on stack (Vercel for Next.js, Docker for APIs, etc.)

**Step 5.3 — Ship Report**
```
SHIP-IT COMPLETE

Project: [Name]
Stack: [Tech stack]
Features: [passed]/[total] passing

[Feature list with status]

To run:  [commands]
To deploy: [commands]

Deferred to v2: [items from ISSUES.md]
```

---

## Decision Framework

| Decision | Default |
|----------|---------|
| Frontend | Next.js 14+ (App Router) |
| Styling | Tailwind CSS + shadcn/ui |
| Database | SQLite with Prisma (simple) / PostgreSQL (complex) |
| Auth | NextAuth.js |
| API | Server Actions + Route Handlers |
| Language | TypeScript (strict) |
| Package manager | pnpm |
| Deployment | Vercel |

Override only when project requirements clearly demand something else.

## State Persistence & Resumption

If a session ends mid-build, the next session can resume:
1. Check `.planning/STATE.md` for current position
2. Check `features.json` for what's complete vs. remaining
3. Check for PLAN.md without matching SUMMARY.md (incomplete work)
4. Resume from exact point of interruption

## Additional Resources

### Reference Files
- **`references/pipeline-phases.md`** — Detailed phase-by-phase guide with templates, agent prompts, and context injection patterns
- **`references/agent-swarm-patterns.md`** — Agent coordination patterns, swarm design, confidence scoring, and segmentation strategies
- **`references/failure-prevention.md`** — The 10 common AI agent failure modes and specific prevention guardrails

### Scripts
- **`scripts/init-project.sh`** — Initialize `.planning/` directory with config, state, and features.json template
