# AGENTS.md

## Purpose

This repository is a curated-skill package for Agent Epics. The main editable product is the `create-epic` skill. The `reference/` directory is synced from upstream and should be treated as imported specification material.

## Repository Map

- `create-epic/SKILL.md`: primary skill instructions and routing metadata
- `create-epic/references/REFERENCE.md`: concise local reference for the skill
- `create-epic/scripts/validate-epic.sh`: validator for generated epic directories
- `reference/`: synced Epic and Skill specification documents
- `.github/workflows/sync-reference.yml`: automation that refreshes `reference/`

## Working Rules

- Prefer minimal, targeted changes. This repo is mostly specification and skill text.
- Do not hand-edit files under `reference/` unless the task is explicitly about synced reference content.
- If the skill behavior changes, keep `create-epic/SKILL.md`, `create-epic/references/REFERENCE.md`, and `create-epic/scripts/validate-epic.sh` consistent.
- Preserve the repository's documentation-oriented tone. Most changes should improve clarity, not add framework or tooling noise.
- When searching the repo, use `mgrep` for semantic local search.

## Documentation Expectations

- Root `README.md` should explain what the repo contains, how it is organized, and what is synced versus authored here.
- Skill-specific implementation details belong under the skill directory, not the root README.
- Avoid duplicating large sections of the upstream spec in authored docs. Link or point to `reference/` instead.

## Validation Expectations

- If you change validation behavior, inspect `create-epic/scripts/validate-epic.sh` directly and keep examples accurate.
- If you change output requirements for the skill, ensure the validator still matches those requirements.

## Safe Defaults

- Assume this repo is consumed by agents and humans reading plain Markdown files directly.
- Favor explicit file names, directory names, and concrete examples over abstract descriptions.
