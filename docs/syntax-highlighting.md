---
layout: default
title: Syntax highlighting
nav_order: 7
---

# Syntax highlighting

Blogatto supports build-time syntax highlighting for code blocks in your markdown files via [Smalto](https://hexdocs.pm/smalto/). When enabled, fenced code blocks with a language tag (e.g., `` ```gleam ``) are highlighted at build time, producing styled HTML with no client-side JavaScript required.

## Enabling syntax highlighting

Syntax highlighting is disabled by default. Enable it by passing a `SyntaxHighlightingConfig` to the markdown configuration:

```gleam
import blogatto/config/markdown
import blogatto/config/markdown/code

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.syntax_highlighting(code.default())
```

`code.default()` includes grammars for 28 languages out of the box.

## Supported languages

The default configuration supports the following languages (with aliases):

| Language | Aliases |
|----------|---------|
| Bash | `bash`, `sh`, `shell` |
| C | `c` |
| C++ | `cpp` |
| CSS | `css` |
| Dart | `dart` |
| Dockerfile | `dockerfile` |
| Elixir | `elixir` |
| Erlang | `erlang` |
| Gleam | `gleam` |
| Go | `go`, `golang` |
| Haskell | `haskell`, `hs` |
| HTML | `html` |
| Java | `java` |
| JavaScript | `javascript`, `js` |
| JSON | `json` |
| Kotlin | `kotlin`, `kt` |
| Lua | `lua` |
| Markdown | `markdown`, `md` |
| PHP | `php` |
| Python | `python`, `py` |
| Ruby | `ruby`, `rb` |
| Rust | `rust`, `rs` |
| Scala | `scala` |
| SQL | `sql` |
| Swift | `swift` |
| TOML | `toml` |
| TypeScript | `typescript`, `ts` |
| XML | `xml` |
| YAML | `yaml`, `yml` |
| Zig | `zig` |

## Adding custom languages

If a language you need is not in the default set, add it with `code.add_language()`:

```gleam
import blogatto/config/markdown/code
import smalto/languages/ocaml

let syntax_config =
  code.default()
  |> code.add_language(ocaml.grammar, ["ocaml", "ml"])
```

The second argument is a list of names that will match the language tag in fenced code blocks.

## Styling highlighted code

Smalto renders each token as a `<span>` with a CSS class corresponding to the token type. By default, the classes are:

| Token type | CSS class |
|------------|-----------|
| Keyword | `smalto-keyword` |
| String | `smalto-string` |
| Number | `smalto-number` |
| Comment | `smalto-comment` |
| Function | `smalto-function` |
| Operator | `smalto-operator` |
| Punctuation | `smalto-punctuation` |
| Type | `smalto-type` |
| Module | `smalto-module` |
| Variable | `smalto-variable` |
| Constant | `smalto-constant` |
| Builtin | `smalto-builtin` |
| Tag | `smalto-tag` |
| Attribute | `smalto-attribute` |
| Selector | `smalto-selector` |
| Property | `smalto-property` |
| Regex | `smalto-regex` |

To style your code blocks, add CSS rules for these classes. Here is a minimal dark theme example:

```css
pre.code-block {
  background: #1e1e2e;
  color: #cdd6f4;
  padding: 1rem;
  border-radius: 0.5rem;
  overflow-x: auto;
}

.smalto-keyword { color: #cba6f7; }
.smalto-string { color: #a6e3a1; }
.smalto-number { color: #fab387; }
.smalto-comment { color: #6c7086; font-style: italic; }
.smalto-function { color: #89b4fa; }
.smalto-operator { color: #89dceb; }
.smalto-punctuation { color: #cdd6f4; }
.smalto-type { color: #f9e2af; }
.smalto-module { color: #f9e2af; }
.smalto-variable { color: #cdd6f4; }
.smalto-constant { color: #fab387; }
.smalto-builtin { color: #f38ba8; }
.smalto-tag { color: #f38ba8; }
.smalto-attribute { color: #f9e2af; }
.smalto-selector { color: #a6e3a1; }
.smalto-property { color: #89b4fa; }
.smalto-regex { color: #f5c2e7; }
```

## Custom token rendering

If CSS classes are not enough, you can override how each token type is rendered using the setter functions on `SyntaxHighlightingConfig`. Each setter takes a function that receives the token text and returns a Lustre element:

```gleam
import blogatto/config/markdown/code
import lustre/attribute
import lustre/element
import lustre/element/html

let syntax_config =
  code.default()
  |> code.keyword(fn(text) {
    html.span(
      [attribute.style([#("color", "#cba6f7"), #("font-weight", "bold")])],
      [element.text(text)],
    )
  })
  |> code.comment(fn(text) {
    html.span(
      [attribute.style([#("color", "#6c7086"), #("font-style", "italic")])],
      [element.text(text)],
    )
  })
```

Available token setters: `keyword`, `string`, `number`, `comment`, `function`, `operator`, `punctuation`, `type_`, `module`, `variable`, `constant`, `builtin`, `tag`, `attribute`, `selector`, `property`, `regex`.

There is also a `custom` setter for custom token types emitted by some grammars. It receives both the custom type name and the token text:

```gleam
code.custom(fn(type_name, text) {
  html.span(
    [attribute.class("smalto-custom-" <> type_name)],
    [element.text(text)],
  )
})
```

## Using with `smalto_config`

For full control over the underlying Smalto rendering, use `code.smalto_config()` to pass a custom `smalto_lustre.Config` directly:

```gleam
import blogatto/config/markdown/code
import smalto/lustre as smalto_lustre

let smalto_cfg = smalto_lustre.default_config()
  // ... customize via smalto_lustre API ...

let syntax_config =
  code.default()
  |> code.smalto_config(smalto_cfg)
```

## Customizing the code block wrapper

Syntax highlighting controls the _contents_ of code blocks. To customize the wrapping `<pre>` and `<code>` elements, use the markdown component setters:

```gleam
import blogatto/config/markdown
import blogatto/config/markdown/code
import gleam/option

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.syntax_highlighting(code.default())
  |> markdown.pre(fn(children) {
    html.pre([attribute.class("code-block")], children)
  })
  |> markdown.code(fn(language, children) {
    let lang_class = case language {
      option.Some(lang) -> "language-" <> lang
      option.None -> ""
    }
    html.code([attribute.class(lang_class)], children)
  })
```

## Complete example

Putting it all together — a markdown config with syntax highlighting, custom wrapper classes, and a custom keyword style:

```gleam
import blogatto/config/markdown
import blogatto/config/markdown/code
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html

let syntax_config =
  code.default()
  |> code.keyword(fn(text) {
    html.span(
      [attribute.class("token-keyword")],
      [element.text(text)],
    )
  })

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.route_prefix("blog")
  |> markdown.syntax_highlighting(syntax_config)
  |> markdown.pre(fn(children) {
    html.pre([attribute.class("code-block")], children)
  })
  |> markdown.code(fn(language, children) {
    let lang_class = case language {
      option.Some(lang) -> "language-" <> lang
      option.None -> ""
    }
    html.code([attribute.class(lang_class)], children)
  })
```
