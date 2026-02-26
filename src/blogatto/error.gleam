//// Error types for the blogatto build pipeline.
////
//// All functions in the library that can fail return
//// `Result(a, BlogattoError)`. Use `describe_error` to obtain a
//// human-readable description.

import simplifile

/// Blogatto build errors.
pub type BlogattoError {
  /// File system errors, such as issues with reading/writing files or directories.
  File(simplifile.FileError)
  /// Invalid URI encountered during URL resolution.
  InvalidUri(String)
  /// Missing required field in frontmatter
  FrontmatterMissingField(String)
  /// Invalid date format in frontmatter
  FrontmatterInvalidDate(String)
  /// A frontmatter line could not be parsed as a `key: value` pair.
  FrontmatterInvalidLine(String)
  /// Missing Frontmatter
  FrontmatterMissing
  /// Dev server error
  DevServer(String)
}

/// Convert an error into a human-readable description.
pub fn describe_error(error: BlogattoError) -> String {
  case error {
    File(file_error) -> "File error: " <> simplifile.describe_error(file_error)
    InvalidUri(uri) -> "Invalid URI: " <> uri
    FrontmatterMissingField(field) ->
      "Frontmatter missing required field: " <> field
    FrontmatterInvalidDate(date) ->
      "Frontmatter has invalid date format: " <> date
    FrontmatterInvalidLine(line) ->
      "Frontmatter contains invalid line: " <> line
    FrontmatterMissing -> "Markdown file is missing frontmatter"
    DevServer(msg) -> "Development server error: " <> msg
  }
}
