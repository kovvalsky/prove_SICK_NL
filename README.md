# prove_SICK_NL
Prove Ducth NLI problems of SICK-NL with LangPro

# Prerequisites

Get Langpro repo with 
`git clone --branch nl git@github.com:kovvalsky/LangPro.git` or `git clone --branch nl https://github.com/kovvalsky/LangPro.git`.
It is used for theorem-proving and converting type-logical terms into simply-typed terms. Note that `nl` branch is rekevant one.
Additionally add `--single-branch` if you want to clone only `nl` branch.


`produce.ini` contains rules how to generate files.
You will need to install [produce](https://github.com/texttheater/produce) if you want to use the rules to build files from scratch.

# HowTo
## Generate typed terms in LaTeX/PDF

The rule uses the corresponding json annotation file and parse terms from a parser (`npn` or `alpino`) to obtain annotated simply-typed terms and format them in LateX. The `trial` part keeps only those terms whose sentences occur in the TRIAL part of SICK. Usually it is good to use a filter otherwise files tend to be >15MB and its later compilation into PDF will take long time. Other options for filter are `yes` (problems with `entailment` label), `no` (problems with `contradiction` label), `unknown` (problems with `neutral` label), `train`, and `test`.

```
produce -d -f produce.ini  SICK_NL/latex/npn.spacy_sm.trial.tex
```

If you want additionally to `tex` file to create `pdf` from it, run:

```
produce -d -f produce.ini  SICK_NL/latex/npn.spacy_sm.trial.pdf
```
