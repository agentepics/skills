# Create Epic — Reference

## EPIC Spec v0.5.0 Quick Reference

### Required files

| File | Purpose |
|------|---------|
| SKILL.md | Routing, instructions, operating loop |
| EPIC.md | Workflow definition, phases, resume instructions |

### Recommended files

| File | Purpose |
|------|---------|
| state.json | Structured state with reserved fields |
| plans/ | Tactical plans with Now/Next/Blocked sections |
| log/ | Append-only activity history |
| cron.d/ | Recurring task definitions (YAML) |
| hooks/ | Event-triggered handlers (markdown or YAML) |
| policy.yml | Autonomy constraints and escalation rules |

### Reserved state.json fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| state_version | integer | 1 | Schema version |
| status | string | "active" | One of: active, paused, complete, abandoned |
| current_plan | string | — | Filename of active plan in plans/ |

### Canonical hook triggers

| Trigger | When it fires |
|---------|---------------|
| install | Epic activated for first time |
| uninstall | Epic removed or torn down |
| status-changed | Lifecycle status changes |
| milestone-complete | ROADMAP.md milestone marked complete |
| plan-empty | Current plan's Now section has no items |
| became-blocked | Epic becomes blocked |
| cron-fired | Any cron.d/ job completes |

### Hook types

| Type | Format | Description |
|------|--------|-------------|
| prompt | .md with YAML frontmatter | Executes in current agent session |
| script | executable file | Subprocess with JSON event on stdin |
| http | .yml with url/method/body | Sends JSON request |
| agent | .md with YAML frontmatter | Spawns sub-agent scoped to epic |

### Cron run types

| Type | Description |
|------|-------------|
| prompt | LLM-driven execution |
| script | Executable subprocess |
| both | Script then prompt |

### Epic archetypes

| Archetype | Description | Key trait |
|-----------|-------------|-----------|
| workflow | Reusable process | Workflow stays stable, state changes |
| instance | One-off project | EPIC.md describes specific project |
| capability | Agent extension | Stays active indefinitely, teaches usage |

### Mutability tiers

| Tier | Files | Who writes |
|------|-------|-----------|
| Working state | plans/, state.json, log/ | Agents, cron |
| Strategic state | ROADMAP.md, DECISIONS.md | Humans, milestones |
| Configuration | SKILL.md, cron.d/, hooks/, policy.yml | Humans only |
| Immutable | scripts/, references/, assets/ | Skill author |

### Timestamp format

All timestamps MUST be ISO 8601 with timezone: `2026-03-08T14:22:44Z`

### Log filename format

`YYYY-MM-DDTHH-MM-SSZ-{actor}-{slug}.md`

Actors: agent, human, cron, hook, hook-error
