//// Internal builder for static pages.
////
//// Iterates over the static routes in the configuration, calls each
//// view function, and writes the resulting HTML to the output directory.

import blogatto/config
import blogatto/error
import blogatto/internal/path
import gleam/dict
import gleam/list
import gleam/result
import lustre/element.{type Element}
import simplifile

/// Builds the static pages for the blog.
pub fn build(config: config.Config(msg)) -> Result(Nil, error.BlogattoError) {
  config.routes
  |> dict.to_list()
  |> list.try_map(fn(route) { build_page(config.output_dir, route.0, route.1) })
  |> result.replace(Nil)
}

/// Builds a single static page for the given route and view function.
fn build_page(
  output_dir: String,
  route: String,
  view: fn() -> Element(msg),
) -> Result(Nil, error.BlogattoError) {
  let output_file = path.route(output_dir, route)

  // create parent directory if it doesn't exist
  use _ <- result.try(
    output_file
    |> path.parent()
    |> simplifile.create_directory_all()
    |> result.map_error(error.File),
  )

  let content = element.to_document_string(view())

  output_file
  |> simplifile.write(content)
  |> result.map_error(error.File)
}
