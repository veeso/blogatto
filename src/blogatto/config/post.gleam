//// Configuration for discovering and rendering blog posts.
////
//// The `PostConfig` controls how blog post source files (currently markdown)
//// are discovered, parsed, and rendered into HTML. It holds `Components`
//// used for rendering markdown AST nodes, the filesystem paths to search
//// for post directories, and an optional template function for customizing
//// the blog post page layout.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config/post
////
//// let post_config =
////   post.default()
////   |> post.path("./blog")
////   |> post.h1(fn(id, children) {
////     html.h1([attribute.id(id), attribute.class("title")], children)
////   })
//// ```

import blogatto/config/post/code
import blogatto/post.{type Post, type PostMetadata}
import gleam/list
import gleam/option.{type Option, None}
import lustre/element.{type Element}
import maud/components as maud_components

/// Configuration for discovering and rendering blog posts.
///
/// The `components` field specifies the components used to render each markdown
/// AST node (headings, paragraphs, code blocks, etc.).
/// The `paths` field lists directories to recursively search for post directories.
/// The `route_prefix` field sets the URL prefix under which blog posts are placed
/// in the output directory (e.g., `"blog"` produces `output_dir/blog/{slug}/index.html`).
/// The `template` field optionally overrides the default blog post page template.
pub type PostConfig(msg) {
  PostConfig(
    /// Components used for rendering markdown AST nodes into Lustre elements.
    components: Components(msg),
    /// Maximum character length for auto-generated post excerpts. (default: 200)
    excerpt_len: Int,
    /// Markdown rendering options. Applies to `.md` source files only.
    options: Options,
    /// Directories to recursively search for post directories.
    paths: List(String),
    /// URL prefix for blog post output paths. When `None`, posts are written
    /// directly under `output_dir/{slug}/index.html`. When `Some("blog")`,
    /// posts are written to `output_dir/blog/{slug}/index.html`.
    route_prefix: Option(String),
    /// Function to customize the blog post URL.
    /// It receives the `PostMetadata` and returns the URL path for that post (e.g., `"/my-post/"` or `"/it/my-post/"`).
    /// When set `route_prefix` is IGNORED! This allows you to have full control over the post URLs,
    /// including the ability to place them outside of the route prefix or to use a completely different URL structure.
    /// If not provided the default builder will be used (i.e. `/{route_prefix?}/{lang}/{slug}/` or `/{route_prefix?}/{slug}/` if language is `None`).
    route_builder: Option(fn(PostMetadata) -> String),
    /// Configuration for syntax highlighting in code blocks.
    ///
    /// If not provided, syntax highlighting is disabled by default.
    /// You can enable it with `post.syntax_highlighting(config, code.default())`, or customize it with your own configuration.
    syntax_highlighting: Option(code.SyntaxHighlightingConfig(msg)),
    /// Optional custom template for rendering a blog post page.
    /// Receives the parsed `Post`, and all the other posts, and returns a full page element.
    /// When `None`, Blogatto uses a minimal default template.
    template: Option(fn(Post(msg), List(Post(msg))) -> Element(msg)),
  )
}

/// Text alignment for table cells.
pub type Alignment {
  /// Left-aligned text (the default for most table cells).
  Left
  /// Center-aligned text.
  Center
  /// Right-aligned text.
  Right
}

/// A record of view functions that control how each markdown element is rendered.
///
/// Components are rendered bottom-up: children are rendered first, then passed
/// to the parent component function as a `List(Element(msg))`. When implementing
/// a custom component, you must pass the children into the element you return,
/// otherwise they will not appear in the output.
pub type Components(msg) {
  Components(
    a: fn(String, Option(String), List(Element(msg))) -> Element(msg),
    blockquote: fn(List(Element(msg))) -> Element(msg),
    checkbox: fn(Bool) -> Element(msg),
    code: fn(Option(String), List(Element(msg))) -> Element(msg),
    del: fn(List(Element(msg))) -> Element(msg),
    em: fn(List(Element(msg))) -> Element(msg),
    footnote: fn(Int, List(Element(msg))) -> Element(msg),
    h1: fn(String, List(Element(msg))) -> Element(msg),
    h2: fn(String, List(Element(msg))) -> Element(msg),
    h3: fn(String, List(Element(msg))) -> Element(msg),
    h4: fn(String, List(Element(msg))) -> Element(msg),
    h5: fn(String, List(Element(msg))) -> Element(msg),
    h6: fn(String, List(Element(msg))) -> Element(msg),
    hr: fn() -> Element(msg),
    img: fn(String, String, Option(String)) -> Element(msg),
    li: fn(List(Element(msg))) -> Element(msg),
    mark: fn(List(Element(msg))) -> Element(msg),
    ol: fn(Option(Int), List(Element(msg))) -> Element(msg),
    p: fn(List(Element(msg))) -> Element(msg),
    pre: fn(List(Element(msg))) -> Element(msg),
    strong: fn(List(Element(msg))) -> Element(msg),
    table: fn(List(Element(msg))) -> Element(msg),
    tbody: fn(List(Element(msg))) -> Element(msg),
    td: fn(Alignment, List(Element(msg))) -> Element(msg),
    th: fn(Alignment, List(Element(msg))) -> Element(msg),
    thead: fn(List(Element(msg))) -> Element(msg),
    tr: fn(List(Element(msg))) -> Element(msg),
    ul: fn(List(Element(msg))) -> Element(msg),
  )
}

/// Options for markdown parsing and rendering. Applies to `.md` source files only.
pub type Options {
  Options(
    /// Enable footnote parsing. (Default: True)
    ///
    /// <https://help.obsidian.md/syntax#Footnotes>
    footnotes: Bool,
    /// Custom IDs for headings. Enabling this will add IDs to all headings regardless of whether an explicit ID was provided or not. (Default: False)
    ///
    /// <https://www.markdownguide.org/extended-syntax/#heading-ids>
    heading_ids: Bool,
    /// Enable table parsing. (Default: True)
    ///
    /// <https://help.obsidian.md/advanced-syntax#Tables>
    tables: Bool,
    /// Enable task list parsing. (Default: True)
    ///
    /// <https://github.github.com/gfm/#task-list-items-extension->
    tasklists: Bool,
    /// Emoji shortcodes (e.g., `:smile:`) are converted to Unicode emojis. (Default: True)
    emojis_shortcodes: Bool,
    /// Automatically convert plain URLs into clickable links, even without
    /// angle brackets or explicit link syntax. (Default: True)
    autolinks: Bool,
  )
}

/// Create a default `PostConfig` with default components,
/// no search paths, no route prefix, no custom route builder, and no custom template.
pub fn default() -> PostConfig(msg) {
  PostConfig(
    components: default_components(),
    excerpt_len: 200,
    options: default_options(),
    paths: [],
    route_prefix: None,
    route_builder: None,
    syntax_highlighting: None,
    template: None,
  )
}

/// Return the default markdown parsing options, with:
///
/// - Footnotes enabled
/// - Heading IDs disabled
/// - Table parsing enabled
/// - Task list parsing enabled
/// - Emoji shortcodes enabled
/// - Extended autolinks enabled
pub fn default_options() -> Options {
  Options(
    footnotes: True,
    heading_ids: False,
    tables: True,
    tasklists: True,
    emojis_shortcodes: True,
    autolinks: True,
  )
}

/// Return the default components, rendering each markdown element as its
/// corresponding HTML element without additional attributes or styling.
pub fn default_components() -> Components(msg) {
  from_maud_components(maud_components.default())
}

/// Set the `Components` used for rendering posts.
pub fn components(
  config: PostConfig(msg),
  components: Components(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components:)
}

/// Set the maximum character length for auto-generated post excerpts.
pub fn excerpt_len(config: PostConfig(msg), len: Int) -> PostConfig(msg) {
  PostConfig(..config, excerpt_len: len)
}

/// Add a directory path to search for post directories.
///
/// Paths are searched recursively, so adding `"./blog"` also covers
/// `"./blog/nested"`. There is no need to add subdirectories separately.
pub fn path(config: PostConfig(msg), path: String) -> PostConfig(msg) {
  PostConfig(..config, paths: list.prepend(config.paths, path))
}

/// Set markdown parsing options.
pub fn options(config: PostConfig(msg), options: Options) -> PostConfig(msg) {
  PostConfig(..config, options:)
}

/// Set the URL prefix used for blog post output paths.
///
/// When set to `"blog"`, posts are written to
/// `output_dir/blog/{slug}/index.html` (or `output_dir/blog/{lang}/{slug}/index.html`
/// for localized posts). When not set, posts go directly under `output_dir`.
///
/// This prefix also affects the absolute URLs generated for each post
/// (used in RSS feeds and sitemaps). For example, with a site URL of
/// `"https://example.com"` and a route prefix of `"blog"`, post URLs
/// become `"https://example.com/blog/{slug}/"`.
pub fn route_prefix(
  config: PostConfig(msg),
  prefix: String,
) -> PostConfig(msg) {
  PostConfig(..config, route_prefix: option.Some(prefix))
}

/// Set a custom route builder function for blog post URLs.
///
/// The route builder receives the `PostMetadata` and returns the URL path for that post (e.g., `"/my-post/"` or `"/it/my-post/"`).
/// Do not add `index.html` to the returned path.
///
/// When set, the `route_prefix` field is IGNORED!
/// This allows you to have full control over the post URLs,
/// including the ability to place them outside of the route prefix or to use a completely different URL structure.
///
/// If not provided the default builder will be used (i.e. `/{route_prefix?}/{lang}/{slug}/` or `/{route_prefix?}/{slug}/` if language is `None`).
pub fn route_builder(
  config: PostConfig(msg),
  builder: fn(PostMetadata) -> String,
) -> PostConfig(msg) {
  PostConfig(..config, route_builder: option.Some(builder))
}

/// Set the configuration for syntax highlighting in code blocks.
pub fn syntax_highlighting(
  config: PostConfig(msg),
  syntax_highlighting: code.SyntaxHighlightingConfig(msg),
) -> PostConfig(msg) {
  PostConfig(..config, syntax_highlighting: option.Some(syntax_highlighting))
}

/// Set a custom template function for rendering blog post pages.
///
/// The template receives a fully parsed `Post` (with rendered contents)
/// and all the other posts, and returns the complete page element. When not set, Blogatto uses
/// a minimal default template with the post title and contents.
pub fn template(
  config: PostConfig(msg),
  template: fn(Post(msg), List(Post(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, template: option.Some(template))
}

// --- Component setters ---

/// Set the `a` component used for links.
///
/// The first argument is the link href, the second is an optional title,
/// and the third is the list of children elements.
pub fn a(
  config: PostConfig(msg),
  view: fn(String, Option(String), List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, a: view))
}

/// Set the `blockquote` component used for block quotes.
pub fn blockquote(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(
    ..config,
    components: Components(..config.components, blockquote: view),
  )
}

/// Set the `checkbox` component used for task list checkboxes.
///
/// The argument indicates whether the checkbox is checked.
pub fn checkbox(
  config: PostConfig(msg),
  view: fn(Bool) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(
    ..config,
    components: Components(..config.components, checkbox: view),
  )
}

/// Set the `code` component used for inline code and code blocks.
///
/// The first argument is the optional language identifier (e.g. `Some("gleam")`
/// for fenced code blocks with a language tag, `None` for inline code).
pub fn code(
  config: PostConfig(msg),
  view: fn(Option(String), List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, code: view))
}

/// Set the `del` component used for strikethrough text.
pub fn del(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, del: view))
}

/// Set the `em` component used for emphasized (italic) text.
pub fn em(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, em: view))
}

/// Set the `footnote` component used for footnote references.
///
/// The first argument is the footnote number, the second is the children elements.
pub fn footnote(
  config: PostConfig(msg),
  view: fn(Int, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(
    ..config,
    components: Components(..config.components, footnote: view),
  )
}

/// Set the `h1` component used for level 1 headings.
///
/// The first argument is the heading id, the second is the children elements.
pub fn h1(
  config: PostConfig(msg),
  view: fn(String, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, h1: view))
}

/// Set the `h2` component used for level 2 headings.
///
/// The first argument is the heading id, the second is the children elements.
pub fn h2(
  config: PostConfig(msg),
  view: fn(String, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, h2: view))
}

/// Set the `h3` component used for level 3 headings.
///
/// The first argument is the heading id, the second is the children elements.
pub fn h3(
  config: PostConfig(msg),
  view: fn(String, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, h3: view))
}

/// Set the `h4` component used for level 4 headings.
///
/// The first argument is the heading id, the second is the children elements.
pub fn h4(
  config: PostConfig(msg),
  view: fn(String, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, h4: view))
}

/// Set the `h5` component used for level 5 headings.
///
/// The first argument is the heading id, the second is the children elements.
pub fn h5(
  config: PostConfig(msg),
  view: fn(String, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, h5: view))
}

/// Set the `h6` component used for level 6 headings.
///
/// The first argument is the heading id, the second is the children elements.
pub fn h6(
  config: PostConfig(msg),
  view: fn(String, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, h6: view))
}

/// Set the `hr` component used for thematic breaks (horizontal rules).
pub fn hr(
  config: PostConfig(msg),
  view: fn() -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, hr: view))
}

/// Set the `img` component used for images.
///
/// The first argument is the image URI, the second is the alt text,
/// and the third is an optional title.
pub fn img(
  config: PostConfig(msg),
  view: fn(String, String, Option(String)) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, img: view))
}

/// Set the `li` component used for list items.
pub fn li(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, li: view))
}

/// Set the `mark` component used for highlighted text.
pub fn mark(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, mark: view))
}

/// Set the `ol` component used for ordered lists.
///
/// The first argument is an optional start number, the second is the
/// list of children elements.
pub fn ol(
  config: PostConfig(msg),
  view: fn(Option(Int), List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, ol: view))
}

/// Set the `p` component used for paragraphs.
pub fn p(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, p: view))
}

/// Set the `pre` component used for preformatted code blocks.
pub fn pre(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, pre: view))
}

/// Set the `strong` component used for bold text.
pub fn strong(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(
    ..config,
    components: Components(..config.components, strong: view),
  )
}

/// Set the `table` component used for tables.
pub fn table(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, table: view))
}

/// Set the `tbody` component used for table body groups.
pub fn tbody(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, tbody: view))
}

/// Set the `td` component used for table data cells.
///
/// The first argument is the column alignment, the second is the
/// list of children elements.
pub fn td(
  config: PostConfig(msg),
  view: fn(Alignment, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, td: view))
}

/// Set the `th` component used for table header cells.
///
/// The first argument is the column alignment, the second is the
/// list of children elements.
pub fn th(
  config: PostConfig(msg),
  view: fn(Alignment, List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, th: view))
}

/// Set the `thead` component used for table header groups.
pub fn thead(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, thead: view))
}

/// Set the `tr` component used for table rows.
pub fn tr(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, tr: view))
}

/// Set the `ul` component used for unordered lists.
pub fn ul(
  config: PostConfig(msg),
  view: fn(List(Element(msg))) -> Element(msg),
) -> PostConfig(msg) {
  PostConfig(..config, components: Components(..config.components, ul: view))
}

// Convert maud `Components` to blogatto `Components`.
fn from_maud_components(c: maud_components.Components(msg)) -> Components(msg) {
  Components(
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
    td: fn(alignment, children) { c.td(to_maud_alignment(alignment), children) },
    th: fn(alignment, children) { c.th(to_maud_alignment(alignment), children) },
    thead: c.thead,
    tr: c.tr,
    ul: c.ul,
  )
}

// Convert blogatto `Alignment` to maud `Alignment`.
fn to_maud_alignment(alignment: Alignment) -> maud_components.Alignment {
  case alignment {
    Left -> maud_components.Left
    Center -> maud_components.Center
    Right -> maud_components.Right
  }
}
