import blogatto/config/post as post_cfg
import blogatto/internal/builder/post/markdown
import gleam/string
import gleeunit/should
import lustre/element

fn render(content: String) -> String {
  let config = post_cfg.default()
  markdown.render(config, content)
  |> element.fragment
  |> element.to_string
}

// --- footnotes ---

pub fn footnote_definition_content_is_rendered_test() {
  let html = render("Body[^a].\n\n[^a]: A footnote.\n")
  html |> string.contains("A footnote.") |> should.be_true
}

pub fn footnote_marker_shows_number_test() {
  let html = render("Body[^note].\n\n[^note]: A footnote.\n")
  html |> string.contains(">1</a>") |> should.be_true
}

pub fn footnote_marker_links_to_definition_test() {
  let html = render("Body[^a].\n\n[^a]: A footnote.\n")
  // Marker is a clickable link to the definition.
  html |> string.contains("href=\"#fn-1\"") |> should.be_true
  // Definition is anchored so the marker can jump to it.
  html |> string.contains("id=\"fn-1\"") |> should.be_true
  // Definition links back to the marker.
  html |> string.contains("href=\"#fnref-1\"") |> should.be_true
  html |> string.contains("id=\"fnref-1\"") |> should.be_true
}

pub fn footnotes_numbered_sequentially_test() {
  let html = render("One[^a] two[^b].\n\n[^a]: Alpha.\n\n[^b]: Bravo.\n")
  let assert Ok(one_index) = string.split_once(html, ">1</a>")
  let assert Ok(two_index) = string.split_once(html, ">2</a>")
  // Marker "1" must appear before marker "2" in document order.
  { string.length(one_index.0) < string.length(two_index.0) }
  |> should.be_true
}

pub fn footnote_definition_links_back_to_correct_marker_test() {
  let html = render("One[^a] two[^b].\n\n[^a]: Alpha.\n\n[^b]: Bravo.\n")
  // Definition 1 is anchored as fn-1 and holds the first footnote body.
  let assert Ok(#(_, after_fn1)) = string.split_once(html, "id=\"fn-1\"")
  after_fn1 |> string.contains("Alpha.") |> should.be_true
}
