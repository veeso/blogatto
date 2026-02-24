//// Internal date parser for frontmatter date strings.
////
//// Parses date strings in the `YYYY-MM-DD HH:MM:SS` format into
//// `gleam/time/timestamp.Timestamp` values using the tempo library.
//// All dates are interpreted as UTC.

import blogatto/error
import gleam/result
import gleam/time/timestamp.{type Timestamp}
import tempo
import tempo/datetime
import tempo/naive_datetime

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
  let fmt = tempo.CustomNaive(format: "YYYY-MM-DD HH:mm:ss")
  raw
  |> naive_datetime.parse(fmt)
  |> result.map(naive_datetime.as_utc)
  |> result.map(datetime.to_timestamp)
  |> result.map_error(fn(_) { error.FrontmatterInvalidDate(raw) })
}
