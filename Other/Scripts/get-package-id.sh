#!/bin/bash

function check_if { (
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

  readonly PKG_INFO=PackageInfo
  local PKG=$(cd "$(dirname "$1")"; pwd)/$(basename "$1")
  local EXCLUDES=

  local TEMP=$(mktemp -t hoge | tr -d '\r')
  rm -rf "$TEMP"
  mkdir -p "$TEMP"
  cd "$TEMP"
  xar -x -f "$PKG" $EXCLUDES

  if [ ! -e "$PKG_INFO" ]; then
    cat Distribution | python "$DIR"/../helpers/check-if-pkg-installed.py "TEST"
    return 1
  fi
  cat $PKG_INFO | tr -d '\r' | tr -d '\n' | sed 's:^.*identifier="\([^"]*\)[.]pkg".*$:\1:g'
  cd $(dirname "$TEMP")
  rm -rf "$TEMP"
) }

get_package_id "$@"
