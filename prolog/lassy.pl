%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Lassy/Alpino annotations

:-module(lassy, [
	lassy2tlp/2
]).

:- use_module('generic_utils', [homogeneous_list/1]).
:- use_module('../LangPro/prolog/utils/generic_preds', [
    substitute_in_atom/4
    ]).

%http://nederbooms.ccl.kuleuven.be/php/common/TreebankFreqsLASSY.html#table8
%https://www.let.rug.nl/vannoord/alp/Alpino/adt.html

lassy2tlp(A, [A.t, L, POS]) :-
    substitute_in_atom(A.l, '_', ' ', L), % repalce underscores in lemmas with space
    lassyPosTags2Penn(A.postag, POS).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% map extended POS tag list of Lassy to penn POS tags
% a list is due to possible MWE
lassyPosTags2Penn(L_PosTag, POS) :-
    postags2prolog(L_PosTag, L_TermPosTag),
    maplist(decompose_lassyPosTag, L_TermPosTag, L_Tag_Feats),
    maplist([TagF, P]>>lassyTagFeatList2Penn([TagF], P), L_Tag_Feats, L_Pos),
    ( homogeneous_list(L_Pos) -> L_Pos = [POS|_]
    ; lassyTagFeatList2Penn(L_Tag_Feats, POS) ).

%------------------------------------------------
lassyTagFeatList2Penn(['n'-Feats], POS) :-
    ( subset(['soort','ev'], Feats) -> POS = 'NN'
    ; subset(['soort','mv'], Feats) -> POS = 'NNS'
    ; subset(['eigen','ev'], Feats) -> POS = 'NNP'
    ; subset(['eigen','mv'], Feats) -> POS = 'NNPS'
    ).

lassyTagFeatList2Penn(['vnw'-Feats], POS) :-
    ( subset(['betr'], Feats) -> POS = 'WDT'  % WP?
    ; subset(['bez'],  Feats) -> POS = 'PRP$'
    ; subset(['onbep'],Feats) -> POS = 'DT'
    ; subset(['aanw'], Feats) -> POS = 'EX'
    ; subset(['recip'],Feats) -> POS = 'DT'
    ; subset(['refl'], Feats) -> POS = 'PRP'
    ; subset(['pers'],  Feats) -> POS = 'PRP'   % added
    ; subset(['per'],  Feats) -> POS = 'PRP'    % can be removed?
    ; subset(['pr'],  Feats) -> POS = 'PRP'     % added
    ; subset(['vb'],   Feats) -> POS = 'WP'
    ).

lassyTagFeatList2Penn([P-_Feats], POS) :-
    ( P == 'lid' -> POS = 'DT'  % onbep vs bep
    ; P == 'vz'  -> POS = 'IN'  % init vs fin: TODO PR?
    ; P == 'ww'  -> POS = 'VB'  % TODO: passive?
    ; P == 'adj' -> POS = 'JJ'  % TODO: prenom/nom/vrij JJR, JJS
    ; P == 'vg'  -> POS = 'CC'  % onder vs neven
    ; P == 'tw'  -> POS = 'CD'
    ; P == 'bw'  -> POS = 'RB'
    ; P == 'let' -> POS = ','   % TODO: shallow
    ; P == 'tsw' -> POS = 'UH'  % baby gets TSW
    ; P == 'spec'-> POS = 'NNP' % FIXME fitting to the domain?
    ).

lassyTagFeatList2Penn(['vz'-_, 'lid'-_], 'AUX').
%------------------------------------------------

decompose_lassyPosTag(PosTag, Tag-Feats) :-
    compound_name_arity(PosTag, Tag, Arity),
    ( Arity = 0 -> Feats = []
    ; PosTag =.. [Tag|Feats] ).

%------------------------------------------------

postags2prolog(PosTags, L_PrologTerm) :-
    atomic_list_concat(L_PosTag, '_', PosTags),
    maplist(postag2prolog, L_PosTag, L_PrologTerm).

postag2prolog(PosTag, TermPosTag) :-
    substitute_in_atom(PosTag, ',', '\',\'', PosTag1),
    substitute_in_atom(PosTag1, '(', '(\'', PosTag2),
    substitute_in_atom(PosTag2, ')', '\')', PosTag3),
    downcase_atom(PosTag3, Postag),
    term_to_atom(TermPosTag, Postag).
