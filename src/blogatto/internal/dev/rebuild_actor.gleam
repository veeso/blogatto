//// OTP actor for coordinating file-change-triggered rebuilds with debouncing.

import blogatto/internal/dev/command
import blogatto/internal/dev/message
import gleam/erlang/process.{type Subject, type Timer}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor

const debounce_delay: Int = 300

type RebuildState {
  RebuildState(
    self: Subject(message.RebuildMessage),
    build_command: String,
    debounce_timer: Option(Timer),
    sse_clients: List(Subject(message.SseMessage)),
  )
}

/// Send a file change notification to the rebuild actor. This resets the
/// debounce timer; after the debounce delay, the build command will run.
pub fn file_changed(
  subject: Subject(message.RebuildMessage),
  path: String,
) -> Nil {
  actor.send(subject, message.FileChanged(path:))
}

/// Register an SSE client subject with the rebuild actor. The client will
/// receive `Reload` messages after each successful rebuild.
pub fn register_sse_client(
  subject: Subject(message.RebuildMessage),
  client: Subject(message.SseMessage),
) -> Nil {
  actor.send(subject, message.RegisterSseClient(subject: client))
}

/// Start the rebuild actor with the given build command. The actor will wait
/// for file change messages, debounce them, shell out to the build command,
/// and broadcast reload events to connected SSE clients.
pub fn new(
  build_command: String,
) -> Result(actor.Started(Subject(message.RebuildMessage)), actor.StartError) {
  actor.new_with_initialiser(5000, fn(subject) {
    // Schedule an immediate rebuild on startup
    process.send(subject, message.Rebuild)
    RebuildState(
      self: subject,
      build_command:,
      debounce_timer: option.None,
      sse_clients: [],
    )
    |> actor.initialised
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
}

fn handle_message(
  state: RebuildState,
  message: message.RebuildMessage,
) -> actor.Next(RebuildState, message.RebuildMessage) {
  case message {
    message.FileChanged(path:) -> {
      io.println("⟳ File changed: " <> path)
      // Cancel existing debounce timer if one is running
      let _ = option.map(state.debounce_timer, process.cancel_timer)
      // Start a new debounce timer
      let timer =
        process.send_after(state.self, debounce_delay, message.Rebuild)
      actor.continue(RebuildState(..state, debounce_timer: option.Some(timer)))
    }
    message.Rebuild -> {
      // Prune dead SSE clients, then broadcast reload on success
      let live_clients = prune_dead_clients(state.sse_clients)
      case rebuild(state.build_command) {
        True -> broadcast_reload(live_clients)
        False -> Nil
      }
      actor.continue(
        RebuildState(
          ..state,
          debounce_timer: option.None,
          sse_clients: live_clients,
        ),
      )
    }
    message.RegisterSseClient(subject:) -> {
      actor.continue(
        RebuildState(
          ..state,
          sse_clients: list.prepend(state.sse_clients, subject),
        ),
      )
    }
  }
}

fn rebuild(build_command: String) -> Bool {
  io.println("⟳ Rebuilding...")
  let #(exit_code, output) = command.exec(build_command)
  case exit_code {
    0 -> {
      io.println("✓ Rebuild complete")
      True
    }
    _ -> {
      io.println(
        "✗ Build failed (exit code " <> int.to_string(exit_code) <> "):",
      )
      io.println(output)
      io.println("  (server still running, fix the error and save again)")
      False
    }
  }
}

fn broadcast_reload(clients: List(Subject(message.SseMessage))) -> Nil {
  list.each(clients, fn(client) { actor.send(client, message.Reload) })
}

/// Remove SSE clients whose owning process is no longer alive.
fn prune_dead_clients(
  clients: List(Subject(message.SseMessage)),
) -> List(Subject(message.SseMessage)) {
  list.filter(clients, fn(client) {
    case process.subject_owner(client) {
      Ok(pid) -> process.is_alive(pid)
      Error(_) -> False
    }
  })
}
