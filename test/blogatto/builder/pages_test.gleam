import blogatto/config
import blogatto/internal/builder/pages as pages_builder
import gleam/string
import gleeunit/should
import lustre/attribute
import lustre/element
import lustre/element/html
import simplifile

const test_dir = "./test_output_pages"

fn with_test_dir(f: fn(String) -> Nil) -> Nil {
  let assert Ok(_) = simplifile.create_directory_all(test_dir)
  f(test_dir)
  let assert Ok(_) = simplifile.delete(test_dir)
  Nil
}

fn simple_view() -> element.Element(msg) {
  html.div([], [html.text("Hello, world!")])
}

fn about_view() -> element.Element(msg) {
  html.main([], [
    html.h1([], [html.text("About Us")]),
    html.p([], [html.text("We build static sites.")]),
  ])
}

fn contact_view() -> element.Element(msg) {
  html.section([attribute.id("contact")], [
    html.h2([], [html.text("Contact")]),
  ])
}

fn minimal_config(output_dir: String) -> config.Config(msg) {
  config.new("https://example.com")
  |> config.output_dir(output_dir)
}

// --- Empty routes ---

pub fn build_with_no_routes_succeeds_test() {
  use dir <- with_test_dir
  let cfg = minimal_config(dir)

  pages_builder.build(cfg)
  |> should.be_ok
}

// --- Single route ---

pub fn build_creates_index_html_for_single_route_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/", simple_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/index.html")
  |> should.be_ok
  |> should.be_true
}

pub fn build_renders_view_content_to_html_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/", simple_view)

  pages_builder.build(cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/index.html")
  content
  |> string.contains("Hello, world!")
  |> should.be_true
}

pub fn build_wraps_output_in_html_document_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/", simple_view)

  pages_builder.build(cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/index.html")
  content
  |> string.starts_with("<!doctype html>")
  |> should.be_true
}

// --- Named routes ---

pub fn build_creates_subdirectory_for_named_route_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/about", about_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/about/index.html")
  |> should.be_ok
  |> should.be_true
}

pub fn build_named_route_contains_view_content_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/about", about_view)

  pages_builder.build(cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/about/index.html")
  content
  |> string.contains("About Us")
  |> should.be_true
  content
  |> string.contains("We build static sites.")
  |> should.be_true
}

// --- Nested routes ---

pub fn build_creates_nested_directories_for_deep_route_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/about/team", simple_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/about/team/index.html")
  |> should.be_ok
  |> should.be_true
}

pub fn build_creates_deeply_nested_route_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/docs/api/v1", simple_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/docs/api/v1/index.html")
  |> should.be_ok
  |> should.be_true
}

// --- Multiple routes ---

pub fn build_creates_files_for_all_routes_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/", simple_view)
    |> config.route("/about", about_view)
    |> config.route("/contact", contact_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/index.html")
  |> should.be_ok
  |> should.be_true
  simplifile.is_file(dir <> "/about/index.html")
  |> should.be_ok
  |> should.be_true
  simplifile.is_file(dir <> "/contact/index.html")
  |> should.be_ok
  |> should.be_true
}

pub fn build_each_route_has_its_own_content_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/about", about_view)
    |> config.route("/contact", contact_view)

  pages_builder.build(cfg)
  |> should.be_ok

  let assert Ok(about_content) = simplifile.read(dir <> "/about/index.html")
  about_content
  |> string.contains("About Us")
  |> should.be_true
  about_content
  |> string.contains("Contact")
  |> should.be_false

  let assert Ok(contact_content) = simplifile.read(dir <> "/contact/index.html")
  contact_content
  |> string.contains("Contact")
  |> should.be_true
  contact_content
  |> string.contains("About Us")
  |> should.be_false
}

// --- HTML attributes preserved ---

pub fn build_preserves_html_attributes_in_output_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/contact", contact_view)

  pages_builder.build(cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/contact/index.html")
  content
  |> string.contains("id=\"contact\"")
  |> should.be_true
}

// --- Route without leading slash ---

pub fn build_handles_route_without_leading_slash_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("privacy", simple_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/privacy/index.html")
  |> should.be_ok
  |> should.be_true
}

// --- Mixed routes ---

pub fn build_handles_mixed_root_and_nested_routes_test() {
  use dir <- with_test_dir
  let cfg =
    minimal_config(dir)
    |> config.route("/", simple_view)
    |> config.route("/about/team", about_view)

  pages_builder.build(cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/index.html")
  |> should.be_ok
  |> should.be_true
  simplifile.is_file(dir <> "/about/team/index.html")
  |> should.be_ok
  |> should.be_true
}
