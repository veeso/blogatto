//// Djot rendering for the post builder.
////
//// Parses djot content via the `jot` library and renders it to Lustre
//// elements via the user's `Components`. Mirrors the markdown renderer's
//// approach so other source formats can be added as sibling submodules.

import blogatto/config/post.{type Components, type PostConfig}
import frontmatter as fm_extractor
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import jot
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}

/// Short file extension recognized by the djot source format.
pub const extension_short = "dj"

/// Long file extension recognized by the djot source format.
pub const extension_long = "djot"

type Context(msg) {
  Context(
    components: Components(msg),
    references: Dict(String, String),
    footnote_numbers: Dict(String, Int),
  )
}

/// Render djot `content` to Lustre elements using the post configuration.
///
/// Frontmatter (a leading `---`-delimited block) is stripped before parsing
/// so jot does not treat it as a thematic break followed by paragraphs;
/// frontmatter is parsed separately by the post builder.
pub fn render(config: PostConfig(msg), content: String) -> List(Element(msg)) {
  let body = fm_extractor.extract(content).content
  let document = jot.parse(body)
  let context =
    Context(
      components: config.components,
      references: document.references,
      footnote_numbers: build_footnote_numbers(document.footnotes),
    )
  list.map(document.content, render_container(_, context, jot.Loose))
}

/// Assign a stable footnote number to each footnote reference in the
/// document, sorted by reference key for deterministic output.
fn build_footnote_numbers(
  footnotes: Dict(String, List(jot.Container)),
) -> Dict(String, Int) {
  footnotes
  |> dict.keys
  |> list.sort(string.compare)
  |> list.index_map(fn(key, index) { #(key, index + 1) })
  |> dict.from_list
}

/// Render a single djot block container into a Lustre element using the
/// component functions from `Components(msg)`. The `layout` argument tracks
/// the current list packing so paragraphs inside a tight list can be
/// rendered without a `<p>` wrapper.
fn render_container(
  container: jot.Container,
  ctx: Context(msg),
  layout: jot.ListLayout,
) -> Element(msg) {
  case container {
    jot.ThematicBreak -> ctx.components.hr()

    jot.Paragraph(attributes: _, content: inlines) -> {
      let children = render_inlines(inlines, ctx)
      case layout {
        jot.Tight -> element.fragment(children)
        jot.Loose -> ctx.components.p(children)
      }
    }

    jot.Heading(attributes: attrs, level: level, content: inlines) -> {
      let id = attrs |> dict.get("id") |> result.unwrap("")
      render_heading(level, id, render_inlines(inlines, ctx), ctx.components)
    }

    jot.Codeblock(attributes: _, language: language, content: text) ->
      ctx.components.pre([
        ctx.components.code(language, [element.text(text)]),
      ])

    jot.RawBlock(content: content) ->
      element.unsafe_raw_html("", "div", [], content)

    jot.BulletList(layout: list_layout, style: _, items: items) ->
      items
      |> list.map(render_list_item(_, list_layout, ctx))
      |> ctx.components.ul

    jot.OrderedList(
      layout: list_layout,
      punctuation: _,
      ordinal: _,
      start: start,
      items: items,
    ) -> {
      let start_attr = case start {
        1 -> None
        n -> Some(n)
      }
      items
      |> list.map(render_list_item(_, list_layout, ctx))
      |> ctx.components.ol(start_attr, _)
    }

    jot.BlockQuote(attributes: _, items: items) ->
      items
      |> list.map(render_container(_, ctx, jot.Loose))
      |> ctx.components.blockquote

    jot.Div(class: _, attributes: attrs, items: items) ->
      element.element(
        "div",
        dict_to_attributes(attrs),
        list.map(items, render_container(_, ctx, jot.Loose)),
      )
  }
}

fn render_heading(
  level: Int,
  id: String,
  children: List(Element(msg)),
  components: Components(msg),
) -> Element(msg) {
  case level {
    1 -> components.h1(id, children)
    2 -> components.h2(id, children)
    3 -> components.h3(id, children)
    4 -> components.h4(id, children)
    5 -> components.h5(id, children)
    _ -> components.h6(id, children)
  }
}

/// Render a single list item. For tight lists, paragraph children are
/// unwrapped to their inline content so no `<p>` markers appear inside the
/// `<li>`, matching the djot rendering convention.
fn render_list_item(
  item: List(jot.Container),
  layout: jot.ListLayout,
  ctx: Context(msg),
) -> Element(msg) {
  item
  |> list.flat_map(fn(container) {
    case layout, container {
      jot.Tight, jot.Paragraph(content: inlines, ..) ->
        render_inlines(inlines, ctx)
      _, _ -> [render_container(container, ctx, layout)]
    }
  })
  |> ctx.components.li
}

fn render_inlines(
  inlines: List(jot.Inline),
  ctx: Context(msg),
) -> List(Element(msg)) {
  list.map(inlines, render_inline(_, ctx))
}

fn render_inline(inline: jot.Inline, ctx: Context(msg)) -> Element(msg) {
  case inline {
    jot.Linebreak -> element.element("br", [], [])
    // U+00A0 NO-BREAK SPACE
    jot.NonBreakingSpace -> element.text("\u{00a0}")
    jot.Text(text) -> element.text(text)
    jot.Link(attributes: attrs, content: text, destination: destination) -> {
      let href = destination_to_url(destination, ctx.references)
      let title = attrs |> dict.get("title") |> option.from_result
      ctx.components.a(href, title, render_inlines(text, ctx))
    }
    jot.Image(attributes: attrs, content: text, destination: destination) -> {
      let uri = destination_to_url(destination, ctx.references)
      let alt = inlines_to_text(text)
      let title = attrs |> dict.get("title") |> option.from_result
      ctx.components.img(uri, alt, title)
    }
    jot.Span(attributes: attrs, content: inlines) ->
      element.element(
        "span",
        dict_to_attributes(attrs),
        render_inlines(inlines, ctx),
      )
    jot.Emphasis(content: inlines) ->
      ctx.components.em(render_inlines(inlines, ctx))
    jot.Strong(content: inlines) ->
      ctx.components.strong(render_inlines(inlines, ctx))
    jot.Delete(content: inlines) ->
      ctx.components.del(render_inlines(inlines, ctx))
    // No `ins` component is exposed by `Components`, so fall back to a raw
    // `<ins>` element preserving the inline children.
    jot.Insert(content: inlines) ->
      element.element("ins", [], render_inlines(inlines, ctx))
    jot.Mark(content: inlines) ->
      ctx.components.mark(render_inlines(inlines, ctx))
    // No `sup`/`sub` components are exposed by `Components`, so fall back to
    // raw `<sup>`/`<sub>` elements preserving the inline children.
    jot.Superscript(content: inlines) ->
      element.element("sup", [], render_inlines(inlines, ctx))
    jot.Subscript(content: inlines) ->
      element.element("sub", [], render_inlines(inlines, ctx))
    jot.Footnote(reference: reference) -> {
      let number =
        ctx.footnote_numbers
        |> dict.get(reference)
        |> result.unwrap(0)
      ctx.components.footnote(number, [element.text(reference)])
    }
    jot.Code(content: text) -> ctx.components.code(None, [element.text(text)])
    jot.MathInline(content: latex) ->
      element.element("span", [attribute.class("math inline")], [
        element.text("\\(" <> latex <> "\\)"),
      ])
    jot.MathDisplay(content: latex) ->
      element.element("span", [attribute.class("math display")], [
        element.text("\\[" <> latex <> "\\]"),
      ])
    jot.Symbol(content: content) ->
      element.element("span", [attribute.class("symbol")], [
        element.text(content),
      ])
  }
}

/// Resolve a djot destination to a URL string. Reference destinations are
/// looked up in the document's reference table; missing references resolve
/// to an empty string, matching jot's HTML rendering behavior.
fn destination_to_url(
  destination: jot.Destination,
  references: Dict(String, String),
) -> String {
  case destination {
    jot.Url(url) -> url
    jot.Reference(name) -> references |> dict.get(name) |> result.unwrap("")
  }
}

fn dict_to_attributes(attrs: Dict(String, String)) -> List(Attribute(msg)) {
  attrs
  |> dict.to_list
  |> list.map(fn(pair) { attribute.attribute(pair.0, pair.1) })
}

/// Extract plain text from a list of inlines, used for image alt text.
fn inlines_to_text(inlines: List(jot.Inline)) -> String {
  inlines
  |> list.map(fn(inline) {
    case inline {
      jot.Text(text) -> text
      jot.Code(text) -> text
      jot.Symbol(text) -> text
      jot.Emphasis(content: inner) -> inlines_to_text(inner)
      jot.Strong(content: inner) -> inlines_to_text(inner)
      jot.Delete(content: inner) -> inlines_to_text(inner)
      jot.Insert(content: inner) -> inlines_to_text(inner)
      jot.Mark(content: inner) -> inlines_to_text(inner)
      jot.Span(content: inner, ..) -> inlines_to_text(inner)
      jot.Link(content: inner, ..) -> inlines_to_text(inner)
      jot.Image(content: inner, ..) -> inlines_to_text(inner)
      jot.NonBreakingSpace -> " "
      jot.Linebreak -> " "
      _ -> ""
    }
  })
  |> string.concat
}
