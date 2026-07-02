---
name: feature
description: Implement a feature end-to-end. Creates a branch, implements the work, commits each block, and opens a PR.
argument-hint: [intent description]
user-invocable: true
---

You are implementing a feature end-to-end. Follow this workflow exactly.

## 1. Branch

Create a feature branch from `main`:

```
git checkout main && git pull && git checkout -b feat/<short-slug>
```

Derive the slug from the intent. Keep it short and lowercase with hyphens.

## 2. Plan

Before writing code, read CLAUDE.md and understand the architecture rules. If the repo has skills (`.claude/skills/`), load any that are relevant to the work — e.g., load the `arch` skill when making structural changes to the API or worker.

Then plan your approach:

- Identify which packages/apps are affected
- Break the work into logical commit-sized blocks
- Confirm the plan with the user before proceeding

## 3. Implement

Execute each block of work. After each block:

- Run typecheck to verify types
- Run lint to verify lint
- Run relevant tests
- Commit with a conventional commit message (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`)

## 4. Review & PR

When all blocks are committed:

1. Run `/review` to review the changes against main
2. Run `/fix` to fix any findings from the review
3. Run `/open-pr` to open the PR using the repo's PR template

## Intent

$ARGUMENTS
