---
layout: default
title: RSS feeds
nav_order: 7
---

# RSS feeds

Blogatto generates RSS 2.0 feeds from your blog posts. You can configure multiple feeds with different filters (e.g., one per language) and customize how posts are serialized into feed items.

## Basic setup

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

This generates `dist/rss.xml` containing all blog posts with auto-generated excerpts of up to 200 characters.

## FeedConfig fields

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | `String` | Channel title |
| `link` | `String` | Website URL |
| `description` | `String` | Channel description |
| `output` | `String` | Output path relative to `output_dir` (e.g., `"/rss.xml"`) |
| `excerpt_len` | `Int` | Maximum character length for auto-generated excerpts |

### Optional channel fields

| Field | Type | Description |
|-------|------|-------------|
| `language` | `Option(String)` | Language code (e.g., `"en-us"`) |
| `copyright` | `Option(String)` | Copyright notice |
| `managing_editor` | `Option(String)` | Editor email |
| `web_master` | `Option(String)` | Webmaster email |
| `pub_date` | `Option(Timestamp)` | Channel publication date |
| `last_build_date` | `Option(Timestamp)` | Last build timestamp |
| `categories` | `List(String)` | Channel category tags |
| `generator` | `Option(String)` | Generator program name |
| `docs` | `Option(String)` | URL to RSS format documentation |
| `cloud` | `Option(Cloud)` | Cloud service for update notifications |
| `ttl` | `Option(Int)` | Cache time-to-live in minutes |
| `image` | `Option(Image)` | Channel image |
| `text_input` | `Option(TextInput)` | Channel text input field |
| `skip_hours` | `List(Int)` | Hours (0-23) to skip updates |
| `skip_days` | `List(Weekday)` | Days to skip updates |

### Filtering and serialization

| Field | Type | Description |
|-------|------|-------------|
| `filter` | `Option(fn(FeedMetadata(msg)) -> Bool)` | Include/exclude posts |
| `serialize` | `Option(fn(FeedMetadata(msg)) -> FeedItem)` | Custom item serialization |

## Filtering posts

Use the `filter` function to control which posts appear in a feed. The function receives `FeedMetadata` containing the post, its URL path, and an auto-generated excerpt:

```gleam
import gleam/option.{Some}

// Only include English posts
let rss =
  feed.FeedConfig(
    ..base_config,
    filter: Some(fn(meta: feed.FeedMetadata(Nil)) {
      meta.post.language == option.None
      || meta.post.language == Some("en")
    }),
  )
```

## Custom serialization

Override how posts become feed items with the `serialize` function:

```gleam
import gleam/dict
import gleam/option.{None, Some}

let rss =
  feed.FeedConfig(
    ..base_config,
    serialize: Some(fn(meta: feed.FeedMetadata(Nil)) {
      let author =
        dict.get(meta.post.extras, "author")
        |> result.map(Some)
        |> result.unwrap(None)

      feed.FeedItem(
        title: meta.post.title,
        description: meta.excerpt,
        link: Some(meta.url),
        author: author,
        comments: None,
        source: None,
        pub_date: Some(meta.post.date),
        categories: [],
        enclosure: None,
        guid: Some(meta.url),
      )
    }),
  )
```

## Multiple feeds

Call `config.feed()` multiple times to generate separate feeds:

```gleam
let en_feed =
  feed.FeedConfig(
    ..base_config,
    output: "/rss.xml",
    title: "My Blog (English)",
    language: Some("en-us"),
    filter: Some(fn(meta) {
      meta.post.language == option.None
      || meta.post.language == Some("en")
    }),
  )

let it_feed =
  feed.FeedConfig(
    ..base_config,
    output: "/rss-it.xml",
    title: "Il mio Blog (Italiano)",
    language: Some("it"),
    filter: Some(fn(meta) {
      meta.post.language == Some("it")
    }),
  )

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
| `excerpt` | `String` | Auto-generated excerpt up to `excerpt_len` characters |
| `post` | `Post(msg)` | The full parsed blog post |
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
