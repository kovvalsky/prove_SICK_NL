%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Task Specific Utility Predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module('utils',
    [
        add_feats_to_tlp/2,
        translate_nl2en/2
    ]).

:- use_module('generic_utils', [ merge_two_lists/4 ]).

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

translate_nl2en(NL, EN) :-
    translate_mwe_nl2en(NL, EN), !.

translate_nl2en((NL1 @ NL2, Ty), (EN1 @ EN2, Ty)) :- !,
    translate_nl2en(NL1, EN1),
    translate_nl2en(NL2, EN2).

translate_nl2en((abst(X, NL), Ty), (abst(X, EN), Ty)) :- !,
    translate_nl2en(NL, EN).

translate_nl2en((tlp(T,NL,P), Ty), (tlp(T,EN,P), Ty)) :- !,
    ( NL == 'niet' -> EN = 'not'
    ; memberchk(NL, ['geen','geen_enkel']) -> EN = 'no'
    ; memberchk(NL, ['het','de']) -> EN = 'the'
    ; memberchk(NL, ['een','één','eén']) -> EN = 'a'
    ; memberchk(NL, ['wat','sommig']), Ty = n:_~>np:_ -> EN = 'some'
    ; NL == 'en' -> EN = 'and'
    ; NL == 'er' -> EN = 'there'
    ; memberchk(NL, ['deze','die','dit','dat']),
      Ty = (np:_~>s:_)~>N~>N -> EN = 'who'
    ; NL == 'door', Ty = np:_~>(np:_~>s:_)~>(np:_~>s:_) -> EN = 'by'
    % ; NL == 'iemand', Ty = np:_ -> EN = 'somebody'
    % ; NL == 'niemand', Ty = np:_ -> EN = 'nobody'
    % ; NL == 'iets', Ty = np:_ -> EN = 'something'
    % ; NL == 'niets', Ty = np:_ -> EN = 'nothing'
    ; NL == 'worden', P == 'RB',
      Ty = (np:_~>s:pt)~>N:_~>s:_, memberchk(N, ['n','np']) -> EN = 'be'
    % ; NL == 'doen', Ty = np:_~>np:_~>s:_ -> EN = 'do'%!!! plaatsen<doen sicknl-3250
    ; memberchk(NL, ['zijn','is','aan_het']), memberchk(P, ['RB','AUX']),
      Ty = (np:_~>s:_)~>np:_~>s:_ -> EN = 'be'
    ; memberchk(NL, ['is','zijn']), Ty = np:_~>s:_ -> EN = 'be' % pos=RB?
    ; NL = EN ).




%----------------------------------------------------

translate_mwe_nl2en(
    ( (Enn,n:_~>D) @ (Paar,n:_), D ),
    ( tlp(Enn_Paar,'a_few','DT'), D )
) :-
    tlp_lemma_in_list(Enn, ['een','één','eén']),
    tlp_lemma_in_list(Paar, ['paar']),
    merge_tlps('_', [Enn,Paar], tlp(Enn_Paar,_,_POS)). %!!! POS can be compound


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
