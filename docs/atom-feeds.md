---
layout: default
title: Atom feeds
nav_order: 10
---

# Atom feeds

Blogatto generates Atom 1.0 feeds from your blog posts. You can configure multiple feeds with different filters (e.g., one per language) and customize how posts are serialized into feed entries. Atom feeds work alongside [RSS feeds](rss-feeds) — both can be generated from the same build.

## Basic setup

```gleam
import blogatto/config
import blogatto/config/feed/atom
import gleam/time/timestamp

let atom_feed =
  atom.new(
    id: "https://example.com/",
    title: atom.PlainText("My Blog"),
    updated: timestamp.system_time(),
  )
  |> atom.subtitle("My personal blog")
  |> atom.author(atom.Person(
    name: "Jane Doe",
    email: option.None,
    uri: option.None,
  ))

let cfg =
  config.new("https://example.com")
  |> config.atom_feed(atom_feed)
```

This generates `dist/atom.xml` containing all blog posts with auto-generated summaries. The summary is built from the post excerpt, whose length is controlled by `markdown.excerpt_len()` (default: 200 characters).

## AtomFeed fields

### Required fields (passed to `atom.new()`)

| Field     | Type        | Description                                          |
| --------- | ----------- | ---------------------------------------------------- |
| `id`      | `String`    | Unique feed identifier (typically a URL or URN)      |
| `title`   | `Text`      | Feed title (`PlainText`, `Html`, or `XHtml` variant) |
| `updated` | `Timestamp` | Last time the feed was updated                       |

### Optional fields (set via builder functions)

| Field          | Setter               | Default       | Description                          |
| -------------- | -------------------- | ------------- | ------------------------------------ |
| `output`       | `atom.output()`      | `"/atom.xml"` | Output path relative to `output_dir` |
| `authors`      | `atom.author()`      | `[]`          | Feed authors (prepends)              |
| `link`         | `atom.link()`        | `None`        | Feed link (e.g., the homepage)       |
| `categories`   | `atom.category()`    | `[]`          | Feed categories (prepends)           |
| `contributors` | `atom.contributor()` | `[]`          | Feed contributors (prepends)         |
| `generator`    | `atom.generator()`   | `None`        | Generator program                    |
| `icon`         | `atom.icon()`        | `None`        | Small icon URL                       |
| `logo`         | `atom.logo()`        | `None`        | Larger logo URL                      |
| `rights`       | `atom.rights()`      | `None`        | Rights/copyright information         |
| `subtitle`     | `atom.subtitle()`    | `None`        | Feed subtitle or tagline             |
| `filter`       | `atom.filter()`      | `None`        | Include/exclude posts                |
| `serialize`    | `atom.serialize()`   | `None`        | Custom entry serialization           |

## Filtering posts

Use the `filter` function to control which posts appear in a feed. The function receives `FeedMetadata` (from `blogatto/config/feed`) containing the post and its URL path:

```gleam
import blogatto/config/feed
import gleam/option

// Only include English posts
let atom_feed =
  atom.new(
    id: "https://example.com/",
    title: atom.PlainText("My Blog"),
    updated: timestamp.system_time(),
  )
  |> atom.filter(fn(meta: feed.FeedMetadata(Nil)) {
    meta.post.language == option.None
    || meta.post.language == option.Some("en")
  })
```

## Custom serialization

Override how posts become feed entries with the `serialize` function:

```gleam
import blogatto/config/feed
import blogatto/config/feed/atom
import gleam/option.{None, Some}

let atom_feed =
  atom.new(
    id: "https://example.com/",
    title: atom.PlainText("My Blog"),
    updated: timestamp.system_time(),
  )
  |> atom.serialize(fn(meta: feed.FeedMetadata(Nil)) {
    atom.AtomFeedItem(
      id: meta.url,
      title: atom.PlainText(meta.post.title),
      updated: meta.post.date,
      authors: [
        atom.Person(name: "Jane Doe", email: None, uri: None),
      ],
      content: None,
      link: Some(atom.Link(
        href: meta.url,
        rel: Some("alternate"),
        content_type: Some("text/html"),
        hreflang: None,
        title: None,
        length: None,
      )),
      summary: Some(atom.PlainText(meta.post.excerpt)),
      categories: [],
      contributors: [],
      published: Some(meta.post.date),
      rights: None,
      source: None,
    )
  })
```

## Multiple feeds

Call `config.atom_feed()` multiple times to generate separate feeds:

```gleam
let en_feed =
  atom.new(
    id: "https://example.com/atom.xml",
    title: atom.PlainText("My Blog (English)"),
    updated: timestamp.system_time(),
  )
  |> atom.filter(fn(meta) {
    meta.post.language == option.None
    || meta.post.language == option.Some("en")
  })

let it_feed =
  atom.new(
    id: "https://example.com/atom-it.xml",
    title: atom.PlainText("Il mio Blog (Italiano)"),
    updated: timestamp.system_time(),
  )
  |> atom.output("/atom-it.xml")
  |> atom.filter(fn(meta) {
    meta.post.language == option.Some("it")
  })

let cfg =
  config.new("https://example.com")
  |> config.atom_feed(en_feed)
  |> config.atom_feed(it_feed)
```

## FeedMetadata

The `FeedMetadata(msg)` type (from `blogatto/config/feed`) passed to `filter` and `serialize` functions:

| Field  | Type        | Description                                          |
| ------ | ----------- | ---------------------------------------------------- |
| `path` | `String`    | URL path (e.g., `"/blog/my-post"`)                   |
| `post` | `Post(msg)` | The full parsed blog post (includes `excerpt` field) |
| `url`  | `String`    | The absolute URL of the post                         |

## AtomFeedItem

The `AtomFeedItem` type returned by `serialize` functions:

| Field          | Type                | Description                                |
| -------------- | ------------------- | ------------------------------------------ |
| `id`           | `String`            | Unique entry identifier (required)         |
| `title`        | `Text`              | Entry title (required)                     |
| `updated`      | `Timestamp`         | Last update timestamp (required)           |
| `authors`      | `List(Person)`      | Entry authors                              |
| `content`      | `Option(Text)`      | Full entry content                         |
| `link`         | `Option(Link)`      | Entry link (e.g., the post URL)            |
| `summary`      | `Option(Text)`      | Short summary or description               |
| `categories`   | `List(Category)`    | Entry categories                           |
| `contributors` | `List(Person)`      | Entry contributors                         |
| `published`    | `Option(Timestamp)` | Original publication timestamp             |
| `rights`       | `Option(Text)`      | Rights information for the entry           |
| `source`       | `Option(Source)`    | Reference to original feed when syndicated |

## Text variants

Atom text fields (`title`, `summary`, `content`, `rights`) accept three variants:

- `atom.PlainText(value)` — plain text, special characters escaped on serialization
- `atom.Html(value)` — HTML content (the string is treated as escaped HTML)
- `atom.XHtml(value)` — XHTML content (must be a valid XHTML fragment)
