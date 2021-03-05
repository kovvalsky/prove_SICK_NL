%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task Specific Utility Predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module('utils',
    [
        add_feats_to_tlp/2,
        translate_nl2en/2
    ]).

%---------------------------------------------------
% Add two dummy features to lexical leaves
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

add_feats_to_tlp((abst(VarTT,T), Ty), (abst(VarTT,TF), Ty)) :- !,
    add_feats_to_tlp(T, TF).

add_feats_to_tlp(AtomTT, AtomTT) :-
    AtomTT =.. [_, Atom, _],
    ( atom(Atom); integer(Atom) ), !.
%----------------------------------------------------

%---------------------------------------------------
% Translate only closed class and semantically heavy words
% like no, every, not, the, a,  etc.
translate_nl2en(X, X) :-  % catching unexpacted vars
    var(X), !,
    format('Untyped variable in translate_nl2en/2'), fail.

translate_nl2en((X,Ty), (X,Ty)) :-
    var(X), !.

translate_nl2en((NL1 @ NL2, Ty), (EN1 @ EN2, Ty)) :- !,
    translate_nl2en(NL1, EN1),
    translate_nl2en(NL2, EN2).

translate_nl2en((abst(X, NL), Ty), (abst(X, EN), Ty)) :- !,
    translate_nl2en(NL, EN).

translate_nl2en((tlp(T,NL,P), Ty), (tlp(T,EN,P), Ty)) :- !,
    ( NL == 'niet' -> EN = 'not'
    ; NL == 'geen' -> EN = 'no'
    ; memberchk(NL, ['het','de']) -> EN = 'the'
    ; memberchk(NL, ['een','één']) -> EN = 'a'
    ; NL == 'en' -> EN = 'and'
    ; memberchk(NL, ['is','zijn']), Ty = np:_~>s:_ -> EN = 'be' % pos=RB?
    ; NL == 'er' -> EN = 'there'
    ; NL == 'die', Ty = (np:_~>s:_)~>N~>N -> EN = 'who'
    ; NL == 'door', Ty = np:_~>(np:_~>s:_)~>(np:_~>s:_) -> EN = 'by'
    ; NL == 'iemand', Ty = np:_ -> EN = 'somebody'
    ; NL == 'niemand', Ty = np:_ -> EN = 'nobody'
    ; NL == 'iets', Ty = np:_ -> EN = 'something'
    ; NL == 'niets', Ty = np:_ -> EN = 'nothing'
    ; NL == 'worden', P == 'RB', Ty = (np:_~>s:pt)~>np:_~>s:_ -> EN = 'be'
    % ; NL == 'doen', Ty = np:_~>np:_~>s:_ -> EN = 'do'%!!! plaatsen<doen sicknl-3250
    ; memberchk(NL, ['is','aan_het']),
      memberchk(P, ['RB','AUX']),
      Ty = (np:_~>s:_)~>np:_~>s:_ -> EN = 'be'
    ; NL = EN ).




%----------------------------------------------------
