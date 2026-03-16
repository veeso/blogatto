---
layout: default
title: Dev server
nav_order: 11
---

# Dev server

Blogatto includes a built-in development server that watches your source files for changes, automatically rebuilds the site, and live-reloads the browser. This eliminates the need for Docker or external servers during development.

## Overview

The dev server combines three capabilities into a single `dev.start()` call:

1. **File watching** — monitors `src/`, markdown paths, and static assets for changes using [filespy](https://hexdocs.pm/filespy/)
2. **Auto-rebuild** — shells out to a configurable build command with debouncing (~300ms) to batch rapid saves
3. **Live reload** — injects a small script into HTML responses that reloads the browser via Server-Sent Events (SSE) after each successful rebuild

## Setup

The dev server needs its own entrypoint module, separate from your build script. This is because the dev server runs your build command as a subprocess — it shells out to `gleam run` (or whatever you configure) to rebuild the site.

### 1. Extract your config into a shared module

If your build configuration lives directly in `main()`, move it to a separate module so both the build script and dev server can use it:

```gleam
// src/my_blog/blog.gleam

import blogatto/config
import blogatto/config/markdown

pub fn config() -> config.Config(Nil) {
  let md =
    markdown.default()
    |> markdown.markdown_path("./blog")
    |> markdown.route_prefix("blog")

  config.new("https://example.com")
  |> config.output_dir("./dist")
  |> config.static_dir("./static")
  |> config.markdown(md)
  |> config.route("/", home_view)
}

// ... view functions ...
```

### 2. Update your build script

```gleam
// src/my_blog.gleam

import blogatto
import blogatto/error
import gleam/io
import my_blog/blog

pub fn main() {
  case blogatto.build(blog.config()) {
    Ok(Nil) -> io.println("Site built successfully!")
    Error(err) -> io.println("Build failed: " <> error.describe_error(err))
  }
}
```

### 3. Create a dev entrypoint

```gleam
// src/my_blog/dev.gleam

import blogatto/dev
import blogatto/error
import gleam/io
import my_blog/blog

pub fn main() {
  case
    blog.config()
    |> dev.new()
    |> dev.build_command("gleam run -m my_blog")
    |> dev.port(3000)
    |> dev.start()
  {
    Ok(Nil) -> io.println("Dev server stopped.")
    Error(err) -> io.println("Dev server error: " <> error.describe_error(err))
  }
}
```

### 4. Run the dev server

```sh
gleam run -m my_blog/dev
```

The server starts, performs an initial build, then watches for changes:

```text
🔨 blogatto dev server starting...
👀 Watching for file changes...
	👀 Watching: ./static
	👀 Watching: ./src/
	👀 Watching: ./blog

⟳ Rebuilding...
✓ Rebuild complete
	→  http://127.0.0.1:3000
	Output: ./dist
```

Open `http://127.0.0.1:3000` in your browser. When you save a file, the site rebuilds and the browser reloads automatically.

## Configuration

The `DevServer` type uses the same builder pattern as the rest of Blogatto:

```gleam
blog.config()
|> dev.new()
|> dev.build_command("gleam run -m my_blog")
|> dev.port(8080)
|> dev.host("0.0.0.0")
|> dev.live_reload(False)
|> dev.start()
```

### `dev.new(config)`

Creates a new `DevServer` from a Blogatto `Config`. The config is used to derive:

- **Output directory** — served over HTTP
- **Markdown paths** — watched for blog post changes
- **Static directory** — watched for asset changes
- **`src/`** — always watched for Gleam source changes

### `dev.build_command(server, command)`

Set the shell command executed on each rebuild. Default: `"gleam run"`.

The build command can be anything: `gleam run -m my_blog`, `make build`, a shell script, etc. Each invocation recompiles the project and runs your build logic, so source changes are picked up naturally without BEAM hot-reloading.

```gleam
dev.new(config)
|> dev.build_command("gleam run -m my_blog")
```

### `dev.port(server, port)`

Set the HTTP server port. Default: `3000`.

```gleam
dev.new(config)
|> dev.port(8080)
```

### `dev.host(server, host)`

Set the bind address. Default: `"127.0.0.1"`.

To make the server accessible from other devices on your network:

```gleam
dev.new(config)
|> dev.host("0.0.0.0")
```

### `dev.live_reload(server, enabled)`

Enable or disable live-reload script injection. Default: `True`.

When enabled, the dev server:

1. Injects a small `<script>` tag before `</body>` in all served HTML responses
2. Exposes an SSE endpoint at `/__blogatto_dev/reload`
3. After each successful rebuild, sends a reload event to all connected browsers

When disabled, the server still watches and rebuilds, but you must manually refresh the browser.

```gleam
dev.new(config)
|> dev.live_reload(False)
```

## Reference

| Option | Default | Description |
|--------|---------|-------------|
| `build_command` | `"gleam run"` | Shell command to rebuild the site |
| `port` | `3000` | HTTP server port |
| `host` | `"127.0.0.1"` | Bind address |
| `live_reload` | `True` | Inject live-reload script into HTML responses |

## How it works

### Architecture

The dev server is built on OTP actors:

- **Rebuild actor** — receives file change notifications, debounces them (300ms), shells out to the build command, and broadcasts reload events to connected browsers
- **File watcher** — uses [filespy](https://hexdocs.pm/filespy/) (which wraps Erlang's `fs` library) to monitor directories and send change events to the rebuild actor
- **HTTP server** — [mist](https://hexdocs.pm/mist/) serves static files from the output directory and manages SSE connections for live reload

### Rebuild flow

1. A file changes on disk
2. The file watcher sends a `FileChanged` message to the rebuild actor
3. The rebuild actor cancels any pending debounce timer and starts a new 300ms timer
4. When the timer fires, the actor shells out to the build command
5. On success (exit code 0), a `Reload` event is sent to all connected SSE clients
6. On failure, the error output is logged and the server keeps running with the last successful build

### Watched directories

The dev server watches these directories based on your config:

| Source | Derived from |
|--------|-------------|
| Gleam source code | `src/` (always watched) |
| Blog post directories | `config.markdown_config.paths` |
| Static assets directory | `config.static_dir` |

The output directory itself is **not** watched — it is rebuilt by the build command.

### HTTP serving

The dev server serves files from `config.output_dir`:

- Directory requests (paths ending in `/`) resolve to `index.html` within that directory
- `.html` paths are served with `Content-Type: text/html`
- Other files are served with the appropriate MIME type based on file extension
- All responses include `Cache-Control: no-cache, no-store` to prevent browser caching
- Path traversal attempts (paths containing `..`) are rejected with 404
- Missing files return 404

## Platform notes

### Linux

The file watcher requires `inotify-tools` to be installed:

```sh
# Debian/Ubuntu
sudo apt-get install inotify-tools

# Fedora
sudo dnf install inotify-tools

# Arch Linux
sudo pacman -S inotify-tools
```

### macOS

File watching uses FSEvents natively — no additional setup required.

## Troubleshooting

### Build command hangs

If the build command prompts for input or enters an infinite loop, it will be killed after 120 seconds and the dev server will report a timeout error. Fix the underlying issue in your build command.

### Port already in use

If the port is already bound by another process, `dev.start()` returns an error. Either stop the other process or use a different port:

```gleam
dev.new(config) |> dev.port(8080)
```

### No file change events on Linux

Make sure `inotify-tools` is installed. You may also need to increase the inotify watch limit:

```sh
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
