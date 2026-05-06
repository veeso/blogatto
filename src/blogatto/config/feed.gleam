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
////   feed.new("My Blog", "https://example.com", "My personal blog")
////   |> feed.language("en-us")
////   |> feed.generator("Blogatto")
//// ```

import blogatto/post.{type Post}

/// Metadata for a blog article passed to the feed configuration filter and serialize functions.
///
/// This provides enough context for the user to decide whether a post should
/// appear in a feed and how it should be represented.
pub type FeedMetadata(msg) {
  FeedMetadata(
    /// The article's URL path (e.g., `"/blog/my-post"`).
    path: String,
    /// The parsed blog post with all frontmatter fields and rendered contents.
    post: Post(msg),
    /// The absolute URL of the post.
    url: String,
  )
}
