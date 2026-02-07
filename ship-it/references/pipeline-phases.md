# Ship-It Pipeline Phases — Detailed Reference

## Phase 1: INTAKE — Threaded Questioning Strategy

### Context Extraction from Vague Prompts

Before asking questions, parse the user's prompt for implicit requirements:

| User Says | Implied Requirements |
|-----------|---------------------|
| "SaaS" | Multi-tenant, auth, billing, dashboard |
| "marketplace" | Two-sided users, listings, search, payments |
| "dashboard" | Data visualization, filtering, real-time updates |
| "tool" | Single-purpose, fast UI, no auth needed |
| "platform" | Multi-feature, roles, API, integrations |
| "portfolio" | Static, visual-heavy, minimal interactivity |
| "enterprise" | RBAC, audit logs, SSO, compliance |

### Scope Calibration Matrix

Determine MVP scope to set expectations:

| Signal | Scope | Phases | Est. Files |
|--------|-------|--------|------------|
| Simple tool (calculator, converter) | Micro | 3-4 | 5-15 |
| Landing page + form | Small | 4-5 | 10-25 |
| CRUD app (todo, notes, CRM) | Medium | 5-7 | 25-60 |
| SaaS with auth + billing | Large | 7-9 | 50-120 |
| Platform with multi-tenancy | XL | 8-12 | 80-200+ |

### Questioning Do's and Don'ts

**DO ask about:**
- Vision, feel, essential outcomes
- "What does success look like?"
- "Walk me through what a user does"

**DON'T ask about:**
- Technical risks (figure those out yourself)
- Codebase patterns (read the code)
- Success metrics (too corporate for intake)
- Constraints they didn't mention (don't invent problems)

---

## Phase 2: RESEARCH — Parallel Agent Coordination

### Agent Prompt Templates

**Agent 1 — Context7 Documentation Research:**
```
Research libraries for [project description] using Context7:

For each library below:
1. Resolve the library ID using resolve-library-id
2. Query for: project setup, core API patterns, configuration
3. Focus on practical code examples — not theory

Libraries:
- [Framework] (e.g., Next.js)
- [Database ORM] (e.g., Prisma)
- [Auth library] (e.g., NextAuth.js)
- [UI library] (e.g., shadcn/ui)
- [Other key deps]

Return: Setup commands, config files needed, key API patterns with code.
```

**Agent 2 — Codebase Exploration (Brownfield Only):**
```
Analyze the codebase at [path]. Map:
1. Directory structure and file naming conventions
2. Existing components, utilities, and shared modules
3. Package dependencies and build scripts
4. Configuration files (tsconfig, eslint, tailwind, etc.)
5. Database schema or API routes if present

Return: Architecture summary, conventions to follow, utilities to reuse.
If no existing code, return "Greenfield project — no existing code."
```

**Agent 3 — Ecosystem Best Practices:**
```
Research best practices for building [specific product type]:
1. Architecture patterns that experts use for this type of product
2. Critical pitfalls and how to avoid them
3. Required third-party services (auth, email, payments, hosting)
4. Any API integrations needed

Return: Actionable recommendations with specific package names and versions.
Do NOT return generic advice.
```

### RESEARCH.md Template

```markdown
# Research: [Project Name]

## Stack Decision
- Framework: [choice] — [one-line reasoning]
- Database: [choice] — [one-line reasoning]
- Auth: [choice] — [one-line reasoning]
- Styling: [choice] — [one-line reasoning]
- Deployment: [choice] — [one-line reasoning]

## Key Libraries
| Library | Purpose | Setup |
|---------|---------|-------|
| next | Framework | npx create-next-app@latest |
| prisma | ORM | npx prisma init |

## Architecture Pattern
[2-3 sentences describing chosen architecture]

## API/Service Dependencies
- [Service]: [integration method]

## Common Pitfalls
1. [Pitfall] — [prevention]

## Code Patterns from Context7
[Key code snippets for reference during build]
```

---

## Phase 3: PLAN — GSD-Integrated Planning

### PROJECT.md Template

```markdown
# [Project Name]

## What This Is
[2-3 sentence description]

## Requirements

### Validated (confirmed by user)
- [Requirement from intake]

### Active (hypotheses to validate by shipping)
- [ ] [Derived requirement]

### Out of Scope (explicit non-goals)
- [Feature] — [why deferred]

## Tech Stack
- **Framework**: [choice]
- **Database**: [choice]
- **Auth**: [choice]
- **Styling**: [choice]

## Key Decisions
| Decision | Choice | Reasoning |
|----------|--------|-----------|
| [decision] | [choice] | [why] |
```

### features.json Generation Rules

1. Each feature maps to a user-observable outcome (not implementation detail)
2. Features are ordered by dependency and priority
3. The skeleton is NOT a feature — it's infrastructure
4. Keep feature count under 15 for MVP (if more, scope is too large)
5. Each feature name is a verb phrase: "Create invoice", "Filter dashboard", "Export PDF"

**Good features:**
```json
{ "id": "F001", "name": "Sign up with email and password", "passes": false }
{ "id": "F002", "name": "Create and edit invoices", "passes": false }
```

**Bad features (too vague or too granular):**
```json
{ "id": "F001", "name": "Authentication", "passes": false }
{ "id": "F002", "name": "Add email field to form", "passes": false }
```

### Walking Skeleton Roadmap Structure

The skeleton phase is special — it establishes the foundation everything else builds on:

```markdown
## Phase 1: Skeleton

### Task 1: Scaffold project
- Run create-next-app (or equivalent)
- Install core dependencies
- Configure TypeScript, Tailwind, ESLint

### Task 2: Set up database
- Initialize Prisma with chosen database
- Create User model (minimum for auth)
- Run initial migration

### Task 3: Set up authentication
- Configure NextAuth.js with credentials provider
- Create login/register pages
- Add auth middleware

### Task 4: Verify end-to-end
- Start dev server
- Register a test user
- Login and see blank dashboard
- Verify API endpoint responds

### Verification
- [ ] `pnpm dev` starts without errors
- [ ] Can register and login
- [ ] Protected route redirects unauthenticated users
- [ ] Database persists data across restarts
```

### Phase Plan Template (for feature phases)

```markdown
# Phase [N]: [Feature Name]

## Objective
[One sentence: what the user can do after this phase]

## Context
- Depends on: Phase [N-1]
- Feature IDs: [F00X, F00Y]
- Key files from research: [relevant patterns]

## Tasks

### Task 1: [Name]
- **Create/Modify**: [file path]
- **Implementation**: [what to build]
- **Verification**: [how to test]

### Task 2: [Name]
...

## Phase Verification
- [ ] Feature works end-to-end
- [ ] Build passes: `pnpm build`
- [ ] No TypeScript errors
- [ ] Previous features still work
```

### Meta-Prompt Critique Checklist

Before executing the roadmap, verify:
- [ ] Every feature in `features.json` maps to at least one phase
- [ ] No feature is split across non-adjacent phases
- [ ] Dependencies flow downward (no phase depends on a later phase)
- [ ] Skeleton phase has end-to-end verification
- [ ] Each phase has 2-3 tasks (not 1, not 10)
- [ ] Database schema is complete before API routes that query it

---

## Phase 4: BUILD — Execution Patterns

### Execution Strategy Selection

Analyze each phase plan to determine the right strategy:

**Strategy A: Fully Autonomous**
- Use when: Phase has no decision points, all tasks are straightforward
- How: Spawn a single Task agent with the full phase plan
- Context: Agent gets PROJECT.md + RESEARCH.md + phase PLAN.md
- Result: Agent writes code, runs verification, reports completion

**Strategy B: Segmented**
- Use when: Phase has verification checkpoints but no architectural decisions
- How: Segment plan between checkpoints, spawn agent per segment
- Benefit: Each agent gets fresh context window
- Coordinate: Main context handles checkpoint verification between segments

**Strategy C: Sequential in Main**
- Use when: Phase has architectural decisions that affect subsequent tasks
- How: Execute tasks one at a time in main context
- Use for: Skeleton phase (always), database schema creation, first feature

### Context for Task Agents

Every spawned agent receives:

```markdown
## Project: [Name]
[One-line description]

## Stack: [framework, db, styling, auth]

## Your Assignment
[Specific tasks from PLAN.md]

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
```

### Atomic Commit Protocol

After each task completes:
1. Stage ONLY files modified by that task (individual `git add`)
2. Commit format: `{type}(phase-{N}): {task-description}`
3. Types: feat, fix, test, refactor, chore
4. Record what was committed for SUMMARY.md

After all phase tasks complete:
1. Stage planning artifacts only
2. Commit: `docs(phase-{N}): complete [phase-name]`

### Re-Grounding Protocol

Every 3 features (or when context feels heavy):
1. Re-read `features.json` — verify current feature status
2. Re-read `PROJECT.md` — confirm requirements haven't drifted
3. Re-read `STATE.md` — verify position tracking is accurate
4. If more than 60% of features complete, verify earlier features still work

---

## Phase 5: SHIP — Verification & Deployment

### Full Verification Protocol

```bash
# Build check
pnpm build 2>&1

# Start dev server
pnpm dev &
sleep 5

# Verify health
curl -s http://localhost:3000 | head -20

# Check all routes exist
# (customize based on project routes)

# Kill dev server
kill %1
```

### Deployment by Stack

**Next.js → Vercel:**
```json
// vercel.json (if needed)
{
  "buildCommand": "pnpm build",
  "framework": "nextjs"
}
```

**Node.js API → Docker:**
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json pnpm-lock.yaml ./
RUN npm i -g pnpm && pnpm install --frozen-lockfile --prod
COPY . .
RUN pnpm build
EXPOSE 3000
CMD ["pnpm", "start"]
```

**Static Site → Vercel/Netlify:**
```json
{
  "buildCommand": "pnpm build",
  "outputDirectory": "dist"
}
```

### Ship Report Template

```markdown
# Ship Report: [Project Name]

## Status: SHIPPED

## Stack
- [Framework]: [version]
- [Database]: [version]
- [Auth]: [version]
- [Styling]: [version]

## Features ([passed]/[total])
| ID | Feature | Status |
|----|---------|--------|
| F001 | [name] | PASS |
| F002 | [name] | PASS |

## Metrics
- Files created: [N]
- Lines of code: [N]
- Git commits: [N]
- Phases completed: [N]/[N]

## Run Locally
\`\`\`bash
git clone [repo]
cd [project]
pnpm install
pnpm dev
\`\`\`

## Deploy
\`\`\`bash
[deployment commands]
\`\`\`

## Deferred to v2 (from ISSUES.md)
- [ISS-001]: [description]
- [ISS-002]: [description]

## Architecture Decisions Made
| Decision | Choice | Phase |
|----------|--------|-------|
| [what] | [choice] | [when] |
```
