import blogatto/internal/dev/command
import gleeunit/should

pub fn exec_successful_command_test() {
  let #(exit_code, output) = command.exec("echo hello")
  exit_code |> should.equal(0)
  output |> should.equal("hello\n")
}

pub fn exec_failed_command_test() {
  let #(exit_code, _output) = command.exec("false")
  exit_code |> should.equal(1)
}

pub fn exec_captures_stdout_test() {
  let #(exit_code, output) = command.exec("printf abc")
  exit_code |> should.equal(0)
  output |> should.equal("abc")
}

pub fn exec_captures_stderr_test() {
  // stderr is redirected to stdout by the FFI
  let #(_exit_code, output) = command.exec("echo err >&2")
  output |> should.equal("err\n")
}

pub fn exec_returns_nonzero_exit_code_test() {
  let #(exit_code, _output) = command.exec("exit 42")
  exit_code |> should.equal(42)
}
