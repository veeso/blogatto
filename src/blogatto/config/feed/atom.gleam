//// Configuration for generating Atom 1.0 feeds from blog articles.
////
//// Each `AtomFeed` defines a single Atom feed output. Multiple feeds can be
//// configured (e.g., one per language) by adding multiple `AtomFeed` values
//// to the main `Config` via `config.atom_feed()`.
////
//// During the build, each blog post's metadata is passed to the optional
//// `filter` and `serialize` functions to control which posts appear in the
//// feed and how they are represented as Atom entries.
////
//// The types in this module mirror the Atom 1.0 specification as exposed
//// by the `webls` library used to serialize the feed.
////
//// ## Example
////
//// ```gleam
//// import blogatto/config/feed/atom
//// import gleam/option.{None}
//// import gleam/time/timestamp
////
//// let feed =
////   atom.new(
////     id: "https://example.com/",
////     title: atom.PlainText("My Blog"),
////     updated: timestamp.system_time(),
////   )
////   |> atom.author(atom.Person(
////     name: "Jane Doe",
////     email: None,
////     uri: None,
////   ))
////   |> atom.subtitle("My personal blog")
//// ```

import blogatto/config/feed.{type FeedMetadata}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/time/timestamp

/// Configuration for a single Atom 1.0 feed output.
///
/// Channel-level fields mirror the standard Atom `<feed>` element.
/// The `filter` and `serialize` functions control which posts appear in the
/// feed and how they are represented. When either is `None`, a default
/// behavior is used.
pub type AtomFeed(msg) {
  AtomFeed(
    /// Optional predicate to include or exclude posts from this feed.
    filter: Option(fn(FeedMetadata(msg)) -> Bool),
    /// Output file path for the generated feed, relative to `output_dir` (e.g., `"/atom.xml"`).
    output: String,
    /// Optional function to convert post metadata into a feed entry.
    serialize: Option(fn(FeedMetadata(msg)) -> AtomFeedItem),
    /// The unique identifier of the feed, typically a URL or URN.
    id: String,
    /// Title of the feed.
    title: Text,
    /// Last time the feed was updated.
    updated: timestamp.Timestamp,
    /// List of authors of the feed.
    authors: List(Person),
    /// Optional link associated with the feed (e.g., the homepage).
    link: Option(Link),
    /// List of categories that classify the feed.
    categories: List(Category),
    /// List of contributors to the feed.
    contributors: List(Person),
    /// Optional generator program identifying the software that produced the feed.
    generator: Option(Generator),
    /// Optional small icon URL representing the feed.
    icon: Option(String),
    /// Optional larger logo URL representing the feed.
    logo: Option(String),
    /// Optional rights information for the feed (e.g., a copyright notice).
    rights: Option(Text),
    /// Optional subtitle or tagline for the feed.
    subtitle: Option(String),
  )
}

/// A serialized Atom feed entry produced by the `serialize` function.
///
/// Fields mirror the standard Atom `<entry>` element. Only `id`, `title`,
/// and `updated` are required; the remaining fields are optional.
pub type AtomFeedItem {
  AtomFeedItem(
    /// The unique identifier of the entry, typically a URL or URN.
    id: String,
    /// Title of the entry.
    title: Text,
    /// Last time the entry was updated.
    updated: timestamp.Timestamp,
    /// Authors of this entry.
    authors: List(Person),
    /// Optional body content of the entry.
    content: Option(Text),
    /// Optional link associated with the entry (e.g., the post URL).
    link: Option(Link),
    /// Optional short summary or description of the entry.
    summary: Option(Text),
    /// Categories that classify this entry.
    categories: List(Category),
    /// Contributors to this entry.
    contributors: List(Person),
    /// Optional original publication timestamp.
    published: Option(timestamp.Timestamp),
    /// Optional rights information for the entry.
    rights: Option(Text),
    /// Optional reference to the original feed this entry was syndicated from.
    source: Option(Source),
  )
}

/// An Atom text construct, used for fields like `title`, `summary`,
/// `content`, and `rights`.
pub type Text {
  /// Plain text content. Special characters are escaped on serialization.
  PlainText(value: String)
  /// HTML content. The string is treated as escaped HTML.
  Html(value: String)
  /// XHTML content. The string must be a valid XHTML fragment.
  XHtml(value: String)
}

/// A person referenced as an author or contributor of a feed or entry.
pub type Person {
  Person(
    /// The full name of the person.
    name: String,
    /// Optional email address.
    email: Option(String),
    /// Optional URI associated with the person (e.g., a homepage).
    uri: Option(String),
  )
}

/// A link associated with an Atom feed or entry.
pub type Link {
  Link(
    /// The target URI of the link.
    href: String,
    /// Optional relation type (e.g., `"self"`, `"alternate"`).
    rel: Option(String),
    /// Optional MIME type of the linked resource.
    content_type: Option(String),
    /// Optional language of the linked resource (e.g., `"en"`).
    hreflang: Option(String),
    /// Optional human-readable title of the link.
    title: Option(String),
    /// Optional length in bytes of the linked resource.
    length: Option(Int),
  )
}

/// A category that classifies an Atom feed or entry.
pub type Category {
  Category(
    /// The category term (the actual tag value).
    term: String,
    /// Optional URI identifying the categorization scheme.
    scheme: Option(String),
    /// Optional human-readable label for the category.
    label: Option(String),
  )
}

/// Identifies the software that generated the Atom feed.
pub type Generator {
  Generator(
    /// Optional URI identifying the generator program.
    uri: Option(String),
    /// Optional version string of the generator.
    version: Option(String),
  )
}

/// A reference to the original feed from which an entry was syndicated.
pub type Source {
  Source(
    /// The unique identifier of the source feed.
    id: String,
    /// The title of the source feed.
    title: String,
    /// The last update timestamp of the source feed.
    updated: timestamp.Timestamp,
  )
}

// --- Builder API ---

/// Create a new `AtomFeed` with the three required Atom 1.0 fields.
///
/// All optional fields receive sensible defaults (`None` or empty lists).
/// Use the setter functions to customize them via piping.
pub fn new(
  id id: String,
  title title: Text,
  updated updated: timestamp.Timestamp,
) -> AtomFeed(msg) {
  AtomFeed(
    filter: None,
    output: "/atom.xml",
    serialize: None,
    id:,
    title:,
    updated:,
    authors: [],
    link: None,
    categories: [],
    contributors: [],
    generator: None,
    icon: None,
    logo: None,
    rights: None,
    subtitle: None,
  )
}

/// Set the predicate used to include or exclude posts from this feed.
pub fn filter(
  config: AtomFeed(msg),
  f: fn(FeedMetadata(msg)) -> Bool,
) -> AtomFeed(msg) {
  AtomFeed(..config, filter: Some(f))
}

/// Set the output file path for the generated feed, relative to `output_dir`.
pub fn output(config: AtomFeed(msg), path: String) -> AtomFeed(msg) {
  AtomFeed(..config, output: path)
}

/// Set the function used to convert post metadata into a feed entry.
pub fn serialize(
  config: AtomFeed(msg),
  f: fn(FeedMetadata(msg)) -> AtomFeedItem,
) -> AtomFeed(msg) {
  AtomFeed(..config, serialize: Some(f))
}

/// Add an author to the feed. Prepends to the existing list.
pub fn author(config: AtomFeed(msg), person: Person) -> AtomFeed(msg) {
  AtomFeed(..config, authors: list.prepend(config.authors, person))
}

/// Set the link associated with the feed.
pub fn link(config: AtomFeed(msg), link: Link) -> AtomFeed(msg) {
  AtomFeed(..config, link: Some(link))
}

/// Add a category that classifies the feed. Prepends to the existing list.
pub fn category(config: AtomFeed(msg), cat: Category) -> AtomFeed(msg) {
  AtomFeed(..config, categories: list.prepend(config.categories, cat))
}

/// Add a contributor to the feed. Prepends to the existing list.
pub fn contributor(config: AtomFeed(msg), person: Person) -> AtomFeed(msg) {
  AtomFeed(..config, contributors: list.prepend(config.contributors, person))
}

/// Set the generator program for the feed.
pub fn generator(config: AtomFeed(msg), generator: Generator) -> AtomFeed(msg) {
  AtomFeed(..config, generator: Some(generator))
}

/// Set the URL of a small icon representing the feed.
pub fn icon(config: AtomFeed(msg), url: String) -> AtomFeed(msg) {
  AtomFeed(..config, icon: Some(url))
}

/// Set the URL of a larger logo representing the feed.
pub fn logo(config: AtomFeed(msg), url: String) -> AtomFeed(msg) {
  AtomFeed(..config, logo: Some(url))
}

/// Set the rights information for the feed (e.g., a copyright notice).
pub fn rights(config: AtomFeed(msg), text: Text) -> AtomFeed(msg) {
  AtomFeed(..config, rights: Some(text))
}

/// Set the subtitle or tagline for the feed.
pub fn subtitle(config: AtomFeed(msg), text: String) -> AtomFeed(msg) {
  AtomFeed(..config, subtitle: Some(text))
}
