#!/usr/bin/python

import sys, os, select, subprocess
import xml.etree.ElementTree as etree


def getPackageID(path):
    xmlString = ""
    xmlString = xmlString.join(path)
    foundIDs = []
    installedIDs = []

    root = etree.fromstring(xmlString)
    for child in root:
        if child.tag == 'pkg-ref' and 'id' in child.attrib and 'version' in child.attrib:
            if child.attrib['id'] not in foundIDs and '.' in child.attrib['id']:
                if 'installKBytes' not in child.attrib or 'installKBytes' in child.attrib and child.attrib['installKBytes'] != '0':
                    foundIDs.append(child.attrib['id'])

    try:
        for pkgID in foundIDs:
            installedIDs.append(subprocess.check_output(['pkgutil', '--pkgs=' + pkgID, '--volume', "/Volumes/macOS Utilities"]).strip('\n'))
    except subprocess.CalledProcessError:
        return False

    return len(installedIDs) == len(foundIDs)


if __name__ == "__main__":
    if select.select([sys.stdin, ], [], [], 0.0)[0] and len(sys.argv) == 2:
        alreadyInstalled = getPackageID(sys.stdin)
        print(alreadyInstalled)
        sys.exit(0)
    elif len(sys.argv) == 0:
        sys.exit('No volume passed')
    elif len(sys.argv) > 2:
        sys.exit('Only one parameter is accepted, volume')
    else:
        sys.exit('No input')
