//// Configuration for generating the XML sitemap.
////
//// When a `SitemapConfig` is provided to the main `Config`, the build pipeline
//// collects all routes (both static pages and blog posts) and generates a
//// sitemap XML file. The optional `filter` and `serialize` functions allow
//// controlling which routes appear and how they are represented.
////
//// Multilingual blog posts automatically produce `SitemapLink` entries
//// with `hreflang` alternate links when language variants exist.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config/sitemap
////
//// let cfg =
////   sitemap.SitemapConfig(
////     filter: option.None,
////     serialize: option.None,
////     path: "/sitemap.xml",
////   )
//// ```

import gleam/option.{type Option}
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

/// A single entry in the sitemap XML.
pub type SitemapEntry {
  SitemapEntry(
    /// The full URL for this sitemap entry.
    url: String,
    /// Priority hint for search engines, between `0.0` and `1.0`.
    priority: Float,
    /// Optional timestamp of the last modification of this page.
    last_modified: Option(Timestamp),
    /// Optional hint for how frequently this page changes.
    change_frequency: Option(ChangeFrequency),
    /// Optional alternate language links for this URL.
    links: Option(List(SitemapLink)),
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

/// An alternate language link within a sitemap entry.
///
/// Used to declare `<xhtml:link rel="alternate" hreflang="..." href="..." />`
/// elements, connecting translated versions of the same page.
pub type SitemapLink {
  SitemapLink(
    /// Language code (e.g., `"it"`, `"en"`), or `None` for the default.
    lang: Option(String),
    /// The full URL for this language variant.
    url: String,
  )
}
