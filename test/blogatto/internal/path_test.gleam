import blogatto/internal/path
import gleam/option.{None, Some}
import gleeunit/should

pub fn language_returns_none_for_default_index_test() {
  path.language("blog/my-post/index.md")
  |> should.equal(None)
}

pub fn language_returns_some_for_language_variant_test() {
  path.language("blog/my-post/index-it.md")
  |> should.equal(Some("it"))
}

pub fn language_returns_some_for_longer_language_code_test() {
  path.language("blog/my-post/index-pt-br.md")
  |> should.equal(Some("pt-br"))
}

pub fn language_returns_none_for_non_markdown_file_test() {
  path.language("blog/my-post/image.png")
  |> should.equal(None)
}

pub fn language_returns_none_for_bare_filename_test() {
  path.language("index.md")
  |> should.equal(None)
}

pub fn language_returns_none_for_non_index_markdown_test() {
  path.language("blog/my-post/readme.md")
  |> should.equal(None)
}

pub fn language_returns_none_for_index_dash_without_lang_test() {
  path.language("blog/my-post/index-.md")
  |> should.equal(None)
}
