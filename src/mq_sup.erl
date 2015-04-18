-module(mq_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).
start_link() ->    
	supervisor:start_link(mq_sup, []).
init(_Args) ->  
	Procs = [{rmq_customer, {rmq_customer, main, []},permanent, brutal_kill, worker, [rmq_customer]}],
        {ok, {{one_for_one, 10, 10}, Procs}}. 
