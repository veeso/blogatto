//// Development server tool for Blogatto.

import blogatto/config
import blogatto/error
import blogatto/internal/dev/file_watcher
import blogatto/internal/dev/rebuild_actor
import blogatto/internal/dev/web_server
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string

/// A development server for Blogatto. This will serve the generated blog and watch for file changes to trigger rebuilds.
pub type DevServer(msg) {
  DevServer(
    /// Build command to build the blog. (default: "gleam run")
    build_command: String,
    /// Blogatto build config to use for knowing which files to watch.
    config: config.Config(msg),
    /// port to listen on. (default: 3000)
    port: Int,
    /// Host to listen on. (default: "127.0.0.1")
    host: String,
    /// Inject the live reload script into the generated HTML pages. (default: true)
    live_reload: Bool,
  )
}

/// Create a new development server with the given config and options.
pub fn new(config: config.Config(msg)) -> DevServer(msg) {
  DevServer(
    build_command: "gleam run",
    config:,
    port: 3000,
    host: "127.0.0.1",
    live_reload: True,
  )
}

/// Set the build command to use for building the blog.
/// This should be a command that can be run in the terminal to build the blog,
/// such as "gleam run" or "make build".
pub fn build_command(
  server: DevServer(msg),
  build_command: String,
) -> DevServer(msg) {
  DevServer(..server, build_command:)
}

/// Set the port to listen on.
pub fn port(server: DevServer(msg), port: Int) -> DevServer(msg) {
  DevServer(..server, port:)
}

/// Set the host to listen on.
pub fn host(server: DevServer(msg), host: String) -> DevServer(msg) {
  DevServer(..server, host:)
}

/// Set whether to inject the live reload script into the generated HTML pages.
pub fn live_reload(server: DevServer(msg), live_reload: Bool) -> DevServer(msg) {
  DevServer(..server, live_reload:)
}

/// Start the development server. This will block the current thread until the server is stopped.
pub fn start(server: DevServer(msg)) -> Result(Nil, error.BlogattoError) {
  io.println("🔨 blogatto dev server starting...")

  io.println("👀 Watching for file changes...")
  let paths_to_watch = paths_to_watch(server.config)
  list.each(paths_to_watch, fn(path) { io.println("\t👀 Watching: " <> path) })
  io.println("")

  // Start the rebuild actor (performs an initial build on startup)
  use started <- result.try(
    rebuild_actor.new(server.build_command)
    |> result.map_error(fn(e) {
      error.DevServer("Failed to start rebuild actor: " <> string.inspect(e))
    }),
  )
  let rebuild_subject = started.data

  // Start the file watcher to watch for changes and trigger rebuilds
  use _ <- result.try(
    paths_to_watch
    |> file_watcher.new(rebuild_subject)
    |> result.map_error(fn(e) {
      error.DevServer("Failed to start file watcher: " <> string.inspect(e))
    }),
  )
  // Start the web server
  use _ <- result.try(
    web_server.WebServer(
      host: server.host,
      port: server.port,
      live_reload: server.live_reload,
      output_dir: server.config.output_dir,
      rebuild_subject:,
    )
    |> web_server.start()
    |> result.map_error(fn(e) {
      error.DevServer("Failed to start web server: " <> string.inspect(e))
    }),
  )

  io.println("\t→  http://" <> server.host <> ":" <> int.to_string(server.port))
  io.println("\tOutput: " <> server.config.output_dir)

  process.sleep_forever()

  Ok(Nil)
}

/// Compute paths to watch for changes based on the given config. This should include all markdown files, src, and static assets.
fn paths_to_watch(config: config.Config(msg)) -> List(String) {
  let paths =
    config.markdown_config
    |> option.map(fn(markdown_config) { markdown_config.paths })
    |> option.unwrap(or: [])
    |> list.prepend("./src/")

  case config.static_dir {
    option.Some(static_dir) -> list.prepend(paths, static_dir)
    option.None -> paths
  }
}
