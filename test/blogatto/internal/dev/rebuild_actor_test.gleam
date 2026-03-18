import blogatto/internal/dev/message.{Reload}
import blogatto/internal/dev/rebuild_actor
import gleam/erlang/process
import gleam/option
import gleeunit/should

fn config(build_command: String) -> rebuild_actor.RebuildStateConfig {
  rebuild_actor.RebuildStateConfig(
    build_command:,
    before_build: option.None,
    after_build: option.None,
  )
}

pub fn new_starts_actor_test() {
  config("true")
  |> rebuild_actor.new()
  |> should.be_ok()
  // Wait for initial rebuild to complete before the test exits,
  // otherwise the actor's io.println may outlive the test's group leader
  process.sleep(200)
}

pub fn successful_build_broadcasts_reload_test() {
  let started =
    config("echo hello")
    |> rebuild_actor.new()
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
    config("false")
    |> rebuild_actor.new()
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
    config("echo hello")
    |> rebuild_actor.new()
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
    config("echo hello")
    |> rebuild_actor.new()
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

pub fn before_build_hook_is_called_test() {
  // Use a subject to track whether the before_build hook was called
  let hook_subject = process.new_subject()

  let started =
    rebuild_actor.RebuildStateConfig(
      build_command: "echo hello",
      before_build: option.Some(fn() {
        process.send(hook_subject, "before_build_called")
        Ok(Nil)
      }),
      after_build: option.None,
    )
    |> rebuild_actor.new()
    |> should.be_ok()

  // The initial rebuild should trigger the before_build hook
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("before_build_called")

  // Trigger another rebuild via file change
  rebuild_actor.file_changed(started.data, "test.md")

  // The before_build hook should be called again
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("before_build_called")

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}

pub fn after_build_hook_is_called_on_success_test() {
  let hook_subject = process.new_subject()

  let started =
    rebuild_actor.RebuildStateConfig(
      build_command: "echo hello",
      before_build: option.None,
      after_build: option.Some(fn() {
        process.send(hook_subject, "after_build_called")
        Ok(Nil)
      }),
    )
    |> rebuild_actor.new()
    |> should.be_ok()

  // The initial rebuild should trigger the after_build hook
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("after_build_called")

  // Trigger another rebuild via file change
  rebuild_actor.file_changed(started.data, "test.md")

  // The after_build hook should be called again
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("after_build_called")

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}

pub fn after_build_hook_not_called_on_failure_test() {
  let hook_subject = process.new_subject()

  let started =
    rebuild_actor.RebuildStateConfig(
      build_command: "false",
      before_build: option.None,
      after_build: option.Some(fn() {
        process.send(hook_subject, "after_build_called")
        Ok(Nil)
      }),
    )
    |> rebuild_actor.new()
    |> should.be_ok()

  // Initial build fails, after_build should NOT be called
  process.receive(from: hook_subject, within: 1000)
  |> should.be_error()

  // Trigger another failed rebuild
  rebuild_actor.file_changed(started.data, "test.md")

  // Still should not be called
  process.receive(from: hook_subject, within: 1000)
  |> should.be_error()

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}

pub fn before_build_hook_called_even_on_failure_test() {
  let hook_subject = process.new_subject()

  rebuild_actor.RebuildStateConfig(
    build_command: "false",
    before_build: option.Some(fn() {
      process.send(hook_subject, "before_build_called")
      Ok(Nil)
    }),
    after_build: option.None,
  )
  |> rebuild_actor.new()
  |> should.be_ok()

  // before_build should be called even when the build command fails
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("before_build_called")

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}

pub fn both_hooks_called_in_order_test() {
  let hook_subject = process.new_subject()

  rebuild_actor.RebuildStateConfig(
    build_command: "echo hello",
    before_build: option.Some(fn() {
      process.send(hook_subject, "before")
      Ok(Nil)
    }),
    after_build: option.Some(fn() {
      process.send(hook_subject, "after")
      Ok(Nil)
    }),
  )
  |> rebuild_actor.new()
  |> should.be_ok()

  // before_build should be called first
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("before")

  // then after_build
  process.receive(from: hook_subject, within: 2000)
  |> should.be_ok()
  |> should.equal("after")

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}

pub fn failing_before_build_hook_aborts_rebuild_test() {
  let sse_subject = process.new_subject()

  let started =
    rebuild_actor.RebuildStateConfig(
      build_command: "echo hello",
      before_build: option.Some(fn() { Error("setup failed") }),
      after_build: option.None,
    )
    |> rebuild_actor.new()
    |> should.be_ok()

  // Wait for the initial (failed) rebuild to complete
  process.sleep(500)

  // Register an SSE client
  rebuild_actor.register_sse_client(started.data, sse_subject)

  // Trigger a rebuild — before_build fails so no Reload should arrive
  rebuild_actor.file_changed(started.data, "test.md")

  process.receive(from: sse_subject, within: 1000)
  |> should.be_error()

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}

pub fn failing_after_build_hook_prevents_reload_test() {
  let sse_subject = process.new_subject()

  let started =
    rebuild_actor.RebuildStateConfig(
      build_command: "echo hello",
      before_build: option.None,
      after_build: option.Some(fn() { Error("post-processing failed") }),
    )
    |> rebuild_actor.new()
    |> should.be_ok()

  // Wait for the initial rebuild to complete
  process.sleep(500)

  // Register an SSE client
  rebuild_actor.register_sse_client(started.data, sse_subject)

  // Trigger a rebuild — after_build fails so no Reload should arrive
  rebuild_actor.file_changed(started.data, "test.md")

  process.receive(from: sse_subject, within: 1000)
  |> should.be_error()

  // Wait for the actor to finish its IO before the test exits
  process.sleep(200)
}
