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

// -- join ---------------------------------------------------------------------

pub fn join_simple_segments_test() {
  path.join("dist", "blog")
  |> should.equal("dist/blog")
}

pub fn join_strips_leading_slash_from_right_test() {
  path.join("./dist", "/blog")
  |> should.equal("./dist/blog")
}

pub fn join_strips_multiple_leading_slashes_test() {
  path.join("dist", "///assets")
  |> should.equal("dist/assets")
}

pub fn join_right_is_empty_test() {
  path.join("dist", "")
  |> should.equal("dist")
}

pub fn join_nested_segments_test() {
  path.join("./output", "/about/team")
  |> should.equal("./output/about/team")
}

pub fn join_index_html_not_to_trailing_slash_test() {
  path.join("/about", "index.html")
  |> should.equal("/about/index.html")
}

// -- route --------------------------------------------------------------------

pub fn route_with_leading_slash_test() {
  path.route("./dist", "/blog")
  |> should.equal("./dist/blog/index.html")
}

pub fn route_without_leading_slash_test() {
  path.route("./dist", "about")
  |> should.equal("./dist/about/index.html")
}

pub fn route_root_route_test() {
  path.route("./dist", "/")
  |> should.equal("./dist/index.html")
}

pub fn route_nested_route_test() {
  path.route("output", "/blog/2024/post")
  |> should.equal("output/blog/2024/post/index.html")
}

// -- parent -------------------------------------------------------------------

pub fn parent_returns_directory_test() {
  path.parent("dist/blog/index.html")
  |> should.equal("dist/blog")
}

pub fn parent_single_segment_test() {
  path.parent("dist/file.txt")
  |> should.equal("dist")
}
