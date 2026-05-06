---
layout: default
title: RSS feeds
nav_order: 9
---

# RSS feeds

Blogatto generates RSS 2.0 feeds from your blog posts. You can configure multiple feeds with different filters (e.g., one per language) and customize how posts are serialized into feed items. RSS feeds work alongside [Atom feeds](atom-feeds) — both can be generated from the same build.

## Basic setup

```gleam
import blogatto/config
import blogatto/config/feed/rss

let rss_feed =
  rss.new("My Blog", "https://example.com", "My personal blog")
  |> rss.language("en-us")
  |> rss.generator("Blogatto")

let cfg =
  config.new("https://example.com")
  |> config.rss_feed(rss_feed)
```

This generates `dist/rss.xml` containing all blog posts with auto-generated excerpts. The excerpt length is controlled by `markdown.excerpt_len()` (default: 200 characters).

## RssFeedConfig fields

### Required fields (passed to `rss.new()`)

| Field         | Type     | Description         |
| ------------- | -------- | ------------------- |
| `title`       | `String` | Channel title       |
| `link`        | `String` | Website URL         |
| `description` | `String` | Channel description |

### Optional fields (set via builder functions)

| Field             | Setter                  | Default      | Description                             |
| ----------------- | ----------------------- | ------------ | --------------------------------------- |
| `output`          | `rss.output()`          | `"/rss.xml"` | Output path relative to `output_dir`    |
| `language`        | `rss.language()`        | `None`       | Language code (e.g., `"en-us"`)         |
| `copyright`       | `rss.copyright()`       | `None`       | Copyright notice                        |
| `managing_editor` | `rss.managing_editor()` | `None`       | Editor email                            |
| `web_master`      | `rss.web_master()`      | `None`       | Webmaster email                         |
| `pub_date`        | `rss.pub_date()`        | `None`       | Channel publication date                |
| `last_build_date` | `rss.last_build_date()` | `None`       | Last build timestamp                    |
| `categories`      | `rss.category()`        | `[]`         | Channel category tags (prepends)        |
| `generator`       | `rss.generator()`       | `None`       | Generator program name                  |
| `docs`            | `rss.docs()`            | `None`       | URL to RSS format documentation         |
| `cloud`           | `rss.cloud()`           | `None`       | Cloud service for update notifications  |
| `ttl`             | `rss.ttl()`             | `None`       | Cache time-to-live in minutes           |
| `image`           | `rss.image()`           | `None`       | Channel image                           |
| `text_input`      | `rss.text_input()`      | `None`       | Channel text input field                |
| `skip_hours`      | `rss.skip_hour()`       | `[]`         | Hours (0-23) to skip updates (prepends) |
| `skip_days`       | `rss.skip_day()`        | `[]`         | Days to skip updates (prepends)         |
| `filter`          | `rss.filter()`          | `None`       | Include/exclude posts                   |
| `serialize`       | `rss.serialize()`       | `None`       | Custom item serialization               |

## Filtering posts

Use the `filter` function to control which posts appear in a feed. The function receives `FeedMetadata` (from `blogatto/config/feed`) containing the post and its URL path:

```gleam
import blogatto/config/feed
import gleam/option

// Only include English posts
let rss_feed =
  rss.new("My Blog", "https://example.com", "My personal blog")
  |> rss.filter(fn(meta: feed.FeedMetadata(Nil)) {
    meta.post.language == option.None
    || meta.post.language == option.Some("en")
  })
```

## Custom serialization

Override how posts become feed items with the `serialize` function:

```gleam
import blogatto/config/feed
import gleam/dict
import gleam/option.{None, Some}

let rss_feed =
  rss.new("My Blog", "https://example.com", "My personal blog")
  |> rss.serialize(fn(meta: feed.FeedMetadata(Nil)) {
    let author =
      dict.get(meta.post.extras, "author")
      |> result.map(Some)
      |> result.unwrap(None)

    rss.RssFeedItem(
      title: meta.post.title,
      description: meta.post.excerpt,
      link: Some(meta.url),
      author: author,
      comments: None,
      source: None,
      pub_date: Some(meta.post.date),
      categories: [],
      enclosure: None,
      guid: Some(meta.url),
    )
  })
```

## Multiple feeds

Call `config.rss_feed()` multiple times to generate separate feeds:

```gleam
let en_feed =
  rss.new("My Blog (English)", "https://example.com", "My personal blog")
  |> rss.language("en-us")
  |> rss.filter(fn(meta) {
    meta.post.language == option.None
    || meta.post.language == option.Some("en")
  })

let it_feed =
  rss.new("Il mio Blog (Italiano)", "https://example.com", "Il mio blog personale")
  |> rss.output("/rss-it.xml")
  |> rss.language("it")
  |> rss.filter(fn(meta) {
    meta.post.language == option.Some("it")
  })

let cfg =
  config.new("https://example.com")
  |> config.rss_feed(en_feed)
  |> config.rss_feed(it_feed)
```

## FeedMetadata

The `FeedMetadata(msg)` type (from `blogatto/config/feed`) passed to `filter` and `serialize` functions:

| Field  | Type        | Description                                          |
| ------ | ----------- | ---------------------------------------------------- |
| `path` | `String`    | URL path (e.g., `"/blog/my-post"`)                   |
| `post` | `Post(msg)` | The full parsed blog post (includes `excerpt` field) |
| `url`  | `String`    | The absolute URL of the post                         |

## RssFeedItem

The `RssFeedItem` type returned by `serialize` functions:

| Field         | Type                | Description                 |
| ------------- | ------------------- | --------------------------- |
| `title`       | `String`            | Item title (required)       |
| `description` | `String`            | Item description (required) |
| `link`        | `Option(String)`    | Item URL                    |
| `author`      | `Option(String)`    | Author email or name        |
| `comments`    | `Option(String)`    | Comments URL                |
| `source`      | `Option(String)`    | Source feed URL             |
| `pub_date`    | `Option(Timestamp)` | Publication date            |
| `categories`  | `List(String)`      | Category tags               |
| `enclosure`   | `Option(Enclosure)` | Media attachment            |
| `guid`        | `Option(String)`    | Globally unique identifier  |
