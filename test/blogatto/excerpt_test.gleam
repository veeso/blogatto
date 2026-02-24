import blogatto/internal/excerpt
import gleam/string
import gleeunit/should
import lustre/element
import lustre/element/html

// --- Basic text extraction ---

pub fn extract_from_single_text_element_test() {
  let elements = [element.text("Hello world")]

  excerpt.extract(elements, 200)
  |> should.equal("Hello world")
}

pub fn extract_from_paragraph_test() {
  let elements = [html.p([], [element.text("Hello world")])]

  excerpt.extract(elements, 200)
  |> should.equal("Hello world")
}

pub fn extract_from_nested_elements_test() {
  let elements = [
    html.div([], [
      html.p([], [element.text("First paragraph.")]),
      html.p([], [element.text("Second paragraph.")]),
    ]),
  ]

  let result = excerpt.extract(elements, 200)
  result |> string.contains("First paragraph.") |> should.be_true
  result |> string.contains("Second paragraph.") |> should.be_true
}

pub fn extract_strips_inline_tags_test() {
  let elements = [
    html.p([], [
      element.text("Hello "),
      html.strong([], [element.text("bold")]),
      element.text(" world"),
    ]),
  ]

  excerpt.extract(elements, 200)
  |> should.equal("Hello bold world")
}

pub fn extract_from_multiple_elements_test() {
  let elements = [
    html.h1([], [element.text("Title")]),
    html.p([], [element.text("Body text here.")]),
  ]

  let result = excerpt.extract(elements, 200)
  result |> string.contains("Title") |> should.be_true
  result |> string.contains("Body text here.") |> should.be_true
}

// --- Whitespace collapsing ---

pub fn extract_collapses_multiple_spaces_test() {
  let elements = [element.text("hello    world")]

  excerpt.extract(elements, 200)
  |> should.equal("hello world")
}

pub fn extract_collapses_newlines_to_spaces_test() {
  let elements = [element.text("hello\n\nworld")]

  excerpt.extract(elements, 200)
  |> should.equal("hello world")
}

pub fn extract_collapses_tabs_test() {
  let elements = [element.text("hello\t\tworld")]

  excerpt.extract(elements, 200)
  |> should.equal("hello world")
}

pub fn extract_collapses_mixed_whitespace_test() {
  let elements = [element.text("hello \n \t \r world")]

  excerpt.extract(elements, 200)
  |> should.equal("hello world")
}

pub fn extract_trims_leading_and_trailing_whitespace_test() {
  let elements = [
    html.p([], [element.text("  hello world  ")]),
  ]

  excerpt.extract(elements, 200)
  |> should.equal("hello world")
}

// --- Truncation ---

pub fn extract_truncates_to_max_len_test() {
  let elements = [element.text("abcdefghij")]

  excerpt.extract(elements, 5)
  |> should.equal("abcde")
}

pub fn extract_returns_full_text_when_shorter_than_max_len_test() {
  let elements = [element.text("short")]

  excerpt.extract(elements, 200)
  |> should.equal("short")
}

pub fn extract_truncates_after_stripping_tags_test() {
  let elements = [
    html.p([], [element.text("abcdefghijklmnop")]),
  ]

  excerpt.extract(elements, 10)
  |> should.equal("abcdefghij")
}

pub fn extract_with_zero_max_len_returns_empty_test() {
  let elements = [element.text("hello")]

  excerpt.extract(elements, 0)
  |> should.equal("")
}

// --- Edge cases ---

pub fn extract_from_empty_list_test() {
  excerpt.extract([], 200)
  |> should.equal("")
}

pub fn extract_from_element_with_no_text_test() {
  let elements = [html.div([], [])]

  excerpt.extract(elements, 200)
  |> should.equal("")
}

pub fn extract_preserves_unicode_characters_test() {
  let elements = [element.text("caf\u{00E9} r\u{00E9}sum\u{00E9}")]

  excerpt.extract(elements, 200)
  |> should.equal("caf\u{00E9} r\u{00E9}sum\u{00E9}")
}

pub fn extract_keeps_html_entities_as_is_test() {
  // Lustre escapes & to &amp; in HTML output, so it remains escaped
  let elements = [element.text("A & B")]

  excerpt.extract(elements, 200)
  |> should.equal("A &amp; B")
}

pub fn extract_handles_angle_brackets_in_text_test() {
  // Lustre escapes < and > in text nodes as &lt; and &gt;
  let elements = [element.text("a < b > c")]

  let result = excerpt.extract(elements, 200)
  result |> string.contains("a") |> should.be_true
  result |> string.contains("b") |> should.be_true
  result |> string.contains("c") |> should.be_true
}

pub fn extract_deeply_nested_elements_test() {
  let elements = [
    html.div([], [
      html.div([], [
        html.div([], [
          html.span([], [element.text("deep")]),
        ]),
      ]),
    ]),
  ]

  excerpt.extract(elements, 200)
  |> should.equal("deep")
}

pub fn extract_long_content_only_processes_needed_portion_test() {
  // Build a long text and verify truncation works correctly
  let long_text = string.repeat("word ", 1000)
  let elements = [element.text(long_text)]

  let result = excerpt.extract(elements, 20)
  string.length(result) |> should.equal(20)
}
