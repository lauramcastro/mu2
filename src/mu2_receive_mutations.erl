-module(mu2_receive_mutations).

-export([all/0, receive_mutations/0]).
-import(mu2_case_mutations,[swap/3,random_not_n/2]).
-include("../include/mutations.hrl").


all() ->
    receive_mutations().

receive_mutations() ->
    [{swap_receive_order,
      ?MUTATION_RESTRICT("receive Pats@@@ when Guards@@@ -> Body@@@ end",
			 length(Pats@@@) > 1),
      ?MUTATION("receive Pats@@@ when Guards@@@ -> Body@@@ end",
		begin
		    A = rand:uniform(length(Pats@@@)),
		    B = random_not_n(length(Pats@@@), A),
		    NewPats@@@ = swap(Pats@@@, A, B),
		    NewGuards@@@ = swap(Guards@@@, A, B),
		    NewBody@@@ = swap(Body@@@, A, B),
		    ?TO_AST("receive NewPats@@@ when NewGuards@@@ -> NewBody@@@ end")
		end)},
     {exchange_receive_guard,
      ?MUTATION_RESTRICT("receive Pats@@@ when Guards@@@ -> Body@@@ end",
			 length(Pats@@@) > 1),
      ?MUTATION("receive Pats@@@ when Guards@@@ -> Body@@@ end",
    		begin
    		    A = rand:uniform(length(Pats@@@)),
    		    B = random_not_n(length(Pats@@@), A),
    		    NewGuards@@@ = swap(Guards@@@, A, B),
    		    ?TO_AST("receive Pats@@@ when NewGuards@@@ -> Body@@@ end")
    		end)},
     {exchange_receive_pattern,
      ?MUTATION_RESTRICT("receive Pats@@@ when Guards@@@ -> Body@@@ end",
			 length(Pats@@@) > 1),
      ?MUTATION("receive Pats@@@ when Guards@@@ -> Body@@@ end",
    		begin
    		    A = rand:uniform(length(Pats@@@)),
    		    B = random_not_n(length(Pats@@@), A),
    		    NewPats@@@ = swap(Pats@@@, A, B),
    		    ?TO_AST("receive NewPats@@@ when Guards@@@ -> Body@@@ end")
    		end)},
     {remove_last_receive_case,
      ?MUTATION_RESTRICT("receive Pats@@@ when Guards@@@ -> Body@@@ end",
			 length(Pats@@@) > 1),
      ?MUTATION("receive Pats@@@ when Guards@@@ -> Body@@@ end",
    		begin
    		    NewPats@@@ = lists:sublist(Pats@@@, length(Pats@@@) -1),
    		    NewGuards@@@ = lists:sublist(Guards@@@, length(Pats@@@) -1),
    		    NewBody@@@ = lists:sublist(Body@@@, length(Pats@@@) -1),
		    ?TO_AST("receive NewPats@@@ when NewGuards@@@ -> NewBody@@@ end")
    		end)}
    ,{increase_timeout,
      ?MUTATION_MATCH("receive Pats@@@ when Guards@@@ -> Body@@@ after APats@@@ -> ABody@@@ end"),
      ?MUTATION("receive Pats@@@ when Guards@@@ -> Body@@@ after APats@@ -> ABody@@ end",
    		begin
		    NewAPats@@ = lists:map(fun(Pat@) -> 
		    				    ?TO_AST("(Pat@ + 10000)")  
		    			    end,
		    			    APats@@),
		    ?TO_AST("receive Pats@@@ when Guards@@@ -> Body@@@ after NewAPats@@ -> ABody@@ end")
    		end)}
    ,{decrease_timeout,
      ?MUTATION_MATCH("receive Pats@@@ when Guards@@@ -> Body@@@ after APats@@@ -> ABody@@@ end"),
      ?MUTATION("receive Pats@@@ when Guards@@@ -> Body@@@ after APats@@ -> ABody@@ end",
    		begin
		    NewAPats@@ = lists:map(fun(Pat@) -> 
		    				    ?TO_AST("(Pat@ / 100)")  
		    			    end,
		    			    APats@@),
		    ?TO_AST("receive Pats@@@ when Guards@@@ -> Body@@@ after NewAPats@@ -> ABody@@ end")
    		end)}
    ].

