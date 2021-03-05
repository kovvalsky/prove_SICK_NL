#!/usr/bin/env python3
# -*- coding: utf8 -*-

'''Utility functions
'''

#################################
import json


#################################
def write_json(filename, sen_annotations):
    '''write annotations in a json format. Each token on a separate line
    '''
    with open(filename, 'w') as F:
        anno_list = []
        for i, toks in sen_annotations.items():
            tokens = ',\n    '.join([ json.dumps(t, ensure_ascii=False) for t in toks ])
            anno_list.append(f'  "{i}": [\n    {tokens} ]')
        content = ',\n'.join(anno_list)
        F.write(f'{{\n{content}\n}}')
