
:- ensure_loaded([
    '../LangPro/prolog/main.pl'
    ]).

:- use_module('tlg_to_tt', [
    write_anno_tts/2, write_anno_tt_debug/2
    ]).
:- use_module('tlg_to_latex', [
    tlg_ids_to_latex/3, tlg_ids_to_pdf/3, rtt_ids_to_latex/2, rtt_ids_to_pdf/2
    ]).


sen_id(SID, PID, PH, Label, Sen) :-
    debMode(part(Part)),
    sen_id(SID, PID, PH, Part, Label, Sen).
