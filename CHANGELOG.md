# Changelog

## 2.0.1

Released on 2026-03-02

### Fixed

- **dev_server:** dev server now redirects with 301 on paths without trailing slash (e.g. `/blog` => `/blog/`)
  > since Blogatto always expects path to have a trailing slash the returned path should always have the trailing slash. Also, currently the dev server returned 404 on a path without trailing slash, instead of serving the page.

## 2.0.0

Released on 2026-02-26

### ⚠ Breaking Changes

- move excerpt from FeedMetadata to Post, excerpt_len from FeedConfig to MarkdownConfig
  > Post(msg) now has a required `excerpt` field.
FeedMetadata no longer has an `excerpt` field. FeedConfig no longer
has an `excerpt_len` field — use `markdown.excerpt_len()` instead.
- pass all posts to blog post template function
  > pass all posts to blog post template function

### Added

- add dev server with file watching, live rebuild, and HTTP serving
- 💥 move excerpt from FeedMetadata to Post, excerpt_len from FeedConfig to MarkdownConfig
  > Excerpt is now computed at post-build time and exposed directly on
  > Post(msg), making it available in route view functions (e.g. blog
  > listing pages) rather than only during feed generation.
  >
  > excerpt_len configuration moves from FeedConfig to MarkdownConfig
  > since it controls how post content is processed during the markdown
  > build step.
- 💥 pass all posts to blog post template function
  > The template function signature changes from `fn(Post(msg)) -> Element(msg)`
  > to `fn(Post(msg), List(Post(msg))) -> Element(msg)`, enabling templates to
  > access all other posts for related posts, navigation, etc.

### Documentation

- add dev server documentation page

## 1.0.2

Released on 2026-02-25

- Fixed:
  - truncate excerpts at word boundaries to avoid broken HTML entities (#2)

## 1.0.1

Released on 2026-02-25

- CI:
  - build example in ci
- Documentation:
  - document slug as required frontmatter field
- Fixed:
  - strip matching quotes from frontmatter values

## 1.0.0

Released on 2026-02-24

- Added:
  - project setup
  - add post type
  - add configuration modules
  - add internal builder modules
  - add module documentation to entry point
  - featured_image to Post type
  - robots builder
  - sitemap builder with full test coverage
  - add RSS 2.0 channel fields to FeedConfig
  - implement feed builder with full test coverage
  - implement pages builder with full test coverage
  - implement static assets builder with full test coverage
  - blog builder
  - update Config routes to accept post list in view functions
  - pass post list to page view functions in pages builder
  - reorder build pipeline to parse blog posts before pages
  - add url field to Post and refactor robots builder
  - add builder pattern to FeedConfig
- Changed:
  - replace FeedMetadata frontmatter dict with Post type
  - drop custom links from SitemapEntry, make priority optional
  - extract path utilities into dedicated internal/path module
  - align FeedItem with RSS 2.0 item structure
- Documentation:
  - rewrite README with comprehensive documentation
  - update CLAUDE.md for route view signature and build order changes
  - add simple_blog example with full build pipeline
  - user and code documentation
  - theme and titles
  - title
  - cname
  - favicon
  - links
  - add example blog walkthrough
  - logo
  - Move logo to website
  - quick start showcase output
- Fixed:
  - address code review findings across codebase
  - pre-release improvements across codebase
  - use tempo for date parsing, add trailing slash to post URLs
- Miscellaneous:
  - add CLAUDE.md
  - update project metadata in gleam.toml
  - featured_image to build pipeline
  - logo
  - manifest
  - funding
- Testing:
  - config module unit tests
  - add full-coverage tests for blogatto.gleam build pipeline
- Style:
  - gleam format
