from Parser.neural.inference import get_model
from Parser.parsing.postprocessing import Analysis
from tqdm import tqdm

from LassyExtraction.terms import *
from LassyExtraction.milltypes import *
from LassyExtraction.aethel import ProofNet

from typing import Optional as Maybe

from itertools import accumulate


def type_to_natlog(wordtype: WordType) -> str:
    if isinstance(wordtype, AtomicType):
        return wordtype.type.lower()
    if isinstance(wordtype, FunctorType):
        return f'({type_to_natlog(wordtype.argument)}) ~> ({type_to_natlog(wordtype.result)})'
    if isinstance(wordtype, DiamondType):
        return wordtype.modality.lower() + ':{' + f'{type_to_natlog(wordtype.content)}' + '}'
    if isinstance(wordtype, BoxType):
        return wordtype.modality.lower() + ':[' + f'{type_to_natlog(wordtype.content)}' + ']'
    raise TypeError(f'Unexpected argument {wordtype} of type {type(wordtype)}')


def term_to_natlog(term: Term) -> str:
    if isinstance(term, Var):
        return f'v(X{term.idx},{type_to_natlog(term.t())})'
    if isinstance(term, Lex):
        return f't({term.idx},{type_to_natlog(term.t())})'
    if isinstance(term, Application):
        return f'(({term_to_natlog(term.functor)}) @ ({term_to_natlog(term.argument)}))'
    if isinstance(term, DiamondIntro):
        return '({' + f'{term.diamond}' + '}:' + f'{term_to_natlog(term.body)})'
    if isinstance(term, DiamondElim):
        return '({' + f'{term.diamond}' + '}-' + f'{term_to_natlog(term.body)})'
    if isinstance(term, BoxIntro):
        return f'([{term.box}]:{term_to_natlog(term.body)})'
    if isinstance(term, BoxElim):
        return f'([{term.box}]-{term_to_natlog(term.body)})'
    if isinstance(term, Abstraction):
        return f'(abst({term_to_natlog(term.abstraction)},{term_to_natlog(term.body)}))'
    raise TypeError(f'Unexected term {term} of type {type(term)}')


def parse_file(sick_file: str = '/home/kokos/Projects/sick_nl/data/tasks/sick_nl/SICK_NL.txt') \
        -> tuple[list[str], list[tuple[int, int, int, str]]]:
    all_lines: list[str] = []
    all_samples: list[tuple[int, int, int, str]] = []
    with open(sick_file, 'r') as f:
        next(f)
        for line in tqdm(f):
            (index, sentence_a, sentence_b, entailment_label, _, ab, ba, _, _, _, _, _) = line.split('\t')
            if sentence_a not in all_lines:
                all_lines.append(sentence_a)
            if sentence_b not in all_lines:
                all_lines.append(sentence_b)
            all_samples.append((int(index), all_lines.index(sentence_a), all_lines.index(sentence_b), entailment_label))
    return all_lines, all_samples


model = get_model('cuda')


def extract_valid(analyses: list[Analysis]) -> list[ProofNet]:
    potentially = [a for a in analyses if a.valid()]
    nets = list(filter(parsable, [a.to_proofnet() for a in potentially]))
    return nets


def parse_sents(sentences: list[str], batch_size: int = 256, beam_size: int = 8) -> list[list[ProofNet]]:
    out = []
    batch = []
    for i, sentence in tqdm(enumerate(sentences)):
        batch.append(sentence)
        if len(batch) == batch_size or i == len(sentences) - 1:
            analyses = model.infer(batch, beam_size)
            out.extend(list(map(extract_valid, analyses)))
            batch = []
    return out


def write_lines(samples: list[tuple[int, int, int, str]], nets: list[list[ProofNet]], output: str):

    def print_sent(net: ProofNet) -> Maybe[tuple[str, Term]]:
        def fix(w: str) -> str:
            return "'" + w.replace("'", "\\'").strip(',.') + "'"

        def print_mw(ws: List[str]) -> str:
            return '[' + ', '.join(map(fix, ws)) + ']'

        words, types = net.proof_frame.get_words(), net.proof_frame.get_types()
        merged = merge_multi_crd(words, types)
        if merged is None:
            return None
        words2, types2, red = merged
        return ('[' + ', '.join([print_mw(w.replace('_', ' ').split()) for w in words2]) + ']',
                offset_term(net.get_term(), red))

    with open(output, 'w') as f:
        f.write(':- op(605, xfy, ~>). % more than : 600\n')
        f.write(':- op(605, yfx, @).   % more than : 600\n\n')
        for idx_s, idx_a, idx_b, _ in samples:
            ns_a = nets[idx_a]
            ns_b = nets[idx_b]
            for na in ns_a:
                temp = print_sent(na)
                if temp is None:
                    continue
                rep, term = temp
                f.write(f'prob_sen({str(idx_s)}, \'p\',\n')
                f.write(f'({term_to_natlog(term)})' + ',\n')
                f.write(rep + '\n')
                f.write(').\n\n')
            for nb in ns_b:
                temp = print_sent(nb)
                if temp is None:
                    continue
                rep, term = temp
                f.write(f'prob_sen({str(idx_s)}, \'h\',\n')
                f.write(f'({term_to_natlog(term)})' + ',\n')
                f.write(rep + '\n')
                f.write(').\n\n')


def main(sick_file: str = '/home/kokos/Projects/sick_nl/data/tasks/sick_nl/SICK_NL.txt',
         batch_size: int = 256, beam_size: int = 6, out_file: str = './parsed_sick.txt'):
    sents, samples = list(parse_file(sick_file))
    nets = parse_sents(sents, batch_size, beam_size)
    nets = [[net for net in sent if parsable(net)] for sent in nets]
    import pickle
    with open('./npn_nets.p', 'wb') as f:
        pickle.dump((sents, nets, samples), f)
    import pdb
    pdb.set_trace()
    write_lines(sents, nets, out_file)


def process_with_alpino(sick_file: str = '/home/kokos/Projects/sick_nl/data/tasks/sick_nl/SICK_NL.txt'):
    from LassyExtraction.lassy import Lassy
    from LassyExtraction.main import transformer, prover, extractor
    from LassyExtraction.transformations import order_nodes
    from .data.preprocessing import collate_type

    lassy = Lassy(root_dir='/home/kokos/Projects/Alpino', treebank_dir='/xml')
    pnets = []

    def get_id(sname):
        return sname.split('.')[-4]

    for sample in lassy:
        dags = transformer(sample[2], meta={'src': sample[1]})
        if len(dags) != 1:
            continue
        typed = extractor(dags[0])
        if typed is None:
            continue
        proved = prover(typed)
        if proved is None:
            continue
        dag, links = proved
        words = [dag.attribs[leaf]['word'] for leaf in order_nodes(dag, dag.get_leaves())]
        types = [collate_type(dag.attribs[leaf]['type']) for leaf in order_nodes(dag, dag.get_leaves())]
        pnets.append(ProofNet.from_data(words, types, links, get_id(sample[1])))
    sents, samples = list(parse_file(sick_file))
    nets = []
    for i in range(len(sents)):
        nets.append([pn for pn in pnets if int(pn.name) - 1 == i])
    nets = [[pn for pn in sent if parsable(pn)] for sent in nets]
    import pdb
    pdb.set_trace()
    write_lines(samples, nets, './alpino.pl')


def parsable(pn: ProofNet) -> bool:
    try:
        ps, ns = list(zip(*pn.axiom_links))
        assert len(set(ps)) == len(set(ns)) == len(pn.axiom_links)
        assert count_words(pn.get_term()) == len([w for w, t in zip(pn.proof_frame.get_words(),
                                                                    pn.proof_frame.get_types())
                                                  if not isinstance(t, EmptyType)])
        return True
    except (ValueError, AssertionError, KeyError, AttributeError):
        return False


def count_words(term: Term) -> int:
    if isinstance(term, Var):
        return 0
    if isinstance(term, Lex):
        return 1
    if isinstance(term, Abstraction):
        return count_words(term.body)
    if isinstance(term, Application):
        return count_words(term.argument) + count_words(term.functor)
    else:
        return count_words(term.body)


def merge_multi_crd(words: List[str], types: List[WordType]) -> Maybe[Tuple[List[str], List[WordType], List[int]]]:
    # distinguish between crd and det case
    rw, rt, red = [], [], []
    empties = []
    adj = False
    for w, t in zip(reversed(words), reversed(types)):
        if isinstance(t, EmptyType):
            empties.append(w)
            adj = True
            red.append(1)
        elif empties:
            if adj and isinstance(t, BoxType) and t.modality == 'det':
                e = empties.pop()
                rw.append(f'{w} {e}')
                rt.append(t)
                adj = False
                red.append(0)
            elif isinstance(t, FunctorType) and isinstance(t.argument, DiamondType) and t.argument.modality == 'cnj':
                e = empties.pop()
                rw.append(f'{w} {e}')
                rt.append(t)
                red.append(0)
            else:
                rw.append(w)
                rt.append(t)
                adj = False
                red.append(0)
        else:
            rw.append(w)
            rt.append(t)
            adj = False
            red.append(0)
    if empties:
        return None
    return list(reversed(rw)), list(reversed(rt)), list(accumulate(reversed(red)))


def offset_term(term: Term, acc: list[int]) -> Term:
    if isinstance(term, Application):
        return Application(offset_term(term.functor, acc), offset_term(term.argument, acc))
    if isinstance(term, Abstraction):
        return Abstraction(offset_term(term.body, acc), term.abstraction.idx)
    if isinstance(term, DiamondElim):
        return DiamondElim(offset_term(term.body, acc))
    if isinstance(term, BoxElim):
        return BoxElim(offset_term(term.body, acc))
    if isinstance(term, DiamondIntro):
        return DiamondIntro(offset_term(term.body, acc), term.diamond)
    if isinstance(term, BoxIntro):
        return BoxIntro(offset_term(term.body, acc), term.box)
    if isinstance(term, Var):
        return term
    if isinstance(term, Lex):
        return Lex(term.t(), term.idx - acc[term.idx])
    raise TypeError
