# Blogatto

![logo](./logo.png)

[![Package Version](https://img.shields.io/hexpm/v/blogatto)](https://hex.pm/packages/blogatto)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/blogatto/)
[![test](https://github.com/veeso/blogatto/actions/workflows/test.yml/badge.svg)](https://github.com/veeso/blogatto/actions/workflows/test.yml)

A Gleam framework for building static blogs with Lustre and Markdown.

Blogatto generates your entire static site from a single configuration: blog posts from markdown with frontmatter, static pages from Lustre views, RSS feeds, sitemaps, and robots.txt — all rendered via [Maud](https://hexdocs.pm/maud/) components.

## Features

- Blog posts from markdown files with YAML frontmatter
- Multilingual posts via `index-{lang}.md` file naming convention
- Static pages from Lustre view functions
- RSS feed generation with customizable filtering and serialization
- Sitemap XML generation with alternate language links
- Robots.txt generation
- Static asset copying
- Custom Maud components for markdown rendering
- Configurable blog post templates

## Installation

```sh
gleam add blogatto@1
```

## Quick start

```gleam
import blogatto
import blogatto/config
import blogatto/config/markdown

pub fn main() {
  let md =
    markdown.default()
    |> markdown.markdown_path("./blog")

  let cfg =
    config.new("https://example.com")
    |> config.output_dir("./dist")
    |> config.static_dir("./static")
    |> config.markdown(md)

  let assert Ok(Nil) = blogatto.build(cfg)
}
```

## Blog post structure

Blog posts follow a directory-per-post convention with optional language variants:

```text
blog/
  my-first-post/
    index.md            # Default language
    index-it.md         # Italian variant
    index-en.md         # English variant
    cover.jpg           # Assets copied alongside HTML
  another-post/
    index.md
```

Each markdown file must have frontmatter with these required fields:

```markdown
---
title: My First Post
date: 2025-01-15 00:00:00
description: A short description of the post
featured_image: /images/hero.jpg
---

Your markdown content here...
```

| Field | Required | Description |
|-------|----------|-------------|
| `title` | Yes | The post title |
| `date` | Yes | Publication date in `YYYY-MM-DD HH:MM:SS` format (UTC) |
| `description` | Yes | A short description or excerpt |
| `featured_image` | No | URL or path to a featured image |

- **Slug** is derived from the directory name (e.g., `my-first-post`)
- **Language** is derived from the filename: `index.md` is the default, `index-it.md` is Italian
- **Assets** — non-markdown files in a post directory (images, etc.) are copied to the output alongside the generated HTML, so relative links in markdown work as-is
- Additional frontmatter keys beyond the ones above are available in `Post.extras`

## Configuration

### Markdown

Set up markdown rendering with Maud components and paths to search for posts:

```gleam
import blogatto/config/markdown

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
```

Use `route_prefix` to place blog posts under a URL prefix (e.g., `/blog/{slug}/`):

```gleam
let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.route_prefix("blog")
```

Optionally override the default blog post template:

```gleam
import blogatto/config/markdown
import blogatto/post.{type Post}
import lustre/element/html

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.template(fn(post: Post(_)) {
    html.html([], [
      html.head([], [html.title([], post.title)]),
      html.body([], post.contents),
    ])
  })
```

### Static routes

Add static pages by mapping URL paths to Lustre view functions. Each view function receives the full list of blog posts, so pages can display recent articles, featured posts, etc.:

```gleam
import blogatto/config
import blogatto/post.{type Post}
import lustre/element.{type Element}
import lustre/element/html

let cfg =
  config.new("https://example.com")
  |> config.route("/", home_view)
  |> config.route("/about", fn(_posts) { about_view() })

fn home_view(posts: List(Post(Nil))) -> Element(Nil) {
  html.html([], [
    html.body([], [
      html.h1([], [element.text("Home")]),
      // Use posts to list recent articles, etc.
    ]),
  ])
}
```

### RSS feeds

Configure one or more RSS feeds with full RSS 2.0 channel support:

```gleam
import blogatto/config
import blogatto/config/feed
import gleam/option.{None, Some}

let rss =
  feed.FeedConfig(
    excerpt_len: 200,
    filter: None,
    output: "/rss.xml",
    serialize: None,
    title: "My Blog",
    link: "https://example.com",
    description: "My personal blog",
    language: Some("en-us"),
    copyright: None,
    managing_editor: None,
    web_master: None,
    pub_date: None,
    last_build_date: None,
    categories: [],
    generator: Some("Blogatto"),
    docs: None,
    cloud: None,
    ttl: None,
    image: None,
    text_input: None,
    skip_hours: [],
    skip_days: [],
  )

let cfg =
  config.new("https://example.com")
  |> config.feed(rss)
```

### Sitemap

Enable sitemap generation with optional filtering:

```gleam
import blogatto/config
import blogatto/config/sitemap
import gleam/option.{None}

let sitemap_config =
  sitemap.SitemapConfig(
    filter: None,
    serialize: None,
    path: "/sitemap.xml",
  )

let cfg =
  config.new("https://example.com")
  |> config.sitemap(sitemap_config)
```

### Robots.txt

Generate a `robots.txt` with crawl policies and a sitemap reference:

```gleam
import blogatto/config
import blogatto/config/robots

let robots_config =
  robots.new("https://example.com/sitemap.xml")
  |> robots.robot(robots.Robot(
    user_agent: "*",
    allowed_routes: ["/"],
    disallowed_routes: [],
  ))

let cfg =
  config.new("https://example.com")
  |> config.robots(robots_config)
```

## Error handling

All build functions return `Result(Nil, BlogattoError)`. Use `error.describe_error()` for human-readable messages:

```gleam
import blogatto
import blogatto/error

case blogatto.build(cfg) {
  Ok(Nil) -> io.println("Site built successfully!")
  Error(err) -> io.println("Build failed: " <> error.describe_error(err))
}
```

## Build pipeline

Calling `blogatto.build(config)` executes these steps:

1. Clean and recreate the output directory
2. Copy static assets (if `static_dir` is configured)
3. Generate robots.txt (if configured)
4. Parse markdown files, extract frontmatter, render blog post pages via Maud components, and copy post assets
5. Render static pages from route view functions
6. Generate RSS feeds
7. Generate sitemap XML

## Development

```sh
gleam build  # Compile the project
gleam test   # Run the tests
gleam format src test  # Format code
```

Further documentation can be found at <https://hexdocs.pm/blogatto>.

## License

Blogatto is licensed under the MIT License. See [LICENSE](LICENSE) for details.
