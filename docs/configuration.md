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
  |> config.post(md_config)
  |> config.route("/", home_view)
  |> config.rss_feed(rss_config)
  |> config.atom_feed(atom_config)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
```

## Reference

### `config.new(site_url)`

Creates a new `Config` with the given base URL. The `site_url` is required because it is used to build absolute URLs for sitemaps, RSS feeds, and blog post URLs.

**Default values:**

| Field         | Default                          |
| ------------- | -------------------------------- |
| `output_dir`  | `"./dist"`                       |
| `static_dir`  | `None` (no static asset copying) |
| `post_config` | `None` (no blog posts)           |
| `routes`      | Empty (no static pages)          |
| `rss_feeds`   | Empty (no RSS feeds)             |
| `atom_feeds`  | Empty (no Atom feeds)            |
| `sitemap`     | `None` (no sitemap)              |
| `robots`      | `None` (no robots.txt)           |

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

### `config.post(config, post_config)`

Set the post configuration for blog post rendering (applies to both Markdown and Djot sources). See [Post components](post-components.md) for component customization and [Blog posts](blog-posts.md) for routing details.

```gleam
import blogatto/config/post

let md = post.default()
  |> post.path("./blog")

config.new("https://example.com")
|> config.post(md)
```

#### Markdown parsing options

The `PostConfig` includes an `Options` record that controls which markdown extensions are enabled during parsing. Use `post.options()` to override the defaults:

```gleam
import blogatto/config/post

let opts = post.Options(
  footnotes: True,
  heading_ids: True,
  tables: True,
  tasklists: True,
  emojis_shortcodes: True,
  autolinks: True,
)

let md = post.default()
  |> post.path("./blog")
  |> post.options(opts)
```

See [Markdown parsing options](blog-posts.md#markdown-parsing-options) for details on each option.

#### Syntax highlighting

Enable build-time syntax highlighting for fenced code blocks:

```gleam
import blogatto/config/post
import blogatto/config/post/code

let md = post.default()
  |> post.path("./blog")
  |> post.syntax_highlighting(code.default())
```

See [Syntax highlighting](syntax-highlighting.md) for the full guide on supported languages, styling, and customization.

#### Markdown routing options

The `PostConfig` controls how blog post URLs are generated. You can use either `route_prefix` or `route_builder` (not both — `route_builder` takes precedence):

- **`post.route_prefix(config, prefix)`** — set a static URL prefix for all posts (e.g., `"blog"` produces `/blog/{slug}/`)
- **`post.route_builder(config, builder)`** — set a function that receives `PostMetadata` and returns a custom URL path per post

See [Custom routing with `route_builder`](blog-posts.md#custom-routing-with-route_builder) for examples.

### `config.route(config, path, view)`

Add a static route mapping a URL path to a view function. The view function receives the full list of blog posts parsed during the build.

Routes map to `{output_dir}/{route}/index.html` in the output.

```gleam
config.new("https://example.com")
|> config.route("/", home_view)
|> config.route("/about", about_view)
```

See [Static pages](static-pages.md) for more on writing view functions.

### `config.rss_feed(config, rss_feed_config)`

Add an RSS feed configuration. Can be called multiple times to generate multiple feeds. See [RSS feeds](rss-feeds.md).

### `config.atom_feed(config, atom_feed_config)`

Add an Atom 1.0 feed configuration. Can be called multiple times to generate multiple feeds. See [Atom feeds](atom-feeds.md).

### `config.sitemap(config, sitemap_config)`

Set the sitemap configuration. See [Sitemap and robots.txt](sitemap-and-robots.md).

### `config.robots(config, robots_config)`

Set the robots.txt configuration. See [Sitemap and robots.txt](sitemap-and-robots.md).

## Common configurations

### Blog-only site

A minimal blog with no static pages:

```gleam
let md =
  post.default()
  |> post.path("./blog")

let cfg =
  config.new("https://example.com")
  |> config.post(md)
```

### Blog with homepage

A blog with a homepage listing recent posts:

```gleam
let md =
  post.default()
  |> post.path("./blog")
  |> post.route_prefix("blog")

let cfg =
  config.new("https://example.com")
  |> config.static_dir("./static")
  |> config.post(md)
  |> config.route("/", home_view)
```

### Full-featured site

Blog, multiple pages, RSS, Atom, sitemap, and robots.txt:

```gleam
let md =
  post.default()
  |> post.path("./blog")
  |> post.route_prefix("blog")
  |> post.excerpt_len(300)
  |> post.template(post_template)

let cfg =
  config.new("https://example.com")
  |> config.output_dir("./dist")
  |> config.static_dir("./static")
  |> config.post(md)
  |> config.route("/", home_view)
  |> config.route("/about", about_view)
  |> config.rss_feed(rss_config)
  |> config.atom_feed(atom_config)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
```

See the [simple_blog example](https://github.com/veeso/blogatto/tree/main/examples/simple_blog) for a complete working version of this configuration.
