# global-functions.sh

## Define Regular User
## I'm just lazy and this was prettier
function define_regular_user() {
  REGULAR_USER=$(get_non_root_account)
}

## Notify Error
## Notify the user if an error was thrown
function notify_error {
  print_color "Something went wrong! Stacktrace:" $RED
  echo "$(caller): ${BASH_COMMAND}"
}

## Cleanup
## Called when exiting the script
function cleanup() {
  printf "\n"
  print_color "Unmounting drives and exiting." $RED

  # Kill the current spinner if spinning
  kill -PIPE $SPIN_PID 2>/dev/null || printf ''

  # Detach mounted disk images
  if [ -n "$NETBOOT_MOUNT_PATH" ] && [ -d "$NETBOOT_MOUNT_PATH" ]; then
      /usr/sbin/diskutil unmountDisk force "$NETBOOT_MOUNT_PATH" >>$DEBUG_LOG 2>&1 || print_color "Unable to unmount disk at '$NETBOOT_MOUNT_PATH'" $RED
  fi

  if [ -n "$BASE_SYSTEM_MOUNT_PATH" ] && [ -d "$BASE_SYSTEM_MOUNT_PATH" ]; then
      /usr/sbin/diskutil unmountDisk force "$BASE_SYSTEM_MOUNT_PATH" >>$DEBUG_LOG 2>&1 || print_color "Unable to unmount disk at '$BASE_SYSTEM_MOUNT_PATH'" $RED
  fi

  # Reset the cursor
  /usr/bin/tput cnorm

  # And finally enable echoctl again
  /bin/stty echoctl
}

## Setup
## Called when starting the script
function setup() {
  /bin/stty -echoctl
  /bin/mkdir -p ./Packages/        # Packages folder
  /bin/mkdir -p ./Applications/    # Applications folder
  /bin/mkdir -p ./Scripts/         # Scripts folder
  /bin/mkdir -p ./Products/          # .nbi output folder
  /bin/mkdir -p ./Other/Downloads/ # Temporary downloads folder
  /bin/mkdir -p ./Logs/            # Logs folder

  /usr/bin/git config --global credential.helper store
  echo '' >$PKG_LOG
  echo '' >$DEBUG_LOG
  /usr/sbin/chown -R "$REGULAR_USER" ./Logs

  define_regular_user
  check_output_folder # Check if the Output folder is empty
}

## Check Output Folder
## Checks that the /Products folder is clean and prompts the user to reuse or overwrite
function check_output_folder() {
  if [ "$(ls -A ./Products/)" ]; then
    /usr/bin/tput bel

    # shellcheck disable=SC2162
    read -e -p "${MAGENTA}The Products folder is not empty. Do you want to [o]verwrite the existing NetBoot set, or [r]ebuild the existing set? ${CLEAR}" CHOICE

    if [ -z "$CHOICE" ]; then
      check_for_empty_folder
    elif [[ "$CHOICE" == "o" ]]; then
      print_color "Removing all sets from Products" $RED
      /bin/rm -rf ./Products/*
    else
      print_color "Reusing disk image." $CYAN
      if test -f "./Products/$NAME.nbi/NetBoot.dmg"; then
        print_color "Looks like this NetBoot image was already compacted." $YELLOW

        /bin/mv "./Products/$NAME.nbi/NetBoot.dmg" "./Products/$NAME.nbi/NetBoot.sparseimage"
      fi
    fi
  fi
}

## Print Color
## Call this with the argument $MESSAGE and $COLOR (check colors.sh)
function print_color() {
  MESSAGE=$1
  COLOR=$2
  END_COLOR=${3:-$'\e[0m'}
  printf "%s\n" "${COLOR}${MESSAGE}${END_COLOR}"
}

## Get Root
## Call this to make sure script is being run with UID=0
function get_root() {
  if [ ! "$UID" -eq 0 ]; then
    exec sudo "$0" "--skip-packages=$2" "--base-disk-image=$1" "$@"
  fi
}

## Check Root
## Call this to see if the script is being run with UID=0
function check_root() {
  if [ "$USER" != 'root' ]; then
    if ! sudo -n -- true 2>/dev/null; then
      printf '\n'
      printf 'Enter password for sudo user "%s":\n' "$USER"
      while ! sudo -- true; do
        printf '\n'
        while true; do
          printf 'Slow your roll. Try to enter password again? [Y/n]: '
          read -r answer
          case "$answer" in
          '' | y | Y | yes | Yes | YES)
            printf '\n'
            printf 'Enter password for sudo user "%s":\n' "$USER"
            break
            ;;
          n | N | no | No | NO)
            printf '\n'
            printf 'OK. Exiting...\n'
            exit 1
            ;;
          *)
            printf 'Please enter a valid option...\n'
            printf '\n'
            ;;
          esac
        done
      done
    fi
  fi
}

## Progress Bar
## Pipe to this function a numeric percentage value, without the percent sign
function prog() {
  local width=80 progress=$1
  shift

  # Create a string of spaces, then change them to dots
  printf -v dots "%*s" "$((progress * width / 100))" ""
  dots=${dots// /.}

  # Print those dots on a fixed-width space plus the percentage etc.
  printf "\r\e[K|%-*s| %3d %% %s" "$width" "$dots" "$progress" "$*"
}

## Spinner
## Shows a little spinner to notate progress that is indeterminate
function spin() {
  spinner="⣾⣽⣻⢿⡿⣟⣯⣷"
  while :; do
    for i in $(seq 0 7); do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 0.1
    done
  done
}

## Stop Spinner
## Call this with the $SPIN_PID argument to cleanly stop the spinner
function stop_spinner() {
  kill "$1"
  wait "$1" 2>/dev/null || printf ''
}

## Get Non-Root Account
## Returns the first non-root user, kinda hacky but it worksTM
function get_non_root_account() {
  ACCOUNTS=()
  while IFS='' read -r line; do ACCOUNTS+=("$line"); done < <(/usr/bin/dscl . list /Users | grep -v '^_')
  for ACCOUNT in "${ACCOUNTS[@]}"; do
    if [ "$ACCOUNT" != "root" ] && [ "$ACCOUNT" != 'nobody' ] && [ "$ACCOUNT" != 'daemon' ] && [ "$ACCOUNT" != "Guest" ]; then
      echo "$ACCOUNT"
      return 0
    fi
  done
}

## Check wget
## Checks for wget, and attempts to install via Homebrew if not found
function check_wget() {
  if ! [ -x "$(command -v /usr/local/bin/wget)" ]; then
    print_color 'Error: wget is not installed. Will attempt to install with Homebrew.' $RED
    if ! [ -x "$(command -v /usr/local/bin/brew)" ]; then
      print_color 'Homebrew is not installed. Please visit "https://brew.sh" to install.' $RED
      exit 1
    else
      /usr/local/bin/brew install wget
    fi
  fi
}

## Prompt for Base System
## Requests the user input a path to an AutoDMG disk image
function prompt_for_base_system() {
  if [ -z "$BASE_SYSTEM_PATH" ]; then
    prompt_for_base_system
  else
    return 0
  fi

  printf "\n"

  /usr/bin/tput bel
  # shellcheck disable=SC2162
  read -e -p "${MAGENTA}Please drag your AutoDMG base image here: ${CLEAR}" BASE_SYSTEM_PATH

  if [[ $BASE_SYSTEM_PATH == *".dmg" ]]; then
    return 0
  else
    print_color "Not a valid DMG!" $RED
    prompt_for_base_system
  fi
}
