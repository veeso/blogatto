import blogatto/config/feed.{type FeedMetadata, FeedMetadata}
import blogatto/config/feed/rss.{RssFeedItem}
import blogatto/post.{Post}
import gleam/dict
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

fn sample_feed_item() -> rss.RssFeedItem {
  RssFeedItem(
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

fn sample_feed_config() -> rss.RssFeedConfig(msg) {
  rss.new("My Blog", "https://example.com", "A sample blog")
}

fn sample_post() -> post.Post(msg) {
  Post(
    title: "Hello",
    slug: "hello",
    url: "https://example.com/hello",
    date: timestamp.from_unix_seconds(1_700_000_000),
    description: "A post",
    excerpt: "A post",
    language: None,
    featured_image: None,
    contents: [],
    extras: dict.new(),
  )
}

pub fn feed_config_construction_with_defaults_test() {
  let cfg = sample_feed_config()

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
  let f = fn(meta: FeedMetadata(msg)) { meta.path != "/draft" }
  let cfg =
    rss.new("Filtered", "https://example.com", "A sample blog")
    |> rss.filter(f)
    |> rss.output("/feed.xml")

  cfg.filter |> should.be_some
}

pub fn feed_config_filter_invocation_test() {
  let f = fn(meta: FeedMetadata(msg)) { meta.path != "/draft" }
  let cfg =
    rss.new("Filtered", "https://example.com", "A sample blog")
    |> rss.filter(f)
    |> rss.output("/feed.xml")

  let assert Some(f) = cfg.filter
  let published =
    FeedMetadata(
      path: "/blog/post",
      post: sample_post(),
      url: "https://example.com/blog/post",
    )
  let draft =
    FeedMetadata(
      path: "/draft",
      post: sample_post(),
      url: "https://example.com/draft",
    )

  f(published) |> should.be_true
  f(draft) |> should.be_false
}

pub fn feed_config_with_serialize_test() {
  let s = fn(meta: FeedMetadata(msg)) {
    RssFeedItem(
      title: meta.post.title,
      description: meta.post.excerpt,
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
    rss.new("With Serializer", "https://example.com", "A sample blog")
    |> rss.serialize(s)

  cfg.serialize |> should.be_some
}

pub fn feed_config_serialize_invocation_test() {
  let s = fn(meta: FeedMetadata(msg)) {
    RssFeedItem(
      title: meta.post.title,
      description: meta.post.excerpt,
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
    rss.new("With Serializer", "https://example.com", "A sample blog")
    |> rss.serialize(s)

  let assert Some(s) = cfg.serialize
  let meta =
    FeedMetadata(
      path: "/blog/hello",
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
      excerpt: "An excerpt",
      language: Some("en"),
      featured_image: Some("./featured.jpeg"),
      contents: [],
      extras: dict.from_list([#("lang", "en")]),
    )
  let meta =
    FeedMetadata(
      path: "/blog/hello",
      post: p,
      url: "https://example.com/blog/hello",
    )

  meta.path |> should.equal("/blog/hello")
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
    rss.Image(
      url: "https://example.com/logo.png",
      title: "Logo",
      link: "https://example.com",
      description: Some("Site logo"),
      width: Some(88),
      height: Some(31),
    )
  let cfg =
    sample_feed_config()
    |> rss.language("en-us")
    |> rss.copyright("2026 Example")
    |> rss.managing_editor("editor@example.com")
    |> rss.category("blog")
    |> rss.category("tech")
    |> rss.ttl(60)
    |> rss.image(img)
    |> rss.skip_hour(2)
    |> rss.skip_hour(1)
    |> rss.skip_hour(0)
    |> rss.skip_day(rss.Sunday)
    |> rss.skip_day(rss.Saturday)

  cfg.language |> should.equal(Some("en-us"))
  cfg.copyright |> should.equal(Some("2026 Example"))
  cfg.managing_editor |> should.equal(Some("editor@example.com"))
  cfg.categories |> should.equal(["tech", "blog"])
  cfg.ttl |> should.equal(Some(60))
  cfg.image |> should.be_some
  cfg.skip_hours |> should.equal([0, 1, 2])
  cfg.skip_days |> should.equal([rss.Saturday, rss.Sunday])
}

pub fn feed_item_with_enclosure_test() {
  let enc =
    rss.Enclosure(
      url: "https://example.com/audio.mp3",
      length: 12_345_678,
      enclosure_type: "audio/mpeg",
    )
  let item =
    RssFeedItem(..sample_feed_item(), enclosure: Some(enc), categories: ["tech"])

  item.enclosure |> should.be_some
  item.categories |> should.equal(["tech"])
}

pub fn feed_new_sets_required_fields_test() {
  let cfg = rss.new("Title", "https://example.com", "Desc")

  cfg.title |> should.equal("Title")
  cfg.link |> should.equal("https://example.com")
  cfg.description |> should.equal("Desc")
}

pub fn feed_new_sets_defaults_test() {
  let cfg = rss.new("T", "L", "D")

  cfg.filter |> should.equal(None)
  cfg.output |> should.equal("/rss.xml")
  cfg.serialize |> should.equal(None)
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

pub fn feed_builder_setters_test() {
  let ts = timestamp.from_unix_seconds(1_700_000_000)
  let cl =
    rss.Cloud(
      domain: "rpc.example.com",
      port: 80,
      path: "/rpc",
      register_procedure: "notify",
      protocol: "http-post",
    )
  let img =
    rss.Image(
      url: "https://example.com/logo.png",
      title: "Logo",
      link: "https://example.com",
      description: None,
      width: None,
      height: None,
    )
  let ti =
    rss.TextInput(
      title: "Search",
      description: "Search the feed",
      name: "q",
      link: "https://example.com/search",
    )

  let cfg =
    rss.new("Blog", "https://example.com", "A blog")
    |> rss.output("/atom.xml")
    |> rss.language("it")
    |> rss.copyright("2026")
    |> rss.managing_editor("ed@example.com")
    |> rss.web_master("wm@example.com")
    |> rss.pub_date(ts)
    |> rss.last_build_date(ts)
    |> rss.category("gleam")
    |> rss.category("blog")
    |> rss.generator("Blogatto")
    |> rss.docs("https://www.rssboard.org/rss-specification")
    |> rss.cloud(cl)
    |> rss.ttl(120)
    |> rss.image(img)
    |> rss.text_input(ti)
    |> rss.skip_hour(3)
    |> rss.skip_hour(4)
    |> rss.skip_day(rss.Monday)

  cfg.output |> should.equal("/atom.xml")
  cfg.language |> should.equal(Some("it"))
  cfg.copyright |> should.equal(Some("2026"))
  cfg.managing_editor |> should.equal(Some("ed@example.com"))
  cfg.web_master |> should.equal(Some("wm@example.com"))
  cfg.pub_date |> should.equal(Some(ts))
  cfg.last_build_date |> should.equal(Some(ts))
  cfg.categories |> should.equal(["blog", "gleam"])
  cfg.generator |> should.equal(Some("Blogatto"))
  cfg.docs |> should.equal(Some("https://www.rssboard.org/rss-specification"))
  cfg.cloud |> should.equal(Some(cl))
  cfg.ttl |> should.equal(Some(120))
  cfg.image |> should.equal(Some(img))
  cfg.text_input |> should.equal(Some(ti))
  cfg.skip_hours |> should.equal([4, 3])
  cfg.skip_days |> should.equal([rss.Monday])
}
