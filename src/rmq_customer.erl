-module(rmq_customer).
-include_lib("amqp_client/include/amqp_client.hrl").
-export([main/0]).
-export([save_db/3]).
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
	{FromUserName,ToUserName,Content}=xml_parse(binary_to_list(Body)),
        Sql="insert into ts_wx_msg(msgid,type,content,fuser,tuser,create_time) values('1','text','"++Content++"','"++FromUserName++"','"++ToUserName++"',now())",
        mysql:fetch(conn,unicode:characters_to_binary(Sql)),
        amqp_channel:call(Channel,#'basic.ack'{delivery_tag = Tag}),
	ok.
%weixin xml parse
xml_parse(Xml)->
        %io:format("~p ~n ", [code:get_path()]),
        {Doc, _} =xmerl_scan:string(Xml),
        %[{xmlText,[{'Content',10},{xml,1}],
    %      1,[],"this is a test",cdata}]
        [{_,_,_,_,Content,_}]=xmerl_xpath:string("/xml/Content/text()", Doc),
        [{_,_,_,_,FromUserName,_}]=xmerl_xpath:string("/xml/ToUserName/text()", Doc),
        [{_,_,_,_,ToUserName,_}]=xmerl_xpath:string("/xml/FromUserName/text()", Doc),
        {FromUserName,ToUserName,Content}.
