# Tasks Management

Use `gog tasks` commands to manage Google Tasks lists and individual tasks.

## Common Commands

### Manage Task Lists

```bash
# List all task lists
gog tasks lists

# Create new task list
gog tasks list create "Work Projects"

# Get specific task list
gog tasks list <list-id>

# Update task list name
gog tasks list <list-id> update --title "Updated Name"

# Delete task list
gog tasks list <list-id> delete
```

### Manage Tasks

```bash
# List tasks in a list
gog tasks list <list-id> tasks

# List tasks in default list
gog tasks

# Create task
gog tasks list <list-id> task create \
  --title "Task title" \
  --notes "Additional details" \
  --due "2026-02-15T00:00:00Z"

# Create task with quick syntax
gog tasks list <list-id> task create --title "Buy groceries"

# Update task
gog tasks list <list-id> task <task-id> update \
  --title "Updated title" \
  --notes "Updated notes" \
  --due "2026-02-20T00:00:00Z"

# Complete task
gog tasks list <list-id> task <task-id> complete

# Uncomplete task
gog tasks list <list-id> task <task-id> uncomplete

# Delete task
gog tasks list <list-id> task <task-id> delete
```

### Subtasks

```bash
# Create subtask (child task)
gog tasks list <list-id> task create \
  --title "Subtask title" \
  --parent <parent-task-id>

# List tasks shows hierarchy automatically
gog tasks list <list-id> tasks
```

### Move Tasks

```bash
# Move task to different position
gog tasks list <list-id> task <task-id> move \
  --previous <previous-task-id>

# Move to top of list
gog tasks list <list-id> task <task-id> move
```

## Date Formats

Due dates use RFC3339 format:
- `2026-02-15T00:00:00Z` - specific date (midnight UTC)
- `2026-02-15T14:00:00Z` - specific date and time

For all-day tasks, use midnight UTC: `2026-02-15T00:00:00Z`

## Tips

- List IDs are required for most operations - get them with `gog tasks lists`
- Task IDs are returned when creating/listing tasks
- Use `--json` for programmatic access to task data
- Completed tasks remain in the list unless deleted
- Tasks support notes for additional context
- Due dates are optional but help with organization
- Subtasks create hierarchy for complex projects
- Move operations let you reorder tasks within a list

## Workflow Examples

**Create daily task list:**
1. Create or select appropriate task list
2. Add tasks with titles and due dates
3. Use subtasks for multi-step items

**Review and complete tasks:**
1. List tasks to see what's pending
2. Complete finished tasks
3. Update or reschedule remaining items

**Organize project:**
1. Create dedicated task list for project
2. Add main tasks
3. Break down complex tasks into subtasks
4. Set due dates for milestones

**Clean up old tasks:**
1. List completed tasks
2. Review what can be deleted
3. Delete or archive as needed
