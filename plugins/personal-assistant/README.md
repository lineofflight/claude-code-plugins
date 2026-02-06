# Personal Assistant

Personal productivity assistant for managing emails, calendars, tasks, contacts, and files across different services.

## Features

### Google Services (via gog CLI)

Comprehensive integration with Google services:
- **Gmail** - Send emails, search messages, manage labels and drafts
- **Calendar** - Schedule events, check availability, manage invitations
- **Tasks** - Create and manage task lists and individual tasks
- **Contacts** - Search, create, and update contacts and groups
- **Drive** - Upload, download, search, and organize files and folders
- **Workspace** - Work with Google Sheets, Docs, and Slides

Additional services and tools can be added to this plugin in the future.

## Requirements

### gog CLI

The Google services integration requires [gog](https://github.com/steipete/gogcli) to be installed and configured.

#### Installation

Install gog using Homebrew:

```bash
brew install steipete/tap/gog
```

Or download from [releases](https://github.com/steipete/gogcli/releases).

#### Configuration

Before using the gog skill, authenticate with Google:

```bash
# Authenticate with your Google account
gog auth login

# Verify authentication
gog calendar calendars
```

See the [gog documentation](https://github.com/steipete/gogcli#setup) for detailed setup instructions.

## Usage

### Google Services

Just ask Claude naturally - it will automatically use the gog skill when you need to interact with Google services:

**Examples:**
- "Schedule a meeting for tomorrow at 2pm"
- "Send an email to john@example.com about the project"
- "What's on my calendar this week?"
- "Add 'Buy groceries' to my tasks"
- "Search my drive for reports from last month"

Claude will automatically reference the appropriate service documentation (calendar, gmail, tasks, etc.) and execute the gog commands for you.

### Future Skills

Additional skills for other services (Outlook, Apple Calendar, etc.) can be added to this plugin as needed.
