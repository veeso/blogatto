//// Internal module for extracting plain-text excerpts from rendered
//// Lustre elements.

import gleam/list
import gleam/string
import lustre/element

/// Extract a plain-text excerpt from rendered Lustre elements.
/// Renders to HTML, strips tags, collapses whitespace, and truncates
/// to at most `max_len` characters on a word boundary.
pub fn extract(elements: List(element.Element(msg)), max_len: Int) -> String {
  elements
  |> list.map(element.to_string)
  |> string.join("")
  // Slice HTML conservatively before stripping — tags add roughly 3x overhead.
  |> string.slice(0, max_len * 3)
  |> strip_html_tags()
  |> collapse_whitespace()
  |> string.trim()
  |> truncate_at_word_boundary(max_len)
}

/// Truncate a string to at most `max_len` characters without breaking words.
/// If the text exceeds `max_len`, it is cut back to the last space boundary.
/// When no space exists (single long word), the text is returned as-is up to
/// `max_len` characters.
pub fn truncate_at_word_boundary(text: String, max_len: Int) -> String {
  case string.length(text) <= max_len {
    True -> text
    False -> {
      let sliced = string.slice(text, 0, max_len)
      // Check whether the cut falls on a word boundary.
      let next_char = string.slice(text, max_len, 1)
      case next_char == " " || next_char == "" {
        // Already at a word boundary.
        True -> string.trim_end(sliced)
        // Mid-word — back up to the last space.
        False -> {
          case string.split(sliced, " ") {
            // Single word with no spaces — keep the slice as-is.
            [_single] -> sliced
            parts -> {
              parts
              |> list.take(list.length(parts) - 1)
              |> string.join(" ")
              |> string.trim_end()
            }
          }
        }
      }
    }
  }
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
