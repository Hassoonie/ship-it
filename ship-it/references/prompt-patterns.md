# Prompt Enhancement Patterns — REFINE Phase Reference

Distilled from CLEARvAI research (3,007 prompt pairs, 1,185 patterns). This file drives the REFINE phase — transforming vague user prompts into structured, high-quality inputs before intake begins.

---

## The 5-Section Template

Every enhanced prompt follows this structure:

```
Section 1: Role
You are a [specific expert role with relevant domain expertise].

Section 2: Task & Context
[Clear description of what needs to be built, who uses it, and why it matters.
Include: product type, target users, key problem being solved.]

Section 3: Constraints & Evaluation Criteria
* [Specific technical constraints — language, framework, performance]
* [Scope constraints — what's in, what's out]
* [Quality criteria — how to evaluate success]
* [Scale expectations — users, data volume, complexity]

Section 4: Reasoning Style
[How to approach the problem: decompose into phases, prioritize by user value,
consider technical dependencies, validate with tests]

Section 5: Output Format
[What the final deliverable looks like: working app, API spec, component library, etc.
Include: file structure expectations, code style, documentation level]
```

---

## Core Patterns for Software Projects

### 1. Role + Constraints + Format (RCF)
**Most common pattern across all categories (used in 80%+ of top-scoring prompts)**

- **Problem:** Generic prompts produce generic outputs that miss requirements
- **Fix:** Assign expert role, define hard constraints, specify output format
- **Recipe:**
  1. Define role with domain-specific expertise ("senior fullstack engineer specializing in Next.js")
  2. List constraints as bullet points (language, framework, performance, security)
  3. Specify output format explicitly (JSON, code with tests, structured markdown)

### 2. Specification-First Coding (I/O + Contracts)
**Critical for code generation — prevents hallucinated APIs and non-compiling code**

- **Problem:** "Write code" prompts produce incorrect, untestable code
- **Fix:** Define function signatures, I/O examples, and edge cases BEFORE generating code
- **Recipe:**
  1. Provide precise specification: function name, signature, language, environment
  2. Include I/O examples (test cases) and edge cases
  3. Add explicit constraints: performance bounds, banned patterns, required libraries
  4. Require tests alongside implementation

### 3. Task Decomposition and Chaining
**Essential for multi-feature projects — prevents scope sprawl**

- **Problem:** Complex tasks overwhelm single prompts, causing dropped requirements
- **Fix:** Break into ordered subtasks with explicit dependencies
- **Recipe:**
  1. Decompose the product into independent features
  2. Order by dependency (data layer before API, API before UI)
  3. Define clear deliverables per subtask
  4. Chain outputs: each phase's output becomes next phase's input

### 4. Chain-of-Thought Reasoning
**For ambiguous requirements — forces explicit reasoning before action**

- **Problem:** Direct answers skip intermediate steps, causing errors in complex decisions
- **Fix:** Instruct step-by-step reasoning before conclusions
- **Recipe:**
  1. Set role as expert reasoner
  2. Instruct: "Think step-by-step: First analyze requirements, then identify technical approach, then evaluate tradeoffs"
  3. Require reasoning to be visible before final recommendation

### 5. Self-Critique Loop (Critic & Refiner)
**For quality assurance — catches errors before execution**

- **Problem:** Single-pass outputs contain unnoticed errors, hallucinations, or gaps
- **Fix:** Generate draft, then review against criteria, then refine
- **Recipe:**
  1. Generate initial output with clear tagging
  2. Feed draft to critic prompt with explicit criteria (completeness, correctness, feasibility)
  3. Refine based on critique findings
  4. Repeat until criteria met (max 2-3 iterations)

### 6. Structured Input-Output Specification
**For consistent, parseable outputs — prevents freeform sprawl**

- **Problem:** Vague outputs, inconsistent formatting, variable-length responses
- **Fix:** Define input and output schemas explicitly
- **Recipe:**
  1. Define input schema: "Input is [type]: [field1], [field2]..."
  2. Define output schema: "Output must be [format] with keys: [key1: type], [key2: type]..."
  3. Specify constraints: max length, no explanations outside schema
  4. Provide format example

---

## Pattern Selection Logic

When enhancing a user's prompt, select patterns based on what they're building:

| Prompt Type | Primary Patterns | Example Trigger |
|-------------|-----------------|-----------------|
| Build an app/product | RCF + Task Decomposition + Specification-First | "build me a...", "create an app..." |
| Fix/debug something | RCF + Chain-of-Thought | "fix this bug...", "why is this..." |
| Design/architect | RCF + Task Decomposition + Self-Critique | "design a system...", "architect..." |
| Analyze/research | RCF + Chain-of-Thought + Structured I/O | "analyze...", "compare...", "evaluate..." |
| Simple CRUD app | RCF + Specification-First | "todo app", "CRUD for...", "simple..." |
| Complex platform | All 6 patterns | "SaaS", "platform", "marketplace" |

---

## Before → After Examples (Software-Relevant)

### Example 1: Vague App Request
**Before:** "build me a bookmark manager"

**After:**
```
Section 1: Role
You are a senior fullstack engineer specializing in modern web applications
with Next.js, TypeScript, and SQLite.

Section 2: Task & Context
Build a personal bookmark manager web application. Users save URLs, which
get auto-enriched with metadata (title, description, favicon, OG image).
Users organize bookmarks with tags, search across all bookmarks, filter
by tag, and toggle favorites. Single-user, local-first.

Section 3: Constraints & Evaluation Criteria
* Stack: Next.js 14+ (App Router), TypeScript strict, Tailwind CSS, Prisma + SQLite
* Must auto-fetch OG metadata when a URL is saved
* Tags stored as JSON array in SQLite (no join table for MVP)
* Search must cover title, URL, and description fields
* All CRUD operations via Server Actions or Route Handlers
* No authentication needed (single-user)

Section 4: Reasoning Style
Decompose into: skeleton → data layer → core CRUD → tags/favorites →
search/filter → polish. Build walking skeleton first, verify end-to-end,
then add features one at a time.

Section 5: Output Format
Working Next.js application with complete source code. No TODOs or
placeholders. Each feature independently testable and committable.
```

### Example 2: Vague Code Request
**Before:** "write code"

**After:**
```
Section 1: Role
You are an expert Python programmer specializing in data processing.

Section 2: Task & Context
Write a function that processes a CSV file of transaction records and
identifies potentially fraudulent entries based on statistical outliers.

Section 3: Constraints
* Function signature: `detect_fraud(filepath: str) -> list[dict]`
* Use pandas for data processing, scipy for statistics
* Flag transactions > 3 standard deviations from user's mean
* Return list of flagged transaction dicts with reason field
* Handle: empty files, missing columns, malformed rows gracefully

Section 4: Reasoning Style
First validate input, then compute per-user statistics, then flag outliers.

Section 5: Output Format
Python function with type hints, docstring, and 3 unit tests using pytest.
```

### Example 3: Vague Plan Request
**Before:** "create a plan"

**After:**
```
Section 1: Role
You are a strategic planning consultant specializing in software product launches.

Section 2: Task & Context
Create a project plan for launching a language learning mobile app
targeting adults aged 25-45. The app uses spaced repetition and
gamification to teach vocabulary.

Section 3: Constraints
* Timeline: 6 months to MVP launch
* Team: 2 engineers, 1 designer, 1 PM
* Must include: key milestones, dependencies, risk mitigations
* Budget estimate required per phase

Section 4: Reasoning Style
Decompose into phases. For each phase, specify tasks, owners, deadlines,
and dependencies. Identify critical path.

Section 5: Output Format
Structured project plan as markdown with phases, tasks, timeline,
and budget breakdown.
```

---

## How REFINE Uses This File

1. Read user's raw prompt
2. Identify prompt type from Pattern Selection Logic table
3. Apply the 5-Section Template, filling in what the user provided and adding specificity where vague
4. Extract implicit requirements (see pipeline-phases.md Context Extraction table)
5. Present enhanced prompt to user for approval/editing
6. Enhanced prompt becomes input to INTAKE phase

**Key principle:** REFINE adds structure and specificity — it never invents requirements the user didn't imply. When uncertain, leave a `[TO CLARIFY]` marker for INTAKE to resolve.
