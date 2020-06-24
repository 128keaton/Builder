#!/usr/bin/python

import json, sys

with open('.mount.json') as f:
    data = json.load(f)

if data and data['system-entities']:
    for entity in data['system-entities']:
        if entity['potentially-mountable'] and 'mount-point' in entity \
                                           and 'VM' not in entity['mount-point'] \
                                           and 'Recovery' not in entity['mount-point'] \
                                           and 'Preboot' not in entity['mount-point'] \
                                           and '- Data' not in entity['mount-point']:
            print(entity['mount-point'])
