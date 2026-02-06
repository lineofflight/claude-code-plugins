# Gmail Management

Use `gog gmail` commands to manage Gmail messages, drafts, and labels.

## Common Commands

### Search and List Messages

```bash
# Search for messages (uses Gmail query syntax)
gog gmail search "from:example@email.com"
gog gmail search "subject:invoice after:2026/01/01"
gog gmail search "has:attachment is:unread"

# List recent threads
gog gmail threads

# Show specific thread
gog gmail thread <thread-id>

# Show specific message
gog gmail message <message-id>
```

### Send Email

```bash
# Send simple email
gog gmail send \
  --to "recipient@example.com" \
  --subject "Subject line" \
  --body "Email content"

# Send with CC and BCC
gog gmail send \
  --to "recipient@example.com" \
  --cc "cc@example.com" \
  --bcc "bcc@example.com" \
  --subject "Subject" \
  --body "Content"

# Send HTML email
gog gmail send \
  --to "recipient@example.com" \
  --subject "HTML Email" \
  --html "<h1>Hello</h1><p>This is HTML</p>"

# Send with attachment
gog gmail send \
  --to "recipient@example.com" \
  --subject "With attachment" \
  --body "See attached file" \
  --attach "/path/to/file.pdf"

# Reply to message
gog gmail send \
  --to "recipient@example.com" \
  --subject "Re: Original subject" \
  --body "Reply content" \
  --in-reply-to "<message-id>"
```

### Manage Drafts

```bash
# List drafts
gog gmail drafts

# Create draft
gog gmail draft create \
  --to "recipient@example.com" \
  --subject "Draft subject" \
  --body "Draft content"

# Send draft
gog gmail draft send <draft-id>

# Delete draft
gog gmail draft delete <draft-id>
```

### Manage Labels

```bash
# List labels
gog gmail labels

# Create label
gog gmail label create "Work/Projects"

# Add label to message
gog gmail message <message-id> add-label <label-id>

# Remove label from message
gog gmail message <message-id> remove-label <label-id>
```

### Manage Messages

```bash
# Mark as read
gog gmail message <message-id> mark-read

# Mark as unread
gog gmail message <message-id> mark-unread

# Archive message
gog gmail message <message-id> archive

# Trash message
gog gmail message <message-id> trash

# Delete permanently
gog gmail message <message-id> delete
```

## Gmail Query Syntax

Search messages using Gmail's powerful query operators:

**From/To/Subject:**
- `from:user@example.com` - from specific sender
- `to:user@example.com` - to specific recipient
- `subject:keyword` - subject contains keyword

**Date ranges:**
- `after:2026/01/01` - after date
- `before:2026/12/31` - before date
- `newer_than:7d` - last 7 days
- `older_than:1m` - older than 1 month

**Attachments and labels:**
- `has:attachment` - has attachments
- `filename:pdf` - specific file type
- `label:important` - has label
- `is:unread` - unread messages
- `is:starred` - starred messages

**Combine queries:**
- `from:boss@company.com is:unread` - unread from boss
- `subject:invoice after:2026/01/01 has:attachment` - invoices with attachments

## Tips

- Use `--json` flag for structured output when parsing programmatically
- Message and thread IDs are returned in list/search results
- Always quote multi-word queries: `"subject:my project"`
- For bulk operations, first search to get IDs, then act on each
- Draft IDs are needed to send or delete drafts
- Use `--html` for formatted emails, `--body` for plain text
- Attachments are specified with `--attach` (can use multiple times)

## Workflow Examples

**Send project update:**
1. Compose email with clear subject and body
2. Include relevant attachments if needed
3. Use CC for stakeholders who need visibility

**Find and respond to urgent messages:**
1. Search for unread messages from specific sender
2. Read message content
3. Compose and send reply

**Clean up inbox:**
1. Search for old messages by date
2. Review results
3. Archive or trash as needed
