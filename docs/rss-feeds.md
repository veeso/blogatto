---
layout: default
title: RSS feeds
nav_order: 8
---

# RSS feeds

Blogatto generates RSS 2.0 feeds from your blog posts. You can configure multiple feeds with different filters (e.g., one per language) and customize how posts are serialized into feed items.

## Basic setup

```gleam
import blogatto/config
import blogatto/config/feed

let rss =
  feed.new("My Blog", "https://example.com", "My personal blog")
  |> feed.language("en-us")
  |> feed.generator("Blogatto")

let cfg =
  config.new("https://example.com")
  |> config.feed(rss)
```

This generates `dist/rss.xml` containing all blog posts with auto-generated excerpts of up to 200 characters.

## FeedConfig fields

### Required fields (passed to `feed.new()`)

| Field | Type | Description |
|-------|------|-------------|
| `title` | `String` | Channel title |
| `link` | `String` | Website URL |
| `description` | `String` | Channel description |

### Optional fields (set via builder functions)

| Field | Setter | Default | Description |
|-------|--------|---------|-------------|
| `output` | `feed.output()` | `"/rss.xml"` | Output path relative to `output_dir` |
| `language` | `feed.language()` | `None` | Language code (e.g., `"en-us"`) |
| `copyright` | `feed.copyright()` | `None` | Copyright notice |
| `managing_editor` | `feed.managing_editor()` | `None` | Editor email |
| `web_master` | `feed.web_master()` | `None` | Webmaster email |
| `pub_date` | `feed.pub_date()` | `None` | Channel publication date |
| `last_build_date` | `feed.last_build_date()` | `None` | Last build timestamp |
| `categories` | `feed.category()` | `[]` | Channel category tags (prepends) |
| `generator` | `feed.generator()` | `None` | Generator program name |
| `docs` | `feed.docs()` | `None` | URL to RSS format documentation |
| `cloud` | `feed.cloud()` | `None` | Cloud service for update notifications |
| `ttl` | `feed.ttl()` | `None` | Cache time-to-live in minutes |
| `image` | `feed.image()` | `None` | Channel image |
| `text_input` | `feed.text_input()` | `None` | Channel text input field |
| `skip_hours` | `feed.skip_hour()` | `[]` | Hours (0-23) to skip updates (prepends) |
| `skip_days` | `feed.skip_day()` | `[]` | Days to skip updates (prepends) |
| `filter` | `feed.filter()` | `None` | Include/exclude posts |
| `serialize` | `feed.serialize()` | `None` | Custom item serialization |

## Filtering posts

Use the `filter` function to control which posts appear in a feed. The function receives `FeedMetadata` containing the post and its URL path:

```gleam
import gleam/option

// Only include English posts
let rss =
  feed.new("My Blog", "https://example.com", "My personal blog")
  |> feed.filter(fn(meta: feed.FeedMetadata(Nil)) {
    meta.post.language == option.None
    || meta.post.language == option.Some("en")
  })
```

## Custom serialization

Override how posts become feed items with the `serialize` function:

```gleam
import gleam/dict
import gleam/option.{None, Some}

let rss =
  feed.new("My Blog", "https://example.com", "My personal blog")
  |> feed.serialize(fn(meta: feed.FeedMetadata(Nil)) {
    let author =
      dict.get(meta.post.extras, "author")
      |> result.map(Some)
      |> result.unwrap(None)

    feed.FeedItem(
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

Call `config.feed()` multiple times to generate separate feeds:

```gleam
let en_feed =
  feed.new("My Blog (English)", "https://example.com", "My personal blog")
  |> feed.language("en-us")
  |> feed.filter(fn(meta) {
    meta.post.language == option.None
    || meta.post.language == option.Some("en")
  })

let it_feed =
  feed.new("Il mio Blog (Italiano)", "https://example.com", "Il mio blog personale")
  |> feed.output("/rss-it.xml")
  |> feed.language("it")
  |> feed.filter(fn(meta) {
    meta.post.language == option.Some("it")
  })

let cfg =
  config.new("https://example.com")
  |> config.feed(en_feed)
  |> config.feed(it_feed)
```

## FeedMetadata

The `FeedMetadata(msg)` type passed to `filter` and `serialize` functions:

| Field | Type | Description |
|-------|------|-------------|
| `path` | `String` | URL path (e.g., `"/blog/my-post"`) |
| `post` | `Post(msg)` | The full parsed blog post (includes `excerpt` field) |
| `url` | `String` | The absolute URL of the post |

## FeedItem

The `FeedItem` type returned by `serialize` functions:

| Field | Type | Description |
|-------|------|-------------|
| `title` | `String` | Item title (required) |
| `description` | `String` | Item description (required) |
| `link` | `Option(String)` | Item URL |
| `author` | `Option(String)` | Author email or name |
| `comments` | `Option(String)` | Comments URL |
| `source` | `Option(String)` | Source feed URL |
| `pub_date` | `Option(Timestamp)` | Publication date |
| `categories` | `List(String)` | Category tags |
| `enclosure` | `Option(Enclosure)` | Media attachment |
| `guid` | `Option(String)` | Globally unique identifier |
