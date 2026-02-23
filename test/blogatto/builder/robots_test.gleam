import blogatto/config
import blogatto/config/robots.{type RobotsConfig, Robot, RobotsConfig}
import blogatto/error
import blogatto/internal/builder/robots as robots_builder
import gleam/string
import gleeunit/should
import simplifile
import temporary

fn make_config(
  output_dir: String,
  robots_cfg: RobotsConfig,
) -> config.Config(msg) {
  config.new("https://example.com")
  |> config.output_dir(output_dir)
  |> config.robots(robots_cfg)
}

pub fn build_writes_robots_txt_file_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
      ])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    simplifile.is_file(dir <> "/robots.txt")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_includes_sitemap_url_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
      ])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
    content
    |> string.contains("Sitemap: https://example.com/sitemap.xml")
    |> should.be_true
  }
}

pub fn build_includes_user_agent_directive_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(
          user_agent: "googlebot",
          allowed_routes: ["/"],
          disallowed_routes: [],
        ),
      ])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
    content
    |> string.contains("User-agent: googlebot")
    |> should.be_true
  }
}

pub fn build_includes_allowed_routes_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(
          user_agent: "*",
          allowed_routes: ["/", "/blog/"],
          disallowed_routes: [],
        ),
      ])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
    content
    |> string.contains("Allow: /")
    |> should.be_true
    content
    |> string.contains("Allow: /blog/")
    |> should.be_true
  }
}

pub fn build_includes_disallowed_routes_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: [], disallowed_routes: [
          "/admin/",
          "/private/",
        ]),
      ])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
    content
    |> string.contains("Disallow: /admin/")
    |> should.be_true
    content
    |> string.contains("Disallow: /private/")
    |> should.be_true
  }
}

pub fn build_handles_multiple_robots_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
        Robot(
          user_agent: "googlebot",
          allowed_routes: ["/", "/blog/"],
          disallowed_routes: ["/admin/"],
        ),
      ])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
    content
    |> string.contains("User-agent: *")
    |> should.be_true
    content
    |> string.contains("User-agent: googlebot")
    |> should.be_true
  }
}

pub fn build_handles_empty_robots_list_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [])

    robots_builder.build(make_config(dir, cfg))
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/robots.txt")
    // Should still contain the sitemap directive
    content
    |> string.contains("Sitemap: https://example.com/sitemap.xml")
    |> should.be_true
  }
}

pub fn build_skips_when_no_robots_config_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      config.new("https://example.com")
      |> config.output_dir(dir)

    robots_builder.build(cfg)
    |> should.be_ok

    simplifile.is_file(dir <> "/robots.txt")
    |> should.be_ok
    |> should.be_false
  }
}

pub fn build_returns_file_error_for_missing_directory_test() {
  let cfg =
    RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
      Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
    ])

  let result =
    robots_builder.build(make_config("./nonexistent_dir_robots_test", cfg))

  result
  |> should.be_error

  let assert Error(error.File(_)) = result
}
