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
  - `config/feed` — Shared feed types (`FeedMetadata`)
  - `config/feed/rss` — RSS feed configuration (`RssFeedConfig`, `RssFeedItem`)
  - `config/markdown` — Markdown rendering config: Maud components, markdown search paths, excerpt length, and optional blog post template override
  - `config/sitemap` — Sitemap generation config (`SitemapConfig`, `SitemapEntry`, `ChangeFrequency`)
  - `config/robots` — Robots.txt generation config
- **`blogatto/post`** — `Post(msg)` type representing a parsed blog post with title, slug, date, description, excerpt, language, optional featured image, rendered contents, and extras dict.

### Internal Modules (not public API)

- **`blogatto/internal/builder/`** — Build sub-modules (no parent `builder.gleam` orchestrator)
  - `builder/blog` — Markdown parsing, post construction, blog page rendering
  - `builder/pages` — Static page rendering from route dict
  - `builder/feed` — Feed generation orchestrator (delegates to per-format builders)
  - `builder/feed/rss` — RSS feed generation via webls
  - `builder/sitemap` — Sitemap XML generation via webls
  - `builder/robots` — robots.txt generation via webls

### Build Pipeline

`blogatto.build(config)` executes these steps in order:

1. **Clean** — Delete and recreate `output_dir`
2. **Copy static assets** — If `static_dir` is set, copy contents to `output_dir`
3. **Build robots.txt** — If configured, generate via webls
4. **Build blog pages** — Walk `markdown_config.paths`, find `index.md`/`index-{lang}.md` per directory, extract frontmatter, render via Maud components, generate plain-text excerpt (truncated to `markdown_config.excerpt_len`), construct `Post(msg)` values, write HTML pages via `markdown_config.template` (or default template, which receives both the current post and all other posts) to `output_dir/{slug}/index.html` or `output_dir/{slug}/index-{lang}.html`. Copy non-markdown assets (images, etc.) from each post's source directory to the output post directory. Produces `List(Post(msg))` used by subsequent steps.
5. **Build static pages** — For each route in `config.routes`, call the view function with the `List(Post(msg))` from step 4, write HTML
6. **Build feeds** — For each `RssFeedConfig`, filter/serialize posts into RSS via webls
7. **Build sitemap** — If configured, collect all routes and blog post URLs, apply filter/serialize, generate XML

### Key Design Patterns

- **Builder pattern**: Configuration is built via functional composition — `config.new(site_url)` piped through `config.rss_feed()`, `config.route()`, `config.output_dir()`, etc.
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

The `pages.yml` workflow builds the mdBook docs and deploys to GitHub Pages on push to `main` when `docs/**` changes (or via manual dispatch).

## Documentation

The user-facing docs live in `docs/` and are built with [mdBook](https://rust-lang.github.io/mdBook/). Domain: `blogat.to` (preserved via `docs/CNAME`). API reference docs are published separately on HexDocs from `///` doc comments.

### Structure

```
docs/
├── book.toml                  # mdBook config
├── SUMMARY.md                 # Sidebar / table of contents — every doc page MUST be listed here
├── CNAME                      # GitHub Pages custom domain (blogat.to)
├── favicon.ico, logo.png, og_preview.jpeg  # Static assets, auto-copied by mdBook to book/
├── theme/
│   └── head.hbs               # Custom <head> injection: favicon.ico link + Open Graph / Twitter meta tags
├── index.md                   # Landing page (mapped to "Introduction" in SUMMARY.md)
├── getting-started.md         # Getting Started section
├── example.md
├── blog-posts.md              # Guides section
├── static-pages.md
├── post-components.md
├── syntax-highlighting.md
├── rss-feeds.md
├── atom-feeds.md
├── sitemap-and-robots.md
├── dev-server.md
├── configuration.md           # Reference section
└── error-handling.md
```

mdBook is configured with `src = "."` so doc files live directly under `docs/` (no `src/` subdir). Build output goes to `docs/book/` (gitignored, produced in CI).

mdBook does **not** automatically wire favicons (other than its built-in `theme/favicon.png` / `theme/favicon.svg`) or emit Open Graph / Twitter Card meta tags — those are injected via `docs/theme/head.hbs`, which mdBook appends inside every page's `<head>`. The OG image points at `https://blogat.to/og_preview.jpeg` (absolute URL, required by social-media scrapers); the favicon link uses `{{ path_to_root }}favicon.ico` so it resolves on every page. If you change the site description, OG image, or favicon filename, update `theme/head.hbs` accordingly.

### Adding a new doc page

1. Create the new `.md` file directly under `docs/` (flat layout — do not create subdirectories unless adding a whole new top-level section).
2. Decide which top-level section it belongs to: **Getting Started**, **Guides**, or **Reference**. If none fit, add a new `# Section` heading to `SUMMARY.md`.
3. **Always** register the new file in `docs/SUMMARY.md` under the chosen section as `- [Page title](filename.md)`. A page that is not in `SUMMARY.md` will not appear in the sidebar and is not reachable from navigation.
4. Use ATX headings (`#`, `##`, …), start every page with a single `# Title` heading, and follow Markdown conventions enforced by markdownlint.
5. Internal links to other docs use the `.md` extension, e.g. `[Configuration](configuration.md)` or `[Routing](blog-posts.md#custom-routing-with-route_builder)` for anchors. Do not use bare slugs (Jekyll-style) — mdBook resolves links by filename.
6. Update `docs/index.md`'s documentation table if the new page is a top-level guide users should discover from the landing page.

### Modifying or removing a doc page

- Renaming or moving a file: update `docs/SUMMARY.md`, fix all `[text](old.md)` links across `docs/*.md`, and update the landing page table in `docs/index.md` if listed there.
- Deleting a file: remove its entry from `docs/SUMMARY.md` and the landing page table, then grep `docs/` for stale links.
- Always preserve `docs/CNAME` — it pins the `blogat.to` domain.

### Local preview

```bash
mdbook serve docs --open    # Live-reload preview at http://localhost:3000
mdbook build docs           # One-shot build to docs/book/
```

## Conventions

- Conventional commits (feat, fix, refactor, perf, doc, test, ci, chore) — changelog generated with git-cliff
- Test files in `test/` named `*_test.gleam`, test functions suffixed `_test`
- Internal modules under `internal/` are not public API
- Module docs use `////` comments; public functions/types get `///` doc comments
- Follow Gleam official conventions: qualified imports only (except types/constructors), snake_case functions, PascalCase types, singular module names
- Libraries must never use `let assert` or `panic` — return `Result` instead
- When adding a doc file under `docs/`, also register it in `docs/SUMMARY.md` under the matching section (see Documentation above)
