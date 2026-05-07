# Post components

Blogatto renders Markdown and [Djot](https://djot.net/) sources through the same set of [Maud](https://hexdocs.pm/maud/)-style components — view functions that control how each AST element becomes HTML. You can override any component to add classes, attributes, or entirely custom markup.

The component setters live on `blogatto/config/post` and apply to every post regardless of source format. Markdown-specific AST nodes (e.g., GFM tables) and Djot-specific AST nodes (e.g., highlight `{=...=}`) reuse overlapping components (`table`, `mark`, …), so a single override applies to both formats.

## How it works

The post source is parsed into an AST, then rendered bottom-up: children are rendered first, then passed to the parent component function as `List(Element(msg))`. When implementing a custom component, you must include the children in the element you return, otherwise they won't appear in the output.

Djot-only inline constructs that have no matching component (e.g. `<span>` from `[text]{.class}`, `<ins>` from `{+text+}`, math, symbols) are emitted as raw Lustre elements with their attributes preserved.

## Default components

`post.default()` uses the default Maud components, which render each markdown element as its corresponding HTML element without additional attributes or styling.

```gleam
import blogatto/config/post

let md = post.default()
  |> post.path("./blog")
```

## Overriding components

Each markdown element has a corresponding setter function on `PostConfig`. Override individual components by piping through the setter:

```gleam
import blogatto/config/post
import lustre/attribute
import lustre/element/html

let md =
  post.default()
  |> post.path("./blog")
  |> post.h1(fn(id, children) {
    html.h1([attribute.id(id), attribute.class("post-title")], children)
  })
  |> post.p(fn(children) {
    html.p([attribute.class("post-paragraph")], children)
  })
```

## Component reference

### Text elements

| Setter        | Signature                                | Description        |
| ------------- | ---------------------------------------- | ------------------ |
| `post.p`      | `fn(List(Element(msg))) -> Element(msg)` | Paragraphs         |
| `post.strong` | `fn(List(Element(msg))) -> Element(msg)` | Bold text          |
| `post.em`     | `fn(List(Element(msg))) -> Element(msg)` | Italic text        |
| `post.del`    | `fn(List(Element(msg))) -> Element(msg)` | Strikethrough text |
| `post.mark`   | `fn(List(Element(msg))) -> Element(msg)` | Highlighted text   |

### Headings

All heading setters take `fn(String, List(Element(msg))) -> Element(msg)` where the first argument is a generated heading ID (useful for anchor links).

| Setter    | Description     |
| --------- | --------------- |
| `post.h1` | Level 1 heading |
| `post.h2` | Level 2 heading |
| `post.h3` | Level 3 heading |
| `post.h4` | Level 4 heading |
| `post.h5` | Level 5 heading |
| `post.h6` | Level 6 heading |

Example with anchor links:

```gleam
post.h2(fn(id, children) {
  html.h2([attribute.id(id)], [
    html.a([attribute.href("#" <> id)], [element.text("#")]),
    element.text(" "),
    ..children
  ])
})
```

### Links and images

| Setter     | Signature                                                        | Description                            |
| ---------- | ---------------------------------------------------------------- | -------------------------------------- |
| `post.a`   | `fn(String, Option(String), List(Element(msg))) -> Element(msg)` | Links (href, optional title, children) |
| `post.img` | `fn(String, String, Option(String)) -> Element(msg)`             | Images (src, alt text, optional title) |

Example — open external links in a new tab:

```gleam
import gleam/option.{None, Some}
import gleam/string

post.a(fn(href, title, children) {
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

| Setter      | Signature                                                | Description                                                |
| ----------- | -------------------------------------------------------- | ---------------------------------------------------------- |
| `post.code` | `fn(Option(String), List(Element(msg))) -> Element(msg)` | Code spans and fenced blocks (optional language, children) |
| `post.pre`  | `fn(List(Element(msg))) -> Element(msg)`                 | Preformatted code block wrapper                            |

The `code` component receives `Some("gleam")` for fenced code blocks with a language tag, or `None` for inline code.

> **Tip:** Blogatto supports build-time syntax highlighting via Smalto, which automatically tokenizes code blocks and renders styled `<span>` elements. When syntax highlighting is enabled, the `code` component receives pre-highlighted children. See [Syntax highlighting](syntax-highlighting.md) for the full guide.

Example — add language class to code blocks:

```gleam
import gleam/option.{None, Some}

post.code(fn(lang, children) {
  let class = case lang {
    Some(l) -> "language-" <> l
    None -> ""
  }
  html.code([attribute.class(class)], children)
})
```

### Lists

| Setter          | Signature                                             | Description                                     |
| --------------- | ----------------------------------------------------- | ----------------------------------------------- |
| `post.ul`       | `fn(List(Element(msg))) -> Element(msg)`              | Unordered lists                                 |
| `post.ol`       | `fn(Option(Int), List(Element(msg))) -> Element(msg)` | Ordered lists (optional start number, children) |
| `post.li`       | `fn(List(Element(msg))) -> Element(msg)`              | List items                                      |
| `post.checkbox` | `fn(Bool) -> Element(msg)`                            | Task list checkboxes (checked state)            |

### Tables

| Setter       | Signature                                           | Description                       |
| ------------ | --------------------------------------------------- | --------------------------------- |
| `post.table` | `fn(List(Element(msg))) -> Element(msg)`            | Table wrapper                     |
| `post.thead` | `fn(List(Element(msg))) -> Element(msg)`            | Table header group                |
| `post.tbody` | `fn(List(Element(msg))) -> Element(msg)`            | Table body group                  |
| `post.tr`    | `fn(List(Element(msg))) -> Element(msg)`            | Table row                         |
| `post.th`    | `fn(Alignment, List(Element(msg))) -> Element(msg)` | Header cell (alignment, children) |
| `post.td`    | `fn(Alignment, List(Element(msg))) -> Element(msg)` | Data cell (alignment, children)   |

The `Alignment` type has three variants: `Left`, `Center`, `Right`.

Example — add alignment classes to table cells:

```gleam
import blogatto/config/post.{Left, Center, Right}

post.td(fn(alignment, children) {
  let class = case alignment {
    Left -> "text-left"
    Center -> "text-center"
    Right -> "text-right"
  }
  html.td([attribute.class(class)], children)
})
```

### Other elements

| Setter            | Signature                                     | Description                  |
| ----------------- | --------------------------------------------- | ---------------------------- |
| `post.blockquote` | `fn(List(Element(msg))) -> Element(msg)`      | Block quotes                 |
| `post.hr`         | `fn() -> Element(msg)`                        | Horizontal rules             |
| `post.footnote`   | `fn(Int, List(Element(msg))) -> Element(msg)` | Footnotes (number, children) |

## Replacing all components at once

Use `post.components()` to set a complete `Components` record:

```gleam
let my_components = post.Components(
  a: my_link,
  blockquote: my_blockquote,
  // ... all 27 fields
)

let md =
  post.default()
  |> post.components(my_components)
```

In most cases, overriding individual components via the setter functions is more convenient.
