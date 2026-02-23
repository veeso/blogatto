//// Configuration for generating RSS feeds from blog articles.
////
//// Each `FeedConfig` defines a single RSS feed output. Multiple feeds can be
//// configured (e.g., one per language) by adding multiple `FeedConfig` values
//// to the main `Config` via `config.feed()`.
////
//// During the build, each blog post's metadata is passed to the optional
//// `filter` and `serialize` functions to control which posts appear in the
//// feed and how they are represented.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config/feed
////
//// let rss =
////   feed.FeedConfig(
////     excerpt_len: 200,
////     filter: option.None,
////     output: "/rss.xml",
////     serialize: option.None,
////     title: "My Blog",
////   )
//// ```

import blogatto/post.{type Post}
import gleam/option.{type Option}
import gleam/time/timestamp

/// Configuration for a single RSS feed output.
///
/// The `filter` function, when provided, determines which posts are included.
/// The `serialize` function, when provided, controls how post metadata maps
/// to feed items. When either is `None`, a default behavior is used.
pub type FeedConfig(msg) {
  FeedConfig(
    /// Maximum character length for auto-generated article excerpts.
    excerpt_len: Int,
    /// Optional predicate to include or exclude posts from this feed.
    filter: Option(fn(FeedMetadata(msg)) -> Bool),
    /// Output file path for the generated feed, relative to `output_dir` (e.g., `"/rss.xml"`).
    output: String,
    /// Optional function to convert post metadata into a feed item.
    serialize: Option(fn(FeedMetadata(msg)) -> FeedItem),
    /// Title displayed in the RSS channel header.
    title: String,
  )
}

/// Metadata for a blog article passed to `FeedConfig` filter and serialize functions.
///
/// This provides enough context for the user to decide whether a post should
/// appear in a feed and how it should be represented.
pub type FeedMetadata(msg) {
  FeedMetadata(
    /// The article's URL path (e.g., `"/blog/my-post"`).
    path: String,
    /// An excerpt extracted from the article body, up to `excerpt_len` characters.
    excerpt: String,
    /// The parsed blog post with all frontmatter fields and rendered contents.
    post: Post(msg),
    /// Post absolute url
    url: String,
  )
}

/// An RSS feed item enclosure (e.g., a podcast audio file or image).
pub type Enclosure {
  Enclosure(url: String, length: Int, enclosure_type: String)
}

/// A serialized RSS feed item produced by the `serialize` function.
///
/// Fields mirror the standard RSS 2.0 `<item>` element. Only `title` and
/// `description` are required; the remaining fields are optional.
pub type FeedItem {
  FeedItem(
    /// Title of the feed entry.
    title: String,
    /// Human-readable description or summary of the item.
    description: String,
    /// The full URL for this entry.
    link: Option(String),
    /// Author email or name for this entry.
    author: Option(String),
    /// URL pointing to comments for this item.
    comments: Option(String),
    /// Source feed URL where this item originated.
    source: Option(String),
    /// Publication timestamp for this feed entry.
    pub_date: Option(timestamp.Timestamp),
    /// Category tags for this item.
    categories: List(String),
    /// Media enclosure (e.g., podcast audio, image).
    enclosure: Option(Enclosure),
    /// Globally unique identifier for this feed item.
    guid: Option(String),
  )
}
