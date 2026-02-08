---
name: ship-it
description: "This skill should be used when the user wants to go from idea to MVP, says 'build this', 'ship it', 'create an app', 'build me a product', 'idea to MVP', 'make this real', 'full build', 'zero to one', or provides a product idea and expects autonomous end-to-end execution. Orchestrates research, planning, and building to ship complete working software from a single prompt."
version: 3.0.0
---

# Ship It — Idea to MVP Orchestrator

Autonomous end-to-end product builder. Takes a single idea and ships a working MVP by orchestrating research, planning, and iterative execution with built-in guardrails against the 10 most common AI agent failure modes.

## Core Principles

1. **Walking skeleton first** — Get the thinnest end-to-end slice working before adding features
2. **One feature at a time** — Implement, test, commit. Never juggle multiple incomplete features
3. **Immutable scope** — Features are tracked in `features.json`; agent can only flip `passes` status, never modify what needs building
4. **Checkpoint everything** — Git commit after each feature. Write progress files. Enable clean restarts
5. **Re-ground regularly** — Re-read `features.json` + `PRD.md` every 3 features to prevent context drift

## The Pipeline

Eight phases, executed in order. Each feeds the next.

```
REFINE → INTAKE → PRD → RESEARCH → ARCHITECTURE → PLAN → BUILD → SHIP
  (0)      (1)     (2)     (3)          (4)         (5)    (6)    (7)

Optional: [MULTI-MODEL REVIEW] after Architecture (4.5)
```

---

### Phase 0: REFINE (Prompt Enhancement)

Transform the user's raw prompt into a structured, high-quality input before intake begins. See `references/prompt-patterns.md` for full pattern library.

1. Parse user's prompt for: product type, features, users, tech preferences, scale
2. Select patterns from the Pattern Selection Logic table (RCF + Task Decomposition for apps, Chain-of-Thought for ambiguous requests)
3. Apply the 5-Section Template: Role, Task & Context, Constraints, Reasoning Style, Output Format
4. Fill in what the user provided, add specificity where vague, mark `[TO CLARIFY]` for unknowns
5. Present enhanced prompt to user for approval/editing
6. User can approve, edit, or say "just build it" to skip

**SKIP RULE**: If user provides a detailed, structured prompt with clear requirements, skip REFINE and go directly to INTAKE.

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

After intake, print:
```
SHIP-IT v3 ENGAGED — Building [Project Name]
Pipeline: PRD → Research → Architecture → Plan → Build → Ship
Mode: Autonomous with guardrails
```

---

### Phase 2: PRD (Product Requirements Document)

After intake, generate a PRD through conversation. This replaces the old PROJECT.md as the source of truth.

1. Draft PRD from REFINE + INTAKE context using template in `references/pipeline-phases.md`
2. PRD sections: Problem Statement, Target Users, User Stories, Functional Requirements, Non-Functional Requirements, Success Metrics, Out of Scope, Open Questions
3. Present to user with targeted questions on gaps ("I see you want auth but didn't specify a method — email/password, OAuth, or magic link?")
4. User approves or adds context. Loop until approved.
5. Save as `.planning/PRD.md` — this is the source of truth for the rest of the pipeline

**Functional Requirements become the seed for `features.json`** — each requirement maps to one or more features.

---

### Phase 3: RESEARCH

Gather technical knowledge. Launch exactly 3 parallel Task agents (max 3-4 agents per workflow to avoid coordination overhead):

**Agent 1 — Documentation (Context7):**
Resolve library IDs with `resolve-library-id`, then query setup patterns, core APIs, auth patterns, database integration with `query-docs`. Focus on practical code examples.

**Agent 2 — Codebase (Explore):**
If existing code detected (brownfield), map architecture, conventions, utilities, dependencies. If greenfield, skip and return "No existing code."

**Agent 3 — Ecosystem (WebSearch):**
Search for best practices, common pitfalls, required third-party services for this specific product type. Return actionable recommendations only.

**Output:** Compile into `.planning/RESEARCH.md`. See `references/pipeline-phases.md` for template.

**Version Validation:** After installing deps in skeleton phase, read `package.json` and compare actual versions against research patterns. If a major version differs (e.g., Prisma 7 vs 6), re-query Context7 for that version's API before proceeding. Document in RESEARCH.md under "Version Validation".

**Research Skip Rule:** For standard web dev (CRUD, auth, REST APIs, forms) with well-known patterns, compress research to 2 minutes. Deep research only for niche domains (3D, audio, ML, real-time, game dev, shaders).

---

### Phase 4: ARCHITECTURE

After research, synthesize findings into an Architecture Decision Record before planning.

1. Generate architecture doc from RESEARCH + PRD context using template in `references/pipeline-phases.md`
2. Sections: System Architecture, Data Model, API Design, Tech Stack Rationale, Key Risks & Mitigations, File/Folder Structure
3. Present to user for review — this is the last checkpoint before autonomous execution
4. Save as `.planning/ARCHITECTURE.md`

The architecture doc drives phase planning — no ad-hoc technical decisions during build.

**Optional: Multi-Model Review (Phase 4.5)** — If configured, send PRD + Architecture to a review model before proceeding. See `references/multi-model-coordination.md`.

---

### Phase 5: PLAN

Generate the implementation plan, then critique it before executing.

**Step 5.1 — Generate features.json (Immutable Scope Contract)**
Derive features from PRD functional requirements. Each requirement maps to one or more features.
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

**Step 5.2 — Create Roadmap**
Structure as a walking skeleton + feature layers:

1. **Skeleton**: Project scaffold + auth + one blank page + one API endpoint + end-to-end verification
2. **Data Layer**: Database schema, models, seed data
3. **Feature 1**: First core feature (highest priority from intake)
4. **Feature 2**: Second core feature
5. **Feature N**: Additional features (one phase per feature)
6. **Polish**: Error handling, loading states, edge cases
7. **Ship**: Build verification, deployment config

Write `.planning/ROADMAP.md` and `.planning/STATE.md`.

**Step 5.3 — Meta-Prompt Critique**
Before executing, review the plan: "Does this roadmap cover all features in features.json? Are phases ordered by dependency? Are there any gaps?" Fix issues found. This self-critique step catches 40% of planning errors before they become build errors.

**Step 5.4 — Plan Each Phase**
For each phase, create `.planning/phases/[N]-[name]/PLAN.md` with specific files, tasks, and verification steps. Keep plans to 2-3 tasks each (GSD pattern — small plans execute reliably).

**Step 5.5 — Launch Briefing**

Print a briefing showing: Project name, stack, phase-by-phase execution plan with file estimates, total features, estimated API cost, confidence level (High/Medium/Low), and what's needed from the user. Use the ASCII box format from `references/pipeline-phases.md`.

**Cost heuristic:** Micro ~$0.50-2, Small ~$2-5, Medium ~$5-15, Large ~$15-40, XL ~$40-100+. Base on phases × tasks × tokens. Over-estimate rather than over-promise.

After the briefing, immediately begin Phase 6 BUILD — the briefing is informational, not a gate.

---

### Phase 6: BUILD

Checkpoint-Validate-Continue pattern. See `references/pipeline-phases.md` for execution strategies and `references/agent-swarm-patterns.md` for coordination patterns.

**Parallelization Strategy (choose one):**

1. **Agent Teams (preferred)** — If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled, spawn a coordinated team for parallel feature phases. Team lead plans and delegates; feature teammates message each other to coordinate shared files; shared task list auto-unblocks dependencies. See `references/agent-swarm-patterns.md` for team patterns.

2. **Subagent fallback** — If Agent Teams unavailable, use Task agents with post-merge verification. After parallel agents complete, run a merge-verify step: check all new components are imported/wired, build passes, fix integration gaps before committing.

**Execution loop (per phase):** Re-ground → Read PLAN.md → Route strategy (A: autonomous, B: segmented, C: sequential, D: agent team) → Implement → Validate → Commit → Update `features.json` + `STATE.md`.

**Deviation rules:** Bugs/missing code/blocking issues → fix immediately (auto). Architectural changes → STOP and ask user. Nice-to-haves → log to ISSUES.md, skip.

**Scaffold ordering:** Run scaffolding tool FIRST into empty dir, then `scripts/init-project.sh`, then install deps + `pnpm approve-builds`.

**Skeleton verification:** After scaffold, verify: app starts, one page renders, one API responds, DB connects. Only proceed after skeleton passes.

**Polish:** After all features pass, invoke Ralph Loop:
```
/ralph-loop "All features pass. Verify end-to-end, fix UI issues, improve error handling." --max-iterations 5
```

---

### Phase 7: SHIP

**Step 7.1 — Final Verification**
- All features in `features.json` show `passes: true`
- Build completes with zero errors
- Dev server starts cleanly
- Core user flow works end-to-end

**Step 7.2 — Deployment Config**
Generate deployment config based on stack (Vercel for Next.js, Docker for APIs, etc.)

**Step 7.3 — Ship Report**
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
- **`references/pipeline-phases.md`** — Phase templates, agent prompts, PRD/Architecture templates, launch briefing format
- **`references/prompt-patterns.md`** — CLEARvAI prompt enhancement patterns, 5-section template, before/after examples
- **`references/agent-swarm-patterns.md`** — Agent coordination patterns, swarm design, segmentation strategies
- **`references/failure-prevention.md`** — 10 failure mode guardrails + known gotchas (Prisma 7, pnpm, WebSearch)
- **`references/multi-model-coordination.md`** — Multi-model review protocol, GPT/Claude coordination, graceful degradation

### Scripts
- **`scripts/init-project.sh`** — Initialize `.planning/` directory (run AFTER framework scaffolding)
