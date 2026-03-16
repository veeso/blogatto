---
layout: default
title: Configuration
nav_order: 5
---

# Configuration

Blogatto uses a builder pattern for configuration. Start with `config.new(site_url)` and pipe through setter functions to configure each feature.

## Config type

The `Config(msg)` type holds all settings for a build. The `msg` type parameter threads through the Lustre message type for type-safe views and components.

```gleam
import blogatto/config

let cfg =
  config.new("https://example.com")
  |> config.output_dir("./dist")
  |> config.static_dir("./static")
  |> config.markdown(md_config)
  |> config.route("/", home_view)
  |> config.feed(rss_config)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
```

## Reference

### `config.new(site_url)`

Creates a new `Config` with the given base URL. The `site_url` is required because it is used to build absolute URLs for sitemaps, RSS feeds, and blog post URLs.

**Default values:**

| Field | Default |
|-------|---------|
| `output_dir` | `"./dist"` |
| `static_dir` | `None` (no static asset copying) |
| `markdown_config` | `None` (no blog posts) |
| `routes` | Empty (no static pages) |
| `feeds` | Empty (no RSS feeds) |
| `sitemap` | `None` (no sitemap) |
| `robots` | `None` (no robots.txt) |

### `config.output_dir(config, directory)`

Set the output directory path. The directory is deleted and recreated on each build.

```gleam
config.new("https://example.com")
|> config.output_dir("./public")
```

### `config.static_dir(config, directory)`

Set a static assets directory. During the build, its contents are copied into the root of the output directory.

```gleam
config.new("https://example.com")
|> config.static_dir("./static")
```

For example, `./static/css/style.css` becomes `./dist/css/style.css`.

### `config.markdown(config, markdown_config)`

Set the markdown configuration for blog post rendering. See [Markdown components](markdown-components) for component customization and [Blog posts](blog-posts) for routing details.

```gleam
import blogatto/config/markdown

let md = markdown.default()
  |> markdown.markdown_path("./blog")

config.new("https://example.com")
|> config.markdown(md)
```

#### Markdown parsing options

The `MarkdownConfig` includes an `Options` record that controls which markdown extensions are enabled during parsing. Use `markdown.options()` to override the defaults:

```gleam
import blogatto/config/markdown

let opts = markdown.Options(
  footnotes: True,
  heading_ids: True,
  tables: True,
  tasklists: True,
  emojis_shortcodes: True,
  autolinks: True,
)

let md = markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.options(opts)
```

See [Markdown parsing options](blog-posts#markdown-parsing-options) for details on each option.

#### Syntax highlighting

Enable build-time syntax highlighting for fenced code blocks:

```gleam
import blogatto/config/markdown
import blogatto/config/markdown/code

let md = markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.syntax_highlighting(code.default())
```

See [Syntax highlighting](syntax-highlighting) for the full guide on supported languages, styling, and customization.

#### Markdown routing options

The `MarkdownConfig` controls how blog post URLs are generated. You can use either `route_prefix` or `route_builder` (not both — `route_builder` takes precedence):

- **`markdown.route_prefix(config, prefix)`** — set a static URL prefix for all posts (e.g., `"blog"` produces `/blog/{slug}/`)
- **`markdown.route_builder(config, builder)`** — set a function that receives `PostMetadata` and returns a custom URL path per post

See [Custom routing with `route_builder`](blog-posts#custom-routing-with-route_builder) for examples.

### `config.route(config, path, view)`

Add a static route mapping a URL path to a view function. The view function receives the full list of blog posts parsed during the build.

Routes map to `{output_dir}/{route}/index.html` in the output.

```gleam
config.new("https://example.com")
|> config.route("/", home_view)
|> config.route("/about", about_view)
```

See [Static pages](static-pages) for more on writing view functions.

### `config.feed(config, feed_config)`

Add an RSS feed configuration. Can be called multiple times to generate multiple feeds. See [RSS feeds](rss-feeds).

### `config.sitemap(config, sitemap_config)`

Set the sitemap configuration. See [Sitemap and robots.txt](sitemap-and-robots).

### `config.robots(config, robots_config)`

Set the robots.txt configuration. See [Sitemap and robots.txt](sitemap-and-robots).

## Common configurations

### Blog-only site

A minimal blog with no static pages:

```gleam
let md =
  markdown.default()
  |> markdown.markdown_path("./blog")

let cfg =
  config.new("https://example.com")
  |> config.markdown(md)
```

### Blog with homepage

A blog with a homepage listing recent posts:

```gleam
let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.route_prefix("blog")

let cfg =
  config.new("https://example.com")
  |> config.static_dir("./static")
  |> config.markdown(md)
  |> config.route("/", home_view)
```

### Full-featured site

Blog, multiple pages, RSS, sitemap, and robots.txt:

```gleam
let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.route_prefix("blog")
  |> markdown.excerpt_len(300)
  |> markdown.template(post_template)

let cfg =
  config.new("https://example.com")
  |> config.output_dir("./dist")
  |> config.static_dir("./static")
  |> config.markdown(md)
  |> config.route("/", home_view)
  |> config.route("/about", about_view)
  |> config.feed(rss_config)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
```

See the [simple_blog example](https://github.com/veeso/blogatto/tree/main/examples/simple_blog) for a complete working version of this configuration.
