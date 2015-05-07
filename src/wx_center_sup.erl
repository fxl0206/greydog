-module(wx_center_sup).
-behaviour(supervisor).
-export([start_link/0,init/1]).
%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    io:format("####################################"),
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
     Procs = [{wx_center_worker, {wx_center_worker, start_link, []},permanent, brutal_kill, worker, [wx_center_worker]}],
        %Procs=[],
        {ok, {{one_for_one, 10, 10}, Procs}}.
