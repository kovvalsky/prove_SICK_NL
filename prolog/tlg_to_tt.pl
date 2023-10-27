%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ========= TLG terms to TT terms ==========
% Convert TLG terms into simply typed lambda terms
% wich are formatted as (term, type)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- module('tlg_to_tt',
    [
        anno_sid_tts/3,
        json_tlg_ids_to_tts/3,
        sen_id_to_tlgs/3,
        tlg_anno_to_tt/3,
        write_anno_tts/2,
        write_anno_tt_debug/2
    ]).

:- use_module('../LangPro/prolog/printer/reporting', [
    test_true/3, report_error/2
    ]).
:- use_module('../LangPro/prolog/llf/ttterm_to_term', [
    write_pretty_ttTerm/3, ttTerm_to_pretty_ttTerm/2
    ]).
:- use_module('../LangPro/prolog/lambda/lambda_tt', [ norm_tt/2 ]).
:- use_module('../LangPro/prolog/utils/generic_preds', [
    true_member/2, read_dict_from_json_file/2
    ]).
:- use_module('generic_utils', [
    enumerate_list/2, homogeneous_list/1, list_to_set_using_match/2,
    dict_length/2, atom_split/4, value_merge_dicts/3,
    dicts_merge_key_value/3, dict_list_to_value_list/3, 
    has_keys/2
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
% Read TLG terms and annotations and write annotated TT terms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_anno_tts(WriteFile, JSON) :-
    open(WriteFile, write, S, [encoding(utf8), close_on_abort(true)]),
    write(S, ':- op(605, xfy, ~>).\n:- op(605, yfx, @).\n\n'),
    read_dict_from_json_file(JSON, AnnoDict),
    get_sen_ids(SIDs),
    dict_keys(AnnoDict, Keys),
    length(Keys, LenKeys),
    length(SIDs, LenSIDs),
    format('~w sentence with diff IDs are read~n', [LenSIDs]),
    format('Annotations for ~w sentences are read~n', [LenKeys]),
    test_true(LenSIDs =< LenKeys,
        'Sentences are more than annotations available', []),
    maplist(write_anno_tt_ignore(S, AnnoDict), SIDs).

write_anno_tt_debug(SID, JSON) :-
    read_dict_from_json_file(JSON, AnnoDict),
    write_anno_tt(user, AnnoDict, SID).

json_tlg_ids_to_tts(JSON, IDs, L_TTs) :-
    read_dict_from_json_file(JSON, AnnoDict),
    maplist(anno_sid_tts(AnnoDict), IDs, L_TTs).


%========================================

write_anno_tt_ignore(S, AnnoDict, SID) :-
    sen_id(SID,_,_,_,_,Raw),
    format(S, '% ~w~n', [Raw]),
    ( write_anno_tt(S, AnnoDict, SID) -> true
    ; format(S, 'sid_tts(~p, []).~n~n', [SID]) ).

write_anno_tt(S, AnnoDict, SID) :-
    anno_sid_tts(AnnoDict, SID, TTs),
    ttterms_to_pretty_atoms(TTs, AtomTTs),
    format(S, 'sid_tts(~p,~n  [~n~w~n  ]).~n~n', [SID, AtomTTs]),
    format('~w~n', [SID]),
    flush_output(S).

anno_sid_tts(AnnoDict, SID, TTs) :-
    atom_number(Key, SID),
    Anno = AnnoDict.Key,
    sen_id_to_tlgs(SID, TLGs, L_Toks),
    %!!! use include instead? alignmnet might fail for some terms-tokens
    ( once(maplist(align_tok_anno(Anno), L_Toks, L_AlignAnno)) -> true
    ; dict_list_to_value_list(Anno, t, AnnoTokens),   
      report_error('Cannot align tokens in sentence id=~w\nterm tokens=~w\nanno tokens=~w', [SID, L_Toks, AnnoTokens]),
      fail ),
    maplist(tlg_anno_to_tt_fail, L_AlignAnno, TLGs, L_TT),
    list_to_set_using_match(L_TT, TTs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UTILITY PREDICATES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get IDs of all sentences
get_sen_ids(SIDs) :-
    findall(SID, sen_id(SID,_,_,_,_,_), SID_List),
    % findall(SID, sen_id_term(SID, _Term, _Toks), SID_List),
    list_to_ord_set(SID_List, SIDs).

%----------------------------------
% align tree terminasl and tokens for Neural Proof Net
% non-deterministic
align_tok_anno(_Anno, [], []).

% MWE alignment
align_tok_anno(Anno, [SubToks|Toks], [AlignedMWE|AlignAnno]) :-
    SubToks = [_,_|_], % it is MWE
    maplist([E,[E]]>>true, SubToks, SingletonSubToks), % to mimic top level
    append(SubAnno, RestAnno, Anno),
    align_tok_anno(SubAnno, SingletonSubToks, SubAligned),
    % value_merge_dicts('_', SubAligned, AlignedMWE),
    dicts_merge_key_value('_', SubAligned, AlignedMWE),
    align_tok_anno(RestAnno, Toks, AlignAnno).

% standard  case when tokens match
align_tok_anno([A|Anno], [T|Toks], [A|AlignAnno]) :-
    T = [A.t],
    align_tok_anno(Anno, Toks, AlignAnno).

% ignores comma token
align_tok_anno([A|Anno], [T|Toks], AlignAnno) :-
    memberchk(A.t, [',']),
    align_tok_anno(Anno, [T|Toks], AlignAnno).

% dealing with MWE TODO this should be ignored later
align_tok_anno([A1,A2|Anno], [[aan_het]|Toks], [A|AlignAnno]) :-
    'aan' = A1.t,
    'het' = A2.t,
    % value_merge_dicts('_', [A1, A2], A),
    dicts_merge_key_value('_', [A1, A2], A),
    align_tok_anno(Anno, Toks, AlignAnno).
%--------------------------------

% used for printing ttterms in file
ttterms_to_pretty_atoms(TTs, AtomTTs) :-
    findall(A, (
        member(TT, TTs),
        ( TT = 'FAIL'-_ -> PTT = TT
        ; ttTerm_to_pretty_ttTerm(TT, PTT) ),
        with_output_to(atom(A), write_pretty_ttTerm('    ', '    ', PTT))
    ), As),
    atomic_list_concat(As, '\n    ,\n', AtomTTs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get corresponding TTterms for sentence IDs and Problem IDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get all available TLGs and its corresponding tokenization for a sentence ID
sen_id_to_tlgs(SID, TLGs, L_Toks) :-
    findall(TLG-Toks, once(
        sen_id_tlg_tok(SID, TLG, Toks) ;
        % prevents from selecting a PID that doesn't exists in non-semeval data
        (sen_id(SID, PID, PH, _, _, _), prob_sen(PID, PH, TLG, Toks))
    ), L_TLG_Toks),
    maplist([TLG1-Toks1, TLG1, Toks1]>>true, L_TLG_Toks, TLGs, L_Toks).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TLG term to TTterm conversion preds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Conversion that doesn't fail on inconvertible TLG terms
tlg_anno_to_tt_fail(Anno, TLG, TT) :-
    ( tlg_anno_to_tt(Anno, TLG, TT) -> true
    ; TT = 'FAIL'-TLG
    ).

tlg_anno_to_tt(Anno, TLG, NormTT) :-
    tlg_term_to_ttterm(TLG, TT, Anno),
    norm_tt(TT, NormTT).

tlg_term_to_ttterm(TLG, TT, Anno) :-
    tlg_term_to_ttterm(TLG, TT, Anno, []). % last argument assigns types to free vars
%---------------------------------------------
% Convert lambdas of type-logical parser into term-type terms
% Main conversion predicate
% Anno is a dictionary of token level annotations
tlg_term_to_ttterm(t(N,C), (TLP,Y), Anno, _Assign) :- !,
    integer(N),
    nth0(N, Anno, Token),
    anno_to_tlp(Token, TLP),
    tlg_type_to_ccg_type(C, Y).

tlg_term_to_ttterm(v(V,_), (V,Y), _Anno, Assign) :- !,
    var(V),
    member((X,T), Assign), % pick type from the binder variable
    V == X, !,
    Y = T.

tlg_term_to_ttterm(abst(VarL,L), (abst(VarT,T), VTy~>TY), Anno, Assign) :- !,
    VarL =.. [_, V, VCa],
    var(V),
    tlg_type_to_ccg_type(VCa, VTy),
    VarT = (V, VTy),
    tlg_term_to_ttterm(L, T, Anno, [VarT|Assign]),
    T = (_, TY).

tlg_term_to_ttterm(L1@L2, (T1@T2, Y1), Anno, Assign) :- !,
    tlg_term_to_ttterm(L1, T1, Anno, Assign),
    tlg_term_to_ttterm(L2, T2, Anno, Assign),
    T1 = (_, Y2 ~> Y1),
    T2 = (_, Y2).

% with decorator terms
tlg_term_to_ttterm(_Dec:L, T, Anno, Assign) :- !,
    tlg_term_to_ttterm(L, T, Anno, Assign).

tlg_term_to_ttterm(_Dec-L, T, Anno, Assign) :- !,
    tlg_term_to_ttterm(L, T, Anno, Assign).
%-----------------------------------------

tlg_type_to_ccg_type(TLG, CCG) :-
    decorated_to_simple(TLG, Simple),
    simple_tlg_to_ccg(Simple, CCG).

%-----------------------------------------
% converting decorated types to simple types
decorated_to_simple(D, D) :-
    atom(D), !.

decorated_to_simple(D1~>D2, S1~>S2) :-
    decorated_to_simple(D1, S1),
    decorated_to_simple(D2, S2).

decorated_to_simple(_D:[T], S) :- !,
    decorated_to_simple(T, S).

decorated_to_simple(_D:{T}, S) :- !,
    decorated_to_simple(T, S).
%-----------------------------------------

%-----------------------------------------
% TLG simple type to CCG simple type
simple_tlg_to_ccg(A~>B, X~>Y) :- !,
    simple_tlg_to_ccg(A, X),
    simple_tlg_to_ccg(B, Y).

simple_tlg_to_ccg(smain, s:dcl).
simple_tlg_to_ccg(n, n:_).
simple_tlg_to_ccg(np, np:_).
simple_tlg_to_ccg(pp, pp).
simple_tlg_to_ccg(pr, pr).

% https://www.let.rug.nl/vannoord/alp/Alpino/adt.html

simple_tlg_to_ccg(ssub, s:sub).     % Subordinate clause (verb final)
simple_tlg_to_ccg(vnw, np:_).       % pronoun feat would be uninformative for WH
simple_tlg_to_ccg(vz, pr).          % particle
simple_tlg_to_ccg(ahi, np:_~>s:ng). % aan het-infinitive group
simple_tlg_to_ccg(ww, np:_~>s:b).   % verb
simple_tlg_to_ccg(ppart, np:_~>s:pt). % passive/perfect participle
simple_tlg_to_ccg(inf, np:_~>s:b).  % bare infinitive group
simple_tlg_to_ccg(ti, np:_~>s:to).  % te-infinitive group
simple_tlg_to_ccg(oti, np:_~>s:to). % om te-infinitive-group
simple_tlg_to_ccg(ap, np:_~>s:adj). % adjective phrase
simple_tlg_to_ccg(adj, np:_~>s:adj).
simple_tlg_to_ccg(adjp, np:_~>s:adj).
%TODO check if this works
simple_tlg_to_ccg(bw, pr).          % Adverb
simple_tlg_to_ccg(adv, pr).         % Adverb, what is diff between these adverbs?
simple_tlg_to_ccg(whrel, s:dcl~>s:dcl). % relative clause with embedded antecedent
simple_tlg_to_ccg(tw, np:num).      % Numeral
simple_tlg_to_ccg(whsub, s:q).      % embedded question
simple_tlg_to_ccg(whq, s:q).        % WH-question

simple_tlg_to_ccg(cp, s:_).        % WH-question
simple_tlg_to_ccg(sv1, s:_).        % WH-question
%-----------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UD pos tags to Penn
% this is not a perfect mapping because it goes
% from less to more informative tags
anno_to_tlp(Anno, tlp(T,L,P)) :-
    once(correct_tlp(Anno, [T,L,P])).

% No pos conversion
% correct_tlp([T,L,POS], [T,L,POS]).

% we are dealing with Alpino/Lassy-style annotations
correct_tlp(A, TLP) :-
    has_keys(['postag'], A),
    !, % stick to this type of annotations
    lassy2tlp(A, TLP).

% we are dealing with non-alpino annotations
% and only converts UPOS to Penn POS
correct_tlp(A, [A.t, A.l, POS]) :-
    upos2penn(A.p, POS).
