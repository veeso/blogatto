---
layout: default
title: Sitemap and robots.txt
nav_order: 8
---

Blogatto can generate a sitemap XML file and a `robots.txt` file for search engine optimization.

## Sitemap

The sitemap includes all static routes and blog post URLs.

### Basic setup

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

This generates `dist/sitemap.xml` with entries for every static route and blog post.

### SitemapConfig fields

| Field | Type | Description |
|-------|------|-------------|
| `path` | `String` | Output path relative to `output_dir` |
| `filter` | `Option(fn(String) -> Bool)` | Include/exclude routes by URL |
| `serialize` | `Option(fn(String) -> SitemapEntry)` | Custom entry serialization |

### Filtering routes

Exclude specific routes from the sitemap:

```gleam
import gleam/option.{Some}
import gleam/string

let sitemap_config =
  sitemap.SitemapConfig(
    filter: Some(fn(url) {
      // Exclude draft pages
      !string.contains(url, "/draft")
    }),
    serialize: None,
    path: "/sitemap.xml",
  )
```

### Custom serialization

Control the priority, change frequency, and last-modified date for each entry:

```gleam
import blogatto/config/sitemap.{Monthly, Weekly}
import gleam/option.{None, Some}
import gleam/string

let sitemap_config =
  sitemap.SitemapConfig(
    filter: None,
    serialize: Some(fn(url) {
      let #(priority, freq) = case string.contains(url, "/blog/") {
        True -> #(0.7, Some(Weekly))
        False -> #(1.0, Some(Monthly))
      }
      sitemap.SitemapEntry(
        url: url,
        priority: Some(priority),
        last_modified: None,
        change_frequency: freq,
      )
    }),
    path: "/sitemap.xml",
  )
```

### SitemapEntry fields

| Field | Type | Description |
|-------|------|-------------|
| `url` | `String` | The full URL for this entry |
| `priority` | `Option(Float)` | Priority hint (`0.0` to `1.0`) |
| `last_modified` | `Option(Timestamp)` | Last modification date |
| `change_frequency` | `Option(ChangeFrequency)` | How often the page changes |

### ChangeFrequency values

| Value | Description |
|-------|-------------|
| `Always` | Changes every access |
| `Hourly` | Changes approximately every hour |
| `Daily` | Changes approximately every day |
| `Weekly` | Changes approximately every week |
| `Monthly` | Changes approximately every month |
| `Yearly` | Changes approximately every year |
| `Never` | Archived, will not change |

## Robots.txt

The `robots.txt` file tells search engine crawlers which pages to index.

### Basic setup

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

This generates `dist/robots.txt`:

```text
Sitemap: https://example.com/sitemap.xml

User-agent: *
Allow: /
```

### Multiple user agents

Add different policies for different crawlers:

```gleam
let robots_config =
  robots.new("https://example.com/sitemap.xml")
  |> robots.robot(robots.Robot(
    user_agent: "*",
    allowed_routes: ["/"],
    disallowed_routes: ["/admin/"],
  ))
  |> robots.robot(robots.Robot(
    user_agent: "Googlebot",
    allowed_routes: ["/"],
    disallowed_routes: [],
  ))
```

### RobotsConfig fields

| Field | Type | Description |
|-------|------|-------------|
| `sitemap_url` | `String` | Full URL to the sitemap |
| `robots` | `List(Robot)` | Crawl policies per user agent |

### Robot fields

| Field | Type | Description |
|-------|------|-------------|
| `user_agent` | `String` | Crawler name (`"*"` for all) |
| `allowed_routes` | `List(String)` | Paths the crawler may access |
| `disallowed_routes` | `List(String)` | Paths the crawler must not access |

## Combining sitemap and robots.txt

A typical SEO setup uses both together, with the robots.txt pointing to the sitemap:

```gleam
import blogatto/config
import blogatto/config/robots
import blogatto/config/sitemap
import gleam/option.{None}

let site_url = "https://example.com"

let sitemap_config =
  sitemap.SitemapConfig(
    filter: None,
    serialize: None,
    path: "/sitemap.xml",
  )

let robots_config =
  robots.new(site_url <> "/sitemap.xml")
  |> robots.robot(robots.Robot(
    user_agent: "*",
    allowed_routes: ["/"],
    disallowed_routes: [],
  ))

let cfg =
  config.new(site_url)
  |> config.sitemap(sitemap_config)
  |> config.robots(robots_config)
```
