//// Internal builder for blog post pages.
////
//// Handles markdown file discovery, frontmatter parsing, rendering
//// markdown to Lustre elements via Maud components, and writing
//// blog post HTML pages to the output directory.

import blogatto/config
import blogatto/config/markdown
import blogatto/error
import blogatto/internal/date
import blogatto/internal/excerpt
import blogatto/internal/frontmatter
import blogatto/internal/path
import blogatto/post
import filepath
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleam/string
import gleam/time/timestamp
import lustre/attribute
import lustre/element
import lustre/element/html
import maud
import maud/components as maud_components
import mork
import simplifile

type PostInfo(msg) {
  PostInfo(
    post: post.Post(msg),
    /// Path to the generated HTML file, relative to the output directory. This is used for linking the post in the feed and sitemap, and for copying assets to the correct location.
    html_path: String,
    /// Directory where to copy assets to
    assets_dir: String,
    /// Paths to existing assets to copy, relative to the markdown file
    assets: List(String),
  )
}

type Frontmatter {
  Frontmatter(
    title: String,
    slug: String,
    date: timestamp.Timestamp,
    description: String,
    featured_image: Option(String),
    extras: Dict(String, String),
  )
}

type PostFiles {
  PostFiles(markdowns: List(String), assets: List(String))
}

type MarkdownFile {
  MarkdownFile(path: String, content: String, language: Option(String))
}

/// Build the blog posts based on the blog configuration.
/// 
/// In case of success, returns a list of Post(msg) values representing the discovered and rendered blog posts,
/// which can be used by the feed and sitemap builders.
pub fn build(
  config: config.Config(msg),
) -> Result(List(post.Post(msg)), error.BlogattoError) {
  case config.markdown_config {
    option.Some(markdown_config) -> {
      use posts <- result.try(parse_all_posts_dir(config, markdown_config))
      use built_posts <- result.try(
        list.try_map(posts, fn(post_info) {
          let other_posts =
            posts
            |> list.filter(fn(p) { p.post.slug != post_info.post.slug })
            |> list.map(fn(p) { p.post })
          build_post(post_info, markdown_config, other_posts)
        }),
      )
      // Sort posts by date, newest first.
      Ok(
        list.sort(built_posts, fn(a, b) {
          order.negate(timestamp.compare(a.date, b.date))
        }),
      )
    }
    option.None -> Ok([])
  }
}

/// Build a single blog post page based on the provided PostInfo(msg) and configuration.
/// 
/// The blog post is rendered to HTML via Maud components, and the resulting HTML page is written to the output directory.
/// Assets are copied to the same output directory, preserving their relative paths to the markdown file.
fn build_post(
  post_info: PostInfo(msg),
  markdown_config: markdown.MarkdownConfig(msg),
  all_posts: List(post.Post(msg)),
) -> Result(post.Post(msg), error.BlogattoError) {
  // create the output directory for the post if it doesn't exist
  use _ <- result.try(
    post_info.assets_dir
    |> simplifile.create_directory_all()
    |> result.map_error(error.File),
  )
  // write the HTML file for the post
  let render_template =
    option.unwrap(markdown_config.template, or: default_template)
  let html_content =
    post_info.post
    |> render_template(all_posts)
    |> element.to_document_string()
  // write the HTML file
  use _ <- result.try(
    post_info.html_path
    |> simplifile.write(html_content)
    |> result.map_error(error.File),
  )
  // copy assets to the output directory, preserving their relative paths to the markdown file
  use _ <- result.try(
    post_info.assets
    |> list.try_map(fn(asset_path) {
      let destination_path =
        path.join(post_info.assets_dir, filepath.base_name(asset_path))
      asset_path
      |> simplifile.copy(destination_path)
      |> result.map_error(error.File)
    }),
  )

  Ok(post_info.post)
}

/// Default template to use to wrap the rendered markdown content of a blog post.
/// Uses the post's language for the `lang` attribute (falls back to `"en"`),
/// includes a viewport meta tag, and preloads the featured image when present.
fn default_template(
  post: post.Post(msg),
  _all_posts: List(post.Post(msg)),
) -> element.Element(msg) {
  let lang = option.unwrap(post.language, "en")
  html.html([attribute.lang(lang)], [
    html.head([], [
      html.meta([attribute.charset("UTF-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1.0"),
      ]),
      html.title([], post.title),
      html.meta([
        attribute.name("description"),
        attribute.content(post.description),
      ]),
      case post.featured_image {
        option.Some(image_url) ->
          html.link([
            attribute.rel("preload"),
            attribute.as_("image"),
            attribute.href(image_url),
          ])
        option.None -> element.none()
      },
    ]),
    html.body([], [html.article([], post.contents)]),
  ])
}

/// Helper function to discover all markdown files in the configured markdown paths, parse them into PostInfo(msg) values, and return a list of all posts to be built.
fn parse_all_posts_dir(
  config: config.Config(msg),
  markdown_config: markdown.MarkdownConfig(msg),
) -> Result(List(PostInfo(msg)), error.BlogattoError) {
  markdown_config.paths
  |> list.try_map(fn(path) { parse_all_posts(path, config, markdown_config) })
  |> result.map(list.flatten)
}

/// Find all posts in a single directory and parse them into Post(msg) values.
/// This involves walking the directory, discovering post directories, parsing frontmatter,
/// rendering markdown via Maud components, and constructing Post(msg) values.
fn parse_all_posts(
  search_directory: String,
  config: config.Config(msg),
  markdown_config: markdown.MarkdownConfig(msg),
) -> Result(List(PostInfo(msg)), error.BlogattoError) {
  use all_posts <- result.try(find_posts(search_directory))

  all_posts
  |> dict.to_list()
  |> list.try_map(fn(post_data) {
    let #(_parent_directory, post_files) = post_data
    parse_posts(post_files, config, markdown_config)
  })
  |> result.map(list.flatten)
}

/// Find all markdown files under a single directory, group them by parent directory,
/// filter out directories without markdown files, and separate markdown files from
/// non-markdown assets.
fn find_posts(
  search_path: String,
) -> Result(Dict(String, PostFiles), error.BlogattoError) {
  use all_files <- result.try(
    search_path
    |> simplifile.get_files()
    |> result.map_error(error.File),
  )
  // let's group directory by parent path, then filter out those that don't contain any markdown files,
  // then for each directory we have left, we can separate markdown files from non-markdown assets.
  all_files
  |> list.group(path.parent)
  |> dict.filter(fn(_dir, files) {
    list.any(files, fn(file) { filepath.extension(file) == Ok("md") })
  })
  |> dict.map_values(fn(_dir, files) {
    let #(markdowns, assets) =
      list.partition(files, fn(file) { filepath.extension(file) == Ok("md") })
    PostFiles(markdowns, assets)
  })
  |> Ok
}

/// Parse all markdown files in a post directory into `PostInfo(msg)` values.
fn parse_posts(
  post_files: PostFiles,
  config: config.Config(msg),
  markdown_config: markdown.MarkdownConfig(msg),
) -> Result(List(PostInfo(msg)), error.BlogattoError) {
  use markdown_files <- result.try(list.try_map(
    post_files.markdowns,
    read_markdown_file,
  ))

  list.try_map(markdown_files, fn(markdown_file) {
    parse_post(markdown_file, config, markdown_config, post_files.assets)
  })
}

/// Parse a single markdown file into a `PostInfo(msg)` value.
fn parse_post(
  markdown_file: MarkdownFile,
  config: config.Config(msg),
  markdown_config: markdown.MarkdownConfig(msg),
  assets: List(String),
) -> Result(PostInfo(msg), error.BlogattoError) {
  // parse frontmatter
  use frontmatter <- result.try(parse_frontmatter(markdown_file.content))

  // build post metadata
  let post_metadata =
    post.PostMetadata(
      title: frontmatter.title,
      slug: frontmatter.slug,
      date: frontmatter.date,
      description: frontmatter.description,
      featured_image: frontmatter.featured_image,
      language: markdown_file.language,
      extras: frontmatter.extras,
    )

  let url_path =
    post_url_path(
      markdown_config.route_prefix,
      markdown_config.route_builder,
      post_metadata,
    )
  let html_path = markdown_html_path(config.output_dir, url_path)
  let url = post_url(config.site_url, url_path)

  // assets dir is the parent of the HTML file
  let assets_dir = path.parent(html_path)
  // render markdown to Lustre via Maud components
  let options =
    mork.configure()
    |> mork.strip_frontmatter(True)
  let rendered_components =
    maud.render_markdown(
      markdown_file.content,
      options,
      to_maud_components(markdown_config.components),
    )
  let excerpt =
    rendered_components
    |> excerpt.extract(markdown_config.excerpt_len)
    |> excerpt.truncate_at_word_boundary(markdown_config.excerpt_len)
  // finally return the PostInfo with all the data needed to build the post page and link it in the feed and sitemap
  Ok(PostInfo(
    html_path: html_path,
    assets_dir: assets_dir,
    assets: assets,
    post: post.Post(
      title: post_metadata.title,
      slug: post_metadata.slug,
      url: url,
      date: post_metadata.date,
      description: post_metadata.description,
      featured_image: post_metadata.featured_image,
      excerpt:,
      language: post_metadata.language,
      extras: post_metadata.extras,
      contents: rendered_components,
    ),
  ))
}

/// Helper function to read a markdown file and return its content along with its language (if specified in the filename).
fn read_markdown_file(
  file_path: String,
) -> Result(MarkdownFile, error.BlogattoError) {
  use content <- result.try(
    file_path
    |> simplifile.read(from: _)
    |> result.map_error(error.File),
  )
  let language = path.language(file_path)

  Ok(MarkdownFile(file_path, content, language))
}

/// Compute the URL path for a blog post based on the optional route prefix, optional route builder, and post metadata.
/// 
/// This function returns the URL path relative to the site root, which is used for linking the post in the feed and sitemap, and for computing the output HTML path.
fn post_url_path(
  route_prefix: Option(String),
  route_builder: Option(fn(post.PostMetadata) -> String),
  metadata: post.PostMetadata,
) -> String {
  case route_builder {
    option.Some(builder) -> post_url_path_from_route_builder(builder, metadata)
    option.None -> post_url_path_from_prefix(route_prefix, metadata)
  }
}

/// Compute the URL path for a blog post based on the route builder and post metadata.
/// 
/// The output of the `route_builder` is used as-is with some sanitization: if it doesn't end with a trailing slash, one is added.
fn post_url_path_from_route_builder(
  route_builder: fn(post.PostMetadata) -> String,
  post_metadata: post.PostMetadata,
) -> String {
  let url =
    post_metadata
    |> route_builder
    |> string.trim
    |> string.replace("index.html", "")

  let url = case string.starts_with(url, "/") {
    True -> url
    False -> "/" <> url
  }

  case string.ends_with(url, "/") {
    True -> url
    False -> url <> "/"
  }
}

/// Compute the URL path for a blog post based on the optional route prefix and post metadata.
/// 
/// The URL path is constructed using the optional `route_prefix`, optional language subdirectory, slug,
/// and always ends with a trailing slash. For example, given `route_prefix = Some("blog")`,
/// `slug = "my-post"`, and `language = None`, the result is `"/blog/my-post/"`.
fn post_url_path_from_prefix(
  route_prefix: Option(String),
  post_metadata: post.PostMetadata,
) -> String {
  let prefix = case route_prefix {
    option.Some(prefix) -> "/" <> prefix
    option.None -> ""
  }
  let lang = case post_metadata.language {
    option.Some(lang) -> "/" <> lang
    option.None -> ""
  }
  prefix <> lang <> "/" <> post_metadata.slug <> "/"
}

/// Determine the output HTML path for a blog post based on the output directory and its URL path from the site root.
fn markdown_html_path(output_dir: String, path: String) -> String {
  output_dir
  |> path.join(path)
  |> path.join("index.html")
}

/// Compute the absolute URL for a blog post.
///
/// Combines `site_url` with the URL path from the site root.
fn post_url(site_url: String, path: String) -> String {
  // Strip trailing slash from site_url to avoid double slashes.
  let base = case string.ends_with(site_url, "/") {
    True -> string.drop_end(site_url, 1)
    False -> site_url
  }
  base <> path
}

/// Helper function to parse the frontmatter of a markdown file and extract the required fields (title, slug, date, description) along with any additional fields.
fn parse_frontmatter(
  content: String,
) -> Result(Frontmatter, error.BlogattoError) {
  use frontmatter <- result.try(frontmatter.parse_content(content))
  use title <- result.try(get_frontmatter_required_field(frontmatter, "title"))
  use slug <- result.try(get_frontmatter_required_field(frontmatter, "slug"))
  use date <- result.try(get_frontmatter_required_field(frontmatter, "date"))
  use description <- result.try(get_frontmatter_required_field(
    frontmatter,
    "description",
  ))
  let featured_image =
    get_frontmatter_optional_field(frontmatter, "featured_image")
  use date <- result.try(date.parse(date))

  // get extras by filtering out the known fields from the frontmatter dictionary
  let extras =
    dict.filter(frontmatter, fn(key, _value) {
      case key {
        "title" -> False
        "slug" -> False
        "date" -> False
        "description" -> False
        "featured_image" -> False
        _ -> True
      }
    })

  Ok(Frontmatter(title, slug, date, description, featured_image, extras))
}

/// Helper function to get a required field from the frontmatter dictionary, returning an error if the field is missing.
fn get_frontmatter_required_field(
  frontmatter: dict.Dict(String, String),
  field_name: String,
) -> Result(String, error.BlogattoError) {
  case dict.get(frontmatter, field_name) {
    Ok(value) -> Ok(value)
    Error(_) -> Error(error.FrontmatterMissingField(field_name))
  }
}

/// Helper function to get an optional field from the frontmatter dictionary, returning None if the field is missing.
fn get_frontmatter_optional_field(
  frontmatter: dict.Dict(String, String),
  field_name: String,
) -> Option(String) {
  dict.get(frontmatter, field_name)
  |> option.from_result
}

// --- Maud component conversion (internal) ---

/// Convert blogatto `Components` to maud `Components`.
fn to_maud_components(
  c: markdown.Components(msg),
) -> maud_components.Components(msg) {
  maud_components.Components(
    a: c.a,
    blockquote: c.blockquote,
    checkbox: c.checkbox,
    code: c.code,
    del: c.del,
    em: c.em,
    footnote: c.footnote,
    h1: c.h1,
    h2: c.h2,
    h3: c.h3,
    h4: c.h4,
    h5: c.h5,
    h6: c.h6,
    hr: c.hr,
    img: c.img,
    li: c.li,
    mark: c.mark,
    ol: c.ol,
    p: c.p,
    pre: c.pre,
    strong: c.strong,
    table: c.table,
    tbody: c.tbody,
    td: fn(alignment, children) {
      c.td(from_maud_alignment(alignment), children)
    },
    th: fn(alignment, children) {
      c.th(from_maud_alignment(alignment), children)
    },
    thead: c.thead,
    tr: c.tr,
    ul: c.ul,
  )
}

/// Convert maud `Alignment` to blogatto `Alignment`.
fn from_maud_alignment(
  alignment: maud_components.Alignment,
) -> markdown.Alignment {
  case alignment {
    maud_components.Left -> markdown.Left
    maud_components.Center -> markdown.Center
    maud_components.Right -> markdown.Right
  }
}
