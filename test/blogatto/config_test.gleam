import blogatto/config
import blogatto/config/feed
import blogatto/config/markdown
import blogatto/config/robots
import blogatto/config/sitemap
import gleam/dict
import gleam/option.{None, Some}
import gleeunit/should
import lustre/element/html

fn sample_feed_config() -> feed.FeedConfig(msg) {
  feed.FeedConfig(
    excerpt_len: 200,
    filter: None,
    output: "/rss.xml",
    serialize: None,
    title: "My Blog",
    link: "https://example.com",
    description: "A sample blog",
    language: None,
    copyright: None,
    managing_editor: None,
    web_master: None,
    pub_date: None,
    last_build_date: None,
    categories: [],
    generator: None,
    docs: None,
    cloud: None,
    ttl: None,
    image: None,
    text_input: None,
    skip_hours: [],
    skip_days: [],
  )
}

pub fn new_sets_site_url_test() {
  let cfg = config.new("https://example.com")
  cfg.site_url
  |> should.equal("https://example.com")
}

pub fn new_has_empty_feeds_test() {
  let cfg = config.new("https://example.com")
  cfg.feeds
  |> should.equal([])
}

pub fn new_has_no_markdown_config_test() {
  let cfg = config.new("https://example.com")
  cfg.markdown_config
  |> should.equal(None)
}

pub fn new_has_default_output_dir_test() {
  let cfg = config.new("https://example.com")
  cfg.output_dir
  |> should.equal("./dist")
}

pub fn new_has_no_robots_test() {
  let cfg = config.new("https://example.com")
  cfg.robots
  |> should.equal(None)
}

pub fn new_has_empty_routes_test() {
  let cfg = config.new("https://example.com")
  cfg.routes
  |> dict.size
  |> should.equal(0)
}

pub fn new_has_no_sitemap_test() {
  let cfg = config.new("https://example.com")
  cfg.sitemap
  |> should.equal(None)
}

pub fn new_has_no_static_dir_test() {
  let cfg = config.new("https://example.com")
  cfg.static_dir
  |> should.equal(None)
}

pub fn feed_prepends_feed_config_test() {
  let fc = sample_feed_config()
  let cfg =
    config.new("https://example.com")
    |> config.feed(fc)

  cfg.feeds
  |> should.equal([fc])
}

pub fn feed_prepends_multiple_feeds_test() {
  let feed1 =
    feed.FeedConfig(
      ..sample_feed_config(),
      output: "/rss.xml",
      title: "English",
    )
  let feed2 =
    feed.FeedConfig(
      ..sample_feed_config(),
      excerpt_len: 150,
      output: "/rss-it.xml",
      title: "Italian",
    )
  let cfg =
    config.new("https://example.com")
    |> config.feed(feed1)
    |> config.feed(feed2)

  // feed2 was prepended last, so it comes first
  cfg.feeds
  |> should.equal([feed2, feed1])
}

pub fn markdown_sets_markdown_config_test() {
  let md = markdown.default()
  let cfg =
    config.new("https://example.com")
    |> config.markdown(md)

  cfg.markdown_config
  |> should.be_some
}

pub fn output_dir_sets_output_directory_test() {
  let cfg =
    config.new("https://example.com")
    |> config.output_dir("./build")

  cfg.output_dir
  |> should.equal("./build")
}

pub fn robots_sets_robots_config_test() {
  let robots_cfg = robots.new("https://example.com/sitemap.xml")
  let cfg =
    config.new("https://example.com")
    |> config.robots(robots_cfg)

  cfg.robots
  |> should.equal(Some(robots_cfg))
}

pub fn route_adds_route_to_dict_test() {
  let view = fn() { html.div([], []) }
  let cfg =
    config.new("https://example.com")
    |> config.route("/about", view)

  cfg.routes
  |> dict.has_key("/about")
  |> should.be_true
}

pub fn route_adds_multiple_routes_test() {
  let cfg =
    config.new("https://example.com")
    |> config.route("/about", fn() { html.div([], []) })
    |> config.route("/contact", fn() { html.div([], []) })

  cfg.routes
  |> dict.size
  |> should.equal(2)
}

pub fn route_view_produces_expected_element_test() {
  let view = fn() { html.p([], [html.text("hello")]) }
  let cfg =
    config.new("https://example.com")
    |> config.route("/about", view)

  let assert Ok(route_view) = dict.get(cfg.routes, "/about")
  route_view()
  |> should.equal(html.p([], [html.text("hello")]))
}

pub fn sitemap_sets_sitemap_config_test() {
  let sm =
    sitemap.SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")
  let cfg =
    config.new("https://example.com")
    |> config.sitemap(sm)

  cfg.sitemap
  |> should.equal(Some(sm))
}

pub fn static_dir_sets_static_directory_test() {
  let cfg =
    config.new("https://example.com")
    |> config.static_dir("./static")

  cfg.static_dir
  |> should.equal(Some("./static"))
}

pub fn route_overwrites_duplicate_key_test() {
  let view1 = fn() { html.p([], [html.text("first")]) }
  let view2 = fn() { html.p([], [html.text("second")]) }
  let cfg =
    config.new("https://example.com")
    |> config.route("/about", view1)
    |> config.route("/about", view2)

  cfg.routes |> dict.size |> should.equal(1)
  let assert Ok(route_view) = dict.get(cfg.routes, "/about")
  route_view()
  |> should.equal(html.p([], [html.text("second")]))
}

pub fn builder_pipeline_preserves_all_settings_test() {
  let md = markdown.default()
  let robots_cfg = robots.new("https://example.com/sitemap.xml")
  let sm =
    sitemap.SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")
  let feed_cfg = feed.FeedConfig(..sample_feed_config(), title: "Blog")

  let cfg =
    config.new("https://example.com")
    |> config.output_dir("./build")
    |> config.static_dir("./static")
    |> config.markdown(md)
    |> config.robots(robots_cfg)
    |> config.sitemap(sm)
    |> config.feed(feed_cfg)
    |> config.route("/about", fn() { html.div([], []) })

  cfg.site_url |> should.equal("https://example.com")
  cfg.output_dir |> should.equal("./build")
  cfg.static_dir |> should.equal(Some("./static"))
  cfg.markdown_config |> should.be_some
  cfg.robots |> should.equal(Some(robots_cfg))
  cfg.sitemap |> should.equal(Some(sm))
  cfg.feeds |> should.equal([feed_cfg])
  cfg.routes |> dict.size |> should.equal(1)
}
