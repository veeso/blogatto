# Changelog

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
