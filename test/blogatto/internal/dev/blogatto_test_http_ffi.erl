-module(blogatto_test_http_ffi).
-export([http_get/1]).

http_get(Url) ->
    ensure_inets(),
    case httpc:request(get, {binary_to_list(Url), []},
                       [{timeout, 5000}],
                       [{body_format, binary}]) of
        {ok, {{_, StatusCode, _}, Headers, Body}} ->
            ContentType = case lists:keyfind("content-type", 1, Headers) of
                {_, CT} -> list_to_binary(CT);
                false   -> <<>>
            end,
            {ok, {StatusCode, ContentType, Body}};
        {error, Reason} ->
            {error, list_to_binary(io_lib:format("~p", [Reason]))}
    end.

ensure_inets() ->
    case inets:start() of
        ok                              -> ok;
        {error, {already_started, _}}   -> ok
    end.
