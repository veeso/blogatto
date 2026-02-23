import blogatto/config/feed.{
  type FeedConfig, type FeedItem, type FeedMetadata, Cloud, Enclosure,
  FeedConfig, FeedItem, FeedMetadata, Image, TextInput,
}
import blogatto/internal/builder/feed as feed_builder
import blogatto/post.{type Post, Post}
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleam/time/timestamp
import gleeunit/should
import simplifile

const test_dir = "./test_output_feed"

fn with_test_dir(f: fn(String) -> Nil) -> Nil {
  let assert Ok(_) = simplifile.create_directory_all(test_dir)
  f(test_dir)
  let assert Ok(_) = simplifile.delete(test_dir)
  Nil
}

fn sample_post() -> Post(msg) {
  Post(
    title: "Hello World",
    slug: "hello-world",
    url: "https://example.com/blog/hello-world",
    date: timestamp.from_unix_seconds(1_700_000_000),
    description: "A first post",
    language: None,
    featured_image: None,
    contents: [],
    extras: dict.new(),
  )
}

fn sample_metadata() -> FeedMetadata(msg) {
  FeedMetadata(
    path: "/blog/hello-world",
    excerpt: "This is the excerpt of the post",
    post: sample_post(),
    url: "https://example.com/blog/hello-world",
  )
}

fn minimal_config(output: String) -> FeedConfig(msg) {
  FeedConfig(
    excerpt_len: 200,
    filter: None,
    output: output,
    serialize: None,
    title: "My Blog",
    link: "https://example.com",
    description: "A test blog",
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

// --- File I/O tests ---

pub fn build_writes_rss_xml_file_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  simplifile.is_file(dir <> "/rss.xml")
  |> should.be_ok
  |> should.be_true
}

pub fn build_creates_subdirectories_for_nested_output_path_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/feeds/rss.xml")

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  simplifile.is_file(dir <> "/feeds/rss.xml")
  |> should.be_ok
  |> should.be_true
}

pub fn build_with_multiple_configs_writes_multiple_files_test() {
  use dir <- with_test_dir
  let cfg1 = minimal_config("/rss.xml")
  let cfg2 = minimal_config("/feed.xml")

  feed_builder.build(dir, [cfg1, cfg2], [sample_metadata()])
  |> should.be_ok

  simplifile.is_file(dir <> "/rss.xml")
  |> should.be_ok
  |> should.be_true
  simplifile.is_file(dir <> "/feed.xml")
  |> should.be_ok
  |> should.be_true
}

pub fn build_with_empty_config_list_succeeds_test() {
  use dir <- with_test_dir

  feed_builder.build(dir, [], [sample_metadata()])
  |> should.be_ok
}

// --- XML structure tests ---

pub fn build_generates_valid_rss_xml_structure_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
  |> should.be_true
  content
  |> string.contains("<rss version=\"2.0.1\">")
  |> should.be_true
  content
  |> string.contains("<channel>")
  |> should.be_true
  content
  |> string.contains("</channel>")
  |> should.be_true
  content
  |> string.contains("</rss>")
  |> should.be_true
}

pub fn build_includes_channel_title_link_description_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<title>My Blog</title>")
  |> should.be_true
  content
  |> string.contains("<link>https://example.com</link>")
  |> should.be_true
  content
  |> string.contains("<description>A test blog</description>")
  |> should.be_true
}

// --- Default behavior tests ---

pub fn build_with_defaults_includes_all_posts_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")
  let post1 = sample_metadata()
  let post2 =
    FeedMetadata(
      ..post1,
      path: "/blog/second-post",
      url: "https://example.com/blog/second-post",
      post: Post(..sample_post(), title: "Second Post", slug: "second-post"),
    )

  feed_builder.build(dir, [cfg], [post1, post2])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<title>Hello World</title>")
  |> should.be_true
  content
  |> string.contains("<title>Second Post</title>")
  |> should.be_true
}

pub fn build_with_default_serialize_populates_item_fields_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  // Title from post
  content
  |> string.contains("<item>")
  |> should.be_true
  content
  |> string.contains("<title>Hello World</title>")
  |> should.be_true
  // Description from excerpt
  content
  |> string.contains(
    "<description>This is the excerpt of the post</description>",
  )
  |> should.be_true
  // Link from url
  content
  |> string.contains("<link>https://example.com/blog/hello-world</link>")
  |> should.be_true
  // pubDate is present
  content
  |> string.contains("<pubDate>")
  |> should.be_true
}

pub fn build_with_empty_metadata_produces_no_items_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<item>")
  |> should.be_false
}

// --- Custom filter tests ---

pub fn build_applies_custom_filter_test() {
  use dir <- with_test_dir
  let filter = fn(meta: FeedMetadata(msg)) -> Bool {
    meta.post.slug != "excluded"
  }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), filter: Some(filter))
  let included = sample_metadata()
  let excluded =
    FeedMetadata(
      ..sample_metadata(),
      path: "/blog/excluded",
      url: "https://example.com/blog/excluded",
      post: Post(..sample_post(), title: "Excluded Post", slug: "excluded"),
    )

  feed_builder.build(dir, [cfg], [included, excluded])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<title>Hello World</title>")
  |> should.be_true
  content
  |> string.contains("<title>Excluded Post</title>")
  |> should.be_false
}

pub fn build_filter_excludes_all_posts_test() {
  use dir <- with_test_dir
  let filter = fn(_meta: FeedMetadata(msg)) -> Bool { False }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), filter: Some(filter))

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<item>")
  |> should.be_false
}

// --- Custom serialize tests ---

pub fn build_applies_custom_serialize_test() {
  use dir <- with_test_dir
  let serialize = fn(meta: FeedMetadata(msg)) -> FeedItem {
    FeedItem(
      title: "Custom: " <> meta.post.title,
      description: "Custom description",
      link: Some(meta.url),
      author: Some("author@example.com"),
      comments: None,
      source: None,
      pub_date: None,
      categories: [],
      enclosure: None,
      guid: None,
    )
  }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), serialize: Some(serialize))

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<title>Custom: Hello World</title>")
  |> should.be_true
  content
  |> string.contains("<description>Custom description</description>")
  |> should.be_true
  content
  |> string.contains("<author>author@example.com</author>")
  |> should.be_true
}

pub fn build_with_filter_and_serialize_combined_test() {
  use dir <- with_test_dir
  let filter = fn(meta: FeedMetadata(msg)) -> Bool { meta.post.slug != "draft" }
  let serialize = fn(meta: FeedMetadata(msg)) -> FeedItem {
    FeedItem(
      title: "[RSS] " <> meta.post.title,
      description: meta.excerpt,
      link: Some(meta.url),
      author: None,
      comments: None,
      source: None,
      pub_date: Some(meta.post.date),
      categories: ["blog"],
      enclosure: None,
      guid: None,
    )
  }
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      filter: Some(filter),
      serialize: Some(serialize),
    )
  let published = sample_metadata()
  let draft =
    FeedMetadata(
      ..sample_metadata(),
      path: "/blog/draft",
      url: "https://example.com/blog/draft",
      post: Post(..sample_post(), title: "Draft Post", slug: "draft"),
    )

  feed_builder.build(dir, [cfg], [published, draft])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<title>[RSS] Hello World</title>")
  |> should.be_true
  content
  |> string.contains("<category>blog</category>")
  |> should.be_true
  content
  |> string.contains("Draft Post")
  |> should.be_false
}

// --- Channel field tests ---

pub fn build_includes_language_in_channel_test() {
  use dir <- with_test_dir
  let cfg = FeedConfig(..minimal_config("/rss.xml"), language: Some("en-us"))

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<language>en-us</language>")
  |> should.be_true
}

pub fn build_includes_copyright_in_channel_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      copyright: Some("Copyright 2024 Example"),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<copyright>Copyright 2024 Example</copyright>")
  |> should.be_true
}

pub fn build_includes_managing_editor_and_web_master_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      managing_editor: Some("editor@example.com"),
      web_master: Some("webmaster@example.com"),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<managingEditor>editor@example.com</managingEditor>")
  |> should.be_true
  content
  |> string.contains("<webMaster>webmaster@example.com</webMaster>")
  |> should.be_true
}

pub fn build_includes_pub_date_and_last_build_date_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      pub_date: Some(timestamp.from_unix_seconds(1_700_000_000)),
      last_build_date: Some(timestamp.from_unix_seconds(1_700_100_000)),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<pubDate>")
  |> should.be_true
  content
  |> string.contains("<lastBuildDate>")
  |> should.be_true
}

pub fn build_includes_channel_categories_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(..minimal_config("/rss.xml"), categories: ["tech", "programming"])

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<category>tech</category>")
  |> should.be_true
  content
  |> string.contains("<category>programming</category>")
  |> should.be_true
}

pub fn build_includes_generator_and_docs_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      generator: Some("blogatto"),
      docs: Some("https://www.rssboard.org/rss-2-0-1"),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<generator>blogatto</generator>")
  |> should.be_true
  content
  |> string.contains("<docs>https://www.rssboard.org/rss-2-0-1</docs>")
  |> should.be_true
}

pub fn build_includes_cloud_in_channel_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      cloud: Some(Cloud(
        domain: "rpc.example.com",
        port: 80,
        path: "/RPC2",
        register_procedure: "myCloud.rssPleaseNotify",
        protocol: "xml-rpc",
      )),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("domain=\"rpc.example.com\"")
  |> should.be_true
  content
  |> string.contains("port=\"80\"")
  |> should.be_true
  content
  |> string.contains("path=\"/RPC2\"")
  |> should.be_true
  content
  |> string.contains("registerProcedure=\"myCloud.rssPleaseNotify\"")
  |> should.be_true
  content
  |> string.contains("protocol=\"xml-rpc\"")
  |> should.be_true
}

pub fn build_includes_ttl_in_channel_test() {
  use dir <- with_test_dir
  let cfg = FeedConfig(..minimal_config("/rss.xml"), ttl: Some(60))

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<ttl>60</ttl>")
  |> should.be_true
}

pub fn build_includes_image_in_channel_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      image: Some(Image(
        url: "https://example.com/logo.png",
        title: "Site Logo",
        link: "https://example.com",
        description: Some("The site logo"),
        width: Some(88),
        height: Some(31),
      )),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<image>")
  |> should.be_true
  content
  |> string.contains("<url>https://example.com/logo.png</url>")
  |> should.be_true
  content
  |> string.contains("<title>Site Logo</title>")
  |> should.be_true
  content
  |> string.contains("<description>The site logo</description>")
  |> should.be_true
  content
  |> string.contains("<width>88</width>")
  |> should.be_true
  content
  |> string.contains("<height>31</height>")
  |> should.be_true
  content
  |> string.contains("</image>")
  |> should.be_true
}

pub fn build_includes_image_without_optional_fields_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      image: Some(Image(
        url: "https://example.com/logo.png",
        title: "Site Logo",
        link: "https://example.com",
        description: None,
        width: None,
        height: None,
      )),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<image>")
  |> should.be_true
  content
  |> string.contains("<url>https://example.com/logo.png</url>")
  |> should.be_true
  // Optional fields should be absent
  content
  |> string.contains("<width>")
  |> should.be_false
  content
  |> string.contains("<height>")
  |> should.be_false
}

pub fn build_includes_text_input_in_channel_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      ..minimal_config("/rss.xml"),
      text_input: Some(TextInput(
        title: "Search",
        description: "Search the blog",
        name: "q",
        link: "https://example.com/search",
      )),
    )

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<textInput>")
  |> should.be_true
  content
  |> string.contains("<title>Search</title>")
  |> should.be_true
  content
  |> string.contains("<description>Search the blog</description>")
  |> should.be_true
  content
  |> string.contains("<name>q</name>")
  |> should.be_true
  content
  |> string.contains("<link>https://example.com/search</link>")
  |> should.be_true
  content
  |> string.contains("</textInput>")
  |> should.be_true
}

pub fn build_includes_skip_hours_in_channel_test() {
  use dir <- with_test_dir
  let cfg = FeedConfig(..minimal_config("/rss.xml"), skip_hours: [0, 1, 2, 23])

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<skipHours>")
  |> should.be_true
  content
  |> string.contains("<hour>0</hour>")
  |> should.be_true
  content
  |> string.contains("<hour>23</hour>")
  |> should.be_true
  content
  |> string.contains("</skipHours>")
  |> should.be_true
}

pub fn build_includes_skip_days_in_channel_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(..minimal_config("/rss.xml"), skip_days: [
      feed.Saturday,
      feed.Sunday,
    ])

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<skipDays>")
  |> should.be_true
  content
  |> string.contains("<day>Saturday</day>")
  |> should.be_true
  content
  |> string.contains("<day>Sunday</day>")
  |> should.be_true
  content
  |> string.contains("</skipDays>")
  |> should.be_true
}

pub fn build_converts_all_weekday_variants_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(..minimal_config("/rss.xml"), skip_days: [
      feed.Monday,
      feed.Tuesday,
      feed.Wednesday,
      feed.Thursday,
      feed.Friday,
      feed.Saturday,
      feed.Sunday,
    ])

  feed_builder.build(dir, [cfg], [])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content |> string.contains("<day>Monday</day>") |> should.be_true
  content |> string.contains("<day>Tuesday</day>") |> should.be_true
  content |> string.contains("<day>Wednesday</day>") |> should.be_true
  content |> string.contains("<day>Thursday</day>") |> should.be_true
  content |> string.contains("<day>Friday</day>") |> should.be_true
  content |> string.contains("<day>Saturday</day>") |> should.be_true
  content |> string.contains("<day>Sunday</day>") |> should.be_true
}

// --- Item field tests ---

pub fn build_with_item_having_author_test() {
  use dir <- with_test_dir
  let serialize = fn(meta: FeedMetadata(msg)) -> FeedItem {
    FeedItem(
      title: meta.post.title,
      description: meta.excerpt,
      link: None,
      author: Some("john@example.com"),
      comments: None,
      source: None,
      pub_date: None,
      categories: [],
      enclosure: None,
      guid: None,
    )
  }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), serialize: Some(serialize))

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<author>john@example.com</author>")
  |> should.be_true
}

pub fn build_with_item_having_comments_and_source_test() {
  use dir <- with_test_dir
  let serialize = fn(meta: FeedMetadata(msg)) -> FeedItem {
    FeedItem(
      title: meta.post.title,
      description: meta.excerpt,
      link: None,
      author: None,
      comments: Some("https://example.com/blog/hello-world#comments"),
      source: Some("https://original.example.com/feed"),
      pub_date: None,
      categories: [],
      enclosure: None,
      guid: None,
    )
  }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), serialize: Some(serialize))

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains(
    "<comments>https://example.com/blog/hello-world#comments</comments>",
  )
  |> should.be_true
  content
  |> string.contains("<source>https://original.example.com/feed</source>")
  |> should.be_true
}

pub fn build_with_item_having_enclosure_test() {
  use dir <- with_test_dir
  let serialize = fn(meta: FeedMetadata(msg)) -> FeedItem {
    FeedItem(
      title: meta.post.title,
      description: meta.excerpt,
      link: None,
      author: None,
      comments: None,
      source: None,
      pub_date: None,
      categories: [],
      enclosure: Some(Enclosure(
        url: "https://example.com/audio/episode1.mp3",
        length: 12_345_678,
        enclosure_type: "audio/mpeg",
      )),
      guid: None,
    )
  }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), serialize: Some(serialize))

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("url=\"https://example.com/audio/episode1.mp3\"")
  |> should.be_true
  content
  |> string.contains("length=\"12345678\"")
  |> should.be_true
  content
  |> string.contains("type=\"audio/mpeg\"")
  |> should.be_true
}

pub fn build_with_item_having_categories_test() {
  use dir <- with_test_dir
  let serialize = fn(meta: FeedMetadata(msg)) -> FeedItem {
    FeedItem(
      title: meta.post.title,
      description: meta.excerpt,
      link: None,
      author: None,
      comments: None,
      source: None,
      pub_date: None,
      categories: ["gleam", "web", "tutorial"],
      enclosure: None,
      guid: None,
    )
  }
  let cfg = FeedConfig(..minimal_config("/rss.xml"), serialize: Some(serialize))

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<category>gleam</category>")
  |> should.be_true
  content
  |> string.contains("<category>web</category>")
  |> should.be_true
  content
  |> string.contains("<category>tutorial</category>")
  |> should.be_true
}

// --- Channel with all optional fields test ---

pub fn build_with_all_channel_fields_test() {
  use dir <- with_test_dir
  let cfg =
    FeedConfig(
      excerpt_len: 200,
      filter: None,
      output: "/rss.xml",
      serialize: None,
      title: "Full Channel",
      link: "https://example.com",
      description: "A fully configured channel",
      language: Some("en-us"),
      copyright: Some("Copyright 2024"),
      managing_editor: Some("editor@example.com"),
      web_master: Some("webmaster@example.com"),
      pub_date: Some(timestamp.from_unix_seconds(1_700_000_000)),
      last_build_date: Some(timestamp.from_unix_seconds(1_700_100_000)),
      categories: ["tech"],
      generator: Some("blogatto"),
      docs: Some("https://www.rssboard.org/rss-2-0-1"),
      cloud: Some(Cloud(
        domain: "rpc.example.com",
        port: 80,
        path: "/RPC2",
        register_procedure: "notify",
        protocol: "xml-rpc",
      )),
      ttl: Some(60),
      image: Some(Image(
        url: "https://example.com/logo.png",
        title: "Logo",
        link: "https://example.com",
        description: None,
        width: None,
        height: None,
      )),
      text_input: Some(TextInput(
        title: "Search",
        description: "Search posts",
        name: "q",
        link: "https://example.com/search",
      )),
      skip_hours: [0, 6, 12],
      skip_days: [feed.Saturday, feed.Sunday],
    )

  feed_builder.build(dir, [cfg], [sample_metadata()])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  // Verify key channel fields are present
  content
  |> string.contains("<title>Full Channel</title>")
  |> should.be_true
  content
  |> string.contains("<language>en-us</language>")
  |> should.be_true
  content
  |> string.contains("<copyright>Copyright 2024</copyright>")
  |> should.be_true
  content
  |> string.contains("<generator>blogatto</generator>")
  |> should.be_true
  content
  |> string.contains("<ttl>60</ttl>")
  |> should.be_true
  content
  |> string.contains("<image>")
  |> should.be_true
  content
  |> string.contains("<textInput>")
  |> should.be_true
  content
  |> string.contains("<skipHours>")
  |> should.be_true
  content
  |> string.contains("<skipDays>")
  |> should.be_true
  // And the item is present
  content
  |> string.contains("<item>")
  |> should.be_true
}

// --- Multiple posts ordering test ---

pub fn build_includes_multiple_posts_as_separate_items_test() {
  use dir <- with_test_dir
  let cfg = minimal_config("/rss.xml")
  let meta1 = sample_metadata()
  let meta2 =
    FeedMetadata(
      path: "/blog/second",
      excerpt: "Second excerpt",
      post: Post(
        ..sample_post(),
        title: "Second",
        slug: "second",
        date: timestamp.from_unix_seconds(1_700_100_000),
      ),
      url: "https://example.com/blog/second",
    )
  let meta3 =
    FeedMetadata(
      path: "/blog/third",
      excerpt: "Third excerpt",
      post: Post(
        ..sample_post(),
        title: "Third",
        slug: "third",
        date: timestamp.from_unix_seconds(1_700_200_000),
      ),
      url: "https://example.com/blog/third",
    )

  feed_builder.build(dir, [cfg], [meta1, meta2, meta3])
  |> should.be_ok

  let assert Ok(content) = simplifile.read(dir <> "/rss.xml")
  content
  |> string.contains("<title>Hello World</title>")
  |> should.be_true
  content
  |> string.contains("<title>Second</title>")
  |> should.be_true
  content
  |> string.contains("<title>Third</title>")
  |> should.be_true
}
