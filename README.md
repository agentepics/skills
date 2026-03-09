# Agent Epics Curated Skills

This repository packages reusable skills for the Agent Epics ecosystem.

Each top-level skill directory is a standalone installable unit built around a `SKILL.md` entrypoint. The repository currently ships one curated skill, `create-epic`, plus a synchronized `reference/` directory containing the upstream Epic and Skill specifications it depends on.

## Repository Layout

```text
.
├── create-epic/   # Skill for scaffolding a complete Agent Epic
├── reference/     # Synced upstream specification and runtime docs
└── .github/       # Maintenance automation, including reference sync
```

## Included Skill

### `create-epic`

`create-epic` scaffolds a complete, operational Agent Epic from a user objective. It guides the agent to generate the curated authored profile:

- `SKILL.md`
- `EPIC.md`
- `runtime/state.json`
- `runtime/plans/`
- `runtime/log/`
- `cron.d/`
- `hooks/`
- `policy.yml`

The skill also includes a validator script at `create-epic/scripts/validate-epic.sh` to check generated epics against the expected structure and required sections.

This operational profile is intentionally fuller than the minimum EPIC core
format. Per the upstream spec, a valid Epic only requires `SKILL.md` and
`EPIC.md`; `create-epic` scaffolds the more complete authored package used by
the curated `epics` repo.

## Reference Material

The `reference/` directory is intentionally treated as synced source material, not hand-maintained project documentation. Those files are pulled from `agentepics/agentepics` by `.github/workflows/sync-reference.yml`.

Do not make manual edits in `reference/` unless you also intend to change the sync process or the upstream source, because local edits will be overwritten on the next sync.

## Working On This Repo

When changing the skill itself:

1. Update `create-epic/SKILL.md` if the workflow or output contract changes.
2. Update `create-epic/references/REFERENCE.md` if the quick-reference guidance needs to stay aligned with the skill.
3. Update `create-epic/scripts/validate-epic.sh` if validation rules change.
4. Keep the skill aligned with the synced Epic specification in `reference/`.

When changing repository-level documentation:

- Keep `README.md` focused on repo purpose, structure, and maintenance model.
- Keep `AGENTS.md` focused on contributor and agent workflow constraints.

## Validation

To validate a generated epic:

```bash
create-epic/scripts/validate-epic.sh <epic-directory>
```

The validator checks required files, frontmatter, section presence, state fields, plan layout, hook formatting, cron config, policy structure, and some cross-file consistency rules.

## License

Apache 2.0
