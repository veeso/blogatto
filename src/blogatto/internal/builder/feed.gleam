//// Feed builder

import blogatto/config/feed as feed_config
import blogatto/error
import blogatto/internal/path
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile
import webls/rss

/// Build the RSS feed XML based on the list of posts and feed configuration.
pub fn build(
  output_dir: String,
  config: List(feed_config.FeedConfig(msg)),
  metadata: List(feed_config.FeedMetadata(msg)),
) -> Result(Nil, error.BlogattoError) {
  config
  |> list.try_map(fn(feed_config) {
    build_feed(output_dir, feed_config, metadata)
  })
  |> result.replace(Nil)
}

/// Build a single RSS feed XML file based on the provided feed configuration and site metadata,
/// then write it to the output file.
fn build_feed(
  output_dir: String,
  config: feed_config.FeedConfig(msg),
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

  // Truncate each excerpt to the configured excerpt_len.
  let metadata =
    list.map(metadata, fn(m) {
      feed_config.FeedMetadata(
        ..m,
        excerpt: string.slice(m.excerpt, 0, config.excerpt_len),
      )
    })

  let feed_items =
    metadata
    |> list.filter_map(fn(post_metadata) {
      case filter_fn(post_metadata) {
        True -> Ok(post_metadata |> serialize_fn() |> feed_item_to_webls())
        False -> Error(Nil)
      }
    })

  let channel = feed_config_to_webls_channel(config, feed_items)
  let content = rss.to_string([channel])

  output_path
  |> simplifile.write(content)
  |> result.map_error(error.File)
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
    guid: option.map(item.guid, fn(g) { #(g, option.Some(True)) }),
  )
}

/// Convert a `FeedConfig` channel fields to an `rss.RssChannel` for XML generation.
fn feed_config_to_webls_channel(
  config: feed_config.FeedConfig(msg),
  items: List(rss.RssItem),
) -> rss.RssChannel {
  rss.RssChannel(
    title: config.title,
    link: config.link,
    description: config.description,
    language: config.language,
    copyright: config.copyright,
    managing_editor: config.managing_editor,
    web_master: config.web_master,
    pub_date: config.pub_date,
    last_build_date: config.last_build_date,
    categories: config.categories,
    generator: config.generator,
    docs: config.docs,
    cloud: option.map(config.cloud, fn(c) {
      rss.Cloud(
        domain: c.domain,
        port: c.port,
        path: c.path,
        register_procedure: c.register_procedure,
        protocol: c.protocol,
      )
    }),
    ttl: config.ttl,
    image: option.map(config.image, fn(img) {
      rss.Image(
        url: img.url,
        title: img.title,
        link: img.link,
        description: img.description,
        width: img.width,
        height: img.height,
      )
    }),
    text_input: option.map(config.text_input, fn(ti) {
      rss.TextInput(
        title: ti.title,
        description: ti.description,
        name: ti.name,
        link: ti.link,
      )
    }),
    skip_hours: config.skip_hours,
    skip_days: list.map(config.skip_days, weekday_to_webls),
    items: items,
  )
}

/// Convert a blogatto `Weekday` to a webls `rss.Weekday`.
fn weekday_to_webls(day: feed_config.Weekday) -> rss.Weekday {
  case day {
    feed_config.Monday -> rss.Monday
    feed_config.Tuesday -> rss.Tuesday
    feed_config.Wednesday -> rss.Wednesday
    feed_config.Thursday -> rss.Thursday
    feed_config.Friday -> rss.Friday
    feed_config.Saturday -> rss.Saturday
    feed_config.Sunday -> rss.Sunday
  }
}
