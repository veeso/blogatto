import filepath as path

/// Compute the output file path for a given route.
///
/// Strips the leading slash from the route, joins it with the output directory,
/// and appends `index.html`.
///
/// ## Examples
///
/// ```gleam
/// route("./dist", "/blog") // -> "./dist/blog/index.html"
/// route("./dist", "about") // -> "./dist/about/index.html"
/// ```
pub fn route(output_dir: String, route: String) -> String {
  output_dir |> join(route) |> join("index.html")
}

/// Safely join two path segments, ensuring no duplicate slashes, and preventing joining absolute paths that would ignore the output directory.
pub fn join(left: String, right: String) -> String {
  case right {
    "/" <> rest -> join(left, rest)
    _ -> path.join(left, right)
  }
}

/// Get the parent directory of a given path.
pub fn parent(path: String) -> String {
  path.directory_name(path)
}
