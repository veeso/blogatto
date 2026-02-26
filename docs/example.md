---
layout: default
title: Example blog
nav_order: 3
---

# Example blog

Blogatto ships with a complete working example at [`examples/simple_blog`](https://github.com/veeso/blogatto/tree/main/examples/simple_blog). This page walks through it step by step so you can see how all the pieces fit together.

## Project layout

```text
examples/simple_blog/
  src/
    simple_blog.gleam           # Build script
    simple_blog/
      blog.gleam                # Shared config
      dev.gleam                 # Dev server entrypoint
  blog/
    hello-world/
      index.md                  # Blog post
    getting-started/
      index.md                  # Blog post
  gleam.toml
```

## Dependencies

The example's `gleam.toml` pulls in Blogatto plus the standard library and Lustre:

```toml
name = "simple_blog"
version = "1.0.0"
target = "erlang"

[dependencies]
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
lustre = ">= 5.6.0 and < 6.0.0"
gleam_time = ">= 1.7.0 and < 2.0.0"
blogatto = ">= 1.0.0 and < 2.0.0"
```

## Build script

The build configuration lives in `src/simple_blog/blog.gleam` as a shared module, used by both the build script (`src/simple_blog.gleam`) and the dev server (`src/simple_blog/dev.gleam`).

### Markdown configuration

The markdown config tells Blogatto where to find posts and how to render them:

```gleam
let md_config =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.route_prefix("blog")
  |> markdown.template(blog_post_template)
```

- `markdown_path("./blog")` — scan the `blog/` directory for post directories
- `route_prefix("blog")` — output posts under `/blog/{slug}/`
- `template(blog_post_template)` — wrap each post in a custom HTML page layout

### RSS feed

```gleam
let rss =
  feed.new(
    "Simple Blog",
    site_url,
    "A simple example blog built with Blogatto",
  )
  |> feed.language("en-us")
  |> feed.generator("Blogatto")
```

This generates an RSS 2.0 feed with a title, description, and language tag.

### Sitemap and robots.txt

```gleam
let sitemap_config = sitemap.new("/sitemap.xml")

let robots_config =
  robots.RobotsConfig(sitemap_url: site_url <> "/sitemap.xml", robots: [
    robots.Robot(
      user_agent: "*",
      allowed_routes: ["/"],
      disallowed_routes: [],
    ),
  ])
```

The sitemap collects all routes and blog post URLs into an XML sitemap. The robots.txt allows all crawlers access to the entire site.

### Assembling the config

All pieces come together with the builder pattern:

```gleam
let cfg =
  config.new(site_url)
  |> config.output_dir("./dist")
  |> config.markdown(md_config)
  |> config.route("/", home_view)
  |> config.feed(rss)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
```

Then a single `blogatto.build(cfg)` call generates the entire site:

```gleam
case blogatto.build(cfg) {
  Ok(Nil) -> io.println("Site built successfully in ./dist")
  Error(err) -> io.println("Build failed: " <> error.describe_error(err))
}
```

## Homepage view

The homepage receives the full list of parsed blog posts and renders them as a linked list, sorted newest-first:

```gleam
fn home_view(posts: List(Post(Nil))) -> Element(Nil) {
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
```

Key points:

- The view receives `List(Post(Nil))` — all posts parsed by the markdown pipeline
- Posts are sorted by `date` using `timestamp.compare` in reverse order
- Each post's `slug`, `title`, and `description` fields are used to build the article list
- The route `/blog/{slug}` matches the `route_prefix("blog")` set in the markdown config

## Blog post template

The template function wraps each blog post's rendered markdown in a full HTML page:

```gleam
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
```

Key points:

- `p.language` is `None` for the default language and `Some("it")` for localized variants — here it falls back to `"en"`
- `p.contents` is a `List(Element(Nil))` containing the rendered markdown — just drop it into a container element
- The template adds a navigation link back to the homepage
- SEO metadata (`title`, `description`) is set from the post's frontmatter fields

## Blog posts

Each blog post lives in its own directory under `blog/`. The directory name becomes the slug.

### hello-world/index.md

```markdown
---
title: Hello World
slug: hello-world
date: 2025-01-15 00:00:00
description: Welcome to my new blog built with Blogatto
---

# Hello World

Welcome to my very first blog post! This blog was built using **Blogatto**,
a static site generator for Gleam.

## What is Blogatto?

Blogatto is a framework for building static blogs with Lustre and Markdown...
```

### getting-started/index.md

```markdown
---
title: Getting Started with Blogatto
slug: getting-started
date: 2025-01-20 00:00:00
description: Learn how to set up your first static blog with Blogatto
---

# Getting Started with Blogatto

Setting up a blog with Blogatto is straightforward...
```

Required frontmatter fields are `title`, `slug`, `date`, and `description`. Any additional fields (e.g. `author`, `tags`) are collected into the post's `extras` dictionary.

## Generated output

Running `gleam run` from the example directory produces:

```text
dist/
  index.html                     # Homepage
  blog/
    hello-world/
      index.html                 # Blog post page
    getting-started/
      index.html                 # Blog post page
  feed.xml                       # RSS feed
  sitemap.xml                    # Sitemap
  robots.txt                     # Robots policy
```

## Running the example

```sh
cd examples/simple_blog
gleam run
```

The site is written to `./dist`. Open `dist/index.html` in a browser to see the homepage with links to both blog posts.

## Running the dev server

The example also includes a dev server entrypoint at `src/simple_blog/dev.gleam`:

```gleam
import blogatto/dev
import blogatto/error
import gleam/io
import simple_blog/blog

pub fn main() {
  case
    blog.config()
    |> dev.new()
    |> dev.start()
  {
    Ok(Nil) -> io.println("Dev server stopped.")
    Error(err) -> io.println("Dev server error: " <> error.describe_error(err))
  }
}
```

Run it with:

```sh
cd examples/simple_blog
gleam run -m simple_blog/dev
```

This starts a local server at `http://127.0.0.1:3000` that watches for file changes, rebuilds the site, and live-reloads the browser. See [Dev server](dev-server) for full documentation.
