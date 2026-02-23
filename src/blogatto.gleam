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
import blogatto/post
import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/uri
import simplifile

/// Build the static site based on the provided configuration.
/// 
/// ## Build steps
/// 
/// 1. Clean output directory and create output directory. This ensures a fresh build each time, preventing stale files from previous builds from lingering in the output directory. It's a simple file operation but crucial for ensuring that the build process produces consistent results. No parsing or rendering involved, just file system operations to manage the output directory.
/// 2. builder/robots — Generate robots.txt via webls. Simplest builder: no parsing, no post dependencies, just config-to-file. Good warm-up to establish the builder module pattern.
/// 3. builder/static - Copy static assets from the configured static_dir to the output directory. This is a straightforward file operation, but it's important to do it early in the build process to ensure that any static files needed by pages or posts are available when those builders run. No parsing or rendering involved, just copying files while preserving directory structure.
/// 4. builder/pages — Render static routes to HTML. Still straightforward: iterate config.routes, call each view function, render with Lustre, write files. No markdown parsing involved.
/// 5. builder/blog — The heavy one. Walk markdown paths, discover post directories, parse frontmatter, render markdown via Maud components, construct Post(msg) values, write HTML pages, copy
/// non-markdown assets. This produces the List(Post(msg)) that feeds and sitemap both need.
/// 6. builder/feed — Generate RSS feeds via webls. Depends on the post list from step. Apply filter/serialize, render with Lustre, write XML file.
/// 7. builder/sitemap — Generate sitemap XML via webls. Depends on both static routes and blog posts being known.
pub fn build(config: config.Config(msg)) -> Result(Nil, error.BlogattoError) {
  // Step 1: Clean output directory, and create output directory
  use _ <- result.try(
    config.output_dir
    |> simplifile.delete()
    |> result.map_error(error.File),
  )
  use _ <- result.try(
    config.output_dir
    |> simplifile.create_directory()
    |> result.map_error(error.File),
  )
  // Step 2: Copy static assets.
  use _ <- result.try(static.build(config))
  // Step 3: Generate robots.txt.
  use _ <- result.try(robots.build(config))
  // Step 4: Render static pages.
  use _ <- result.try(pages.build(config, []))
  // Step 5: Render blog posts.
  use posts <- result.try(blog.build(config))
  // Step 6: Generate RSS feed.
  let feed_metadata = feed_metadata(posts)
  use _ <- result.try(feed.build(config.output_dir, config.feeds, feed_metadata))
  // Step 7: Generate sitemap.xml.
  use _ <- result.try(sitemap_build(config, posts))

  Ok(Nil)
}

/// Transform the list of blog posts into the metadata format needed for feed generation. This involves extracting relevant information from each post, such as title, URL, publication date, and any other fields that the feed configuration's serialize function might require. The resulting List(FeedMetadata) will be used by the feed builder to generate the RSS feed items.
fn feed_metadata(
  posts: List(post.Post(msg)),
) -> List(feed_config.FeedMetadata(msg)) {
  list.map(posts, fn(p) {
    let path =
      uri.parse(p.url)
      |> result.map(fn(u) { u.path })
      |> result.unwrap(or: p.url)
    feed_config.FeedMetadata(
      path: path,
      excerpt: p.description,
      post: p,
      url: p.url,
    )
  })
}

/// Construct the `SitemapBuild` data structure needed for sitemap generation. This involves taking the overall site configuration and the list of blog posts, and packaging them into a format that the sitemap builder can work with. The `SitemapBuild` type is designed to hold all necessary information for generating the sitemap, including any filter or serialize functions from the config, as well as the list of routes that should be included in the sitemap (which would typically be derived from both static pages and blog posts).
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
