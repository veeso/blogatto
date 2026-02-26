//// A simple blog example demonstrating the full Blogatto build pipeline.
////
//// Builds a static blog with a homepage listing articles, two markdown
//// blog posts, an RSS feed, a sitemap, and a robots.txt file.
////
//// Run with `gleam run` from the `examples/simple_blog` directory.

import blogatto/dev
import blogatto/error
import gleam/io
import simple_blog/blog

pub fn main() {
  let cfg = blog.config()
  // run dev server
  case
    cfg
    |> dev.new()
    |> dev.start()
  {
    Ok(Nil) -> io.println("Dev server stopped.")
    Error(err) -> io.println("Dev server error: " <> error.describe_error(err))
  }
}
