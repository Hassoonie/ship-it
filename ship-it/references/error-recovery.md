# Ship-It Error Recovery — Structured Diagnostic Protocol

When a build error occurs during Phase 6 BUILD, follow this structured protocol instead of ad-hoc debugging. Most errors fall into known categories with known fixes.

---

## 3-Strike Diagnostic Protocol

Every error gets exactly 3 attempts before escalation. No more trial-and-error spirals.

### Strike 1: Quick Fix (30 seconds)

Read the error message. Check the Error Category Quick-Fix Table below. Apply the documented fix. If the error doesn't match a known category, move to Strike 2.

### Strike 2: Structured Diagnosis (2 minutes)

1. **Isolate** — Identify the exact file and line from the error stack trace
2. **Compare** — Read the relevant section in `RESEARCH.md` for correct API patterns
3. **Verify versions** — Check `package.json` for actual installed version vs. what research assumed
4. **Check Context7** — Query `query-docs` for the specific API that's failing
5. Apply the fix based on findings

### Strike 3: Escalate (1 minute)

If Strike 2 didn't resolve it:
1. Log the error to `ISSUES.md` with full context (error message, file, what was tried)
2. If the error **blocks** the current feature: STOP and ask user
3. If the error is **non-blocking**: skip the affected subtask, mark feature as partial, continue
4. Never attempt a 4th fix — diminishing returns lead to context waste

---

## Error Category Quick-Fix Table

| Category | Symptoms | Fix |
|----------|----------|-----|
| **Import error** | `Module not found`, `Cannot find module` | Check package is installed (`pnpm add`), verify import path matches actual export path, check for `@/` alias misconfiguration |
| **API mismatch** | `X is not a function`, `Property X does not exist` | Version mismatch — check `package.json` version, re-query Context7 for that exact version's API |
| **DB error** | `Table does not exist`, `Column not found`, migration fail | Run `npx prisma generate`, run `npx prisma migrate dev`, verify schema matches code expectations |
| **TypeScript** | `Type X is not assignable`, `Property missing` | Read the type definition, fix the shape. For Next.js page props: check if params/searchParams need `await` (Next.js 15+) |
| **Interactive prompt** | Command hangs, no output, agent stalls | Pipe `echo "n" \|` or use `--yes`/`--no-input` flags. See failure-prevention.md gotchas |
| **Native module** | `better-sqlite3` build fails, `node-gyp` errors | Add to `pnpm.onlyBuiltDependencies` in package.json, run `pnpm install` |
| **Build error** | `pnpm build` fails with component errors | Check for missing `"use client"` directives, missing Suspense boundaries, unresolved server/client component mismatches |
| **Auth error** | NextAuth redirect loops, session undefined | Verify `NEXTAUTH_SECRET` is set, check middleware matcher paths, verify provider configuration |
| **Hydration** | `Text content mismatch`, `Hydration failed` | Move dynamic content (dates, random values) behind `useEffect` or `"use client"`, ensure server/client render same initial state |

---

## Version Mismatch Recovery

When actual installed versions differ from research assumptions (caught by Version Pre-Check or by runtime errors):

### Detection

```
Expected (RESEARCH.md):  prisma@6.x
Actual (package.json):   prisma@7.x
```

### Recovery Procedure

1. **Re-query Context7** — `resolve-library-id` for the library, then `query-docs` with the specific API pattern that's failing
2. **Update RESEARCH.md** — Add a "Version Corrections" subsection documenting the actual version and corrected patterns
3. **Fix affected files** — Apply the corrected API patterns from Context7
4. **Verify** — Run `pnpm build` to confirm the fix
5. **Prevent recurrence** — If this library is used in later features, the corrected patterns in RESEARCH.md will be picked up during re-grounding

### When to Re-Query vs. When to Fix Inline

- **Major version difference** (e.g., 6→7): Always re-query Context7. APIs likely changed significantly.
- **Minor version difference** (e.g., 14.1→14.2): Fix inline if the error is obvious. Re-query only if the fix isn't clear.
- **Patch version difference** (e.g., 5.1.0→5.1.3): Almost never an issue. Fix inline.

---

## Prisma-Specific Recovery

Prisma version mismatches were the #1 time sink in testing. This decision tree handles every known Prisma error pattern.

```
Error occurs with Prisma
│
├─ "PrismaClient is not a constructor" or "Cannot find module"
│   ├─ Check: Is Prisma 7.x installed? (check package.json)
│   │   ├─ YES → Use adapter pattern (see failure-prevention.md Prisma 7 section)
│   │   └─ NO → Run `npx prisma generate`, verify import path
│   │
│   └─ Check: Import path correct?
│       ├─ Prisma 7: `@/generated/prisma/client` (with /client)
│       └─ Prisma 6: `@prisma/client`
│
├─ "Table does not exist" or migration errors
│   ├─ Run: `npx prisma migrate dev --name fix`
│   ├─ Then: `npx prisma generate` (Prisma 7 doesn't auto-generate)
│   └─ Verify: DB file exists at expected path (project root for SQLite)
│
├─ "PrismaBetterSqlite3 is not defined"
│   ├─ Check: `@prisma/adapter-better-sqlite3` installed?
│   ├─ Check: Import uses lowercase `Sqlite3` not `SQLite3`
│   └─ Check: `better-sqlite3` in `pnpm.onlyBuiltDependencies`
│
├─ Schema/type mismatch after migration
│   ├─ Run: `npx prisma generate` (always regenerate after schema changes)
│   ├─ Restart: TypeScript server / dev server to pick up new types
│   └─ Verify: Generated client matches schema field names exactly
│
└─ prisma.config.ts errors
    ├─ Check: `dotenv` installed as dev dependency
    ├─ Check: Config imports `dotenv/config`
    └─ Check: Config uses correct provider for chosen adapter
```

### Prisma Recovery Checklist

When any Prisma error occurs, verify these in order:

1. `package.json` — correct Prisma version and adapter packages installed
2. `schema.prisma` — generator uses `prisma-client` provider (Prisma 7), output path set
3. `prisma.config.ts` — exists, imports dotenv, exports config
4. `lib/db.ts` (or equivalent) — uses adapter pattern with correct class name
5. Client generated — `npx prisma generate` was run after last schema change
6. DB file exists — at `process.cwd() + '/dev.db'` for SQLite

---

## Integration with Pipeline

- **During BUILD**: Follow 3-Strike Protocol for every error. Log all Strike 3 escalations to ISSUES.md.
- **During REVIEW (Phase 6.5)**: Reviewers flag potential error-prone patterns. See `quality-gates.md`.
- **During SHIP**: If verification fails, use the Error Category table to classify and fix before re-verifying.
- **Deviation rules update**: "Bugs/blocking issues → apply 3-Strike Protocol (Strike 1→2→3). If Strike 3 reached, log to ISSUES.md and escalate per protocol."
