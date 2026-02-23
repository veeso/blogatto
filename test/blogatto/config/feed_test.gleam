import blogatto/config/feed.{
  type FeedMetadata, FeedConfig, FeedItem, FeedMetadata,
}
import gleam/dict
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

pub fn feed_config_construction_with_defaults_test() {
  let cfg =
    FeedConfig(
      excerpt_len: 200,
      filter: None,
      output: "/rss.xml",
      serialize: None,
      title: "My Blog",
    )

  cfg.excerpt_len |> should.equal(200)
  cfg.filter |> should.equal(None)
  cfg.output |> should.equal("/rss.xml")
  cfg.serialize |> should.equal(None)
  cfg.title |> should.equal("My Blog")
}

pub fn feed_config_with_filter_test() {
  let filter = fn(meta: FeedMetadata) { meta.path != "/draft" }
  let cfg =
    FeedConfig(
      excerpt_len: 100,
      filter: Some(filter),
      output: "/feed.xml",
      serialize: None,
      title: "Filtered",
    )

  cfg.filter |> should.be_some
}

pub fn feed_config_filter_invocation_test() {
  let filter = fn(meta: FeedMetadata) { meta.path != "/draft" }
  let cfg =
    FeedConfig(
      excerpt_len: 100,
      filter: Some(filter),
      output: "/feed.xml",
      serialize: None,
      title: "Filtered",
    )

  let assert Some(f) = cfg.filter
  let published =
    FeedMetadata(path: "/blog/post", excerpt: "Hello", frontmatter: dict.new())
  let draft =
    FeedMetadata(path: "/draft", excerpt: "WIP", frontmatter: dict.new())

  f(published) |> should.be_true
  f(draft) |> should.be_false
}

pub fn feed_config_with_serialize_test() {
  let serialize = fn(meta: FeedMetadata) {
    FeedItem(
      custom_elements: dict.new(),
      date: timestamp.from_unix_seconds(0),
      description: meta.excerpt,
      guid: meta.path,
      url: "https://example.com" <> meta.path,
    )
  }
  let cfg =
    FeedConfig(
      excerpt_len: 150,
      filter: None,
      output: "/rss.xml",
      serialize: Some(serialize),
      title: "With Serializer",
    )

  cfg.serialize |> should.be_some
}

pub fn feed_config_serialize_invocation_test() {
  let serialize = fn(meta: FeedMetadata) {
    FeedItem(
      custom_elements: dict.new(),
      date: timestamp.from_unix_seconds(0),
      description: meta.excerpt,
      guid: meta.path,
      url: "https://example.com" <> meta.path,
    )
  }
  let cfg =
    FeedConfig(
      excerpt_len: 150,
      filter: None,
      output: "/rss.xml",
      serialize: Some(serialize),
      title: "With Serializer",
    )

  let assert Some(s) = cfg.serialize
  let meta =
    FeedMetadata(
      path: "/blog/hello",
      excerpt: "A post",
      frontmatter: dict.new(),
    )
  let item = s(meta)

  item.description |> should.equal("A post")
  item.guid |> should.equal("/blog/hello")
  item.url |> should.equal("https://example.com/blog/hello")
}

pub fn feed_metadata_construction_test() {
  let fm = dict.from_list([#("title", "Hello"), #("lang", "en")])
  let meta =
    FeedMetadata(path: "/blog/hello", excerpt: "An excerpt", frontmatter: fm)

  meta.path |> should.equal("/blog/hello")
  meta.excerpt |> should.equal("An excerpt")
  meta.frontmatter |> dict.get("title") |> should.equal(Ok("Hello"))
  meta.frontmatter |> dict.get("lang") |> should.equal(Ok("en"))
}

pub fn feed_item_construction_test() {
  let custom = dict.from_list([#("category", "tech")])
  let item =
    FeedItem(
      custom_elements: custom,
      date: timestamp.from_unix_seconds(1_700_000_000),
      description: "A description",
      guid: "unique-id-123",
      url: "https://example.com/blog/post",
    )

  item.description |> should.equal("A description")
  item.guid |> should.equal("unique-id-123")
  item.url |> should.equal("https://example.com/blog/post")
  item.custom_elements |> dict.get("category") |> should.equal(Ok("tech"))
}
