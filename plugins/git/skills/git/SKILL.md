---
name: git
description: Use when committing or creating branches
---

# Git Conventions

## Commits

- Stage the files you changed, then use Task tool (model: haiku, run_in_background: true) for the commit message and commit
- If there are unstaged changes to tracked files after staging, mention them before handing off
- If the user asks to include missed files, stage them and amend the previous commit
- Follow existing project conventions (check recent commits, commitlint config, etc.)
- Match the user's style: casing (e.g. lowercase acronyms), punctuation, tense, verbosity
- If no conventions found: imperative mood, capitalized, max 50 chars
- Body only when necessary (blank line, 72 char wrap)

## Branches

- Work on feature branches, not main
- Use worktrees for parallel work; clean up when done
