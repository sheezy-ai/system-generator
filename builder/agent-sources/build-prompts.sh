#!/bin/bash
# Build expert prompts from source files
# Injects common sections and substitutes placeholders

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$PROJECT_ROOT/agents"

# Explicit paths for agent prompts (these get substituted into generated files)
AGENTS_PATH="$AGENTS_DIR"
GUIDES_PATH="$PROJECT_ROOT/guides"
SYSTEM_DESIGN_PATH="/Users/sean.sheehan/projects/experiential/experiential-design"

# Source stage configuration
source "$SCRIPT_DIR/stage-config.sh"

# Map source stage names to output directory names
get_output_dir() {
    local stage="$1"
    case "$stage" in
        "01-blueprint") echo "01-blueprint" ;;
        "02-prd") echo "02-prd" ;;
        "03-foundations") echo "03-foundations" ;;
        "04-architecture") echo "04-architecture" ;;
        "05-components") echo "05-components" ;;
        "06-tasks") echo "06-tasks" ;;
        "07-conventions") echo "07-conventions" ;;
        "08-build") echo "08-build" ;;
        "09-verification") echo "09-verification" ;;
        "10-provisioning") echo "10-provisioning" ;;
        "11-packaging") echo "11-packaging" ;;
        "12-operations-readiness") echo "12-operations-readiness" ;;
        *) echo "Unknown stage: $stage" >&2; return 1 ;;
    esac
}

# Inject common sections into content
inject_common_sections() {
    local content="$1"

    # Inject shared common sections
    for common_file in "$SCRIPT_DIR/common"/*.md; do
        if [[ -f "$common_file" ]]; then
            local section_name=$(basename "$common_file" .md)
            local marker="<!-- INJECT: $section_name -->"
            local section_content
            section_content=$(cat "$common_file")
            content="${content//$marker/$section_content}"
        fi
    done

    # Substitute path placeholders with explicit absolute paths
    content="${content//\{\{AGENTS_PATH\}\}/$AGENTS_PATH}"
    content="${content//\{\{GUIDES_PATH\}\}/$GUIDES_PATH}"
    content="${content//\{\{SYSTEM_DESIGN_PATH\}\}/$SYSTEM_DESIGN_PATH}"

    echo "$content"
}

# Inject create-specific common sections
inject_create_sections() {
    local content="$1"

    for common_file in "$SCRIPT_DIR/common/create"/*.md; do
        if [[ -f "$common_file" ]]; then
            local section_name=$(basename "$common_file" .md)
            local marker="<!-- INJECT: $section_name -->"
            local section_content
            section_content=$(cat "$common_file")
            content="${content//$marker/$section_content}"
        fi
    done

    echo "$content"
}

# Inject review-specific common sections
inject_review_sections() {
    local content="$1"

    for common_file in "$SCRIPT_DIR/common/review"/*.md; do
        if [[ -f "$common_file" ]]; then
            local section_name=$(basename "$common_file" .md)
            local marker="<!-- INJECT: $section_name -->"
            local section_content
            section_content=$(cat "$common_file")
            content="${content//$marker/$section_content}"
        fi
    done

    echo "$content"
}

# Clean stale .md files from an output directory that have no corresponding source
clean_output_dir() {
    local output_dir="$1"
    local source_dir="$2"

    if [[ ! -d "$output_dir" ]]; then
        return
    fi

    for output_file in "$output_dir"/*.md; do
        if [[ -f "$output_file" ]]; then
            local basename
            basename=$(basename "$output_file")
            if [[ ! -f "$source_dir/$basename" ]]; then
                echo "  Removing stale: $output_file"
                rm "$output_file"
            fi
        fi
    done

    # Remove empty directories
    if [[ -d "$output_dir" ]] && [[ -z "$(ls -A "$output_dir" 2>/dev/null)" ]]; then
        rmdir "$output_dir"
        echo "  Removed empty directory: $output_dir"
    fi
}

# Clean stale files recursively (handles expert subdirectories)
clean_output_dir_recursive() {
    local output_dir="$1"
    local source_dir="$2"

    if [[ ! -d "$output_dir" ]]; then
        return
    fi

    # Clean top-level .md files
    clean_output_dir "$output_dir" "$source_dir"

    # Clean subdirectories
    for output_subdir in "$output_dir"/*/; do
        if [[ -d "$output_subdir" ]]; then
            local subdir_name
            subdir_name=$(basename "$output_subdir")
            if [[ -d "$source_dir/$subdir_name" ]]; then
                clean_output_dir "$output_subdir" "$source_dir/$subdir_name"
            else
                echo "  Removing stale directory: $output_subdir"
                rm -rf "$output_subdir"
            fi
        fi
    done

    # Remove empty parent if everything was cleaned
    if [[ -d "$output_dir" ]] && [[ -z "$(ls -A "$output_dir" 2>/dev/null)" ]]; then
        rmdir "$output_dir"
        echo "  Removed empty directory: $output_dir"
    fi
}

# Process a single Create expert file
build_create_expert() {
    local stage="$1"
    local expert_file="$2"
    local expert_name=$(basename "$expert_file" .md)

    # Get stage configuration
    get_stage_config "$stage"

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file="$AGENTS_DIR/$output_dir_name/create/experts/$expert_name.md"

    # Start with the core expert file
    local content
    content=$(cat "$expert_file")

    # Inject common sections
    content=$(inject_common_sections "$content")
    content=$(inject_create_sections "$content")

    # Substitute placeholders
    content="${content//\{\{DOCUMENT\}\}/$DOCUMENT}"
    content="${content//\{\{DOCUMENT_LOWER\}\}/$DOCUMENT_LOWER}"
    content="${content//\{\{DRAFT_DOCUMENT\}\}/$DRAFT_DOCUMENT}"
    content="${content//\{\{SOURCE_DOCUMENTS\}\}/$SOURCE_DOCUMENTS}"
    content="${content//\{\{MATURITY_GUIDE\}\}/$MATURITY_GUIDE}"
    content="${content//\{\{OUTPUT_BASE\}\}/$OUTPUT_BASE}"
    content="${content//\{\{ITEM_TYPE\}\}/gaps}"

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single Initialize workflow file
build_initialize_workflow() {
    local stage="$1"
    local workflow_file="$2"
    local workflow_name=$(basename "$workflow_file" .md)

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file="$AGENTS_DIR/$output_dir_name/initialize/$workflow_name.md"

    # Start with the core workflow file
    local content
    content=$(cat "$workflow_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single Cross-Cutting workflow file
build_cross_cutting_workflow() {
    local stage="$1"
    local workflow_file="$2"
    local workflow_name=$(basename "$workflow_file" .md)

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file="$AGENTS_DIR/$output_dir_name/cross-cutting/$workflow_name.md"

    # Start with the core workflow file
    local content
    content=$(cat "$workflow_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single Coherence workflow file
build_coherence_workflow() {
    local stage="$1"
    local workflow_file="$2"
    local workflow_name=$(basename "$workflow_file" .md)

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file="$AGENTS_DIR/$output_dir_name/coherence/$workflow_name.md"

    # Start with the core workflow file
    local content
    content=$(cat "$workflow_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single Create workflow file
build_create_workflow() {
    local stage="$1"
    local workflow_file="$2"
    local workflow_name=$(basename "$workflow_file" .md)

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file="$AGENTS_DIR/$output_dir_name/create/$workflow_name.md"

    # Start with the core workflow file
    local content
    content=$(cat "$workflow_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single Review expert file
build_review_expert() {
    local stage="$1"
    local expert_file="$2"
    local subdir="$3"  # Optional: "build" or "ops" for component-specs
    local expert_name=$(basename "$expert_file" .md)

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file
    if [[ -n "$subdir" ]]; then
        output_file="$AGENTS_DIR/$output_dir_name/review/experts/$subdir/$expert_name.md"
    else
        output_file="$AGENTS_DIR/$output_dir_name/review/experts/$expert_name.md"
    fi

    # Start with the core expert file
    local content
    content=$(cat "$expert_file")

    # Inject common sections
    content=$(inject_common_sections "$content")
    content=$(inject_review_sections "$content")

    # Substitute placeholders
    content="${content//\{\{ITEM_TYPE\}\}/issues}"

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single Review workflow file
build_review_workflow() {
    local stage="$1"
    local workflow_file="$2"
    local workflow_name=$(basename "$workflow_file" .md)

    # Get output directory
    local output_dir_name=$(get_output_dir "$stage")
    local output_file="$AGENTS_DIR/$output_dir_name/review/$workflow_name.md"

    # Start with the core workflow file
    local content
    content=$(cat "$workflow_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single stage file (07-conventions, 08-build)
build_stage_file() {
    local stage="$1"
    local source_file="$2"
    local file_name=$(basename "$source_file" .md)

    local output_file="$AGENTS_DIR/$stage/$file_name.md"

    # Start with the core file
    local content
    content=$(cat "$source_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single 06-tasks file
build_tasks_file() {
    local tasks_file="$1"
    local file_name=$(basename "$tasks_file" .md)

    local output_file="$AGENTS_DIR/06-tasks/$file_name.md"

    # Start with the core file
    local content
    content=$(cat "$tasks_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single universal-agent file
build_universal_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)

    local output_file="$AGENTS_DIR/universal-agents/$agent_name.md"

    # Start with the core file
    local content
    content=$(cat "$agent_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Process a single specialist-agent file
build_specialist_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)

    local output_file="$AGENTS_DIR/specialist-agents/$agent_name.md"

    # Start with the core file
    local content
    content=$(cat "$agent_file")

    # Inject common sections
    content=$(inject_common_sections "$content")

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Main build process
echo "Building Create prompts..."
echo ""

# Clean stale create output files
for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/create" ]]; then
        stage=$(basename "$stage_dir")
        output_dir_name=$(get_output_dir "$stage")
        clean_output_dir_recursive "$AGENTS_DIR/$output_dir_name/create" "$stage_dir/create"
    fi
done

for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/create" ]]; then
        stage=$(basename "$stage_dir")
        echo "Stage: $stage"

        # Build workflow files (non-experts)
        for workflow_file in "$stage_dir/create"/*.md; do
            if [[ -f "$workflow_file" ]]; then
                build_create_workflow "$stage" "$workflow_file"
            fi
        done

        # Build expert files
        if [[ -d "$stage_dir/create/experts" ]]; then
            for expert_file in "$stage_dir/create/experts"/*.md; do
                if [[ -f "$expert_file" ]]; then
                    build_create_expert "$stage" "$expert_file"
                fi
            done
        fi

        echo ""
    fi
done

echo "Create build complete."
echo ""

# Build Initialize prompts (currently only 05-components has this)
echo "Building Initialize prompts..."
echo ""

# Clean stale initialize output files
for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/initialize" ]]; then
        stage=$(basename "$stage_dir")
        output_dir_name=$(get_output_dir "$stage")
        clean_output_dir "$AGENTS_DIR/$output_dir_name/initialize" "$stage_dir/initialize"
    fi
done

for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/initialize" ]]; then
        stage=$(basename "$stage_dir")
        echo "Stage: $stage"

        # Build workflow files
        for workflow_file in "$stage_dir/initialize"/*.md; do
            if [[ -f "$workflow_file" ]]; then
                build_initialize_workflow "$stage" "$workflow_file"
            fi
        done

        echo ""
    fi
done

echo "Initialize build complete."
echo ""

# Build Cross-Cutting prompts (currently only 05-components has this)
echo "Building Cross-Cutting prompts..."
echo ""

# Clean stale cross-cutting output files
for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/cross-cutting" ]]; then
        stage=$(basename "$stage_dir")
        output_dir_name=$(get_output_dir "$stage")
        clean_output_dir "$AGENTS_DIR/$output_dir_name/cross-cutting" "$stage_dir/cross-cutting"
    fi
done

for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/cross-cutting" ]]; then
        stage=$(basename "$stage_dir")
        echo "Stage: $stage"

        # Build workflow files
        for workflow_file in "$stage_dir/cross-cutting"/*.md; do
            if [[ -f "$workflow_file" ]]; then
                build_cross_cutting_workflow "$stage" "$workflow_file"
            fi
        done

        echo ""
    fi
done

echo "Cross-Cutting build complete."
echo ""

# Build Coherence prompts (currently only 05-components has this)
echo "Building Coherence prompts..."
echo ""

# Clean stale coherence output files
for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/coherence" ]]; then
        stage=$(basename "$stage_dir")
        output_dir_name=$(get_output_dir "$stage")
        clean_output_dir "$AGENTS_DIR/$output_dir_name/coherence" "$stage_dir/coherence"
    fi
done

for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/coherence" ]]; then
        stage=$(basename "$stage_dir")
        echo "Stage: $stage"

        # Build workflow files
        for workflow_file in "$stage_dir/coherence"/*.md; do
            if [[ -f "$workflow_file" ]]; then
                build_coherence_workflow "$stage" "$workflow_file"
            fi
        done

        echo ""
    fi
done

echo "Coherence build complete."
echo ""

# Build Review prompts
echo "Building Review prompts..."
echo ""

# Clean stale review output files
for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/review" ]]; then
        stage=$(basename "$stage_dir")
        output_dir_name=$(get_output_dir "$stage")
        clean_output_dir_recursive "$AGENTS_DIR/$output_dir_name/review" "$stage_dir/review"
    fi
done

for stage_dir in "$SCRIPT_DIR/stages"/*; do
    if [[ -d "$stage_dir/review" ]]; then
        stage=$(basename "$stage_dir")
        echo "Stage: $stage"

        # Build workflow files (non-experts)
        for workflow_file in "$stage_dir/review"/*.md; do
            if [[ -f "$workflow_file" ]]; then
                build_review_workflow "$stage" "$workflow_file"
            fi
        done

        # Build expert files
        if [[ -d "$stage_dir/review/experts" ]]; then
            # Check for nested structure (component-specs has build/ and ops/)
            if [[ -d "$stage_dir/review/experts/build" ]] || [[ -d "$stage_dir/review/experts/ops" ]]; then
                for subdir in build ops; do
                    if [[ -d "$stage_dir/review/experts/$subdir" ]]; then
                        for expert_file in "$stage_dir/review/experts/$subdir"/*.md; do
                            if [[ -f "$expert_file" ]]; then
                                build_review_expert "$stage" "$expert_file" "$subdir"
                            fi
                        done
                    fi
                done
            else
                # Flat structure
                for expert_file in "$stage_dir/review/experts"/*.md; do
                    if [[ -f "$expert_file" ]]; then
                        build_review_expert "$stage" "$expert_file"
                    fi
                done
            fi
        fi

        echo ""
    fi
done

echo "Review build complete."
echo ""

# Build 06-tasks prompts
echo "Building 06-tasks prompts..."
echo ""

# Clean stale 06-tasks output files
if [[ -d "$SCRIPT_DIR/stages/06-tasks" ]]; then
    clean_output_dir "$AGENTS_DIR/06-tasks" "$SCRIPT_DIR/stages/06-tasks"
fi

if [[ -d "$SCRIPT_DIR/stages/06-tasks" ]]; then
    for tasks_file in "$SCRIPT_DIR/stages/06-tasks"/*.md; do
        if [[ -f "$tasks_file" ]]; then
            build_tasks_file "$tasks_file"
        fi
    done
fi

echo "06-tasks build complete."
echo ""

# Build 07-conventions prompts
echo "Building 07-conventions prompts..."
echo ""

# Clean stale 07-conventions output files
if [[ -d "$SCRIPT_DIR/stages/07-conventions" ]]; then
    clean_output_dir "$AGENTS_DIR/07-conventions" "$SCRIPT_DIR/stages/07-conventions"
fi

if [[ -d "$SCRIPT_DIR/stages/07-conventions" ]]; then
    for conventions_file in "$SCRIPT_DIR/stages/07-conventions"/*.md; do
        if [[ -f "$conventions_file" ]]; then
            build_stage_file "07-conventions" "$conventions_file"
        fi
    done
fi

echo "07-conventions build complete."
echo ""

# Build 08-build prompts
echo "Building 08-build prompts..."
echo ""

# Clean stale 08-build output files
if [[ -d "$SCRIPT_DIR/stages/08-build" ]]; then
    clean_output_dir "$AGENTS_DIR/08-build" "$SCRIPT_DIR/stages/08-build"
fi

if [[ -d "$SCRIPT_DIR/stages/08-build" ]]; then
    for build_file in "$SCRIPT_DIR/stages/08-build"/*.md; do
        if [[ -f "$build_file" ]]; then
            build_stage_file "08-build" "$build_file"
        fi
    done
fi

echo "08-build build complete."
echo ""

# Build 09-verification prompts
echo "Building 09-verification prompts..."
echo ""

# Clean stale 09-verification output files
if [[ -d "$SCRIPT_DIR/stages/09-verification" ]]; then
    clean_output_dir "$AGENTS_DIR/09-verification" "$SCRIPT_DIR/stages/09-verification"
fi

if [[ -d "$SCRIPT_DIR/stages/09-verification" ]]; then
    for verification_file in "$SCRIPT_DIR/stages/09-verification"/*.md; do
        if [[ -f "$verification_file" ]]; then
            build_stage_file "09-verification" "$verification_file"
        fi
    done
fi

echo "09-verification build complete."
echo ""

# Build 10-provisioning prompts
echo "Building 10-provisioning prompts..."
echo ""

# Clean stale 10-provisioning output files
if [[ -d "$SCRIPT_DIR/stages/10-provisioning" ]]; then
    clean_output_dir "$AGENTS_DIR/10-provisioning" "$SCRIPT_DIR/stages/10-provisioning"
fi

if [[ -d "$SCRIPT_DIR/stages/10-provisioning" ]]; then
    for provisioning_file in "$SCRIPT_DIR/stages/10-provisioning"/*.md; do
        if [[ -f "$provisioning_file" ]]; then
            build_stage_file "10-provisioning" "$provisioning_file"
        fi
    done
fi

echo "10-provisioning build complete."
echo ""

# Build 11-packaging prompts
echo "Building 11-packaging prompts..."
echo ""

# Clean stale 11-packaging output files
if [[ -d "$SCRIPT_DIR/stages/11-packaging" ]]; then
    clean_output_dir "$AGENTS_DIR/11-packaging" "$SCRIPT_DIR/stages/11-packaging"
fi

if [[ -d "$SCRIPT_DIR/stages/11-packaging" ]]; then
    for packaging_file in "$SCRIPT_DIR/stages/11-packaging"/*.md; do
        if [[ -f "$packaging_file" ]]; then
            build_stage_file "11-packaging" "$packaging_file"
        fi
    done
fi

echo "11-packaging build complete."
echo ""

# Build 12-operations-readiness prompts
echo "Building 12-operations-readiness prompts..."
echo ""

# Clean stale 12-operations-readiness output files
if [[ -d "$SCRIPT_DIR/stages/12-operations-readiness" ]]; then
    clean_output_dir "$AGENTS_DIR/12-operations-readiness" "$SCRIPT_DIR/stages/12-operations-readiness"
fi

if [[ -d "$SCRIPT_DIR/stages/12-operations-readiness" ]]; then
    for ops_readiness_file in "$SCRIPT_DIR/stages/12-operations-readiness"/*.md; do
        if [[ -f "$ops_readiness_file" ]]; then
            build_stage_file "12-operations-readiness" "$ops_readiness_file"
        fi
    done
fi

echo "12-operations-readiness build complete."
echo ""

# Build universal-agents prompts
echo "Building universal-agents prompts..."
echo ""

# Clean stale universal-agents output files
if [[ -d "$SCRIPT_DIR/universal-agents" ]]; then
    clean_output_dir "$AGENTS_DIR/universal-agents" "$SCRIPT_DIR/universal-agents"
fi

if [[ -d "$SCRIPT_DIR/universal-agents" ]]; then
    for agent_file in "$SCRIPT_DIR/universal-agents"/*.md; do
        if [[ -f "$agent_file" ]]; then
            build_universal_agent "$agent_file"
        fi
    done
fi

echo "Universal-agents build complete."
echo ""

# Build specialist-agents prompts
echo "Building specialist-agents prompts..."
echo ""

# Clean stale specialist-agents output files
if [[ -d "$SCRIPT_DIR/specialist-agents" ]]; then
    clean_output_dir "$AGENTS_DIR/specialist-agents" "$SCRIPT_DIR/specialist-agents"
fi

if [[ -d "$SCRIPT_DIR/specialist-agents" ]]; then
    for agent_file in "$SCRIPT_DIR/specialist-agents"/*.md; do
        if [[ -f "$agent_file" ]]; then
            build_specialist_agent "$agent_file"
        fi
    done
fi

echo "Specialist-agents build complete."
echo ""

echo "Builder build complete."
echo ""

# ===================================================================
# Build Operator agent prompts
# ===================================================================

echo "Building Operator prompts..."
echo ""

# Operator paths (resolved to absolute paths)
OPERATOR_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)/operator"
OPERATOR_SOURCES="$OPERATOR_ROOT/agent-sources"
OPERATOR_AGENTS="$OPERATOR_ROOT/agents"

# Operator-specific placeholder values
# OPERATOR_AGENTS_PATH is resolved at build time (absolute path to built agents)
OPERATOR_AGENTS_PATH="$OPERATOR_AGENTS"

# Project-specific paths — override via environment for project-specific builds
# If not set, placeholders remain in output for resolution at project init time
OPERATOR_ARTEFACTS_PATH="${OPERATOR_ARTEFACTS_PATH:-}"
OPERATOR_STATE_PATH="${OPERATOR_STATE_PATH:-}"

# Build a single operator agent file
build_operator_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)

    local output_file="$OPERATOR_AGENTS/$agent_name.md"

    # Start with the core file
    local content
    content=$(cat "$agent_file")

    # Inject common sections (shared from builder/agent-sources/common/)
    content=$(inject_common_sections "$content")

    # Substitute operator-specific placeholders
    content="${content//\{\{OPERATOR_AGENTS_PATH\}\}/$OPERATOR_AGENTS_PATH}"

    # Substitute project-specific paths only if set (otherwise placeholders remain)
    if [[ -n "$OPERATOR_ARTEFACTS_PATH" ]]; then
        content="${content//\{\{ARTEFACTS_PATH\}\}/$OPERATOR_ARTEFACTS_PATH}"
    fi
    if [[ -n "$OPERATOR_STATE_PATH" ]]; then
        content="${content//\{\{STATE_PATH\}\}/$OPERATOR_STATE_PATH}"
    fi

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Clean stale operator output files
if [[ -d "$OPERATOR_SOURCES" ]]; then
    clean_output_dir "$OPERATOR_AGENTS" "$OPERATOR_SOURCES"
fi

if [[ -d "$OPERATOR_SOURCES" ]]; then
    for agent_file in "$OPERATOR_SOURCES"/*.md; do
        if [[ -f "$agent_file" ]]; then
            build_operator_agent "$agent_file"
        fi
    done
fi

echo "Operator build complete."
echo ""

# ===================================================================
# Build Maintainer agent prompts
# ===================================================================

echo "Building Maintainer prompts..."
echo ""

# Maintainer paths (resolved to absolute paths)
MAINTAINER_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)/maintainer"
MAINTAINER_SOURCES="$MAINTAINER_ROOT/agent-sources"
MAINTAINER_AGENTS="$MAINTAINER_ROOT/agents"

# Build-time resolved placeholder values
# MAINTAINER_AGENTS_PATH: absolute path to built maintainer agents
# BUILDER_AGENTS_PATH: absolute path to built builder agents (for Evolve Agent invoking SB review)
# GENERATOR_ROOT: absolute path to system-generator root (for ARTEFACT-SPEC.md and other generator-level docs)
MAINTAINER_AGENTS_PATH="$MAINTAINER_AGENTS"
BUILDER_AGENTS_PATH="$AGENTS_DIR"
GENERATOR_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)"

# Project-specific paths — override via environment for project-specific builds
# If not set, placeholders remain in output for resolution at project init time
MAINTAINER_MAINTENANCE_PATH="${MAINTAINER_MAINTENANCE_PATH:-}"
MAINTAINER_OPERATIONS_PATH="${MAINTAINER_OPERATIONS_PATH:-}"
MAINTAINER_SOURCE_PATH="${MAINTAINER_SOURCE_PATH:-}"
MAINTAINER_STATE_PATH="${MAINTAINER_STATE_PATH:-}"

# Build a single maintainer agent file
build_maintainer_agent() {
    local agent_file="$1"
    local agent_name=$(basename "$agent_file" .md)

    local output_file="$MAINTAINER_AGENTS/$agent_name.md"

    # Start with the core file
    local content
    content=$(cat "$agent_file")

    # Inject common sections (shared from builder/agent-sources/common/)
    content=$(inject_common_sections "$content")

    # Substitute build-time resolved placeholders
    content="${content//\{\{MAINTAINER_AGENTS_PATH\}\}/$MAINTAINER_AGENTS_PATH}"
    content="${content//\{\{BUILDER_AGENTS_PATH\}\}/$BUILDER_AGENTS_PATH}"
    content="${content//\{\{GENERATOR_ROOT\}\}/$GENERATOR_ROOT}"

    # Substitute project-specific paths only if set (otherwise placeholders remain)
    if [[ -n "$MAINTAINER_MAINTENANCE_PATH" ]]; then
        content="${content//\{\{MAINTENANCE_PATH\}\}/$MAINTAINER_MAINTENANCE_PATH}"
    fi
    if [[ -n "$MAINTAINER_OPERATIONS_PATH" ]]; then
        content="${content//\{\{OPERATIONS_PATH\}\}/$MAINTAINER_OPERATIONS_PATH}"
    fi
    if [[ -n "$MAINTAINER_SOURCE_PATH" ]]; then
        content="${content//\{\{SOURCE_PATH\}\}/$MAINTAINER_SOURCE_PATH}"
    fi
    if [[ -n "$MAINTAINER_STATE_PATH" ]]; then
        content="${content//\{\{STATE_PATH\}\}/$MAINTAINER_STATE_PATH}"
    fi

    # Write output
    mkdir -p "$(dirname "$output_file")"
    echo "$content" > "$output_file"
    echo "  Built: $output_file"
}

# Clean stale maintainer output files
if [[ -d "$MAINTAINER_SOURCES" ]]; then
    clean_output_dir "$MAINTAINER_AGENTS" "$MAINTAINER_SOURCES"
fi

if [[ -d "$MAINTAINER_SOURCES" ]]; then
    for agent_file in "$MAINTAINER_SOURCES"/*.md; do
        if [[ -f "$agent_file" ]]; then
            build_maintainer_agent "$agent_file"
        fi
    done
fi

echo "Maintainer build complete."
echo ""

echo "Build complete."
