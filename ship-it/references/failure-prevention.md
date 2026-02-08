# Ship-It Failure Prevention — The 10 Guardrails

AI agents fail in predictable ways. Ship-It prevents each one with specific guardrails built into the pipeline.

---

## Failure Mode 1: Cascading Errors

**What happens:** One early mistake compounds through all subsequent decisions. A wrong database schema leads to wrong API routes leads to wrong frontend logic.

**Prevention:**
- Walking skeleton verifies end-to-end BEFORE any features are built
- Each feature is committed independently — broken features don't contaminate others
- Verification checkpoint after each phase catches errors before they cascade
- `git bisect` works because of atomic per-task commits

**Guardrail in pipeline:** Phase 4 VALIDATE step — run build + tests after every feature, never skip.

---

## Failure Mode 2: Context Drift

**What happens:** Agent loses track of original goal as context window fills with implementation details. Feature 8 starts contradicting the requirements from intake.

**Prevention:**
- `features.json` is the immutable source of truth — re-read every 3 features
- `PROJECT.md` re-read at each re-grounding checkpoint
- Features can only be flipped pass/fail, never modified or removed
- Re-grounding protocol built into execution loop

**Guardrail in pipeline:** Phase 4 RE-GROUND step — first action before implementing each feature.

---

## Failure Mode 3: Yak Shaving

**What happens:** Agent goes down rabbit holes fixing tangential issues. Tries to optimize a CSS animation when it should be building the payment flow.

**Prevention:**
- Deviation Rule 5: Nice-to-have enhancements are LOGGED to ISSUES.md, not implemented
- Each phase plan has exactly 2-3 tasks — no room for tangential work
- Scope gate: If a subtask takes > 3 fix attempts, stop and report instead of spiraling

**Guardrail in pipeline:** Deviation rules — auto-log enhancements, continue without implementing.

---

## Failure Mode 4: Silent Requirement Dropping

**What happens:** Agent quietly omits features that are hard to implement. The final product is missing 30% of requested functionality with no explanation.

**Prevention:**
- `features.json` is the immutable contract — every feature has an ID and pass/fail status
- Ship report explicitly lists all features with their status
- Agent CANNOT remove features from the list — only flip passes to true
- Meta-prompt critique in Phase 3 verifies every feature maps to a phase

**Guardrail in pipeline:** features.json IRON RULE — agent may only change `passes`, never modify scope.

---

## Failure Mode 5: Memory Poisoning

**What happens:** Bad information stored in notes or memory files corrupts future decisions. Agent writes "use CommonJS" in a note, then follows it even though the project uses ESM.

**Prevention:**
- STATE.md uses structured format with explicit sections, not freeform text
- Research findings are compiled into structured RESEARCH.md, not scattered notes
- Key decisions tracked in PROJECT.md with reasoning, not just outcomes
- Planning artifacts are versioned through git — bad states can be identified

**Guardrail in pipeline:** Structured templates for all planning artifacts — no freeform memory writes.

---

## Failure Mode 6: Non-Atomic Operations

**What happens:** Partial failures leave codebase in inconsistent state. Half a database migration + half an API route = broken everything.

**Prevention:**
- Atomic per-task commits — each task is one commit
- Individual file staging (never `git add .`)
- If a task fails mid-execution, rollback to last commit
- Verification after each phase ensures consistency

**Guardrail in pipeline:** Phase 4 COMMIT step — stage specific files only, commit per task, verify after.

---

## Failure Mode 7: Context Window Exhaustion

**What happens:** Agent runs out of tokens mid-task and produces degraded, truncated, or hallucinated output in the final 20% of context.

**Prevention:**
- CHECK CONTEXT step after each feature — write progress if context is heavy
- Execution strategies B/C segment work to keep agents in fresh context
- Each Task agent gets a fresh context window
- STATE.md + features.json enable clean session restart at any point
- Re-grounding re-reads key files rather than relying on in-context memory

**Guardrail in pipeline:** Phase 4 CHECK CONTEXT step + segmented execution strategies.

---

## Failure Mode 8: Reimplementation Syndrome

**What happens:** Agent rebuilds existing libraries from scratch instead of using npm packages. Writes a custom JWT library when `jsonwebtoken` exists.

**Prevention:**
- Research phase explicitly discovers correct packages BEFORE build starts
- Context7 queries return actual library APIs — agent sees the real package interface
- RESEARCH.md includes specific package names and setup commands
- Build rules: "Check if a package exists before building from scratch"

**Guardrail in pipeline:** Phase 2 Research + Context7 integration — discover packages before coding.

---

## Failure Mode 9: Risk-Averse Paralysis

**What happens:** Agent afraid to break things, takes shortcuts like commenting out code, adding TODO stubs, or implementing partial features to avoid errors.

**Prevention:**
- Explicit permission in build rules: "Write complete, production-quality code"
- Deviation Rule 1-3: Auto-fix bugs and blocking issues without hesitation
- Walking skeleton proves the foundation works — features build on solid ground
- Per-task commits mean any breakage is easily revertable

**Guardrail in pipeline:** Build rules explicitly ban TODOs, placeholders, and "implement later" comments.

---

## Failure Mode 10: Quality Cliff in Final 20%

**What happens:** Output quality degrades sharply in the last 20% of context window. Polish phase produces sloppy code.

**Prevention:**
- Ralph Loop runs as a SEPARATE session with fresh context for polish
- Features are built one at a time with re-grounding — context stays fresh
- Segmented execution (Strategy B) spawns fresh agents for each segment
- Ship verification runs as final check with fresh eyes

**Guardrail in pipeline:** Ralph Loop invocation for polish — fresh context, iterative refinement.

---

## Known Gotchas (Updated from Test Runs)

### Prisma 7.x Breaking Changes
Prisma 7 removes the traditional `PrismaClient()` constructor. You MUST use the driver adapter pattern:
- Install: `@prisma/adapter-better-sqlite3` + `better-sqlite3` (for SQLite)
- Import from `@/generated/prisma/client` (not `@/generated/prisma`)
- Constructor: `new PrismaClient({ adapter })` — NOT `new PrismaClient()` or `new PrismaClient({ datasourceUrl })`
- Class name: `PrismaBetterSqlite3` (lowercase `qlite`, not `SQLite3`)
- DB location: `process.cwd()` + `dev.db` at project root (not `prisma/dev.db`)
- Schema: use `provider = "prisma-client"` in generator, no `url` in datasource for SQLite with adapter

```typescript
import { PrismaClient } from "@/generated/prisma/client"
import { PrismaBetterSqlite3 } from "@prisma/adapter-better-sqlite3"
import path from "path"

const dbPath = path.join(process.cwd(), "dev.db")
const adapter = new PrismaBetterSqlite3({ url: `file:${dbPath}` })
const prisma = new PrismaClient({ adapter })
```

### pnpm Build Scripts Blocked
pnpm blocks native module compilation by default (e.g., `better-sqlite3`). After installing native deps:
```bash
pnpm approve-builds
```
Without this, the database driver silently fails with 0-byte DB files.

### create-next-app vs .planning/ Conflict
`create-next-app` and similar scaffolding tools reject non-empty directories. Always:
1. Scaffold into empty directory FIRST
2. Run `init-project.sh` AFTER scaffolding completes
Never initialize `.planning/` before running the scaffolder.

### WebSearch Unavailability
WebSearch can return "unavailable" for ~50% of queries. Always:
1. Retry with rephrased query
2. Fall back to Context7 docs
3. Document gaps in RESEARCH.md under "Unverified Assumptions"

---

## Master Prevention Checklist

After completing each feature, verify these guardrails are holding:

```
[ ] features.json is unmodified (no scope changes)
[ ] Feature was committed atomically
[ ] Build still passes
[ ] Previous features still work
[ ] No TODO or placeholder code in committed files
[ ] STATE.md reflects current position accurately
[ ] Context feels manageable (not exhausted)
```

If any check fails, stop and fix before proceeding to the next feature. Prevention is always cheaper than debugging cascaded failures across multiple features.

---

## When to Escalate to User

Despite all guardrails, some situations require human judgment:

1. **Architectural conflict** — Two features need contradictory approaches
2. **Third-party service decision** — Choice between paid services with different tradeoffs
3. **Scope ambiguity** — Feature requirement is genuinely ambiguous even after intake
4. **Auth/security model** — Security decisions should always be validated by humans
5. **> 3 failed fix attempts** — Agent is stuck in a loop and needs fresh perspective

Use deviation Rule 4 (STOP and ask user) for these situations.
