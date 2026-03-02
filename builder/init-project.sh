#!/bin/bash
# init-project.sh - Scaffold system-builder project structure
#
# Usage: ./init-project.sh [target-directory]
#
# Creates system-design/ structure in the target directory (defaults to current directory).
# Builds agents/ in the system-builder directory (where this script lives).
#
# Idempotent - only creates what's missing, never overwrites.
#
# Creates in target directory:
#   - system-design/[stage]/versions/ directories for all 6 stages
#   - system-design/[stage]/guide.md - stage guides
#   - system-design/[stage]/maturity.md - maturity guides (where applicable)
#   - system-design/05-components/specs/ for component specifications
#   - system-design/06-tasks/tasks/ for task files
#   - Deferred items files (stages 02-05)
#   - Pending issues files (stages 01-05)
#   - system-design/01-blueprint/versions/out-of-scope.md
#   - system-design/README.md
#
# Creates in system-builder directory:
#   - agents/ (built from agent-sources/)

set -e

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# Convert to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    # Directory doesn't exist yet, create it
    mkdir -p "$1"
    TARGET_DIR="$(cd "$1" && pwd)"
}

echo "Initialising project structure..."
echo "  Target: $TARGET_DIR"
echo "  Agents: $SCRIPT_DIR/agents"
echo ""

# Track what we create
created=()
existed=()

# Helper: create file if it doesn't exist
create_file() {
    local path="$1"
    local content="$2"
    if [[ -f "$path" ]]; then
        existed+=("$path")
    else
        mkdir -p "$(dirname "$path")"
        echo "$content" > "$path"
        created+=("$path")
    fi
}

# --- Directories ---

dirs=(
    "$TARGET_DIR/system-design/01-blueprint/versions"
    "$TARGET_DIR/system-design/02-prd/versions"
    "$TARGET_DIR/system-design/03-foundations/versions"
    "$TARGET_DIR/system-design/04-architecture/versions"
    "$TARGET_DIR/system-design/05-components/versions"
    "$TARGET_DIR/system-design/05-components/specs"
    "$TARGET_DIR/system-design/06-tasks/tasks"
    "$TARGET_DIR/system-design/07-conventions/versions"
    "$TARGET_DIR/system-design/07-conventions/conventions"
    "$TARGET_DIR/system-design/08-build/versions"
    "$TARGET_DIR/system-design/09-verification/versions"
)

for dir in "${dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        existed+=("$dir/")
    else
        mkdir -p "$dir"
        created+=("$dir/")
    fi
done

# --- Deferred Items (stages 02-05) ---

deferred_items_template='# Deferred Items

Items deferred here from upstream stages. Review when starting this stage'\''s workflows.

---

## Deferred Items

*(None yet)*'

create_file "$TARGET_DIR/system-design/02-prd/versions/deferred-items.md" "$deferred_items_template"
create_file "$TARGET_DIR/system-design/03-foundations/versions/deferred-items.md" "$deferred_items_template"
create_file "$TARGET_DIR/system-design/04-architecture/versions/deferred-items.md" "$deferred_items_template"
create_file "$TARGET_DIR/system-design/05-components/versions/deferred-items.md" "$deferred_items_template"

# --- Pending Issues (stages 01-05) ---

pending_issues_template='# Pending Issues

Issues identified in downstream stages that need resolution here.

See `docs/pending-issues-format.md` for format specification.

---

## Unresolved

*(None yet)*

---

## Resolved

*(None yet)*'

create_file "$TARGET_DIR/system-design/01-blueprint/versions/pending-issues.md" "$pending_issues_template"
create_file "$TARGET_DIR/system-design/02-prd/versions/pending-issues.md" "$pending_issues_template"
create_file "$TARGET_DIR/system-design/03-foundations/versions/pending-issues.md" "$pending_issues_template"
create_file "$TARGET_DIR/system-design/04-architecture/versions/pending-issues.md" "$pending_issues_template"
# Note: 05-components does not have a stage-level pending-issues.md
# Issues are logged directly to component-level: versions/[component]/pending-issues.md

# --- Shared Files ---

out_of_scope_template='# Out of Scope

Items explicitly excluded from all phases of this project.

These are conscious decisions, not deferrals.

---

## Excluded

*(None yet)*'

create_file "$TARGET_DIR/system-design/01-blueprint/versions/out-of-scope.md" "$out_of_scope_template"

# --- Stage Guides ---

copy_guide() {
    local source="$1"
    local dest="$2"
    if [[ -f "$dest" ]]; then
        existed+=("$dest")
    else
        mkdir -p "$(dirname "$dest")"
        cp "$source" "$dest"
        created+=("$dest")
    fi
}

copy_guide "$SCRIPT_DIR/guides/01-blueprint-guide.md" "$TARGET_DIR/system-design/01-blueprint/guide.md"
copy_guide "$SCRIPT_DIR/guides/02-prd-guide.md" "$TARGET_DIR/system-design/02-prd/guide.md"
copy_guide "$SCRIPT_DIR/guides/02-prd-maturity.md" "$TARGET_DIR/system-design/02-prd/maturity.md"
copy_guide "$SCRIPT_DIR/guides/03-foundations-guide.md" "$TARGET_DIR/system-design/03-foundations/guide.md"
copy_guide "$SCRIPT_DIR/guides/03-foundations-maturity.md" "$TARGET_DIR/system-design/03-foundations/maturity.md"
copy_guide "$SCRIPT_DIR/guides/04-architecture-guide.md" "$TARGET_DIR/system-design/04-architecture/guide.md"
copy_guide "$SCRIPT_DIR/guides/04-architecture-maturity.md" "$TARGET_DIR/system-design/04-architecture/maturity.md"
copy_guide "$SCRIPT_DIR/guides/05-components-guide.md" "$TARGET_DIR/system-design/05-components/guide.md"
copy_guide "$SCRIPT_DIR/guides/05-components-maturity.md" "$TARGET_DIR/system-design/05-components/maturity.md"
copy_guide "$SCRIPT_DIR/guides/06-tasks-guide.md" "$TARGET_DIR/system-design/06-tasks/guide.md"

# --- System README ---

readme_source="$SCRIPT_DIR/agent-sources/system-readme.md"
readme_dest="$TARGET_DIR/system-design/README.md"
agents_path="$SCRIPT_DIR/agents"
project_path="$TARGET_DIR"

if [[ -f "$readme_dest" ]]; then
    existed+=("$readme_dest")
else
    mkdir -p "$(dirname "$readme_dest")"
    sed -e "s|{{AGENTS_PATH}}|$agents_path|g" -e "s|{{PROJECT_PATH}}|$project_path|g" "$readme_source" > "$readme_dest"
    created+=("$readme_dest")
fi

# --- Build Agent Prompts (in system-builder directory) ---

echo "Building agent prompts..."
"$SCRIPT_DIR/agent-sources/build-prompts.sh"
echo ""

# --- Report ---

echo "Created:"
if [[ ${#created[@]} -eq 0 ]]; then
    echo "  (nothing - all structure already exists)"
else
    for item in "${created[@]}"; do
        echo "  $item"
    done
fi

echo ""
echo "Already existed:"
if [[ ${#existed[@]} -eq 0 ]]; then
    echo "  (nothing)"
else
    for item in "${existed[@]}"; do
        echo "  $item"
    done
fi

echo ""
echo "Done."
