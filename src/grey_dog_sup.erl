-module(grey_dog_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
	 Procs = [
     {mysql, {mysql, start_link, [conn,"127.0.0.1",3306,"root","286955","greybird",undefined,utf8]},permanent, brutal_kill, worker, [mysql]},
     {mq_sup, {mq_sup, start_link, []},permanent, brutal_kill, supervisor, [mq_sup]}
     % {wx_center_sup, {wx_center_sup, start_link, []},permanent, brutal_kill, supervisor, [wx_center_sup]}
     ],
        %Procs=[],
        {ok, {{one_for_one, 10, 10}, Procs}}.
