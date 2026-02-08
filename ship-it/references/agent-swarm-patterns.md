# Agent Coordination Patterns for Ship-It v3.1

## Strategy Hierarchy

Pick the highest-available strategy that fits the phase:

```
1. Agent Teams (preferred)    — CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS enabled
2. Subagent Swarm (fallback)  — Task tool with parallel agents + post-merge verify
3. Sequential (safe default)  — Single context, one task at a time
```

> More tokens, better output. Specialized agents with defined roles outperform a single context juggling everything.

---

## 1. Agent Teams (Primary Strategy)

Agent Teams spawn a coordinated team where agents can message each other, share a task list, and auto-unblock dependencies. The team lead plans and delegates; teammates execute in parallel.

### When to Use Agent Teams

- Phase has 3+ independent features/tasks
- Features touch different file domains (pages vs API vs components)
- You want parallel execution WITH inter-agent coordination
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled

### Team Composition Patterns

#### Pattern A: Feature Team (most common)

For building multiple features in parallel:

```
┌──────────────────────────────────────────────┐
│               TEAM LEAD                       │
│  Plans work, delegates, resolves conflicts    │
│  Owns: shared types, index files, routing     │
└──────┬──────────┬──────────┬────────────────┘
       │          │          │
  ┌────▼────┐ ┌──▼────┐ ┌──▼──────────┐
  │Feature A│ │Feat B │ │Feature C     │
  │Teammate │ │Tmate  │ │Teammate      │
  │         │ │       │ │              │
  │Pages +  │ │Pages +│ │Pages +       │
  │API +    │ │API +  │ │API +         │
  │Comps    │ │Comps  │ │Comps         │
  └─────────┘ └───────┘ └──────────────┘
```

Each teammate owns a vertical slice: page + API route + components for ONE feature. No file overlap.

#### Pattern B: Layer Team

For phases where work splits by architectural layer:

```
┌──────────────────────────────────────────────┐
│               TEAM LEAD                       │
│  Coordinates layer integration                │
└──────┬──────────┬──────────┬────────────────┘
       │          │          │
  ┌────▼────┐ ┌──▼────┐ ┌──▼──────────┐
  │Database │ │API    │ │Frontend      │
  │Teammate │ │Tmate  │ │Teammate      │
  │         │ │       │ │              │
  │Schema,  │ │Routes,│ │Pages,        │
  │Seeds,   │ │Server │ │Components,   │
  │Migrations│ │Actions│ │Layouts       │
  └─────────┘ └───────┘ └──────────────┘
```

Use when layers are thick enough to justify separate agents. DB teammate finishes first and messages API teammate with schema details.

#### Pattern C: Research Team

For the RESEARCH phase (Phase 3):

```
┌──────────────────────────────────────────────┐
│               TEAM LEAD                       │
│  Compiles RESEARCH.md from all findings       │
└──────┬──────────┬──────────┬────────────────┘
       │          │          │
  ┌────▼────┐ ┌──▼────┐ ┌──▼──────────┐
  │Context7 │ │Explore│ │WebSearch     │
  │Teammate │ │Tmate  │ │Teammate      │
  │         │ │       │ │              │
  │Docs,    │ │Code   │ │Best          │
  │APIs,    │ │map,   │ │practices,    │
  │Patterns │ │Conven.│ │Pitfalls      │
  └─────────┘ └───────┘ └──────────────┘
```

### Team Agent Role Definitions

**Team Lead responsibilities:**
1. Break the phase plan into non-overlapping assignments
2. Create shared types/interfaces BEFORE spawning teammates
3. Assign file ownership — no two teammates write the same file
4. Monitor the shared task list for blockers
5. Run merge-verify after all teammates complete
6. Handle index files, routing, and shared config

**Feature Teammate responsibilities:**
1. Read assigned tasks from the shared task list
2. Implement COMPLETE, WORKING code — no TODOs, no placeholders
3. Message other teammates when producing shared interfaces they consume
4. Mark tasks complete when done
5. Stay within assigned file scope — never modify files outside your assignment

### Inter-Agent Messaging

Teammates can message each other to coordinate:

```
Example flow:
1. DB Teammate creates User schema, messages API Teammate:
   "User model ready with fields: id, email, name, passwordHash, createdAt"

2. API Teammate creates /api/users routes, messages Frontend Teammate:
   "POST /api/users expects { email, name, password }, returns User object"

3. Frontend Teammate builds the registration form using the exact contract
```

This eliminates the #1 integration failure: mismatched interfaces between layers.

### Shared Task List

The team's shared task list auto-manages dependencies:

```
Task 1: Create User schema + migration          [DB Teammate]
Task 2: Create auth API routes                   [API Teammate]     blocks: [1]
Task 3: Build login/register pages               [Frontend Teammate] blocks: [2]
Task 4: Create Dashboard layout                  [Frontend Teammate] blocks: [1]
Task 5: Build settings page                      [Frontend Teammate] blocks: [2]
```

Tasks with `blocks` wait until dependencies resolve. This prevents teammates from building against non-existent APIs.

### Team Context Template

Every team agent (lead and teammates) receives:

```markdown
## Project: [Name]
[One-line description]

## Tech Stack
- Framework: [X]
- Database: [X]
- Styling: [X]
- Auth: [X]
- Language: TypeScript (strict)

## Working Directory: [absolute path]

## Your Role: [Team Lead / Feature Teammate / Layer Teammate]

## Your Assignment
[Specific tasks — explicit file paths and expected outputs]

## File Ownership
YOU own these files (only you write to them):
- [file1]
- [file2]

DO NOT modify these files (owned by other teammates):
- [file3] (owned by [Teammate X])
- [file4] (owned by [Teammate Y])

## Code Conventions
- Named exports for utilities, default exports for components/pages
- Tailwind CSS utility classes (no custom CSS unless necessary)
- Error handling: try/catch with meaningful messages
- Proper TypeScript types — no `any`
- Handle loading and error states in UI components
- Include all imports at the top of every file

## Strict Rules
- Write COMPLETE, WORKING code — no TODOs, no placeholders
- Every file must be syntactically valid and importable
- Follow the patterns in RESEARCH.md
- If unsure about a library API, use Context7 to look it up
- Message teammates when you produce an interface they consume
- Do NOT modify files outside your assigned scope
```

---

## 2. Subagent Swarm (Fallback Strategy)

When Agent Teams are unavailable, use Task agents with post-merge verification.

### Core Rule: Max 3-4 Agents Per Workflow

More agents create coordination overhead that negates productivity gains. Every additional agent adds:
- Context assembly cost (preparing the prompt)
- Result integration cost (merging outputs)
- Conflict resolution cost (overlapping file writes)

Sweet spot: 3 agents for research, 2-3 for parallel feature work, 3 for quality review.

### The Coordinator Pattern

The main Claude instance acts as coordinator — it plans, delegates, and integrates but does NOT compete with agents on implementation.

```
        ┌─────────────────┐
        │   Coordinator    │
        │ (Plans + Routes) │
        └────────┬────────┘
                 │
      ┌──────────┼──────────┐
      │          │          │
  ┌───▼───┐ ┌───▼───┐ ┌───▼───┐
  │Agent 1│ │Agent 2│ │Agent 3│
  │(Focus)│ │(Focus)│ │(Focus)│
  └───────┘ └───────┘ └───────┘
```

**Coordinator responsibilities:**
1. Break work into independent, non-overlapping units
2. Prepare context for each agent (project info + specific tasks)
3. Spawn agents (parallel for independent tasks, sequential for dependent)
4. Collect and integrate results
5. Resolve file conflicts if agents touched the same files
6. Run verification after integration

### Post-Merge Verification (Critical for Subagents)

Since subagents can't message each other, the coordinator MUST run a merge-verify step after all agents complete:

```
1. All agents complete their tasks
2. Coordinator checks:
   - All new components are imported where needed
   - All new API routes are wired to pages
   - Shared types match across consumers
   - No duplicate or conflicting exports
3. Run `pnpm build` — fix any errors
4. Run dev server — verify pages render
5. Only then commit the integrated result
```

This step catches the integration gaps that Agent Teams handle via messaging.

### Subagent Prompt Template

```markdown
## Project: [Name]
[One-line description]

## Stack: [framework, db, styling, auth]

## Your Assignment
[Specific tasks — be explicit about file paths and expected outputs]

## Conventions
- TypeScript strict mode
- Tailwind CSS utility classes
- Named exports for utilities, default for components
- Error handling: try/catch with meaningful messages
- All imports at top of file

## Rules
- Write COMPLETE code — no TODOs, no placeholders
- Every file must be syntactically valid
- Use proper TypeScript types — no `any`
- Handle loading and error states in UI
- Follow patterns from RESEARCH.md
- Do NOT modify files outside your assigned scope
```

---

## 3. When to Use Which Strategy

### AGENT TEAMS when:
- 3+ independent features to build in parallel
- Features span multiple layers (page + API + DB)
- You want agents to coordinate shared interfaces
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled

### SUBAGENT SWARM when:
- Agent Teams unavailable
- Building multiple independent UI components
- Creating separate API routes with no shared logic
- Running different types of review (bugs, style, security)
- Researching different aspects of the tech stack

### SEQUENTIAL when:
- Database schema → API routes (schema must exist first)
- API routes → Frontend integration (endpoints must exist first)
- Auth middleware → Protected routes (middleware must exist first)
- Phase has < 3 tasks
- Tasks are tightly coupled (each depends on the previous)
- Skeleton phase (ALWAYS sequential)

---

## Swarm Patterns by Phase

### Research Swarm (Phase 3)

Always 3 agents (Team or Subagent):

```
Agent 1 (Context7):     Documentation + code patterns
Agent 2 (Explore):      Existing codebase mapping
Agent 3 (WebSearch):    Ecosystem best practices
```

Each agent has a completely different tool focus — zero overlap.

### Feature Swarm (Phase 6 — BUILD)

**With Agent Teams:**
Spawn a feature team. Team lead assigns vertical slices. Teammates message each other with interface contracts. Shared task list auto-unblocks.

**With Subagents:**
```
Agent A: Build component/route X
Agent B: Build component/route Y
Agent C: Build component/route Z
```

Each agent gets pre-assigned file paths. Coordinator runs merge-verify after completion.

**Conflict prevention (both strategies):**
- Pre-assign file paths — no two agents write the same file
- Shared types/interfaces go in a types file created BEFORE spawning agents
- Index files (re-exports) are updated by lead/coordinator AFTER agents complete

### Quality Swarm (Optional — after all features built)

```
Agent 1: Bug + correctness review (read-only)
Agent 2: Accessibility + responsive review (read-only)
Agent 3: Build verification + type checking (runs commands)
```

**Confidence scoring:** Each issue gets scored 0-100:
- 0-25: False positive or nitpick — discard
- 26-50: Minor, cosmetic — log to ISSUES.md
- 51-79: Real but not blocking — log to ISSUES.md
- 80-100: Critical — fix immediately

Only act on issues scored 80+.

---

## Segmentation for Context Window Management

For large phases (5+ tasks), segment to keep agents in fresh context:

```
Phase with 8 tasks:

Segment 1 (tasks 1-3) → Agent A (fresh context)
  ↓ verify: build passes
Segment 2 (tasks 4-6) → Agent B (fresh context)
  ↓ verify: build passes
Segment 3 (tasks 7-8) → Agent C (fresh context)
  ↓ verify: build passes
```

Each agent gets the full project context plus only their segment's tasks. Fresh context window prevents quality degradation.

---

## Wave Execution for Large Projects

For projects with 8+ phases, execute in waves:

```
Wave 1: Skeleton          (sequential — always)
  ↓ verify skeleton works end-to-end
Wave 2: Data Layer        (1-2 agents)
  ↓ verify database + models work
Wave 3: Core Features     (Agent Team or 2-3 subagents)
  ↓ verify all core features pass
Wave 4: Secondary Features (Agent Team or 2-3 subagents)
  ↓ verify all features pass
Wave 5: Polish + Ship     (1-2 agents)
  ↓ final verification
```

Each wave completes and verifies before the next begins.

---

## Ralph Loop Integration

After agent coordination completes all features, use Ralph Loop for iterative refinement:

**Invoke when:**
- All features in `features.json` show `passes: true`
- Build completes but UI needs polish
- Integration between components needs smoothing

**Prompt template:**
```
All features in features.json pass. Verify and refine [project]:
1. Start dev server and verify it builds
2. Navigate to each page — check rendering and responsiveness
3. Test each feature for correct behavior
4. Fix bugs, type errors, or UI issues found
5. Improve error handling and loading states
6. Verify previous fixes didn't introduce regressions

Stop when: all features work correctly, build passes, UI is polished.
```

**Iteration limits:**
- Simple project (< 20 files): `--max-iterations 3`
- Standard MVP (20-60 files): `--max-iterations 5`
- Large project (60+ files): `--max-iterations 8`

---

## Anti-Patterns to Avoid

1. **Spawning agents for trivial work** — If a phase has 1-2 small tasks, just do them directly
2. **No post-merge verification (subagents)** — Always verify integration after parallel agents complete
3. **Overlapping file ownership** — Pre-assign files; two agents writing the same file causes conflicts
4. **Too many agents** — Diminishing returns past 4; coordination cost exceeds speed gain
5. **Agents modifying planning artifacts** — Only the lead/coordinator updates STATE.md, features.json, and ROADMAP.md
6. **Skipping shared types** — Create shared interfaces BEFORE spawning agents, not after
7. **Using Agent Teams for sequential work** — If tasks are tightly coupled, sequential is faster than coordination overhead
