---
name: github
description: Use when interacting with GitHub (issues, PRs, projects, repo exploration)
compatibility: Requires gh CLI
---

# GitHub Skill

Use `gh` CLI to interact with GitHub repositories.

## Key Patterns

- `gh api repos/owner/repo/contents/path` — read files from any repo
- `gh api repos/owner/repo/issues/N/comments` — read issue discussions
- `gh repo view owner/repo` — README and metadata
- Add `--repo owner/repo` to any command for third-party repos
- When creating gists with markdown, use `.md` extension (e.g., `gh gist create README.md`) for proper rendering

## PR Review Comments

PR review comments use numeric IDs in the REST API, not GraphQL node IDs.

- **List review comments**: `gh api repos/OWNER/REPO/pulls/N/comments --jq '.[].id'`
- **Reply to a review comment**: `gh api repos/OWNER/REPO/pulls/N/comments -f body='...' -F in_reply_to=COMMENT_ID` (POST to the same comments endpoint with `in_reply_to`, NOT to a `/replies` sub-endpoint)
- **Get thread GraphQL IDs**: `gh api graphql -f query='{ repository(owner: "OWNER", name: "REPO") { pullRequest(number: N) { reviewThreads(first: 20) { nodes { id isResolved comments(first: 1) { nodes { body } } } } } } }'`
- **Resolve a thread**: `gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "PRRT_..."}) { thread { isResolved } } }'`
- Avoid backticks in `-f body=` strings — shell interpolation issues. Use single quotes.

### Responding to review feedback

After pushing fixes for review comments, reply to each comment explaining what was done, then resolve threads that are fully addressed. Leave threads open if the feedback is deferred or tracked elsewhere.

## Worktree Gotchas

`gh pr merge --delete-branch` fails in worktrees when the base branch is checked out in another worktree. The merge still succeeds on GitHub, but the local branch switch fails. If you see `fatal: 'main' is already used by worktree`, the PR was likely already merged — verify with `gh pr view N --json state`.
