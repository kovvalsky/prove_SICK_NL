%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% French specific predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module('fr2en',
    [
        translate_fr2en/2
    ]).

:- use_module('utils', [tlp_lemma_in_list/2, merge_tlps/3]).
:- use_module('../LangPro/prolog/printer/reporting', [
    report_error/2
    ]).
:- use_module('../LangPro/prolog/llf/ttterm_preds', [
	add_heads/2, set_type_for_tt/3
    ]).

%------------------- FRENCH -------------------------------
% Translate only closed class and semantically heavy words
% like no, every, not, the, a,  etc.
translate_fr2en(X, X) :-  % catching unexpacted vars
    var(X), !,
    format('Untyped variable in translate_fr2en/2'), fail.

translate_fr2en((X,Ty), (X,Type)) :-
    var(X), !,
    change_atomic_types(Ty, Type).

% does some fixes, e.g., il y a -> il_y a
translate_fr2en(FR, EN) :-
    translate_mwe_fr2en(FR, FR1), !,
    translate_fr2en(FR1, EN).

translate_fr2en((FR1 @ FR2, Ty), (EN1 @ EN2, Type)) :- !,
    translate_fr2en(FR1, EN1),
    translate_fr2en(FR2, EN2),
    change_atomic_types(Ty, Type).

translate_fr2en((abst(X, FR), Ty), (abst(X, EN), Type)) :- !,
    translate_fr2en(FR, EN),
    change_atomic_types(Ty, Type).

translate_fr2en((tlp(T,FR,P), Ty), (tlp(T,EN,P1), Type)) :- !,
    get_number_suffix(P, _, Suffix),
    ( FR == 'pas' -> EN = 'not', P1 = 'RB'%, format('~w: ~w~n', [T, Ty])
    ; FR == 'ne', P == 'ADV-ADV' -> EN = 'ne', P1 = 'NIL' % semantically empty
    % ; memberchk(FR, ['geen','geen_enkel']) -> EN = 'no'
    ; memberchk(FR, ['la','le']) -> EN = 'the', P1 = 'DT' %FIXME les --> s?
    ; memberchk(FR, ['un', 'une']), Suffix == 'Sing' -> EN = 'a', P1 = 'DT'
    ; memberchk(FR, ['un', 'une']), Suffix == 'Plur' -> EN = 's', P1 = 'DT'
    % ; memberchk(FR, ['wat','sommig']), Ty = _~>np:_ -> EN = 'some'
    ; FR == 'et' -> EN = 'and', P1 = 'CC'
    ; FR == 'y', P == 'CLO-PRO:PER' -> EN = 'there', P1 = 'EX'
    ; FR == 'il', P == 'CLS-PRO:PER' -> EN = 'it', P1 = 'EX'
    ; FR == 'there', P == 'EX' -> EN = FR, P1 = P % to pass  this after mwe is done
    ; FR == 'no', P == 'DT' -> EN = FR, P1 = P % to pass  this after mwe is done
    ; FR == 'nobody', P == 'DT' -> EN = FR, P1 = P % to pass  this after mwe is done
    ; memberchk(FR, ['qui','que']), Ty = (np:_~>s:_)~>N~>N -> EN = 'who', P1 = 'WP'
    ; FR == 'par', Ty = np:_~>(np:_~>s:_)~>(np:_~>s:_) -> EN = 'by', P1 = 'IN'
    ; FR == 'par', Ty = np:acc~>pp:par -> EN = 'by', P1 = 'IN'
    % % ; FR == 'iemand', Ty = np:_ -> EN = 'somebody'
    % % ; FR == 'niemand', Ty = np:_ -> EN = 'nobody'
    % % ; FR == 'iets', Ty = np:_ -> EN = 'something'
    % % ; FR == 'niets', Ty = np:_ -> EN = 'nothing'
    % ; FR == 'worden', P == 'RB',
    %   Ty = (np:_~>s:pt)~>N:_~>s:_, memberchk(N, ['n','np']) -> EN = 'be'
    % % ; FR == 'doen', Ty = np:_~>np:_~>s:_ -> EN = 'do'%!!! plaatsen<doen sicknl-3250
    % ; memberchk(FR, ['is','aan_het']),
    %   % memberchk(P, ['RB','AUX']), ignoring POS as it can be wrong
    %   Ty = (np:_~>s:_)~>_NP_or_N:_~>s:_ -> EN = 'be'
    ; FR == 'avoir', Ty = np:_~>np:thr~>s:_ -> EN = 'be', P1 = 'VB'
    ; memberchk(FR, ['être']), memberchk(Ty, [(n:_~>n:_)~>(np:_~>s:_), (np:_~>s:_)~>(np:_~>s:_)])
        -> EN = 'be', P1 ='VB'
    ; FR = EN 
    ),
    ( var(P1) -> fr_pos_tags_to_tag(P, P1); true ),
    change_atomic_types(Ty, Type). 

% accommodates tlp/5 terms
translate_fr2en((tlp(T,FR,P,F1,F2), Ty), (tlp(T,EN,P1,F1,F2), Type)) :- !,
    translate_fr2en((tlp(T,FR,P), Ty), (tlp(T,EN,P1), Type)).

%----------------------------------------------------
% context-free change of types 
change_atomic_types(Ty, _) :- 
    var(Ty), !,
    report_error('Var type found: ~w~n', [Ty]).

change_atomic_types(Ty1~>Ty2, Type1~>Type2) :- !,
    change_atomic_types(Ty1, Type1),
    change_atomic_types(Ty2, Type2).

change_atomic_types(Ty, Type) :-
    Ty = pp:_ -> Type = pp % preposition features are discarded
    ; Ty == s:pass -> Type = s:pss % passive feature normalization
    ; Ty == s:main -> Type = s:dcl % assume that main=dcl
    ; Type = Ty.

%----------------------------------------------------

% ((a NP) y) li --> (a NP) il_y:there
translate_mwe_fr2en(
    ( (((A,Ty_A) @ NP, _) @ (Y,cl_y), _) @ (IL,_), s:main ),
    ( ((A,Ty_np_np_s) @ NP, Ty_vp) @ There, s:dcl )
) :-
    tlp_lemma_in_list(Y, ['y']),
    tlp_lemma_in_list(IL, ['il']),
    tlp_lemma_in_list(A, ['avoir']), !,
    Ty_A == np:acc ~> cl_y ~> np:nom ~> s:main,
    Ty_vp = np:thr ~> s:dcl,
    Ty_np_np_s = np:acc ~> np:thr ~> s:dcl,
    There = (tlp(ILY,'there','EX','Ins','Ins'), np:thr),
    merge_tlps('_', [IL,Y], tlp(ILY,_,_,_,_)).


% (ne ((a (Mod:np~>np personne:np)) y)) li --> (a (Mod:np~>np (no personne))) il_y:there
translate_mwe_fr2en(
    ( ((NE,_Ty_NE) @ (((A,Ty_A) @ ModPer, _) @ (Y,cl_y), _), _) @ (IL,_), s:main ),
    ( ((A,Ty_np_np_s) @ ModNoPer, Ty_vp) @ There, s:dcl )
) :-
    tlp_lemma_in_list(Y, ['y']),
    tlp_lemma_in_list(IL, ['il']),
    NE = tlp(NeT,'ne',_,_,_),
    tlp_lemma_in_list(A, ['avoir']), 
    ModPer = (Mod @ (Per, np:F1), ModNP_Ty),
    Mod = (_, np:_~>np:_),
    tlp_lemma_in_list(Per, ['personne']),
    !,
    set_type_for_tt((Per, np:F1), n:F2, Per_N),
    Ty_A == np:acc ~> cl_y ~> np:nom ~> s:main,
    Ty_vp = np:thr ~> s:dcl,
    Ty_np_np_s = np:acc ~> np:thr ~> s:dcl,
    NoPer = ((tlp(NeT,'no','DT','Ins','Ins'), n:F2~>np:F1) @ Per_N, np:F1),
    ModNoPer = (Mod @ NoPer, ModNP_Ty),
    There = (tlp(ILY,'there','EX','Ins','Ins'), np:thr),
    merge_tlps('_', [IL,Y], tlp(ILY,_,_,_,_)).


% (ne ((a NP) y)) li -->  (ne (a NP)) il_y:there
translate_mwe_fr2en(
    ( ((NE,_Ty_NE) @ (((A,Ty_A) @ NP, _) @ (Y,cl_y), _), _) @ (IL,_), s:main ),
    ( ((NE,Ty_NE_new) @ ((A,Ty_np_np_s) @ NP, Ty_vp), Ty_vp) @ There, s:dcl )
) :-
    tlp_lemma_in_list(Y, ['y']),
    tlp_lemma_in_list(IL, ['il']),
    tlp_lemma_in_list(NE, ['ne']),
    tlp_lemma_in_list(A, ['avoir']), !,
    Ty_A == np:acc ~> cl_y ~> np:nom ~> s:main,
    Ty_vp = np:thr ~> s:dcl,
    Ty_np_np_s = np:acc ~> np:thr ~> s:dcl,
    Ty_NE_new = (np:thr ~> s:dcl) ~> np:thr ~> s:dcl,
    There = (tlp(ILY,'there','EX','Ins','Ins'), np:thr),
    merge_tlps('_', [IL,Y], tlp(ILY,_,_,_,_)).

% (pas (de N, pp:de), np) --> (pas_de N, np)
translate_mwe_fr2en(
    ( (PAS,_) @ ((DE,_) @ TT_N, pp:de), Ty_np ),
    ( (PAS_DE,n:F~>Ty_np) @ TT_N, Ty_np )
) :-
    tlp_lemma_in_list(PAS, ['pas']),
    tlp_lemma_in_list(DE, ['de']), 
    TT_N = (_, n:F), 
    Ty_np = np:_, !,
    merge_tlps('_', [PAS,DE], tlp(Pas_de,_,_,_,_)),
    PAS_DE = tlp(Pas_de, no, 'DT','Ins','Ins').




%----------------------------------------------------
% Converting POS tags
fr_pos_tags_to_tag('CLS-PRO:PER', 'CLS-PRO:PER') :- !.
fr_pos_tags_to_tag('CLO-PRO:PER', 'CLO-PRO:PER') :- !.

fr_pos_tags_to_tag(T1_T2Suffix, T) :-
    atomic_list_concat([_T1, T2Suffix], '-', T1_T2Suffix),
    get_number_suffix(T2Suffix, T2, Suffix),
    ( T2 == 'NOM', Suffix == 'Plur' -> T = 'NNS'
    ; T2 == 'NOM', Suffix == 'Sing' -> T = 'NN'
    ; T2 == 'DET:ART' -> T = 'DT'
    ; T2 == 'DET:POS' -> T = 'PRP$'
    ; T2 == 'PRP' -> T = 'IN'
    % ; T2 == 'PRP:det' -> T = 'IN'
    ; T2 == 'ADJ' -> T = 'JJ'
    ; T2 == 'ADV' -> T = 'RB'
    ; T2 == 'KON' -> T = 'CC'
    %------- VER -------
    ; T2 == 'VER:pres' -> T = 'VB'
    ; T2 == 'VER:pper' -> T = 'VBN'
    ; T2 == 'VER:infi' -> T = 'VB'
    ; T2 == 'VER:simp' -> T = 'VBD'
    ; T2 == 'VER:ppre' -> T = 'VB'
    %------- PRP -------
    ; T2 == 'PRO:PER' -> T = 'PRP'
    ; T2 == 'PRO:REL' -> T = 'WP'
    % ; T2 == 'PRO:IND' -> T = 'PRP'
    ; T2 == 'PRO:DEM' -> T = 'DT'
    ; T2 == 'PRO' -> T = 'PRP'
    %--------------------
    ; T2 == 'NAM' -> T = 'NNP'
    ; T2 == 'NUM' -> T = 'CD'
    ; T = T2
    ).

get_number_suffix(POS_suffix, POS, Suffix) :-
    member(Suffix, ['Sing', 'Plur', '']),
    sub_atom(POS_suffix, Before, _, 0, Suffix),
    ( Suffix == '' -> Before_1 = Before; Before_1 is Before - 1 ),
    sub_atom(POS_suffix, 0, Before_1, _, POS),
    !.