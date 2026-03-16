//// This module exposes the configuration for syntax highlighting of code blocks in markdown files.

import gleam/dict
import gleam/list
import lustre/element.{type Element}
import smalto
import smalto/grammar
import smalto/languages/bash
import smalto/languages/c
import smalto/languages/cpp
import smalto/languages/css
import smalto/languages/dart
import smalto/languages/dockerfile
import smalto/languages/elixir
import smalto/languages/erlang
import smalto/languages/gleam
import smalto/languages/go
import smalto/languages/haskell
import smalto/languages/html
import smalto/languages/java
import smalto/languages/javascript
import smalto/languages/json
import smalto/languages/kotlin
import smalto/languages/lua
import smalto/languages/markdown
import smalto/languages/php
import smalto/languages/python
import smalto/languages/ruby
import smalto/languages/rust
import smalto/languages/scala
import smalto/languages/sql
import smalto/languages/swift
import smalto/languages/toml
import smalto/languages/typescript
import smalto/languages/xml
import smalto/languages/yaml
import smalto/languages/zig
import smalto/lustre as smalto_lustre

/// The configuration for syntax highlighting of code blocks in markdown files.
pub opaque type SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    /// Lustre components to render smalto tokens.
    config: smalto_lustre.Config(msg),
    /// A mapping from language names to their corresponding grammars.
    languages: dict.Dict(String, fn() -> grammar.Grammar),
  )
}

/// Returns the default configuration for syntax highlighting of code blocks in markdown files.
pub fn default() -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    config: smalto_lustre.default_config(),
    languages: dict.from_list([
      #("bash", bash.grammar),
      #("c", c.grammar),
      #("cpp", cpp.grammar),
      #("css", css.grammar),
      #("dart", dart.grammar),
      #("dockerfile", dockerfile.grammar),
      #("elixir", elixir.grammar),
      #("erlang", erlang.grammar),
      #("gleam", gleam.grammar),
      #("go", go.grammar),
      #("golang", go.grammar),
      #("haskell", haskell.grammar),
      #("hs", haskell.grammar),
      #("html", html.grammar),
      #("java", java.grammar),
      #("javascript", javascript.grammar),
      #("js", javascript.grammar),
      #("json", json.grammar),
      #("kotlin", kotlin.grammar),
      #("kt", kotlin.grammar),
      #("lua", lua.grammar),
      #("markdown", markdown.grammar),
      #("md", markdown.grammar),
      #("php", php.grammar),
      #("python", python.grammar),
      #("py", python.grammar),
      #("rb", ruby.grammar),
      #("ruby", ruby.grammar),
      #("rs", rust.grammar),
      #("rust", rust.grammar),
      #("scala", scala.grammar),
      #("sh", bash.grammar),
      #("shell", bash.grammar),
      #("sql", sql.grammar),
      #("swift", swift.grammar),
      #("toml", toml.grammar),
      #("ts", typescript.grammar),
      #("typescript", typescript.grammar),
      #("xml", xml.grammar),
      #("yaml", yaml.grammar),
      #("yml", yaml.grammar),
      #("zig", zig.grammar),
    ]),
  )
}

/// Highlights source code for the given language, returning highlighted Lustre elements.
/// Returns Error(Nil) if the language is not in the configured languages dictionary.
pub fn highlight(
  config: SyntaxHighlightingConfig(msg),
  language: String,
  source: String,
) -> Result(List(Element(msg)), Nil) {
  case dict.get(config.languages, language) {
    Ok(grammar_fn) -> {
      let tokens = smalto.to_tokens(source, grammar_fn())
      Ok(smalto_lustre.to_lustre(tokens, config.config))
    }
    Error(_) -> Error(Nil)
  }
}

/// Sets the smalto_lustre configuration for syntax highlighting. This allows you to customize how different token types are rendered.
pub fn smalto_config(
  config: SyntaxHighlightingConfig(msg),
  smalto_lustre_config: smalto_lustre.Config(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(..config, config: smalto_lustre_config)
}

/// Adds a new language to the syntax highlighting configuration.
pub fn add_language(
  config: SyntaxHighlightingConfig(msg),
  grammar_fn: fn() -> grammar.Grammar,
  language_names: List(String),
) -> SyntaxHighlightingConfig(msg) {
  let updated_languages =
    list.fold(language_names, config.languages, fn(acc, lang) {
      dict.insert(acc, lang, grammar_fn)
    })
  SyntaxHighlightingConfig(..config, languages: updated_languages)
}

pub fn keyword(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.keyword(config.config, element),
  )
}

pub fn string(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.string(config.config, element),
  )
}

pub fn number(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.number(config.config, element),
  )
}

pub fn comment(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.comment(config.config, element),
  )
}

pub fn function(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.function(config.config, element),
  )
}

pub fn operator(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.operator(config.config, element),
  )
}

pub fn punctuation(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.punctuation(config.config, element),
  )
}

pub fn type_(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.type_(config.config, element),
  )
}

pub fn module(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.module(config.config, element),
  )
}

pub fn variable(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.variable(config.config, element),
  )
}

pub fn constant(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.constant(config.config, element),
  )
}

pub fn builtin(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.builtin(config.config, element),
  )
}

pub fn tag(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.tag(config.config, element),
  )
}

pub fn attribute(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.attribute(config.config, element),
  )
}

pub fn selector(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.selector(config.config, element),
  )
}

pub fn property(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.property(config.config, element),
  )
}

pub fn regex(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.regex(config.config, element),
  )
}

pub fn custom(
  config: SyntaxHighlightingConfig(msg),
  element: fn(String, String) -> Element(msg),
) -> SyntaxHighlightingConfig(msg) {
  SyntaxHighlightingConfig(
    ..config,
    config: smalto_lustre.custom(config.config, element),
  )
}
