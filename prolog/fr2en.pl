%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% French specific predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module('fr2en',
    [
        translate_fr2en/2
    ]).

%------------------- FRENCH -------------------------------
% Translate only closed class and semantically heavy words
% like no, every, not, the, a,  etc.
translate_fr2en(X, X) :-  % catching unexpacted vars
    var(X), !,
    format('Untyped variable in translate_fr2en/2'), fail.

translate_fr2en((X,Ty), (X,Ty)) :-
    var(X), !.

% translate_fr2en(NL, EN) :-
%     translate_mwe_nl2en(NL, EN), !.

translate_fr2en((NL1 @ NL2, Ty), (EN1 @ EN2, Ty)) :- !,
    translate_fr2en(NL1, EN1),
    translate_fr2en(NL2, EN2).

translate_fr2en((abst(X, NL), Ty), (abst(X, EN), Ty)) :- !,
    translate_fr2en(NL, EN).

translate_fr2en((tlp(T,NL,P), Ty), (tlp(T,EN,P1), Ty)) :- !,
    ( 
    NL == 'pas' -> EN = 'not'
    % ; memberchk(NL, ['geen','geen_enkel']) -> EN = 'no'
    ; memberchk(NL, ['la','le']) -> EN = 'the'
    ; memberchk(NL, ['un', 'une']) -> EN = 'a'
    % ; memberchk(NL, ['wat','sommig']), Ty = _~>np:_ -> EN = 'some'
    ; NL == 'et' -> EN = 'and'
    ; NL == 'y' -> EN = 'there'
    % ; memberchk(NL, ['deze','die','dit','dat']),
    %   ( Ty = (np:_~>s:_)~>N~>N; Ty = s:_~>N~>N )  -> EN = 'who'
    ; NL == 'par', Ty = np:_~>(np:_~>s:_)~>(np:_~>s:_) -> EN = 'by'
    % % ; NL == 'iemand', Ty = np:_ -> EN = 'somebody'
    % % ; NL == 'niemand', Ty = np:_ -> EN = 'nobody'
    % % ; NL == 'iets', Ty = np:_ -> EN = 'something'
    % % ; NL == 'niets', Ty = np:_ -> EN = 'nothing'
    % ; NL == 'worden', P == 'RB',
    %   Ty = (np:_~>s:pt)~>N:_~>s:_, memberchk(N, ['n','np']) -> EN = 'be'
    % % ; NL == 'doen', Ty = np:_~>np:_~>s:_ -> EN = 'do'%!!! plaatsen<doen sicknl-3250
    % ; memberchk(NL, ['is','aan_het']),
    %   % memberchk(P, ['RB','AUX']), ignoring POS as it can be wrong
    %   Ty = (np:_~>s:_)~>_NP_or_N:_~>s:_ -> EN = 'be'
    % ; NL == 'zijn', % zijn can have PRP$ wrongly sicknl-1412
    %   Ty = (np:_~>s:_)~>_NP_or_N:_~>s:_ -> EN = 'be', P1 = 'AUX'
    % ; memberchk(NL, ['is','zijn']), Ty = np:_~>s:_ -> EN = 'be' % pos=RB?
    ; NL = EN 
    ),
    (var(P1) -> P1 = P; true ). 

% accommodates tlp/5 terms
translate_fr2en((tlp(T,NL,P,F1,F2), Ty), (tlp(T,EN,P1,F1,F2), Ty)) :- !,
    translate_fr2en((tlp(T,NL,P), Ty), (tlp(T,EN,P1), Ty)).

%----------------------------------------------------

% translate_mwe_nl2en(
%     ( (Enn,n:_~>D) @ (Paar,n:_), D ),
%     ( tlp(Enn_Paar,'a_few','DT'), D )
% ) :-
%     tlp_lemma_in_list(Enn, ['een','één','eén']),
%     tlp_lemma_in_list(Paar, ['paar']),
%     merge_tlps('_', [Enn,Paar], tlp(Enn_Paar,_,_POS)). %!!! POS can be compound