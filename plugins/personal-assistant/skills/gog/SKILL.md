---
name: gog
description: Interact with Google services (Gmail, Calendar, Tasks, Contacts, Drive, Sheets, Docs, Slides) via gog CLI
compatibility: Requires gog CLI
---

# Google Services via gog

Use the `gog` command-line tool to manage Google services.

## Available Services

Detailed documentation for each service:

- **[calendar.md](calendar.md)** - Schedule events, check availability, manage invitations
- **[gmail.md](gmail.md)** - Send emails, search messages, manage labels and drafts
- **[tasks.md](tasks.md)** - Create and manage task lists and individual tasks
- **[contacts.md](contacts.md)** - Search, create, and update contacts and groups
- **[drive.md](drive.md)** - Upload, download, search, and organize files and folders
- **[workspace.md](workspace.md)** - Work with Google Sheets, Docs, and Slides

## Quick Start

All commands follow the pattern:

```bash
gog <service> <command> [flags]
```

Common flags:
- `--json` - Output as JSON for scripting
- `--help` - Show command help

Examples:
```bash
# List calendar events
gog calendar events

# Send an email
gog gmail send --to "user@example.com" --subject "Hello" --body "Message"

# Create a task
gog tasks list <list-id> task create --title "Buy groceries"

# Search Drive
gog drive search "name contains 'report'"
```

Refer to the service-specific documentation files for detailed usage, patterns, and examples.
