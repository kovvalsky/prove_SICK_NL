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
	% sick_nl-3834: ei < kip ei
	assertz(s('TH-0', _, 'kip ei', 'n', 1, _)),
	assertz(hyp('TH-0', 'eng-30-01460457-n')),
	% sick_nl-1276: rijs bier < bier
	assertz(s('TH-1', _, 'rijst bier', 'n', 1, _)),
	assertz(hyp('TH-1', 'eng-30-07886849-n')),

	retractall(s('eng-30-00007846-n', _, 'man', 'n', 3, _)),
	assertz(hyp('eng-30-13104059-n', 'eng-30-12212361-n')).

% block certain unwanted senses
:- odwn_patch.
