---
name: fix
description: Fix review findings from /review. Auto-fixes nits and safe auto-fix items, writes unresolved findings for /open-pr to surface as hotspots. Use after /review.
user-invocable: true
allowed-tools: Bash(git *), Bash(mkdir *), Read, Write, Edit, Grep, Glob
---

You fix code issues identified by `/review`. You read the review findings, apply safe fixes automatically, and write unresolved findings to a file for `/open-pr` to surface as hotspots.

## Step 1: Find the review findings

Get the current HEAD SHA and look for findings:

```
git rev-parse HEAD
```

Check `tmp/review/<sha>/findings.md`. If it doesn't exist, fall back to the most recent directory in `tmp/review/` that contains a `findings.md`. If no findings exist at all, tell the user to run `/review` first and stop.

Also read the individual finding files (`standards.md`, `logic.md`, `risk.md`) for full detail.

## Step 2: Categorize findings

Sort all findings into two buckets:

### Bucket 1: Auto-fix (just do it)
- All **nit** severity findings regardless of fix classification
- All **warning** and **blocker** findings marked **auto-fix**

These are two-way doors — mechanical, unambiguous fixes. Apply them without asking.

### Bucket 2: Unresolved (note for humans)
- All **warning** and **blocker** findings marked **needs-human**
- Any finding where the fix is ambiguous or could change behavior in unexpected ways

These are one-way doors or judgment calls. Do NOT apply them. Write them to the unresolved findings file for `/open-pr` to surface.

## Step 3: Apply auto-fixes

For each auto-fix finding:

1. Read the file in full to understand context
2. Apply the suggested fix
3. Verify the fix doesn't break anything obvious (types, imports, etc.)
4. Track what you changed

After all auto-fixes are applied, run any available verification:
- Typecheck if available (`tsc --noEmit`, `pnpm typecheck`, etc.)
- Lint if available (`eslint`, `pnpm lint`, etc.)

If a fix causes a new issue, revert it and move it to the unresolved bucket.

## Step 4: Write unresolved findings

Write all unresolved findings to `tmp/review/<sha>/unresolved.md`:

```markdown
# Unresolved Findings

## [Axis] Finding N: <title>
- **Severity:** blocker/warning
- **File:** path/to/file.ts:42
- **Issue:** <description>
- **Suggested fix:** <what the reviewer suggested>
- **Why this needs a human:** <why an agent shouldn't decide this alone>
```

If there are no unresolved findings, write an empty file with `# Unresolved Findings\n\nNone.`

## Step 5: Commit fixes

After all fixes are applied:

1. Stage the changed files
2. Commit with message: `fix: address review findings`
3. Update the review findings — mark resolved findings in the findings file

If no fixes were applied (all findings were unresolved or already addressed), skip the commit.

## Output

Print a summary:

```
## Fix Summary

Auto-fixed: N findings
- <list of what was fixed>

Unresolved (for human review): N findings
- <list with file:line and one-line description>

Skipped: N findings
- <list of findings that were already resolved>
```
