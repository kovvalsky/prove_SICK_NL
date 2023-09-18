#!/usr/bin/env python3
# -*- coding: utf8 -*-

'''Convert Alpino trees from xml format into lambda terms in prolog format
'''

import os
import argparse
import sys
sys.path.extend(["../aethel"])
from scripts.langpro_interface import file_to_natlog

def parse_arguments():
    parser = argparse.ArgumentParser(\
        description='Convert Alpino xml trees to lambda prolog terms')

    # Arguments covering directories and files
    parser.add_argument(
    'dir', metavar="DIR",
        help="A directory with alpino parses in xml format where files are named as sen_id.xml")
    # parser.add_argument(
    # 'pl', metavar="FILE_PATH",
    #     help="A prolog file mapping ")
    parser.add_argument(
    '-v', dest='v', action='count', default=0,
        help="Verbosity level")

    # pre-processing arguments
    args = parser.parse_args()
    return args


def list_to_prolog_list(str_list):
    """ Takes a list (of list) of strings and returns a string representing a prolog term
    """
    def escape_single_quotes(s):
        return s.replace("'", r"\'")
    
    if isinstance(str_list, str):
        return f"'{escape_single_quotes(str_list)}'"
    
    if isinstance(str_list, list):
        return '[' + ', '.join([ list_to_prolog_list(el) for el in str_list ]) + ']'

##############################################################################
################################ Main function ################################
if __name__ == '__main__':
    args = parse_arguments()

    # print prolog preamble that defines operators used in terms
    print(""":- op(605, xfy, ~>). % more than : 600
:- op(605, yfx, @).   % more than : 600
""")

    if os.path.isdir(args.dir):    
        # print term and tokenization for each file
        for root, _, files in os.walk(args.dir):
            if files:
                sorted_file_ids = sorted([ int( os.path.splitext(f)[0]) for f in files ])
                for i in sorted_file_ids:
                    try:
                        term, tokens = file_to_natlog(os.path.join(root, f"{i}.xml"))
                        print(f"\nsen_id_tlg_tok({i},\n{term},\n{list_to_prolog_list(tokens)}\n).")
                    except Exception as e:
                        print(f"Couldn't parse {i}: {e}", file=sys.stderr)
                    continue
    elif os.path.isfile(args.dir):
        # if the path is file itself
        # used for testing and debugging
        term, tokens = file_to_natlog(args.dir)
        print(f"\nsen_id_tlg_tok(0,\n{term},\n{list_to_prolog_list(tokens)}\n).")

