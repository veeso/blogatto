import blogatto/config/sitemap.{SitemapEntry}
import blogatto/error
import blogatto/internal/builder/sitemap as sitemap_builder
import gleam/option.{None, Some}
import gleam/string
import gleam/time/timestamp
import gleeunit/should
import simplifile
import temporary

pub fn build_writes_sitemap_xml_file_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = sitemap.new("/sitemap.xml")
    let build =
      sitemap_builder.SitemapBuild(config: cfg, routes: ["/", "/about"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    simplifile.is_file(dir <> "/sitemap.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_generates_valid_xml_structure_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = sitemap.new("/sitemap.xml")
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content
    |> string.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    |> should.be_true
    content
    |> string.contains(
      "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">",
    )
    |> should.be_true
    content
    |> string.contains("</urlset>")
    |> should.be_true
  }
}

pub fn build_includes_all_routes_as_url_entries_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = sitemap.new("/sitemap.xml")
    let build =
      sitemap_builder.SitemapBuild(config: cfg, routes: [
        "/", "/about", "/blog/hello",
      ])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content |> string.contains("<loc>/</loc>") |> should.be_true
    content |> string.contains("<loc>/about</loc>") |> should.be_true
    content |> string.contains("<loc>/blog/hello</loc>") |> should.be_true
  }
}

pub fn build_handles_empty_routes_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = sitemap.new("/sitemap.xml")
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: [])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content
    |> string.contains("<urlset")
    |> should.be_true
    // no <url> entries
    content
    |> string.contains("<url>")
    |> should.be_false
  }
}

pub fn build_applies_custom_filter_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      sitemap.new("/sitemap.xml")
      |> sitemap.filter(fn(route) { route != "/admin" })
    let build =
      sitemap_builder.SitemapBuild(config: cfg, routes: [
        "/about", "/admin", "/blog",
      ])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content |> string.contains("<loc>/about</loc>") |> should.be_true
    content |> string.contains("<loc>/blog</loc>") |> should.be_true
    content |> string.contains("<loc>/admin</loc>") |> should.be_false
  }
}

pub fn build_filter_excludes_all_routes_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      sitemap.new("/sitemap.xml")
      |> sitemap.filter(fn(_route) { False })
    let build =
      sitemap_builder.SitemapBuild(config: cfg, routes: ["/about", "/blog"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content |> string.contains("<url>") |> should.be_false
  }
}

pub fn build_applies_custom_serialize_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      sitemap.new("/sitemap.xml")
      |> sitemap.serialize(fn(route) {
        SitemapEntry(
          url: "https://example.com" <> route,
          priority: Some(0.8),
          last_modified: None,
          change_frequency: Some(sitemap.Weekly),
        )
      })
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/about"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content
    |> string.contains("<loc>https://example.com/about</loc>")
    |> should.be_true
    content
    |> string.contains("<priority>0.8</priority>")
    |> should.be_true
    content
    |> string.contains("<changefreq>weekly</changefreq>")
    |> should.be_true
  }
}

pub fn build_with_priority_in_output_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      sitemap.new("/sitemap.xml")
      |> sitemap.serialize(fn(route) {
        SitemapEntry(
          url: route,
          priority: Some(1.0),
          last_modified: None,
          change_frequency: None,
        )
      })
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content
    |> string.contains("<priority>1.0</priority>")
    |> should.be_true
  }
}

pub fn build_with_last_modified_in_output_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      sitemap.new("/sitemap.xml")
      |> sitemap.serialize(fn(route) {
        SitemapEntry(
          url: route,
          priority: None,
          last_modified: Some(timestamp.from_unix_seconds(1_700_000_000)),
          change_frequency: None,
        )
      })
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content
    |> string.contains("<lastmod>")
    |> should.be_true
  }
}

pub fn build_with_all_change_frequency_variants_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let frequencies = [
      #(sitemap.Always, "always"),
      #(sitemap.Hourly, "hourly"),
      #(sitemap.Daily, "daily"),
      #(sitemap.Weekly, "weekly"),
      #(sitemap.Monthly, "monthly"),
      #(sitemap.Yearly, "yearly"),
      #(sitemap.Never, "never"),
    ]

    check_frequency(dir, frequencies)
  }
}

fn check_frequency(
  dir: String,
  frequencies: List(#(sitemap.ChangeFrequency, String)),
) -> Nil {
  case frequencies {
    [] -> Nil
    [#(freq, expected_str), ..rest] -> {
      let cfg =
        sitemap.new("/sitemap.xml")
        |> sitemap.serialize(fn(_route) {
          SitemapEntry(
            url: "/",
            priority: None,
            last_modified: None,
            change_frequency: Some(freq),
          )
        })
      let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/"])

      sitemap_builder.build(dir, "https://example.com", build)
      |> should.be_ok

      let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
      content
      |> string.contains("<changefreq>" <> expected_str <> "</changefreq>")
      |> should.be_true

      check_frequency(dir, rest)
    }
  }
}

pub fn build_creates_subdirectories_for_nested_path_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = sitemap.new("/sitemaps/sitemap.xml")
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/"])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    simplifile.is_file(dir <> "/sitemaps/sitemap.xml")
    |> should.be_ok
    |> should.be_true
  }
}

pub fn build_with_filter_and_serialize_combined_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg =
      sitemap.new("/sitemap.xml")
      |> sitemap.filter(fn(route) { route != "/private" })
      |> sitemap.serialize(fn(route) {
        SitemapEntry(
          url: "https://example.com" <> route,
          priority: Some(0.5),
          last_modified: None,
          change_frequency: Some(sitemap.Monthly),
        )
      })
    let build =
      sitemap_builder.SitemapBuild(config: cfg, routes: [
        "/about", "/private", "/blog",
      ])

    sitemap_builder.build(dir, "https://example.com", build)
    |> should.be_ok

    let assert Ok(content) = simplifile.read(dir <> "/sitemap.xml")
    content
    |> string.contains("<loc>https://example.com/about</loc>")
    |> should.be_true
    content
    |> string.contains("<loc>https://example.com/blog</loc>")
    |> should.be_true
    content
    |> string.contains("private")
    |> should.be_false
  }
}

pub fn build_returns_error_for_invalid_site_url_test() {
  let assert Ok(_) = {
    use dir <- temporary.create(temporary.directory())
    let cfg = sitemap.new("/sitemap.xml")
    let build = sitemap_builder.SitemapBuild(config: cfg, routes: ["/"])

    // uri.merge fails when the base URI has no scheme/host
    let result = sitemap_builder.build(dir, "", build)

    result |> should.be_error

    let assert Error(error.InvalidUri(_)) = result
    Nil
  }
}
