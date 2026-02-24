---
layout: default
title: Markdown components
nav_order: 5
---

Blogatto renders markdown through [Maud](https://hexdocs.pm/maud/) components — view functions that control how each markdown element becomes HTML. You can override any component to add classes, attributes, or entirely custom markup.

## How it works

Markdown is parsed into an AST, then rendered bottom-up: children are rendered first, then passed to the parent component function as `List(Element(msg))`. When implementing a custom component, you must include the children in the element you return, otherwise they won't appear in the output.

## Default components

`markdown.default()` uses the default Maud components, which render each markdown element as its corresponding HTML element without additional attributes or styling.

```gleam
import blogatto/config/markdown

let md = markdown.default()
  |> markdown.markdown_path("./blog")
```

## Overriding components

Each markdown element has a corresponding setter function on `MarkdownConfig`. Override individual components by piping through the setter:

```gleam
import blogatto/config/markdown
import lustre/attribute
import lustre/element/html

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.h1(fn(id, children) {
    html.h1([attribute.id(id), attribute.class("post-title")], children)
  })
  |> markdown.p(fn(children) {
    html.p([attribute.class("post-paragraph")], children)
  })
```

## Component reference

### Text elements

| Setter | Signature | Description |
|--------|-----------|-------------|
| `markdown.p` | `fn(List(Element(msg))) -> Element(msg)` | Paragraphs |
| `markdown.strong` | `fn(List(Element(msg))) -> Element(msg)` | Bold text |
| `markdown.em` | `fn(List(Element(msg))) -> Element(msg)` | Italic text |
| `markdown.del` | `fn(List(Element(msg))) -> Element(msg)` | Strikethrough text |
| `markdown.mark` | `fn(List(Element(msg))) -> Element(msg)` | Highlighted text |

### Headings

All heading setters take `fn(String, List(Element(msg))) -> Element(msg)` where the first argument is a generated heading ID (useful for anchor links).

| Setter | Description |
|--------|-------------|
| `markdown.h1` | Level 1 heading |
| `markdown.h2` | Level 2 heading |
| `markdown.h3` | Level 3 heading |
| `markdown.h4` | Level 4 heading |
| `markdown.h5` | Level 5 heading |
| `markdown.h6` | Level 6 heading |

Example with anchor links:

```gleam
markdown.h2(fn(id, children) {
  html.h2([attribute.id(id)], [
    html.a([attribute.href("#" <> id)], [element.text("#")]),
    element.text(" "),
    ..children
  ])
})
```

### Links and images

| Setter | Signature | Description |
|--------|-----------|-------------|
| `markdown.a` | `fn(String, Option(String), List(Element(msg))) -> Element(msg)` | Links (href, optional title, children) |
| `markdown.img` | `fn(String, String, Option(String)) -> Element(msg)` | Images (src, alt text, optional title) |

Example — open external links in a new tab:

```gleam
import gleam/option.{None, Some}
import gleam/string

markdown.a(fn(href, title, children) {
  let attrs = case string.starts_with(href, "http") {
    True -> [
      attribute.href(href),
      attribute.target("_blank"),
      attribute.attribute("rel", "noopener noreferrer"),
    ]
    False -> [attribute.href(href)]
  }
  let attrs = case title {
    Some(t) -> [attribute.title(t), ..attrs]
    None -> attrs
  }
  html.a(attrs, children)
})
```

### Code

| Setter | Signature | Description |
|--------|-----------|-------------|
| `markdown.code` | `fn(Option(String), List(Element(msg))) -> Element(msg)` | Code spans and fenced blocks (optional language, children) |
| `markdown.pre` | `fn(List(Element(msg))) -> Element(msg)` | Preformatted code block wrapper |

The `code` component receives `Some("gleam")` for fenced code blocks with a language tag, or `None` for inline code.

Example — add language class for syntax highlighting:

```gleam
import gleam/option.{None, Some}

markdown.code(fn(lang, children) {
  let class = case lang {
    Some(l) -> "language-" <> l
    None -> ""
  }
  html.code([attribute.class(class)], children)
})
```

### Lists

| Setter | Signature | Description |
|--------|-----------|-------------|
| `markdown.ul` | `fn(List(Element(msg))) -> Element(msg)` | Unordered lists |
| `markdown.ol` | `fn(Option(Int), List(Element(msg))) -> Element(msg)` | Ordered lists (optional start number, children) |
| `markdown.li` | `fn(List(Element(msg))) -> Element(msg)` | List items |
| `markdown.checkbox` | `fn(Bool) -> Element(msg)` | Task list checkboxes (checked state) |

### Tables

| Setter | Signature | Description |
|--------|-----------|-------------|
| `markdown.table` | `fn(List(Element(msg))) -> Element(msg)` | Table wrapper |
| `markdown.thead` | `fn(List(Element(msg))) -> Element(msg)` | Table header group |
| `markdown.tbody` | `fn(List(Element(msg))) -> Element(msg)` | Table body group |
| `markdown.tr` | `fn(List(Element(msg))) -> Element(msg)` | Table row |
| `markdown.th` | `fn(Alignment, List(Element(msg))) -> Element(msg)` | Header cell (alignment, children) |
| `markdown.td` | `fn(Alignment, List(Element(msg))) -> Element(msg)` | Data cell (alignment, children) |

The `Alignment` type has three variants: `Left`, `Center`, `Right`.

Example — add alignment classes to table cells:

```gleam
import blogatto/config/markdown.{Left, Center, Right}

markdown.td(fn(alignment, children) {
  let class = case alignment {
    Left -> "text-left"
    Center -> "text-center"
    Right -> "text-right"
  }
  html.td([attribute.class(class)], children)
})
```

### Other elements

| Setter | Signature | Description |
|--------|-----------|-------------|
| `markdown.blockquote` | `fn(List(Element(msg))) -> Element(msg)` | Block quotes |
| `markdown.hr` | `fn() -> Element(msg)` | Horizontal rules |
| `markdown.footnote` | `fn(Int, List(Element(msg))) -> Element(msg)` | Footnotes (number, children) |

## Replacing all components at once

Use `markdown.components()` to set a complete `Components` record:

```gleam
let my_components = markdown.Components(
  a: my_link,
  blockquote: my_blockquote,
  // ... all 27 fields
)

let md =
  markdown.default()
  |> markdown.components(my_components)
```

In most cases, overriding individual components via the setter functions is more convenient.
