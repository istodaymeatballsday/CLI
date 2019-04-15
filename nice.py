# works both in python 3.7 and 2.7

import sys
import json

s = ''
for line in sys.stdin:
    s += line

for i, v in enumerate(json.loads(s)):
    print(v['displayNames'][1]['dishDisplayName'])
