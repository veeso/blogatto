import blogatto/config/feed.{type FeedMetadata, FeedMetadata}
import blogatto/config/feed/atom.{
  type AtomFeed, type AtomFeedItem, AtomFeed, AtomFeedItem, Category, Generator,
  Link, Person, Source,
}
import blogatto/internal/builder/feed/atom as feed_builder
import blogatto/post.{type Post, Post}
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleam/time/timestamp
import gleeunit/should
import simplifile
import temporary

fn sample_post() -> Post(msg) {
  Post(
    title: "Hello World",
    slug: "hello-world",
    url: "https://example.com/blog/hello-world",
    date: timestamp.from_unix_seconds(1_700_000_000),
    description: "A first post",
    excerpt: "This is the excerpt of the post",
    language: None,
    featured_image: None,
    contents: [],
    extras: dict.new(),
  )
}

fn sample_metadata() -> FeedMetadata(msg) {
  FeedMetadata(
    path: "/blog/hello-world",
    post: sample_post(),
    url: "https://example.com/blog/hello-world",
  )
}

fn minimal_config(output: String) -> AtomFeed(msg) {
  AtomFeed(
    filter: None,
    output: output,
    serialize: None,
    id: "https://example.com/",
    title: atom.PlainText("My Blog"),
    updated: timestamp.from_unix_seconds(1_700_000_000),
    authors: [],
    link: None,
    categories: [],
    contributors: [],
    generator: None,
    icon: None,
    logo: None,
    rights: None,
    subtitle: None,
  )
}

// --- File I/O tests ---

pub fn build_writes_atom_xml_file_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    simplifile.is_file(dir <> "/atom.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_creates_subdirectories_for_nested_output_path_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/feeds/atom.xml")

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    simplifile.is_file(dir <> "/feeds/atom.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_with_multiple_configs_writes_multiple_files_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg1 = minimal_config("/atom.xml")
    let cfg2 = minimal_config("/feed.xml")

    feed_builder.build(dir, [cfg1, cfg2], [sample_metadata()])
    |> should.be_ok

    simplifile.is_file(dir <> "/atom.xml")
    |> should.be_ok
    |> should.be_true
    simplifile.is_file(dir <> "/feed.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_with_empty_config_list_succeeds_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())

    feed_builder.build(dir, [], [sample_metadata()])
    |> should.be_ok
  }
}

// --- XML structure tests ---

pub fn build_generates_valid_atom_xml_structure_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    |> should.be_true
    content
    |> string.contains("<feed xmlns=\"http://www.w3.org/2005/Atom\">")
    |> should.be_true
    content
    |> string.contains("</feed>")
    |> should.be_true
  }
}

pub fn build_includes_feed_id_title_updated_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<id>https://example.com/</id>")
    |> should.be_true
    content
    |> string.contains("<title>My Blog</title>")
    |> should.be_true
    content
    |> string.contains("<updated>")
    |> should.be_true
  }
}

// --- Default behavior tests ---

pub fn build_with_defaults_includes_all_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")
    let post1 = sample_metadata()
    let post2 =
      FeedMetadata(
        path: "/blog/second-post",
        url: "https://example.com/blog/second-post",
        post: Post(..sample_post(), title: "Second Post", slug: "second-post"),
      )

    feed_builder.build(dir, [cfg], [post1, post2])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<title>Hello World</title>")
    |> should.be_true
    content
    |> string.contains("<title>Second Post</title>")
    |> should.be_true
  }
}

pub fn build_with_default_serialize_populates_entry_fields_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<entry>")
    |> should.be_true
    // Id from url
    content
    |> string.contains("<id>https://example.com/blog/hello-world</id>")
    |> should.be_true
    // Title from post
    content
    |> string.contains("<title>Hello World</title>")
    |> should.be_true
    // Summary from excerpt
    content
    |> string.contains("<summary>This is the excerpt of the post</summary>")
    |> should.be_true
    // Link href from url
    content
    |> string.contains("href=\"https://example.com/blog/hello-world\"")
    |> should.be_true
    // Published is present
    content
    |> string.contains("<published>")
    |> should.be_true
  }
}

pub fn build_with_empty_metadata_produces_no_entries_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<entry>")
    |> should.be_false
  }
}

// --- Custom filter tests ---

pub fn build_applies_custom_filter_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let filter = fn(meta: FeedMetadata(msg)) -> Bool {
      meta.post.slug != "excluded"
    }
    let cfg = AtomFeed(..minimal_config("/atom.xml"), filter: Some(filter))
    let included = sample_metadata()
    let excluded =
      FeedMetadata(
        path: "/blog/excluded",
        url: "https://example.com/blog/excluded",
        post: Post(..sample_post(), title: "Excluded Post", slug: "excluded"),
      )

    feed_builder.build(dir, [cfg], [included, excluded])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<title>Hello World</title>")
    |> should.be_true
    content
    |> string.contains("Excluded Post")
    |> should.be_false
  }
}

pub fn build_filter_excludes_all_posts_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let filter = fn(_meta: FeedMetadata(msg)) -> Bool { False }
    let cfg = AtomFeed(..minimal_config("/atom.xml"), filter: Some(filter))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<entry>")
    |> should.be_false
  }
}

// --- Custom serialize tests ---

pub fn build_applies_custom_serialize_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText("Custom: " <> meta.post.title),
        updated: meta.post.date,
        authors: [Person(name: "Jane", email: None, uri: None)],
        content: Some(atom.PlainText("Custom content body")),
        link: None,
        summary: None,
        categories: [],
        contributors: [],
        published: None,
        rights: None,
        source: None,
      )
    }
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), serialize: Some(serialize))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<title>Custom: Hello World</title>")
    |> should.be_true
    content
    |> string.contains("<content>Custom content body</content>")
    |> should.be_true
    content
    |> string.contains("<name>Jane</name>")
    |> should.be_true
  }
}

pub fn build_with_filter_and_serialize_combined_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let filter = fn(meta: FeedMetadata(msg)) -> Bool {
      meta.post.slug != "draft"
    }
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText("[Atom] " <> meta.post.title),
        updated: meta.post.date,
        authors: [],
        content: None,
        link: None,
        summary: Some(atom.PlainText(meta.post.excerpt)),
        categories: [Category(term: "blog", scheme: None, label: None)],
        contributors: [],
        published: Some(meta.post.date),
        rights: None,
        source: None,
      )
    }
    let cfg =
      AtomFeed(
        ..minimal_config("/atom.xml"),
        filter: Some(filter),
        serialize: Some(serialize),
      )
    let published = sample_metadata()
    let draft =
      FeedMetadata(
        path: "/blog/draft",
        url: "https://example.com/blog/draft",
        post: Post(..sample_post(), title: "Draft Post", slug: "draft"),
      )

    feed_builder.build(dir, [cfg], [published, draft])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<title>[Atom] Hello World</title>")
    |> should.be_true
    content
    |> string.contains("term=\"blog\"")
    |> should.be_true
    content
    |> string.contains("Draft Post")
    |> should.be_false
  }
}

// --- Feed-level field tests ---

pub fn build_includes_feed_authors_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), authors: [
        Person(
          name: "Jane Doe",
          email: Some("jane@example.com"),
          uri: Some("https://example.com/jane"),
        ),
      ])

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<name>Jane Doe</name>")
    |> should.be_true
    content
    |> string.contains("<email>jane@example.com</email>")
    |> should.be_true
    content
    |> string.contains("<uri>https://example.com/jane</uri>")
    |> should.be_true
  }
}

pub fn build_includes_feed_link_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(
        ..minimal_config("/atom.xml"),
        link: Some(Link(
          href: "https://example.com/atom.xml",
          rel: Some("self"),
          content_type: Some("application/atom+xml"),
          hreflang: None,
          title: None,
          length: None,
        )),
      )

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("href=\"https://example.com/atom.xml\"")
    |> should.be_true
    content
    |> string.contains("rel=\"self\"")
    |> should.be_true
    content
    |> string.contains("type=\"application/atom+xml\"")
    |> should.be_true
  }
}

pub fn build_includes_feed_categories_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), categories: [
        Category(term: "tech", scheme: None, label: Some("Technology")),
        Category(term: "blog", scheme: None, label: None),
      ])

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("term=\"tech\"")
    |> should.be_true
    content
    |> string.contains("label=\"Technology\"")
    |> should.be_true
    content
    |> string.contains("term=\"blog\"")
    |> should.be_true
  }
}

pub fn build_includes_feed_contributors_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), contributors: [
        Person(name: "Alice", email: None, uri: None),
      ])

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<name>Alice</name>")
    |> should.be_true
  }
}

pub fn build_includes_feed_generator_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(
        ..minimal_config("/atom.xml"),
        generator: Some(Generator(
          uri: Some("https://github.com/veeso/blogatto"),
          version: Some("5.0.1"),
        )),
      )

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("uri=\"https://github.com/veeso/blogatto\"")
    |> should.be_true
    content
    |> string.contains("version=\"5.0.1\"")
    |> should.be_true
  }
}

pub fn build_includes_feed_icon_and_logo_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(
        ..minimal_config("/atom.xml"),
        icon: Some("https://example.com/icon.png"),
        logo: Some("https://example.com/logo.png"),
      )

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<icon>https://example.com/icon.png</icon>")
    |> should.be_true
    content
    |> string.contains("<logo>https://example.com/logo.png</logo>")
    |> should.be_true
  }
}

pub fn build_includes_feed_rights_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(
        ..minimal_config("/atom.xml"),
        rights: Some(atom.PlainText("Copyright 2026 Example")),
      )

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<rights>Copyright 2026 Example</rights>")
    |> should.be_true
  }
}

pub fn build_includes_feed_subtitle_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(
        ..minimal_config("/atom.xml"),
        subtitle: Some("My personal blog"),
      )

    feed_builder.build(dir, [cfg], [])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<subtitle>My personal blog</subtitle>")
    |> should.be_true
  }
}

// --- Entry field tests ---

pub fn build_with_entry_having_authors_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText(meta.post.title),
        updated: meta.post.date,
        authors: [
          Person(name: "John Doe", email: Some("john@example.com"), uri: None),
        ],
        content: None,
        link: None,
        summary: None,
        categories: [],
        contributors: [],
        published: None,
        rights: None,
        source: None,
      )
    }
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), serialize: Some(serialize))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<name>John Doe</name>")
    |> should.be_true
    content
    |> string.contains("<email>john@example.com</email>")
    |> should.be_true
  }
}

pub fn build_with_entry_having_content_html_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText(meta.post.title),
        updated: meta.post.date,
        authors: [],
        content: Some(atom.Html("<p>body</p>")),
        link: None,
        summary: None,
        categories: [],
        contributors: [],
        published: None,
        rights: None,
        source: None,
      )
    }
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), serialize: Some(serialize))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<content>")
    |> should.be_true
    content
    |> string.contains("<p>body</p>")
    |> should.be_true
  }
}

pub fn build_with_entry_having_categories_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText(meta.post.title),
        updated: meta.post.date,
        authors: [],
        content: None,
        link: None,
        summary: None,
        categories: [
          Category(term: "gleam", scheme: None, label: None),
          Category(term: "web", scheme: None, label: None),
        ],
        contributors: [],
        published: None,
        rights: None,
        source: None,
      )
    }
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), serialize: Some(serialize))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("term=\"gleam\"")
    |> should.be_true
    content
    |> string.contains("term=\"web\"")
    |> should.be_true
  }
}

pub fn build_with_entry_having_source_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText(meta.post.title),
        updated: meta.post.date,
        authors: [],
        content: None,
        link: None,
        summary: None,
        categories: [],
        contributors: [],
        published: None,
        rights: None,
        source: Some(Source(
          id: "https://other.example.com/",
          title: "Other Blog",
          updated: timestamp.from_unix_seconds(1_700_000_000),
        )),
      )
    }
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), serialize: Some(serialize))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<source>")
    |> should.be_true
    content
    |> string.contains("<id>https://other.example.com/</id>")
    |> should.be_true
    content
    |> string.contains("<title>Other Blog</title>")
    |> should.be_true
  }
}

pub fn build_with_entry_having_rights_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let serialize = fn(meta: FeedMetadata(msg)) -> AtomFeedItem {
      AtomFeedItem(
        id: meta.url,
        title: atom.PlainText(meta.post.title),
        updated: meta.post.date,
        authors: [],
        content: None,
        link: None,
        summary: None,
        categories: [],
        contributors: [],
        published: None,
        rights: Some(atom.PlainText("CC-BY-4.0")),
        source: None,
      )
    }
    let cfg =
      AtomFeed(..minimal_config("/atom.xml"), serialize: Some(serialize))

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<rights>CC-BY-4.0</rights>")
    |> should.be_true
  }
}

// --- Multiple posts ---

pub fn build_includes_multiple_posts_as_separate_entries_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = minimal_config("/atom.xml")
    let meta1 = sample_metadata()
    let meta2 =
      FeedMetadata(
        path: "/blog/second",
        post: Post(
          ..sample_post(),
          title: "Second",
          slug: "second",
          excerpt: "Second excerpt",
          date: timestamp.from_unix_seconds(1_700_100_000),
        ),
        url: "https://example.com/blog/second",
      )
    let meta3 =
      FeedMetadata(
        path: "/blog/third",
        post: Post(
          ..sample_post(),
          title: "Third",
          slug: "third",
          excerpt: "Third excerpt",
          date: timestamp.from_unix_seconds(1_700_200_000),
        ),
        url: "https://example.com/blog/third",
      )

    feed_builder.build(dir, [cfg], [meta1, meta2, meta3])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
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
}

// --- All feed fields ---

pub fn build_with_all_feed_fields_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      AtomFeed(
        filter: None,
        output: "/atom.xml",
        serialize: None,
        id: "https://example.com/",
        title: atom.PlainText("Full Feed"),
        updated: timestamp.from_unix_seconds(1_700_000_000),
        authors: [Person(name: "Jane", email: None, uri: None)],
        link: Some(Link(
          href: "https://example.com/atom.xml",
          rel: Some("self"),
          content_type: None,
          hreflang: None,
          title: None,
          length: None,
        )),
        categories: [Category(term: "tech", scheme: None, label: None)],
        contributors: [Person(name: "Bob", email: None, uri: None)],
        generator: Some(Generator(uri: None, version: Some("1.0"))),
        icon: Some("https://example.com/icon.png"),
        logo: Some("https://example.com/logo.png"),
        rights: Some(atom.PlainText("2026")),
        subtitle: Some("Tagline"),
      )

    feed_builder.build(dir, [cfg], [sample_metadata()])
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/atom.xml")
    content
    |> string.contains("<title>Full Feed</title>")
    |> should.be_true
    content
    |> string.contains("<name>Jane</name>")
    |> should.be_true
    content
    |> string.contains("<name>Bob</name>")
    |> should.be_true
    content
    |> string.contains("term=\"tech\"")
    |> should.be_true
    content
    |> string.contains("<icon>https://example.com/icon.png</icon>")
    |> should.be_true
    content
    |> string.contains("<logo>https://example.com/logo.png</logo>")
    |> should.be_true
    content
    |> string.contains("<rights>2026</rights>")
    |> should.be_true
    content
    |> string.contains("<subtitle>Tagline</subtitle>")
    |> should.be_true
    content
    |> string.contains("<entry>")
    |> should.be_true
  }
}
