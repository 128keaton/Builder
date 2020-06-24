#!/bin/bash

URL_PATTERN='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

# shellcheck disable=SC2164
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PLIST_PATH="$SCRIPT_PATH/../../Configuration/build.plist"

APP_URL=$1

if [[ $APP_URL =~ $URL_PATTERN ]]; then
  UNESCAPED_APP_NAME=$(basename "$APP_URL.app")
  APP_NAME=${UNESCAPED_APP_NAME//./\\.}

  # shellcheck disable=SC2086
  if ! /usr/bin/plutil -insert $APP_NAME -xml $APP_URL $PLIST_PATH &>/dev/null; then
    echo "Could not add app '$UNESCAPED_APP_NAME' to 'build.plist', check for duplicates?"
    exit 1
  fi

  echo "Added app '$UNESCAPED_APP_NAME' from '$APP_URL' to 'build.plist'!"
else
  echo "URL '$APP_URL' is not a valid URL."
fi
