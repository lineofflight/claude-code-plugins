# rem-sleep v0.5: Memory Architecture Upgrade

## Background

This plan comes from a deep-dive comparison of the rem-sleep plugin against Claude Code's new auto memory system shipped with Opus 4.6 / Claude Code v2.1.32 (February 5, 2026). The goal was to understand what rem-sleep does well, where auto memory has advantages, and how to evolve rem-sleep to be complementary rather than redundant.

## Context: What Auto Memory Is

Claude Code v2.1.32 introduced built-in persistent memory. Key properties:

- **Storage**: `~/.claude/projects/<project-hash>/memory/MEMORY.md` — user-scoped, outside the repo
- **Mechanism**: Claude writes notes to MEMORY.md inline during conversation. The file is injected into the system prompt every session (truncated at ~200 lines).
- **Lifecycle**: Manual. Claude is told to "update or remove memories that turn out to be wrong" but nothing enforces this.
- **What it captures**: High-level project context — "this project uses monorepo", "user prefers TypeScript". It's a curated notepad under a tight line budget. Operational details (workarounds, gotchas, exact API patterns) get dropped in favor of bigger-picture notes.

Separately, Anthropic shipped an API-level memory tool (`memory_20250818`) for developers building agentic apps. This gives Claude CRUD operations on a `/memories` directory. Not directly relevant to plugins — it's an API feature, not a Claude Code feature — but it signals Anthropic's direction: file-based memory, no vector DB, no embeddings.

## Context: What rem-sleep Does Today

A two-phase system modeled on biological sleep consolidation:

### Phase 1: Encode (hooks/encode)
- **Triggers**: PreCompact (before context compaction) and SessionEnd (on clear)
- **Mechanism**: Spawns a Sonnet subprocess (`claude --print --dangerously-skip-permissions --model sonnet`) that receives hook metadata via `$ARGUMENTS`, including `transcript_path`. The subprocess reads the session transcript JSONL and extracts patterns across 9 categories: debugging insights, tool failures, framework workarounds, undocumented gotchas, codebase conventions, user preferences, brand voice, effective approaches, architectural decisions.
- **Output**: Appends structured markdown entries to `.claude/rem/patterns/{domain}.md`

### Phase 2: Consolidate (hooks/consolidate)
- **Trigger**: Stop hook, gated by ~5% random chance (`RANDOM % 20`)
- **Mechanism**: Spawns Claude to scan all pattern files, find recurring learnings (3+ occurrences), crystallize them into `.claude/skills/{domain}/` or project `CLAUDE.md`, and prune stale entries (>30 days old)
- **Output**: Durable project skills + pruned pattern files

### Current pattern format
```markdown
### YYYY-MM-DD: Title

- **Observation**: What was learned
- **Details**: Specific details about the pattern
- **Context**: When/where this pattern applies
```

## Key Findings from Comparison

### Where rem-sleep wins
1. **No context tax** — patterns don't consume system prompt tokens until they graduate to skills. Auto memory burns ~200 lines every turn.
2. **Domain partitioning** — `rails.md`, `python.md` vs a single MEMORY.md junk drawer.
3. **Automated lifecycle** — 30-day pruning + 3-occurrence crystallization. Auto memory has no expiry.
4. **Team-shareable output** — crystallized skills live in the repo.
5. **Separation of concerns** — encoding subprocess doesn't distract the main model.
6. **Operational depth** — the transcript is a gold mine of workarounds, gotchas, and conventions that auto memory's 200-line notepad doesn't have room for. This is rem-sleep's core value proposition.

### Where auto memory wins
1. **Zero setup** — works out of the box.
2. **Real-time** — captures knowledge the moment it's learned, not just at session boundaries.
3. **Read-before-act** — system prompt explicitly says "check your memories before starting." rem-sleep patterns are invisible until consolidation.
4. **User-scoped storage** — lives in `~/.claude/`, doesn't pollute the project directory.

## Detailed Feature Plan

### 1. Read-before-act

**Problem**: Patterns sit in `.claude/rem/patterns/` (or new user-scoped location) and are never consulted. Knowledge encoded in the previous session is invisible to the current session until consolidation promotes it to a skill. There's a blind window between encoding and crystallization.

**Solution**: Surface recent patterns at session start. Options:
- A skill instruction that tells Claude to check the patterns directory when starting unfamiliar work
- A SessionStart hook that injects a brief summary of recent patterns
- A lightweight index file that lists recent pattern titles (cheaper than loading all pattern content)

**Design consideration**: Don't load all pattern files into context — that defeats the "no context tax" advantage. A title-level index or a "last 5 entries" summary is the right granularity.

### 2. Real-time capture (low-frequency encode on Stop)

**Problem**: Encode only fires on PreCompact and SessionEnd. If a session dies mid-conversation (crash, timeout, network drop), all learnings from that session are lost.

**Solution**: Add a low-frequency encode on the Stop hook, similar to how consolidation uses a random gate. Something like 10% chance on Stop. This provides opportunistic mid-session encoding without the overhead of encoding after every response.

**Implementation**: Add a new Stop hook entry in hooks.json with its own random gate. Can reuse the same encode script — just add a `[ $((RANDOM % 10)) -eq 0 ] || exit 0` gate at the top of a wrapper, or add a second Stop entry alongside consolidate.

**Consideration**: The Stop hook already runs consolidate at 5%. Adding encode at 10% means ~15% of responses trigger a background subprocess. Both are async so they don't block the user, but monitor resource usage.

### 3. Contradiction detection

**Problem**: A pattern encoded incorrectly persists for 30 days. There's no mechanism for correcting wrong patterns — only age-based expiry.

**Solution**: During encoding, the subprocess should check existing patterns in the same domain and flag contradictions. If the current transcript shows that a previously encoded pattern was wrong (e.g., "actually, `includes(:commentable)` doesn't work — you need `preload`"), the encode hook should update or remove the old entry.

**Implementation**: Pass the relevant domain's existing patterns into the encode prompt so the subprocess can cross-reference. Add an instruction like: "If the transcript contradicts an existing pattern, update or remove the stale entry."

### 4. Transcript as primary source

**Not a feature — a design principle.** The conversation transcript contains operational knowledge that auto memory's 200-line notepad drops. This is rem-sleep's core differentiator. Do not try to read from MEMORY.md as an encoding shortcut. The transcript is the gold mine; MEMORY.md is the gift shop summary.

The encode hook's targeted 9-category extraction prompt is specifically designed to pull out the stuff auto memory misses: workarounds, gotchas, failure modes, conventions.

### 5. Write consolidated skills back to MEMORY.md

**Problem**: Auto memory and rem-sleep are siloed. Skills crystallized by rem-sleep don't appear in MEMORY.md, so Claude's built-in memory system doesn't benefit from consolidation.

**Solution**: When consolidation promotes patterns to skills, also write a one-liner summary to MEMORY.md. This gives the auto memory system access to crystallized knowledge without the user maintaining it manually.

**Implementation**: The consolidate hook already writes to `.claude/skills/` and `CLAUDE.md`. Add MEMORY.md (`~/.claude/projects/<hash>/memory/MEMORY.md`) as an additional write target. Keep entries minimal — just a reference line, not a full copy of the skill.

**Consideration**: Need to discover the correct MEMORY.md path. This depends on how Claude Code hashes the project path.

### 6. Deduplicate MEMORY.md

**Problem**: Over time, MEMORY.md accumulates entries that are now redundant with crystallized skills. Under the 200-line truncation limit, these redundant entries displace useful content.

**Solution**: During consolidation, scan MEMORY.md for entries that are covered by existing skills and remove them.

**Implementation**: Add to the consolidate prompt: "Check MEMORY.md for entries that duplicate knowledge now in .claude/skills/. Remove redundant entries." The subprocess has tool access and can edit the file.

**Consideration**: This is a write to a file outside the project directory. Make sure the subprocess can access `~/.claude/projects/...`. Since it runs with `--dangerously-skip-permissions`, filesystem access shouldn't be an issue.

### 7. YAML frontmatter on pattern entries

**Problem**: The consolidate hook spawns a full Claude call to do mechanical work (counting occurrences, checking dates) that unix tools could handle. It also can't bail early when there's nothing worth consolidating.

**Solution**: Add YAML frontmatter to each pattern entry:

```markdown
---
domain: rails
date: 2026-02-02
tags: [activerecord, n+1, polymorphic]
---
### ActiveRecord includes with polymorphic associations
- **Observation**: N+1 queries persist despite using includes
- **Details**: Use `includes(:commentable)` with explicit polymorphic type
- **Context**: Polymorphic belongs_to with eager loading
```

**Benefits**:
- Consolidate hook can count entries and bail early (skip model call if < 3 entries in any domain)
- Date-based pruning can be done with grep/awk before the model call
- Tag frequency analysis pre-filters candidates for the model
- The model call focuses on semantic grouping (its actual strength) rather than counting and date math

**Implementation**: Update the encode prompt to emit frontmatter. Update the consolidate script to do mechanical pre-filtering before the Claude call. The Claude call receives only the pre-filtered candidates, not all patterns.

### 8. Skills cite source observations

**Problem**: No traceability from crystallized skills back to the observations that produced them.

**Solution**: Skills should include a comment citing their source observations:

```markdown
<!-- .claude/skills/rails/eager-loading.md -->
<!-- consolidated from: rails.md 2026-02-02, 2026-02-04, 2026-02-05 -->
```

**Why one-directional**: Patterns are ephemeral (pruned after 30 days or after consolidation). Backlinks on patterns pointing to skills would be deleted along with the patterns. The durable artifact is the skill, so that's where provenance lives.

**Implementation**: Update the consolidate prompt to include source dates when writing skill files.

### 9. Patterns move to user scope

**Problem**: Patterns currently live at `.claude/rem/patterns/` inside the project directory. This requires gitignoring, risks accidental commits, and means all team members share the same pattern pool despite having different experiences.

**Solution**: Move patterns to user-scoped storage: `~/.claude/rem/patterns/<project-identifier>/`

**Rationale**: Patterns are personal working memory — they reflect what *you* struggled with. Two developers hitting different bugs should build different pattern sets. This mirrors auto memory's user-scoped storage at `~/.claude/projects/...`.

**The flow becomes**:
```
~/.claude/rem/patterns/<project-id>/rails.md    (personal, ephemeral)
        │ consolidate
        ▼
.claude/skills/rails/eager-loading.md           (shared, durable)
```

User-scoped input, project-scoped output.

**Implementation**:
- Use a hash of the project root path as `<project-id>` (consistent with how Claude Code identifies projects)
- Update encode hook to write to `~/.claude/rem/patterns/<project-id>/`
- Update consolidate hook to read from new location, write skills to project directory
- Remove `.claude/rem/` from project gitignore (no longer needed)
- Consider matching Claude Code's own project hashing scheme for consistency

### Project identifier

For the project identifier in user-scoped paths, use a SHA-256 hash of the absolute project root path, truncated to the first 16 hex characters. This matches the convention used by Claude Code for `~/.claude/projects/`. The encode and consolidate hooks can compute it as:

```bash
PROJECT_ID=$(echo -n "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" | sha256sum | cut -c1-16)
PATTERNS_DIR="$HOME/.claude/rem/patterns/$PROJECT_ID"
```

### 10. Consolidation placement guidance: universal vs domain

**Problem**: The consolidate prompt says "crystallize into `.claude/skills/{domain}/` or CLAUDE.md" but gives no guidance on when to choose which. The model makes ad-hoc decisions about where knowledge lands.

**Solution**: Add explicit placement criteria to the consolidate prompt. The axis is **frequency of relevance**, not project vs user:

- **CLAUDE.md** — Universal rules. Knowledge needed on virtually every task regardless of what files are being touched. Style conventions, return type patterns, error handling policy, project structure norms, naming conventions.
- **Skills** — Domain knowledge. Knowledge relevant only when working in a specific area. Framework workarounds, library gotchas, API-specific patterns, tooling quirks.

Both categories can be project-specific. "Always return Result types" is project-specific *and* universal (every service object, every task). "Polymorphic eager loading needs explicit type" is project-specific *and* domain (only when touching ActiveRecord polymorphic associations).

**Why this matters**: CLAUDE.md is loaded every session, every turn. It's expensive context. Only truly universal rules should live there. Domain knowledge in skills is loaded on demand — it doesn't burn tokens when you're not working in that area.

**Implementation**: Update the consolidate prompt with explicit criteria:
```
When placing consolidated knowledge:
- CLAUDE.md: Rules that apply to EVERY task in this codebase (style, conventions,
  return types, error handling, project structure). These burn context tokens every
  turn — only universal rules justify that cost.
- .claude/skills/{domain}/: Knowledge for a specific area (framework workarounds,
  library gotchas, API patterns). Loaded on demand, not always.
```

## Implementation Order

Suggested priority based on impact and dependency:

1. **Item 9** (user-scoped patterns) — architectural change, do first so other features build on the right path
2. **Item 7** (YAML frontmatter) — changes the pattern format, must happen before features that parse patterns
3. **Item 8** (source citations on skills) — small change to consolidate prompt
4. **Item 2** (real-time capture on Stop) — new hook entry, straightforward
5. **Item 1** (read-before-act) — depends on final pattern location (item 9)
6. **Item 3** (contradiction detection) — enhancement to encode prompt
7. **Item 5** (write to MEMORY.md) — depends on discovering MEMORY.md path
8. **Item 6** (deduplicate MEMORY.md) — depends on item 5

## Version

This plan targets rem-sleep v0.5.0 (minor version bump — new features, no breaking changes to skill output format). Bump in plugin.json when implementation begins.

## Files to Modify

- `plugins/rem-sleep/.claude-plugin/plugin.json` — version bump
- `plugins/rem-sleep/hooks/hooks.json` — add Stop encode hook entry
- `plugins/rem-sleep/hooks/encode` — user-scoped paths, frontmatter format, contradiction detection, optional MEMORY.md write
- `plugins/rem-sleep/hooks/consolidate` — user-scoped pattern reads, pre-filtering with frontmatter, source citations, MEMORY.md dedup
- `plugins/rem-sleep/README.md` — updated docs
