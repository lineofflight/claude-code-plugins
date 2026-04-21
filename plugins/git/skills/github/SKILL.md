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

## Issues & Projects

Everything below is project-agnostic. The actual IDs (project, field, option, issue type) are repo-specific — fetch them once and keep them in the project's own docs.

**Look up issue node ID (for use in other mutations):**

```bash
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") { issue(number: N) { id } }
}'
```

**List a repo's issue types** (to find `issueTypeId`):

```bash
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issueTypes(first: 10) { nodes { id name } }
  }
}'
```

**Set an issue's type** (gh CLI does not yet support `--type`):

```bash
gh api graphql -f query='mutation {
  updateIssue(input: { id: "ISSUE_NODE_ID", issueTypeId: "IT_..." }) {
    issue { issueType { name } }
  }
}'
```

**List a project's fields + single-select option IDs** (Status, etc. — run once per project):

```bash
gh api graphql -f query='{
  organization(login: "ORG") {
    projectV2(number: N) {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options { id name }
          }
        }
      }
    }
  }
}'
```

For user-owned (personal) projects, swap `organization(login: "ORG")` for `user(login: "USER")`.

**Add an issue to a project:**

```bash
gh api graphql -f query='mutation {
  addProjectV2ItemById(input: {
    projectId: "PVT_...",
    contentId: "I_..."
  }) { item { id } }
}'
```

**Find a project item ID for an issue already on the board:**

```bash
gh api graphql -f query='{
  repository(owner: "OWNER", name: "REPO") {
    issue(number: N) {
      projectItems(first: 20) {
        nodes { id project { id title number } }
      }
    }
  }
}'
```

If an issue is on multiple projects, the `project` selection disambiguates which item ID belongs to which board.

**Move a card between columns (single-select field):**

```bash
gh api graphql -f query='mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_...",
    itemId: "PVTI_...",
    fieldId: "PVTSSF_...",
    value: { singleSelectOptionId: "..." }
  }) { projectV2Item { id } }
}'
```

GitHub Projects can auto-move cards when a linked PR opens or merges — configure that in the project's Workflows settings rather than scripting it. Manual moves are for the cases automation does not cover (non-closing PRs, status changes without a PR).

**Clear a single-select field (e.g. move a card back to the "no status" column / Backlog):**

```bash
gh api graphql -f query='mutation {
  clearProjectV2ItemFieldValue(input: {
    projectId: "PVT_...",
    itemId: "PVTI_...",
    fieldId: "PVTSSF_..."
  }) { projectV2Item { id } }
}'
```

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
