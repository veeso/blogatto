---
layout: default
title: Error handling
nav_order: 11
---

# Error handling

All Blogatto build functions return `Result(Nil, BlogattoError)`. The library never panics — every failure is surfaced as a `Result`.

## BlogattoError variants

| Variant | Payload | Description |
|---------|---------|-------------|
| `File(FileError)` | `simplifile.FileError` | File system error (reading, writing, deleting files or directories) |
| `InvalidUri(String)` | The invalid URI string | A URI could not be parsed during URL resolution |
| `FrontmatterMissing` | — | A markdown file has no frontmatter block |
| `FrontmatterMissingField(String)` | Field name | A required frontmatter field (`title`, `date`, or `description`) is missing |
| `FrontmatterInvalidDate(String)` | The date string | The `date` field could not be parsed as `YYYY-MM-DD HH:MM:SS` |
| `FrontmatterInvalidLine(String)` | The line content | A frontmatter line could not be parsed as a `key: value` pair |

## Handling errors

### Basic pattern

```gleam
import blogatto
import blogatto/error
import gleam/io

case blogatto.build(cfg) {
  Ok(Nil) -> io.println("Site built successfully!")
  Error(err) -> {
    io.println("Build failed: " <> error.describe_error(err))
    // Exit with error code, log to monitoring, etc.
  }
}
```

### Matching specific errors

```gleam
import blogatto
import blogatto/error
import gleam/io

case blogatto.build(cfg) {
  Ok(Nil) -> io.println("Done!")
  Error(error.FrontmatterMissingField(field)) ->
    io.println("A post is missing the '" <> field <> "' field in its frontmatter")
  Error(error.FrontmatterInvalidDate(date)) ->
    io.println("Invalid date format: '" <> date <> "'. Use YYYY-MM-DD HH:MM:SS")
  Error(error.FrontmatterMissing) ->
    io.println("A markdown file is missing its frontmatter block")
  Error(err) ->
    io.println("Build failed: " <> error.describe_error(err))
}
```

## describe_error

The `error.describe_error(error)` function converts any `BlogattoError` into a human-readable string:

```gleam
import blogatto/error

error.describe_error(error.FrontmatterMissingField("title"))
// -> "Frontmatter missing required field: title"

error.describe_error(error.FrontmatterInvalidDate("not-a-date"))
// -> "Frontmatter has invalid date format: not-a-date"

error.describe_error(error.InvalidUri(":::bad"))
// -> "Invalid URI: :::bad"
```

## Common issues

### Missing frontmatter

Every markdown file must start with a `---` delimited frontmatter block. Files without frontmatter produce `FrontmatterMissing`.

**Fix:** Add frontmatter to the top of the file:

```markdown
---
title: My Post
date: 2025-01-15 00:00:00
description: A short description
---
```

### Invalid date format

The `date` field must follow `YYYY-MM-DD HH:MM:SS` format exactly.

**Valid:** `2025-01-15 00:00:00`

**Invalid:** `2025-01-15`, `Jan 15, 2025`, `2025/01/15 00:00:00`

### File permission errors

`File(Eacces)` indicates a permissions issue reading source files or writing to the output directory.

**Fix:** Ensure the output directory's parent is writable and source files are readable.
