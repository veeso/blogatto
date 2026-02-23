import blogatto/config/feed.{
  type FeedMetadata, FeedConfig, FeedItem, FeedMetadata,
}
import blogatto/post.{Post}
import gleam/dict
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

fn sample_feed_item() -> feed.FeedItem {
  FeedItem(
    title: "A title",
    description: "A description",
    link: Some("https://example.com/blog/post"),
    author: None,
    comments: None,
    source: None,
    pub_date: Some(timestamp.from_unix_seconds(1_700_000_000)),
    categories: [],
    enclosure: None,
    guid: Some("unique-id-123"),
  )
}

fn sample_feed_config() -> feed.FeedConfig(msg) {
  FeedConfig(
    excerpt_len: 200,
    filter: None,
    output: "/rss.xml",
    serialize: None,
    title: "My Blog",
    link: "https://example.com",
    description: "A sample blog",
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

fn sample_post() -> post.Post(msg) {
  Post(
    title: "Hello",
    slug: "hello",
    url: "https://example.com/hello",
    date: timestamp.from_unix_seconds(1_700_000_000),
    description: "A post",
    language: None,
    featured_image: None,
    contents: [],
    extras: dict.new(),
  )
}

pub fn feed_config_construction_with_defaults_test() {
  let cfg = sample_feed_config()

  cfg.excerpt_len |> should.equal(200)
  cfg.filter |> should.equal(None)
  cfg.output |> should.equal("/rss.xml")
  cfg.serialize |> should.equal(None)
  cfg.title |> should.equal("My Blog")
  cfg.link |> should.equal("https://example.com")
  cfg.description |> should.equal("A sample blog")
  cfg.language |> should.equal(None)
  cfg.copyright |> should.equal(None)
  cfg.managing_editor |> should.equal(None)
  cfg.web_master |> should.equal(None)
  cfg.pub_date |> should.equal(None)
  cfg.last_build_date |> should.equal(None)
  cfg.categories |> should.equal([])
  cfg.generator |> should.equal(None)
  cfg.docs |> should.equal(None)
  cfg.cloud |> should.equal(None)
  cfg.ttl |> should.equal(None)
  cfg.image |> should.equal(None)
  cfg.text_input |> should.equal(None)
  cfg.skip_hours |> should.equal([])
  cfg.skip_days |> should.equal([])
}

pub fn feed_config_with_filter_test() {
  let filter = fn(meta: FeedMetadata(msg)) { meta.path != "/draft" }
  let cfg =
    FeedConfig(
      ..sample_feed_config(),
      excerpt_len: 100,
      filter: Some(filter),
      output: "/feed.xml",
      title: "Filtered",
    )

  cfg.filter |> should.be_some
}

pub fn feed_config_filter_invocation_test() {
  let filter = fn(meta: FeedMetadata(msg)) { meta.path != "/draft" }
  let cfg =
    FeedConfig(
      ..sample_feed_config(),
      excerpt_len: 100,
      filter: Some(filter),
      output: "/feed.xml",
      title: "Filtered",
    )

  let assert Some(f) = cfg.filter
  let published =
    FeedMetadata(
      path: "/blog/post",
      excerpt: "Hello",
      post: sample_post(),
      url: "https://example.com/blog/post",
    )
  let draft =
    FeedMetadata(
      path: "/draft",
      excerpt: "WIP",
      post: sample_post(),
      url: "https://example.com/draft",
    )

  f(published) |> should.be_true
  f(draft) |> should.be_false
}

pub fn feed_config_with_serialize_test() {
  let serialize = fn(meta: FeedMetadata(msg)) {
    FeedItem(
      title: meta.post.title,
      description: meta.excerpt,
      link: Some("https://example.com" <> meta.path),
      author: None,
      comments: None,
      source: None,
      pub_date: None,
      categories: [],
      enclosure: None,
      guid: Some(meta.path),
    )
  }
  let cfg =
    FeedConfig(
      ..sample_feed_config(),
      excerpt_len: 150,
      serialize: Some(serialize),
      title: "With Serializer",
    )

  cfg.serialize |> should.be_some
}

pub fn feed_config_serialize_invocation_test() {
  let serialize = fn(meta: FeedMetadata(msg)) {
    FeedItem(
      title: meta.post.title,
      description: meta.excerpt,
      link: Some("https://example.com" <> meta.path),
      author: None,
      comments: None,
      source: None,
      pub_date: None,
      categories: [],
      enclosure: None,
      guid: Some(meta.path),
    )
  }
  let cfg =
    FeedConfig(
      ..sample_feed_config(),
      excerpt_len: 150,
      serialize: Some(serialize),
      title: "With Serializer",
    )

  let assert Some(s) = cfg.serialize
  let meta =
    FeedMetadata(
      path: "/blog/hello",
      excerpt: "A post",
      post: sample_post(),
      url: "https://example.com/blog/hello",
    )
  let item = s(meta)

  item.description |> should.equal("A post")
  item.guid |> should.equal(Some("/blog/hello"))
  item.link |> should.equal(Some("https://example.com/blog/hello"))
}

pub fn feed_metadata_construction_test() {
  let p =
    Post(
      title: "Hello",
      slug: "hello",
      url: "https://example.com/blog/hello",
      date: timestamp.from_unix_seconds(1_700_000_000),
      description: "A post",
      language: Some("en"),
      featured_image: Some("./featured.jpeg"),
      contents: [],
      extras: dict.from_list([#("lang", "en")]),
    )
  let meta =
    FeedMetadata(
      path: "/blog/hello",
      excerpt: "An excerpt",
      post: p,
      url: "https://example.com/blog/hello",
    )

  meta.path |> should.equal("/blog/hello")
  meta.excerpt |> should.equal("An excerpt")
  meta.post.title |> should.equal("Hello")
  meta.post.featured_image |> should.equal(Some("./featured.jpeg"))
  meta.post.extras |> dict.get("lang") |> should.equal(Ok("en"))
}

pub fn feed_item_construction_test() {
  let item = sample_feed_item()

  item.title |> should.equal("A title")
  item.description |> should.equal("A description")
  item.link |> should.equal(Some("https://example.com/blog/post"))
  item.author |> should.equal(None)
  item.comments |> should.equal(None)
  item.source |> should.equal(None)
  item.pub_date |> should.be_some
  item.categories |> should.equal([])
  item.enclosure |> should.equal(None)
  item.guid |> should.equal(Some("unique-id-123"))
}

pub fn feed_config_with_channel_fields_test() {
  let img =
    feed.Image(
      url: "https://example.com/logo.png",
      title: "Logo",
      link: "https://example.com",
      description: Some("Site logo"),
      width: Some(88),
      height: Some(31),
    )
  let cfg =
    FeedConfig(
      ..sample_feed_config(),
      language: Some("en-us"),
      copyright: Some("2026 Example"),
      managing_editor: Some("editor@example.com"),
      categories: ["tech", "blog"],
      ttl: Some(60),
      image: Some(img),
      skip_hours: [0, 1, 2],
      skip_days: [feed.Saturday, feed.Sunday],
    )

  cfg.language |> should.equal(Some("en-us"))
  cfg.copyright |> should.equal(Some("2026 Example"))
  cfg.managing_editor |> should.equal(Some("editor@example.com"))
  cfg.categories |> should.equal(["tech", "blog"])
  cfg.ttl |> should.equal(Some(60))
  cfg.image |> should.be_some
  cfg.skip_hours |> should.equal([0, 1, 2])
  cfg.skip_days |> should.equal([feed.Saturday, feed.Sunday])
}

pub fn feed_item_with_enclosure_test() {
  let enc =
    feed.Enclosure(
      url: "https://example.com/audio.mp3",
      length: 12_345_678,
      enclosure_type: "audio/mpeg",
    )
  let item =
    FeedItem(..sample_feed_item(), enclosure: Some(enc), categories: ["tech"])

  item.enclosure |> should.be_some
  item.categories |> should.equal(["tech"])
}
