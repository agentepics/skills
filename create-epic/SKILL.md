---
name: create-epic
description: >
  Create a new Agent Epic from scratch with all required and operational files.
  Use when the user wants to scaffold a new epic, start a new autonomous workflow,
  create a new capability epic, or set up a new project epic. Handles dual-purpose
  SKILL.md generation, EPIC.md, runtime state, plans, log, cron, hooks, and policy
  generation following the EPIC specification v0.5.2.
license: Apache-2.0
compatibility: Requires file system write access. Works in any workspace with Agent Epics.
metadata:
  author: agentepics
  version: "1.1"
---

# Create Epic

Scaffold a complete, operational Agent Epic following the EPIC specification v0.5.2.

Before generating files, read `references/REFERENCE.md` for the exact canonical
`## Agent Epics` footer, the current runtime layout, and the validation profile.
Use the current authored-package format from `agentepics` and curated `epics`
as the scaffolding target. If `epics.sh` implementation behavior lags behind the
spec, keep the authored files spec-aligned and tell the user about any runtime
follow-up they may still need.

## When to use this skill

- User asks to create a new epic, workflow, or autonomous task
- User wants to scaffold an epic from a description or objective
- User says "new epic", "create epic", "scaffold epic", or "start a new workflow"
- User describes a goal that should become a durable autonomous workflow or capability

## Inputs

Gather or infer the following:

1. **Name** (required) — lowercase-with-hyphens identifier, under 64 characters
2. **Title** (required) — human-readable name
3. **Objective** (required) — what the epic accomplishes in 1–2 sentences
4. **Category** (required) — Execution, Planning, Automation, Governance, Communication, or a custom category
5. **Archetype** (required) — one of:
   - `workflow` — reusable process with fresh runtime state per run
   - `instance` — one-off project with unique scope
   - `capability` — durable agent extension or integration
6. **Cron schedule** (optional) — how often the epic should run autonomously
7. **Tags** (optional) — discovery keywords
8. **Published source** (optional) — where the full epic package is published, for epics intended to be recoverable from a standalone `SKILL.md`

If the user gives a freeform description, infer missing fields and ask only for
what cannot be safely inferred.

## Output structure

Create this authored-package profile:

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

Use `runtime/` for live state. Do not scaffold top-level `state.json`, `plans/`,
`log/`, `ROADMAP.md`, `DECISIONS.md`, or `artifacts/`.

## Operating loop

1. Infer or confirm the inputs.
2. Choose tags, hooks, cron cadence, and policy limits based on the archetype and category.
3. Generate the full epic directory with epic-specific content.
4. Populate `runtime/state.json`, `runtime/plans/001-initial.md`, and `runtime/log/.gitkeep`.
5. Validate the scaffolded epic.
6. Report the created file tree, validator output, and a one-line summary of each file.

## File instructions

### 1. Create `SKILL.md`

Write a dual-purpose `SKILL.md` for `spec_version: 0.5.2`:

- Add standard skill frontmatter with `name` and `description`
- Keep the top section short and activation-oriented
- State what the epic does and when it should activate
- Explicitly say that `EPIC.md` is the authoritative source for lifecycle, state model, guardrails, and resume behavior
- Include a one-line pointer near the top telling first-time readers to see the **Agent Epics** section below
- For published epics intended to be recoverable from only `SKILL.md`, add recommended `metadata.source` frontmatter
- Append the exact canonical footer block from `references/REFERENCE.md`
- Make the canonical footer the final section of the file with nothing after it

Do not use the old `Purpose`, `Operating loop`, and `Rules` structure for authored epics.
Do not paraphrase or rewrite the canonical footer.

For `metadata.source`, support these forms:

- absolute `http` or `https` URL string
- structured object with `repo`, `path`, and optional `ref`

Recommended form:

```yaml
metadata:
  source:
    repo: github.com/agentepics/epics
    path: agent-heartbeat
    ref: main
```

`metadata.source` is recommended for published epics, not required. If it is
absent, the epic is still valid. Hosts may use it to locate the full epic when
only `SKILL.md` is available, but trust policy still governs any fetch or
install behavior.

### 2. Create `EPIC.md`

Use this frontmatter template:

```yaml
---
spec_version: 0.5.2
id: {name}
tags: [{tags}]
timezone: UTC
---
```

Include these sections in the body:

- `## Objective`
- `## Phases`
- `## Success criteria`
- `## State to preserve`
- `## Guardrails`
- `## Resume`

Keep `EPIC.md` focused on the durable operating definition. Put volatile work in
`runtime/`, not in the `EPIC.md` body.

### 3. Create `runtime/state.json`

Always include these reserved fields:

```json
{
  "state_version": 1,
  "status": "active",
  "name": "{title}",
  "current_plan": "001-initial.md"
}
```

Add epic-specific flat fields that reflect the objective. Prefer simple
machine-readable facts over nested structures unless the objective requires
otherwise.

### 4. Create `runtime/plans/001-initial.md`

Use this structure:

```markdown
# {Title} — Initial Plan

Updated: {today's date}

## Now
- {First concrete action}
- {Second concrete action}

## Next
- {Follow-up actions after Now is complete}

## Blocked
- Nothing currently blocked
```

Keep each section concrete. Use 2–4 items where possible.

### 5. Create `runtime/log/`

Always create `runtime/log/.gitkeep`.

Do not write a starter log file unless the task specifically calls for one.

### 6. Create `hooks/`

Always create:

- `install.md`
- `status-changed.md`

Add more hooks based on the archetype:

| Archetype | Additional hooks |
|-----------|------------------|
| workflow | `plan-empty.md`, `milestone-complete.md` |
| instance | `plan-empty.md`, `became-blocked.md` |
| capability | `became-blocked.md` |

Use markdown hooks with YAML frontmatter:

```markdown
---
enabled: true
type: prompt
timeout: 300
---

{Imperative hook instructions that reference runtime/... paths}
```

Use `runtime/...` paths inside hook bodies. Hooks should be specific, imperative,
and idempotent-friendly.

Current `epics.sh` builds may only execute install hooks directly. Still scaffold
the broader typed-hook package surface used by the spec and curated epics, but do
not claim every trigger executes automatically in every host today.

### 7. Create `cron.d/`

If the epic is autonomous, create at least one cron job. For manual-only epics,
skip `cron.d/`.

Suggested schedules:

| Pattern | Schedule | Use for |
|---------|----------|---------|
| Frequent | `*/30 * * * *` | Heartbeats, monitors |
| Hourly | `0 * * * *` | Active execution loops |
| Every few hours | `0 */4 * * *` | Connectivity checks, syncs |
| Daily | `0 9 * * *` | Planning, reporting, audits |
| Weekly | `0 10 * * 1` | Summaries, reviews |

Use this structure:

```yaml
name: {descriptive-name}
schedule: "{cron expression}"
timezone: UTC
enabled: true
run:
  type: prompt
  prompt: |
    {Cycle instructions that reference runtime/state.json, runtime/plans/,
    and other relevant runtime paths}
context:
  - runtime/state.json
output:
  log: true
  update_state: true
  notify: false
```

Current `epics.sh` builds may require explicit daemon route setup for scheduled
execution instead of automatically consuming package `cron.d/` jobs. Still author
the YAML cron files, but note any extra runtime setup the user may need.

### 8. Create `policy.yml`

Use this structure:

```yaml
autonomy:
  max_spend_per_run: {0.10-1.00 depending on risk}
  allowed_tools:
    - bash
    - file_read
    - file_write
  forbidden_actions:
    - {actions this epic must never take}

escalation:
  on_error: log_and_continue
  on_ambiguity: ask_human
```

Suggested spend limits:

- Capability and monitoring epics: `0.10`–`0.25`
- Governance and reporting epics: `0.25`
- Planning epics: `0.50`
- Execution epics: `0.50`–`1.00`

## Validation

After scaffolding:

1. Run `bash scripts/validate-epic.sh <epic-directory>`
2. If the `epics` CLI is available, also run `epics validate <epic-directory>` as an additional package check
3. Fix any failures before considering the epic complete

Verify at minimum:

- `SKILL.md` has standard frontmatter and the exact canonical footer
- `metadata.source` is included when the epic is meant to be published and recoverable from standalone `SKILL.md`
- `EPIC.md` says `spec_version: 0.5.2`
- All live-state references point to `runtime/...`
- `runtime/state.json` includes `state_version`, `status`, `name`, and `current_plan`
- `runtime/plans/001-initial.md` has `Now`, `Next`, and `Blocked`
- `hooks/install.md` exists
- `policy.yml` has `autonomy` and `escalation`
- All generated text is specific to the epic, not placeholder prose

## Edge cases

- If the target directory already exists and contains an epic, warn before overwriting
- If the user wants a manual-only epic, omit `cron.d/` but keep `hooks/`
- If the user gives too little information to infer an objective, ask for the objective before generating
- If the user asks for the smallest possible valid epic, explain that this skill intentionally scaffolds the fuller operational profile
- For capability epics, emphasize that the top section of `SKILL.md` teaches when to activate the capability, while durable behavior lives in `EPIC.md` and `runtime/`
- If the user relies on `epics.sh`, mention that some runtime features may still require extra host or daemon setup even when the authored epic files are correct
