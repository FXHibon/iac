# OpenSpec Changes Directory

This directory stores active proposals, design decisions, delta specs, and tasks for ongoing infrastructure changes.

## Directory Structure for a Change

When introducing a new feature, infrastructure modification, or app deployment, create a folder under `changes/`:

```text
openspec/changes/<change-id>/
├── proposal.md     # Rationale, scope, impact, and non-goals
├── design.md       # Technical architecture decisions & IaC component updates
├── tasks.md        # Checkbox implementation checklist
└── specs/          # Delta specifications
    └── <domain>/
        └── spec.md # Added / modified / removed Gherkin scenarios
```

## Lifecycle

1. **Propose**: Create `<change-id>` directory with `proposal.md`, `design.md`, `tasks.md`, and delta specs.
2. **Review & Approve**: Validate specs with maintainers/AI assistants.
3. **Apply**: Execute tasks in `tasks.md` and verify using `task deploy-*` or `task tofu-apply`.
4. **Sync & Archive**: Merge delta specs into `openspec/specs/` source-of-truth and move `<change-id>` to `openspec/changes/archive/<change-id>/`.
