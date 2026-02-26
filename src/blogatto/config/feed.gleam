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
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp

/// Configuration for a single RSS feed output.
///
/// Channel-level fields mirror the standard RSS 2.0 `<channel>` element.
/// The `filter` and `serialize` functions control which posts appear in the
/// feed and how they are represented. When either is `None`, a default
/// behavior is used.
pub type FeedConfig(msg) {
  FeedConfig(
    /// Optional predicate to include or exclude posts from this feed.
    filter: Option(fn(FeedMetadata(msg)) -> Bool),
    /// Output file path for the generated feed, relative to `output_dir` (e.g., `"/rss.xml"`).
    output: String,
    /// Optional function to convert post metadata into a feed item.
    serialize: Option(fn(FeedMetadata(msg)) -> FeedItem),
    /// Title displayed in the RSS channel header.
    title: String,
    /// The URL of the website corresponding to this channel.
    link: String,
    /// A description of the channel.
    description: String,
    /// The language the channel is written in (e.g., "en-us").
    language: Option(String),
    /// Copyright notice for the channel content.
    copyright: Option(String),
    /// Email address for the managing editor.
    managing_editor: Option(String),
    /// Email address for the webmaster.
    web_master: Option(String),
    /// The publication date of the channel content.
    pub_date: Option(timestamp.Timestamp),
    /// The last time the channel content changed.
    last_build_date: Option(timestamp.Timestamp),
    /// Category tags for the channel.
    categories: List(String),
    /// A string indicating the program used to generate the channel.
    generator: Option(String),
    /// A URL that points to the documentation for the RSS format.
    docs: Option(String),
    /// Cloud service configuration for channel update notifications.
    cloud: Option(Cloud),
    /// Time to live: number of minutes the channel can be cached.
    ttl: Option(Int),
    /// An image to display with the channel.
    image: Option(Image),
    /// A text input area to display with the channel.
    text_input: Option(TextInput),
    /// Hours (0-23) during which aggregators should skip updating.
    skip_hours: List(Int),
    /// Days of the week during which aggregators should skip updating.
    skip_days: List(Weekday),
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
    /// The parsed blog post with all frontmatter fields and rendered contents.
    post: Post(msg),
    /// The absolute URL of the post.
    url: String,
  )
}

/// Cloud configuration for RSS channel update notifications.
pub type Cloud {
  Cloud(
    /// The domain of the cloud service.
    domain: String,
    /// The port for the cloud service.
    port: Int,
    /// The path for the cloud service.
    path: String,
    /// The registration procedure (usually "http-post" or "xml-rpc").
    register_procedure: String,
    /// The protocol used for the cloud service.
    protocol: String,
  )
}

/// An image associated with an RSS channel.
pub type Image {
  Image(
    /// The URL of the image.
    url: String,
    /// The title of the image.
    title: String,
    /// The link associated with the image.
    link: String,
    /// An optional description of the image.
    description: Option(String),
    /// An optional width of the image in pixels.
    width: Option(Int),
    /// An optional height of the image in pixels.
    height: Option(Int),
  )
}

/// A text input field for an RSS channel.
pub type TextInput {
  TextInput(
    /// The title of the text input field.
    title: String,
    /// A description of the text input field's purpose.
    description: String,
    /// The name attribute for the text input field.
    name: String,
    /// The link associated with the text input field.
    link: String,
  )
}

/// A day of the week for RSS channel skip days.
pub type Weekday {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
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

// --- Builder API ---

/// Create a new `FeedConfig` with the three required RSS 2.0 channel fields.
///
/// All optional fields receive sensible defaults (`None`, empty lists, or
/// standard values). Use the setter functions to customize them via piping.
pub fn new(title: String, link: String, description: String) -> FeedConfig(msg) {
  FeedConfig(
    filter: None,
    output: "/rss.xml",
    serialize: None,
    title:,
    link:,
    description:,
    language: None,
    copyright: None,
    managing_editor: None,
    web_master: None,
    pub_date: None,
    last_build_date: None,
    categories: [],
    generator: None,
    docs: None,
    cloud: None,
    ttl: None,
    image: None,
    text_input: None,
    skip_hours: [],
    skip_days: [],
  )
}

/// Set the predicate used to include or exclude posts from this feed.
pub fn filter(
  config: FeedConfig(msg),
  f: fn(FeedMetadata(msg)) -> Bool,
) -> FeedConfig(msg) {
  FeedConfig(..config, filter: Some(f))
}

/// Set the output file path for the generated feed, relative to `output_dir`.
pub fn output(config: FeedConfig(msg), path: String) -> FeedConfig(msg) {
  FeedConfig(..config, output: path)
}

/// Set the function used to convert post metadata into a feed item.
pub fn serialize(
  config: FeedConfig(msg),
  f: fn(FeedMetadata(msg)) -> FeedItem,
) -> FeedConfig(msg) {
  FeedConfig(..config, serialize: Some(f))
}

/// Set the language code for the channel (e.g., `"en-us"`).
pub fn language(config: FeedConfig(msg), lang: String) -> FeedConfig(msg) {
  FeedConfig(..config, language: Some(lang))
}

/// Set the copyright notice for the channel content.
pub fn copyright(config: FeedConfig(msg), text: String) -> FeedConfig(msg) {
  FeedConfig(..config, copyright: Some(text))
}

/// Set the email address for the managing editor.
pub fn managing_editor(
  config: FeedConfig(msg),
  email: String,
) -> FeedConfig(msg) {
  FeedConfig(..config, managing_editor: Some(email))
}

/// Set the email address for the webmaster.
pub fn web_master(config: FeedConfig(msg), email: String) -> FeedConfig(msg) {
  FeedConfig(..config, web_master: Some(email))
}

/// Set the publication date of the channel content.
pub fn pub_date(
  config: FeedConfig(msg),
  ts: timestamp.Timestamp,
) -> FeedConfig(msg) {
  FeedConfig(..config, pub_date: Some(ts))
}

/// Set the last time the channel content changed.
pub fn last_build_date(
  config: FeedConfig(msg),
  ts: timestamp.Timestamp,
) -> FeedConfig(msg) {
  FeedConfig(..config, last_build_date: Some(ts))
}

/// Add a category tag to the channel. Prepends to the existing list.
pub fn category(config: FeedConfig(msg), cat: String) -> FeedConfig(msg) {
  FeedConfig(..config, categories: list.prepend(config.categories, cat))
}

/// Set the program name used to generate the channel.
pub fn generator(config: FeedConfig(msg), name: String) -> FeedConfig(msg) {
  FeedConfig(..config, generator: Some(name))
}

/// Set a URL pointing to the documentation for the RSS format.
pub fn docs(config: FeedConfig(msg), url: String) -> FeedConfig(msg) {
  FeedConfig(..config, docs: Some(url))
}

/// Set the cloud service configuration for channel update notifications.
pub fn cloud(config: FeedConfig(msg), cloud: Cloud) -> FeedConfig(msg) {
  FeedConfig(..config, cloud: Some(cloud))
}

/// Set the time-to-live: number of minutes the channel can be cached.
pub fn ttl(config: FeedConfig(msg), minutes: Int) -> FeedConfig(msg) {
  FeedConfig(..config, ttl: Some(minutes))
}

/// Set the image to display with the channel.
pub fn image(config: FeedConfig(msg), image: Image) -> FeedConfig(msg) {
  FeedConfig(..config, image: Some(image))
}

/// Set the text input area to display with the channel.
pub fn text_input(config: FeedConfig(msg), input: TextInput) -> FeedConfig(msg) {
  FeedConfig(..config, text_input: Some(input))
}

/// Add an hour (0-23) during which aggregators should skip updating.
/// Prepends to the existing list.
pub fn skip_hour(config: FeedConfig(msg), hour: Int) -> FeedConfig(msg) {
  FeedConfig(..config, skip_hours: list.prepend(config.skip_hours, hour))
}

/// Add a day of the week during which aggregators should skip updating.
/// Prepends to the existing list.
pub fn skip_day(config: FeedConfig(msg), day: Weekday) -> FeedConfig(msg) {
  FeedConfig(..config, skip_days: list.prepend(config.skip_days, day))
}
