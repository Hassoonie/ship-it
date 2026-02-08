# Ship-It Quality Gates — Testing & Code Review

Quality is enforced at two points: tests during BUILD, and a structured code review between BUILD and SHIP.

---

## Testing Strategy

### MVP Test Pyramid

Not every line needs a test. Ship-It follows a pragmatic pyramid for MVPs:

| Layer | Required? | What to Test | Tool |
|-------|-----------|-------------|------|
| **Critical path** | Required | Auth flow, core CRUD, data persistence | vitest + testing-library |
| **Feature smoke** | Required | Each feature's happy path works end-to-end | vitest |
| **Component** | Optional | Isolated UI components with complex state | vitest + testing-library |
| **E2E** | Optional | Full browser flows (only if auth is complex) | Playwright |

**Rule of thumb:** If a feature touches the database or auth, it gets a test. Pure UI layout does not.

### Vitest Setup (During Skeleton Phase)

Add testing infrastructure during skeleton setup, not after:

```bash
pnpm add -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import path from 'path'

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom'
```

Add to `package.json` scripts:
```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

### Test File Conventions

- Co-locate tests: `src/app/api/users/route.test.ts` next to `route.ts`
- Name pattern: `[filename].test.ts` or `[filename].test.tsx`
- One test file per feature minimum (maps to features.json)
- Test file naming matches feature ID: comment `// Tests for F001` at top

### Test Generation Template for Task Agents

When spawning a Task agent for a feature, include this in the agent prompt:

```
## Testing Requirements

After implementing the feature, write tests:

1. Critical path test — verify the main user flow works:
   - API route returns correct data
   - Database operations persist correctly
   - Auth-protected routes reject unauthenticated requests

2. Feature smoke test — verify the feature's happy path:
   - Create/read/update/delete operations work
   - UI renders without errors
   - Form submissions produce expected results

Put tests in: src/[feature-area]/[feature].test.ts
Run with: pnpm test
All tests must pass before marking the feature complete.
```

### When to Skip Tests

- Skeleton phase (Phase 1): No tests yet — just verify manually that the app starts
- Pure layout/styling changes: No tests needed
- Configuration files: No tests needed
- If `pnpm test` doesn't exist yet: Set it up before writing tests

---

## Code Review Protocol (Phase 6.5: REVIEW)

After all features pass but BEFORE polish, run a structured code review using 3 parallel Task agents. This catches integration bugs, security issues, and UX problems that per-feature testing misses.

### Pipeline Position

```
BUILD (6) → REVIEW (6.5) → POLISH → SHIP (7)
```

REVIEW runs only once, after the last feature is marked `passes: true` in `features.json`.

### Review Swarm (3 Agents, Parallel)

Launch exactly 3 Task agents in parallel, each with a different review lens:

**Agent 1 — Correctness Review:**
```
Review the codebase for correctness issues:

1. Read all source files in src/
2. Check for: unused imports, dead code, unreachable branches
3. Check for: incorrect error handling (silent catches, missing try/catch on async)
4. Check for: data flow issues (props not passed, state not updated, missing awaits)
5. Check for: security issues (SQL injection, XSS, exposed secrets, missing auth checks)

Rate each issue: confidence score 0-100.
Return issues as a table: | File | Line | Issue | Confidence | Severity |
```

**Agent 2 — Integration Review:**
```
Review the codebase for integration issues:

1. Trace each user flow from UI → API → Database → Response → UI
2. Check: Are all API routes called from the frontend? Any orphaned routes?
3. Check: Do database queries match the Prisma schema exactly?
4. Check: Are all components imported and rendered where needed?
5. Check: Do shared types match between producers and consumers?
6. Check: Are navigation links pointing to existing routes?

Rate each issue: confidence score 0-100.
Return issues as a table: | Flow | Issue | Confidence | Severity |
```

**Agent 3 — UX Baseline Review:**
```
Review the codebase for UX baseline issues:

1. Check every form: Has validation? Shows errors? Has loading state on submit?
2. Check every async operation: Has loading indicator? Has error state?
3. Check every list: Has empty state? Has loading skeleton?
4. Check navigation: Is current page highlighted? Can user always get back?
5. Check responsive: Any hardcoded widths that would break on mobile?

Rate each issue: confidence score 0-100.
Return issues as a table: | Component | Issue | Confidence | Severity |
```

### Triage Protocol

After all 3 agents return, triage by confidence score:

| Confidence | Action |
|-----------|--------|
| **80-100** | Fix immediately — high certainty this is a real issue |
| **50-79** | Fix if quick (< 2 min), otherwise log to ISSUES.md |
| **< 50** | Log to ISSUES.md only — too uncertain to act on |

### Review Execution Steps

1. Verify all features pass in `features.json`
2. Run `pnpm build` — must pass before review starts
3. Launch 3 review agents in parallel
4. Collect results, deduplicate overlapping issues
5. Triage by confidence score
6. Fix all 80+ issues
7. Fix-or-log 50-79 issues
8. Log < 50 issues to ISSUES.md
9. Run `pnpm build` again after fixes
10. Run `pnpm test` — all tests must still pass
11. Commit review fixes: `fix(review): [summary of fixes]`
12. Proceed to POLISH

### Skip Conditions

Skip REVIEW if:
- Project has fewer than 3 features (too small to benefit)
- Build is already failing (fix build first, then review)
- User explicitly requests skipping review

---

## ISSUES.md Integration

Both testing failures and review findings feed into ISSUES.md:

```markdown
| ID | Severity | Phase | Description | Status |
|----|----------|-------|-------------|--------|
| ISS-001 | High | Review | Missing auth check on /api/users DELETE | Fixed |
| ISS-002 | Medium | Review | No loading state on dashboard | Deferred |
| ISS-003 | Low | Test | Edge case: empty string in search | Deferred |
```

Issues marked "Fixed" during review don't carry forward. Issues marked "Deferred" appear in the Ship Report under "Deferred to v2".
