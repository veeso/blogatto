//// Shell command execution for the dev server.

/// Execute a shell command and return its exit code and output.
@external(erlang, "blogatto_dev_ffi", "exec_command")
pub fn exec(command: String) -> #(Int, String)
