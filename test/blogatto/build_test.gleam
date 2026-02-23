import blogatto
import blogatto/config
import blogatto/config/feed.{type FeedConfig, FeedConfig}
import blogatto/config/markdown
import blogatto/config/robots.{Robot, RobotsConfig}
import blogatto/config/sitemap.{SitemapConfig}
import blogatto/error
import blogatto/post
import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/string
import gleeunit/should
import lustre/element
import lustre/element/html
import simplifile
import temporary

// --- Helpers ---

fn markdown_content(
  title: String,
  slug: String,
  date: String,
  description: String,
  body: String,
) -> String {
  "---\ntitle: "
  <> title
  <> "\nslug: "
  <> slug
  <> "\ndate: "
  <> date
  <> "\ndescription: "
  <> description
  <> "\n---\n"
  <> body
}

fn sample_markdown() -> String {
  markdown_content(
    "Hello World",
    "hello-world",
    "2024-01-15 10:00:00",
    "A test post",
    "# Hello\n\nThis is a test post.\n",
  )
}

fn create_post_dir(blog_dir: String, slug: String) -> String {
  let post_dir = blog_dir <> "/" <> slug
  let assert Ok(_) = simplifile.create_directory_all(post_dir)
  post_dir
}

fn write_markdown(dir: String, filename: String, content: String) -> Nil {
  let assert Ok(_) = simplifile.write(dir <> "/" <> filename, content)
  Nil
}

fn minimal_config(output_dir: String) -> config.Config(msg) {
  config.new("https://example.com")
  |> config.output_dir(output_dir)
}

fn config_with_blog(output_dir: String, blog_dir: String) -> config.Config(msg) {
  let md_config =
    markdown.default()
    |> markdown.markdown_path(blog_dir)

  config.new("https://example.com")
  |> config.output_dir(output_dir)
  |> config.markdown(md_config)
}

fn minimal_feed_config(output: String) -> FeedConfig(msg) {
  FeedConfig(
    excerpt_len: 200,
    filter: None,
    output: output,
    serialize: None,
    title: "My Blog",
    link: "https://example.com",
    description: "A test blog",
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

fn simple_view(_posts: List(post.Post(msg))) -> element.Element(msg) {
  html.div([], [html.text("Hello, page!")])
}

fn posts_counting_view(posts: List(post.Post(msg))) -> element.Element(msg) {
  let count = list.length(posts) |> int.to_string
  html.div([], [html.text("post-count:" <> count)])
}

// --- Output directory management ---

pub fn build_with_minimal_config_succeeds_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok
  }
}

pub fn build_creates_output_directory_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_directory(output)
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_cleans_existing_output_directory_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"
    let assert Ok(_) = simplifile.create_directory(output)
    let assert Ok(_) = simplifile.write(output <> "/stale.txt", "old content")

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/stale.txt")
    |> should.be_ok
    |> should.be_false
  }
}

pub fn build_succeeds_when_output_dir_does_not_preexist_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/fresh-output"

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_directory(output)
    |> should.be_ok
    |> should.be_true
  }
}

// --- Static assets (step 2) ---

pub fn build_copies_static_assets_to_output_dir_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use static_src <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let assert Ok(_) =
      simplifile.write(static_src <> "/style.css", "body { color: red; }")

    minimal_config(output)
    |> config.static_dir(static_src)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/style.css")
    |> should.be_ok
    |> should.be_true

    simplifile.read(output <> "/style.css")
    |> should.be_ok
    |> should.equal("body { color: red; }")
  }
}

pub fn build_copies_nested_static_structure_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use static_src <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let assert Ok(_) = simplifile.create_directory_all(static_src <> "/css")
    let assert Ok(_) =
      simplifile.write(static_src <> "/css/main.css", "css-content")

    minimal_config(output)
    |> config.static_dir(static_src)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/css/main.css")
    |> should.be_ok
    |> should.be_true
  }
}

// --- Robots.txt (step 3) ---

pub fn build_generates_robots_txt_when_configured_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let robots_cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
      ])

    minimal_config(output)
    |> config.robots(robots_cfg)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/robots.txt")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_robots_txt_contains_expected_content_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let robots_cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
      ])

    minimal_config(output)
    |> config.robots(robots_cfg)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/robots.txt")
    content
    |> string.contains("Sitemap: https://example.com/sitemap.xml")
    |> should.be_true
    content
    |> string.contains("User-agent: *")
    |> should.be_true
  }
}

pub fn build_skips_robots_txt_when_not_configured_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/robots.txt")
    |> should.be_ok
    |> should.be_false
  }
}

// --- Blog posts (step 4) ---

pub fn build_renders_blog_posts_to_html_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    config_with_blog(output, blog)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/hello-world/index.html")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_blog_html_contains_rendered_content_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    config_with_blog(output, blog)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) =
      simplifile.read(output <> "/hello-world/index.html")
    content |> string.contains("Hello") |> should.be_true
    content |> string.contains("This is a test post.") |> should.be_true
  }
}

pub fn build_without_markdown_config_produces_no_blog_files_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok

    // No blog post directories should exist
    simplifile.is_file(output <> "/hello-world/index.html")
    |> should.be_ok
    |> should.be_false
  }
}

pub fn build_renders_multiple_blog_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post1_dir = create_post_dir(blog, "first-post")
    write_markdown(
      post1_dir,
      "index.md",
      markdown_content(
        "First Post",
        "first-post",
        "2024-01-01 00:00:00",
        "The first",
        "# First\n",
      ),
    )

    let post2_dir = create_post_dir(blog, "second-post")
    write_markdown(
      post2_dir,
      "index.md",
      markdown_content(
        "Second Post",
        "second-post",
        "2024-02-01 00:00:00",
        "The second",
        "# Second\n",
      ),
    )

    config_with_blog(output, blog)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/first-post/index.html")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/second-post/index.html")
    |> should.be_ok
    |> should.be_true
  }
}

// --- Static pages (step 5) ---

pub fn build_renders_static_pages_from_routes_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> config.route("/", simple_view)
    |> config.route("/about", simple_view)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/index.html")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/about/index.html")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_static_page_contains_view_content_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> config.route("/", simple_view)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/index.html")
    content |> string.contains("Hello, page!") |> should.be_true
  }
}

pub fn build_page_view_receives_parsed_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "test-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Test Post",
        "test-post",
        "2024-01-01 00:00:00",
        "A test",
        "# Test\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.route("/", posts_counting_view)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/index.html")
    content |> string.contains("post-count:1") |> should.be_true
  }
}

pub fn build_page_view_receives_multiple_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post1_dir = create_post_dir(blog, "post-a")
    write_markdown(
      post1_dir,
      "index.md",
      markdown_content(
        "Post A",
        "post-a",
        "2024-01-01 00:00:00",
        "First",
        "# A\n",
      ),
    )

    let post2_dir = create_post_dir(blog, "post-b")
    write_markdown(
      post2_dir,
      "index.md",
      markdown_content(
        "Post B",
        "post-b",
        "2024-02-01 00:00:00",
        "Second",
        "# B\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.route("/", posts_counting_view)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/index.html")
    content |> string.contains("post-count:2") |> should.be_true
  }
}

// --- RSS feeds (step 6, tests feed_metadata indirectly) ---

pub fn build_generates_rss_feed_when_configured_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "feed-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Feed Post",
        "feed-post",
        "2024-01-15 10:00:00",
        "A post for RSS",
        "# Feed\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/rss.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_feed_contains_post_title_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "rss-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "RSS Post Title",
        "rss-post",
        "2024-03-01 12:00:00",
        "RSS description",
        "# Content\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/rss.xml")
    content
    |> string.contains("<title>RSS Post Title</title>")
    |> should.be_true
  }
}

pub fn build_feed_uses_post_url_as_link_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "url-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "URL Post",
        "url-post",
        "2024-04-01 08:00:00",
        "Testing URL",
        "# URL\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/rss.xml")
    content
    |> string.contains("<link>https://example.com/url-post</link>")
    |> should.be_true
  }
}

pub fn build_feed_uses_post_description_as_excerpt_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "excerpt-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Excerpt Post",
        "excerpt-post",
        "2024-05-01 09:00:00",
        "This is the post description",
        "# Content\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/rss.xml")
    content
    |> string.contains(
      "<description>This is the post description</description>",
    )
    |> should.be_true
  }
}

pub fn build_with_no_feeds_produces_no_rss_files_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "no-feed-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "No Feed",
        "no-feed-post",
        "2024-06-01 10:00:00",
        "No feed",
        "# Content\n",
      ),
    )

    config_with_blog(output, blog)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/rss.xml")
    |> should.be_ok
    |> should.be_false
  }
}

pub fn build_generates_multiple_feeds_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "multi-feed")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Multi Feed",
        "multi-feed",
        "2024-07-01 10:00:00",
        "Multiple feeds",
        "# Content\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> config.feed(minimal_feed_config("/feed.xml"))
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/rss.xml")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/feed.xml")
    |> should.be_ok
    |> should.be_true
  }
}

// --- Sitemap (step 7, tests sitemap_build indirectly) ---

pub fn build_generates_sitemap_when_configured_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    minimal_config(output)
    |> config.route("/", simple_view)
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/sitemap.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_sitemap_includes_static_routes_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    minimal_config(output)
    |> config.route("/", simple_view)
    |> config.route("/about", simple_view)
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/sitemap.xml")
    content
    |> string.contains("<loc>https://example.com/</loc>")
    |> should.be_true
    content
    |> string.contains("<loc>https://example.com/about</loc>")
    |> should.be_true
  }
}

pub fn build_sitemap_includes_blog_post_urls_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "sitemap-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Sitemap Post",
        "sitemap-post",
        "2024-07-01 11:00:00",
        "For sitemap",
        "# Sitemap\n",
      ),
    )

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    config_with_blog(output, blog)
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/sitemap.xml")
    content
    |> string.contains("<loc>https://example.com/sitemap-post</loc>")
    |> should.be_true
  }
}

pub fn build_sitemap_includes_both_routes_and_blog_urls_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "both-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Both Post",
        "both-post",
        "2024-08-01 12:00:00",
        "Both",
        "# Both\n",
      ),
    )

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    config_with_blog(output, blog)
    |> config.route("/about", simple_view)
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/sitemap.xml")
    content
    |> string.contains("<loc>https://example.com/about</loc>")
    |> should.be_true
    content
    |> string.contains("<loc>https://example.com/both-post</loc>")
    |> should.be_true
  }
}

pub fn build_skips_sitemap_when_not_configured_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    minimal_config(output)
    |> blogatto.build()
    |> should.be_ok

    simplifile.is_file(output <> "/sitemap.xml")
    |> should.be_ok
    |> should.be_false
  }
}

pub fn build_sitemap_contains_valid_xml_structure_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    minimal_config(output)
    |> config.route("/", simple_view)
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/sitemap.xml")
    content
    |> string.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    |> should.be_true
    content
    |> string.contains("<urlset")
    |> should.be_true
    content
    |> string.contains("</urlset>")
    |> should.be_true
  }
}

// --- Full integration ---

pub fn build_full_pipeline_with_all_features_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    use static_src <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    // Set up static assets
    let assert Ok(_) = simplifile.write(static_src <> "/style.css", "body{}")

    // Set up blog post
    let post_dir = create_post_dir(blog, "full-test")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Full Test",
        "full-test",
        "2024-09-01 14:00:00",
        "Full integration",
        "# Full\n",
      ),
    )

    // Build config with all features
    let robots_cfg =
      RobotsConfig(sitemap_url: "https://example.com/sitemap.xml", robots: [
        Robot(user_agent: "*", allowed_routes: ["/"], disallowed_routes: []),
      ])

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    let md_config =
      markdown.default()
      |> markdown.markdown_path(blog)

    config.new("https://example.com")
    |> config.output_dir(output)
    |> config.static_dir(static_src)
    |> config.markdown(md_config)
    |> config.robots(robots_cfg)
    |> config.route("/", simple_view)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    // Verify all artifacts
    simplifile.is_file(output <> "/style.css")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/robots.txt")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/full-test/index.html")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/index.html")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/rss.xml")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(output <> "/sitemap.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_full_pipeline_sitemap_has_all_urls_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "integrated-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Integrated Post",
        "integrated-post",
        "2024-10-01 15:00:00",
        "Integrated",
        "# Integrated\n",
      ),
    )

    let sitemap_cfg =
      SitemapConfig(filter: None, serialize: None, path: "/sitemap.xml")

    config_with_blog(output, blog)
    |> config.route("/", simple_view)
    |> config.route("/about", simple_view)
    |> config.sitemap(sitemap_cfg)
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/sitemap.xml")
    // Static routes
    content
    |> string.contains("<loc>https://example.com/</loc>")
    |> should.be_true
    content
    |> string.contains("<loc>https://example.com/about</loc>")
    |> should.be_true
    // Blog post URL
    content
    |> string.contains("<loc>https://example.com/integrated-post</loc>")
    |> should.be_true
  }
}

pub fn build_full_pipeline_feed_has_post_data_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "feed-int-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Feed Integration",
        "feed-int-post",
        "2024-11-01 16:00:00",
        "Feed integration desc",
        "# Feed\n",
      ),
    )

    config_with_blog(output, blog)
    |> config.feed(minimal_feed_config("/rss.xml"))
    |> blogatto.build()
    |> should.be_ok

    let assert Ok(content) = simplifile.read(output <> "/rss.xml")
    content
    |> string.contains("<title>Feed Integration</title>")
    |> should.be_true
    content
    |> string.contains("<link>https://example.com/feed-int-post</link>")
    |> should.be_true
    content
    |> string.contains("<description>Feed integration desc</description>")
    |> should.be_true
  }
}

// --- Error cases ---

pub fn build_returns_error_for_nonexistent_static_dir_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let result =
      minimal_config(output)
      |> config.static_dir("/tmp/nonexistent_blogatto_static_xyz")
      |> blogatto.build()

    result |> should.be_error

    let assert Error(error.File(_)) = result
    Nil
  }
}

pub fn build_returns_error_for_invalid_blog_markdown_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "bad-post")
    write_markdown(post_dir, "index.md", "# No frontmatter\n\nJust text.\n")

    let result =
      config_with_blog(output, blog)
      |> blogatto.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissing) = result
    Nil
  }
}

pub fn build_returns_error_for_missing_frontmatter_field_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())
    let output = dir <> "/output"

    let post_dir = create_post_dir(blog, "no-title")
    write_markdown(
      post_dir,
      "index.md",
      "---\nslug: no-title\ndate: 2024-01-01 00:00:00\ndescription: missing title\n---\n# Body\n",
    )

    let result =
      config_with_blog(output, blog)
      |> blogatto.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissingField("title")) = result
    Nil
  }
}

pub fn build_returns_error_for_invalid_output_dir_parent_test() {
  let result =
    minimal_config("/nonexistent_blogatto_test_xyz/parent/output")
    |> blogatto.build()

  result |> should.be_error

  let assert Error(error.File(_)) = result
}
