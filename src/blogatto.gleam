//// Blogatto is a Gleam framework for building static blogs.
////
//// Given a `Config`, a single call to `build()` generates your entire site:
//// blog posts from markdown with frontmatter, static pages from Lustre views,
//// RSS feeds, sitemaps, and robots.txt — all rendered via Maud components
//// and written to the configured output directory.
////
//// ## Quick start
////
//// ```gleam
//// import blogatto
//// import blogatto/config
//// import blogatto/config/markdown
////
//// pub fn main() {
////   let md =
////     markdown.default()
////     |> markdown.markdown_path("./blog")
////
////   let cfg =
////     config.new("https://example.com")
////     |> config.output_dir("./dist")
////     |> config.static_dir("./static")
////     |> config.markdown(md)
////
////   let assert Ok(Nil) = blogatto.build(cfg)
//// }
//// ```

