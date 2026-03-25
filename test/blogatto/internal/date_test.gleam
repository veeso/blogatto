import blogatto/error
import blogatto/internal/date
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import gleeunit/should

pub fn parse_valid_datetime_test() {
  date.parse("2023-01-25 00:00:00")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.January, day: 25),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

pub fn parse_datetime_with_nonzero_time_test() {
  date.parse("2024-12-31 23:59:59")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2024, month: calendar.December, day: 31),
    time: calendar.TimeOfDay(
      hours: 23,
      minutes: 59,
      seconds: 59,
      nanoseconds: 0,
    ),
    offset: duration.seconds(0),
  ))
}

pub fn parse_returns_error_for_missing_time_test() {
  date.parse("2023-01-25")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate("2023-01-25"))
}

pub fn parse_returns_error_for_invalid_month_test() {
  date.parse("2023-13-25 00:00:00")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate("2023-13-25 00:00:00"))
}

pub fn parse_returns_error_for_zero_month_test() {
  date.parse("2023-00-25 00:00:00")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate("2023-00-25 00:00:00"))
}

pub fn parse_returns_error_for_non_numeric_test() {
  date.parse("abcd-ef-gh ij:kl:mn")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate("abcd-ef-gh ij:kl:mn"))
}

pub fn parse_returns_error_for_empty_string_test() {
  date.parse("")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate(""))
}

pub fn parse_returns_error_for_wrong_separator_test() {
  date.parse("2023/01/25 00:00:00")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate("2023/01/25 00:00:00"))
}

// Timezone offset tests

pub fn parse_datetime_with_positive_utc_offset_test() {
  // 2023-01-25 02:00:00 +02:00 should be 2023-01-25 00:00:00 UTC
  date.parse("2023-01-25 02:00:00 +02:00")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.January, day: 25),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

pub fn parse_datetime_with_negative_utc_offset_test() {
  // 2023-01-24 19:00:00 -05:00 should be 2023-01-25 00:00:00 UTC
  date.parse("2023-01-24 19:00:00 -05:00")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.January, day: 25),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

pub fn parse_datetime_with_utc_offset_zero_test() {
  date.parse("2023-01-25 00:00:00 +00:00")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.January, day: 25),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

// IANA timezone name tests

pub fn parse_datetime_with_iana_tz_name_test() {
  // Europe/Helsinki is UTC+2 in January (EET, no DST)
  // 2023-01-25 02:00:00 Europe/Helsinki should be 2023-01-25 00:00:00 UTC
  date.parse("2023-01-25 02:00:00 Europe/Helsinki")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.January, day: 25),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

pub fn parse_datetime_with_negative_iana_tz_test() {
  // America/New_York is UTC-5 in January (EST, no DST)
  // 2023-01-24 19:00:00 America/New_York should be 2023-01-25 00:00:00 UTC
  date.parse("2023-01-24 19:00:00 America/New_York")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.January, day: 25),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

pub fn parse_datetime_with_iana_tz_during_dst_test() {
  // America/New_York is UTC-4 in July (EDT, DST active)
  // 2023-07-25 20:00:00 America/New_York should be 2023-07-26 00:00:00 UTC
  date.parse("2023-07-25 20:00:00 America/New_York")
  |> should.be_ok()
  |> should.equal(timestamp.from_calendar(
    date: calendar.Date(year: 2023, month: calendar.July, day: 26),
    time: calendar.TimeOfDay(hours: 0, minutes: 0, seconds: 0, nanoseconds: 0),
    offset: duration.seconds(0),
  ))
}

pub fn parse_returns_error_for_invalid_tz_name_test() {
  date.parse("2023-01-25 00:00:00 Invalid/Timezone")
  |> should.be_error()
  |> should.equal(error.FrontmatterInvalidDate(
    "2023-01-25 00:00:00 Invalid/Timezone",
  ))
}
