//// Configuration for generating the `robots.txt` file.
////
//// When a `RobotsConfig` is provided to the main `Config`, the build pipeline
//// generates a `robots.txt` file in the output directory using the `webls` library.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config/robots
////
//// let bot =
////   robots.Robot(
////     user_agent: "*",
////     allowed_routes: ["/"],
////     disallowed_routes: ["/admin/"],
////   )
////
//// let cfg =
////   robots.RobotsConfig(
////     sitemap_url: "https://example.com/sitemap.xml",
////     robots: [bot],
////   )
//// ```

import gleam/list

/// Configuration for `robots.txt` generation.
///
/// Contains the sitemap URL advertised to crawlers and a list of
/// per-user-agent crawl policies.
pub type RobotsConfig {
  RobotsConfig(
    /// The full URL of the sitemap for crawlers (e.g., `"https://example.com/sitemap.xml"`).
    sitemap_url: String,
    /// Crawl policies, one per user agent.
    robots: List(Robot),
  )
}

/// A crawl policy for a specific user agent.
///
/// Use `"*"` as the `user_agent` for a catch-all policy that applies
/// to all crawlers not matched by a more specific entry.
pub type Robot {
  Robot(
    /// The crawler user agent this policy applies to (e.g., `"*"`, `"googlebot"`).
    user_agent: String,
    /// URL paths the crawler is allowed to access (e.g., `["/", "/blog/"]`).
    allowed_routes: List(String),
    /// URL paths the crawler must not access (e.g., `["/admin/", "/private/"]`).
    disallowed_routes: List(String),
  )
}

/// Create a `RobotsConfig` with a sitemap URL and no crawl policies.
pub fn new(sitemap_url: String) -> RobotsConfig {
  RobotsConfig(sitemap_url: sitemap_url, robots: [])
}

/// Add a crawl policy for a user agent.
pub fn robot(config: RobotsConfig, robot: Robot) -> RobotsConfig {
  RobotsConfig(..config, robots: list.prepend(config.robots, robot))
}
