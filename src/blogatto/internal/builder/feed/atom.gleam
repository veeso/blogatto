//// Atom Feed builder.
////
//// This module is responsible for generating Atom 1.0 feed XML files from
//// the list of `AtomFeed` configurations declared in the user's `Config`.
////
//// For each configured feed, the builder:
////
////   1. Resolves the absolute output path under `output_dir` and creates
////      the parent directory if needed.
////   2. Filters the supplied list of `FeedMetadata` using the configured
////      `filter` function (or a default that includes every post).
////   3. Serializes each remaining metadata into an `AtomFeedItem` using the
////      configured `serialize` function (or a default that produces a
////      minimal entry from the post fields).
////   4. Maps the public `AtomFeed` / `AtomFeedItem` configuration types to
////      the corresponding `webls/atom` types and writes the rendered XML
////      to disk via `simplifile`.
////
//// This module is internal: its API is not part of Blogatto's public surface
//// and may change without notice.

import blogatto/config/feed as feed_config
import blogatto/config/feed/atom as atom_feed_config
import blogatto/error
import blogatto/internal/path
import gleam/list
import gleam/option
import gleam/result
import simplifile
import webls/atom

/// Build the Atom feed XML files based on the list of posts and feed configurations.
///
/// Iterates over every configured `AtomFeed`, generating and writing the
/// corresponding XML file. Returns `Ok(Nil)` once every feed has been built,
/// or the first encountered `BlogattoError`.
pub fn build(
  output_dir: String,
  config: List(atom_feed_config.AtomFeed(msg)),
  metadata: List(feed_config.FeedMetadata(msg)),
) -> Result(Nil, error.BlogattoError) {
  config
  |> list.try_map(fn(feed_config) {
    build_feed(output_dir, feed_config, metadata)
  })
  |> result.replace(Nil)
}

/// Build a single Atom feed XML file based on the provided feed configuration and site metadata,
/// then write it to the output file.
fn build_feed(
  output_dir: String,
  config: atom_feed_config.AtomFeed(msg),
  metadata: List(feed_config.FeedMetadata(msg)),
) -> Result(Nil, error.BlogattoError) {
  let output_path = path.join(output_dir, config.output)
  // create parent directory
  use _ <- result.try(
    output_path
    |> path.parent()
    |> simplifile.create_directory_all()
    |> result.map_error(error.File),
  )

  let filter_fn = option.unwrap(config.filter, or: default_filter)
  let serialize_fn = option.unwrap(config.serialize, or: default_serialize)

  let entries =
    metadata
    |> list.filter_map(fn(post_metadata) {
      case filter_fn(post_metadata) {
        True -> Ok(post_metadata |> serialize_fn() |> feed_item_to_webls())
        False -> Error(Nil)
      }
    })

  let feed = feed_config_to_webls_feed(config, entries)
  let content = atom.to_string(feed)

  output_path
  |> simplifile.write(content)
  |> result.map_error(error.File)
}

/// Default filter function that includes all posts in the feed when no custom filter is provided.
fn default_filter(_metadata: feed_config.FeedMetadata(msg)) -> Bool {
  True
}

/// Default serialize function that converts post metadata into a basic Atom entry when no custom serializer is provided.
fn default_serialize(
  metadata: feed_config.FeedMetadata(msg),
) -> atom_feed_config.AtomFeedItem {
  atom_feed_config.AtomFeedItem(
    id: metadata.url,
    title: atom_feed_config.PlainText(metadata.post.title),
    updated: metadata.post.date,
    authors: [],
    content: option.None,
    link: option.Some(atom_feed_config.Link(
      href: metadata.url,
      rel: option.Some("alternate"),
      content_type: option.None,
      hreflang: option.None,
      title: option.None,
      length: option.None,
    )),
    summary: option.Some(atom_feed_config.PlainText(metadata.post.excerpt)),
    categories: [],
    contributors: [],
    published: option.Some(metadata.post.date),
    rights: option.None,
    source: option.None,
  )
}

/// Convert an `AtomFeedItem` to an `atom.AtomEntry` for XML generation.
fn feed_item_to_webls(item: atom_feed_config.AtomFeedItem) -> atom.AtomEntry {
  atom.AtomEntry(
    id: item.id,
    title: text_to_webls(item.title),
    updated: item.updated,
    authors: list.map(item.authors, person_to_webls),
    content: option.map(item.content, text_to_webls),
    link: option.map(item.link, link_to_webls),
    summary: option.map(item.summary, text_to_webls),
    categories: list.map(item.categories, category_to_webls),
    contributors: list.map(item.contributors, person_to_webls),
    published: item.published,
    rights: option.map(item.rights, text_to_webls),
    source: option.map(item.source, source_to_webls),
  )
}

/// Convert an `AtomFeed` configuration's feed-level fields to an `atom.AtomFeed` for XML generation.
fn feed_config_to_webls_feed(
  config: atom_feed_config.AtomFeed(msg),
  entries: List(atom.AtomEntry),
) -> atom.AtomFeed {
  atom.AtomFeed(
    id: config.id,
    title: text_to_webls(config.title),
    updated: config.updated,
    authors: list.map(config.authors, person_to_webls),
    link: option.map(config.link, link_to_webls),
    categories: list.map(config.categories, category_to_webls),
    contributors: list.map(config.contributors, person_to_webls),
    generator: option.map(config.generator, generator_to_webls),
    icon: config.icon,
    logo: config.logo,
    rights: option.map(config.rights, text_to_webls),
    subtitle: config.subtitle,
    entries:,
  )
}

/// Convert a blogatto `Text` to a webls `atom.Text`.
fn text_to_webls(text: atom_feed_config.Text) -> atom.Text {
  case text {
    atom_feed_config.PlainText(str) -> atom.PlainText(str)
    atom_feed_config.Html(html) -> atom.Html(html)
    atom_feed_config.XHtml(xhtml) -> atom.XHtml(xhtml)
  }
}

/// Convert a blogatto `Person` to a webls `atom.Person`.
fn person_to_webls(person: atom_feed_config.Person) -> atom.Person {
  atom.Person(name: person.name, email: person.email, uri: person.uri)
}

/// Convert a blogatto `Link` to a webls `atom.Link`.
fn link_to_webls(link: atom_feed_config.Link) -> atom.Link {
  atom.Link(
    href: link.href,
    rel: link.rel,
    content_type: link.content_type,
    hreflang: link.hreflang,
    title: link.title,
    length: link.length,
  )
}

/// Convert a blogatto `Category` to a webls `atom.Category`.
fn category_to_webls(cat: atom_feed_config.Category) -> atom.Category {
  atom.Category(term: cat.term, scheme: cat.scheme, label: cat.label)
}

/// Convert a blogatto `Generator` to a webls `atom.Generator`.
fn generator_to_webls(gen: atom_feed_config.Generator) -> atom.Generator {
  atom.Generator(uri: gen.uri, version: gen.version)
}

/// Convert a blogatto `Source` to a webls `atom.Source`.
fn source_to_webls(source: atom_feed_config.Source) -> atom.Source {
  atom.Source(id: source.id, title: source.title, updated: source.updated)
}
