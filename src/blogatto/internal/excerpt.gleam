//// Internal module for extracting plain-text excerpts from rendered
//// Lustre elements.

import gleam/list
import gleam/string
import lustre/element

/// Extract a plain-text excerpt from rendered Lustre elements.
/// Renders to HTML, strips tags, collapses whitespace, and truncates
/// to `max_len` characters.
pub fn extract(elements: List(element.Element(msg)), max_len: Int) -> String {
  elements
  |> list.map(element.to_string)
  |> string.join("")
  // Slice HTML conservatively before stripping — tags add roughly 3x overhead.
  |> string.slice(0, max_len * 3)
  |> strip_html_tags()
  |> collapse_whitespace()
  |> string.trim()
  |> string.slice(0, max_len)
}

/// Remove HTML tags from a string, keeping only text content.
fn strip_html_tags(html: String) -> String {
  do_strip_tags(string.to_graphemes(html), False, "")
}

fn do_strip_tags(graphemes: List(String), in_tag: Bool, acc: String) -> String {
  case graphemes {
    [] -> acc
    ["<", ..rest] -> do_strip_tags(rest, True, acc)
    [">", ..rest] -> do_strip_tags(rest, False, acc)
    [char, ..rest] ->
      case in_tag {
        True -> do_strip_tags(rest, True, acc)
        False -> do_strip_tags(rest, False, acc <> char)
      }
  }
}

/// Collapse runs of whitespace (spaces, newlines, tabs) into single spaces.
fn collapse_whitespace(text: String) -> String {
  do_collapse_whitespace(string.to_graphemes(text), False, "")
}

fn do_collapse_whitespace(
  graphemes: List(String),
  prev_ws: Bool,
  acc: String,
) -> String {
  case graphemes {
    [] -> acc
    [char, ..rest] ->
      case char == " " || char == "\n" || char == "\t" || char == "\r" {
        True ->
          case prev_ws {
            True -> do_collapse_whitespace(rest, True, acc)
            False -> do_collapse_whitespace(rest, True, acc <> " ")
          }
        False -> do_collapse_whitespace(rest, False, acc <> char)
      }
  }
}
