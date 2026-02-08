# Multi-Model Coordination — Review Protocol

Optional add-on that sends PRD + Architecture docs to a review model before build begins. The review model provides structured feedback that the user can incorporate.

---

## How It Works

```
PRD + Architecture → Review Model (GPT 5.2 / Claude Opus) → Structured Feedback → User Decision → Build
```

1. After Phase 4 (Architecture) completes, check if multi-model review is configured
2. If configured, send PRD.md + ARCHITECTURE.md to the review model
3. Review model returns structured feedback (see format below)
4. Present feedback to user
5. User decides what to incorporate (approve all, cherry-pick, or skip)
6. Proceed to Phase 5 (Plan) with any incorporated changes

---

## Configuration

Multi-model review requires one of:

### Option A: External API (GPT 5.2)
```bash
# In project .env or shell environment
OPENAI_API_KEY=sk-...
SHIP_IT_REVIEW_MODEL=gpt-5.2  # or gpt-4o, o3, etc.
```

### Option B: Claude-Only Mode (No External API)
Use Claude Opus for review and Claude Sonnet for coding. No external API needed.
```bash
SHIP_IT_REVIEW_MODEL=claude-opus  # Uses the current Claude session
```

### Option C: Skip Review
If no review model is configured, the skill skips Phase 4.5 entirely and proceeds directly to Plan. This is the default behavior.

---

## Review Prompt Template

Send this to the review model:

```
You are a senior technical architect reviewing a product specification
and architecture document before a development team begins building.

## Documents to Review

### PRD
[contents of .planning/PRD.md]

### Architecture
[contents of .planning/ARCHITECTURE.md]

## Your Review

Provide structured feedback in exactly these 4 categories:

### STRENGTHS
What's well-designed and should be kept as-is. Be specific.

### CHANGES
What should be modified before building. For each:
- What to change
- Why it matters
- Suggested alternative

### MISSING
What's not addressed but should be. For each:
- What's missing
- Why it's important
- How to add it

### RISKS
Technical or product risks to watch during build. For each:
- The risk
- Likelihood (high/medium/low)
- Mitigation strategy

Keep feedback actionable. Focus on issues that would cause build
failures or require rework, not stylistic preferences.
```

---

## Invoking the Review

### Via Script (External API)

```bash
#!/bin/bash
# scripts/review-with-model.sh
# Sends PRD + Architecture to review model and returns feedback

set -e

PROJECT_DIR="${1:-.}"
REVIEW_MODEL="${SHIP_IT_REVIEW_MODEL:-gpt-5.2}"

# Check for API key
if [ -z "$OPENAI_API_KEY" ] && [[ "$REVIEW_MODEL" == gpt-* ]]; then
    echo "No OPENAI_API_KEY set. Skipping multi-model review."
    exit 0
fi

PRD=$(cat "$PROJECT_DIR/.planning/PRD.md" 2>/dev/null || echo "No PRD found")
ARCH=$(cat "$PROJECT_DIR/.planning/ARCHITECTURE.md" 2>/dev/null || echo "No Architecture doc found")

if [[ "$REVIEW_MODEL" == gpt-* ]]; then
    # OpenAI API call
    RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$(jq -n \
            --arg model "$REVIEW_MODEL" \
            --arg prd "$PRD" \
            --arg arch "$ARCH" \
            '{
                model: $model,
                messages: [
                    {
                        role: "system",
                        content: "You are a senior technical architect reviewing a product specification and architecture document before a development team begins building. Provide structured feedback in 4 categories: STRENGTHS, CHANGES, MISSING, RISKS. Keep feedback actionable."
                    },
                    {
                        role: "user",
                        content: ("## PRD\n" + $prd + "\n\n## Architecture\n" + $arch + "\n\nProvide your review.")
                    }
                ],
                temperature: 0.3,
                max_tokens: 2000
            }')" )

    echo "$RESPONSE" | jq -r '.choices[0].message.content' > "$PROJECT_DIR/.planning/REVIEW.md"
    echo "Review saved to .planning/REVIEW.md"
else
    echo "Claude-only mode: Review will be done in-context."
fi
```

### Via In-Context (Claude-Only Mode)

If using Claude-only mode, the orchestrator reads both docs and performs the review inline:

1. Read `.planning/PRD.md` and `.planning/ARCHITECTURE.md`
2. Apply the review prompt template as a self-critique step
3. Present findings to user
4. Save as `.planning/REVIEW.md`

---

## Presenting Feedback to User

After review completes, present a summary:

```
╔══════════════════════════════════════════════╗
║         MULTI-MODEL REVIEW COMPLETE          ║
╠══════════════════════════════════════════════╣
║                                              ║
║  Reviewed by: [model name]                   ║
║                                              ║
║  STRENGTHS: [N] items                        ║
║  CHANGES:   [N] recommended                  ║
║  MISSING:   [N] gaps identified              ║
║  RISKS:     [N] flagged                      ║
║                                              ║
╚══════════════════════════════════════════════╝
```

Then use AskUserQuestion:
- "Incorporate all changes" — Apply all recommended changes to PRD + Architecture
- "Let me review each" — Walk through changes one by one
- "Skip review feedback" — Proceed to build as-is
- "Show me the full review" — Display complete REVIEW.md

---

## Graceful Degradation

| Scenario | Behavior |
|----------|----------|
| No API key configured | Skip review, proceed to Plan |
| API call fails | Log error, skip review, proceed to Plan |
| Review model returns garbage | Present raw output, let user decide |
| User says "skip" | Proceed immediately, save no review file |

The skill always works without multi-model review. It's a quality enhancement, not a gate.
