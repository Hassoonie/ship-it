# Agent Swarm Patterns for Ship-It v2

## Core Rule: Max 3-4 Agents Per Workflow

More agents create coordination overhead that negates productivity gains. Every additional agent adds:
- Context assembly cost (preparing the prompt)
- Result integration cost (merging outputs)
- Conflict resolution cost (overlapping file writes)

The sweet spot is 3 agents for research, 2-3 for parallel feature work, 3 for quality review.

---

## The Coordinator Pattern

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

---

## When to Swarm vs. Sequential

### SWARM (parallel) when:
- Building multiple independent UI components
- Creating separate API routes with no shared logic
- Running different types of review (bugs, style, security)
- Researching different aspects of the tech stack

### SEQUENTIAL when:
- Database schema → API routes (schema must exist first)
- API routes → Frontend integration (endpoints must exist first)
- Auth middleware → Protected routes (middleware must exist first)
- Shared utilities → Components that use them

### SINGLE AGENT when:
- Phase has < 3 tasks
- Tasks are tightly coupled (each depends on the previous)
- Coordination overhead would exceed time saved

---

## Swarm Patterns by Phase

### Research Swarm (Phase 2)

Always 3 agents:

```
Agent 1 (Context7):     Documentation + code patterns
Agent 2 (Explore):      Existing codebase mapping
Agent 3 (WebSearch):    Ecosystem best practices
```

Each agent has a completely different tool focus — zero overlap.

### Feature Swarm (Phase 4 — when applicable)

Use when a phase has 3+ independent tasks:

```
Agent A: Build component/route X
Agent B: Build component/route Y
Agent C: Build component/route Z
```

**Each agent gets:**
- Project context (PROJECT.md, RESEARCH.md)
- Their specific tasks only
- Shared conventions document
- File paths that are "theirs" (no overlap)

**Conflict prevention:**
- Pre-assign file paths to agents — no two agents write the same file
- Shared types/interfaces go in a types file created BEFORE spawning agents
- Index files (re-exports) are updated by coordinator AFTER agents complete

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

Only act on issues scored 80+. This prevents noise from drowning real problems.

---

## Agent Prompt Engineering

### Essential Context Block (include in every agent prompt)

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

## Your Assignment
[Specific tasks — be explicit about file paths and expected outputs]

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
- If unsure about library API, use Context7 to look it up
- Do NOT modify files outside your assigned scope
```

### Agent Result Collection

When spawning multiple agents:

1. Launch all agents (parallel)
2. Wait for all to complete
3. Check for file conflicts (two agents wrote the same file)
4. If conflicts: coordinator merges manually
5. Run `pnpm build` to verify everything integrates
6. Fix any integration issues (import paths, type mismatches)
7. Commit integrated result

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

Each agent gets:
- The full project context (PROJECT.md, RESEARCH.md)
- Only their segment's tasks
- Current state of the codebase (they can read existing files)
- Fresh context window (no accumulated implementation debris)

**Benefit:** Prevents quality cliff from context exhaustion. Agent C has the same quality ceiling as Agent A.

---

## Wave Execution for Large Projects

For projects with 8+ phases, execute in waves:

```
Wave 1: Skeleton          (1 agent, sequential)
  ↓ verify skeleton works end-to-end
Wave 2: Data Layer        (1-2 agents)
  ↓ verify database + models work
Wave 3: Core Features     (2-3 agents parallel)
  ↓ verify all core features pass
Wave 4: Secondary Features (2-3 agents parallel)
  ↓ verify all features pass
Wave 5: Polish + Ship     (1-2 agents)
  ↓ final verification
```

Each wave completes and verifies before the next begins. This prevents building on broken foundations.

---

## Ralph Loop Integration

After agent swarms complete all features, use Ralph Loop for iterative refinement:

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
2. **Agents coordinating with each other** — Only the coordinator talks to agents; agents never talk to each other
3. **Sharing mutable state between agents** — Each agent gets immutable context; coordinator handles state updates
4. **Too many parallel agents** — Diminishing returns past 4; coordination cost exceeds speed gain
5. **Agents modifying planning artifacts** — Only the coordinator updates STATE.md, features.json, and ROADMAP.md
