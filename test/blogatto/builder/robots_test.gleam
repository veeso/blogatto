import blogatto/config/robots.{Robot, RobotsConfig}
import blogatto/error
import blogatto/internal/builder/robots as robots_builder
import gleam/string
import gleeunit/should
import simplifile

const test_dir = "./test_output_robots"

fn with_test_dir(f: fn(String) -> Nil) -> Nil {
  let assert Ok(_) = simplifile.create_directory_all(test_dir)
  f(test_dir)
  let assert Ok(_) = simplifile.delete(test_dir)
  Nil
}

pub fn build_writes_robots_txt_file_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
    ])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  simplifile.is_file(dir <> "/robots.txt")
  |> should.be_ok
  |> should.be_true
}

pub fn build_includes_sitemap_url_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
    ])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
  content
  |> string.contains("Sitemap: https://example.com/sitemap.xml")
  |> should.be_true
}

pub fn build_includes_user_agent_directive_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(
        user_agent: "googlebot",
        allowed_routes: ["/"],
        disallowed_routes: [],
      ),
    ])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
  content
  |> string.contains("User-agent: googlebot")
  |> should.be_true
}

pub fn build_includes_allowed_routes_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(
        user_agent: "*",
        allowed_routes: ["/", "/blog/"],
        disallowed_routes: [],
      ),
    ])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
  content
  |> string.contains("Allow: /")
  |> should.be_true
  content
  |> string.contains("Allow: /blog/")
  |> should.be_true
}

pub fn build_includes_disallowed_routes_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(user_agent: "*", allowed_routes: [], disallowed_routes: [
        "/admin/",
        "/private/",
      ]),
    ])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
  content
  |> string.contains("Disallow: /admin/")
  |> should.be_true
  content
  |> string.contains("Disallow: /private/")
  |> should.be_true
}

pub fn build_handles_multiple_robots_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
      Robot(
        user_agent: "googlebot",
        allowed_routes: ["/", "/blog/"],
        disallowed_routes: ["/admin/"],
      ),
    ])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
  content
  |> string.contains("User-agent: *")
  |> should.be_true
  content
  |> string.contains("User-agent: googlebot")
  |> should.be_true
}

pub fn build_handles_empty_robots_list_test() {
  use dir <- with_test_dir
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [])

  robots_builder.build(dir, cfg)
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
  // Should still contain the sitemap directive
  content
  |> string.contains("Sitemap: https://example.com/sitemap.xml")
  |> should.be_true
}

pub fn build_returns_file_error_for_missing_directory_test() {
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
    ])

  let result = robots_builder.build("./nonexistent_dir_robots_test", cfg)

  result
  |> should.be_error

  let assert Error(error.File(_)) = result
}
