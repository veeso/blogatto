---
layout: default
title: Getting started
nav_order: 2
---

# Getting started

This guide walks you through installing Blogatto and building your first static blog.

## Prerequisites

- [Gleam](https://gleam.run) 1.14.0 or later
- [Erlang/OTP](https://www.erlang.org/) 28 or later

## Installation

Add Blogatto to your Gleam project:

```sh
gleam add blogatto@3
```

## Project structure

A typical Blogatto project looks like this:

```text
my-blog/
  src/
    my_blog.gleam        # Your build script
  blog/
    hello-world/
      index.md           # Blog post (default language)
      cover.jpg          # Post assets
    second-post/
      index.md
      index-it.md        # Italian variant
  static/
    css/
      style.css          # Static assets copied to output
    images/
      logo.png
  gleam.toml
```

## Minimal example

The simplest Blogatto setup parses markdown files and writes HTML:

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

Run the build:

```sh
gleam run
```

This produces:

```text
dist/
  css/
    style.css
  images/
    logo.png
  hello-world/
    index.html
    cover.jpg
  second-post/
    index.html
    index-it.html
```

## Adding a homepage

Most blogs need a landing page that lists articles. Add a route with a view function that receives the full list of parsed posts:

```gleam
import blogatto
import blogatto/config
import blogatto/config/markdown
import blogatto/post.{type Post}
import gleam/list
import gleam/time/timestamp
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn main() {
  let md =
    markdown.default()
    |> markdown.markdown_path("./blog")
    |> markdown.route_prefix("blog")

  let cfg =
    config.new("https://example.com")
    |> config.output_dir("./dist")
    |> config.static_dir("./static")
    |> config.markdown(md)
    |> config.route("/", home_view)

  let assert Ok(Nil) = blogatto.build(cfg)
}

fn home_view(posts: List(Post(Nil))) -> Element(Nil) {
  let sorted =
    list.sort(posts, fn(a, b) { timestamp.compare(b.date, a.date) })

  html.html([attribute.lang("en")], [
    html.head([], [
      html.title([], "My Blog"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/css/style.css"),
      ]),
    ]),
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

## Full example

See the [simple_blog example](https://github.com/veeso/blogatto/tree/main/examples/simple_blog) for a complete project with homepage, blog post template, RSS feed, sitemap, and robots.txt.

## Next steps

- [Blog posts](blog-posts) — learn about frontmatter, multilingual support, and post assets
- [Configuration](configuration) — explore all configuration options
- [Static pages](static-pages) — add more pages and use post data in views
