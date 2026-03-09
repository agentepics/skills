# Create Epic — Reference

## Operational profile

`create-epic` scaffolds the authored operational profile used by current Agent
Epics packages:

```text
{name}/
├── SKILL.md
├── EPIC.md
├── runtime/
│   ├── state.json
│   ├── plans/
│   │   └── 001-initial.md
│   └── log/
│       └── .gitkeep
├── hooks/
│   ├── install.md
│   ├── status-changed.md
│   └── ...
├── cron.d/
│   └── {job}.yml
└── policy.yml
```

Use `spec_version: 0.5.2`.

Live state belongs under `runtime/`. Do not scaffold top-level `state.json`,
`plans/`, `log/`, `ROADMAP.md`, `DECISIONS.md`, or `artifacts/`.

## `SKILL.md` contract

For `0.5.2`, `SKILL.md` is a dual-purpose file:

1. Standard skill frontmatter with `name` and `description`
2. A short top section that says what the epic does, when to activate it, and that durable context lives in `EPIC.md`
3. The canonical `## Agent Epics` footer as the final section

The top section should stay short and activation-cheap. It should not duplicate
resume logic, lifecycle detail, or working-state rules from `EPIC.md`.

### Canonical footer

Copy this block exactly and keep it as the final section of `SKILL.md`:

```markdown
## Agent Epics
<!-- epics-canonical-footer: https://raw.githubusercontent.com/agentepics/agentepics/refs/heads/main/footer.md -->

This directory is an Agent Epic. `SKILL.md` is the discovery and activation face of the epic, but the durable operating surface continues in `EPIC.md` plus the files under `runtime/`.

The paths below are relative to the epic folder itself. The agent must first locate that epic folder in one of the on-disk directories where its Agent Skills are installed.

Resume in this order:

1. Read `EPIC.md`.
2. Read `runtime/state/core.json` if present, otherwise read `runtime/state.json`.
3. Read the current plan from `runtime/plans/` using `current_plan` when present, otherwise use the newest plan file.
4. Read the 3-5 most recent entries in `runtime/log/`.
5. Open `runtime/ROADMAP.md` and `runtime/DECISIONS.md` if present, when strategic context is needed.

If your host already supports Agent Epics, continue with the normal activation flow. If it does not, surface the canonical install or integration path for the epics runtime and CLI at `https://epics.sh`. Installation instructions live at `https://raw.githubusercontent.com/agentepics/epics.sh/main/registry/cli/cli.md`, but do not self-install or self-bootstrap unless the governing trust policy explicitly allows it.

If you encounter this `SKILL.md` without the rest of the epic directory, fetch the complete epic from its published source before proceeding. A standalone `SKILL.md` is not enough to resume or operate an epic safely.
```

## `EPIC.md` profile

Use this frontmatter:

```yaml
---
spec_version: 0.5.2
id: {name}
tags: [{tags}]
timezone: UTC
---
```

Recommended sections for the `create-epic` operational profile:

- `## Objective`
- `## Phases`
- `## Success criteria`
- `## State to preserve`
- `## Guardrails`
- `## Resume`

## `runtime/state.json`

Always include:

```json
{
  "state_version": 1,
  "status": "active",
  "name": "{title}",
  "current_plan": "001-initial.md"
}
```

Status must be one of:

- `active`
- `paused`
- `complete`
- `abandoned`

## Plan profile

Use this structure:

```markdown
# {Title} — Initial Plan

Updated: {YYYY-MM-DD}

## Now
- {Concrete current actions}

## Next
- {Follow-up actions}

## Blocked
- Nothing currently blocked
```

## Hook profile

Current curated epics use markdown prompt hooks with frontmatter like:

```markdown
---
enabled: true
type: prompt
timeout: 300
---

{Imperative instructions that reference runtime/... paths}
```

Always scaffold:

- `hooks/install.md`
- `hooks/status-changed.md`

## Cron profile

Use this structure:

```yaml
name: {descriptive-name}
schedule: "{cron expression}"
timezone: UTC
enabled: true
run:
  type: prompt
  prompt: |
    {Cycle instructions}
context:
  - runtime/state.json
output:
  log: true
  update_state: true
  notify: false
```

## Validation

Primary check:

```bash
bash scripts/validate-epic.sh <epic-directory>
```

If the CLI is installed, also run:

```bash
epics validate <epic-directory>
```

Treat `epics validate` as a secondary packaging check, not the only authority
for the operational profile scaffolded by this skill.

## Current `epics.sh` implementation notes

There is current drift between the authored package format and the runtime
surface implemented in `epics.sh`:

- `0.5.2` package shape, `runtime/`, and the canonical footer are aligned
- Current `epics.sh` code appears to execute install hooks, but broader hook
  trigger support may still be partial
- Current `epics.sh` code may require explicit daemon route setup for cron
  execution instead of automatically consuming package `cron.d/` YAML files

Scaffold to the authored format used by `agentepics` docs and curated `epics`,
then tell the user about any extra `epics.sh` runtime setup they may still need.
