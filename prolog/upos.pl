%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing UPOS tags

:-module(upos, [
	upos2penn/2
]).

:- use_module('generic_utils', [homogeneous_list/1]).

% https://universaldependencies.org/tagset-conversion/en-penn-uposf.html

% TODO contractions like ann_het and zum
upos2penn('ADP_DET', 'AUX').
% TODO add JJR & JJS
upos2penn('ADJ', 'JJ').
% TODO this is a weak rule: add RP, IN, and TO
upos2penn('ADP', 'IN').
% TODO add RBR, RBS, and WRB (covers 'niet' too)
upos2penn('ADV', 'RB').
% TODO add MD and uses of the various verbal tags (VB, VBP, VBG, VBN, VBD, VBZ)
% when they are forms of be, have, do, and get
upos2penn('AUX', 'RB').
upos2penn('CCONJ', 'CC').
% TODO can also be PDT, WDT
upos2penn('DET', 'DT').
upos2penn('INTJ', 'UH').
% TODO add NNS case
upos2penn('NOUN', 'NN').
upos2penn('NUM', 'CD').
% TODO covers TO and RB, like possessive marker, negation and infinitive to
% weirdly not output by Spacy_sm
upos2penn('PART', 'PART').
% TODO coveres PRP, PRP$, WP, WP$, EX, DT
% choosing only option relevant for SICK
upos2penn('PRON', 'PRP$').
% TODO covers NNP or NNPS, not relevant for SICK
upos2penn('PROPN', 'NNP').
% Not relevant for SICK
upos2penn('PUNCT', ',').
% TODO subordinating conjunction covers that, whether, if, when, since, before from IN
upos2penn('SCONJ', 'IN').
% TODO  left blank, not relevant for SICK
upos2penn('SYM', 'SYM').
% covers VB, VBP, VBZ, VBD, VBG, VBN but mapped to most general prefix
upos2penn('VERB', 'VB').
% not relevant for SICK
upos2penn('X', 'X').
upos2penn(POS_POS, POS) :-
    atomic_list_concat([POS|R], '_', POS_POS),
    homogeneous_list([POS|R]).
upos2penn(X, X).
