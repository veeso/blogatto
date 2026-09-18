# Run all tests.
[group('test')]
test args="":
  gleam test {{ args }}

# Run a single test module.
[group('test')]
test_module module:
  gleam test -- --module={{ module }}
