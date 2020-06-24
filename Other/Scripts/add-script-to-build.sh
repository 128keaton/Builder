#!/bin/bash

URL_PATTERN='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

# shellcheck disable=SC2164
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PLIST_PATH="$SCRIPT_PATH/../../Configuration/scripts.plist"

SCRIPT_URL=$1

if [[ $SCRIPT_URL =~ $URL_PATTERN ]]; then
  UNESCAPED_SCRIPT_NAME=$(basename "$SCRIPT_URL")
  SCRIPT_NAME=${UNESCAPED_SCRIPT_NAME//./\\.}

  # shellcheck disable=SC2086
  if ! /usr/bin/plutil -insert $SCRIPT_NAME -xml $SCRIPT_URL $PLIST_PATH &>/dev/null; then
    echo "Could not add script '$UNESCAPED_SCRIPT_NAME' to 'scripts.plist', check for duplicates?"
    exit 1
  fi

  echo "Added script '$UNESCAPED_SCRIPT_NAME' from '$SCRIPT_URL' to 'scripts.plist'!"
else
  echo "URL '$SCRIPT_URL' is not a valid URL."
fi
