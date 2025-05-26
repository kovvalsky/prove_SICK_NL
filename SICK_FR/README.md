# French SICK

## Issues

* No annotation information helps to distinguish plural nouns from singular.
* pid=4816: `Il n'y a personne qui coupe un peu de gingembre`. Is this grammatical and non-ambiguous? Is here `personne` disambiguated as `nobody` because of the presence of `ne`?


## Labels affected by translation

This lists problems that got such translations that the translated problems are not anymore compatible with the original SICK_EN inference labels.

```txt
pid=3181 EN is neutral but FR should be contradiction
A man is trekking in the woods
The man is not hiking in the woods
vs
Un homme marche dans les bois
L'homme ne marche pas dans les bois
```

## Solutions to FR challenges

### 🛠️ Insert a WH-pronoun for VPs of type `np->n->n`

To prove the contradiction such as below, one needs to relate `épluche:np->np->s` to `épluchant:np->n->n` but it is difficult because of their different types.
We convert `personne épluchant:np->n->n un oignon` into `personne WHICH:np->s->(n->n) épluchant:np->np->s un oignon`, which makes the connection between the verbs more transparent.

```txt
SICK_FR-3720  contradiction
P: Une personne épluche:np->np->s un oignon
H: Il n'y a pas de personne épluchant:np->n->n un oignon
```

`fix_term/2` in `LangPro\prolog\llf\ccgTerm_to_llf.pl` is responsible for it.

### 🛠️ Attach remote "ne" to "personne"

In sentences such as P below, `ne` is renamed to `no` and attached to `personne` so that the underlying logical form is `be (no (who ...) personne) there` where closed-class words are replaced with English.
With this it is possible to prove the contradiction below.

```txt
SICK_FR-4816  contradiction
P: Il n'y a personne qui coupe un peu de gingembre
H: Une personne coupe un peu de gingembre
```


`translate_mwe_fr2en/2` in `prove_SICK_NL/prolog/fr2en.pl` is responsible for it with `fix_term/2` from `LangPro\prolog\llf\ccgTerm_to_llf.pl`. 

### 🛠️ Predicative adjectives

In the English CCG, `be green` is analyzed as `be:(np->s:adj)->np->s:dcl green:np->s:adj` while in French `be:(n->n)->np->s:dcl green:n->n` seems to be a proffered analysis.
To accommodate the latter, the tableau rule `empty_mod` is extended, which discards `be:(n->n)->np->s:dcl` and changes the type of `green` to `np->s:adj`.  
The analysis is intuitive and that's why it was accommodated in the inference rules rather than rewriting the French terms in the English style.
This addition solves the problem such as:

```txt
SICK_FR-3812  entailment
P: Une femme tranche un poivre qui est vert
H: Une femme tranche un poivre vert
```

### 🛠️ Normalize French terms

This is not a big deal, but it is still worth mentioning.
French terms are not always in a beta normal form, e.g., 819-premise  
`Une personne en équipement de vélo est debout régulièrement en face de certaines montagnes`, which includes the subterm  
`(λx. régulièrement(est debout x)) Une_personne_en_équipement_de_vélo`.  
Before fixing any issues in the terms, first they are normalized.


## Analysis

[MElt tagset](https://almanach.inria.fr/software_and_resources/MElt-en.html)  
[FR tagset](https://www.cis.uni-muenchen.de/~schmid/tools/TreeTagger/data/french-tagset.html)

Stats of the 2nd pos tag, which is more informative than the 1st one.

```txt
  50725 NOM             -> NN (NNS?)
  35984 DET:ART         -> DT
  24269 PRP             -> IN
  20471 VER:pres        -> VB
   9416 ADJ             -> JJ
   5447 ADV             -> RB
   3886 KON             -> CC
   3394 PRP:det         ->
   3388 PRO:PER         -> PRP
   3201 VER:pper        -> VBN
   1876 NUM             -> CD
   1461 PRO:REL         -> WP
    832 PRO:IND         -> 
    645 VER:infi        -> VB
    636 VER:ppre        -> VB
    581 DET:POS         -> PRP$
    398 PUN             ->
    139 NAM             -> NNP
     29 ABR             ->
     24 PRO             -> PRP
     23 PRO:DEM         -> DT
     21 VER:simp        -> VBD
     18 VER:impf        ->
     14 VER:futu        ->
      2 VER:subp        ->
      2 SYM             ->
```
