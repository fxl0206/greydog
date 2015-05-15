-module(rmq_customer).
-include_lib("amqp_client/include/amqp_client.hrl").
-export([main/0]).
-export([save_db/3]).
-record(meta,{fuser,tuser,msgtype,data}).

main() ->
    {ok, Connection} =
        amqp_connection:start(#amqp_params_network{username = <<"admin">>,password = <<"admin">>,host = "123.56.90.92"}),
    {ok, Channel} = amqp_connection:open_channel(Connection),

    amqp_channel:call(Channel, #'queue.declare'{queue = <<"wx_msg">>,durable = true}),
    io:format(" [*] Waiting for messages. To exit press CTRL+C~n"),
    amqp_channel:call(Channel, #'basic.qos'{prefetch_count = 1}),
    amqp_channel:subscribe(Channel, #'basic.consume'{queue = <<"wx_msg">>,
                                                     no_ack = false}, self()),
    receive
        #'basic.consume_ok'{} -> ok
    end,
    loop(Channel).


loop(Channel) ->
    receive
        {#'basic.deliver'{delivery_tag = Tag}, #amqp_msg{payload = Body}} ->
	spawn(?MODULE,save_db,[Body,Channel,Tag]), 
	io:format(" [x] Received ~p~n", [Body]),
            loop(Channel)
    end.
save_db(Body,Channel,Tag)->
        amqp_channel:call(Channel,#'basic.ack'{delivery_tag = Tag}),
	    #meta{fuser = FromUserName, tuser = ToUserName, msgtype = MsgType, data = Data}=xml_parse(binary_to_list(Body)),
        case MsgType of
            "text" ->
               [Content|[]] = Data;
            "event" ->
                [Event|[EventKey|[]]] = Data,
                Content=Event++"#"++EventKey;
            _ ->
               Content = "无法识别的消息类型!" 
        end,
        Sql="insert into ts_wx_msg(msgid,type,content,fuser,tuser,create_time) values('1','text','"++Content++"','"++FromUserName++"','"++ToUserName++"',now())",
        mysql:fetch(conn,unicode:characters_to_binary(Sql)),
        io:format("~n=========delivery_tag is : ~p=============~n",[Tag]),
	ok.
%weixin xml parse
xml_parse(Xml)->
        {Doc, _} =xmerl_scan:string(Xml),
       [{_,_,_,_,FromUserName,_}]=xmerl_xpath:string("/xml/ToUserName/text()", Doc),
       [{_,_,_,_,MsgType,_}]=xmerl_xpath:string("/xml/MsgType/text()", Doc),
       [{_,_,_,_,ToUserName,_}]=xmerl_xpath:string("/xml/FromUserName/text()", Doc),
        case MsgType of
            "text" ->
                [{_,_,_,_,Content,_}]=xmerl_xpath:string("/xml/Content/text()", Doc),
                Data=[Content];
            "event" ->
                [{_,_,_,_,Event,_}]=xmerl_xpath:string("/xml/Event/text()", Doc),
                [{_,_,_,_,EventKey,_}]=xmerl_xpath:string("/xml/EventKey/text()", Doc),
                Data=[Event,EventKey];
            _ ->
                Data =[]
        end,
        #meta{fuser = FromUserName, tuser = ToUserName, msgtype = MsgType, data = Data}.
