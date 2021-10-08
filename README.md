# prove_SICK_NL
Prove Ducth NLI problems of [SICK-NL](https://github.com/gijswijnholds/sick_nl) with [LangPro](https://github.com/kovvalsky/LangPro).
Note that the current repo contains SICK-NL version that corresponds its English counterpart used for [Semeval-2014 Task 1](https://alt.qcri.org/semeval2014/task1/). SemeEval version contains in total 9927 problems while the original one 9840 problems.

# Prerequisites

The current repo and the [LangPro](https://github.com/kovvalsky/LangPro) repo shoudl be in the same directory.

Get Langpro repo with 
`git clone --branch nl git@github.com:kovvalsky/LangPro.git` or `git clone --branch nl https://github.com/kovvalsky/LangPro.git`.
It is used for theorem-proving and converting type-logical terms into simply-typed terms.
Note that `nl` branch is relevant one.
Additionally add `--single-branch` if you want to clone only `nl` branch.


`produce.ini` contains rules how to generate files.
You will need to install [produce](https://github.com/texttheater/produce) if you want to use the rules to build files from scratch.

# HowTo

## Theorem proving SICK-NL problems
Before proving the problems, either enter the prolog interactive mode (recommended for a demo usage):
```
% loading the prover with alpino (or npn_robbert) trees
$ swipl -f prolog/main.pl  SICK_NL/sen.pl  SICK_NL/parses/alpino.pl  WNProlog/wn.pl
% This can be run only in the beginning, to set the global parameters: the part of the dataset, language flag, lexical annotation file, and theorem proving parameters 
?- parList([parts([train]), lang(nl), anno_json('SICK_NL/anno/alpino.json'), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck]).
% Run LangPro in the graphical mode with aligned terms (if the prove is found, it is most probably done with aligned terms as this mode is tested first for efficiency reasons.)
```
Or run the prolog goals directly from the terminal:
```
$ swipl -g "PROLOG_PREDICATES_TO_BE_CHECKED" -t halt -f prolog/main.pl  SICK_NL/sen.pl  SICK_NL/parses/alpino.pl  WNProlog/wn.pl
```

### Prove a particular problem without abductive training

```
% In an interactive mode, prove a problem and pretty display the proof in a separate window
?- gentail(aligned, 8502).
Tableau for "yes" checking is generated with Ter,6 ruleapps
XP: [isa(man,persoon),isa(meer,water)]
true.
```
### Prove a particular problem without abductive training

## Generate typed terms in LaTeX/PDF
### For all sentences filtered with a label or a part

The rule uses the corresponding json annotation file and parse terms from a parser (`npn_robbert` or `alpino`) to obtain annotated simply-typed terms and format them in LateX. The `trial` part keeps only those terms whose sentences occur in the TRIAL part of SICK. Usually it is good to use a filter otherwise files tend to be >15MB and its later compilation into PDF will take long time. Other options for filter are `yes` (problems with `entailment` label), `no` (problems with `contradiction` label), `unknown` (problems with `neutral` label), `train`, `test`, and `all` (i.e. no filters).

```
produce -d -f produce.ini  SICK_NL/latex/npn.spacy_sm.trial.tex
```

If you want additionally to `tex` file to create `pdf` from it, run:

```
produce -d -f produce.ini  SICK_NL/latex/npn.spacy_sm.trial.pdf
```
The conversion uses `lualatex` as it is faster than `pdflatex` and can deal with huge files (well, at least on my machine:)).

### For a specific NLI problem
Create a pdf that depicts how initial trees are converted into the final trees for the sentences of an NLI problem with a specific ID (e.g., 1333).
```
produce -d -b -f produce.ini   SICK_NL/latex/npn.spacy_lg.1333.pdf
```
