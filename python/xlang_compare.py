#!/usr/bin/env python
# -*- coding: utf8 -*-

import argparse
import re
import sys
from collections import defaultdict
sys.path.append('LangPro/python')
from evaluate import read_id_labels, canonical_label
from termcolor import colored

#################################
def parse_arguments():
    parser = argparse.ArgumentParser(description="Compare predictions cross-translations")
    parser.add_argument(
    '--sys', required=True, metavar='FILE',
        help='File with problem ID, white space and label per line')
    parser.add_argument(
    '--ref', metavar='FILE',
        help="File with reference labels. If not specified, gold labels are reference")
    parser.add_argument(
    '--src', required=True, metavar='FILE',
        help="Prolog file containing problems in source/original language (e.g. EN)")
    parser.add_argument(
    '--trg', required=True, metavar='FILE',
        help="Prolog file containing problems in target/working language (e.g. NL)")
    parser.add_argument(
    '-m', '--mode', required=True, nargs=2, metavar='MODE',
        help=("A pair of set of predicted labels and a set of reference labels, "
              "e.g. 'N EC' means that prediction is N for E or C reference labels"))
    parser.add_argument(
    '-md', '--mode-diff', action='store_true',
        help=("Predicted and reference labels shoudl be different. "
              "This makes difference when a set of prediceted and reference "
              "labels intersect. 'N NEC' with -md will ignore 'N N' pairs."))
    # meta parameters
    parser.add_argument(
    '-v', '--verbose', dest='v', default=0, type=int, metavar='N',
        help='verbosity level of reporting')
    args = parser.parse_args()
    assert set(args.mode[0] + args.mode[1]).issubset(set('ENC')), \
        f"mode should be a pair of one of these E,N,C iitial letters of labels"
    return args

#################################
def read_nli_sen_pl(sen_pl):
    '''Read sen.pl file into a dictionary'''
    nli = defaultdict(dict)
    pattern = re.compile(r"sen_id\((\d+), (\d+), ('[ph]'), ('[^']+')?,? ?('[^']+'), ('.+')\).")
    with open(sen_pl) as F:
        for l in F:
            if not l.strip(): continue # ignore empty lines
            if l.strip().startswith('%'): continue # ignore prolog comments
            m = pattern.match(l)
            if m:
                _, pid, ph, part, label, sen = m.groups()
                nli[pid][ph.strip("'")] = sen.strip("'").replace("\\'", "'")
                nli[pid]['l'] = canonical_label(label.strip("'"))
                nli[pid]['part'] = part.strip("'") if part else part
    return nli

#################################
def print_comparison(modes, src, trg, pred, ref=None):
    mode, diff = modes
    pids = sorted([ int(i) for i in pred ])
    cnt = 0
    if ref:
        ref_is_gold = False
    else:
        ref = { i:trg[i]['l'] for i in trg }
        ref_is_gold = True
    for i in pids:
        i = str(i)
        assert i in src, f"{i}th problem not in src"
        assert i in trg, f"{i}th problem not in trg"
        assert i in ref, f"{i}th problem not in ref"
        if pred[i][0] in mode[0] and ref[i][0] in mode[1]:
            if diff and pred[i][0] == ref[i][0]:
                continue # skip pred=ref cases
            ref_lab = '' if ref_is_gold else f"-({ref[i][0]})"
            print(f"{i:>5}: {pred[i][0]}{ref_lab}-[{trg[i]['l']}]")
            print(colored(f"P:trg: {trg[i]['p']}", "cyan"))
            print(colored(f"  src: {src[i]['p']}", "red"))
            print(colored(f"H:trg: {trg[i]['h']}", "cyan"))
            print(colored(f"  src: {src[i]['h']}", "red"))
            cnt += 1
    print(f"Total printed problems: {cnt}")

#################################
if __name__ == '__main__':
    args = parse_arguments()
    src = read_nli_sen_pl(args.src)
    trg = read_nli_sen_pl(args.trg)
    #assert len(src) == len(trg), \
    #    f"src and trg data of different size ({len(src)}) vs ({len(trg)})"
    pred = read_id_labels(args.sys)
    ref = read_id_labels(args.ref) if args.ref else None
    # assert len(pred) == len(gold),\
    #     f"gold and pred of different size ({len(gold)} vs {len(pred)})"
    # print comparison of predictiosn and gold based on a comaprison mode
    print_comparison((args.mode,args.mode_diff), src, trg, pred, ref=ref)
