import blogatto/config/robots.{Robot}
import gleeunit/should

pub fn new_sets_sitemap_url_test() {
  let cfg = robots.new("https://example.com/sitemap.xml")
  cfg.sitemap_url
  |> should.equal("https://example.com/sitemap.xml")
}

pub fn new_has_empty_robots_list_test() {
  let cfg = robots.new("https://example.com/sitemap.xml")
  cfg.robots
  |> should.equal([])
}

pub fn robot_prepends_crawl_policy_test() {
  let bot =
    Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: ["/admin/"])
  let cfg =
    robots.new("https://example.com/sitemap.xml")
    |> robots.robot(bot)

  cfg.robots
  |> should.equal([bot])
}

pub fn robot_prepends_multiple_policies_test() {
  let bot1 =
    Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: ["/admin/"])
  let bot2 =
    Robot(
      user_agent: "googlebot",
      allowed_routes: ["/", "/blog/"],
      disallowed_routes: [],
    )
  let cfg =
    robots.new("https://example.com/sitemap.xml")
    |> robots.robot(bot1)
    |> robots.robot(bot2)

  // bot2 was prepended last, so it comes first
  cfg.robots
  |> should.equal([bot2, bot1])
}

pub fn robot_preserves_sitemap_url_test() {
  let bot = Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: [])
  let cfg =
    robots.new("https://example.com/sitemap.xml")
    |> robots.robot(bot)

  cfg.sitemap_url
  |> should.equal("https://example.com/sitemap.xml")
}
