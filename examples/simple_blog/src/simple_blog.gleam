//// A simple blog example demonstrating the full Blogatto build pipeline.
////
//// Builds a static blog with a homepage listing articles, two markdown
//// blog posts, an RSS feed, a sitemap, and a robots.txt file.
////
//// Run with `gleam run` from the `examples/simple_blog` directory.

import blogatto
import blogatto/config
import blogatto/config/feed
import blogatto/config/markdown
import blogatto/config/robots
import blogatto/config/sitemap
import blogatto/error
import blogatto/post.{type Post}
import gleam/io
import gleam/list
import gleam/option
import gleam/time/timestamp
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

const site_url = "https://example.com"

pub fn main() {
  // Markdown configuration: search the blog/ directory for posts
  let md_config =
    markdown.default()
    |> markdown.markdown_path("./blog")
    |> markdown.route_prefix("blog")
    |> markdown.template(blog_post_template)

  // RSS feed configuration
  let rss =
    feed.new(
      "Simple Blog",
      site_url,
      "A simple example blog built with Blogatto",
    )
    |> feed.language("en-us")
    |> feed.generator("Blogatto")

  // Sitemap configuration
  let sitemap_config = sitemap.new("/sitemap.xml")

  // Robots.txt configuration
  let robots_config =
    robots.RobotsConfig(sitemap_url: site_url <> "/sitemap.xml", robots: [
      robots.Robot(
        user_agent: "*",
        allowed_routes: ["/"],
        disallowed_routes: [],
      ),
    ])

  // Build the full site configuration
  let cfg =
    config.new(site_url)
    |> config.output_dir("./dist")
    |> config.markdown(md_config)
    |> config.route("/", home_view)
    |> config.feed(rss)
    |> config.sitemap(sitemap_config)
    |> config.robots(robots_config)

  // Build the site
  case blogatto.build(cfg) {
    Ok(Nil) -> io.println("Site built successfully in ./dist")
    Error(err) -> io.println("Build failed: " <> error.describe_error(err))
  }
}

/// Home page view: renders a header and a list of all blog posts
/// sorted by date (newest first).
fn home_view(posts: List(Post(Nil))) -> Element(Nil) {
  // Sort posts newest first by comparing dates in reverse
  let sorted_posts =
    list.sort(posts, fn(a, b) { timestamp.compare(b.date, a.date) })

  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.title([], "Simple Blog"),
    ]),
    html.body([], [
      html.header([], [
        html.h1([], [element.text("Simple Blog")]),
        html.p([], [
          element.text("A simple example blog built with Blogatto."),
        ]),
      ]),
      html.main([], [
        html.h2([], [element.text("Articles")]),
        html.ul(
          [],
          list.map(sorted_posts, fn(p) {
            html.li([], [
              html.a([attribute.href("/blog/" <> p.slug)], [
                element.text(p.title),
              ]),
              element.text(" — "),
              html.em([], [element.text(p.description)]),
            ])
          }),
        ),
      ]),
      html.footer([], [
        html.p([], [
          element.text("Built with "),
          html.a([attribute.href("https://github.com/veeso/blogatto")], [
            element.text("Blogatto"),
          ]),
        ]),
      ]),
    ]),
  ])
}

/// Blog post template: renders a full HTML page for a single blog post
/// with a navigation link back to the homepage.
fn blog_post_template(p: Post(Nil)) -> Element(Nil) {
  let lang = option.unwrap(p.language, "en")

  html.html([attribute.lang(lang)], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.title([], p.title),
      html.meta([
        attribute.name("description"),
        attribute.content(p.description),
      ]),
    ]),
    html.body([], [
      html.header([], [
        html.nav([], [
          html.a([attribute.href("/")], [element.text("← Home")]),
        ]),
      ]),
      html.main([], [
        html.article([], [
          html.h1([], [element.text(p.title)]),
          html.p([], [html.em([], [element.text(p.description)])]),
          html.div([], p.contents),
        ]),
      ]),
      html.footer([], [
        html.p([], [
          element.text("Built with "),
          html.a([attribute.href("https://github.com/veeso/blogatto")], [
            element.text("Blogatto"),
          ]),
        ]),
      ]),
    ]),
  ])
}
