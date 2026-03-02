//// Web server for development.

import blogatto/internal/dev/message
import blogatto/internal/dev/rebuild_actor
import blogatto/internal/path
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/otp/actor
import gleam/otp/static_supervisor
import gleam/string
import gleam/string_tree
import marceau
import mist.{type Connection, type ResponseData}
import simplifile

pub type WebServer {
  WebServer(
    host: String,
    port: Int,
    live_reload: Bool,
    output_dir: String,
    rebuild_subject: Subject(message.RebuildMessage),
  )
}

/// Start the development web server. This serves the generated blog and sends reload events to clients when the rebuild actor triggers a rebuild.
pub fn start(
  server: WebServer,
) -> Result(actor.Started(static_supervisor.Supervisor), actor.StartError) {
  fn(request) { handle_request(request, server) }
  |> mist.new
  |> mist.bind(server.host)
  |> mist.port(server.port)
  |> mist.start
}

fn handle_request(
  request: Request(Connection),
  server: WebServer,
) -> Response(ResponseData) {
  case request.path {
    "/__blogatto_dev/reload" if server.live_reload -> {
      mist.server_sent_events(
        request:,
        initial_response: response.new(200),
        init: sse_init(server.rebuild_subject),
        loop: sse_loop,
      )
    }
    path -> {
      // Reject path traversal attempts
      case string.contains(path, "..") {
        True -> not_found()
        False -> {
          case classify_path(path) {
            Page -> serve_page(server.output_dir, path, server.live_reload)
            Asset -> serve_asset(server.output_dir, path)
            Redirect(to) -> redirect(to)
          }
        }
      }
    }
  }
}

fn sse_init(
  rebuild_subject: Subject(message.RebuildMessage),
) -> fn(Subject(message.SseMessage)) ->
  Result(actor.Initialised(Nil, message.SseMessage, Nil), String) {
  fn(subject) {
    rebuild_actor.register_sse_client(rebuild_subject, subject)
    actor.initialised(Nil)
    |> Ok
  }
}

fn sse_loop(
  _state: Nil,
  msg: message.SseMessage,
  conn: mist.SSEConnection,
) -> actor.Next(Nil, message.SseMessage) {
  case msg {
    message.Reload -> {
      let event =
        string_tree.from_string("reload")
        |> mist.event
        |> mist.event_name("reload")
      case mist.send_event(conn, event) {
        Ok(_) -> actor.continue(Nil)
        Error(_) -> actor.stop()
      }
    }
  }
}

fn serve_page(
  output_dir: String,
  page: String,
  live_reload: Bool,
) -> Response(ResponseData) {
  let file_path = path.join(output_dir, page)
  let file_path = case string.ends_with(page, "/") {
    True -> path.join(file_path, "index.html")
    False -> file_path
  }
  case simplifile.is_file(file_path) {
    Error(_) -> not_found()
    Ok(False) -> not_found()
    Ok(True) -> {
      case simplifile.read(file_path) {
        Error(error) ->
          server_error(
            "Failed to read page: " <> simplifile.describe_error(error),
          )
        Ok(html) -> {
          200
          |> response.new()
          |> response.set_header("Content-Type", "text/html")
          |> response.set_header("Cache-Control", "no-cache, no-store")
          |> response.set_body(
            mist.Bytes(
              bytes_tree.from_string(append_live_reload_script(
                html,
                live_reload,
              )),
            ),
          )
        }
      }
    }
  }
}

pub const live_reload_script = "<script>new EventSource('/__blogatto_dev/reload').addEventListener('reload',function(){location.reload()});</script>"

/// Append the live reload script to HTML content. When `live_reload` is
/// `True`, the script is injected just before `</body>`. If no closing body
/// tag is found, it is appended at the end.
pub fn append_live_reload_script(html: String, live_reload: Bool) -> String {
  case live_reload {
    False -> html
    True -> {
      case string.split_once(html, "</body>") {
        Ok(#(before, after)) ->
          before <> live_reload_script <> "</body>" <> after
        Error(_) -> html <> live_reload_script
      }
    }
  }
}

fn serve_asset(output_dir: String, asset_path: String) -> Response(ResponseData) {
  let path = path.join(output_dir, asset_path)
  case simplifile.is_file(path) {
    Error(_) -> not_found()
    Ok(False) -> not_found()
    Ok(True) -> {
      case simplifile.read_bits(path) {
        Error(error) ->
          server_error(
            "Failed to read asset: " <> simplifile.describe_error(error),
          )
        Ok(bits) -> {
          200
          |> response.new()
          |> response.set_header("Content-Type", mime_type_for_path(asset_path))
          |> response.set_header("Cache-Control", "no-cache, no-store")
          |> response.set_body(mist.Bytes(bytes_tree.from_bit_array(bits)))
        }
      }
    }
  }
}

fn not_found() -> Response(ResponseData) {
  404
  |> response.new()
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

fn server_error(msg: String) -> Response(ResponseData) {
  500
  |> response.new()
  |> response.set_body(mist.Bytes(bytes_tree.from_string(msg)))
}

/// Determine the MIME type for a file path based on its extension.
pub fn mime_type_for_path(path: String) -> String {
  let ext = path |> string.split(".") |> list.reverse |> list.first
  case ext {
    Ok(ext) -> marceau.extension_to_mime_type(ext)
    Error(_) -> "application/octet-stream"
  }
}

type PathKind {
  Page
  Asset
  Redirect(to: String)
}

/// Classify a request path into a page, asset, or redirect.
/// Paths ending with `/` or `.html` are pages. Paths without a dot
/// (e.g. `/about`) are redirected to the same path with a trailing slash
/// so that relative URLs in the served HTML resolve correctly.
fn classify_path(path: String) -> PathKind {
  case string.ends_with(path, "/"), string.ends_with(path, ".html") {
    True, _ -> Page
    _, True -> Page
    _, _ ->
      case string.contains(path, ".") {
        True -> Asset
        False -> Redirect(path <> "/")
      }
  }
}

fn redirect(to location: String) -> Response(ResponseData) {
  301
  |> response.new()
  |> response.set_header("Location", location)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}
