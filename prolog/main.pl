
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

% predicates that can introduce TLG terms (depending on how they were obtained)
:- dynamic prob_sen/4.
:- dynamic sen_id_tlg_tok/3.

sen_id(SID, PID, PH, Label, Sen) :-
    debMode(parts(Parts)),
    % this order keeps IDs ordered
    sen_id(SID, PID, PH, PART, Label, Sen),
    downcase_atom(PART, Part),
    memberchk(Part, Parts).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% patch that allows to introduce terms from different source than LangPro
:- multifile sen_id_to_base_ttterm/2.
:- discontiguous sen_id_to_base_ttterm/2.

sen_id_to_base_ttterm(SID, TTterm) :-
    sen_id_to_tlgs(SID, _TLGs, _L_Toks), !,
    debMode(anno_dict(AnnoDict)),
    anno_sid_tts(AnnoDict, SID, [TT_NL|_]),
    translate_nl2en(TT_NL, TT),
    add_feats_to_tlp(TT, TTterm).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test_tlg_to_llf :-
    findall(SID, sen_id(SID,_,_,_,_), L_SID),
    list_to_ord_set(L_SID, SIDs),
    findall(_, (
        member(S, SIDs),
        writeln(S),
        sen_id_to_base_ttterm(S, Tree),
        correct_ttterm(Tree, CorrTree),
        once_gen_quant_tt(CorrTree, _LLF)
    ), _).
