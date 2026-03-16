import blogatto/config/markdown/code
import gleam/list
import gleam/string
import gleeunit/should
import lustre/element
import smalto/languages/gleam
import smalto/languages/rust
import smalto/lustre as smalto_lustre

// --- highlight ---

pub fn highlight_gleam_keyword_test() {
  let config = code.default()
  let result = code.highlight(config, "gleam", "pub fn main() {}")

  result
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  // the output should contain highlighted tokens, not raw text
  |> string.contains("pub")
  |> should.be_true
}

pub fn highlight_gleam_produces_styled_spans_test() {
  let config = code.default()
  let result = code.highlight(config, "gleam", "let x = 1")

  let html =
    result
    |> should.be_ok
    |> element.fragment()
    |> element.to_string()

  // default config uses inline style spans for keywords
  html |> string.contains("<span") |> should.be_true
  html |> string.contains("let") |> should.be_true
}

pub fn highlight_python_test() {
  let config = code.default()
  let result = code.highlight(config, "python", "print(\"hello\")")

  let html =
    result
    |> should.be_ok
    |> element.fragment()
    |> element.to_string()

  html |> string.contains("print") |> should.be_true
  html |> string.contains("hello") |> should.be_true
}

pub fn highlight_unknown_language_returns_error_test() {
  let config = code.default()

  code.highlight(config, "brainfuck", "+++.")
  |> should.be_error
  |> should.equal(Nil)
}

pub fn highlight_returns_multiple_elements_test() {
  let config = code.default()
  let elements =
    code.highlight(config, "gleam", "pub fn main() {}")
    |> should.be_ok

  // tokenization should produce multiple elements (keywords, whitespace, punctuation, etc.)
  list.length(elements) |> should.not_equal(0)
}

pub fn highlight_empty_source_returns_empty_list_test() {
  let config = code.default()

  code.highlight(config, "gleam", "")
  |> should.be_ok
  |> should.equal([])
}

pub fn highlight_preserves_source_content_test() {
  let source = "import gleam/io\n\npub fn main() {\n  io.println(\"Hello!\")\n}"
  let config = code.default()

  let html =
    code.highlight(config, "gleam", source)
    |> should.be_ok
    |> element.fragment()
    |> element.to_string()

  // all identifiers and strings from the source should appear in the output
  html |> string.contains("import") |> should.be_true
  html |> string.contains("gleam") |> should.be_true
  html |> string.contains("pub") |> should.be_true
  html |> string.contains("fn") |> should.be_true
  html |> string.contains("main") |> should.be_true
  html |> string.contains("Hello!") |> should.be_true
}

pub fn highlight_with_custom_keyword_renderer_test() {
  let config =
    code.default()
    |> code.keyword(fn(text) { element.text("[KW:" <> text <> "]") })

  let html =
    code.highlight(config, "gleam", "pub fn main() {}")
    |> should.be_ok
    |> element.fragment()
    |> element.to_string()

  // custom renderer should wrap keywords
  html |> string.contains("[KW:pub") |> should.be_true
  html |> string.contains("[KW:fn") |> should.be_true
}

// --- Language aliases ---

pub fn highlight_rs_alias_for_rust_test() {
  let config = code.default()

  code.highlight(config, "rs", "fn main() {}")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("fn")
  |> should.be_true
}

pub fn highlight_js_alias_for_javascript_test() {
  let config = code.default()

  code.highlight(config, "js", "const x = 1;")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("const")
  |> should.be_true
}

pub fn highlight_ts_alias_for_typescript_test() {
  let config = code.default()

  code.highlight(config, "ts", "const x: number = 1;")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("const")
  |> should.be_true
}

pub fn highlight_py_alias_for_python_test() {
  let config = code.default()

  code.highlight(config, "py", "print(\"hello\")")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("print")
  |> should.be_true
}

pub fn highlight_sh_alias_for_bash_test() {
  let config = code.default()

  code.highlight(config, "sh", "echo hello")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("echo")
  |> should.be_true
}

pub fn highlight_shell_alias_for_bash_test() {
  let config = code.default()

  code.highlight(config, "shell", "echo hello")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("echo")
  |> should.be_true
}

pub fn highlight_rb_alias_for_ruby_test() {
  let config = code.default()

  code.highlight(config, "rb", "puts \"hello\"")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("puts")
  |> should.be_true
}

pub fn highlight_yml_alias_for_yaml_test() {
  let config = code.default()

  code.highlight(config, "yml", "key: value")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("key")
  |> should.be_true
}

pub fn highlight_golang_alias_for_go_test() {
  let config = code.default()

  code.highlight(config, "golang", "func main() {}")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("func")
  |> should.be_true
}

pub fn highlight_kt_alias_for_kotlin_test() {
  let config = code.default()

  code.highlight(config, "kt", "fun main() {}")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("fun")
  |> should.be_true
}

pub fn highlight_hs_alias_for_haskell_test() {
  let config = code.default()

  code.highlight(config, "hs", "main = putStrLn \"hello\"")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("main")
  |> should.be_true
}

pub fn highlight_md_alias_for_markdown_test() {
  let config = code.default()

  code.highlight(config, "md", "# Hello")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("Hello")
  |> should.be_true
}

// --- smalto_config ---

pub fn smalto_config_applies_custom_lustre_config_test() {
  let custom_lustre_config = smalto_lustre.default_config()

  let config =
    code.default()
    |> code.smalto_config(custom_lustre_config)

  // highlighting should still work after setting a custom smalto config
  code.highlight(config, "gleam", "pub fn main() {}")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("pub")
  |> should.be_true
}

// --- add_language ---

pub fn add_language_registers_new_language_test() {
  let config =
    code.default()
    |> code.add_language(gleam.grammar, ["my_gleam", "myg"])

  // the new alias should work
  code.highlight(config, "my_gleam", "pub fn main() {}")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("pub")
  |> should.be_true

  // the second alias should also work
  code.highlight(config, "myg", "let x = 1")
  |> should.be_ok
  |> element.fragment()
  |> element.to_string()
  |> string.contains("let")
  |> should.be_true
}

pub fn add_language_overrides_existing_language_test() {
  // override "gleam" with the rust grammar
  let config =
    code.default()
    |> code.add_language(rust.grammar, ["gleam"])

  // "gleam" now uses the rust grammar, so Rust keywords should be highlighted
  let html =
    code.highlight(config, "gleam", "fn main() { let x = 1; }")
    |> should.be_ok
    |> element.fragment()
    |> element.to_string()

  html |> string.contains("fn") |> should.be_true
  html |> string.contains("let") |> should.be_true
}

pub fn add_language_with_empty_names_does_not_change_config_test() {
  let config = code.default()
  let updated_config = code.add_language(config, gleam.grammar, [])

  // unknown language should still fail — nothing was added
  code.highlight(updated_config, "brainfuck", "+++.")
  |> should.be_error
  |> should.equal(Nil)
}
