import simplifile

/// Blogatto build errors.
pub type BlogattoError {
  /// File system errors, such as issues with reading/writing files or directories.
  File(simplifile.FileError)
}

/// Convert an error into a human-readable description.
pub fn describe_error(error: BlogattoError) -> String {
  case error {
    File(file_error) -> "File error: " <> simplifile.describe_error(file_error)
  }
}
