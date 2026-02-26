-module(blogatto_dev_ffi).
-export([exec_command/1]).

-define(BUILD_TIMEOUT_MS, 120000).

exec_command(Command) ->
    Sh = os:find_executable("sh"),
    Port = open_port(
        {spawn_executable, Sh},
        [{args, ["-c", binary_to_list(Command)]},
         exit_status, stderr_to_stdout, binary]
    ),
    collect_output(Port, <<>>).

collect_output(Port, Acc) ->
    receive
        {Port, {data, Data}} ->
            collect_output(Port, <<Acc/binary, Data/binary>>);
        {Port, {exit_status, Status}} ->
            {Status, Acc}
    after ?BUILD_TIMEOUT_MS ->
        port_close(Port),
        {124, <<"Build timed out after 120 seconds\n">>}
    end.
