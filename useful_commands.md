## Error Analysis

### Comparison of Parsers
1. Compare predictions of `$sys` and `$ref` on the train set (while using the both pos taggers) and print problems (in both EN `$src` and NL `$trg`) for which the predictions differ (`$md` flag on). The predictions will be formatted as `$sys-($ref)-[$gold]`.
```
$ python3 python/xlang_compare.py --sys Results/train/npn.alpino-spacy_lg.ans --ref Results/train/alpino.alpino-spacy_lg.ans  --src LangPro/ccg_sen_d/SICK_sen.pl --trg SICK_NL/sen.pl  -m NEC NEC -md

...
 8502: N-(E)-[ENTAILMENT]
P:trg: De man gaat het meer in
  src: The man is going into the lake
H:trg: De persoon gaat het water in
  src: The person is going into the water
...
```   
2. Pick a particular problem, e.g., 8502, where the alpino trees helps to solve but not the npn trees. Check what predictions each version of LangPro made. The output can be read as [gold], prediction, tableau_status, terminated_or_limited, rule_applications_used, explanation.
```
$ grep "\b8502:" Results/train/*.*.log

Results/train/alpino.alpino.log:8502:     [yes],     yes,  closed, 'Ter',6     XP: [isa(man,persoon),isa(meer,water)]
Results/train/alpino.spacy_lg.log:8502:     [yes], unknown,    open, 'Ter',47    XP: []
Results/train/npn.alpino.log:8502:     [yes], unknown,    open, 'Ter',35    XP: []
Results/train/npn.spacy_lg.log:8502:     [yes], unknown,    open, 'Ter',35    XP: []
```
It shows that only alpino with its pos tags is able to lead LangPro to the correct label. Why the npn trees with the alpino tags are not  able to do so?
3. For further inspection, in the Atril pdf reader, view the syntactic trees and LLFs (e.g., based on `npn` parser and `alpino` pos tags) used for theorem-proving:
```
ID=8502; parser=npn; pos=alpino; produce -d -b -f produce.ini   SICK_NL/latex/$parser.$pos.$ID.pdf && atril SICK_NL/latex/$parser.$pos.$ID.pdf & disown
```
4. If needed to look beyond trees, then check the tableau. It is a good practice that you a separate terminal window for each parser where prolog with the corresponding trees will be loaded.
```
# loading the prover with alpino trees
$ swipl -f prolog/main.pl  SICK_NL/sen.pl  SICK_NL/parses/alpino.pl  WNProlog/wn.pl
# This can be run only once to set the global parameters in teh beginning
?- parList([parts([train]), lang(nl), anno_json('SICK_NL/anno/alpino.json'), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck]).
# Run LangPro in the graphical mode with aligned terms (if the prove is found, it is most probably done with aligned terms as this mode is tested first for efficiency reasons.)
?- gentail(aligned, 8502).
```
You might need to run LangPro for the npn trees with the alpino pos tags in another terminal window to compare two tableaux.

### Reasons for failed proofs

Let's consider 8316 `Honden racen op een circuit ENTAILS Honden rennen op een spoor`. It seems that if trees are fine, then having `racen < rennen` and `circuit < spoor` should be sufficient to prove entailment.

1. Check if a particular lexical knowledge is available in WN.
The following checks if `garnaal` is more specific than `persoon`, and also shows
the transitive chain between these concepts:
```
$ swipl -f prolog/main.pl WNProlog/wn.pl
% Num is a numerical POS tag (1=Noun, 2=Verb, 3=Adjective, 4-Adverb)
% SN is a sense number (not ID), and Path a list of sense IDs
?- word_hyp(_, garnaal, persoon, Num, SN1, SN2, Path).
% or print all hypernyms of a particular word
?- print_all_word_hyp(circuit, W2).
% or all hyponyms
?- print_all_word_hyp(W1, rennen).
```
2. A prolog command for proving (with GUI) a particular problem with manually provided lexical knowledge (e.g., `isa_wn(racen, rennen), isa_wn(circuit, spoor)`):
```
% Global parameters are set once
?- parList([parts([train]), lang(nl), anno_json('SICK_NL/anno/spacy_lg.json'), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck]).
% Running GUI proving:
?- gentail(align, [isa_wn(racen, rennen), isa_wn(circuit, spoor)], 8316).
% if no GUI needed, then use:
?- solve_entailment(align, [isa_wn(racen, rennen), isa_wn(circuit, spoor)], (8316, whatever), X).
% Actually the output shows that both knowledges is necessary and sufficent for finding the proof.
```

## Evaluation

### Ensemble of four LPs
```
LangPro/python/evaluate.py  --gld SICK_NL/sen.pl   --sys Results/abd_eva/TD_E/npn_robbert.alpino/r200,c0_ab,ch,cKB,cT,p123.ans.E  Results/abd_eva/TD_E/alpino.alpino/r200,c20_ab,ch,cKB,cT,p123.ans.E  Results/abd_eva/TD_E/npn_robbert.spacy_lg/r200,c0_ab,ch,cKB,cT,p123.ans.E  Results/abd_eva/TD_E/alpino.spacy_lg/r200,c20_ab,ch,cKB,cT,p123.ans.E   --hybrid
```

### LPs vs Neural models
The problems that were solved by the LP ensemble and failed by all neural models:
```
python3 LangPro/python/evaluate.py --sys Results/abd_eva/TD_E/LangPro_2x2_r200.ans  baselines/bertje.tsv  baselines/mbert.tsv  baselines/robbert.tsv   --gld SICK_NL/sen.pl -onc 1 | grep -P " [CE] " | grep -oP "\d+" | xargs  -I % sh -c 'grep "\s%," SICK_NL/sen.pl'
```

## Other Commands
### LaTeX & PDF
Produce pdf files for problems and open in atril:
```
ID=6912; parser=alpino; produce -d -b -f produce.ini   SICK_NL/latex/$parser.spacy_lg.$ID.pdf && atril SICK_NL/latex/$parser.spacy_lg.$ID.pdf & disown
```

### Contrast Solved & Unsolved across parsers
List problems that were not solved by either npn or alpino:
```
produce -d -f produce.ini trial.alpino-npn.spacy_lg.N-EC.comp
```
List problems that were not solved by either npn or alpino, but were solved by C&C:
```
produce -d -f produce.ini  trial.alpino-npn-vs-ccg.spacy_lg.N-EC.comp
```



### Abduction
Abduction for a specific problem (NL):
```
parList([parts([trial,train]), lang(nl), anno_json('SICK_NL/anno/spacy_lg.json'), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck]), Config = [fold-3, align-both, constchk, constKB, compTerms, patterns-([_,_@_,(_@_)@_, _@(_@_)])], PID=384, sen_id(_,PID,'h',Ans,_), train_with_abduction(Config, [(PID, Ans)], KB, Scores, Acc).
```

Abduction with initial knowledge for a specific problem:
```
parList([parts([trial,train]), lang(nl), anno_json('SICK_NL/anno/spacy_lg.json'), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck]), Config = [fold-3, align-both, constchk, constKB, compTerms, patterns-([_,_@_,(_@_)@_, _@(_@_)])], PID=384, sen_id(_,PID,'h',Ans,_), maplist(add_lex_to_id_ans, [(PID, Ans)], TrainIDAL), while_improve_induce_prove(TrainIDAL, [(PID,Ans)]-FailA, []-SolvA, Config, [isa_wn(rennen,lopen)], Induced_KB0)
```

### WordNet
Find all hypernyms of a word:
```
print_all_word_hyp(garnaal, W2)
```
Get hypernymy relation with the path
```
word_hyp(_, garnaal, persoon, Num, SN1, SN2, Path)
```

### Testing Changes
After changing prover, make sure nothing degrades:
```
produce -B -f produce.ini Results/trial/ccg.ans
produce -B -f produce.ini Results/trial/alpino-npn.spacy_lg.ans

produce -f produce.ini trial.alpino-npn.spacy_lg.score
produce -f produce.ini trial.ccg.score

parser=npn; part=trial; python3 python/xlang_compare.py --sys Results/$part/$parser.spacy_lg.ans --ref best/$part/$parser.spacy_lg.ans --src LangPro/ccg_sen_d/SICK_${part}_sen.pl --trg SICK_NL/sen.pl -m CEN CEN -md
```

### Showing fixes done with sentences
```
produce -d  -f produce.ini stats.train_trial.alpino.spacy_lg.tree_fix
```
