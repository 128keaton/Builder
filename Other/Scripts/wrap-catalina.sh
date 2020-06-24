#!/bin/bash
# Create .dmg file for macOS

# Adapt these variables to your needs

DMG_NAME="Catalina"
OUTPUT_DMG_DIR="./"
APP_FILE="/Applications/Install macOS Catalina.app"


# The directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# The temp directory used, within $DIR
WORK_DIR=`mktemp -d "${DIR}/tmp"`

# Check if tmp dir was created
if [[ ! "${WORK_DIR}" || ! -d "${WORK_DIR}" ]]; then
    echo "Could not create temp dir"
    exit 1
fi

# Function to deletes the temp directory
function cleanup {
    rm -rf "${WORK_DIR}"
    #echo "Deleted temp working directory ${WORK_DIR}"
}

# Register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

# Copy application on temp dir
cp -R "${APP_FILE}" "${WORK_DIR}"

# Create .dmg
hdiutil create -volname "${DMG_NAME}" -srcfolder "${WORK_DIR}" -ov -format UDZO "${OUTPUT_DMG_DIR}/${DMG_NAME}.dmg"
hdiutil attach "${OUTPUT_DMG_DIR}/${DMG_NAME}.dmg"
