---
name: review
description: Review code changes on the current branch against main using 3 parallel agent reviewers (standards, logic, risk). Use after implementing changes and before opening a PR.
user-invocable: true
allowed-tools: Bash(git *), Bash(mkdir *), Read, Write, Grep, Glob, Agent
---

You are orchestrating a code review of the current branch against `main` using three specialized review agents. Each agent reviews from a different perspective. Run them in parallel for speed.

## Step 1: Verify there are changes to review

```
git log main..HEAD --oneline
```

If there are no commits ahead of `main`, tell the user and stop.

## Step 2: Capture the review key

Get the current HEAD SHA — this is the review key used for saving findings.

```
git rev-parse HEAD
```

Create the output directory:

```
mkdir -p tmp/review/<sha>
```

## Step 3: Launch review agents

Spawn all three review agents **in parallel** using the Agent tool:

1. **review-standards** agent — with subagent_type `review` and the task: review the current branch against main for standards compliance
2. **review-logic** agent — with subagent_type `review` and the task: review the current branch against main for logic correctness
3. **review-risk** agent — with subagent_type `review` and the task: review the current branch against main for security and risk

Each agent will run `git diff main...HEAD` to get the changes.

## Step 4: Save individual findings

Write each agent's output to its own file:

- `tmp/review/<sha>/standards.md`
- `tmp/review/<sha>/logic.md`
- `tmp/review/<sha>/risk.md`

## Step 5: Aggregate and save

Combine all findings into `tmp/review/<sha>/findings.md`:

```markdown
# Code Review

<standards agent output>

<logic agent output>

<risk agent output>

## Summary

| Axis | Verdict | Blockers | Warnings | Nits | Auto-fixable |
|------|---------|----------|----------|------|--------------|
| Standards | PASS/FAIL | N | N | N | N |
| Logic | PASS/FAIL | N | N | N | N |
| Risk | PASS/FAIL | N | N | N | N |

## Overall Verdict

<PASS if all three pass, FAIL if any fail>

Auto-fixable findings: N — run `/fix` to resolve them.
Needs-human findings: N — listed above, require manual review.
```

## Output

Print the full aggregated review report to the user.
