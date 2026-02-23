//// Builder for static assets. This is a simple builder that copies files from the configured static directory to the output directory.
//// It should run early in the build process to ensure that any static files needed by pages or posts are available when those builders run.
//// No parsing or rendering involved, just copying files while preserving directory structure.

import blogatto/config
import blogatto/error
import gleam/option
import gleam/result
import simplifile

/// Build the static assets for the blog by copying files from the configured static directory to the output directory.
pub fn build(config: config.Config(msg)) -> Result(Nil, error.BlogattoError) {
  case config.static_dir {
    option.None -> Ok(Nil)
    // no static dir configured, nothing to do
    option.Some(static_dir) -> copy_static_dir(static_dir, config.output_dir)
  }
}

/// Helper function to copy the static directory to the output directory.
fn copy_static_dir(
  static_dir: String,
  output_dir: String,
) -> Result(Nil, error.BlogattoError) {
  static_dir
  |> simplifile.copy(output_dir)
  |> result.map_error(error.File)
}
