---
name: create-epic
description: >
  Create a new Agent Epic from scratch with all required and operational files.
  Use when the user wants to scaffold a new epic, start a new autonomous workflow,
  create a new capability epic, or set up a new project epic. Handles SKILL.md,
  EPIC.md, state.json, plans, log, cron, hooks, and policy generation following
  the EPIC specification v0.5.0.
license: Apache-2.0
compatibility: Requires file system write access. Works in any workspace with Agent Epics.
metadata:
  author: agentepics
  version: "1.0"
---

# Create Epic

Scaffold a complete, operational Agent Epic following the EPIC specification v0.5.0.

## When to use this skill

- User asks to create a new epic, workflow, or autonomous task
- User wants to scaffold an epic from a description or objective
- User says "new epic", "create epic", "scaffold epic", "start a new workflow"
- User describes a goal that should become a durable autonomous workflow

## Inputs

Gather the following from the user before creating:

1. **Name** (required) — lowercase-with-hyphens identifier (e.g., `deploy-pipeline`)
2. **Title** (required) — human-readable name (e.g., "Deploy Pipeline")
3. **Objective** (required) — what this epic accomplishes
4. **Category** (required) — one of: Execution, Planning, Automation, Governance, Communication, or a custom category
5. **Archetype** (required) — one of:
   - `workflow` — reusable process (e.g., how to launch SaaS, run outreach)
   - `instance` — one-off project with unique scope
   - `capability` — extends the agent itself (new tools, channels, integrations)
6. **Cron schedule** (optional) — how often the epic should run autonomously
7. **Tags** (optional) — keywords for discovery

If the user provides a freeform description instead of structured inputs, infer these fields from context. Ask only for what cannot be reasonably inferred.

## Output structure

Create the following directory tree at the target location:

```
{name}/
├── SKILL.md              # Routing and instructions
├── EPIC.md               # Workflow definition with YAML frontmatter
├── state.json            # Initial structured state
├── plans/
│   └── 001-initial.md    # First tactical plan
├── log/
│   └── .gitkeep          # Preserve empty directory
├── cron.d/               # At least one cron job if autonomous
│   └── {schedule}.yml
├── hooks/                # Lifecycle hooks
│   ├── install.md        # Always include install hook
│   ├── status-changed.md # Always include status-changed hook
│   └── ...               # Additional hooks based on archetype
└── policy.yml            # Autonomy constraints
```

## Step-by-step instructions

### Step 1: Create SKILL.md

Write a SKILL.md with three sections:

- **Purpose** — one paragraph explaining what this epic does and what it does NOT do
- **Operating loop** — numbered steps the agent follows each cycle
- **Rules** — hard constraints on behavior (3–5 bullet points)

The operating loop must always include:
1. Reading state.json to orient
2. Doing the core work
3. Writing a log entry
4. Updating state.json

### Step 2: Create EPIC.md

Use this frontmatter template:

```yaml
---
spec_version: 0.5.0
id: {name}
tags: [{tags}]
timezone: UTC
---
```

Include these sections in the body:
- **Objective** — what this epic accomplishes (1–2 sentences)
- **Phases** — numbered list of lifecycle phases (3–6 phases)
- **Success criteria** — measurable outcomes (3–5 bullets)
- **State to preserve** — which files hold durable state
- **Guardrails** — what the epic must NOT do (2–4 bullets)
- **Resume** — exact steps to resume from interruption

### Step 3: Create state.json

Always include these reserved fields:

```json
{
  "state_version": 1,
  "status": "active",
  "name": "{title}",
  "current_plan": "001-initial.md"
}
```

Add epic-specific fields based on the objective. Keep it flat — avoid deeply nested objects.

### Step 4: Create plans/001-initial.md

Use this template:

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

Keep each section to 2–4 items. Be specific — "Set up X" not "Get started".

### Step 5: Create hooks/

**Always create these hooks:**

- `install.md` — runs on first activation. Should orient the epic, verify prerequisites, populate initial state, and write the first log entry.
- `status-changed.md` — runs when status changes. Should handle pause/resume/complete transitions and update state accordingly.

**Create additional hooks based on archetype:**

| Archetype | Additional hooks |
|-----------|-----------------|
| workflow | `plan-empty.md`, `milestone-complete.md` |
| instance | `plan-empty.md`, `became-blocked.md` |
| capability | `became-blocked.md` |

Hook format:

```markdown
---
enabled: true
type: prompt
timeout: {120-300}
---

{Prompt instructions for what the hook should do}
```

### Step 6: Create cron.d/

If the epic runs autonomously, create at least one cron job. Choose the schedule based on the epic's nature:

| Pattern | Schedule | Use for |
|---------|----------|---------|
| Frequent | `*/30 * * * *` | Heartbeats, monitors |
| Hourly | `0 * * * *` | Active execution loops |
| Every few hours | `0 */4 * * *` | Connectivity checks, syncs |
| Daily | `0 9 * * *` | Planning, reporting, audits |
| Weekly | `0 10 * * 1` | Summaries, reviews |

Cron format:

```yaml
name: {descriptive-name}
schedule: "{cron expression}"
timezone: UTC
enabled: true
run:
  type: prompt
  prompt: |
    {What the agent should do each cycle. Reference state.json,
    plans/, and other epic files by name.}
context:
  - state.json
output:
  log: true
  update_state: true
  notify: false
```

### Step 7: Create policy.yml

Set autonomy constraints appropriate to the epic's risk level:

```yaml
autonomy:
  max_spend_per_run: {0.10 for low-risk, 0.25 for medium, 1.00 for high}
  allowed_tools:
    - bash
    - file_read
    - file_write
    {add more based on need}
  forbidden_actions:
    - {actions this epic must never take}

escalation:
  on_error: log_and_continue
  on_ambiguity: ask_human
```

Guidelines for spend limits:
- Capability/monitoring epics: $0.10–$0.25
- Governance/reporting epics: $0.25
- Planning epics: $0.50
- Execution epics: $0.50–$1.00

### Step 8: Verify

After creating all files, verify:
- [ ] SKILL.md has Purpose, Operating loop, and Rules sections
- [ ] EPIC.md has valid frontmatter with spec_version 0.5.0
- [ ] EPIC.md has all required sections (Objective, Phases, Success criteria, State to preserve, Guardrails, Resume)
- [ ] state.json has state_version, status, and current_plan fields
- [ ] plans/001-initial.md has Now, Next, and Blocked sections
- [ ] hooks/install.md exists and handles first activation
- [ ] hooks/status-changed.md exists and handles pause/resume
- [ ] At least one cron job exists if the epic is autonomous
- [ ] policy.yml has autonomy and escalation sections
- [ ] All file content is specific to this epic — no generic placeholder text

Then run the validator:

```bash
scripts/validate-epic.sh <epic-directory>
```

The validator checks all required files, frontmatter, body sections, state fields, plan
structure, hook format, cron YAML, policy structure, and cross-file consistency. Fix
any errors before considering the epic complete. Warnings are advisory.

Report the created file tree, validator output, and a one-line summary of each file to the user.

## Edge cases

- If the user wants an epic without cron (manual-only), skip cron.d/ but still create hooks
- If the user provides a very short description, ask for the objective before proceeding
- If the target directory already has an epic, warn the user before overwriting
- For capability epics, emphasize that SKILL.md teaches the agent how to USE the capability across all contexts — not just within this epic
