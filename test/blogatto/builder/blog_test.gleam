import blogatto/config
import blogatto/config/markdown
import blogatto/error
import blogatto/internal/builder/blog as blog_builder
import blogatto/internal/path
import blogatto/post
import gleam/dict
import gleam/list
import gleam/option
import gleam/string
import gleeunit/should
import lustre/attribute
import lustre/element
import lustre/element/html
import simplifile
import temporary

// --- Helpers ---

fn markdown_content(
  title: String,
  slug: String,
  date: String,
  description: String,
  body: String,
) -> String {
  "---\ntitle: "
  <> title
  <> "\nslug: "
  <> slug
  <> "\ndate: "
  <> date
  <> "\ndescription: "
  <> description
  <> "\n---\n"
  <> body
}

fn sample_markdown() -> String {
  markdown_content(
    "Hello World",
    "hello-world",
    "2024-01-15 10:00:00",
    "A test post",
    "# Hello\n\nThis is a test post.\n",
  )
}

fn sample_markdown_with_featured_image() -> String {
  "---\ntitle: Featured Post\nslug: featured-post\ndate: 2024-02-20 12:00:00\ndescription: Post with image\nfeatured_image: /images/hero.jpg\n---\n# Featured\n\nHas an image.\n"
}

fn sample_markdown_with_extras() -> String {
  "---\ntitle: Extra Post\nslug: extra-post\ndate: 2024-03-10 08:00:00\ndescription: Post with extras\nauthor: Alice\ncategory: tech\n---\n# Extras\n\nHas extra fields.\n"
}

/// Config without route_prefix — posts go directly under output_dir.
fn minimal_config(output_dir: String, blog_dir: String) -> config.Config(msg) {
  let md_config =
    markdown.default()
    |> markdown.markdown_path(blog_dir)

  config.new("https://example.com")
  |> config.output_dir(output_dir)
  |> config.markdown(md_config)
}

/// Config with a route_prefix.
fn prefixed_config(
  output_dir: String,
  blog_dir: String,
  prefix: String,
) -> config.Config(msg) {
  let md_config =
    markdown.default()
    |> markdown.markdown_path(blog_dir)
    |> markdown.route_prefix(prefix)

  config.new("https://example.com")
  |> config.output_dir(output_dir)
  |> config.markdown(md_config)
}

fn config_with_template(
  output_dir: String,
  blog_dir: String,
  tmpl: fn(post.Post(msg)) -> element.Element(msg),
) -> config.Config(msg) {
  let md_config =
    markdown.default()
    |> markdown.markdown_path(blog_dir)
    |> markdown.template(tmpl)

  config.new("https://example.com")
  |> config.output_dir(output_dir)
  |> config.markdown(md_config)
}

fn create_post_dir(blog_dir: String, slug: String) -> String {
  let post_dir = blog_dir <> "/" <> slug
  let assert Ok(_) = simplifile.create_directory_all(post_dir)
  post_dir
}

fn write_markdown(dir: String, filename: String, content: String) -> Nil {
  let assert Ok(_) = simplifile.write(dir <> "/" <> filename, content)
  Nil
}

/// Expected HTML path when route_prefix is None.
fn expected_html_path(output_dir: String, slug: String) -> String {
  path.join(output_dir, slug)
  |> path.join("index.html")
}

/// Expected HTML path with a route_prefix.
fn expected_prefixed_html_path(
  output_dir: String,
  prefix: String,
  slug: String,
) -> String {
  path.join(output_dir, prefix)
  |> path.join(slug)
  |> path.join("index.html")
}

/// Expected HTML path for a localized post (no prefix).
fn expected_localized_html_path(
  output_dir: String,
  lang: String,
  slug: String,
) -> String {
  path.join(output_dir, lang)
  |> path.join(slug)
  |> path.join("index.html")
}

/// Expected HTML path for a localized post with a route_prefix.
fn expected_prefixed_localized_html_path(
  output_dir: String,
  prefix: String,
  lang: String,
  slug: String,
) -> String {
  path.join(output_dir, prefix)
  |> path.join(lang)
  |> path.join(slug)
  |> path.join("index.html")
}

/// Parent directory of the expected HTML path (where assets are copied).
fn expected_assets_dir(output_dir: String, slug: String) -> String {
  path.parent(expected_html_path(output_dir, slug))
}

// --- No markdown config ---

pub fn build_without_markdown_config_returns_empty_list_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())

    let cfg =
      config.new("https://example.com")
      |> config.output_dir(dir)

    blog_builder.build(cfg)
    |> should.be_ok
    |> should.equal([])
  }
}

// --- Empty markdown directory ---

pub fn build_with_empty_blog_dir_returns_empty_list_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok
    |> should.equal([])
  }
}

// --- Single post ---

pub fn build_single_post_returns_one_post_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    let posts =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    list.length(posts) |> should.equal(1)
  }
}

pub fn build_single_post_has_correct_title_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.title |> should.equal("Hello World")
  }
}

pub fn build_single_post_has_correct_slug_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.slug |> should.equal("hello-world")
  }
}

pub fn build_single_post_has_correct_description_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.description |> should.equal("A test post")
  }
}

pub fn build_single_post_default_language_is_none_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.language |> should.equal(option.None)
  }
}

pub fn build_single_post_creates_html_file_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    // with no route_prefix, HTML goes directly under output_dir/slug/
    let html_path = expected_html_path(dir, "hello-world")

    simplifile.is_file(html_path)
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_single_post_html_contains_rendered_markdown_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "hello-world")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("Hello") |> should.be_true
    content |> string.contains("This is a test post.") |> should.be_true
  }
}

pub fn build_single_post_html_is_a_full_document_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "hello-world")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.starts_with("<!doctype html>") |> should.be_true
  }
}

// --- Featured image ---

pub fn build_post_with_featured_image_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "featured-post")
    write_markdown(post_dir, "index.md", sample_markdown_with_featured_image())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.featured_image |> should.equal(option.Some("/images/hero.jpg"))
  }
}

pub fn build_post_without_featured_image_is_none_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "hello-world")
    write_markdown(post_dir, "index.md", sample_markdown())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.featured_image |> should.equal(option.None)
  }
}

pub fn build_post_featured_image_appears_in_html_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "featured-post")
    write_markdown(post_dir, "index.md", sample_markdown_with_featured_image())

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "featured-post")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("/images/hero.jpg") |> should.be_true
    content |> string.contains("preload") |> should.be_true
  }
}

// --- Extras ---

pub fn build_post_with_extras_collects_extra_fields_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "extra-post")
    write_markdown(post_dir, "index.md", sample_markdown_with_extras())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    dict.get(post.extras, "author") |> should.be_ok |> should.equal("Alice")
    dict.get(post.extras, "category") |> should.be_ok |> should.equal("tech")
  }
}

pub fn build_post_extras_excludes_known_fields_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "extra-post")
    write_markdown(post_dir, "index.md", sample_markdown_with_extras())

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    dict.get(post.extras, "title") |> should.be_error
    dict.get(post.extras, "slug") |> should.be_error
    dict.get(post.extras, "date") |> should.be_error
    dict.get(post.extras, "description") |> should.be_error
  }
}

// --- Multilingual posts ---

pub fn build_multilingual_post_returns_multiple_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "my-post")
    write_markdown(post_dir, "index.md", sample_markdown())
    write_markdown(
      post_dir,
      "index-it.md",
      markdown_content(
        "Ciao Mondo",
        "hello-world",
        "2024-01-15 10:00:00",
        "Un post di test",
        "# Ciao\n\nQuesto e' un post di test.\n",
      ),
    )

    let posts =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    list.length(posts) |> should.equal(2)
  }
}

pub fn build_multilingual_post_has_correct_languages_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "my-post")
    write_markdown(post_dir, "index.md", sample_markdown())
    write_markdown(
      post_dir,
      "index-it.md",
      markdown_content(
        "Ciao Mondo",
        "hello-world",
        "2024-01-15 10:00:00",
        "Un post di test",
        "# Ciao\n",
      ),
    )

    let posts =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    let languages =
      posts
      |> list.map(fn(p: post.Post(_)) { p.language })
      |> list.sort(fn(a, b) {
        string.compare(string.inspect(a), string.inspect(b))
      })

    languages |> should.equal([option.None, option.Some("it")])
  }
}

pub fn build_multilingual_post_creates_language_subdirectory_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "my-post")
    write_markdown(post_dir, "index.md", sample_markdown())
    write_markdown(
      post_dir,
      "index-it.md",
      markdown_content(
        "Ciao Mondo",
        "hello-world",
        "2024-01-15 10:00:00",
        "Un post di test",
        "# Ciao\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    // Italian post goes under the language subdirectory
    let it_path = expected_localized_html_path(dir, "it", "hello-world")

    simplifile.is_file(it_path)
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_multilingual_post_italian_html_contains_italian_content_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "my-post")
    write_markdown(post_dir, "index.md", sample_markdown())
    write_markdown(
      post_dir,
      "index-it.md",
      markdown_content(
        "Ciao Mondo",
        "hello-world",
        "2024-01-15 10:00:00",
        "Un post di test",
        "# Ciao\n\nContenuto italiano.\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let it_path = expected_localized_html_path(dir, "it", "hello-world")

    let assert Ok(content) = simplifile.read(it_path)
    content |> string.contains("Contenuto italiano.") |> should.be_true
  }
}

// --- Multiple posts ---

pub fn build_multiple_posts_returns_all_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post1_dir = create_post_dir(blog, "first-post")
    write_markdown(
      post1_dir,
      "index.md",
      markdown_content(
        "First Post",
        "first-post",
        "2024-01-01 00:00:00",
        "The first",
        "# First\n",
      ),
    )

    let post2_dir = create_post_dir(blog, "second-post")
    write_markdown(
      post2_dir,
      "index.md",
      markdown_content(
        "Second Post",
        "second-post",
        "2024-02-01 00:00:00",
        "The second",
        "# Second\n",
      ),
    )

    let posts =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    list.length(posts) |> should.equal(2)
  }
}

pub fn build_multiple_posts_creates_separate_html_files_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post1_dir = create_post_dir(blog, "first-post")
    write_markdown(
      post1_dir,
      "index.md",
      markdown_content(
        "First Post",
        "first-post",
        "2024-01-01 00:00:00",
        "The first",
        "# First\n",
      ),
    )

    let post2_dir = create_post_dir(blog, "second-post")
    write_markdown(
      post2_dir,
      "index.md",
      markdown_content(
        "Second Post",
        "second-post",
        "2024-02-01 00:00:00",
        "The second",
        "# Second\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    simplifile.is_file(expected_html_path(dir, "first-post"))
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(expected_html_path(dir, "second-post"))
    |> should.be_ok
    |> should.be_true
  }
}

// --- Assets copying ---

pub fn build_copies_assets_alongside_html_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "image-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Image Post",
        "image-post",
        "2024-04-01 00:00:00",
        "Post with image asset",
        "# Image\n\n![photo](photo.jpg)\n",
      ),
    )
    let assert Ok(_) =
      simplifile.write(post_dir <> "/photo.jpg", "fake-image-data")

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let assets_dir = expected_assets_dir(dir, "image-post")
    let asset_path = assets_dir <> "/photo.jpg"

    simplifile.is_file(asset_path)
    |> should.be_ok
    |> should.be_true

    simplifile.read(asset_path)
    |> should.be_ok
    |> should.equal("fake-image-data")
  }
}

pub fn build_copies_multiple_assets_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "multi-asset")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Multi Asset",
        "multi-asset",
        "2024-05-01 00:00:00",
        "Post with multiple assets",
        "# Assets\n",
      ),
    )
    let assert Ok(_) = simplifile.write(post_dir <> "/photo.jpg", "image-data")
    let assert Ok(_) = simplifile.write(post_dir <> "/diagram.svg", "svg-data")

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let assets_dir = expected_assets_dir(dir, "multi-asset")

    simplifile.is_file(assets_dir <> "/photo.jpg")
    |> should.be_ok
    |> should.be_true

    simplifile.is_file(assets_dir <> "/diagram.svg")
    |> should.be_ok
    |> should.be_true
  }
}

// --- Custom template ---

pub fn build_with_custom_template_applies_template_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "custom-tmpl")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Custom",
        "custom-tmpl",
        "2024-06-01 00:00:00",
        "Custom template test",
        "# Custom\n",
      ),
    )

    let custom_template = fn(p: post.Post(msg)) -> element.Element(msg) {
      html.html([], [
        html.head([], [html.title([], p.title)]),
        html.body([], [
          html.div([attribute.class("custom-wrapper")], p.contents),
        ]),
      ])
    }

    config_with_template(dir, blog, custom_template)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "custom-tmpl")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("custom-wrapper") |> should.be_true
  }
}

// --- Default template structure ---

pub fn build_default_template_contains_meta_description_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "meta-test")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Meta Test",
        "meta-test",
        "2024-07-01 00:00:00",
        "Description for meta tag",
        "# Meta\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "meta-test")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("Description for meta tag") |> should.be_true
    content |> string.contains("description") |> should.be_true
  }
}

pub fn build_default_template_contains_title_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "title-test")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Title Test Post",
        "title-test",
        "2024-07-01 00:00:00",
        "desc",
        "# Body\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "title-test")

    let assert Ok(content) = simplifile.read(html_path)
    content
    |> string.contains("<title>Title Test Post</title>")
    |> should.be_true
  }
}

pub fn build_default_template_contains_viewport_meta_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "viewport-test")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Viewport Test",
        "viewport-test",
        "2024-07-01 00:00:00",
        "desc",
        "# Body\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "viewport-test")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("viewport") |> should.be_true
  }
}

pub fn build_default_template_uses_post_language_for_lang_attr_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "lang-test")
    write_markdown(
      post_dir,
      "index-fr.md",
      markdown_content(
        "Bonjour",
        "lang-test",
        "2024-07-01 00:00:00",
        "French post",
        "# Bonjour\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_localized_html_path(dir, "fr", "lang-test")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("lang=\"fr\"") |> should.be_true
  }
}

pub fn build_default_template_falls_back_to_en_for_default_language_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "en-fallback")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "English Fallback",
        "en-fallback",
        "2024-07-01 00:00:00",
        "desc",
        "# Body\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "en-fallback")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("lang=\"en\"") |> should.be_true
  }
}

pub fn build_default_template_wraps_content_in_article_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "article-test")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Article Test",
        "article-test",
        "2024-07-01 00:00:00",
        "desc",
        "# Body\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_html_path(dir, "article-test")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("<article>") |> should.be_true
  }
}

// --- Error cases ---

pub fn build_returns_error_for_missing_title_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "no-title")
    write_markdown(
      post_dir,
      "index.md",
      "---\nslug: no-title\ndate: 2024-01-01 00:00:00\ndescription: missing title\n---\n# Body\n",
    )

    let result =
      minimal_config(dir, blog)
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissingField("title")) = result
    Nil
  }
}

pub fn build_returns_error_for_missing_slug_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "no-slug")
    write_markdown(
      post_dir,
      "index.md",
      "---\ntitle: No Slug\ndate: 2024-01-01 00:00:00\ndescription: missing slug\n---\n# Body\n",
    )

    let result =
      minimal_config(dir, blog)
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissingField("slug")) = result
    Nil
  }
}

pub fn build_returns_error_for_missing_date_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "no-date")
    write_markdown(
      post_dir,
      "index.md",
      "---\ntitle: No Date\nslug: no-date\ndescription: missing date\n---\n# Body\n",
    )

    let result =
      minimal_config(dir, blog)
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissingField("date")) = result
    Nil
  }
}

pub fn build_returns_error_for_missing_description_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "no-desc")
    write_markdown(
      post_dir,
      "index.md",
      "---\ntitle: No Desc\nslug: no-desc\ndate: 2024-01-01 00:00:00\n---\n# Body\n",
    )

    let result =
      minimal_config(dir, blog)
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissingField("description")) = result
    Nil
  }
}

pub fn build_returns_error_for_invalid_date_format_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "bad-date")
    write_markdown(
      post_dir,
      "index.md",
      "---\ntitle: Bad Date\nslug: bad-date\ndate: not-a-date\ndescription: bad date\n---\n# Body\n",
    )

    let result =
      minimal_config(dir, blog)
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.FrontmatterInvalidDate(_)) = result
    Nil
  }
}

pub fn build_returns_error_for_missing_frontmatter_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "no-fm")
    write_markdown(
      post_dir,
      "index.md",
      "# Just a heading\n\nNo frontmatter.\n",
    )

    let result =
      minimal_config(dir, blog)
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.FrontmatterMissing) = result
    Nil
  }
}

pub fn build_returns_error_for_nonexistent_blog_dir_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())

    let result =
      minimal_config(dir, "/tmp/nonexistent_blogatto_test_dir_xyz")
      |> blog_builder.build()

    result |> should.be_error

    let assert Error(error.File(_)) = result
    Nil
  }
}

// --- Post contents are non-empty ---

pub fn build_post_has_non_empty_contents_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "content-post")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Content Post",
        "content-post",
        "2024-08-01 00:00:00",
        "Has content",
        "# Title\n\nParagraph one.\n\nParagraph two.\n",
      ),
    )

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    list.is_empty(post.contents) |> should.be_false
  }
}

// --- Multiple markdown paths ---

pub fn build_with_multiple_markdown_paths_returns_all_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog1 <- temporary.create(temporary.directory())
    use blog2 <- temporary.create(temporary.directory())

    let post1_dir = create_post_dir(blog1, "post-a")
    write_markdown(
      post1_dir,
      "index.md",
      markdown_content(
        "Post A",
        "post-a",
        "2024-01-01 00:00:00",
        "From blog1",
        "# A\n",
      ),
    )

    let post2_dir = create_post_dir(blog2, "post-b")
    write_markdown(
      post2_dir,
      "index.md",
      markdown_content(
        "Post B",
        "post-b",
        "2024-02-01 00:00:00",
        "From blog2",
        "# B\n",
      ),
    )

    let md_config =
      markdown.default()
      |> markdown.markdown_path(blog1)
      |> markdown.markdown_path(blog2)

    let cfg =
      config.new("https://example.com")
      |> config.output_dir(dir)
      |> config.markdown(md_config)

    let posts =
      cfg
      |> blog_builder.build()
      |> should.be_ok

    list.length(posts) |> should.equal(2)
  }
}

// --- No duplicate posts from multiple paths ---

pub fn build_with_multiple_paths_produces_no_duplicates_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog1 <- temporary.create(temporary.directory())
    use blog2 <- temporary.create(temporary.directory())

    let post1_dir = create_post_dir(blog1, "unique-a")
    write_markdown(
      post1_dir,
      "index.md",
      markdown_content(
        "Unique A",
        "unique-a",
        "2024-01-01 00:00:00",
        "From dir1",
        "# A\n",
      ),
    )

    let post2_dir = create_post_dir(blog2, "unique-b")
    write_markdown(
      post2_dir,
      "index.md",
      markdown_content(
        "Unique B",
        "unique-b",
        "2024-02-01 00:00:00",
        "From dir2",
        "# B\n",
      ),
    )

    let md_config =
      markdown.default()
      |> markdown.markdown_path(blog1)
      |> markdown.markdown_path(blog2)

    let cfg =
      config.new("https://example.com")
      |> config.output_dir(dir)
      |> config.markdown(md_config)

    let posts =
      cfg
      |> blog_builder.build()
      |> should.be_ok

    let titles =
      posts
      |> list.map(fn(p: post.Post(_)) { p.title })
      |> list.sort(string.compare)

    titles |> should.equal(["Unique A", "Unique B"])
  }
}

// --- Post without body ---

pub fn build_post_with_only_frontmatter_and_no_body_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "empty-body")
    write_markdown(
      post_dir,
      "index.md",
      "---\ntitle: Empty Body\nslug: empty-body\ndate: 2024-01-01 00:00:00\ndescription: No body\n---\n",
    )

    let assert [post] =
      minimal_config(dir, blog)
      |> blog_builder.build()
      |> should.be_ok

    post.title |> should.equal("Empty Body")
  }
}

// --- route_prefix ---

pub fn build_with_route_prefix_places_html_under_prefix_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "prefixed")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Prefixed Post",
        "prefixed",
        "2024-09-01 00:00:00",
        "desc",
        "# Prefixed\n",
      ),
    )

    prefixed_config(dir, blog, "blog")
    |> blog_builder.build()
    |> should.be_ok

    let html_path = expected_prefixed_html_path(dir, "blog", "prefixed")

    simplifile.is_file(html_path)
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_with_route_prefix_and_language_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "prefix-lang")
    write_markdown(
      post_dir,
      "index-es.md",
      markdown_content(
        "Hola",
        "prefix-lang",
        "2024-09-01 00:00:00",
        "Spanish post",
        "# Hola\n",
      ),
    )

    prefixed_config(dir, blog, "blog")
    |> blog_builder.build()
    |> should.be_ok

    // output_dir/blog/es/prefix-lang/index.html
    let html_path =
      expected_prefixed_localized_html_path(dir, "blog", "es", "prefix-lang")

    simplifile.is_file(html_path)
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_with_route_prefix_html_contains_content_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "prefix-content")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Prefix Content",
        "prefix-content",
        "2024-09-01 00:00:00",
        "desc",
        "# Hello prefix\n",
      ),
    )

    prefixed_config(dir, blog, "articles")
    |> blog_builder.build()
    |> should.be_ok

    let html_path =
      expected_prefixed_html_path(dir, "articles", "prefix-content")

    let assert Ok(content) = simplifile.read(html_path)
    content |> string.contains("Hello prefix") |> should.be_true
  }
}

pub fn build_without_route_prefix_does_not_embed_source_path_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "no-prefix")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "No Prefix",
        "no-prefix",
        "2024-09-01 00:00:00",
        "desc",
        "# No prefix\n",
      ),
    )

    minimal_config(dir, blog)
    |> blog_builder.build()
    |> should.be_ok

    // HTML should be at output_dir/no-prefix/index.html, NOT under blog source path
    let html_path = expected_html_path(dir, "no-prefix")

    simplifile.is_file(html_path)
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_route_prefix_copies_assets_under_prefix_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    use blog <- temporary.create(temporary.directory())

    let post_dir = create_post_dir(blog, "prefix-assets")
    write_markdown(
      post_dir,
      "index.md",
      markdown_content(
        "Prefix Assets",
        "prefix-assets",
        "2024-09-01 00:00:00",
        "desc",
        "# Assets\n",
      ),
    )
    let assert Ok(_) = simplifile.write(post_dir <> "/photo.png", "image-bytes")

    prefixed_config(dir, blog, "blog")
    |> blog_builder.build()
    |> should.be_ok

    let assets_dir =
      path.parent(expected_prefixed_html_path(dir, "blog", "prefix-assets"))

    simplifile.read(assets_dir <> "/photo.png")
    |> should.be_ok
    |> should.equal("image-bytes")
  }
}
