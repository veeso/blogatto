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

Optionally override the default blog post template:

```gleam
import blogatto/config/markdown
import blogatto/post.{type Post}

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

Add static pages by mapping URL paths to Lustre view functions:

```gleam
import blogatto/config

let cfg =
  config.new("https://example.com")
  |> config.route("/", fn() { index_view() })
  |> config.route("/about", fn() { about_view() })
```

### RSS feeds

Configure one or more RSS feeds with optional filtering and serialization:

```gleam
import blogatto/config
import blogatto/config/feed

let rss = feed.FeedConfig(
  excerpt_len: 200,
  filter: option.None,
  output: "/rss.xml",
  serialize: option.None,
  title: "My Blog",
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

let sitemap_config = sitemap.SitemapConfig(
  filter: option.None,
  serialize: option.None,
  path: "/sitemap.xml",
)

let cfg =
  config.new("https://example.com")
  |> config.sitemap(sitemap_config)
```

## Build pipeline

Calling `blogatto.build(config)` executes these steps:

1. Clean and recreate the output directory
2. Copy static assets (if `static_dir` is configured)
3. Parse markdown files and extract frontmatter
4. Render blog post pages via Maud components
5. Render static pages from route view functions
6. Generate RSS feeds
7. Generate sitemap XML
8. Generate robots.txt

## Development

```sh
gleam build  # Compile the project
gleam test   # Run the tests
gleam format src test  # Format code
```

Further documentation can be found at <https://hexdocs.pm/blogatto>.

## License

Blogatto is licensed under the MIT License. See [LICENSE](LICENSE) for details.
