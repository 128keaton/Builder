## Build Applications
## Expects application repos to have a `build.sh` script in the root.
## Take a look at https://github.com/128keaton/macOS-Utilities for a good example
build_applications() {
  printf "\n"
  print_color "Building applications. (${#APPLICATIONS_TO_BUILD[@]} total)" $CYAN

  RETURN_TO=$PWD
  /bin/mkdir -p ./Other/Build/Applications

  for REPO_URL in "${APPLICATIONS_TO_BUILD[@]}"; do
    CLONE_PATH=${REPO_URL##*/}
    NEEDS_BUILD=false
    APP_NAME=$(echo "$CLONE_PATH" | tr "-" " ").app
    cd ./Other/Build/Applications || return

    if [ ! -f "./$CLONE_PATH/.gitignore" ]; then
      printf "\n"
      print_color "The repo for '$APP_NAME' was not already cloned in applications. Cloning now." $MAGENTA
      /usr/bin/git clone "$REPO_URL" "$CLONE_PATH" &>/dev/null
      cd "$CLONE_PATH" || return

      print_color "Finished cloning the repo for '$APP_NAME'." $GREEN
      NEEDS_BUILD=true
    else
      printf "\n"
      print_color "The application '$APP_NAME' was already cloned in applications. Checking for updates." $MAGENTA
      cd "$CLONE_PATH" || return

      # Check for changes in the repo
      if /usr/bin/git fetch origin &>/dev/null && [ "$(/usr/bin/git rev-list HEAD...origin/master --count)" != 0 ]; then
        /usr/bin/git reset --hard HEAD &>/dev/null
        /usr/bin/git pull &>/dev/null
        print_color "The application '$APP_NAME' has changed, so we will go ahead and rebuild." $MAGENTA
        NEEDS_BUILD=true
      elif [ ! -d "./Output/$APP_NAME" ]; then
        print_color "No updates found." $MAGENTA
        print_color "The application '$APP_NAME' was not yet built so we will go ahead and build." $MAGENTA
        NEEDS_BUILD=true
      elif [ -d "./Output/$APP_NAME" ]; then
        print_color "No updates found." $MAGENTA
        print_color "Copying '$APP_NAME' to '$RETURN_TO/Applications/'." $CYAN

        /bin/rm -rf "$RETURN_TO"/Applications/"$APP_NAME"
        /bin/cp -r ./Output/"$APP_NAME" "$RETURN_TO"/Applications/
        /usr/sbin/chown -R "$REGULAR_USER" "$RETURN_TO"/Applications/"$APP_NAME"
        /bin/chmod -R 755 "$RETURN_TO"/Applications/"$APP_NAME"
      fi
    fi

    if $NEEDS_BUILD; then
      print_color "Building application '$APP_NAME'." $CYAN
      spin &
      SPIN_PID=$!

      /usr/sbin/chown -R "$REGULAR_USER" ./
      /usr/bin/sudo -s -u "$REGULAR_USER" ./build.sh &>/dev/null

      stop_spinner $SPIN_PID

      # shellcheck disable=SC2181
      if [ ! -d "./Output/$APP_NAME" ]; then
        print_color "$(ls)" $YELLOW
        print_color "Unable to build '$APP_NAME'. Please check '$RETURN_TO/Applications/$CLONE_PATH/build.log' for more info." $RED
        cd "$RETURN_TO" || return
        exit 1
      else
        print_color "Successfully built '$APP_NAME'. Copying exported archive to '$RETURN_TO/Applications/'." $GREEN

        /bin/rm -rf "$RETURN_TO"/Applications/"$APP_NAME"
        /bin/cp -r ./Output/"$APP_NAME" "$RETURN_TO"/Applications/
        /usr/sbin/chown -R "$REGULAR_USER" "$RETURN_TO"/Applications/"$APP_NAME"
        /bin/chmod -R 755 "$RETURN_TO"/Applications/"$APP_NAME"
      fi
    fi

    cd "$RETURN_TO" || return
  done

  /bin/chmod -R 755 ./Applications
  /usr/sbin/chown -R "$REGULAR_USER" ./Applications

  # Sorry
  /bin/cp ./Other/Build/com.macOS-Utilities.preferences.plist ./Applications/macOS\ Utilities.app/Contents/Resources/

  printf "\n"
  print_color "Finished building applications." $GREEN
}

## Build User Package
## Creates a package with `createuserpackage` with the configured options
function build_user_package() {
  printf "\n"
  print_color "Building CreateAdmin package" $CYAN
  print_color "Log available at $PWD/$PKG_LOG" $MAGENTA

  PACKAGES_DIR="$PWD/Packages/"
  RETURN_TO="$PWD"

  cd ./Other/Helpers/pycreateuserpkg || return

  if ! (./createuserpkg --name="$ADMIN_USERNAME" \
    --password="$ADMIN_PASSWORD" \
    --admin \
    --autologin \
    --identifier=com.apple.createadmin \
    --gid=20 \
    --uid="$ADMIN_UID" \
    --version=1.0 \
    --fullname="$ADMIN_FULL_NAME" \
    "$PACKAGES_DIR"CreateAdmin.pkg >>"$RETURN_TO/$PKG_LOG" 2>&1); then

    print_color 'Unable to make CreateAdmin package. Please check the package log' $RED
    exit 1
  fi

  cd "$RETURN_TO" || return
  print_color "Successfully built CreateAdmin package." $GREEN
}

function build_all() {
  build_applications &&
    build_user_package
}
