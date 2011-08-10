%%% This module is a variant of ux_uca_sort_key_binary 
%%% for case sensative collation.
-module(ux_uca_sort_key_binary_cs).
-export([sort_key/2]).
-import(ux_uca, [sort_array/2]).

-include("ux.hrl").
-include("ux_uca.hrl").
-include("ux_uca_common.hrl").

sort_key(C=#uca_options{strength=MaxLvl}, S) ->
    W = sort_array(C, S),
    D = get_ducet(),
    A = ux_uca_alt:get_alternate_function(C, D),
    R = [], % Remains
    K = [], % Key
    do_sort_key1(MaxLvl, W, D, A, R, K).

%% @param S::integer()  Strength (Max level)
%% @param W::[binary()] Weights
%% @param D::fun()      Ducet
%% @param A::fun()      Altername
%% @param R::[[int()]]  Remain weights
%% @param K::[int()]    Result key
do_sort_key1(S, [WH|WT], D, A, R, K) ->
    {NewA, [L1|Rem]} = do_alt(A, WH),
    do_sort_key1(S, WT, D, NewA, [Rem|R], [L1|K]);
do_sort_key1(S, [], D, A, R, K) 
    when (S > 1) ->
    W = lists:reverse(R),
    L = 2, % Level
    WL = [],
    NewK = [0|K],
    RevK = lists:reverse(NewK),
    Fn = get_reassign_function(D, 3),
    BinK = Fn({to_binary, RevK}),
    do_sort_key2(S, L, W, D, BinK);
do_sort_key1(S, [], D, A, R, K) ->
    Fn = get_reassign_function(D, 3),
    RevK = lists:reverse(K),
    Fn({to_binary, RevK}). % Return result

%% L::int() Level
%% WL::[int()] Weigth on level L
do_sort_key2(S, L, W, D, K) ->
    {LvlW, RemW} = split_levels(W),
    % Get a reassign function.
    RaFn = get_reassign_function(D, L),
    ReassignW = RaFn(LvlW),
    % We swap values on L1 and L3.
    % So, now we use to_binary for L1 on L3, and v.v.
    BinFn = get_reassign_function(D, case L of 3 -> 1; _ -> L end),
    case RemW of
    _ when RemW=:=[]; S=<L -> 
        RevW = lists:reverse(ReassignW),
        BinW = BinFn({to_binary, RevW}),
        <<K/binary, BinW/binary>>;

    [_|_] -> 
        % Add a delimeter.
        NewW = [0|ReassignW],
        RevW = lists:reverse(NewW),
        BinW = BinFn({to_binary, RevW}),
        NewK = <<K/binary, BinW/binary>>,

        do_sort_key2(S, L+1, RemW, D, NewK)
    end.
