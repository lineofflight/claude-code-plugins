# Google Workspace Documents

Use `gog` commands to work with Google Sheets, Docs, and Slides.

## Google Sheets

### Read Data

```bash
# Read entire sheet
gog sheets <spreadsheet-id> read

# Read specific range
gog sheets <spreadsheet-id> read "Sheet1!A1:D10"

# Read with JSON output
gog sheets <spreadsheet-id> read --json

# List all sheets in spreadsheet
gog sheets <spreadsheet-id> list
```

### Write Data

```bash
# Write to range
gog sheets <spreadsheet-id> write "Sheet1!A1" \
  --values "[[\"Name\",\"Email\"],[\"John\",\"john@example.com\"]]"

# Append row
gog sheets <spreadsheet-id> append "Sheet1!A1" \
  --values "[[\"New\",\"Row\"]]"

# Clear range
gog sheets <spreadsheet-id> clear "Sheet1!A1:D10"
```

### Create and Format

```bash
# Create new spreadsheet
gog sheets create "Spreadsheet Name"

# Add sheet
gog sheets <spreadsheet-id> add-sheet "New Sheet"

# Format cells
gog sheets <spreadsheet-id> format "Sheet1!A1:A10" \
  --bold \
  --background-color "#FFFF00"

# Update cell properties
gog sheets <spreadsheet-id> update "Sheet1!A1" \
  --number-format "0.00"
```

## Google Docs

### Read Content

```bash
# Read document content
gog docs <document-id> read

# Export to different format
gog docs <document-id> export --format pdf --output document.pdf
gog docs <document-id> export --format docx --output document.docx
```

### Create and Edit

```bash
# Create new document
gog docs create "Document Title"

# Insert text at end
gog docs <document-id> append "New paragraph text"

# Replace text
gog docs <document-id> replace "old text" "new text"
```

## Google Slides

### Read Presentations

```bash
# Get presentation info
gog slides <presentation-id> info

# Read slide content
gog slides <presentation-id> read

# Export to PDF
gog slides <presentation-id> export --format pdf --output slides.pdf

# Export to PPTX
gog slides <presentation-id> export --format pptx --output slides.pptx
```

### Create and Edit

```bash
# Create new presentation
gog slides create "Presentation Title"

# Add slide
gog slides <presentation-id> add-slide

# Update slide content
gog slides <presentation-id> update-slide <slide-id> \
  --title "Slide Title" \
  --body "Slide content"
```

## Document IDs

Document IDs are found in URLs:

- **Sheets**: `https://docs.google.com/spreadsheets/d/{SPREADSHEET_ID}/edit`
- **Docs**: `https://docs.google.com/document/d/{DOCUMENT_ID}/edit`
- **Slides**: `https://docs.google.com/presentation/d/{PRESENTATION_ID}/edit`

Or search using Drive commands:
```bash
gog drive search "name = 'Document Name'"
```

## Sheets Cell References

Use A1 notation for ranges:
- Single cell: `A1`
- Range: `A1:D10`
- Entire row: `1:1`
- Entire column: `A:A`
- Named sheet: `Sheet1!A1:D10`

## Export Formats

**Sheets:**
- `xlsx` - Microsoft Excel
- `pdf` - PDF
- `csv` - CSV (first sheet only)
- `tsv` - TSV

**Docs:**
- `docx` - Microsoft Word
- `pdf` - PDF
- `txt` - Plain text
- `html` - HTML

**Slides:**
- `pptx` - Microsoft PowerPoint
- `pdf` - PDF
- `png` - PNG images (one per slide)

## Tips

- Use `--json` for structured output when parsing data
- Sheet data is in 2D array format: `[["row1col1", "row1col2"], ["row2col1", "row2col2"]]`
- For complex sheet operations, read data, process locally, then write back
- Export to standard formats (PDF, DOCX, XLSX) for sharing
- Document IDs work across Drive and document-specific commands
- Create documents with descriptive names for easy retrieval
- Use Drive commands to organize and share Workspace documents

## Workflow Examples

**Create and populate spreadsheet:**
1. Create new spreadsheet with descriptive name
2. Write headers to first row
3. Append data rows
4. Format as needed

**Extract data from spreadsheet:**
1. Get spreadsheet ID from Drive or URL
2. Read specific range or entire sheet
3. Parse JSON output for analysis
4. Process data as needed

**Generate report:**
1. Read data from spreadsheet
2. Create new doc or slides
3. Insert processed data/charts
4. Export to PDF for distribution

**Update existing document:**
1. Read current content
2. Make modifications (append, replace)
3. Verify changes
4. Share updated version

**Batch export documents:**
1. Search for documents by type
2. Export each to desired format
3. Save to local directory
4. Archive or distribute as needed
