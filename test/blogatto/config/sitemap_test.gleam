import blogatto/config/sitemap.{
  Always, Daily, Hourly, Monthly, Never, SitemapEntry, Weekly, Yearly,
}
import gleam/option.{None, Some}
import gleam/time/timestamp
import gleeunit/should

pub fn sitemap_config_new_sets_defaults_test() {
  let cfg = sitemap.new("/sitemap.xml")

  cfg.filter |> should.equal(None)
  cfg.serialize |> should.equal(None)
  cfg.path |> should.equal("/sitemap.xml")
}

pub fn sitemap_config_with_filter_test() {
  let cfg =
    sitemap.new("/sitemap.xml")
    |> sitemap.filter(fn(route) { route != "/admin" })

  cfg.filter |> should.be_some
}

pub fn sitemap_config_filter_invocation_test() {
  let cfg =
    sitemap.new("/sitemap.xml")
    |> sitemap.filter(fn(route) { route != "/admin" })

  let assert Some(f) = cfg.filter
  f("/about") |> should.be_true
  f("/admin") |> should.be_false
}

pub fn sitemap_config_with_serialize_test() {
  let cfg =
    sitemap.new("/sitemap.xml")
    |> sitemap.serialize(fn(route) {
      SitemapEntry(
        url: "https://example.com" <> route,
        priority: Some(0.8),
        last_modified: None,
        change_frequency: Some(Weekly),
      )
    })

  cfg.serialize |> should.be_some
}

pub fn sitemap_config_serialize_invocation_test() {
  let cfg =
    sitemap.new("/sitemap.xml")
    |> sitemap.serialize(fn(route) {
      SitemapEntry(
        url: "https://example.com" <> route,
        priority: Some(0.8),
        last_modified: None,
        change_frequency: Some(Weekly),
      )
    })

  let assert Some(s) = cfg.serialize
  let entry = s("/about")

  entry.url |> should.equal("https://example.com/about")
  entry.priority |> should.equal(Some(0.8))
  entry.last_modified |> should.equal(None)
  entry.change_frequency |> should.equal(Some(Weekly))
}

pub fn sitemap_config_path_overrides_test() {
  let cfg =
    sitemap.new("/sitemap.xml")
    |> sitemap.path("/custom-sitemap.xml")

  cfg.path |> should.equal("/custom-sitemap.xml")
}

pub fn sitemap_entry_with_all_fields_test() {
  let entry =
    SitemapEntry(
      url: "https://example.com/about",
      priority: Some(1.0),
      last_modified: Some(timestamp.from_unix_seconds(1_700_000_000)),
      change_frequency: Some(Monthly),
    )

  entry.url |> should.equal("https://example.com/about")
  entry.priority |> should.equal(Some(1.0))
  entry.last_modified |> should.be_some
  entry.change_frequency |> should.equal(Some(Monthly))
}

pub fn sitemap_entry_with_no_optional_fields_test() {
  let entry =
    SitemapEntry(
      url: "https://example.com/page",
      priority: Some(0.5),
      last_modified: None,
      change_frequency: None,
    )

  entry.last_modified |> should.equal(None)
  entry.change_frequency |> should.equal(None)
}

pub fn change_frequency_variants_test() {
  // Verify all variants are distinct via pattern matching
  [Always, Hourly, Daily, Weekly, Monthly, Yearly, Never]
  |> check_all_frequencies
}

// --- Helper ---

fn check_all_frequencies(freqs: List(sitemap.ChangeFrequency)) -> Nil {
  case freqs {
    [] -> Nil
    [freq, ..rest] -> {
      case freq {
        Always -> should.equal(freq, Always)
        Hourly -> should.equal(freq, Hourly)
        Daily -> should.equal(freq, Daily)
        Weekly -> should.equal(freq, Weekly)
        Monthly -> should.equal(freq, Monthly)
        Yearly -> should.equal(freq, Yearly)
        Never -> should.equal(freq, Never)
      }
      check_all_frequencies(rest)
    }
  }
}
