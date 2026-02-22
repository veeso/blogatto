//// Internal build orchestrator and shared utilities.
////
//// This module contains the core build pipeline logic and utility functions
//// shared across the individual builder modules.

import filepath as path

/// Compute the output file path for a given route.
///
/// Strips the leading slash from the route, joins it with the output directory,
/// and appends `index.html`.
///
/// ## Examples
///
/// ```gleam
/// route_filepath("./dist", "/blog") // -> "./dist/blog/index.html"
/// route_filepath("./dist", "about") // -> "./dist/about/index.html"
/// ```
pub fn route_filepath(output_dir: String, route: String) -> String {
  // Remove leading slash so filepath.join works correctly
  let route = case route {
    "/" <> rest -> rest
    _ -> route
  }
  output_dir |> path.join(route) |> path.join("index.html")
}
