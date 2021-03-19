%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- ensure_loaded([
	'wn_hyp',
	%'wn_h_',
 	'wn_sim',
	'wn_ant',
	'wn_der',
	'wn_s'
	]).

:- dynamic s/6.
:- dynamic hyp/2.


odwn_patch :-
	retractall(s('eng-30-00007846-n', _, 'man', 'n', 3, _)),
	assertz(hyp('eng-30-13104059-n', 'eng-30-12212361-n')).

% block certain unwanted senses
:- odwn_patch.
