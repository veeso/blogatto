//// Shared footnote markup helpers for the post renderers.
////
//// Both the markdown and djot renderers emit the footnote definitions as a
//// `<section class="footnotes"><ol>` of anchored `<li id="fn-N">` items, each
//// ending with a back-link to its reference site. Keeping the markup here
//// guarantees both source formats produce the same structure.

import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}

/// Wrap the rendered footnote definition `items` in a `<section><ol>`. Returns
/// an empty list when there are no footnotes, so callers can append it
/// unconditionally.
pub fn section(items: List(Element(msg))) -> List(Element(msg)) {
  case items {
    [] -> []
    _ -> [
      element.element("section", [attribute.class("footnotes")], [
        element.element("ol", [], items),
      ]),
    ]
  }
}

/// Render a single footnote definition as an `<li id="fn-N">` containing the
/// already-rendered definition `body` followed by a back-link to its reference
/// site (`#fnref-N`).
pub fn item(number: Int, body: List(Element(msg))) -> Element(msg) {
  let num = int.to_string(number)
  let backlink =
    element.element(
      "a",
      [attribute.href("#fnref-" <> num), attribute.class("footnote-backref")],
      [element.text("↩")],
    )
  element.element(
    "li",
    [attribute.id("fn-" <> num)],
    list.append(body, [backlink]),
  )
}
