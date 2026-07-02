---
name: open-pr
description: Build a PR description from review findings and open the PR. Use after /review (and optionally /fix). Does not review or fix code.
user-invocable: true
allowed-tools: Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git rev-parse *), Bash(git add *), Bash(git commit *), Bash(git push -u origin HEAD), Bash(git push origin HEAD), Bash(git push), Bash(gh pr *), Bash(ls *), Bash(mkdir *), Bash(rm -rf tmp/review/*), Read, Grep, Glob
---

You open a pull request. You build the PR description from review findings and commit history, then create the PR. Does not review or fix code.

## Prerequisites

- Branch should be pushed to the remote.
- Review findings should exist in `tmp/review/<commit-sha>/` (from `/review`). If they don't exist, warn the user but proceed — the PR description will note that no AI review was run.

## Step 1: Capture review key and find findings

Get the current HEAD SHA via `git rev-parse HEAD` **before making any commits**. This is the review key. Look for `tmp/review/<sha>/`. If it doesn't exist, fall back to the most recent directory in `tmp/review/` that contains findings files. Read the findings files if they exist.

Also check for `tmp/review/<sha>/unresolved.md` — these are findings that could not be auto-fixed and should be surfaced as hotspots.

## Step 2: Commit any uncommitted changes

Run `git status`. If there are uncommitted changes, show the user the list of changed files and ask for confirmation before staging and committing. Use a conventional commit message (e.g., `fix:`, `feat:`, `chore:`). After any commit, check `git status -sb` — if the branch is ahead of the remote (or has no tracking branch), push with `git push -u origin HEAD`.

## Step 3: Detect PR template

Check for a PR template in the repo:
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `pull_request_template.md`

If a template exists, use its exact section structure for the PR body. Fill in every section based on the actual changes.

If no template exists, use this default structure:

```markdown
## Summary
<!-- What this PR does and why -->

## Key Changes
<!-- Bullet list of the most important changes -->

## AI Review
<!-- AI code review summary -->

## Validation
<!-- Relevant validation steps for this specific PR -->
```

## Step 4: Build the PR description

**CRITICAL: If a PR template was found in Step 3, use its EXACT section structure. Do NOT use the default sections below. Read the template's HTML comments for guidance on what each section expects, and fill them in accordingly.**

The default sections below ONLY apply when no repo PR template exists:

**Summary** — Synthesize from the commit history (`git log main..HEAD --oneline`) and your understanding of the work. Write in prose — explain what changed and why like you'd explain it to a colleague. Not a bulleted list of file changes.

**Key Changes** — Bullet list of the most important changes. Focus on what's different, not every file touched.

**AI Review** — Summarize from the review findings:
- Which review agents ran (standards, logic, risk) and their verdicts
- Number of findings by severity
- What was auto-fixed vs. what remains unresolved
- If no review was run, say "No AI review was run for this PR."

**Hotspots / Unresolved findings** — If the template has a section for hotspots, review areas, or similar, surface:
- Any unresolved findings from `unresolved.md`
- Areas of real risk from your judgment
- If there are no hotspots, say so explicitly

**Validation** — List specific, relevant validation steps for THIS PR (not generic checklist items — think about what a reviewer should actually verify).

## Markdown formatting — do NOT over-escape

The heredoc in Step 5 (`<<'EOF'`) prevents shell expansion, so the PR body is passed to GitHub as literal markdown. **Write markdown as it should render. Do not defensively escape characters that have no special markdown meaning.**

Common over-escape mistakes to avoid:

- `\~50 endpoints` → write `~50 endpoints`. Tilde is not strikethrough unless doubled (`~~text~~`).
- `\_variable\_` in prose → write `_variable_` if you want italics, or just `variable` if you don't. Only escape underscores when surrounding text would otherwise trigger unintended italics.
- `\*` inside prose → write `*`. Same rule as underscore.
- `\[text\]` when it's not a link → write `[text]`.
- `\.` `\#` `\-` `\+` `\(` `\)` `\<` `\>` `\!` `\|` `\&` → write the bare character. None of these need escaping in normal prose.
- Backticks inside backticks → use the right number of backticks rather than escaping.

The only escapes you routinely need are: backslashes inside inline code where they'd otherwise consume the next character, and literal `**`/`*`/`_` when you want them to render visibly inside emphasized text. Trust GitHub's renderer; don't pre-escape.

Spot-check before creating the PR: read your draft body as if it were already rendered. Anywhere you see a stray `\` in front of a non-special character, remove it.

## Step 5: Create the PR

Use `gh pr create`. Pass the body via heredoc:

```bash
gh pr create --title "<short description>" --body "$(cat <<'EOF'
<filled template>

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Title should be under 72 characters. Use conventional commit prefixes: `feat`, `fix`, `refactor`, `chore`, `docs`.

If the PR already exists (branch already has an open PR), update it instead:

```bash
gh pr edit --body "$(cat <<'EOF'
<filled template>
EOF
)"
```

## Cleanup

Remove only the consumed review directory (`tmp/review/<review-key>/`), not all of `tmp/review/`.

## Output

Print the PR URL.
