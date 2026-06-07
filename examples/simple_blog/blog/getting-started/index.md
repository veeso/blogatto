---
title: Getting Started with Blogatto
slug: getting-started
date: 2025-01-20 00:00:00 Europe/Rome
description: Learn how to set up your first static blog with Blogatto
---

# Getting Started with Blogatto

Setting up a blog with Blogatto is straightforward. Here is how to get going.

## Installation

Add blogatto to your `gleam.toml` dependencies:

```toml
[dependencies]
blogatto = ">= 1.0.0 and < 2.0.0"
```

## Configuration

Create a configuration with routes, markdown paths, and optional features like RSS feeds and sitemaps. Use the builder pattern to compose your config:

```gleam
let cfg =
  config.new("https://example.com")
  |> config.output_dir("./dist")
  |> config.markdown(md_config)
  |> config.route("/", home_view)
```

## Writing posts

Each blog post lives in its own directory under the configured markdown path. The directory name becomes the post slug.

A post directory contains:

- `index.md` with frontmatter and content
- Any images or assets referenced in the post

## Building

Run `gleam run` to build your site. The generated HTML, feeds, and sitemap will be written to the output directory.

## Footnotes

Blogatto supports footnotes in Markdown posts[^obsidian]. References are
rendered as clickable links to the definitions at the bottom of the post[^nav],
and each definition links back to where it was referenced[^backref].

Happy blogging!

[^obsidian]: Footnotes use the Obsidian syntax: `[^label]` for the reference and `[^label]: ...` for the definition.

[^nav]: Click a footnote number to jump to its definition.

[^backref]: Use the back-link to return to the reference.
