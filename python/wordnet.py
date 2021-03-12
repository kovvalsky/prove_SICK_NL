from OpenDutchWordnet import Wn_grid_parser
from tqdm import tqdm

from typing import NamedTuple


class Lex(NamedTuple):
    id:         str
    lemma:      str
    pos:        str
    sense_id:   str
    sense_nr:   int
    synset_id:  str


Binary = tuple[str, str]
hypers: set[Binary] = set()
antos:  set[Binary] = set()
synos:  set[Binary] = set()
xsynos: set[Binary] = set()
lexes:  set[Lex] = set()


_hyper, _anto, _syno, _xsyno = 'has_hyperonym', 'near_antonym', 'near_synonym', 'xpos_near_synonym'


parser = Wn_grid_parser(Wn_grid_parser.odwn)
parser.clean_remove_synsets_without_relations(parser.synsets_get_generator())


lex_gen = parser.les_get_generator()
for lex in tqdm(lex_gen):
    lex_id = lex.get_id()
    lemma = lex.get_lemma()
    pos = lex.get_pos()[0]
    sense_id = lex.get_sense_id()
    sense_nr = lex.get_sense_number()
    synset_id = lex.get_synset_id()
    if synset_id is None:
        continue
    lexes.add(Lex(lex_id, lemma, pos, sense_id, int(sense_nr), synset_id))

used_synsets = set(map(lambda lex: lex.synset_id, lexes))

synset_gen = parser.synsets_get_generator()
for synset in tqdm(synset_gen):
    source = synset.get_id()
    if source not in used_synsets:
        continue
    for target in map(lambda hyper: hyper.get_target(), synset.get_relations(_hyper)):
        if target not in used_synsets:
            continue
        hypers.add((source, target))
    for target in map(lambda anto: anto.get_target(), synset.get_relations(_anto)):
        if target not in used_synsets:
            continue
        antos.add((source, target))
        antos.add((target, source))
    for target in map(lambda syno: syno.get_target(), synset.get_relations(_syno)):
        if target not in used_synsets:
            continue
        synos.add((source, target))
        synos.add((target, source))
    for target in (map(lambda xsyn: xsyn.get_target(), synset.get_relations(_xsyno))):
        if target not in used_synsets:
            continue
        xsynos.add((source, target))
        xsynos.add((target, source))


def escape(x: str) -> str:
    return x.replace("'", "\'")


def print_lexes(path: str = './wn_s.pl'):
    with open(path, 'a') as f:
        for lex in lexes:
            f.write(f's("{lex.synset_id}", _, "{lex.lemma}", "{lex.pos}", {lex.sense_nr}, _).\n')


def print_hypers(path: str = './wn_hyp.pl'):
    with open(path, 'a') as f:
        for hyp in hypers:
            f.write(f'hyp("{hyp[0]}", "{hyp[1]}").\n')


def print_antos(path: str = './wn_ant.pl'):
    with open(path, 'a') as f:
        for anto in antos:
            f.write(f'ant("{anto[0]}", _, "{anto[1]}", _).\n')


def print_synos(path: str = './wn_sim.pl'):
    with open(path, 'a') as f:
        for syno in synos:
            f.write(f'sim("{syno[0]}", "{syno[1]}").\n')


def print_xsynos(path: str = './wn_der.pl'):
    with open(path, 'a') as f:
        for syno in synos:
            f.write(f"sim('{escape(syno[0])}', _, '{escape(syno[1])}', _).\n")