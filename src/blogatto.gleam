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

import blogatto/config
import blogatto/error

/// Build the static site based on the provided configuration.
/// 
/// ## Build steps
/// 
/// 0. Clean output directory and copy static assets. This is a prerequisite for all builders to ensure a fresh build environment and that static files are available for the pages and posts.
/// 1. builder/robots — Generate robots.txt via webls. Simplest builder: no parsing, no post dependencies, just config-to-file. Good warm-up to establish the builder module pattern.
/// 2. builder/static - Copy static assets from the configured static_dir to the output directory. This is a straightforward file operation, but it's important to do it early in the build process to ensure that any static files needed by pages or posts are available when those builders run. No parsing or rendering involved, just copying files while preserving directory structure.
/// 3. builder/pages — Render static routes to HTML. Still straightforward: iterate config.routes, call each view function, render with Lustre, write files. No markdown parsing involved.
/// 4. builder/blog — The heavy one. Walk markdown paths, discover post directories, parse frontmatter, render markdown via Maud components, construct Post(msg) values, write HTML pages, copy
/// non-markdown assets. This produces the List(Post(msg)) that feeds and sitemap both need.
/// 5. builder/feed — Generate RSS feeds via webls. Depends on the post list from step 4. Apply filter/serialize per FeedConfig, write XML.
/// 6. builder/sitemap — Generate sitemap XML via webls. Depends on both static routes and blog posts being known. Apply filter/serialize, handle hreflang links for multilingual posts.
pub fn build(config: config.Config(msg)) -> Result(Nil, error.BlogattoError) {
  todo
}
