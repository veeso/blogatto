//// Internal date parser for frontmatter date strings.
////
//// Parses date strings in the `YYYY-MM-DD HH:MM:SS` format into
//// `gleam/time/timestamp.Timestamp` values. All dates are interpreted
//// as UTC.

import blogatto/error
import gleam/int
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

/// Parse a date string in `YYYY-MM-DD HH:MM:SS` format into a UTC timestamp.
///
/// The date and time components are separated by a single space. The time
/// portion uses 24-hour format. Returns `FrontmatterInvalidDate` if the
/// string does not match the expected format or contains out-of-range values.
///
/// ## Examples
///
/// ```gleam
/// parse("2023-01-25 00:00:00")
/// // -> Ok(timestamp representing 2023-01-25T00:00:00Z)
/// ```
pub fn parse(raw: String) -> Result(Timestamp, error.BlogattoError) {
  case string.split(raw, " ") {
    [date_part, time_part] -> {
      case string.split(date_part, "-"), string.split(time_part, ":") {
        [y, m, d], [hh, mm, ss] -> parse_components(y, m, d, hh, mm, ss, raw)
        _, _ -> Error(error.FrontmatterInvalidDate(raw))
      }
    }
    _ -> Error(error.FrontmatterInvalidDate(raw))
  }
}

/// Parse individual string components into integers and build a timestamp.
fn parse_components(
  y: String,
  m: String,
  d: String,
  hh: String,
  mm: String,
  ss: String,
  raw: String,
) -> Result(Timestamp, error.BlogattoError) {
  case
    int.parse(y),
    int.parse(m),
    int.parse(d),
    int.parse(hh),
    int.parse(mm),
    int.parse(ss)
  {
    Ok(year), Ok(month), Ok(day), Ok(hours), Ok(minutes), Ok(seconds) ->
      build_timestamp(year, month, day, hours, minutes, seconds, raw)
    _, _, _, _, _, _ -> Error(error.FrontmatterInvalidDate(raw))
  }
}

/// Build a timestamp from validated integer components.
fn build_timestamp(
  year: Int,
  month: Int,
  day: Int,
  hours: Int,
  minutes: Int,
  seconds: Int,
  raw: String,
) -> Result(Timestamp, error.BlogattoError) {
  case month_from_int(month) {
    Ok(m) ->
      Ok(timestamp.from_calendar(
        date: calendar.Date(year:, month: m, day:),
        time: calendar.TimeOfDay(hours:, minutes:, seconds:, nanoseconds: 0),
        offset: duration.seconds(0),
      ))
    Error(Nil) -> Error(error.FrontmatterInvalidDate(raw))
  }
}

/// Convert a 1-based month integer to a calendar month.
fn month_from_int(month: Int) -> Result(calendar.Month, Nil) {
  case month {
    1 -> Ok(calendar.January)
    2 -> Ok(calendar.February)
    3 -> Ok(calendar.March)
    4 -> Ok(calendar.April)
    5 -> Ok(calendar.May)
    6 -> Ok(calendar.June)
    7 -> Ok(calendar.July)
    8 -> Ok(calendar.August)
    9 -> Ok(calendar.September)
    10 -> Ok(calendar.October)
    11 -> Ok(calendar.November)
    12 -> Ok(calendar.December)
    _ -> Error(Nil)
  }
}
