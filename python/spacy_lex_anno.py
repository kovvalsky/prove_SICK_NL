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

    # annotated sentences
    sen_annotations = OrderedDict()
    for i, sen in enumerate(sentences, start=1):
        if args.ids and i not in args.ids: continue
        sen_annotations[i] = []
        d = nlp(sen)
        for t in d:
            tok = OrderedDict([('t', t.text), ('l', t.lemma_), ('p', t.pos_)])
            sen_annotations[i].append(tok)

    # write annotations in a json format
    write_json(args.json, sen_annotations)
