//// Internal date parser for frontmatter date strings.
////
//// Parses date strings in the `YYYY-MM-DD HH:MM:SS` format into
//// `gleam/time/timestamp.Timestamp` values using the tempo library.
//// Dates without a timezone are interpreted as UTC.
//// An optional timezone can be specified as a UTC offset (e.g. `+02:00`)
//// or as an IANA timezone name (e.g. `Europe/Helsinki`).

import blogatto/error
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}
import tempo
import tempo/date as tdate
import tempo/datetime
import tempo/naive_datetime
import tempo/time as ttime
import tzif/database
import tzif/tzcalendar

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
/// For UTC offsets (e.g. "+02:00"), parses directly with tempo.
/// For IANA timezone names (e.g. "Europe/Helsinki"), uses
/// tzcalendar.from_calendar to correctly resolve the local time to UTC,
/// handling DST transitions and ambiguous/invalid times.
fn parse_with_tz(raw: String) -> Result(Timestamp, error.BlogattoError) {
  case string.split(raw, " ") {
    [date_part, time_part, tz_part] ->
      case string.contains(tz_part, "/") {
        // IANA timezone name — use tzcalendar for correct DST handling
        True -> parse_with_iana_tz(raw, date_part <> " " <> time_part, tz_part)
        // UTC offset — parse directly with tempo
        False -> {
          let fmt = tempo.Custom(format: "YYYY-MM-DD HH:mm:ss Z")
          raw
          |> datetime.parse(fmt)
          |> result.map(datetime.to_timestamp)
          |> result.map_error(fn(_) { error.FrontmatterInvalidDate(raw) })
        }
      }
    _ -> Error(error.FrontmatterInvalidDate(raw))
  }
}

/// Parse a datetime string with an IANA timezone name using tzcalendar.
/// First parses the naive datetime to extract calendar parts, then uses
/// tzcalendar.from_calendar to convert the local time to UTC timestamp(s).
/// If the local time is ambiguous (DST fall-back), picks the earlier UTC
/// timestamp. If the local time is invalid (DST spring-forward), returns
/// an error.
fn parse_with_iana_tz(
  raw: String,
  datetime_str: String,
  tz_name: String,
) -> Result(Timestamp, error.BlogattoError) {
  let fmt = tempo.CustomNaive(format: "YYYY-MM-DD HH:mm:ss")
  let error = error.FrontmatterInvalidDate(raw)

  use naive <- result.try(
    naive_datetime.parse(datetime_str, fmt) |> result.replace_error(error),
  )

  // Extract calendar parts from the parsed naive datetime
  let parsed_date = naive_datetime.get_date(naive)
  let parsed_time = naive_datetime.get_time(naive)

  let date =
    calendar.Date(
      year: tdate.get_year(parsed_date),
      month: tdate.get_month(parsed_date),
      day: tdate.get_day(parsed_date),
    )
  let time =
    calendar.TimeOfDay(
      hours: ttime.get_hour(parsed_time),
      minutes: ttime.get_minute(parsed_time),
      seconds: ttime.get_second(parsed_time),
      nanoseconds: 0,
    )

  let db = get_tz_database()
  use timestamps <- result.try(
    tzcalendar.from_calendar(date, time, tz_name, db)
    |> result.replace_error(error),
  )

  case timestamps {
    // Single unambiguous result
    [ts] -> Ok(ts)
    // Ambiguous time (DST fall-back) — pick the earlier UTC timestamp
    [ts1, ts2, ..] ->
      case timestamp.compare(ts1, ts2) {
        order.Lt | order.Eq -> Ok(ts1)
        order.Gt -> Ok(ts2)
      }
    // Invalid time (DST spring-forward) — no valid timestamp exists
    [] -> Error(error)
  }
}

/// Get the timezone database, cached via persistent_term.
/// The database is loaded from the prebuilt zones package on first access.
@external(erlang, "blogatto_ffi", "get_tz_database")
fn get_tz_database() -> database.TzDatabase
