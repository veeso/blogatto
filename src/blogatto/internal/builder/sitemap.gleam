//// Internal builder for sitemap XML generation.
////
//// Collects all routes (static pages and blog posts), applies the
//// configured filter and serialize functions, and generates a
//// sitemap XML file via the `webls` library.

import blogatto/config/sitemap
import blogatto/error
import blogatto/internal/path
import gleam/list
import gleam/option
import gleam/result
import gleam/time/timestamp
import gleam/uri
import simplifile
import webls/sitemap as webls_sitemap

/// Data structure to hold all necessary information for sitemap generation.
pub type SitemapBuild {
  SitemapBuild(
    /// The sitemap configuration containing filter and serialize functions.
    config: sitemap.SitemapConfig,
    /// List of all the routes exposed by the site, including both static pages and blog posts.
    routes: List(String),
  )
}

/// Generate the sitemap XML file based on the provided configuration and site data.
pub fn build(
  output_dir: String,
  site_url: String,
  build: SitemapBuild,
) -> Result(Nil, error.BlogattoError) {
  let sitemap_file = path.join(output_dir, build.config.path)
  use sitemap_uri <- result.try(sitemap_url(site_url, build.config.path))

  // create full dir path for sitemap output
  use _ <- result.try(
    sitemap_file
    |> path.parent()
    |> simplifile.create_directory_all()
    |> result.map_error(error.File),
  )
  // generate sitemap items from all routes
  let items = sitemap_items(build.config, build.routes)

  // create and write sitemap to file
  let content =
    sitemap_uri
    |> webls_sitemap.sitemap()
    |> webls_sitemap.with_sitemap_last_modified(timestamp.system_time())
    |> webls_sitemap.with_sitemap_items(items)
    |> webls_sitemap.to_string()

  sitemap_file
  |> simplifile.write(content)
  |> result.map_error(error.File)
}

/// Generate a list of `webls_sitemap.SitemapItem` from the provided routes, applying the configured filter and serialize functions.
fn sitemap_items(
  config: sitemap.SitemapConfig,
  routes: List(String),
) -> List(webls_sitemap.SitemapItem) {
  let filter_fn = option.unwrap(config.filter, default_filter)
  let serialize_fn = option.unwrap(config.serialize, default_serialize)
  list.filter_map(routes, fn(route) {
    case filter_fn(route) {
      True ->
        Ok(
          route
          |> serialize_fn
          |> sitemap_entry_to_webls,
        )
      False -> Error(Nil)
    }
  })
}

/// Default filter function that includes all routes in the sitemap.
fn default_filter(_route: String) -> Bool {
  True
}

/// Default serialize function that converts a route string into a `sitemap.SitemapEntry` with default values for priority and no change frequency or alternate links.
fn default_serialize(route: String) -> sitemap.SitemapEntry {
  sitemap.SitemapEntry(
    url: route,
    priority: option.None,
    last_modified: option.None,
    change_frequency: option.None,
  )
}

/// Convert a `sitemap.SitemapEntry` into a `webls_sitemap.SitemapItem` for XML generation.
fn sitemap_entry_to_webls(
  entry: sitemap.SitemapEntry,
) -> webls_sitemap.SitemapItem {
  webls_sitemap.SitemapItem(
    loc: entry.url,
    last_modified: entry.last_modified,
    change_frequency: option.map(
      entry.change_frequency,
      sitemap_frequency_to_webls,
    ),
    priority: entry.priority,
  )
}

/// Convert the configured `sitemap.ChangeFrequency` into the corresponding `webls_sitemap.ChangeFrequency` for XML generation.
fn sitemap_frequency_to_webls(
  freq: sitemap.ChangeFrequency,
) -> webls_sitemap.ChangeFrequency {
  case freq {
    sitemap.Always -> webls_sitemap.Always
    sitemap.Hourly -> webls_sitemap.Hourly
    sitemap.Daily -> webls_sitemap.Daily
    sitemap.Weekly -> webls_sitemap.Weekly
    sitemap.Monthly -> webls_sitemap.Monthly
    sitemap.Yearly -> webls_sitemap.Yearly
    sitemap.Never -> webls_sitemap.Never
  }
}

/// Construct the full sitemap URL by merging the site URL with the sitemap path.
fn sitemap_url(
  site_url: String,
  sitemap_path: String,
) -> Result(String, error.BlogattoError) {
  use site_url <- result.try(parse_uri(site_url))
  use sitemap_relative <- result.try(parse_uri(sitemap_path))

  site_url
  |> uri.merge(sitemap_relative)
  |> result.map(uri.to_string)
  |> result.map_error(fn(_) {
    error.InvalidUri(
      uri.to_string(site_url) <> "/" <> uri.to_string(sitemap_relative),
    )
  })
}

/// Parse a URI string into a `uri.Uri` type, returning an error if the URI is invalid.
fn parse_uri(uri_str: String) -> Result(uri.Uri, error.BlogattoError) {
  uri_str
  |> uri.parse()
  |> result.map_error(fn(_) { error.InvalidUri(uri_str) })
}
