
## Create NetBoot Sparseimage
## Creates a NetBoot.sparseimage with the configured options
function create_netboot_sparseimage() {
  printf "\n"
  NETBOOT_SPARSEIMAGE_PATH="./Products/$NAME.nbi/NetBoot.sparseimage"
  NETBOOT_FOLDER_PATH="./Products/$NAME.nbi/"

  if [ ! -f "$NETBOOT_SPARSEIMAGE_PATH" ]; then
    print_color "Creating NetBoot.sparseimage at '$NETBOOT_SPARSEIMAGE_PATH" $CYAN
    /bin/mkdir -p ./Products/"$NAME".nbi
    /usr/bin/hdiutil create "$NETBOOT_SPARSEIMAGE_PATH" \
      -type SPARSE \
      -size 64g \
      -volname "$NAME" \
      -uid 0 \
      -gid 80 \
      -mode 1775 \
      -layout "GPTSPUD" \
      -fs "HFS+J" \
      -stretch 500g \
      -ov \
      -puppetstrings >&/dev/null
  else
    print_color "Reusing existing NetBoot.sparseimage at '$NETBOOT_SPARSEIMAGE_PATH'" $CYAN
  fi
}

## Mount NetBoot Sparseimage
## Mounts the Netboot.sparseimage at the given path
function mount_netboot_sparseimage() {
  printf "\n"
  NETBOOT_MOUNT_PATH=$(/usr/bin/hdiutil attach "$NETBOOT_SPARSEIMAGE_PATH" -nobrowse -owners on -plist | awk -F"[<>]" 'a{print $3; exit}$2=="key"&&$3=="mount-point"{a=1}')

  if [ -z "$NETBOOT_MOUNT_PATH" ]; then
    print_color "Unable to mount sparse image image at $NETBOOT_SPARSEIMAGE_PATH" $RED
    exit 1
  fi

  print_color "Mounted NetBoot.sparseimage at $NETBOOT_MOUNT_PATH" $GREEN
}

## Copy System to NetBoot Sparseimage
## Copys the contents of the base system disk image to the Netboot sparseimage
function copy_system_to_netboot_sparseimage() {
  printf "\n"
  if [ ! -f "$NETBOOT_MOUNT_PATH"/.copied ]; then
    print_color "Copying files from base system to NetBoot.sparseimage" $CYAN
    echo >$DITTO_LOG

    spin &
    SPIN_PID=$!

    /usr/bin/ditto "$BASE_SYSTEM_MOUNT_PATH" "$NETBOOT_MOUNT_PATH" -vV &>$DITTO_LOG

    stop_spinner $SPIN_PID
    /usr/bin/touch "$NETBOOT_MOUNT_PATH"/.copied
  else
    print_color "Skipping base system copy since .copied file is present at root" $YELLOW
  fi
}

## Mount Base System
## Mounts the base AutoDMG disk image from the specified path
function mount_base_system() {
  print_color "Mounting DMG at path: $BASE_SYSTEM_PATH" $CYAN

  spin &
  SPIN_PID=$!

  # First, attempt to mount and error if unable to mount
  /usr/bin/hdiutil attach "$BASE_SYSTEM_PATH" -nobrowse -owners on >>$DEBUG_LOG 2>&1

  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    print_color "Unable to mount disk image at $BASE_SYSTEM_PATH" $RED
    exit 1
  fi

  # Redirect the plist output to '.mount.plist'
  /usr/bin/hdiutil attach "$BASE_SYSTEM_PATH" -nobrowse -owners on -plist >.mount.plist

  # Convert '.mount.plist' to json
  /usr/bin/plutil -convert json -o .mount.json .mount.plist

  # Finally, get the mount path by calling our python script which processes JSON
  BASE_SYSTEM_MOUNT_PATH=$(python Other/Helpers/get-mounted-drives.py)

  /bin/rm -rf .mount.plist
  /bin/rm -rf .mount.json

  stop_spinner $SPIN_PID
  print_color "Base System mounted at $BASE_SYSTEM_MOUNT_PATH" $GREEN
}

## Get Base System Info
## Reads the OS version and build version from the mounted base system
function get_base_system_info() {
  OS_VERSION=$(/usr/bin/defaults read "$BASE_SYSTEM_MOUNT_PATH"/System/Library/CoreServices/SystemVersion.plist ProductVersion)
  OS_BUILD_VERSION=$(/usr/bin/defaults read "$BASE_SYSTEM_MOUNT_PATH"/System/Library/CoreServices/SystemVersion.plist ProductBuildVersion)
  print_color "Base System - macOS $OS_VERSION ($OS_BUILD_VERSION)" $BLUE
}

## Eject Disk Images
## Detaches the NetBoot sparseimage and AutoDMG base image
function eject_disk_images() {
  printf "\n"
  print_color "Ejecting disk images." $CYAN

  print_color "$(/usr/bin/hdiutil detach -force "$NETBOOT_MOUNT_PATH")" $YELLOW
  print_color "$(/usr/bin/hdiutil detach -force "$BASE_SYSTEM_MOUNT_PATH")" $YELLOW
}

## Shrink Sparseimage
## Shrinks/compact the NetBoot sparseimage
function shrink_sparseimage() {
  printf "\n"
  print_color "Shrinking and renaming NetBoot.sparseimage." $CYAN

  spin &
  SPIN_PID=$!

  /usr/bin/hdiutil compact "$NETBOOT_FOLDER_PATH"/NetBoot.sparseimage -batteryallowed >>$DEBUG_LOG
  /bin/mv "$NETBOOT_FOLDER_PATH"/NetBoot.sparseimage "$NETBOOT_FOLDER_PATH"/NetBoot.dmg

  stop_spinner $SPIN_PID
}


