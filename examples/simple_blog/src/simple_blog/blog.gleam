//// A simple blog example demonstrating the full Blogatto build pipeline.
////
//// Builds a static blog with a homepage listing articles, two markdown
//// blog posts, an RSS feed, an Atom feed, a sitemap, and a robots.txt file.
////
//// Run with `gleam run` from the `examples/simple_blog` directory.

import blogatto/config
import blogatto/config/feed/atom
import blogatto/config/feed/rss
import blogatto/config/post as post_cfg
import blogatto/config/post/code
import blogatto/config/robots
import blogatto/config/sitemap
import blogatto/post.{type Post}
import gleam/dict
import gleam/list
import gleam/option
import gleam/time/timestamp
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import smalto/lustre/themes

const site_url = "https://example.com"

pub fn config() -> config.Config(Nil) {
  // Syntax highlighting configuration using CSS classes
  let syntax_config =
    code.default()
    |> code.smalto_config(themes.material_light())

  // Post configuration: search the blog/ directory for posts
  let post_config =
    post_cfg.default()
    |> post_cfg.path("./blog")
    |> post_cfg.route_prefix("blog")
    |> post_cfg.template(blog_post_template)
    |> post_cfg.syntax_highlighting(syntax_config)
    |> post_cfg.pre(fn(_attributes, children) {
      html.pre([attribute.class("code-block")], children)
    })
    |> post_cfg.code(fn(attributes, language, children) {
      let lang_class = case language {
        option.Some(lang) -> "language-" <> lang
        option.None -> ""
      }
      // Djot lets an author annotate a fenced code block, e.g.
      // ` ```gleam {title="hello.gleam"} `. When a title is present we render a
      // caption above the code; otherwise we fall back to a bare `<code>`.
      case dict.get(attributes, "title") {
        Ok(title) ->
          html.figure([attribute.class("code-figure")], [
            html.figcaption([], [element.text(title)]),
            html.code([attribute.class(lang_class)], children),
          ])
        Error(_) -> html.code([attribute.class(lang_class)], children)
      }
    })
    |> post_cfg.blockquote(fn(attributes, children) {
      // A blockquote annotated with `{.pull}` in djot becomes a pull-quote;
      // any other blockquote keeps the default styling. Before block
      // attributes were exposed this required content sniffing.
      let class = case dict.get(attributes, "class") {
        Ok("pull") -> "blockquote pull-quote"
        _ -> "blockquote"
      }
      html.blockquote([attribute.class(class)], children)
    })

  // RSS feed configuration
  let rss_feed =
    rss.new(
      "Simple Blog",
      site_url,
      "A simple example blog built with Blogatto",
    )
    |> rss.language("en-us")
    |> rss.generator("Blogatto")

  // Atom feed configuration
  let atom_feed =
    atom.new(
      id: site_url <> "/",
      title: atom.PlainText("Simple Blog"),
      updated: timestamp.system_time(),
    )
    |> atom.subtitle("A simple example blog built with Blogatto")
    |> atom.link(atom.Link(
      href: site_url <> "/atom.xml",
      rel: option.Some("self"),
      content_type: option.Some("application/atom+xml"),
      hreflang: option.None,
      title: option.None,
      length: option.None,
    ))
    |> atom.generator(atom.Generator(
      uri: option.Some("https://github.com/veeso/blogatto"),
      version: option.None,
    ))

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

  config.new(site_url)
  |> config.output_dir("./dist")
  |> config.post(post_config)
  |> config.route("/", home_view)
  |> config.rss_feed(rss_feed)
  |> config.atom_feed(atom_feed)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
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
              html.a([attribute.href("/blog/" <> p.slug <> "/")], [
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
fn blog_post_template(
  p: Post(Nil),
  _all_posts: List(Post(Nil)),
) -> Element(Nil) {
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
