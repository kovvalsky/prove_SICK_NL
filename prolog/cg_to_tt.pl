%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ========= CG terms to TT terms ==========
% Convert CG terms into simply typed lambda terms
% which are formatted as (term, type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- module('cg_to_tt',
    [
        sen_id_cg/2,
        sen_all_cg/0,
        cg_ids_to_latex/2
    ]).

:- use_module('../LangPro/prolog/printer/reporting', [
    test_true/3, report_error/2
    ]).
:- use_module('../LangPro/prolog/llf/ttterm_to_term', [
    write_pretty_ttTerm/3, ttTerm_to_pretty_ttTerm/2
    ]).
:- use_module('../LangPro/prolog/lambda/lambda_tt', [ norm_tt/2 ]).
:- use_module('tlg_to_latex', [ tt_to_latex/2 ]).
:- use_module('generic_utils', [
    filepath_write_source/2
    ]).
:- use_module('utils', [ add_feats_to_tlp/2 ]).
:- use_module('../LangPro/prolog/latex/latex_ttterm', [
    latex_ttTerm_preambule/1
    ]).
:- use_module('upos', [upos2penn/2]).
:- use_module('lassy', [lassy2tlp/2]).

:- op(605, xfy, ~>).     % more than : 600
:- op(605, yfx, @).       % more than : 600

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for debuging
:- dynamic debMode/1.
debMode(Arg) :-
    retractall( debMode(_) ),
    assertz( debMode(Arg) ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sen_all_cg :-
    findall(SID-TTterm,
        ( cg_term(SID, CG),
          cg_typed_to_ttTerm(CG, TTterm0),
          add_feats_to_tlp(TTterm0, TTterm)
        ), 
    _).

sen_id_cg(SID, TTterm) :-
    cg_term(SID, CG),
    cg_typed_to_ttTerm(CG, TTterm0),
    add_feats_to_tlp(TTterm0, TTterm).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cg_typed_to_ttTerm(X, X) :-
    var(X), !,
    report_error('Unexpected variable found: ~w\n', [X]),
    fail.

cg_typed_to_ttTerm((tlp(Tok,Lem,Pos,F1,F2), Cat), (tlp(Tok,Lem,Pos,F1,F2), Type)) :- !,
    cg_cat_to_type(Cat, Type),
    ( (var(Tok); var(Lem); var(Pos)) 
    ->  report_error('Unexpected variable found: tok=~w; lem=~w; pos=~w~n', [Tok, Lem, Pos]),
        (Tok, Lem, Pos) = ('TOK', 'LEM', 'POS')
    ; true
    ).

cg_typed_to_ttTerm((T1@T2, Cat), (TT1@TT2, Type)) :- !,
    cg_cat_to_type(Cat, Type),
    cg_typed_to_ttTerm(T1, TT1),
    cg_typed_to_ttTerm(T2, TT2).

cg_typed_to_ttTerm((Var, Cat), (Var, Type)) :- 
    var(Var), !,
    cg_cat_to_type(Cat, Type).

cg_typed_to_ttTerm((abst(V, T), Cat), (abst(VT, TT), Type)) :- 
    nonvar(V), V = (Var, _), var(Var), !,
    cg_typed_to_ttTerm(V, VT),
    cg_cat_to_type(Cat, Type),
    cg_typed_to_ttTerm(T, TT).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cg_cat_to_type(X, X) :-
    var(X), !, 
    report_error('Unexpected variable found: ~w\n', [X]).

cg_cat_to_type(lit(X), Type) :-
    !,
    ( X = np(Case,_F1,_F2) % Case can be var and F1,F2 can be non var, e.g., np(nom,il,3-s)
    -> Type = np:Case
    ; X == n 
    -> Type = n:_
    ; X = s(F), atom(F)
    -> Type = s:F
    ; X = s(inf(F)), atom(F)
    -> Type = s:Inf, atomic_list_concat([inf, F], '_', Inf)
    ; X = pp(F) % F can be rarely var 
    -> Type = pp:F
    ; (X == cl_r; X == cl_y; X == txt)
    -> Type = X
    ; writeln(lit(X))
    ).

cg_cat_to_type(DR_DL, Type1~>Type2) :-
    ( DR_DL = dr(0,Cat1,Cat2)
    ; DR_DL = dl(0,Cat1,Cat2) 
    ; DR_DL = dl(1,Cat1,Cat2)
    ), !,
    cg_cat_to_type(Cat1, Type1),
    cg_cat_to_type(Cat2, Type2).

cg_cat_to_type(X, X) :-
    writeln(X).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cg_ids_to_latex(IDs, FilePath) :-
    findall(TTterm,
        ( cg_term(SID, CG),
          memberchk(SID, IDs), 
          cg_typed_to_ttTerm(CG, TTterm0),
          add_feats_to_tlp(TTterm0, TTterm) 
        ), 
    TTterms),
    filepath_write_source(FilePath, S),
    latex_ttTerm_preambule(S),
    write(S, '\\begin{document}\n'),
    maplist(tt_to_latex(S), TTterms),
    write(S, '\\end{document}'),
    close(S).