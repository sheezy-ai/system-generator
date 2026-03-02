#!/bin/bash
# Stage configuration for prompt building
# Defines placeholder values for each stage

get_stage_config() {
    local stage="$1"

    case "$stage" in
        "01-blueprint")
            DOCUMENT="Blueprint"
            DOCUMENT_LOWER="Blueprint"
            DRAFT_DOCUMENT="draft Blueprint"
            SOURCE_DOCUMENTS="the Concept document"
            MATURITY_GUIDE="guides/01-blueprint-maturity.md"
            OUTPUT_BASE="system-design/01-blueprint/versions/round-0/02-experts"
            ;;
        "02-prd")
            DOCUMENT="PRD"
            DOCUMENT_LOWER="PRD"
            DRAFT_DOCUMENT="draft PRD"
            SOURCE_DOCUMENTS="the Blueprint"
            MATURITY_GUIDE="guides/02-prd-maturity.md"
            OUTPUT_BASE="system-design/02-prd/versions/round-0/02-experts"
            ;;
        "03-foundations")
            DOCUMENT="Foundations"
            DOCUMENT_LOWER="Foundations"
            DRAFT_DOCUMENT="draft Foundations"
            SOURCE_DOCUMENTS="the PRD"
            MATURITY_GUIDE="guides/03-foundations-maturity.md"
            OUTPUT_BASE="system-design/03-foundations/versions/round-0/02-experts"
            ;;
        "04-architecture")
            DOCUMENT="Architecture Overview"
            DOCUMENT_LOWER="architecture"
            DRAFT_DOCUMENT="draft Architecture Overview"
            SOURCE_DOCUMENTS="PRD and Foundations"
            MATURITY_GUIDE="guides/04-architecture-maturity.md"
            OUTPUT_BASE="system-design/04-architecture/versions/round-0/02-experts"
            ;;
        "05-components")
            DOCUMENT="Component Spec"
            DOCUMENT_LOWER="spec"
            DRAFT_DOCUMENT="draft Component Spec"
            SOURCE_DOCUMENTS="Architecture Overview and Foundations"
            MATURITY_GUIDE="guides/05-components-maturity.md"
            OUTPUT_BASE="system-design/05-components/versions/round-0/02-experts"
            ;;
        *)
            echo "Unknown stage: $stage" >&2
            return 1
            ;;
    esac
}
