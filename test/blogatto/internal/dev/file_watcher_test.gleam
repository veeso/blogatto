import blogatto/internal/dev/file_watcher
import gleam/list
import gleam/string
import gleeunit/should
import simplifile

pub fn resolve_to_absolute_leaves_absolute_paths_unchanged_test() {
  let dirs = ["/usr/local/bin", "/tmp"]
  let result = file_watcher.resolve_to_absolute(dirs)
  result |> should.equal(["/usr/local/bin", "/tmp"])
}

pub fn resolve_to_absolute_resolves_relative_paths_test() {
  let dirs = ["./blog", "static"]
  let result = file_watcher.resolve_to_absolute(dirs)
  let assert Ok(cwd) = simplifile.current_directory()
  // All results should be absolute paths
  list.each(result, fn(path) {
    path |> string.starts_with("/") |> should.be_true
  })
  // The relative paths should be joined with the cwd
  result |> list.length |> should.equal(2)
  list.each(result, fn(path) {
    path |> string.starts_with(cwd) |> should.be_true
  })
}

pub fn resolve_to_absolute_mixed_paths_test() {
  let dirs = ["/absolute", "./relative"]
  let result = file_watcher.resolve_to_absolute(dirs)
  let assert Ok(cwd) = simplifile.current_directory()
  case result {
    [first, second] -> {
      first |> should.equal("/absolute")
      second |> string.starts_with(cwd) |> should.be_true
    }
    _ -> should.fail()
  }
}

pub fn resolve_to_absolute_empty_list_test() {
  let result = file_watcher.resolve_to_absolute([])
  result |> should.equal([])
}
