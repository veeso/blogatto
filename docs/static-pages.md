---
layout: default
title: Static pages
nav_order: 7
---

# Static pages

Static pages are non-blog HTML pages generated from Lustre view functions. Use them for homepages, about pages, archives, or any page that isn't a markdown blog post.

## Adding routes

Register routes with `config.route(path, view)`. Each route maps a URL path to a view function:

```gleam
import blogatto/config

let cfg =
  config.new("https://example.com")
  |> config.route("/", home_view)
  |> config.route("/about", about_view)
  |> config.route("/archive", archive_view)
```

### Output paths

Routes map to `{output_dir}/{route}/index.html`:

| Route | Output file |
|-------|-------------|
| `"/"` | `dist/index.html` |
| `"/about"` | `dist/about/index.html` |
| `"/archive"` | `dist/archive/index.html` |

## Writing view functions

Every view function receives the full list of blog posts parsed during the build and returns a Lustre `Element(msg)`:

```gleam
import blogatto/post.{type Post}
import lustre/element.{type Element}
import lustre/element/html

fn about_view(_posts: List(Post(Nil))) -> Element(Nil) {
  html.html([], [
    html.head([], [html.title([], "About")]),
    html.body([], [
      html.h1([], [element.text("About this blog")]),
      html.p([], [element.text("Welcome to my blog.")]),
    ]),
  ])
}
```

If a page doesn't need blog post data, ignore the argument with `_posts`.

## Using post data

The post list enables dynamic content on static pages. Common patterns:

### Homepage with recent posts

```gleam
import gleam/list
import gleam/time/timestamp

fn home_view(posts: List(Post(Nil))) -> Element(Nil) {
  let recent =
    posts
    |> list.sort(fn(a, b) { timestamp.compare(b.date, a.date) })
    |> list.take(5)

  html.html([], [
    html.head([], [html.title([], "Home")]),
    html.body([], [
      html.h1([], [element.text("Latest posts")]),
      html.ul(
        [],
        list.map(recent, fn(p) {
          html.li([], [
            html.a([attribute.href(p.url)], [element.text(p.title)]),
          ])
        }),
      ),
    ]),
  ])
}
```

### Archive page grouped by year

```gleam
import gleam/dict
import gleam/int
import gleam/list
import gleam/time/calendar
import gleam/time/timestamp

fn archive_view(posts: List(Post(Nil))) -> Element(Nil) {
  // Group posts by year
  let by_year =
    list.group(posts, fn(p) {
      let date = timestamp.to_calendar(p.date, calendar.utc_offset)
      date.date.year
    })

  let years =
    by_year
    |> dict.to_list()
    |> list.sort(fn(a, b) { int.compare(b.0, a.0) })

  html.html([], [
    html.head([], [html.title([], "Archive")]),
    html.body([], [
      html.h1([], [element.text("Archive")]),
      ..list.map(years, fn(entry) {
        let #(year, year_posts) = entry
        html.section([], [
          html.h2([], [element.text(int.to_string(year))]),
          html.ul(
            [],
            list.map(year_posts, fn(p) {
              html.li([], [
                html.a([attribute.href(p.url)], [element.text(p.title)]),
              ])
            }),
          ),
        ])
      })
    ]),
  ])
}
```

### Filtering by language

```gleam
import gleam/list
import gleam/option.{None, Some}

fn english_home(posts: List(Post(Nil))) -> Element(Nil) {
  let en_posts =
    list.filter(posts, fn(p) {
      p.language == None || p.language == Some("en")
    })
  // ... render en_posts
}
```

## Blog post templates

Blog post templates control the full page layout wrapping each rendered blog post. Set a template via `markdown.template()`:

```gleam
import blogatto/config/markdown
import blogatto/post.{type Post}
import gleam/option
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.template(post_template)

fn post_template(post: Post(Nil)) -> Element(Nil) {
  let lang = option.unwrap(post.language, "en")

  html.html([attribute.lang(lang)], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.title([], post.title),
      html.meta([
        attribute.name("description"),
        attribute.content(post.description),
      ]),
    ]),
    html.body([], [
      html.nav([], [
        html.a([attribute.href("/")], [element.text("Home")]),
      ]),
      html.article([], [
        html.h1([], [element.text(post.title)]),
        html.div([], post.contents),
      ]),
    ]),
  ])
}
```

The template receives a fully parsed `Post` with rendered `contents`. When no template is set, Blogatto uses a minimal default that wraps the title and contents in a basic HTML page.
