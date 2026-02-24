//// Configuration for generating the XML sitemap.
////
//// When a `SitemapConfig` is provided to the main `Config`, the build pipeline
//// collects all routes (both static pages and blog posts) and generates a
//// sitemap XML file. The optional `filter` and `serialize` functions allow
//// controlling which routes appear and how they are represented.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config/sitemap
////
//// let cfg =
////   sitemap.new("/sitemap.xml")
////   |> sitemap.filter(fn(url) { url != "/admin" })
//// ```

import gleam/option.{type Option, None, Some}
import gleam/time/timestamp.{type Timestamp}

/// Configuration for sitemap XML generation.
///
/// The `filter` function excludes routes by path. The `serialize` function
/// converts a route path into a `SitemapEntry` with priority, change frequency,
/// and optional alternate language links. The sitemap's absolute URL is derived
/// from `Config.site_url` combined with `path` at build time.
pub type SitemapConfig {
  SitemapConfig(
    /// Optional predicate to include or exclude routes from the sitemap.
    filter: Option(fn(String) -> Bool),
    /// Optional function to convert a route path into a sitemap entry.
    serialize: Option(fn(String) -> SitemapEntry),
    /// Output file path for the sitemap, relative to `output_dir` (e.g., `"/sitemap.xml"`).
    path: String,
  )
}

// --- Builder API ---

/// Create a new `SitemapConfig` with the given output path.
///
/// All optional fields receive sensible defaults (`None`). Use the setter
/// functions to customize them via piping.
pub fn new(path: String) -> SitemapConfig {
  SitemapConfig(filter: None, serialize: None, path:)
}

/// Set the predicate used to include or exclude routes from the sitemap.
pub fn filter(config: SitemapConfig, f: fn(String) -> Bool) -> SitemapConfig {
  SitemapConfig(..config, filter: Some(f))
}

/// Set the function used to convert a route path into a sitemap entry.
pub fn serialize(
  config: SitemapConfig,
  f: fn(String) -> SitemapEntry,
) -> SitemapConfig {
  SitemapConfig(..config, serialize: Some(f))
}

/// Set the output file path for the sitemap, relative to `output_dir`.
pub fn path(config: SitemapConfig, path: String) -> SitemapConfig {
  SitemapConfig(..config, path:)
}

/// A single entry in the sitemap XML.
pub type SitemapEntry {
  SitemapEntry(
    /// The full URL for this sitemap entry.
    url: String,
    /// Priority hint for search engines, between `0.0` and `1.0`.
    priority: Option(Float),
    /// Optional timestamp of the last modification of this page.
    last_modified: Option(Timestamp),
    /// Optional hint for how frequently this page changes.
    change_frequency: Option(ChangeFrequency),
  )
}

/// How frequently a page is likely to change.
///
/// Used as a hint for search engine crawlers.
pub type ChangeFrequency {
  /// The page changes every time it is accessed.
  Always
  /// The page changes approximately every hour.
  Hourly
  /// The page changes approximately every day.
  Daily
  /// The page changes approximately every week.
  Weekly
  /// The page changes approximately every month.
  Monthly
  /// The page changes approximately every year.
  Yearly
  /// The page is archived and will not change again.
  Never
}
