-module(mu2_mutation).
-export([generate_mutants/4, random_mutation/2, all_mutations/0, generate_mutants/1, mutate/1]).

-include("../include/mutations.hrl").

all_mutations() ->
    mu2_exchange_mutations:all() ++ mu2_case_mutations:all() ++ mu2_if_mutations:all() ++ mu2_datatype_mutations:all() ++ mu2_receive_mutations:all().

%% This is for use on the command line via -s 
mutate([File, OutputFolder, CountString]) ->
    {Count, _Rem} = string:to_integer(atom_to_list(CountString)),
    io:format("Mutating ~p, generating ~p mutants in ~p~n", [File, Count, OutputFolder]),
    generate_mutants(atom_to_list(File), all_mutations(), Count, atom_to_list(OutputFolder)). 

generate_mutants(File, Mutations, Number, OutputFolder) ->
    wrangler_ast_server:start_ast_server(),
    case possible_mutations(File, Mutations) of
	[] ->
	    {error, "No possible mutations available for this file."};
	PosMuts ->
	    more_mutants(File, PosMuts, Number, OutputFolder)
    end.

generate_mutants([File, Mutations, Number, OutputFolder]) ->
    generate_mutants(File, Mutations, Number, OutputFolder).

apply_extras(AST, Loc) ->
    case mu2_extras_server:pop_first() of
	{error, no_mutations} -> 
	    AST;
	Mutation ->
	    {ok, NewAST} = erlang:apply(Mutation, [AST, Loc]),
	    apply_extras(NewAST, Loc)
	end.

random_mutation(File, PosMuts) ->
    Item = rand:uniform(length(PosMuts)),
    {{Name, _Match, Mutation}, Loc} = lists:nth(Item, PosMuts),
    {ok, AST} = api_refac:get_ast(File),
    io:format("Applying ~p at ~p...~n", [Name, Loc]),
    {ok, MidAST} = erlang:apply(Mutation, [AST, Loc]),
    NewAST = apply_extras(MidAST, Loc),
    {File, Name, Item, Loc, NewAST}.

%% Internal functions ----------------------------

more_mutants(_File, [], _Number, _OutputFolder) ->
    io:format("No more mutations possible.~n"),
    [];
%% Checks Number is exactly 0; this allows you to use -1 to generate ALL possible mutants
more_mutants(_File, _PosMuts, Number, _OutputFolder) when (Number == 0) ->
    [];
more_mutants(File, PosMuts, Number, OutputFolder) ->
    {File, Name, Item, Loc, ST} = random_mutation(File, PosMuts),
    MutantName = mu2_output:make_mutant_name(File, Name, Loc),
    mu2_output:write_mutant(OutputFolder, MutantName, ST),
    {Pre, Post} = lists:split(Item, PosMuts),
    OtherPosMuts = lists:sublist(Pre, Item-1) ++ Post,
    [{MutantName, Name, Loc} | more_mutants(File, OtherPosMuts, Number-1, OutputFolder)].

possible_mutations(File, Ms) ->
    possible_mutations(File, Ms, []).

possible_mutations(_File, [], Res) ->
    lists:flatten(Res);
possible_mutations(File, [{Name, Match, Mutation} | Ms], Res) ->
    io:format("Checking applicability of ~p, ~p more to try...~n", [Name, length(Ms)]),
    NewRes = [lists:map(fun({_File, Loc}) -> {{Name, Match, Mutation}, Loc} end, erlang:apply(Match, [File])) | Res],
    possible_mutations(File, Ms, NewRes).

