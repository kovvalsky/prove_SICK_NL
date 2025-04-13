%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task Specific Utility Predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module('utils',
    [
        add_feats_to_tlp/2,
        tlp_lemma_in_list/2,
        merge_tlps/3
    ]).

:- use_module('generic_utils', [ merge_two_lists/4 ]).

%---------------------------------------------------
% Add two dummy features to lexical leaves if they don't have them
add_feats_to_tlp(Var, Var) :-
	var(Var), !,
	format('Untyped variable in add_feats_to_tlp/2'), fail.

add_feats_to_tlp(VarTT, VarTT) :-
    VarTT =.. [_, Var, _],
    var(Var), !.

add_feats_to_tlp((T1 @ T2, Ty), (TF1 @ TF2, Ty)) :- !,
    add_feats_to_tlp(T1, TF1),
    add_feats_to_tlp(T2, TF2).

add_feats_to_tlp((tlp(T,L,P), Ty), (tlp(T,L,P,'O','O'), Ty)) :- !.

add_feats_to_tlp((tlp(T,L,P,F1,F2), Ty), (tlp(T,L,P,F1,F2), Ty)) :- !,
    ( var(F1) -> F1 = 'O'; true ),
    ( var(F2) -> F2 = 'O'; true ).

add_feats_to_tlp((abst(VarTT,T), Ty), (abst(VarTT,TF), Ty)) :- !,
    add_feats_to_tlp(T, TF).

add_feats_to_tlp(AtomTT, AtomTT) :-
    AtomTT =.. [_, Atom, _],
    ( atom(Atom); integer(Atom) ), !.
%----------------------------------------------------



%----------------------------------------------------
tlp_lemma_in_list(TLP, List) :-
	nonvar(TLP),
	TLP = tlp(_,Lemma,_),
	memberchk(Lemma, List).

%----------------------------------------------------
merge_tlps(_, [TLP], TLP) :- !.

merge_tlps(Delim, [TLP1,TLP2|Rest], TLP) :-
    nonvar(TLP1), nonvar(TLP2),
    TLP1 =.. L1, TLP2 =.. L2,
    merge_two_lists(Delim, L1, L2, L),
    TLP12 =.. L,
    merge_tlps(Delim, [TLP12|Rest], TLP).


%----------------------------------------------------
