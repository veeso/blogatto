//// Message types for the dev server rebuild actor and SSE coordination.

import gleam/erlang/process.{type Subject}

/// Opaque message type for coordinating the rebuild actor.
pub type RebuildMessage {
  /// A watched file changed on disk. Sent by `filespy`
  FileChanged(path: String)
  /// The debounce timer fired, indicating that we should trigger a rebuild.
  Rebuild
  /// A client connected to the server-sent events endpoint and should be registered to receive reload notifications.
  RegisterSseClient(subject: Subject(SseMessage))
}

/// Message type for server-sent events to the client.
pub type SseMessage {
  Reload
}
