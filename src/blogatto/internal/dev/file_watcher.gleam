//// File watcher integration using filespy to detect source file changes.

import blogatto/internal/dev/message
import blogatto/internal/dev/rebuild_actor
import filepath
import filespy
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleam/result
import simplifile

/// A file watcher that uses `filespy` to watch for changes in the specified
/// directories and notifies the rebuild actor to trigger rebuilds.
///
/// Directories are resolved to absolute paths before being passed to filespy,
/// because the underlying `fs` Erlang library uses the watch path as both the
/// working directory and the path argument for `mac_listener`. If a relative
/// path like `"./blog"` is passed, `mac_listener` ends up watching
/// `<cwd>/blog/blog` (a non-existent path), so no events are ever emitted.
pub fn new(
  dirs: List(String),
  rebuild_subject: Subject(message.RebuildMessage),
) -> Result(actor.Started(Subject(filespy.Change(Nil))), actor.StartError) {
  let abs_dirs = resolve_to_absolute(dirs)

  filespy.new()
  |> filespy.add_dirs(abs_dirs)
  |> filespy.set_handler(fn(path, event) {
    case event {
      filespy.Created | filespy.Modified | filespy.Deleted | filespy.Renamed -> {
        rebuild_actor.file_changed(rebuild_subject, path)
      }
      _ -> Nil
    }
  })
  |> filespy.start()
}

/// Resolve a list of directory paths to absolute paths. Paths that are already
/// absolute are left unchanged; relative paths are joined with the current
/// working directory.
pub fn resolve_to_absolute(dirs: List(String)) -> List(String) {
  let cwd =
    simplifile.current_directory()
    |> result.unwrap("")

  list.map(dirs, fn(dir) {
    case filepath.is_absolute(dir) {
      True -> dir
      False -> filepath.join(cwd, dir)
    }
  })
}
