import blogatto/config/post as post_cfg
import blogatto/internal/builder/post/djot
import gleam/string
import gleeunit/should
import lustre/element

fn render(content: String) -> String {
  let config = post_cfg.default()
  djot.render(config, content)
  |> element.fragment
  |> element.to_string
}

// --- extensions ---

pub fn extension_short_is_dj_test() {
  djot.extension_short
  |> should.equal("dj")
}

pub fn extension_long_is_djot_test() {
  djot.extension_long
  |> should.equal("djot")
}

// --- paragraphs and basic inlines ---

pub fn paragraph_test() {
  render("Hello, world!")
  |> string.contains("<p>Hello, world!</p>")
  |> should.be_true
}

pub fn emphasis_test() {
  let html = render("_emphasized_")
  html |> string.contains("<em>") |> should.be_true
  html |> string.contains("emphasized") |> should.be_true
}

pub fn strong_test() {
  let html = render("*bold*")
  html |> string.contains("<strong>") |> should.be_true
  html |> string.contains("bold") |> should.be_true
}

pub fn delete_test() {
  let html = render("{-removed-}")
  html |> string.contains("<del>") |> should.be_true
  html |> string.contains("removed") |> should.be_true
}

pub fn insert_test() {
  let html = render("{+added+}")
  html |> string.contains("<ins>") |> should.be_true
  html |> string.contains("added") |> should.be_true
}

pub fn mark_test() {
  let html = render("see {=highlighted=} text")
  html |> string.contains("<mark>") |> should.be_true
  html |> string.contains("highlighted") |> should.be_true
}

pub fn inline_code_test() {
  let html = render("Use `let x = 1` here.")
  html |> string.contains("<code>") |> should.be_true
  html |> string.contains("let x = 1") |> should.be_true
}

// --- headings ---

pub fn heading_h1_test() {
  let html = render("# Hello")
  html |> string.contains("<h1") |> should.be_true
  html |> string.contains("Hello") |> should.be_true
}

pub fn heading_h2_test() {
  let html = render("## Subtitle")
  html |> string.contains("<h2") |> should.be_true
  html |> string.contains("Subtitle") |> should.be_true
}

pub fn heading_auto_id_test() {
  let html = render("# Hello world")
  html |> string.contains("id=\"Hello-world\"") |> should.be_true
}

// --- code blocks ---

pub fn codeblock_test() {
  let source = "```gleam\nlet x = 1\n```"
  let html = render(source)
  html |> string.contains("<pre>") |> should.be_true
  html |> string.contains("language-gleam") |> should.be_true
  html |> string.contains("let x = 1") |> should.be_true
}

pub fn codeblock_without_language_test() {
  let source = "```\nplain text\n```"
  let html = render(source)
  html |> string.contains("<pre>") |> should.be_true
  html |> string.contains("<code>") |> should.be_true
  html |> string.contains("plain text") |> should.be_true
}

// --- lists ---

pub fn bullet_list_test() {
  let html = render("- one\n- two\n- three\n")
  html |> string.contains("<ul>") |> should.be_true
  html |> string.contains("<li>one</li>") |> should.be_true
  html |> string.contains("<li>two</li>") |> should.be_true
  html |> string.contains("<li>three</li>") |> should.be_true
}

pub fn ordered_list_test() {
  let html = render("1. first\n2. second\n")
  html |> string.contains("<ol>") |> should.be_true
  html |> string.contains("first") |> should.be_true
  html |> string.contains("second") |> should.be_true
}

pub fn ordered_list_with_start_test() {
  let html = render("3. third\n4. fourth\n")
  html |> string.contains("start=\"3\"") |> should.be_true
}

// --- blockquote ---

pub fn blockquote_test() {
  let html = render("> a quote\n")
  html |> string.contains("<blockquote>") |> should.be_true
  html |> string.contains("a quote") |> should.be_true
}

// --- thematic break ---

pub fn thematic_break_test() {
  render("---\n")
  |> string.contains("<hr>")
  |> should.be_true
}

// --- links and images ---

pub fn link_test() {
  let html = render("See [Gleam](https://gleam.run).")
  html |> string.contains("<a") |> should.be_true
  html |> string.contains("href=\"https://gleam.run\"") |> should.be_true
  html |> string.contains("Gleam") |> should.be_true
}

pub fn reference_link_test() {
  let source = "See [Gleam][site].\n\n[site]: https://gleam.run\n"
  let html = render(source)
  html |> string.contains("href=\"https://gleam.run\"") |> should.be_true
  html |> string.contains("Gleam") |> should.be_true
}

pub fn image_test() {
  let html = render("![alt text](/img.png)")
  html |> string.contains("<img") |> should.be_true
  html |> string.contains("src=\"/img.png\"") |> should.be_true
  html |> string.contains("alt=\"alt text\"") |> should.be_true
}

// --- raw block ---

pub fn raw_block_test() {
  let source = "``` =html\n<custom>raw</custom>\n```"
  render(source)
  |> string.contains("<custom>raw</custom>")
  |> should.be_true
}

// --- footnotes ---

pub fn footnote_reference_test() {
  let source = "Body text[^a].\n\n[^a]: A footnote.\n"
  let html = render(source)
  html |> string.contains("<sup") |> should.be_true
  html |> string.contains("a") |> should.be_true
}

// --- div ---

pub fn div_test() {
  let source = "::: warn\nBe careful.\n:::\n"
  let html = render(source)
  html |> string.contains("<div") |> should.be_true
  html |> string.contains("Be careful.") |> should.be_true
}

// --- span ---

pub fn span_test() {
  let html = render("[hello]{.greeting}")
  html |> string.contains("<span") |> should.be_true
  html |> string.contains("hello") |> should.be_true
}

// --- symbol ---

pub fn symbol_test() {
  let html = render(":smile:")
  html |> string.contains("class=\"symbol\"") |> should.be_true
  html |> string.contains("smile") |> should.be_true
}

// --- math ---

pub fn math_inline_test() {
  let html = render("$`x^2`")
  html |> string.contains("class=\"math inline\"") |> should.be_true
  html |> string.contains("\\(x^2\\)") |> should.be_true
}

pub fn math_display_test() {
  let html = render("$$`x^2`")
  html |> string.contains("class=\"math display\"") |> should.be_true
  html |> string.contains("\\[x^2\\]") |> should.be_true
}
