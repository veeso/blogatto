import filepath as path
import gleam/option.{type Option, None, Some}
import gleam/string

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

/// Extract the optional language code from a markdown file path.
///
/// Returns `Some(lang)` for filenames matching the `index-{lang}.md`
/// pattern (e.g., `Some("it")` for `index-it.md`), or `None` for
/// `index.md` or filenames that don't match the convention.
///
/// ## Examples
///
/// ```gleam
/// language("blog/my-post/index.md")     // -> None
/// language("blog/my-post/index-it.md")  // -> Some("it")
/// language("blog/my-post/image.png")    // -> None
/// ```
pub fn language(file_path: String) -> Option(String) {
  let stem =
    file_path
    |> path.base_name()
    |> path.strip_extension()

  case string.split_once(stem, "index-") {
    Ok(#("", lang)) if lang != "" -> Some(lang)
    _ -> None
  }
}
