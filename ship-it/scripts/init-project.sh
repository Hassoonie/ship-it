#!/bin/bash
# Ship-It v3 Project Initializer
# Creates .planning directory with config, state, and features.json template
#
# IMPORTANT: For greenfield projects using scaffolding tools (create-next-app,
# create-vite, etc.), run the scaffolding FIRST, then run this script.
# Scaffolding tools reject non-empty directories.

set -e

PROJECT_DIR="${1:-.}"
PROJECT_NAME="${2:-my-project}"

echo ""
echo "  SHIP-IT v3 — Project Initialization"
echo "  ======================================"
echo ""

# Safety check: if .planning already exists, skip creation
if [ -d "$PROJECT_DIR/.planning" ]; then
    echo "  .planning/ already exists — skipping initialization"
    echo "  (Use this for resuming interrupted sessions)"
    echo ""
    exit 0
fi

# Detect existing code (brownfield detection)
CODE_FILES=$(find "$PROJECT_DIR" -maxdepth 3 \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -20)
HAS_PACKAGE=false
[ -f "$PROJECT_DIR/package.json" ] || [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/Cargo.toml" ] || [ -f "$PROJECT_DIR/go.mod" ] && HAS_PACKAGE=true

if [ -n "$CODE_FILES" ] || [ "$HAS_PACKAGE" = true ]; then
    echo "  Existing code detected (brownfield project)"
    echo "  Agent 2 will map architecture during research phase"
    BROWNFIELD=true
else
    echo "  No existing code detected (greenfield project)"
    BROWNFIELD=false
fi

echo ""

# Initialize git if needed
if [ ! -d "$PROJECT_DIR/.git" ] && [ ! -f "$PROJECT_DIR/.git" ]; then
    git -C "$PROJECT_DIR" init -q
    echo "  Initialized git repository"
fi

# Create directory structure
mkdir -p "$PROJECT_DIR/.planning/phases"
mkdir -p "$PROJECT_DIR/.planning/todos/pending"
mkdir -p "$PROJECT_DIR/.planning/todos/done"

# Create config.json
cat > "$PROJECT_DIR/.planning/config.json" << 'CONFIGEOF'
{
  "mode": "autonomous",
  "planningDepth": "standard",
  "confirmationGates": false,
  "createdBy": "ship-it-v3",
  "version": "3.0.0"
}
CONFIGEOF

# Create STATE.md
cat > "$PROJECT_DIR/.planning/STATE.md" << STATEEOF
# Project State: $PROJECT_NAME

## Current Position
- **Phase**: 0 — Initialization
- **Status**: Pipeline starting
- **Started**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Brownfield**: $BROWNFIELD

## Pipeline Progress
- [ ] Refine complete
- [ ] Intake complete
- [ ] PRD complete
- [ ] Research complete
- [ ] Architecture complete
- [ ] Plan complete (features.json + ROADMAP.md)
- [ ] Skeleton verified
- [ ] Features building
- [ ] All features passing
- [ ] Polish complete
- [ ] Shipped

## Decisions Made
| Decision | Choice | Phase | Reasoning |
|----------|--------|-------|-----------|

## Deferred Issues
(None yet)

## Session History
- $(date -u +"%Y-%m-%dT%H:%M:%SZ") — Ship-It v3 initialized
STATEEOF

# Create features.json template
cat > "$PROJECT_DIR/.planning/features.json" << 'FEATEOF'
{
  "project": "",
  "created": "",
  "features": []
}
FEATEOF

echo "  Project structure initialized:"
echo "    .planning/config.json    (autonomous mode)"
echo "    .planning/STATE.md       (pipeline tracker)"
echo "    .planning/features.json  (immutable scope contract)"
echo "    .planning/phases/        (phase plan storage)"
echo "    .planning/todos/         (issue tracker)"
echo ""
echo "  Ready for Ship-It pipeline execution."
echo ""
