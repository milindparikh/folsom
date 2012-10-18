%%%
%%% Copyright 2011, Boundary
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%


%%%-------------------------------------------------------------------
%%% File:      folsom_metrics_counter.erl
%%% @author    joe williams <j@boundary.com>
%%% @doc
%%% @end
%%%-----------------------------------------------------------------

-module(folsom_metrics_counter).

-export([new/1,
         inc/1,
         inc/2,
         dec/1,
         dec/2,
         get_value/1,
         clear/1]).

-define(WIDTH, 16). %% Keep this a power of two

-include("folsom.hrl").

new(Name) ->
    Counters = [{{Name,N}, 0} || N <- lists:seq(0,?WIDTH-1)],
    ets:insert(?COUNTER_TABLE, Counters).

inc(Name) ->
    inc(Name, 1).

inc(Name, Value) when is_integer(Value) ->
    ets:update_counter(?COUNTER_TABLE, key(Name), Value);
inc(Name, Value) when is_float(Value) ->
    inc_float_racy_but_good_enough(key(Name), Value).

dec(Name) ->
    dec(Name, -1).

dec(Name, Value) when is_integer(Value) ->
    ets:update_counter(?COUNTER_TABLE, key(Name), -Value);
dec(Name, Value) when is_float(Value) ->
    inc_float_racy_but_good_enough(key(Name), -1.0 * Value).

inc_float_racy_but_good_enough(Name, Value) ->
    Old = case ets:lookup(?COUNTER_TABLE, Name) of
              [{_, Val}] -> Val;
              []         -> 0.0
          end,
    true = ets:insert(?COUNTER_TABLE, {Name, Old + Value}).

get_value(Name) ->
    Count = lists:sum(ets:select(?COUNTER_TABLE, [{{{Name,'_'},'$1'},[],['$1']}])),
    Count.

clear(Name) ->
    new(Name).

key(Name) ->
    X = erlang:system_info(scheduler_id),
    Rnd = X band (?WIDTH-1),
    {Name, Rnd}.
