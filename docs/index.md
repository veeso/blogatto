---
layout: default
title: Home
nav_order: 1
---

# Blogatto

A Gleam framework for building static blogs with Lustre and Markdown.

Blogatto generates your entire static site from a single configuration: blog posts from markdown with frontmatter, static pages from Lustre views, RSS feeds, sitemaps, and robots.txt — all rendered via [Maud](https://hexdocs.pm/maud/) components.

## Features

- **Blog posts from markdown** — write in markdown with YAML frontmatter, Blogatto handles parsing, rendering, and output
- **Multilingual support** — add `index-it.md`, `index-fr.md`, etc. alongside `index.md` for language variants
- **Static pages** — map URL paths to Lustre view functions that receive the full list of blog posts
- **RSS feeds** — generate one or more RSS 2.0 feeds with optional filtering and custom serialization
- **Sitemap XML** — automatic sitemap generation covering static pages and blog posts
- **Robots.txt** — configurable crawl policies with sitemap reference
- **Custom markdown rendering** — override any markdown element's HTML output via Maud components
- **Blog post templates** — full control over the page layout wrapping each blog post
- **Static asset copying** — copy CSS, images, and other assets into the output directory

## How it works

You define a `Config` using the builder pattern, then call `blogatto.build(config)`. The build pipeline:

1. Cleans and recreates the output directory
2. Copies static assets
3. Generates robots.txt
4. Parses markdown files, extracts frontmatter, renders HTML, and copies post assets
5. Renders static pages from route view functions
6. Generates RSS feeds
7. Generates sitemap XML

The output is a fully static site ready to deploy to any static hosting provider.

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting started](getting-started) | Installation, project setup, and your first build |
| [Blog posts](blog-posts) | Directory structure, frontmatter, multilingual support |
| [Configuration](configuration) | Full configuration reference |
| [Markdown components](markdown-components) | Customizing markdown rendering |
| [Static pages](static-pages) | Routes, view functions, and using post data |
| [RSS feeds](rss-feeds) | Feed configuration, filtering, and serialization |
| [Sitemap and robots.txt](sitemap-and-robots) | Sitemap and crawler configuration |
| [Error handling](error-handling) | Error types and recovery patterns |

## API reference

Full API documentation is available on [HexDocs](https://hexdocs.pm/blogatto/).
