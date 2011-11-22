-module(zmq_socket_rep).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("zmq_internal.hrl").

-export([init/1, close/4, idle/4, pending/4, processing/4]).

-record(state, {
		  last_recv = none  :: pid()|'none'
}).

%%%===================================================================
%%% API
%%%===================================================================

%%%===================================================================
%%% zmq_socket callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the Fsm
%%
%% @spec init(Args) -> {ok, StateName, State} |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------

init(_Opts) ->
	{ok, idle, #state{}}.

close(_StateName, _Transport, MqSState, State) ->
	State1 = State#state{last_recv = none},
	{next_state, idle, MqSState, State1}.

idle(check, recv, _MqSState, _State) ->
	ok;
idle(check, {deliver_recv, _Transport}, _MqSState, _State) ->
	ok;
idle(check, deliver, _MqSState, _State) ->
	ok;
idle(check, _, _MqSState, _State) ->
	{error, fsm};

idle(do, {queue, _Transport}, MqSState, State) ->
	{next_state, pending, MqSState, State};
idle(do, {deliver, Transport}, MqSState, State) ->
	State1 = State#state{last_recv = Transport},
	{next_state, processing, MqSState, State1};
idle(do, _, _MqSState, _State) ->
	{error, fsm}.

pending(check, {deliver_recv, _Transport}, _MqSState, _State) ->
	ok;
pending(check, recv, _MqSState, _State) ->
	ok;
pending(check, deliver, _MqSState, _State) ->
	ok;
pending(check, _, _MqSState, _State) ->
	{error, fsm};

pending(do, {queue, _Transport}, MqSState, State) ->
	{next_state, pending, MqSState, State};
pending(do, {dequeue, _Transport}, MqSState, State) ->
	{next_state, pending, MqSState, State};
pending(do, {deliver, Transport}, MqSState, State) ->
	State1 = State#state{last_recv = Transport},
	{next_state, processing, MqSState, State1};
pending(do, _, _MqSState, _State) ->
	{error, fsm}.

processing(check, send, _MqSState, #state{last_recv = Transport}) ->
	{ok, Transport};
processing(check, _, _MqSState, _State) ->
	{error, fsm};

processing(do, {deliver_send, _Transport}, MqSState, State) ->
	State1 = State#state{last_recv = none},
	{next_state, idle, MqSState, State1};

processing(do, _, _MqSState, _State) ->
	{error, fsm}.
