# Calendar Management

Use `gog calendar` commands to manage Google Calendar events.

## Common Commands

### List Events

```bash
# List upcoming events
gog calendar events

# List events for specific date range
gog calendar events --from "2026-02-10T00:00:00Z" --to "2026-02-17T23:59:59Z"

# List events from all calendars
gog calendar events --all

# Show events as JSON for parsing
gog calendar events --json
```

### Create Events

```bash
# Create an event with location
gog calendar create primary \
  --summary "Event title" \
  --from "2026-02-10T14:00:00+01:00" \
  --to "2026-02-10T15:00:00+01:00" \
  --location "Address or URL"

# All-day event
gog calendar create primary \
  --summary "All day event" \
  --from "2026-02-15" \
  --to "2026-02-16" \
  --all-day

# Event with attendees and description
gog calendar create primary \
  --summary "Team meeting" \
  --from "2026-02-12T10:00:00+01:00" \
  --to "2026-02-12T11:00:00+01:00" \
  --attendees "email1@example.com,email2@example.com" \
  --description "Meeting agenda and notes"

# Event with Google Meet
gog calendar create primary \
  --summary "Video call" \
  --from "2026-02-13T15:00:00+01:00" \
  --to "2026-02-13T16:00:00+01:00" \
  --with-meet
```

### Update Events

```bash
# Update event time
gog calendar update primary <event-id> \
  --from "2026-02-10T15:00:00+01:00" \
  --to "2026-02-10T16:00:00+01:00"

# Update event details
gog calendar update primary <event-id> \
  --summary "Updated title" \
  --location "New location"
```

### Get Event Details

```bash
# Get specific event
gog calendar event primary <event-id>
```

### List Calendars

```bash
# Show all available calendars
gog calendar calendars
```

## Date and Time Formats

**RFC3339 format** (required for date-times):
- With timezone: `2026-02-10T14:00:00+01:00`
- UTC: `2026-02-10T14:00:00Z`
- Date only (for all-day): `2026-02-15`

**Common timezones:**
- Europe/Amsterdam: `+01:00` (CET) or `+02:00` (CEST in summer)
- US Eastern: `-05:00` (EST) or `-04:00` (EDT in summer)
- US Pacific: `-08:00` (PST) or `-07:00` (PDT in summer)
- UTC: `Z`

## Tips

- Use `primary` as the calendar ID for the user's main calendar
- Event IDs are returned when creating events and can be used for updates
- When updating events, only specify the fields you want to change
- For recurring events, use `--rrule` (e.g., `RRULE:FREQ=WEEKLY;BYDAY=MO`)
- Parse JSON output (`--json`) for scripting and automation
- Check `gog calendar create --help` for all available options

## Workflow Examples

**Schedule appointment:**
1. List existing events to check for conflicts
2. Create event with appropriate details
3. Confirm creation by showing event link

**Reschedule:**
1. Get event details to verify current time
2. Update with new time
3. Confirm the change

**Check availability:**
1. List events for specific date range
2. Analyze gaps in schedule
3. Suggest available time slots
