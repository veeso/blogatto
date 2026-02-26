# Blogatto

![logo](https://blogat.to/logo.png)

[![Package Version](https://img.shields.io/hexpm/v/blogatto)](https://hex.pm/packages/blogatto)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/blogatto/)
[![conventional-commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![target-erlang](https://img.shields.io/badge/target-erlang-b83998)](https://www.erlang.org/)
[![test](https://github.com/veeso/blogatto/actions/workflows/test.yml/badge.svg)](https://github.com/veeso/blogatto/actions/workflows/test.yml)

A Gleam framework for building static blogs with [**Lustre**](https://hexdocs.pm/lustre/) and Markdown.

Blogatto generates your entire static site from a single configuration: blog posts from markdown with frontmatter, static pages from [Lustre](https://hexdocs.pm/lustre/) views, RSS feeds, sitemaps, and robots.txt — all rendered via [Maud](https://hexdocs.pm/maud/) components.

## Features

- Blog posts from markdown files with YAML frontmatter
- Multilingual posts via `index-{lang}.md` file naming convention
- Static pages from [Lustre](https://hexdocs.pm/lustre/) view functions
- RSS feed generation with customizable filtering and serialization
- Sitemap XML generation with alternate language links
- Robots.txt generation
- Static asset copying
- Custom Maud components for markdown rendering
- Configurable blog post templates
- Dev server with file watching, auto-rebuild, and live reload

## Installation

```sh
gleam add blogatto@1
gleam add lustre@5
```

## Quick start

```gleam
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
import gleam/time/timestamp
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

const site_url = "https://example.com"

pub fn main() {
  // Markdown config with custom heading component
  let md =
    markdown.default()
    |> markdown.markdown_path("./blog")
    |> markdown.route_prefix("blog")
    |> markdown.h1(fn(id, children) {
      html.h1([attribute.id(id), attribute.class("post-title")], children)
    })

  // RSS feed
  let rss =
    feed.new("My Blog", site_url, "My personal blog")
    |> feed.language("en-us")
    |> feed.generator("Blogatto")

  // Build configuration
  let cfg =
    config.new(site_url)
    |> config.output_dir("./dist")
    |> config.static_dir("./static")
    |> config.markdown(md)
    |> config.route("/", home_view)
    |> config.feed(rss)
    |> config.sitemap(sitemap.new("/sitemap.xml"))
    |> config.robots(robots.RobotsConfig(
      sitemap_url: site_url <> "/sitemap.xml",
      robots: [
        robots.Robot(
          user_agent: "*",
          allowed_routes: ["/"],
          disallowed_routes: [],
        ),
      ],
    ))

  case blogatto.build(cfg) {
    Ok(Nil) -> io.println("Site built successfully!")
    Error(err) -> io.println("Build failed: " <> error.describe_error(err))
  }
}

fn home_view(posts: List(Post(Nil))) -> Element(Nil) {
  let sorted =
    list.sort(posts, fn(a, b) { timestamp.compare(b.date, a.date) })

  html.html([], [
    html.head([], [html.title([], "My Blog")]),
    html.body([], [
      html.h1([], [element.text("My Blog")]),
      html.ul(
        [],
        list.map(sorted, fn(p) {
          html.li([], [
            html.a([attribute.href("/blog/" <> p.slug)], [
              element.text(p.title),
            ]),
          ])
        }),
      ),
    ]),
  ])
}
```

Running `gleam build` will generate the `dist` directory with the following structure:

```
dist/
├── blog/
│   └── my-post/
│       └── index.html
├── index.html
├── robots.txt
├── sitemap.xml
└── feed.xml
```

## Dev server

Blogatto includes a built-in development server that watches your source files for changes, automatically rebuilds the site, and live-reloads the browser via SSE.

Create a separate dev entrypoint module (e.g., `src/dev.gleam`):

```gleam
import blogatto/dev
import blogatto/error
import gleam/io
import my_blog // your module that exposes your blogatto config

pub fn main() {
  let cfg = my_blog.config()

  case
    cfg
    |> dev.new()
    |> dev.build_command("gleam run -m my_blog")
    |> dev.port(3000)
    |> dev.start()
  {
    Ok(Nil) -> io.println("Dev server stopped.")
    Error(err) -> io.println("Dev server error: " <> error.describe_error(err))
  }
}
```

Run with: `gleam run -m dev`

The dev server will:

1. Perform an initial build by running the configured build command
2. Serve the output directory over HTTP at `http://127.0.0.1:3000`
3. Watch `src/`, markdown paths, and static assets for changes
4. Debounce rapid file changes (~300ms) and rebuild automatically
5. Live-reload the browser on successful rebuilds

### Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `build_command` | `"gleam run"` | Shell command to rebuild the site |
| `port` | `3000` | HTTP server port |
| `host` | `"127.0.0.1"` | Bind address |
| `live_reload` | `True` | Inject live-reload script into HTML responses |

> **Note for Linux users**: The file watcher requires `inotify-tools` to be installed.

## Documentation

Full documentation is available at [blogat.to](https://blogat.to), covering blog post structure, configuration, markdown components, static pages, RSS feeds, sitemaps, dev server, and error handling.

API reference is on [HexDocs](https://hexdocs.pm/blogatto/).

## Development

```sh
gleam build  # Compile the project
gleam test   # Run the tests
gleam format src test  # Format code
```

## License

Blogatto is licensed under the MIT License. See [LICENSE](LICENSE) for details.
