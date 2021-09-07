#!/usr/bin/env python3
# -*- coding: utf8 -*-
'''Print a list of fixing rules per sentence'''

import re
import sys
from collections import Counter

if __name__ == '__main__':
    # count fixing rules per problem
    sen_id, rules = None, None
    sid_rule_stats = []
    for line in sys.stdin:
        l = line.strip()
        if re.match('\d+$', l):
            if sen_id and rules:
                total = sum(rules.values())
                sid_rule_stats.append((sen_id, total, len(rules), rules))
            sen_id = l
            rules = Counter()
        elif re.match('.+ Fix:.+', l):
            rules.update([l])

    # read id and raw sentecnes from sen.pl
    id_raw = dict()
    with open(sys.argv[1]) as F:
        for l in F:
            m = re.match("sen_id\((\d+).+ '(.+)'\).", l)
            if m:
                i, raw = m.groups()
                id_raw[i] = raw

    # print sentecnes with most fixes
    sid_rule_stats = sorted(sid_rule_stats, key=lambda x: (x[2], x[1]))
    for sid, tot_rules, diff_rules, rules in sid_rule_stats:
        all_rules = '\n'.join(sorted(rules))
        if "eta-reduction for Conj" not in all_rules: continue
        print(f"{sid}: {id_raw[sid]}\n{tot_rules} {diff_rules}\n{all_rules}")
