
### Peregrine
Sync working copy with Peregrine copy:
```
rsync -azP -LK --exclude peregrine/ --exclude SICK_NL/latex/ --exclude SICK_NL/parses/alpino_xml/ --exclude .git/ --exclude LangPro/.git --exclude LangPro/parsers --exclude LangPro/SNLI --exclude LangPro/results /home/kowalsky/Natural\ Tableau/prove_SICK_NL/ p278651@peregrine.hpc.rug.nl:/home/p278651/LangPro_nl
```
Sync Peregrine outputs with local copy:
```
rsync -azP --delete  p278651@peregrine.hpc.rug.nl:/home/p278651/LangPro_nl/peregrine/   /home/kowalsky/Natural\ Tableau/prove_SICK_NL/peregrine
```
Run CV-3 on peregrine on certain parts:
```
CPU=20; R=50; sbatch --time=30:00 --cpus-per-task=$CPU  --job-name=CV-$R-$CPU --output=peregrine/out/CV-$R-$CPU  peregrine/produce.sh " " peregrine/Results/CV-3/TD/alpino.spacy_lg/r${R},c${CPU}_ab,ch,cKB,cT,p123.log
```

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

### Proving particular problems
Run graphical entailment with initial knowledge:
```
parList([parts([trial,train]), lang(nl), anno_json('SICK_NL/anno/spacy_lg.json'), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck]), gentail(align, [isa_wn(rennen,lopen), isa_wn(gras,veld)], 384).
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
