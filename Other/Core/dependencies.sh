## dependencies.sh

## Download Packages
## Download configured packages
function download_packages() {
  printf "\n"
  print_color "Downloading packages." "$CYAN"

  for URL in "${PACKAGES_TO_DOWNLOAD[@]}"; do
    print_color "Downloading package from ${URL}" "$YELLOW"
    /usr/local/bin/wget -nc -q -P "./Packages/" "$URL" &>"$DEBUG_LOG"
  done

  print_color "Successfully downloaded packages." "$GREEN"
}

## Download CLI Tools
## Downloads the Xcode Command Line tools
function download_cli_tools() {
  printf "\n"
  print_color "Downloading Xcode Command Line Tools" "$CYAN"
  if [ ! -f './Packages/Command Line Tools.pkg' ]; then
    {
      /usr/local/bin/wget -nc --cookies=on --load-cookies="$CLI_TOOLS_COOKIES" --keep-session-cookies --save-cookies="$CLI_TOOLS_COOKIES" -P Other/Downloads "$CLI_TOOLS"
      /usr/bin/hdiutil attach Other/Downloads/Command_Line_Tools_for_Xcode_11.4.1.dmg
      /bin/cp /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg ./Packages/
      /usr/bin/hdiutil detach /Volumes/Command\ Line\ Developer\ Tools
    } >> "$DEBUG_LOG" 2>&1
  fi

  print_color "Successfully downloaded Xcode Command Line Tools." "$GREEN"
}

## Download Scripts
## Download configured scripts
function download_scripts() {
  printf "\n"
  print_color "Downloading scripts." "$CYAN"

  for URL in "${SCRIPTS_TO_DOWNLOAD[@]}"; do
    print_color "Downloading script from ${URL}" "$YELLOW"
    /usr/local/bin/wget -nc -q -P "./Scripts/" "$URL" &>"$DEBUG_LOG"
  done

  print_color "Successfully downloaded scripts." "$GREEN"

  print_color "Correcting permissions on scripts." "$CYAN"
  /bin/chmod +x ./Scripts/*
  /usr/sbin/chown -R "$REGULAR_USER" ./Scripts

  print_color "Corrected permissions on scripts." "$GREEN"
}

## Download Wallpaper
## Clone wallpaper repository
function download_wallpaper() {
  printf "\n"
  if [ -f './Wallpaper/Loaded.jpg' ]; then
    print_color "Wallpaper already downloaded. Checking for updates.." "$CYAN"
    cd Wallpaper || return
    /usr/bin/git pull >>../"$DEBUG_LOG" 2>&1
    cd ../
  else
    print_color "Downloading wallpaper" "$CYAN"
    /usr/bin/git clone "$WALLPAPER_REPO" Wallpaper
  fi

  /usr/sbin/chown -R "$REGULAR_USER" ./Wallpaper
  print_color "Successfully downloaded wallpaper." "$GREEN"
}

## Download Applications
## Clone pre-built applications repository
download_applications() {
  printf "\n"
  if [ -f './Applications/.gitignore' ]; then
    print_color "Applications already downloaded. Checking for updates.." "$CYAN"
    cd Applications || return
    /usr/bin/git pull >>../"$DEBUG_LOG" 2>&1
    cd ../
  else
    /bin/rm -rf ./Applications
    print_color "Downloading applications" "$CYAN"
    /usr/bin/git clone "$APPLICATIONS_REPO" Applications
  fi

  print_color "Successfully downloaded applications." "$GREEN"
}

## Download pycreateuserpackage
## Downloads the `pycreateuserpkg` tool
function download_pycreateuserpackage() {
  printf "\n"
  print_color "Downloading pycreateuserpkg" "$CYAN"

  /bin/mkdir -p ./Other/Helpers/

  RETURN_TO="$PWD"

  if [ -f './Other/Helpers/pycreateuserpkg/.gitignore' ]; then
    print_color "pycreateuserpkg already downloaded. Checking for updates.." "$CYAN"
    cd ./Other/Helpers/pycreateuserpkg || return
    /usr/bin/git pull >>"$RETURN_TO"/ "$DEBUG_LOG" 2>&1
    cd "$RETURN_TO" || return
  else
    /bin/rm -rf ./Other/Helpers/pycreateuserpkg
    print_color "Downloading pycreateuserpkg" "$CYAN"
    /usr/bin/git clone "$PYCREATEUSERPKG_URL" ./Other/Helpers/pycreateuserpkg >>"$RETURN_TO"/ "$DEBUG_LOG" 2>&1
  fi

  print_color "Successfully downloaded pycreateuserpkg." "$GREEN"
}

## Download Depencencies
## Downloads everything
function download_dependencies() {
  download_packages &&
    download_scripts &&
    download_wallpaper &&
    download_applications &&
    download_pycreateuserpackage &&
    download_cli_tools
}
