# System-Generator

Takes a product concept and produces a self-sustaining software system — code, operational infrastructure, and maintenance capability. Humans steer; agents execute.

## Three Frameworks

| Framework | Role | Agents |
|-----------|------|--------|
| **Builder** | Creates the system (12-stage pipeline: concept → design → code → operational artefacts) | 70+ stage-specific agents |
| **Operator** | Runs the system (monitoring, incidents, deployments, routine operations, capacity) | 6 agents |
| **Maintainer** | Evolves the system (patches, features, architectural changes, spec-code consistency) | 8 agents |

Builder is mostly one-shot. Operator and Maintainer run continuously in steady state. Nine shared artefacts connect all three frameworks.

## Build

```bash
./build-prompts.sh
```

Builds agent prompts from source templates (`agent-sources/`) into ready-to-use prompts (`agents/`) for all three frameworks. Injects common sections and resolves path placeholders.

## Initialise a Project

```bash
./init-project.sh [target-directory]
```

Scaffolds the `system-design/` directory structure in the target, copies stage guides, and runs the build.

## Documentation

| Document | What it covers |
|----------|---------------|
| `OVERVIEW.md` | Full conceptual overview — lifecycle, artefact layer, signal flow, design principles |
| `ARTEFACT-SPEC.md` | Format definitions for the 9 shared artefacts |
| `INTEGRATION.md` | Signal formats between Operator and Maintainer |
| `builder/docs/overview.md` | Builder framework internals and stage details |
| `operator/OVERVIEW.md` | Operator concept, workflows, autonomy model |
| `maintainer/OVERVIEW.md` | Maintainer concept, change depth model, autonomy model |
| `*/ARCHITECTURE.md` | Agent design, tool definitions, coordination patterns |

Start with `OVERVIEW.md` for the big picture.
