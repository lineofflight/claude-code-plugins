# Claude Code Plugins

## Plugin Authoring

- When editing a plugin, bump the patch version in `plugin.json`
- When creating a new plugin, add it to `.claude-plugin/marketplace.json` and the marketplace `README.md`

## Plugin Structure

```
plugins/<name>/
  .claude-plugin/
    plugin.json          # name, version, description
  hooks/
    hooks.json           # hook definitions
    *.sh                 # hook scripts
  skills/
    <skill-name>/
      SKILL.md           # skill definition (frontmatter + content)
  CLAUDE.md              # dev notes
  README.md
```

- Skills go at the **plugin root** (`skills/`), NOT inside `.claude-plugin/`
- Each skill is a subdirectory with a `SKILL.md` file
- `SKILL.md` must have frontmatter: `name`, `description`, `user_invocable: true`

## Reference

- [Headless](https://code.claude.com/docs/en/headless) — Running Claude Code in CI/scripts
- [Hooks](https://code.claude.com/docs/en/hooks) — Hook events and configuration
- [Hooks guide](https://code.claude.com/docs/en/hooks-guide) — Practical hook examples
- [MCP](https://code.claude.com/docs/en/mcp) — Model Context Protocol servers
- [Plugins](https://code.claude.com/docs/en/plugins) — Creating and distributing plugins
