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
import blogatto/config/feed as feed_config
import blogatto/error
import blogatto/internal/builder/blog
import blogatto/internal/builder/feed
import blogatto/internal/builder/pages
import blogatto/internal/builder/robots
import blogatto/internal/builder/sitemap
import blogatto/internal/builder/static
import blogatto/internal/excerpt
import blogatto/post
import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import simplifile

/// Build the static site based on the provided configuration.
/// 
/// ## Build steps
///
/// 1. Clean output directory and recreate it.
/// 2. Copy static assets from `static_dir` to `output_dir`.
/// 3. Generate `robots.txt` via webls.
/// 4. Build blog pages — walk markdown paths, parse frontmatter, render
///    via Maud components, write HTML, copy assets. Produces `List(Post(msg))`.
/// 5. Render static pages from configured routes.
/// 6. Generate RSS feeds via webls.
/// 7. Generate sitemap XML via webls.
pub fn build(config: config.Config(msg)) -> Result(Nil, error.BlogattoError) {
  // Step 1: Clean output directory, and create output directory.
  // Ignore Enoent so the first build works when the output directory
  // does not yet exist.
  use _ <- result.try(case simplifile.delete(config.output_dir) {
    Ok(Nil) -> Ok(Nil)
    Error(simplifile.Enoent) -> Ok(Nil)
    Error(err) -> Error(error.File(err))
  })
  use _ <- result.try(
    config.output_dir
    |> simplifile.create_directory()
    |> result.map_error(error.File),
  )
  // Step 2: Copy static assets.
  use _ <- result.try(static.build(config))
  // Step 3: Generate robots.txt.
  use _ <- result.try(robots.build(config))
  // Step 4: Render blog posts.
  use posts <- result.try(blog.build(config))
  // Step 5: Render static pages.
  use _ <- result.try(pages.build(config, posts))
  // Step 6: Generate RSS feed.
  let max_excerpt_len = max_excerpt_len(config.feeds)
  let feed_metadata = feed_metadata(posts, max_excerpt_len)
  use _ <- result.try(feed.build(config.output_dir, config.feeds, feed_metadata))
  // Step 7: Generate sitemap.xml.
  use _ <- result.try(sitemap_build(config, posts))

  Ok(Nil)
}

/// Find the largest `excerpt_len` across all configured feeds so we know
/// how much text to extract from each post body.
fn max_excerpt_len(feeds: List(feed_config.FeedConfig(msg))) -> Int {
  list.fold(feeds, 0, fn(acc, f) { int.max(acc, f.excerpt_len) })
}

/// Transform the list of blog posts into the metadata format needed for
/// feed generation. The excerpt is extracted from the rendered post body
/// as plain text (HTML tags stripped), limited to `max_len` characters.
fn feed_metadata(
  posts: List(post.Post(msg)),
  max_len: Int,
) -> List(feed_config.FeedMetadata(msg)) {
  list.map(posts, fn(p) {
    let path =
      uri.parse(p.url)
      |> result.map(fn(u) { u.path })
      |> result.unwrap(or: p.url)
    let excerpt = excerpt.extract(p.contents, max_len)
    feed_config.FeedMetadata(path:, excerpt:, post: p, url: p.url)
  })
}

// Build the sitemap by collecting static routes and blog post URLs,
// then delegating to the sitemap builder.
fn sitemap_build(
  config: config.Config(msg),
  posts: List(post.Post(msg)),
) -> Result(Nil, error.BlogattoError) {
  case config.sitemap {
    option.None -> Ok(Nil)
    option.Some(sitemap_config) -> {
      use base_uri <- result.try(
        uri.parse(config.site_url)
        |> result.replace_error(error.InvalidUri(config.site_url)),
      )
      use routes <- result.try(
        config.routes
        |> dict.keys()
        |> list.try_map(fn(route) {
          uri.parse(route)
          |> result.try(fn(relative) { uri.merge(base_uri, relative) })
          |> result.map(uri.to_string)
          |> result.replace_error(error.InvalidUri(route))
        }),
      )
      let blog_routes =
        posts
        |> list.map(fn(p) { p.url })

      let routes = list.append(routes, blog_routes)
      let build = sitemap.SitemapBuild(config: sitemap_config, routes: routes)
      sitemap.build(config.output_dir, config.site_url, build)
    }
  }
}
