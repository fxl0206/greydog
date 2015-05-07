-module(wx_center_worker).
-behaviour(gen_server).
-export([
    start_link/0,
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
    ]).

-define(TIME,5000).
-define(TOKEN,"lWpmoIilmtlWm").
-define(AESKEY,"XSODyEIWuOYwUImf9E874THanu4Zy1245sX13XXGYxG=").

-type monitors() :: [{{reference(), pid()}, any()}].
-record(state, {
    monitors = [] :: monitors()
}). 
 
%start_link
start_link() ->
    gen_server:start_link({local,?MODULE},?MODULE,[],[]).

%Http请求
% Option = {proxy, {Proxy, NoProxy}} | 
% {https_proxy, {Proxy, NoProxy}} | 
% {max_sessions, MaxSessions} | 
% {max_keep_alive_length, MaxKeepAlive} |
% {keep_alive_timeout, KeepAliveTimeout} | 
% {max_pipeline_length, MaxPipeline} | 
% {pipeline_timeout, PipelineTimeout} | 
% {cookies, CookieMode} | 
% {ipfamily, IpFamily} | 
% {ip, IpAddress} | 
% {port, Port} | 
% {socket_opts, socket_opts()} | 
% {verbose, VerboseMode} 
% Profile = profile()
%同步请求
%{ok, {{Version, 200, ReasonPhrase}, Headers, Body}} = httpc:request(get, {"http://www.baidu.com", []}, [], []).

%异步请求
%{ok, RequestId} = httpc:request(get, {"http://www.baidu.com", []}, [], [{sync, false}]),
%receive {http, {RequestId, Result}} -> ok after 500 -> error end.
%init pool 
init([]) ->
     io:format("####################################"),
    erlang:send_after(?TIME,self(),loop_interval_event),
    {ok,state}.

%hander_call
handle_call(code,_From,State) ->
    {reply,data,State}.

%hander_cast
handle_cast(code,State) ->
    {noreply,State}.

%hander_info
handle_info(code,State) ->
    {noreply,State};

handle_info(loop_interval_event, State) ->
     {{Year,Month,Day},{Hour,Min,Second}}=calendar:local_time(),
     case {Hour,Min}  of 
        {11,22} ->
           io:format("#3###################################");
        _ ->
           io:format("timeout messages !~n")
        end,

    erlang:send_after(?TIME,self(),loop_interval_event),
    Body="<xml><ToUserName><![CDATA[wxc02de619d60b35f4]]></ToUserName>
<Encrypt><![CDATA[9HFaOmfdNRqx5+L7AWtVCKrl9Kmo3rPmA2kUp2seAEHBNC/EzQV9nI/hWa/7Ybt4rDOXzSo1wxYDJy7kYTsFFIdnvzv2Jz8HtBccqFGsruYr98l9B4cenkJrXwWFB0Oh/sqz6m21yVwH8W2SnuOfV4K+GdTdDhiqPxHWFS2S/JjfyMkRpjwZ5100YOXe1N8/phgg1AKK7lneF1zfMwXmclQdstXsZ1zyrfHl69oD8OU07txkTVGjtV0gDB0liM0JFywqsdZ+R0pHc9lMOOJTxuRupZOTs7ymIVRFt/v9g1Ro4fCxMNQ4oV2/tBa6KCeiDiL2xJ30XhGXn1XtRgad4WszhgR++jwrHYU8MUhjiisJEkDTsB3oPUZ3C8WL1z3T7u8iGBbRoHmHvRAX1dbJ6IJlKNUrdSpWAQje2lO3IOw=]]></Encrypt>
<AgentID><![CDATA[0]]></AgentID>
</xml>",
    {ok, {{Version, 200, ReasonPhrase}, Headers, Bodys}} = httpc:request(post, {"http://123.56.90.92/qy?msg_signature=7a523c5a28f7197bb44b10529ae24fb64eb8576e&timestamp=1430801386&nonce=1326063369", [],"text/xml",Body}, [], []),
     io:format("~p ",[Headers]),
     io:format("~p ",[Bodys]),
     {FromUserName,AgentID,Encrypt}=wx_tool:msg_package_parse(Bodys),

    Token=?TOKEN,
    Aeskey=base64:decode(?AESKEY),
    KeyList=binary_to_list(Aeskey),
    % io:format("~n22222~n~p~n~n",[KeyList]),
    IvList=lists:sublist(KeyList,1,16),
    Iv=list_to_binary(IvList),
    EchostrAesData=base64:decode_to_string(Encrypt),
    Str=crypto:aes_cbc_128_decrypt(Aeskey,Iv,list_to_binary(EchostrAesData)),
    io:format("~n~n~ts~n~n",[Str]),

    Strlist=binary_to_list(Str),
    <<C:32>>=list_to_binary(lists:sublist(Strlist,17,4)),
    io:format("~n~n~p~n~n",[lists:sublist(Strlist,17,4)]),
    io:format("~p~n",[C]),
    Bodya=lists:sublist(Strlist,21, C),
    {FromUserNames,ToUserName,Content}=wx_tool:msg_body_parse(Bodya),
    io:format("~n~n~ts~n~n",[Bodya]),

    {noreply, State}.
%terminate
terminate(_Reason, _State) ->
    ok.

%code_change
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
