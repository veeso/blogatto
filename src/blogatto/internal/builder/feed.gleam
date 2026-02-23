//// Feed builder

import blogatto/config
import blogatto/config/feed as feed_config
import blogatto/error
import blogatto/internal/path
import gleam/list
import gleam/option
import gleam/result
import simplifile
import webls/rss

/// Build the RSS feed XML based on the list of posts and feed configuration.
pub fn build(
  config: config.Config(msg),
  metadata: feed_config.FeedMetadata(msg),
) -> Result(Nil, error.BlogattoError) {
  config.feeds
  |> list.try_map(fn(feed_config) {
    build_feed(config.output_dir, config.site_url, feed_config, metadata)
  })
  |> result.replace(Nil)
}

/// Build a single RSS feed XML file based on the provided feed configuration and site metadata,
/// then write it to the output file.
fn build_feed(
  output_dir: String,
  site_url: String,
  config: feed_config.FeedConfig(msg),
  metadata: feed_config.FeedMetadata(msg),
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

  todo
}

/// Default filter function that includes all posts in the feed when no custom filter is provided.
fn default_filter(_metadata: feed_config.FeedMetadata(msg)) -> Bool {
  True
}

/// Default serialize function that converts post metadata into a basic feed item when no custom serializer is provided.
fn default_serialize(
  metadata: feed_config.FeedMetadata(msg),
) -> feed_config.FeedItem {
  feed_config.FeedItem(
    title: metadata.post.title,
    description: metadata.excerpt,
    link: option.Some(metadata.url),
    author: option.None,
    comments: option.None,
    source: option.None,
    pub_date: option.Some(metadata.post.date),
    categories: [],
    enclosure: option.None,
    guid: option.Some(metadata.url),
  )
}

/// Convert a `FeedItem` to an `rss.RssItem` for XML generation.
fn feed_item_to_webls(item: feed_config.FeedItem) -> rss.RssItem {
  rss.RssItem(
    title: item.title,
    description: item.description,
    link: item.link,
    author: item.author,
    comments: item.comments,
    source: item.source,
    pub_date: item.pub_date,
    categories: item.categories,
    enclosure: option.map(item.enclosure, fn(enc) {
      rss.Enclosure(
        url: enc.url,
        length: enc.length,
        enclosure_type: enc.enclosure_type,
      )
    }),
    guid: option.map(item.guid, fn(g) { #(g, option.None) }),
  )
}
