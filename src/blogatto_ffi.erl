-module(blogatto_ffi).
-export([get_tz_database/0]).

get_tz_database() ->
    try persistent_term:get(blogatto_tz_database)
    catch
        error:badarg ->
            Db = zones:database(),
            persistent_term:put(blogatto_tz_database, Db),
            Db
    end.
