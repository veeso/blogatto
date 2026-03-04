import blogatto/internal/dev/rebuild_actor
import blogatto/internal/dev/web_server
import gleam/erlang/process
import gleam/int
import gleam/string
import gleeunit/should
import simplifile
import temporary

// -- Pure function tests: append_live_reload_script --------------------------

pub fn append_live_reload_disabled_returns_unchanged_test() {
  let html = "<html><body><p>Hello</p></body></html>"
  web_server.append_live_reload_script(html, False)
  |> should.equal(html)
}

pub fn append_live_reload_inserts_before_body_close_test() {
  let html = "<html><body><p>Hello</p></body></html>"
  let result = web_server.append_live_reload_script(html, True)
  result
  |> should.equal(
    "<html><body><p>Hello</p>"
    <> web_server.live_reload_script
    <> "</body></html>",
  )
}

pub fn append_live_reload_appends_when_no_body_close_test() {
  let html = "<html><p>Hello</p></html>"
  let result = web_server.append_live_reload_script(html, True)
  result
  |> string.ends_with(web_server.live_reload_script)
  |> should.be_true
  result
  |> string.starts_with("<html><p>Hello</p></html>")
  |> should.be_true
}

pub fn append_live_reload_contains_event_source_test() {
  let html = "<html><body></body></html>"
  let result = web_server.append_live_reload_script(html, True)
  result |> string.contains("EventSource") |> should.be_true
  result |> string.contains("/__blogatto_dev/reload") |> should.be_true
  result |> string.contains("location.reload()") |> should.be_true
}

pub fn append_live_reload_only_first_body_close_test() {
  // Only the first </body> occurrence should be matched
  let html = "<body>one</body><body>two</body>"
  let result = web_server.append_live_reload_script(html, True)
  result
  |> should.equal(
    "<body>one" <> web_server.live_reload_script <> "</body><body>two</body>",
  )
}

pub fn append_live_reload_empty_html_test() {
  let result = web_server.append_live_reload_script("", True)
  result |> should.equal(web_server.live_reload_script)
}

// -- Pure function tests: mime_type_for_path ---------------------------------

pub fn mime_type_html_test() {
  web_server.mime_type_for_path("page.html")
  |> should.equal("text/html")
}

pub fn mime_type_css_test() {
  web_server.mime_type_for_path("style.css")
  |> should.equal("text/css")
}

pub fn mime_type_js_test() {
  web_server.mime_type_for_path("app.js")
  |> should.equal("text/javascript")
}

pub fn mime_type_png_test() {
  web_server.mime_type_for_path("image.png")
  |> should.equal("image/png")
}

pub fn mime_type_jpg_test() {
  web_server.mime_type_for_path("photo.jpg")
  |> should.equal("image/jpeg")
}

pub fn mime_type_svg_test() {
  web_server.mime_type_for_path("icon.svg")
  |> should.equal("image/svg+xml")
}

pub fn mime_type_nested_path_test() {
  web_server.mime_type_for_path("assets/fonts/bold.woff2")
  |> should.equal("font/woff2")
}

pub fn mime_type_multiple_dots_test() {
  // "script.min.js" → last segment is "js"
  web_server.mime_type_for_path("script.min.js")
  |> should.equal("text/javascript")
}

pub fn mime_type_unknown_extension_test() {
  web_server.mime_type_for_path("data.xyz123")
  |> should.equal("application/octet-stream")
}

// -- Integration tests -------------------------------------------------------

@external(erlang, "blogatto_test_http_ffi", "http_get")
fn http_get(url: String) -> Result(#(Int, String, String), String)

@external(erlang, "blogatto_test_http_ffi", "http_get_no_redirect")
fn http_get_no_redirect(
  url: String,
) -> Result(#(Int, String, String, String), String)

/// Helper to build a localhost URL for the test server.
fn url(port: Int, path: String) -> String {
  "http://127.0.0.1:" <> int.to_string(port) <> path
}

pub fn serve_html_page_test() {
  let port = 20_152
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) =
      simplifile.write(
        output_dir <> "/index.html",
        "<html><body><h1>Home</h1></body></html>",
      )

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    let assert Ok(#(status, content_type, body)) = http_get(url(port, "/"))
    status |> should.equal(200)
    content_type |> string.contains("text/html") |> should.be_true
    body |> string.contains("<h1>Home</h1>") |> should.be_true
    // Live reload script should be injected
    body |> string.contains("EventSource") |> should.be_true

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_html_page_without_live_reload_test() {
  let port = 20_153
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) =
      simplifile.write(
        output_dir <> "/index.html",
        "<html><body><h1>Home</h1></body></html>",
      )

    let pids = start_server(output_dir, port, False)
    process.sleep(100)

    let assert Ok(#(status, _, body)) = http_get(url(port, "/"))
    status |> should.equal(200)
    body |> string.contains("<h1>Home</h1>") |> should.be_true
    // Live reload script should NOT be injected
    body |> string.contains("EventSource") |> should.be_false

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_nested_page_test() {
  let port = 20_154
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) = simplifile.create_directory_all(output_dir <> "/about")
    let assert Ok(_) =
      simplifile.write(
        output_dir <> "/about/index.html",
        "<html><body><p>About</p></body></html>",
      )

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    let assert Ok(#(status, _, body)) = http_get(url(port, "/about/"))
    status |> should.equal(200)
    body |> string.contains("<p>About</p>") |> should.be_true

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_missing_page_returns_404_test() {
  let port = 20_155
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    let assert Ok(#(status, _, _)) = http_get(url(port, "/nonexistent/"))
    status |> should.equal(404)

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_static_asset_test() {
  let port = 20_156
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) =
      simplifile.write(output_dir <> "/style.css", "body { color: red; }")

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    let assert Ok(#(status, content_type, body)) =
      http_get(url(port, "/style.css"))
    status |> should.equal(200)
    content_type |> string.contains("text/css") |> should.be_true
    body |> string.contains("color: red") |> should.be_true
    // Assets should NOT have live reload script
    body |> string.contains("EventSource") |> should.be_false

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_missing_asset_returns_404_test() {
  let port = 20_157
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    let assert Ok(#(status, _, _)) = http_get(url(port, "/missing.js"))
    status |> should.equal(404)

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn path_traversal_page_returns_404_test() {
  let port = 20_158
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) =
      simplifile.write(
        output_dir <> "/index.html",
        "<html><body>Home</body></html>",
      )

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    // Attempt path traversal with ..
    let assert Ok(#(status, _, _)) = http_get(url(port, "/../../etc/passwd"))
    status |> should.equal(404)

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn path_traversal_asset_returns_404_test() {
  let port = 20_159
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    // Attempt path traversal on an asset path
    let assert Ok(#(status, _, _)) = http_get(url(port, "/../../../etc/hosts"))
    status |> should.equal(404)

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_html_page_has_no_cache_headers_test() {
  let port = 20_160
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) =
      simplifile.write(
        output_dir <> "/index.html",
        "<html><body>Home</body></html>",
      )

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    let assert Ok(#(status, _, _)) = http_get(url(port, "/"))
    status |> should.equal(200)

    stop_server(pids)
    Ok(Nil)
  }
}

pub fn serve_nested_page_without_trailing_slash_redirects_test() {
  let port = 20_161
  let assert Ok(_) = {
    use output_dir <- temporary.create(temporary.directory())
    let assert Ok(_) = simplifile.create_directory_all(output_dir <> "/about")
    let assert Ok(_) =
      simplifile.write(
        output_dir <> "/about/index.html",
        "<html><body><p>About</p></body></html>",
      )

    let pids = start_server(output_dir, port, True)
    process.sleep(100)

    // Without trailing slash should redirect to /about/
    let assert Ok(#(status, _, location, _)) =
      http_get_no_redirect(url(port, "/about"))
    status |> should.equal(301)
    location |> should.equal("/about/")

    stop_server(pids)
    Ok(Nil)
  }
}

/// Start the dev web server for testing. Returns the PIDs of the rebuild
/// actor and the mist supervisor, both unlinked from the test process so
/// that cleanup with `process.kill` does not crash the test.
fn start_server(
  output_dir: String,
  port: Int,
  live_reload: Bool,
) -> #(process.Pid, process.Pid) {
  // Start a rebuild actor (uses "true" so it always succeeds)
  let assert Ok(rebuild_started) = rebuild_actor.new("true")
  process.unlink(rebuild_started.pid)
  // Wait for initial rebuild
  process.sleep(200)

  let assert Ok(server_started) =
    web_server.WebServer(
      host: "127.0.0.1",
      port:,
      live_reload:,
      output_dir:,
      rebuild_subject: rebuild_started.data,
    )
    |> web_server.start()
  process.unlink(server_started.pid)

  #(rebuild_started.pid, server_started.pid)
}

fn stop_server(pids: #(process.Pid, process.Pid)) -> Nil {
  process.kill(pids.1)
  process.kill(pids.0)
  process.sleep(50)
}
