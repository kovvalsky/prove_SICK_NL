%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ========= Generic utility predicates ==========
% The predicates require only standard libraries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- module('generic_utils',
    [
        atom_split/4,
        dict_length/2,
        enumerate_list/2,
        filepath_write_source/2,
        indexed_dict_to_list/2,
        list_to_set_using_match/2,
        num_list/2,
        value_merge_dicts/3
    ]).

% :- use_module(library(http/json)).
:- use_module(library(dicts)).
:- use_module(library(clpfd)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Given a list, enumerate its elements starting with 0
enumerate_list(List, Enum) :-
    findall(I-E, nth0(I, List, E), Enum).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% takes list and returns set, where matching is considered as euqlity
% keep the first occurences and remove the repetitive occurences
list_to_set_using_match(List, Set) :-
	list_to_set_using_match_r(List, Reverse),
	reverse(Reverse, Set).

list_to_set_using_match_r([], []) :- !.

list_to_set_using_match_r(List, Set) :-
	append(Front, [H], List), !,
	( \+memberchk(H, Front) ->
		Set = [H | Rest],
		list_to_set_using_match_r(Front, Rest)
	; list_to_set_using_match_r(Front, Set)
	).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merge annotations recursively



indexed_dict_to_list(IndDict, List) :-
    dict_keys(IndDict, Keys),
    maplist(atom_number, Keys, NumKeys),
    sort(NumKeys, Indices),
    findall(D, (
        member(I, Indices),
        atom_number(A, I),
        D = IndDict.A
    ), List).

dict_length(D, N) :-
    dict_keys(D, Keys),
    length(Keys, N).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
atom_split(Atom, N, Part1, Part2) :-
    N >= 0,
    atom_concat(Part1, Part2, Atom),
    atom_length(Part1, N).

atom_split(Atom, N, Part1, Part2) :-
    N < 0,
    atom_length(Atom, L),
    Part1_Len is L + N,
    atom_concat(Part1, Part2, Atom),
    atom_length(Part1, Part1_Len).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO accommodate empty Dicts list or Dicts with empty keys
value_merge_dicts(Delim, Dicts, Merge) :-
    maplist(dict_keys, Dicts, L_Keys),
    homogeneous_list(L_Keys), % all dictionaries have same keys
    maplist(dict_pairs, Dicts, Tags, L_Pairs),
    homogeneous_list(Tags),
    maplist(pairs_values, L_Pairs, L_Values),
    transpose(L_Values, L_KeyVals),
    maplist({Delim}/[KeyVals, Merged]>>atomic_list_concat(KeyVals, Delim, Merged),
        L_KeyVals, MergedVals),
    L_Keys = [Keys|_],
    Tags = [Tag|_],
    pairs_keys_values(Pairs, Keys, MergedVals),
    dict_pairs(Merge, Tag, Pairs).


homogeneous_list([]) :- !.

homogeneous_list([E|List]) :-
    maplist(=(E), List).


% list, singleton and interval of integers to list
num_list(Var, Var) :-
    var(Var), !.

num_list(List, List) :-
    is_list(List), !.

num_list(Num, [Num]) :-
    integer(Num), !.

num_list(Interval, List) :-
    Interval =.. [_, Low, High],
    integer(Low), integer(High),
    findall(L, between(Low, High, L), List).


% create a source for a given filepath
filepath_write_source(FilePath, S) :-
    file_directory_name(FilePath, Dir),
    ( exists_directory(Dir) -> true; make_directory(Dir) ),
    open(FilePath, write, S, [encoding(utf8), close_on_abort(true)]).
