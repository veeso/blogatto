//// Feed builder

import blogatto/config
import blogatto/config/feed as feed_config
import blogatto/error
import blogatto/internal/builder/feed/rss as rss_builder
import gleam/result

/// Build the RSS feed XML based on the list of posts and feed configuration.
pub fn build(
  output_dir: String,
  config: config.Config(msg),
  metadata: List(feed_config.FeedMetadata(msg)),
) -> Result(Nil, error.BlogattoError) {
  use _ <- result.try(
    rss_builder.build(output_dir, config.rss_feeds, metadata)
    |> result.replace(Nil),
  )
  Ok(Nil)
}
