# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Blogatto is a Gleam framework for building static blogs with Lustre and Markdown support. Given a `Config`, a single `blogatto.build(config)` call orchestrates the entire static site generation: parsing markdown with frontmatter, rendering HTML via Maud components, generating RSS feeds, sitemaps, and robots.txt, and copying static assets. Targets Erlang runtime.

Multilingual blog posts are supported via a directory-per-post convention: `index.md` (default language), `index-{lang}.md` (e.g., `index-it.md` for Italian).

## Build & Development Commands

```bash
gleam build              # Compile the project
gleam test               # Run all tests (gleeunit)
gleam format src test    # Format source and test files
gleam format --check src test  # Check formatting (used in CI)
gleam deps download      # Download dependencies
```

There is no single-test runner flag in gleeunit; to run a specific test module, use `gleam test -- --module=<module_name>`.

## Architecture

### Public Modules

- **`blogatto`** — Main entry point. Exposes `build(Config(msg)) -> Result(Nil, BuildError)` which orchestrates the entire build pipeline.
- **`blogatto/config`** — Configuration builder (`Config(msg)` generic type) with functional composition. Routes are defined via `config.route(path, view)` where the view function receives the list of parsed blog posts (`List(Post(msg))`).
  - `config/feed` — RSS feed configuration (`FeedConfig`, `FeedMetadata`, `FeedItem`)
  - `config/markdown` — Markdown rendering config: Maud components, markdown search paths, and optional blog post template override
  - `config/sitemap` — Sitemap generation config (`SitemapConfig`, `SitemapEntry`, `ChangeFrequency`). Custom links (`SitemapLink`) were dropped as webls does not support them.
  - `config/robots` — Robots.txt generation config
- **`blogatto/post`** — `Post(msg)` type representing a parsed blog post with title, slug, date, description, language, optional featured image, rendered contents, and extras dict.

### Internal Modules (not public API)

- **`blogatto/internal/builder`** — Build orchestrator and shared utilities
  - `builder/blog` — Markdown parsing, post construction, blog page rendering
  - `builder/pages` — Static page rendering from route dict
  - `builder/feed` — RSS feed generation via webls
  - `builder/sitemap` — Sitemap XML generation via webls
  - `builder/robots` — robots.txt generation via webls

### Build Pipeline

`blogatto.build(config)` executes these steps in order:

1. **Clean** — Delete and recreate `output_dir`
2. **Copy static assets** — If `static_dir` is set, copy contents to `output_dir`
3. **Build robots.txt** — If configured, generate via webls
4. **Build blog pages** — Walk `markdown_config.paths`, find `index.md`/`index-{lang}.md` per directory, extract frontmatter, render via Maud components, construct `Post(msg)` values, write HTML pages via `markdown_config.template` (or default template) to `output_dir/{slug}/index.html` or `output_dir/{slug}/index-{lang}.html`. Copy non-markdown assets (images, etc.) from each post's source directory to the output post directory. Produces `List(Post(msg))` used by subsequent steps.
5. **Build static pages** — For each route in `config.routes`, call the view function with the `List(Post(msg))` from step 4, write HTML
6. **Build feeds** — For each `FeedConfig`, filter/serialize posts into RSS via webls
7. **Build sitemap** — If configured, collect all routes and blog post URLs, apply filter/serialize, generate XML

### Key Design Patterns

- **Builder pattern**: Configuration is built via functional composition — `config.new(site_url)` piped through `config.feed()`, `config.route()`, `config.output_dir()`, etc.
- **Generic over message type**: `Config(msg)` threads the Lustre message type through the entire configuration and into Post/template types.
- **Route-to-file mapping**: Routes map to `{output_dir}/{route}/index.html` output paths.
- **Closure-based routing**: Static routes stored as `Dict(String, fn(List(Post(msg))) -> Element(msg))`. Each view function receives the full list of parsed blog posts, enabling pages to display featured posts, recent articles, etc.
- **Directory-per-post**: Blog posts live in directories under markdown paths. Each post directory contains `index.md` (default language), optional `index-{lang}.md` variants, and any related assets (images, etc.). Slug = directory name. Language = filename pattern (`index-{lang}.md`). Non-markdown files in the post directory are copied to the output alongside the generated HTML, so relative image links in markdown work as-is.
- **No panics in library code**: All errors return `Result(_, BuildError)`.

### Key Dependencies

- **lustre** — UI framework for rendering HTML elements
- **maud** — HTML component library for markdown rendering
- **mork** — Markdown parser (CommonMark)
- **frontmatter** — Frontmatter extraction from markdown files
- **webls** — RSS, sitemap, and robots.txt generation
- **simplifile** — File I/O operations
- **filepath** — Path manipulation

## CI

GitHub Actions runs on push to main/master and on PRs: deps download, test, format check. Requires OTP 28 and Gleam 1.14.0.

## Conventions

- Conventional commits (feat, fix, refactor, perf, doc, test, ci, chore) — changelog generated with git-cliff
- Test files in `test/` named `*_test.gleam`, test functions suffixed `_test`
- Internal modules under `internal/` are not public API
- Module docs use `////` comments; public functions/types get `///` doc comments
- Follow Gleam official conventions: qualified imports only (except types/constructors), snake_case functions, PascalCase types, singular module names
- Libraries must never use `let assert` or `panic` — return `Result` instead
