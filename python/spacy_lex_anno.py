#!/usr/bin/env python3
# -*- coding: utf8 -*-

'''Annotated raw text with lemma and pos tags
'''

#################################
import spacy
import argparse
from collections import OrderedDict
import json
import re
from utils import write_json

from typing import List
from spacy.language import Language
from spacy.tokens import Token, Doc


def parse_arguments():
    parser = argparse.ArgumentParser(description='Token annotation with Spacy')

    # Arguments covering directories and files
    parser.add_argument(
    'raw', metavar="FILE_PATH",
        help="A file with a sentence per line")
    parser.add_argument(
    'json', metavar="FILE_PATH",
        help="A json output file with annotations")
    parser.add_argument(
    '-s', '--size', default='sm',
        choices=['sm', 'md', 'lg'], metavar="Spacy model",
        help="The space model size")
    parser.add_argument(
    '--ids', nargs='*', type=int, metavar="LIST OF IDS",
        help="A list of sentence IDs, i.e. line numbers, to be processed (starts from 1)")
    parser.add_argument(
    '-v', dest='v', action='count', default=0,
        help="Verbosity level")

    # pre-processing arguments
    args = parser.parse_args()
    return args


def parse_sents(model: Language, sents: List[str], ids: List[int]) -> OrderedDict[int, List[OrderedDict[str, str]]]:
    def parse_doc(doc: Doc) -> List[OrderedDict[str, str]]:
        def parse_tok(token: Token) -> OrderedDict[str, str]:
            return OrderedDict([('t', token.text), ('l', token.lemma_), ('p', token.pos_)] +
                               list(token.morph.to_dict().items()))
        return [parse_tok(token) for token in doc]
    docs = model.pipe(sents, disable=['parser', 'ner'], batch_size=128)
    return OrderedDict(zip(ids, (parse_doc(doc) for doc in docs)))


##############################################################################
################################ Main function ################################
if __name__ == '__main__':
    args = parse_arguments()
    m = { size: f"nl_core_news_{size}" for size in 'sm md lg'.split() }
    nlp = spacy.load(m[args.size])

    # read input
    with open(args.raw) as F:
        sentences = [ l.strip() for l in F ]
    if args.v >= 1: print(f"{len(sentences)} sentences are read")

    idxs, sentences = list(zip(*((i, s) for i, s in enumerate(sentences, start=1) if not args.ids or i in args.ids)))
    sen_annotations = parse_sents(nlp, sentences, idxs)

    # write annotations in a json format
    write_json(args.json, sen_annotations)
