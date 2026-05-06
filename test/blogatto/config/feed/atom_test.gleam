import blogatto/config/feed.{type FeedMetadata, FeedMetadata}
import blogatto/config/feed/atom.{AtomFeedItem}
import blogatto/post.{Post}
import gleam/dict
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

fn sample_feed_item() -> atom.AtomFeedItem {
  AtomFeedItem(
    id: "https://example.com/blog/post",
    title: atom.PlainText("A title"),
    updated: timestamp.from_unix_seconds(1_700_000_000),
    authors: [],
    content: None,
    link: Some(atom.Link(
      href: "https://example.com/blog/post",
      rel: Some("alternate"),
      content_type: None,
      hreflang: None,
      title: None,
      length: None,
    )),
    summary: Some(atom.PlainText("A summary")),
    categories: [],
    contributors: [],
    published: Some(timestamp.from_unix_seconds(1_700_000_000)),
    rights: None,
    source: None,
  )
}

fn sample_feed_config() -> atom.AtomFeed(msg) {
  atom.new(
    id: "https://example.com/",
    title: atom.PlainText("My Blog"),
    updated: timestamp.from_unix_seconds(1_700_000_000),
  )
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
  cfg.output |> should.equal("/atom.xml")
  cfg.serialize |> should.equal(None)
  cfg.id |> should.equal("https://example.com/")
  cfg.title |> should.equal(atom.PlainText("My Blog"))
  cfg.updated |> should.equal(timestamp.from_unix_seconds(1_700_000_000))
  cfg.authors |> should.equal([])
  cfg.link |> should.equal(None)
  cfg.categories |> should.equal([])
  cfg.contributors |> should.equal([])
  cfg.generator |> should.equal(None)
  cfg.icon |> should.equal(None)
  cfg.logo |> should.equal(None)
  cfg.rights |> should.equal(None)
  cfg.subtitle |> should.equal(None)
}

pub fn feed_config_with_filter_test() {
  let f = fn(meta: FeedMetadata(msg)) { meta.path != "/draft" }
  let cfg =
    sample_feed_config()
    |> atom.filter(f)
    |> atom.output("/feeds/atom.xml")

  cfg.filter |> should.be_some
  cfg.output |> should.equal("/feeds/atom.xml")
}

pub fn feed_config_filter_invocation_test() {
  let f = fn(meta: FeedMetadata(msg)) { meta.path != "/draft" }
  let cfg = sample_feed_config() |> atom.filter(f)

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
    AtomFeedItem(
      id: meta.url,
      title: atom.PlainText(meta.post.title),
      updated: meta.post.date,
      authors: [],
      content: None,
      link: None,
      summary: Some(atom.PlainText(meta.post.excerpt)),
      categories: [],
      contributors: [],
      published: Some(meta.post.date),
      rights: None,
      source: None,
    )
  }
  let cfg = sample_feed_config() |> atom.serialize(s)

  cfg.serialize |> should.be_some
}

pub fn feed_config_serialize_invocation_test() {
  let s = fn(meta: FeedMetadata(msg)) {
    AtomFeedItem(
      id: meta.url,
      title: atom.PlainText(meta.post.title),
      updated: meta.post.date,
      authors: [],
      content: None,
      link: Some(atom.Link(
        href: meta.url,
        rel: Some("alternate"),
        content_type: None,
        hreflang: None,
        title: None,
        length: None,
      )),
      summary: Some(atom.PlainText(meta.post.excerpt)),
      categories: [],
      contributors: [],
      published: Some(meta.post.date),
      rights: None,
      source: None,
    )
  }
  let cfg = sample_feed_config() |> atom.serialize(s)

  let assert Some(s) = cfg.serialize
  let meta =
    FeedMetadata(
      path: "/blog/hello",
      post: sample_post(),
      url: "https://example.com/blog/hello",
    )
  let entry = s(meta)

  entry.id |> should.equal("https://example.com/blog/hello")
  entry.title |> should.equal(atom.PlainText("Hello"))
  entry.summary |> should.equal(Some(atom.PlainText("A post")))
}

pub fn feed_item_construction_test() {
  let item = sample_feed_item()

  item.id |> should.equal("https://example.com/blog/post")
  item.title |> should.equal(atom.PlainText("A title"))
  item.summary |> should.equal(Some(atom.PlainText("A summary")))
  item.link |> should.be_some
  item.published |> should.be_some
  item.authors |> should.equal([])
  item.contributors |> should.equal([])
  item.categories |> should.equal([])
  item.content |> should.equal(None)
  item.rights |> should.equal(None)
  item.source |> should.equal(None)
}

pub fn feed_new_sets_required_fields_test() {
  let ts = timestamp.from_unix_seconds(1_700_000_000)
  let cfg =
    atom.new(id: "urn:example:feed", title: atom.PlainText("T"), updated: ts)

  cfg.id |> should.equal("urn:example:feed")
  cfg.title |> should.equal(atom.PlainText("T"))
  cfg.updated |> should.equal(ts)
}

pub fn feed_new_sets_defaults_test() {
  let ts = timestamp.from_unix_seconds(1_700_000_000)
  let cfg = atom.new(id: "id", title: atom.PlainText("T"), updated: ts)

  cfg.filter |> should.equal(None)
  cfg.output |> should.equal("/atom.xml")
  cfg.serialize |> should.equal(None)
  cfg.authors |> should.equal([])
  cfg.link |> should.equal(None)
  cfg.categories |> should.equal([])
  cfg.contributors |> should.equal([])
  cfg.generator |> should.equal(None)
  cfg.icon |> should.equal(None)
  cfg.logo |> should.equal(None)
  cfg.rights |> should.equal(None)
  cfg.subtitle |> should.equal(None)
}

pub fn feed_builder_setters_test() {
  let ts = timestamp.from_unix_seconds(1_700_000_000)
  let jane =
    atom.Person(
      name: "Jane Doe",
      email: Some("jane@example.com"),
      uri: Some("https://example.com/jane"),
    )
  let bob = atom.Person(name: "Bob", email: None, uri: None)
  let alice = atom.Person(name: "Alice", email: None, uri: None)
  let lnk =
    atom.Link(
      href: "https://example.com/",
      rel: Some("self"),
      content_type: Some("application/atom+xml"),
      hreflang: None,
      title: None,
      length: None,
    )
  let cat_blog = atom.Category(term: "blog", scheme: None, label: Some("Blog"))
  let cat_tech = atom.Category(term: "tech", scheme: None, label: None)
  let gen =
    atom.Generator(
      uri: Some("https://github.com/veeso/blogatto"),
      version: Some("5.0.1"),
    )

  let cfg =
    atom.new(
      id: "https://example.com/",
      title: atom.PlainText("My Blog"),
      updated: ts,
    )
    |> atom.output("/feeds/atom.xml")
    |> atom.author(jane)
    |> atom.author(bob)
    |> atom.link(lnk)
    |> atom.category(cat_blog)
    |> atom.category(cat_tech)
    |> atom.contributor(alice)
    |> atom.generator(gen)
    |> atom.icon("https://example.com/icon.png")
    |> atom.logo("https://example.com/logo.png")
    |> atom.rights(atom.PlainText("2026 Example"))
    |> atom.subtitle("My personal blog")

  cfg.output |> should.equal("/feeds/atom.xml")
  cfg.authors |> should.equal([bob, jane])
  cfg.link |> should.equal(Some(lnk))
  cfg.categories |> should.equal([cat_tech, cat_blog])
  cfg.contributors |> should.equal([alice])
  cfg.generator |> should.equal(Some(gen))
  cfg.icon |> should.equal(Some("https://example.com/icon.png"))
  cfg.logo |> should.equal(Some("https://example.com/logo.png"))
  cfg.rights |> should.equal(Some(atom.PlainText("2026 Example")))
  cfg.subtitle |> should.equal(Some("My personal blog"))
}

pub fn feed_text_variants_test() {
  let plain = atom.PlainText("hello")
  let html = atom.Html("<p>hello</p>")
  let xhtml = atom.XHtml("<div xmlns=\"http://www.w3.org/1999/xhtml\">hi</div>")

  plain.value |> should.equal("hello")
  html.value |> should.equal("<p>hello</p>")
  xhtml.value
  |> should.equal("<div xmlns=\"http://www.w3.org/1999/xhtml\">hi</div>")
}

pub fn feed_item_with_content_and_source_test() {
  let src =
    atom.Source(
      id: "https://other.example.com/",
      title: "Other Blog",
      updated: timestamp.from_unix_seconds(1_700_000_000),
    )
  let item =
    AtomFeedItem(
      ..sample_feed_item(),
      content: Some(atom.Html("<p>body</p>")),
      source: Some(src),
      categories: [atom.Category(term: "tech", scheme: None, label: None)],
    )

  item.content |> should.equal(Some(atom.Html("<p>body</p>")))
  item.source |> should.equal(Some(src))
  item.categories
  |> should.equal([atom.Category(term: "tech", scheme: None, label: None)])
}
