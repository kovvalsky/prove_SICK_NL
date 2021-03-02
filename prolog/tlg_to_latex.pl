%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Print TLGs in a LaTeX format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- module(tlg_to_latex,
    [
    tlg_ids_to_latex/3,
    tlg_ids_to_pdf/3,
    rtt_ids_to_latex/2,
    rtt_ids_to_pdf/2
    ]).

:- use_module('generic_utils', [
    num_list/2, filepath_write_source/2
    ]).
:- use_module('../LangPro/prolog/llf/ttterm_to_term', [
    ttTerm_to_pretty_ttTerm/2
    ]).
:- use_module('../LangPro/prolog/utils/generic_preds', [
    format_list_list/3, read_dict_from_json_file/2
    ]).
:- use_module('tlg_to_tt', [json_tlg_ids_to_tts/3, anno_sid_tts/3]).
:- use_module('../LangPro/prolog/latex/latex_ttterm', [
    latex_ttTerm_print_tree/3, latex_ttTerm_preambule/1
    ]).

:- multifile sid_tts/2. % silences warnnings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write TT terms (obtained form TLGs) in LaTex according to sentecne IDs
tlg_ids_to_latex(JSON, Filter, FilePath) :-
    filepath_write_source(FilePath, S),
    filter_sen_ids(Filter, SIDs),
    latex_ttTerm_preambule(S),
    write(S, '\\begin{document}\n'),
    read_dict_from_json_file(JSON, AnnoDict),
    write_sen_tts_to_latex(S, AnnoDict, SIDs),
    write(S, '\\end{document}'),
    close(S).

tlg_ids_to_pdf(JSON, Filter, FilePath) :-
    tlg_ids_to_latex(JSON, Filter, FilePath),
    % format(atom(Cmd), 'lualatex ~w', [FilePath]),
    % for heavy duty
    format(atom(Cmd), 'hash_extra=5000000 max_strings=5000000 lualatex ~w', [FilePath]),
    shell(Cmd).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write ready TT terms in LaTex according to sentecne IDs
rtt_ids_to_latex(Filter, FilePath) :-
    filepath_write_source(FilePath, S),
    filter_sen_ids(Filter, SIDs),
    latex_ttTerm_preambule(S),
    write(S, '\\begin{document}\n'),
    write_sen_rtts_to_latex(S, SIDs),
    write(S, '\\end{document}'),
    close(S).

rtt_ids_to_pdf(Filter, FilePath) :-
    rtt_ids_to_latex(Filter, FilePath),
    % format(atom(Cmd), 'lualatex ~w', [FilePath]),
    % for heavy duty
    format(atom(Cmd), 'hash_extra=5000000 max_strings=5000000 lualatex ~w', [FilePath]),
    shell(Cmd).

%----------------------------------------------
% read ready Pretty TT terms and print them in LaTex
write_sen_rtts_to_latex(_S, []) :- !.

write_sen_rtts_to_latex(S, [SID|SIDs]) :-
    write_sen_info_to_latex(S, SID),
    sid_tts(SID, PrettyTTs),
    maplist(ttTerm_to_pretty_ttTerm, TTs, PrettyTTs),
    maplist(latex_ttTerm_print_tree(S, 2), TTs),
    write_sen_rtts_to_latex(S, SIDs).
%----------------------------------------------

%----------------------------------------------
% convert TLGs into TT terms and write in LaTeX
write_sen_tts_to_latex(_S, _AnnoDict, []) :- !.

write_sen_tts_to_latex(S, AnnoDict, [SID|SIDs]) :-
    write_sen_info_to_latex(S, SID),
    anno_sid_tts(AnnoDict, SID, TTs),
    maplist(latex_ttTerm_print_tree(S, 2), TTs),
    write_sen_tts_to_latex(S, AnnoDict, SIDs).
%----------------------------------------------

% write info about the sentence with SID in S in Latex format
write_sen_info_to_latex(S, SID) :-
    once(sen_id(SID,_,_,_,_,Raw)),
    findall([PID,PH,Part,Lab],(
        sen_id(SID,PID,PH,Part,Lab,Raw)
    ), Info),
    length(Info, N),
    format(S, '\\noindent\\texttt{[~w]} \\Large{\\textbf{~w}}~n~n\\noindent ~w occurences:~n',
        [SID, Raw, N]),
    format_list_list(S, '(~w:~w ~w ~w) ', Info),
    format(S, '~n~n', []),
    flush_output(S).


%----------------------------------------------
filter_sen_ids(Filter, SIDs) :-
    nonvar(Filter),
    sublist_of_list(Filter, [yes, no, unknown, 'TRIAL', 'TRAIN', 'TEST']), !,
    findall(L, (
    member(L, Filter), memberchk(L, [yes, no, unknown])
    ), Labels),
        findall(P, (
        member(P, Filter), memberchk(P, ['TRIAL', 'TRAIN', 'TEST'])
    ), Parts),
    findall(SID, (
        sen_id(SID,_,_,Part,Lab,_),
        once((memberchk(Part, Parts); Parts = [])),
        once((memberchk(Lab, Labels); Labels = []))
    ), SID_List),
    list_to_ord_set(SID_List, SIDs).

filter_sen_ids(LIS, SIDs) :-
    num_list(LIS, List),
    findall(SID, (
        sen_id(SID,_,_,_,_,_),
        memberchk(SID, List)
    ), SID_List),
    list_to_ord_set(SID_List, SIDs).
%----------------------------------------------
