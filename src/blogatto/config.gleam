//// Main configuration module for Blogatto.
////
//// The `Config` type holds all settings needed to build a static blog site.
//// Use `new(site_url)` to create a configuration with the required base URL,
//// then pipe it through the builder functions to set up feeds, routes, posts,
//// sitemap, robots, and static assets.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config
//// import blogatto/config/post
////
//// let post_config =
////   post.default()
////   |> post.path("./blog")
////
//// let cfg =
////   config.new("https://example.com")
////   |> config.output_dir("./dist")
////   |> config.static_dir("./static")
////   |> config.post(post_config)
//// ```

import blogatto/config/feed/atom as atom_feed_config
import blogatto/config/feed/rss as rss_feed_config
import blogatto/config/post as post_config
import blogatto/config/robots
import blogatto/config/sitemap
import blogatto/post
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/element.{type Element}

/// Blogatto configuration. Contains everything needed to build a static blog site.
///
/// The generic `msg` type parameter threads the Lustre message type through
/// the configuration, enabling type-safe component and view definitions.
pub type Config(msg) {
  Config(
    /// Atom feeds to generate, each with its own filter/serialize/output settings.
    atom_feeds: List(atom_feed_config.AtomFeed(msg)),
    /// Output directory for the built site. Default: `"./dist"`.
    output_dir: String,
    /// Post configuration for rendering blog articles. When `None`, no blog posts are built.
    post_config: Option(post_config.PostConfig(msg)),
    /// Robots.txt configuration. When `None`, no robots.txt is generated.
    robots: Option(robots.RobotsConfig),
    /// Static routes mapping URL paths to view functions.
    /// Each view function receives the full list of blog posts, enabling pages
    /// that display recent posts, featured posts, or other post-based content.
    routes: Dict(String, fn(List(post.Post(msg))) -> Element(msg)),
    /// RSS feeds to generate, each with its own filter/serialize/output settings.
    rss_feeds: List(rss_feed_config.RssFeedConfig(msg)),
    /// The base URL of the site (e.g., `"https://example.com"`).
    /// Used to build absolute URLs for sitemaps, RSS feeds, and other outputs.
    site_url: String,
    /// Sitemap configuration. When `None`, no sitemap is generated.
    sitemap: Option(sitemap.SitemapConfig),
    /// Path to a static assets directory to copy into the output root.
    /// When `None`, no static assets are copied.
    static_dir: Option(String),
  )
}

/// Create a new `Config` with the given base URL for the site.
///
/// The `site_url` is required because it is used to produce absolute URLs
/// in sitemaps, RSS feeds, and robots.txt (e.g., `"https://example.com"`).
///
/// Use the builder functions to further configure feeds, routes, posts, and more.
pub fn new(site_url: String) -> Config(msg) {
  Config(
    atom_feeds: [],
    output_dir: "./dist",
    post_config: None,
    robots: None,
    routes: dict.new(),
    rss_feeds: [],
    site_url:,
    sitemap: None,
    static_dir: None,
  )
}

/// Add an Atom feed configuration to the build.
pub fn atom_feed(
  config: Config(msg),
  feed: atom_feed_config.AtomFeed(msg),
) -> Config(msg) {
  Config(..config, atom_feeds: list.prepend(config.atom_feeds, feed))
}

/// Set the post configuration for blog post rendering.
pub fn post(
  config: Config(msg),
  post_config: post_config.PostConfig(msg),
) -> Config(msg) {
  Config(..config, post_config: Some(post_config))
}

/// Set the output directory path for the built site.
pub fn output_dir(config: Config(msg), directory: String) -> Config(msg) {
  Config(..config, output_dir: directory)
}

/// Set the robots.txt configuration.
pub fn robots(config: Config(msg), robots: robots.RobotsConfig) -> Config(msg) {
  Config(..config, robots: Some(robots))
}

/// Add a static route mapping a URL path to a view function.
///
/// The view function receives the full list of blog posts parsed during the build,
/// allowing pages to display recent posts, featured posts, or other post-based content.
/// The route path maps to `{output_dir}/{route}/index.html`.
pub fn route(
  config: Config(msg),
  route: String,
  view: fn(List(post.Post(msg))) -> Element(msg),
) -> Config(msg) {
  Config(..config, routes: dict.insert(config.routes, route, view))
}

/// Add an RSS feed configuration to the build.
pub fn rss_feed(
  config: Config(msg),
  feed: rss_feed_config.RssFeedConfig(msg),
) -> Config(msg) {
  Config(..config, rss_feeds: list.prepend(config.rss_feeds, feed))
}

/// Set the sitemap generation configuration.
pub fn sitemap(
  config: Config(msg),
  sitemap: sitemap.SitemapConfig,
) -> Config(msg) {
  Config(..config, sitemap: Some(sitemap))
}

/// Set the path to a static assets directory.
///
/// During the build, the contents of this directory are copied
/// into the root of `output_dir`.
pub fn static_dir(config: Config(msg), directory: String) -> Config(msg) {
  Config(..config, static_dir: Some(directory))
}
