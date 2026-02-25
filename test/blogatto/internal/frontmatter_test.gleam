import blogatto/error
import blogatto/internal/frontmatter
import gleam/dict
import gleeunit/should

pub fn parse_valid_frontmatter_test() {
  "title: Hello World\ndescription: A first post\ndate: 2024-01-15"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([
      #("title", "Hello World"),
      #("description", "A first post"),
      #("date", "2024-01-15"),
    ]),
  )
}

pub fn parse_skips_empty_lines_test() {
  "title: Hello\n\ndescription: World"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([#("title", "Hello"), #("description", "World")]),
  )
}

pub fn parse_skips_comment_lines_test() {
  "# This is a comment\ntitle: Hello\n# Another comment\ndate: 2024-01-15"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([#("title", "Hello"), #("date", "2024-01-15")]),
  )
}

pub fn parse_trims_whitespace_test() {
  "  title  :  Hello World  \n  description  :  A post  "
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([#("title", "Hello World"), #("description", "A post")]),
  )
}

pub fn parse_value_containing_colon_test() {
  "title: Hello: World: Foo"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(dict.from_list([#("title", "Hello: World: Foo")]))
}

pub fn parse_returns_error_on_malformed_line_test() {
  "title: Hello\nthis has no separator"
  |> frontmatter.parse()
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidLine("this has no separator"))
}

pub fn parse_empty_string_returns_empty_dict_test() {
  ""
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(dict.new())
}

pub fn parse_only_comments_returns_empty_dict_test() {
  "# comment one\n# comment two"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(dict.new())
}

pub fn parse_windows_line_endings_test() {
  "title: Hello\r\ndescription: World"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([#("title", "Hello"), #("description", "World")]),
  )
}

// --- parse_content tests ---

pub fn parse_content_extracts_frontmatter_from_markdown_test() {
  "---\ntitle: Hello\ndescription: World\n---\n# Heading\n"
  |> frontmatter.parse_content()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([#("title", "Hello"), #("description", "World")]),
  )
}

pub fn parse_content_returns_error_when_no_frontmatter_test() {
  "# Just a heading\n\nNo frontmatter here.\n"
  |> frontmatter.parse_content()
  |> should.be_error()
  |> should.equal(error.FrontmatterMissing)
}

pub fn parse_strips_double_quotes_from_values_test() {
  "title: \"Hello World\"\ndescription: \"A first post\""
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([
      #("title", "Hello World"),
      #("description", "A first post"),
    ]),
  )
}

pub fn parse_strips_single_quotes_from_values_test() {
  "title: 'Hello World'\ndescription: 'A first post'"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(
    dict.from_list([
      #("title", "Hello World"),
      #("description", "A first post"),
    ]),
  )
}

pub fn parse_keeps_mismatched_quotes_test() {
  "title: \"Hello World'"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(dict.from_list([#("title", "\"Hello World'")]))
}

pub fn parse_keeps_value_with_only_opening_quote_test() {
  "title: \"Hello World"
  |> frontmatter.parse()
  |> should.be_ok()
  |> should.equal(dict.from_list([#("title", "\"Hello World")]))
}

pub fn parse_content_handles_empty_frontmatter_block_test() {
  "---\n---\n# Body\n"
  |> frontmatter.parse_content()
  |> should.be_ok()
  |> should.equal(dict.new())
}

pub fn parse_content_ignores_body_after_frontmatter_test() {
  "---\ntitle: Test\n---\nThis line: has a colon but is body\n"
  |> frontmatter.parse_content()
  |> should.be_ok()
  |> should.equal(dict.from_list([#("title", "Test")]))
}
