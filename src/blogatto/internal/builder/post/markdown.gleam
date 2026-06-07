//// Markdown rendering for the post builder.
////
//// Parses markdown content via mork using the configured `Options`, and
//// renders it to Lustre elements via the user's `Components`. When syntax
//// highlighting is configured, code blocks are tokenized via smalto and
//// rendered as styled spans.
////
//// The post builder delegates the markdown half of its work here so other
//// source formats (e.g. djot) can be added as sibling submodules.

import blogatto/config/post.{type PostConfig}
import blogatto/config/post/code
import blogatto/internal/builder/post/footnote
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string
import lustre/element.{type Element}
import maud
import maud/components as maud_components
import mork
import mork/document as mork_document

/// File extension recognized by the markdown source format.
pub const extension: String = "md"

/// Render markdown `content` to Lustre elements using the post configuration.
///
/// The document body is rendered first, then the footnote definitions are
/// rendered separately into an anchored `<section><ol>` (with back-links) so
/// footnotes are navigable, matching the djot renderer. maud's own footnote
/// append (bare paragraphs, no anchors) is bypassed by clearing the
/// document's footnotes before rendering the body.
pub fn render(config: PostConfig(msg), content: String) -> List(Element(msg)) {
  let components = to_maud_components(config)
  let document =
    mork.parse_with_options(
      options: mork_options(config.options),
      input: content,
    )
  let body =
    maud.render_document(
      mork_document.Document(..document, footnotes: dict.new()),
      components,
    )
  list.append(body, render_footnotes(document, components))
}

/// Render the markdown footnote definitions into an anchored `<section><ol>`,
/// ordered by footnote number. Each definition's blocks are rendered through
/// maud so they share the configured components.
fn render_footnotes(
  document: mork_document.Document,
  components: maud_components.Components(msg),
) -> List(Element(msg)) {
  document.footnotes
  |> dict.values
  |> list.sort(fn(a, b) { int.compare(a.num, b.num) })
  |> list.map(fn(data) {
    let body =
      maud.render_document(
        mork_document.Document(
          ..document,
          blocks: data.blocks,
          footnotes: dict.new(),
        ),
        components,
      )
    footnote.item(data.num, body)
  })
  |> footnote.section
}

/// Convert blogatto `Components` to maud `Components`, wrapping the `code`
/// component with syntax highlighting when configured.
fn to_maud_components(
  config: PostConfig(msg),
) -> maud_components.Components(msg) {
  let c = config.components
  maud_components.Components(
    a: c.a,
    blockquote: c.blockquote,
    checkbox: c.checkbox,
    code: code_component(config.syntax_highlighting, c.code),
    del: c.del,
    em: c.em,
    footnote: c.footnote,
    h1: c.h1,
    h2: c.h2,
    h3: c.h3,
    h4: c.h4,
    h5: c.h5,
    h6: c.h6,
    hr: c.hr,
    img: c.img,
    li: c.li,
    mark: c.mark,
    ol: c.ol,
    p: c.p,
    pre: c.pre,
    strong: c.strong,
    table: c.table,
    tbody: c.tbody,
    td: fn(alignment, children) {
      c.td(from_maud_alignment(alignment), children)
    },
    th: fn(alignment, children) {
      c.th(from_maud_alignment(alignment), children)
    },
    thead: c.thead,
    tr: c.tr,
    ul: c.ul,
  )
}

/// Wrap the user's `code` component with syntax highlighting. When highlighting
/// is configured and a matching language grammar is found, the code block's
/// text content is tokenized via smalto and rendered as highlighted Lustre
/// elements. Otherwise, the original code component is used as-is.
fn code_component(
  syntax_highlighting: Option(code.SyntaxHighlightingConfig(msg)),
  code_fn: fn(dict.Dict(String, String), Option(String), List(Element(msg))) ->
    Element(msg),
) -> fn(dict.Dict(String, String), Option(String), List(Element(msg))) ->
  Element(msg) {
  case syntax_highlighting {
    option.None -> code_fn
    option.Some(config) -> {
      fn(
        attributes: dict.Dict(String, String),
        language: Option(String),
        children: List(Element(msg)),
      ) -> Element(msg) {
        case language {
          option.Some(lang) -> {
            // Extract raw text from children and unescape HTML entities,
            // since element.to_string HTML-escapes text content.
            // Each child is converted individually to avoid fragment
            // comment markers that element.fragment adds.
            let source =
              children
              |> list.map(element.to_string)
              |> string.join("")
              |> unescape_html()
            case code.highlight(config, lang, source) {
              Ok(highlighted) -> code_fn(attributes, language, highlighted)
              Error(_) -> code_fn(attributes, language, children)
            }
          }
          option.None -> code_fn(attributes, language, children)
        }
      }
    }
  }
}

/// Unescape HTML entities in a string. Used to recover raw source code from
/// Lustre text elements which HTML-escape their content via houdini.
/// The `&amp;` entity must be unescaped last to avoid double-unescaping
/// sequences like `&amp;lt;`.
fn unescape_html(html: String) -> String {
  html
  |> string.replace("&lt;", "<")
  |> string.replace("&gt;", ">")
  |> string.replace("&quot;", "\"")
  |> string.replace("&#39;", "'")
  |> string.replace("&amp;", "&")
}

fn from_maud_alignment(alignment: maud_components.Alignment) -> post.Alignment {
  case alignment {
    maud_components.Left -> post.Left
    maud_components.Center -> post.Center
    maud_components.Right -> post.Right
  }
}

fn mork_options(options: post.Options) -> mork_document.Options {
  mork_document.Options(
    // we already parse frontmatter separately, so we can tell mork to ignore it
    strip_frontmatter: True,
    footnotes: options.footnotes,
    heading_ids: options.heading_ids,
    tables: options.tables,
    tasklists: options.tasklists,
    emojis: options.emojis_shortcodes,
    autolinks: options.autolinks,
  )
}
