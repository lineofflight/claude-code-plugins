# Contacts Management

Use `gog contacts` commands to manage Google Contacts.

## Common Commands

### Search and List Contacts

```bash
# List all contacts
gog contacts list

# Search contacts by name
gog contacts search "John Smith"

# Search by email
gog contacts search "email@example.com"

# Search by phone
gog contacts search "+1234567890"

# Get specific contact
gog contacts get <contact-id>

# Show as JSON
gog contacts list --json
```

### Create Contact

```bash
# Create contact with basic info
gog contacts create \
  --given-name "John" \
  --family-name "Smith" \
  --email "john.smith@example.com" \
  --phone "+1-555-0123"

# Create with company info
gog contacts create \
  --given-name "Jane" \
  --family-name "Doe" \
  --email "jane.doe@company.com" \
  --phone "+1-555-0456" \
  --organization "Acme Corp" \
  --job-title "Software Engineer"

# Create with address
gog contacts create \
  --given-name "Bob" \
  --family-name "Johnson" \
  --email "bob@example.com" \
  --address "123 Main St, City, State 12345"

# Create with multiple emails/phones
gog contacts create \
  --given-name "Alice" \
  --family-name "Williams" \
  --email "alice.personal@gmail.com" \
  --email "alice.work@company.com" \
  --phone "+1-555-1111" \
  --phone "+1-555-2222"
```

### Update Contact

```bash
# Update contact details
gog contacts update <contact-id> \
  --email "new.email@example.com" \
  --phone "+1-555-9999"

# Update name
gog contacts update <contact-id> \
  --given-name "NewFirstName" \
  --family-name "NewLastName"

# Update organization
gog contacts update <contact-id> \
  --organization "New Company" \
  --job-title "New Title"
```

### Delete Contact

```bash
# Delete contact
gog contacts delete <contact-id>
```

### Contact Groups

```bash
# List contact groups
gog contacts groups

# Create group
gog contacts group create "Family"

# Add contact to group
gog contacts group <group-id> add <contact-id>

# Remove contact from group
gog contacts group <group-id> remove <contact-id>

# Delete group
gog contacts group <group-id> delete
```

## Contact Fields

Common fields when creating/updating contacts:

**Name:**
- `--given-name` - First name
- `--family-name` - Last name
- `--middle-name` - Middle name
- `--nickname` - Nickname

**Contact info:**
- `--email` - Email address (can repeat)
- `--phone` - Phone number (can repeat)
- `--address` - Physical address

**Organization:**
- `--organization` - Company name
- `--job-title` - Job title
- `--department` - Department

**Other:**
- `--birthday` - Birthday (YYYY-MM-DD)
- `--notes` - Additional notes
- `--website` - Website URL

## Tips

- Search is flexible - matches names, emails, phones, and organizations
- Contact IDs are returned when creating/listing contacts
- Multiple emails and phones can be added by repeating the flag
- Use `--json` for structured output when parsing programmatically
- Groups help organize contacts into categories
- Updates only modify specified fields, leaving others unchanged
- Phone numbers can be in any format but international format (+1-555-...) is recommended

## Workflow Examples

**Add new business contact:**
1. Create contact with name, email, company, and title
2. Add to relevant group (e.g., "Clients" or "Vendors")
3. Add notes with context about how you met

**Find contact information:**
1. Search by name or partial email
2. Get full contact details
3. Use information for email or calendar invite

**Update contact after job change:**
1. Search for contact by name
2. Update organization and job title
3. Add new work email if provided

**Organize contacts:**
1. Create groups for different categories
2. Add contacts to appropriate groups
3. Use groups for easier filtering and bulk operations
