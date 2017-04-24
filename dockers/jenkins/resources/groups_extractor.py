#!/usr/bin/env python
import json
import sys

data = json.load(sys.stdin)

groups = ""
for P in data:
    groups+=P["key"]+",";
if groups.__len__() > 0:
    groups = groups[:-1]
print(groups)
