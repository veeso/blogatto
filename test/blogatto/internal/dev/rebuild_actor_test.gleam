import blogatto/internal/dev/message.{Reload}
import blogatto/internal/dev/rebuild_actor
import gleam/erlang/process
import gleeunit/should

pub fn new_starts_actor_test() {
  rebuild_actor.new("true")
  |> should.be_ok()
  // Wait for initial rebuild to complete before the test exits,
  // otherwise the actor's io.println may outlive the test's group leader
  process.sleep(200)
}

pub fn successful_build_broadcasts_reload_test() {
  let started =
    rebuild_actor.new("echo hello")
    |> should.be_ok()

  // Wait for the initial rebuild to finish before registering
  process.sleep(200)

  // Register an SSE client to receive reload notifications
  let sse_subject = process.new_subject()
  rebuild_actor.register_sse_client(started.data, sse_subject)

  // Trigger a file change
  rebuild_actor.file_changed(started.data, "test.md")

  // Wait for debounce (300ms) + build; should receive Reload
  process.receive(from: sse_subject, within: 2000)
  |> should.be_ok()
  |> should.equal(Reload)
}

pub fn failed_build_does_not_broadcast_reload_test() {
  let started =
    rebuild_actor.new("false")
    |> should.be_ok()

  // Wait for initial rebuild to finish
  process.sleep(200)

  let sse_subject = process.new_subject()
  rebuild_actor.register_sse_client(started.data, sse_subject)

  rebuild_actor.file_changed(started.data, "test.md")

  // Build fails so no Reload should arrive
  process.receive(from: sse_subject, within: 1000)
  |> should.be_error()
}

pub fn debounce_batches_rapid_changes_test() {
  let started =
    rebuild_actor.new("echo hello")
    |> should.be_ok()

  // Wait for initial rebuild to finish
  process.sleep(200)

  let sse_subject = process.new_subject()
  rebuild_actor.register_sse_client(started.data, sse_subject)

  // Send multiple rapid file changes; debounce should batch them
  rebuild_actor.file_changed(started.data, "a.md")
  rebuild_actor.file_changed(started.data, "b.md")
  rebuild_actor.file_changed(started.data, "c.md")
  rebuild_actor.file_changed(started.data, "d.md")
  rebuild_actor.file_changed(started.data, "e.md")

  // Exactly one Reload should arrive
  process.receive(from: sse_subject, within: 2000)
  |> should.be_ok()
  |> should.equal(Reload)

  // No second Reload should arrive
  process.receive(from: sse_subject, within: 500)
  |> should.be_error()
}

pub fn multiple_sse_clients_all_receive_reload_test() {
  let started =
    rebuild_actor.new("echo hello")
    |> should.be_ok()

  // Wait for initial rebuild to finish
  process.sleep(200)

  // Register two SSE clients
  let client_a = process.new_subject()
  let client_b = process.new_subject()
  rebuild_actor.register_sse_client(started.data, client_a)
  rebuild_actor.register_sse_client(started.data, client_b)

  rebuild_actor.file_changed(started.data, "test.md")

  // Both clients should receive Reload
  process.receive(from: client_a, within: 2000)
  |> should.be_ok()
  |> should.equal(Reload)

  process.receive(from: client_b, within: 2000)
  |> should.be_ok()
  |> should.equal(Reload)
}
