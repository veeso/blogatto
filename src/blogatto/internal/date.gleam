//// Internal date parser for frontmatter date strings.
////
//// Parses date strings in the `YYYY-MM-DD HH:MM:SS` format into
//// `gleam/time/timestamp.Timestamp` values using the tempo library.
//// Dates without a timezone are interpreted as UTC.
//// An optional timezone can be specified as a UTC offset (e.g. `+02:00`)
//// or as an IANA timezone name (e.g. `Europe/Helsinki`).

import blogatto/error
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}
import tempo
import tempo/datetime
import tempo/naive_datetime
import tzif/database

/// Parse a date string into a UTC timestamp.
///
/// Accepted formats:
/// - `YYYY-MM-DD HH:MM:SS` — interpreted as UTC
/// - `YYYY-MM-DD HH:MM:SS +HH:MM` or `YYYY-MM-DD HH:MM:SS -HH:MM` — UTC offset
/// - `YYYY-MM-DD HH:MM:SS Continent/City` — IANA timezone name
///
/// Returns `FrontmatterInvalidDate` if the string does not match any
/// expected format or contains out-of-range values.
///
/// ## Examples
///
/// ```gleam
/// parse("2023-01-25 00:00:00")
/// // -> Ok(timestamp representing 2023-01-25T00:00:00Z)
///
/// parse("2023-01-25 02:00:00 +02:00")
/// // -> Ok(timestamp representing 2023-01-25T00:00:00Z)
///
/// parse("2023-01-25 02:00:00 Europe/Helsinki")
/// // -> Ok(timestamp representing 2023-01-25T00:00:00Z)
/// ```
pub fn parse(raw: String) -> Result(Timestamp, error.BlogattoError) {
  let parts = string.split(raw, " ")
  case list.length(parts) {
    // "YYYY-MM-DD HH:MM:SS" — no timezone, interpret as UTC
    2 -> parse_naive(raw)
    // "YYYY-MM-DD HH:MM:SS <tz>" — has timezone part
    3 -> parse_with_tz(raw)
    _ -> Error(error.FrontmatterInvalidDate(raw))
  }
}

/// Parse a date string without a timezone (e.g. "2023-01-25 00:00:00") into a UTC timestamp.
fn parse_naive(raw: String) -> Result(Timestamp, error.BlogattoError) {
  let fmt = tempo.CustomNaive(format: "YYYY-MM-DD HH:mm:ss")
  raw
  |> naive_datetime.parse(fmt)
  |> result.map(naive_datetime.as_utc)
  |> result.map(datetime.to_timestamp)
  |> result.map_error(fn(_) { error.FrontmatterInvalidDate(raw) })
}

/// Parse a date string with a timezone at the end.
/// Handles both UTC offsets (e.g. "+02:00") and IANA timezone names
/// (e.g. "Europe/Helsinki") by first resolving names to offsets.
fn parse_with_tz(raw: String) -> Result(Timestamp, error.BlogattoError) {
  let fmt = tempo.Custom(format: "YYYY-MM-DD HH:mm:ss Z")
  raw
  |> resolve_tz_name
  |> datetime.parse(fmt)
  |> result.map(datetime.to_timestamp)
  |> result.map_error(fn(_) { error.FrontmatterInvalidDate(raw) })
}

/// If the string ends with an IANA timezone name (e.g. "Europe/Helsinki"),
/// replaces it with the equivalent UTC offset (e.g. "+02:00").
/// If the last token does not contain a "/" it is returned unchanged,
/// allowing offset formats like "+02:00" to pass through to tempo.
fn resolve_tz_name(raw: String) -> String {
  case string.split(raw, " ") {
    [date_part, time_part, tz_part] ->
      case string.contains(tz_part, "/") {
        True -> {
          let datetime_part = date_part <> " " <> time_part
          case resolve_offset(datetime_part, tz_part) {
            Ok(offset_str) -> datetime_part <> " " <> offset_str
            // If resolution fails, return unchanged so parse_with_tz fails
            // with FrontmatterInvalidDate
            Error(_) -> raw
          }
        }
        // Not a tz name, might be an offset like "+02:00" — pass through
        False -> raw
      }
    _ -> raw
  }
}

/// Look up the UTC offset for a timezone name at the given approximate datetime.
/// The datetime string is parsed as naive (UTC) to get a reference timestamp
/// for the lookup, which is close enough for correct DST resolution in
/// nearly all cases.
fn resolve_offset(datetime_str: String, tz_name: String) -> Result(String, Nil) {
  let fmt = tempo.CustomNaive(format: "YYYY-MM-DD HH:mm:ss")

  use naive <- result.try(
    naive_datetime.parse(datetime_str, fmt) |> result.replace_error(Nil),
  )
  let approximate_ts = naive |> naive_datetime.as_utc |> datetime.to_timestamp

  let db = get_tz_database()
  use zone_params <- result.try(
    database.get_zone_parameters(approximate_ts, tz_name, db)
    |> result.replace_error(Nil),
  )

  Ok(format_offset(zone_params.offset))
}

/// Format a Duration offset as "+HH:MM" or "-HH:MM".
fn format_offset(offset: duration.Duration) -> String {
  let total_seconds = {
    let #(seconds, _) = duration.to_seconds_and_nanoseconds(offset)
    seconds
  }
  let sign = case total_seconds >= 0 {
    True -> "+"
    False -> "-"
  }
  let abs_seconds = int.absolute_value(total_seconds)
  let hours = abs_seconds / 3600
  let minutes = { abs_seconds % 3600 } / 60

  sign
  <> int.to_string(hours)
  |> string.pad_start(2, "0")
  <> ":"
  <> int.to_string(minutes) |> string.pad_start(2, "0")
}

/// Get the timezone database, cached via persistent_term.
/// The database is loaded from the prebuilt zones package on first access.
@external(erlang, "blogatto_ffi", "get_tz_database")
fn get_tz_database() -> database.TzDatabase
