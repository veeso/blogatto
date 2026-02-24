import blogatto/error
import gleam/string
import gleeunit/should
import simplifile

pub fn describe_file_error_test() {
  error.File(simplifile.Enoent)
  |> error.describe_error()
  |> string.contains("File error")
  |> should.be_true
}

pub fn describe_invalid_uri_error_test() {
  error.InvalidUri("not a uri")
  |> error.describe_error()
  |> should.equal("Invalid URI: not a uri")
}

pub fn describe_frontmatter_missing_field_error_test() {
  error.FrontmatterMissingField("title")
  |> error.describe_error()
  |> should.equal("Frontmatter missing required field: title")
}

pub fn describe_frontmatter_invalid_date_error_test() {
  error.FrontmatterInvalidDate("not-a-date")
  |> error.describe_error()
  |> should.equal("Frontmatter has invalid date format: not-a-date")
}

pub fn describe_frontmatter_invalid_line_error_test() {
  error.FrontmatterInvalidLine("bad line")
  |> error.describe_error()
  |> should.equal("Frontmatter contains invalid line: bad line")
}

pub fn describe_frontmatter_missing_error_test() {
  error.FrontmatterMissing
  |> error.describe_error()
  |> should.equal("Markdown file is missing frontmatter")
}
