---
layout: default
title: Blog posts
nav_order: 4
---

# Blog posts

Blogatto discovers blog posts from markdown files with YAML frontmatter. This guide covers the directory convention, frontmatter fields, multilingual support, and post assets.

## Directory-per-post convention

Each blog post lives in its own directory. The directory name becomes the post's **slug** (URL-friendly identifier):

```text
blog/
  my-first-post/         # slug: "my-first-post"
    index.md             # Default language
    index-it.md          # Italian variant
    index-fr.md          # French variant
    cover.jpg            # Asset copied to output
  another-post/          # slug: "another-post"
    index.md
    diagram.png
```

Blogatto searches all directories listed in `markdown.markdown_path()` recursively.

## Frontmatter

Each markdown file must start with a YAML frontmatter block:

```markdown
---
title: My First Post
slug: my-first-post
date: 2025-01-15 00:00:00
description: A short description of the post
featured_image: /images/hero.jpg
---

Your markdown content here...
```

### Required fields

| Field | Format | Description |
|-------|--------|-------------|
| `title` | String | The post title |
| `slug` | String | URL-friendly identifier for the post |
| `date` | `YYYY-MM-DD HH:MM:SS` | Publication date (UTC) |
| `description` | String | A short description or excerpt |

### Optional fields

| Field | Format | Description |
|-------|--------|-------------|
| `featured_image` | String | URL or path to a featured image |

### Extra fields

Any frontmatter keys beyond the required and optional fields are collected in `Post.extras` as a `Dict(String, String)`. This is useful for custom metadata like tags, categories, or author names:

```markdown
---
title: My Post
slug: my-post
date: 2025-01-15 00:00:00
description: A post about Gleam
author: Jane Doe
tags: gleam, web
---
```

Access extras in your views:

```gleam
import gleam/dict

case dict.get(post.extras, "author") {
  Ok(author) -> html.span([], [element.text("By " <> author)])
  Error(Nil) -> element.none()
}
```

## Multilingual posts

Language variants use the `index-{lang}.md` naming convention:

| Filename | Language |
|----------|----------|
| `index.md` | Default (no language set, `Post.language` is `None`) |
| `index-en.md` | English (`Post.language` is `Some("en")`) |
| `index-it.md` | Italian (`Post.language` is `Some("it")`) |
| `index-fr.md` | French (`Post.language` is `Some("fr")`) |

Each variant is an independent `Post` with its own frontmatter. You can have different titles and descriptions per language:

```text
blog/
  hello-world/
    index.md        # title: "Hello World"
    index-it.md     # title: "Ciao Mondo"
```

### Output paths

When a `route_prefix` is set (e.g., `"blog"`):

| Input | Output |
|-------|--------|
| `hello-world/index.md` | `dist/blog/hello-world/index.html` |
| `hello-world/index-it.md` | `dist/blog/it/hello-world/index.html` |

Without a `route_prefix`:

| Input | Output |
|-------|--------|
| `hello-world/index.md` | `dist/hello-world/index.html` |
| `hello-world/index-it.md` | `dist/it/hello-world/index.html` |

### Custom routing with `route_builder`

For full control over post URLs, use `markdown.route_builder()` instead of `route_prefix`. The route builder receives a `PostMetadata` value and returns the URL path for that post. When set, the `route_prefix` is ignored.

```gleam
import blogatto/config/markdown
import blogatto/post
import gleam/int
import gleam/option
import gleam/time/calendar

let md =
  markdown.default()
  |> markdown.markdown_path("./blog")
  |> markdown.route_builder(fn(meta: post.PostMetadata) {
    let #(year, month, _day) = calendar.to_date(meta.date)
    "/blog/" <> int.to_string(year) <> "/" <> int.to_string(month) <> "/" <> meta.slug <> "/"
  })
```

This produces date-based URLs like `/blog/2024/1/my-post/` and filesystem paths like `dist/blog/2024/1/my-post/index.html`.

The route builder can also incorporate language:

```gleam
markdown.route_builder(fn(meta: post.PostMetadata) {
  let lang_prefix = case meta.language {
    option.Some(lang) -> "/" <> lang
    option.None -> ""
  }
  lang_prefix <> "/blog/" <> meta.slug <> "/"
})
```

Blogatto normalizes the returned path: a leading `/` is added if missing, and a trailing `/` is appended if missing.

#### `PostMetadata` fields

The `PostMetadata` type contains all frontmatter-derived fields available at routing time:

| Field | Type | Description |
|-------|------|-------------|
| `title` | `String` | From frontmatter |
| `slug` | `String` | From frontmatter |
| `date` | `Timestamp` | From frontmatter |
| `description` | `String` | From frontmatter |
| `language` | `Option(String)` | `None` for default, `Some("it")` for variants |
| `featured_image` | `Option(String)` | From frontmatter, if provided |
| `extras` | `Dict(String, String)` | Additional frontmatter fields |

Note that `PostMetadata` intentionally excludes `url` (which is the output of the route builder), `excerpt`, and `contents` (which are not available at routing time).

### Filtering posts by language

In route views, filter the post list by language to build language-specific pages:

```gleam
import gleam/list
import gleam/option.{None, Some}

fn english_posts(posts: List(Post(Nil))) -> List(Post(Nil)) {
  list.filter(posts, fn(p) {
    p.language == None || p.language == Some("en")
  })
}
```

## Post assets

Non-markdown files in a post directory (images, PDFs, etc.) are automatically copied to the output directory alongside the generated HTML. This means relative links in your markdown work as expected:

```markdown
---
title: My Post
slug: my-post
date: 2025-01-15 00:00:00
description: A post with images
---

![Photo](./photo.jpg)
```

If `photo.jpg` is in the same directory as `index.md`, it will be copied to the output and the relative link will resolve correctly.

## The Post type

After parsing, each markdown file produces a `Post(msg)` value with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `title` | `String` | From frontmatter |
| `slug` | `String` | From frontmatter |
| `url` | `String` | Absolute URL (e.g., `"https://example.com/blog/my-post"`) |
| `date` | `Timestamp` | From frontmatter |
| `description` | `String` | From frontmatter |
| `excerpt` | `String` | Auto-generated plain-text excerpt from rendered content, truncated to `excerpt_len` characters |
| `language` | `Option(String)` | `None` for default, `Some("it")` for variants |
| `featured_image` | `Option(String)` | From frontmatter, if provided |
| `contents` | `List(Element(msg))` | Rendered markdown as Lustre elements |
| `extras` | `Dict(String, String)` | Additional frontmatter fields |

The full list of posts is passed to every route view function and is available during feed and sitemap generation.
