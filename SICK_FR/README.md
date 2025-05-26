# French SICK

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


## Knowledge base

Currently dedicated knowledge base for French is missing.
`SICK_FR/knowledge.pl` contains samples pf relations that are useful for solving SICK problems.
These samples are cherry-picked from the knowledge induced with the abduction learning on the SICK-train and -trial parts.  
It would be useful to use JDM database as KB for LangPro.
The below list can be used as a guide how to extract relations from JDM.

```txt
head SICK_FR/knowledge.pl
%%%%%%%%%%%%%%% Samples from Induced Knowledge %%%%%%%%%%%%%%%%
ind_rel(isa_wn(éplucher,peler)).                    % 1659,1660,4992,5799
ind_rel(isa_wn(skateur,skateboarder)).              % 9303
ind_rel(isa_wn(roller,rollerblader)).               % 7064
ind_rel(isa_wn(regarder,vérifier)).                 % 3938
ind_rel(isa_wn(océan,eau)).                         % 9069
ind_rel(isa_wn(nourriture,repas)).                  % 5110
ind_rel(isa_wn(note,papier)).                       % 4360
ind_rel(isa_wn(homme,personne)).                    % 1373,1677,1723,2030,2091,2391
ind_rel(isa_wn(haltère,poids)).                     % 2896,2898
```

Each sample relation comes with problem IDs for which it makes difference.
If we run LangPro on all the mentioned problems with cherry-picked relations, all the problems gets solved:

```txt
# using the relation file as input
$ swipl  -f prolog/main.pl  SICK_FR/knowledge.pl  SICK_FR/sick_langpro_input_prolog.pl  SICK_FR/sick_fr_id.pl
% making trial and train parts available and explicitly telling to use induced knowledge with the ind_kb flag, i.e., to use relations from ind_rel(...)
?- parList([parts([trial,train]), lang(fr), complete_tree, allInt, aall, wn_ant, wn_sim, wn_der, constchck, ind_kb]).
% prove the 52 problems, which require the sample relations
?- entail_some([1659,1660,4992,5799,9303,7064,3938,9069,5110,4360,1373,1677,1723,2030,2091,2391,2896,2898,2509,3395,5358,5361,2708,2710,3795,3800,1373,1677,1723,2030,2091,2391,8163,2615,2910,4015,5362,6308,8219,8806,9033,9644,4342,1640,4611,7896,1046,9070,1747,868,3367,3405]).
```

## Running abduction

Run abductive learning on the SICK-train and -trial parts, and whatever relations will be learned, use them to prove problems from the SICK-test.
The learned relations can be found in the created `*_KB.pl` file or in the log file.

```bash
$ produce -b -d -f produce.ini  Results/fr/abd_eva/TD_E/r50,c0_ab,ch,cKB,cT,p123.log
```

Currently, as of May 26, the results with abduction and without dedicated FR KB are not high:  
SICK-test accuracy 71.1 with precision 96.8.  
SICK-train+trial accuracy 76.9 with precision 98.6.

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

The French translation isn't wrong, but perhaps we should translate them as follows to maintain the distinction between the two original terms in English:

Un homme fait un trek dans les bois.

L'homme ne fait pas de randonnée dans les bois.

But in this case it will be with an anglicism.



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
