## install.sh

## Install Packages
## Install configured packages to the NetBoot system
function install_packages() {
  if $SKIP_PACKAGE_INSTALL; then
    printf "\n"
    print_color "--skip-packages was passed, so we are not installing packages" "$YELLOW"
    create_dyld_caches
  else
    printf "\n"
    print_color "Installing Packages..." "$CYAN"
    print_color "Log available at $PWD/$INSTALLER_LOG" "$MAGENTA"
    echo >"$INSTALLER_LOG"

    for PKG in ./Packages/*; do
      PKG_NAME=$(basename "$PKG")
      PKG_NAME="${PKG_NAME%.*}"
      PKG_ALREADY_INSTALLED=$(pkg_is_installed "$PKG" "$NETBOOT_MOUNT_PATH")

      /usr/sbin/chown -R "$REGULAR_USER" "$PKG"
      /bin/chmod -R 755 "$PKG"

      if [[ $PKG_ALREADY_INSTALLED == *"true"* ]]; then
        printf "\n"
        print_color "Package '$PKG_NAME' is already installed. Skipping." "$GREEN"
      else
        printf "\n"
        print_color "Installing package '$PKG_NAME'." "$BLUE"
        PROGRESS="0"

        # Info from http://www.manpagez.com/man/8/installer/osx-10.4.php
        /usr/sbin/installer -pkg "$PKG" -target "$NETBOOT_MOUNT_PATH" -verboseR | while read -r line; do
          echo "$line" >>"$INSTALLER_LOG"

          STATUS=$(echo "$line" | awk -F":" '/PHASE:/ { print $3}')

          if [[ "$line" == *"%"* ]]; then
            PROGRESS=$(echo "$line" | grep -oh '\%\d*\.\d*' | sed 's/%//')
          fi

          if [ -n "$PROGRESS" ]; then
            PROGRESS=${PROGRESS%.*}
            prog "$PROGRESS" "$STATUS"
          fi
        done
      fi
    done

    printf "\n"
    print_color "Installed packages successfully" "$GREEN"
  fi
}

## Install Applications
## Install the configured applications to the NetBoot system
function install_applications() {
  AVAILABLE_APPLICATIONS=$(/usr/bin/find "$PWD/Applications" -name "*.app")

  echo "$AVAILABLE_APPLICATIONS" >> "$DEBUG_LOG"

  printf "\n"
  print_color "Installing applications.." "$CYAN"

  for APP in "$PWD"/Applications/*.app; do # Whitespace-safe but not recursive.
    APP_NAME=$(basename "$APP")
    print_color "Installing application '$APP_NAME'." "$CYAN"

    /bin/mkdir -p "$NETBOOT_MOUNT_PATH/Applications/$APP_NAME"
    /usr/bin/ditto "$APP" "$NETBOOT_MOUNT_PATH/Applications/$APP_NAME"

    print_color "Installed" "$GREEN"
    printf "\n"
  done

  print_color "Successfully installed applications." "$GREEN"
}


## Package Is Installed
## Helper function for the install_packages function. Determines if a package is installed or not on the NetBoot system
function pkg_is_installed() {
  readonly PKG_INFO=PackageInfo
  readonly RETURN_TO="$(PWD)"
  IS_INSTALLED="false"

  PKG=$(
    cd "$(dirname "$1")" || return
    pwd
  )/$(basename "$1")
  TEMP=$(mktemp -t hoge | tr -d '\r')

  rm -rf "$TEMP"
  mkdir -p "$TEMP"
  cd "$TEMP" || return
  xar -x -f "$PKG"

  if [ -f 'Distribution' ] && [[ $PKG != *"InstallScripts.pkg"* ]] && [[ $PKG != *"UserSetup.pkg"* ]]; then
    IS_INSTALLED=$("$RETURN_TO"/Other/Helpers/check-if-pkg-installed.py "$NETBOOT_MOUNT_PATH" <Distribution)
  fi

  cd "$(dirname "$TEMP")" || return
  rm -rf "$TEMP"
  cd "$RETURN_TO" || return
  echo "$IS_INSTALLED" | awk '{print tolower($0)}'
}


function install_everything() {
  install_packages
  install_applications
}
