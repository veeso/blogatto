//// Internal frontmatter parser for YAML-like `key: value` format.
////
//// Provides two entry points: `parse_content` extracts the frontmatter
//// block from a full markdown document (between `---` delimiters) using
//// the `frontmatter` package, then parses the key-value pairs; `parse`
//// operates on already-extracted raw frontmatter text. Empty lines and
//// comment lines (starting with `#`) are skipped. Each non-skipped line
//// must contain a `:` separator; lines without one produce an error.

import blogatto/error
import frontmatter as fm_extractor
import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/result
import gleam/string

/// Extract and parse frontmatter from full markdown content.
///
/// Uses the `frontmatter` package to locate the block between `---`
/// delimiters, then parses the extracted text into key-value pairs.
/// Returns `FrontmatterMissing` when the document has no frontmatter block.
///
/// ## Examples
///
/// ```gleam
/// parse_content("---\ntitle: Hello\n---\n# Body")
/// // -> Ok(dict.from_list([#("title", "Hello")]))
/// ```
pub fn parse_content(
  content: String,
) -> Result(Dict(String, String), error.BlogattoError) {
  let extracted = fm_extractor.extract(content)
  case extracted.frontmatter {
    option.Some(raw_fm) -> parse(raw_fm)
    option.None -> Error(error.FrontmatterMissing)
  }
}

/// Parse raw frontmatter text into a dictionary of key-value pairs.
///
/// Lines are split on the first `:` character; the key and value are both
/// trimmed of surrounding whitespace. Empty lines and lines starting with
/// `#` are ignored. Lines that contain no `:` produce a
/// `FrontmatterInvalidLine` error.
///
/// ## Examples
///
/// ```gleam
/// parse("title: Hello\ndescription: A post")
/// // -> Ok(dict.from_list([#("title", "Hello"), #("description", "A post")]))
/// ```
pub fn parse(raw: String) -> Result(Dict(String, String), error.BlogattoError) {
  raw
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.filter(fn(line) { line != "" && !string.starts_with(line, "#") })
  |> list.try_fold(dict.new(), fn(acc, line) {
    use #(key, value) <- result.try(parse_line(line))
    Ok(dict.insert(acc, key, value))
  })
}

/// Parse a single frontmatter line into a key-value tuple.
fn parse_line(line: String) -> Result(#(String, String), error.BlogattoError) {
  case string.split_once(line, ":") {
    Ok(#(key, value)) -> Ok(#(string.trim(key), string.trim(value)))
    Error(Nil) -> Error(error.FrontmatterInvalidLine(line))
  }
}
