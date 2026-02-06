# Google Drive Management

Use `gog drive` commands to manage Google Drive files and folders.

## Common Commands

### List and Search Files

```bash
# List files in root
gog drive list

# List files in specific folder
gog drive list --parent <folder-id>

# Search by name
gog drive search "name contains 'report'"

# Search by type
gog drive search "mimeType = 'application/pdf'"

# Search in folder
gog drive search "name contains 'invoice'" --parent <folder-id>

# Show detailed info with JSON
gog drive list --json
```

### Upload Files

```bash
# Upload file to root
gog drive upload /path/to/file.pdf

# Upload to specific folder
gog drive upload /path/to/file.pdf --parent <folder-id>

# Upload with custom name
gog drive upload /path/to/file.pdf --name "Custom Name.pdf"

# Upload and convert to Google format
gog drive upload document.docx --convert
```

### Download Files

```bash
# Download file
gog drive download <file-id>

# Download to specific location
gog drive download <file-id> --output /path/to/destination.pdf

# Export Google Doc/Sheet/Slides
gog drive export <file-id> --mime-type application/pdf --output doc.pdf
```

### Manage Files and Folders

```bash
# Create folder
gog drive mkdir "New Folder"

# Create folder in parent
gog drive mkdir "Subfolder" --parent <parent-folder-id>

# Move file
gog drive move <file-id> --parent <new-parent-id>

# Rename file
gog drive rename <file-id> "New Name.pdf"

# Copy file
gog drive copy <file-id> --name "Copy of File.pdf"

# Delete file (move to trash)
gog drive trash <file-id>

# Permanently delete
gog drive delete <file-id>

# Restore from trash
gog drive restore <file-id>
```

### File Sharing and Permissions

```bash
# Share file with specific user
gog drive share <file-id> \
  --email "user@example.com" \
  --role writer

# Share with link (anyone with link can view)
gog drive share <file-id> --anyone --role reader

# List permissions
gog drive permissions <file-id>

# Remove permission
gog drive permission <file-id> <permission-id> delete
```

## Common MIME Types

**Google Workspace:**
- Google Doc: `application/vnd.google-apps.document`
- Google Sheet: `application/vnd.google-apps.spreadsheet`
- Google Slides: `application/vnd.google-apps.presentation`
- Google Folder: `application/vnd.google-apps.folder`

**Standard formats:**
- PDF: `application/pdf`
- Word: `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- Excel: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- PowerPoint: `application/vnd.openxmlformats-officedocument.presentationml.presentation`
- Text: `text/plain`
- Image (JPEG): `image/jpeg`
- Image (PNG): `image/png`

## Search Query Syntax

Drive supports powerful search queries:

**By name:**
- `name = 'exact name'`
- `name contains 'partial'`

**By type:**
- `mimeType = 'application/pdf'`
- `mimeType contains 'image/'`

**By date:**
- `modifiedTime > '2026-01-01T00:00:00'`
- `createdTime < '2025-12-31T23:59:59'`

**By owner/sharing:**
- `'user@example.com' in owners`
- `'user@example.com' in writers`
- `sharedWithMe = true`

**By status:**
- `trashed = false`
- `starred = true`

**Combine queries with `and`:**
- `name contains 'report' and mimeType = 'application/pdf'`

## Permission Roles

- `owner` - Full control
- `writer` - Can edit and share
- `commenter` - Can comment but not edit
- `reader` - View only

## Tips

- File and folder IDs are returned in list/search operations
- Use `--parent <folder-id>` to work within specific folders
- `--convert` flag converts MS Office files to Google Workspace format on upload
- Export Google Docs/Sheets/Slides to standard formats (PDF, DOCX, XLSX, PPTX)
- Use `--json` for programmatic access
- Trash operations are reversible; permanent delete is not
- Share with `--anyone` for public links, or `--email` for specific users
- Search is fast and supports complex queries

## Workflow Examples

**Upload project files:**
1. Create project folder
2. Upload files to that folder
3. Share folder with team members

**Find and download document:**
1. Search by name or type
2. Get file ID from results
3. Download or export to desired format

**Organize files:**
1. Create folder structure
2. Search for files to organize
3. Move files to appropriate folders

**Share document with team:**
1. Find file by name
2. Share with team members' emails
3. Set appropriate permissions (reader/writer)

**Clean up old files:**
1. Search by date (e.g., modified > 6 months ago)
2. Review results
3. Trash or delete unnecessary files
