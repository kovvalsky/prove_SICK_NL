# French SICK

## Issues

* No annotation information helps to distinguish plural nouns from singular. -> We have obtained this information independently with Stanza, it can be extracted from the file with Stanza's annotation and added next to the POS-tag in the prolog file of the sentences.
* pid=4816: `Il n'y a personne qui coupe un peu de gingembre`. Is this grammatical and non-ambiguous? Is here `personne` disambiguated as `nobody` because of the presence of `ne`? -> Yes, `personne ne` means `nobody` in French.


## Labels affected by translation

```
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
