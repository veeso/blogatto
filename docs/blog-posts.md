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
| `language` | `Option(String)` | `None` for default, `Some("it")` for variants |
| `featured_image` | `Option(String)` | From frontmatter, if provided |
| `contents` | `List(Element(msg))` | Rendered markdown as Lustre elements |
| `extras` | `Dict(String, String)` | Additional frontmatter fields |

The full list of posts is passed to every route view function and is available during feed and sitemap generation.
