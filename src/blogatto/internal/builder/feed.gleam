//// Feed builder

import blogatto/config
import blogatto/config/feed as feed_config
import blogatto/error
import blogatto/internal/builder/feed/atom as atom_builder
import blogatto/internal/builder/feed/rss as rss_builder
import gleam/result

/// Build the RSS feed XML based on the list of posts and feed configuration.
pub fn build(
  output_dir: String,
  config: config.Config(msg),
  metadata: List(feed_config.FeedMetadata(msg)),
) -> Result(Nil, error.BlogattoError) {
  use _ <- result.try(
    output_dir
    |> rss_builder.build(config.rss_feeds, metadata)
    |> result.replace(Nil),
  )
  output_dir
  |> atom_builder.build(config.atom_feeds, metadata)
  |> result.replace(Nil)
}
