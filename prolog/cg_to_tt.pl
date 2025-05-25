%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ========= CG terms to TT terms ==========
% Convert CG terms into simply typed lambda terms
% which are formatted as (term, type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- module('cg_to_tt',
    [
        sen_id_cg/2,
        sen_all_cg/0,
        cg_typed_to_ttTerm/2
    ]).

:- use_module('../LangPro/prolog/printer/reporting', [
    test_true/3, report_error/2
    ]).
:- use_module('../LangPro/prolog/llf/ttterm_to_term', [
    write_pretty_ttTerm/3, ttTerm_to_pretty_ttTerm/2
    ]).
:- use_module('../LangPro/prolog/lambda/lambda_tt', [ norm_tt/2 ]).

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

sen_id_cg(SID, NormTT) :-
    cg_term(SID, CG),
    cg_typed_to_ttTerm(CG, TTterm),
    norm_tt(TTterm, NormTT). % normalization is needed for terms such as SICK_FR-819p
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cg_typed_to_ttTerm(X, X) :-
    var(X), !,
    report_error('Unexpected variable found: ~w\n', [X]),
    fail.

cg_typed_to_ttTerm((Var, Cat), (Var, Type)) :- 
    var(Var), !,
    cg_cat_to_type(Cat, Type).    

cg_typed_to_ttTerm((tlp(Tok,Lem,Pos,F1,F2), Cat), (tlp(Tok,Lem,Pos,F1,F2), Type)) :- !,
    cg_cat_to_type(Cat, Type),
    % ( Lem == 'ne' -> format('~w    ~w    ~w~n', [Lem, Pos, Type]); true ),
    % ( Tok == 'a' -> format('~w    ~w    ~w~n', [Lem, Pos, Type]); true ), 
    % ( Lem == 'pas' -> format('~w    ~w    ~w~n', [Lem, Pos, Type]); true ), 
    ( (var(Tok); var(Lem); var(Pos)) 
    ->  report_error('Unexpected variable found: tok=~w; lem=~w; pos=~w~n', [Tok, Lem, Pos]),
        (Tok, Lem, Pos) = ('TOK', 'LEM', 'POS')
    ; true
    ).

cg_typed_to_ttTerm((T1@T2, Cat), (TT1@TT2, Type)) :- !,
    cg_cat_to_type(Cat, Type),
    cg_typed_to_ttTerm(T1, TT1),
    cg_typed_to_ttTerm(T2, TT2).

cg_typed_to_ttTerm((abst(V, T), Cat), (abst(VT, TT), Type)) :- 
    nonvar(V), V = (Var, _), var(Var), !,
    cg_typed_to_ttTerm(V, VT),
    cg_cat_to_type(Cat, Type),
    cg_typed_to_ttTerm(T, TT).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converting types

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
    ; X = s(F), var(F)  % (tlp(et, et, 'CC-KON', 0, O), dr(0,dl(0,dl(1,lit(s(main)),lit(s(main))),dl(1,lit(s(main)),lit(s(main)))),dl(1,lit(s(E)),lit(s(E)))))
    -> Type = s:F
    ; X = s(inf(F)), atom(F)
    -> Type = s:Inf, atomic_list_concat([inf, F], '_', Inf)
    ; X = pp(F) % F can be rarely var 
    -> Type = pp:F
    ; X = txt 
    -> Type = s:main
    ; (X == cl_r; X == cl_y)
    -> Type = X
    ; writeln(lit(X))
    ).

cg_cat_to_type(DR_DL, ArgType~>FunType) :-
    ( DR_DL = dr(0,FunCat,ArgCat)
    ; DR_DL = dl(0,ArgCat,FunCat) 
    ; DR_DL = dl(1,FunCat,ArgCat)
    ), !,
    cg_cat_to_type(FunCat, FunType),
    cg_cat_to_type(ArgCat, ArgType).

cg_cat_to_type(X, X) :-
    writeln(X).