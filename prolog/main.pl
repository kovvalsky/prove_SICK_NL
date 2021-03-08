
:- ensure_loaded([
    '../LangPro/prolog/main.pl'
    ]).

:- use_module('tlg_to_tt', [
    write_anno_tts/2, write_anno_tt_debug/2, sen_id_to_tlgs/3, anno_sid_tts/3
    ]).
:- use_module('tlg_to_latex', [
    tlg_pid_to_latex/3, tlg_ids_to_latex/3, tlg_ids_to_pdf/3,
    rtt_ids_to_latex/2, rtt_ids_to_pdf/2
    ]).
:- use_module('utils', [ add_feats_to_tlp/2, translate_nl2en/2 ]).
% :- use_module('generic_utils', [ read_dict_from_json_file/2
%     ]).



sen_id(SID, PID, PH, Label, Sen) :-
    debMode(part(Part)),
    sen_id(SID, PID, PH, Part, Label, Sen).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- multifile sen_id_to_base_ttterm/2.
:- discontiguous sen_id_to_base_ttterm/2.

sen_id_to_base_ttterm(SID, TTterm) :-
    sen_id_to_tlgs(SID, _TLGs, _L_Toks), !,
    debMode(anno_dict(AnnoDict)),
    anno_sid_tts(AnnoDict, SID, [TT_NL|_]),
    translate_nl2en(TT_NL, TT),
    add_feats_to_tlp(TT, TTterm).
