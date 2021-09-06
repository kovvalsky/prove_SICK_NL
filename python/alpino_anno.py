#!/usr/bin/env python3
# -*- coding: utf8 -*-

'''Extract token-level annotations from Alpino xml trees
'''

#################################
import argparse
from collections import OrderedDict
import xml.etree.ElementTree as ET
import os
from os import path as op
from utils import write_json

def parse_arguments():
    parser = argparse.ArgumentParser(\
        description='Extract annotations from Alpino xml trees')

    # Arguments covering directories and files
    parser.add_argument(
    'dir', metavar="DIR",
        help="A directory with alpino parses")
    parser.add_argument(
    'json', metavar="FILE_PATH",
        help="A json output file with annotations")
    parser.add_argument(
    '--ids', nargs='*', type=int, metavar="LIST OF IDS",
        help="A list of sentence IDs to be processed (starts from 1)")
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

    # read sen IDs and xml paths
    id_xml = { int(ixml.split('.')[0]): op.join(args.dir, ixml) \
                for ixml in os.listdir(args.dir) }

    # attributes to be extracted and mapped to shorted keys
    att_key_iter = list(zip('word lemma root sense pos pt lcat rel postag'.split(), \
                   't l r s p pt lcat rel postag'.split()))
    # parse xml files
    sen_annotations = OrderedDict()
    for i, xml in sorted(id_xml.items()):
        if args.ids and i not in args.ids: continue
        sen_annotations[i] = []
        r = ET.parse(xml).getroot()
        # tokens are elements with @word attribute, which have start and end
        toks = { (int(e.attrib['begin']), int(e.attrib['end'])): e \
                    for e in r.findall('.//node[@word]') }
        for _, t in sorted(toks.items()):
            tok = OrderedDict( (k, t.attrib[a]) for a, k in att_key_iter )
            sen_annotations[i].append(tok)

    if args.v >= 1:
        print(f"Annotations read from {len(sen_annotations)} files")

    # write annotations in a json format
    write_json(args.json, sen_annotations)
