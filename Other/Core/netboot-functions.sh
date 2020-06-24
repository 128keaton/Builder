## Reduce NetBoot Size
## Removes junk from the image not really needed
function reduce_netboot_size() {
  printf "\n"
  if [ "$COMPACT_NETBOOT" != false ]; then
    print_color "Reducing size of NetBoot image..." $CYAN

    MINOR_VERSION="$(/usr/bin/cut -d'.' -f2 <<<"$OS_VERSION")"

    if [ "$MINOR_VERSION" -ge "15" ]; then
      /usr/bin/find "$NETBOOT_MOUNT_PATH"/System/Applications/* -maxdepth 0 -not -path "*Launchpad.app*" -not -path "*Safari.app*" -not -path "*Photo Booth.app*" -not -path "*System Preferences.app*" -not -path "*TextEdit.app*" -not -path "*Applications/Utilities*" -exec rm -rf {} \;
    else
      /usr/bin/find "$NETBOOT_MOUNT_PATH"/Applications/* -maxdepth 0 -not -path "*Launchpad.app*" -not -path "*Safari.app*" -not -path "*Photo Booth.app*" -not -path "*System Preferences.app*" -not -path "*TextEdit.app*" -not -path "*Applications/Utilities*" -exec rm -rf {} \;
    fi

    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Application\ Support/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Audio/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Documentation/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Desktop\ Pictures/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Dictionaries/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Fonts/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Modem\ Scripts/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Printers/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Receipts/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Screen\ Savers/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Logs/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/Updates/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/WebServer/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/Library/User\ Pictures/*

    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/CoreServices/KeyboardSetupAssistant.app
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Screen\ Savers/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Speech/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Printers/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/LinguisticData/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Compositions/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Caches/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Automator/*
    /bin/rm -rf "$NETBOOT_MOUNT_PATH"/System/Library/Address\ Book\ Plug-Ins/*
  fi

  print_color "Successfully reduced the size of the NetBoot image." $GREEN
}

## Cleanup NetBoot Image
## Removes weird system things that can sometimes be copied over but are device-specific
function cleanup_netboot_image() {
  printf "\n"
  print_color "Cleaning up NetBoot image..." $CYAN

  {
    /bin/rm "${NETBOOT_MOUNT_PATH:?}"/private/var/vm/swapfile*
    /bin/rm "${NETBOOT_MOUNT_PATH:?}"/private/var/vm/sleepimage
    /bin/rm -rf "${NETBOOT_MOUNT_PATH:?}"/private/var/tmp/*
    /bin/rm -rf "${NETBOOT_MOUNT_PATH:?}"/dev/*
    /bin/rm -rf "${NETBOOT_MOUNT_PATH:?}"/private/tmp/*
    /bin/rm -rf "${NETBOOT_MOUNT_PATH:?}"/Volumes/*
    /bin/rm -rf "${NETBOOT_MOUNT_PATH:?}"/var/run/*
  } >>$DEBUG_LOG 2>&1

  print_color "Successfully cleaned up the NetBoot image." $GREEN
}

## Disable Software Update
## Disables the Software Update component of macOS
function disable_software_update() {
  printf "\n"
  print_color "Disabling Software Update..." $CYAN

  {
    /bin/rm -rf "$NETBOOT_MOUNT_PATH/System/Library/CoreServices/Software Update.app"
    /bin/rm -rf "$NETBOOT_MOUNT_PATH/System/Library/LaunchDaemons/com.apple.softwareupdate*"
  } >>$DEBUG_LOG 2>&1

  print_color "Successfully disabled Software Update." $GREEN
}

## Remove Preferences
## Remove the System Preference files that will be regenerated on boot
function remove_preferences() {
  printf "\n"
  print_color "Removing System Preferences..." $CYAN
  PREFS_TO_REMOVE=(
    '/Library/Preferences/SystemConfiguration/preferences.plist'
    '/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist'
  )

  for PREF_FILE in "${PREFS_TO_REMOVE[@]}"; do
    print_color "Removing ${PREF_FILE}" $YELLOW
    /bin/rm -rf "$NETBOOT_MOUNT_PATH""$PREF_FILE"
  done

  print_color "Successfully removed System Preferences." $GREEN
}

## Bypass Setup
## Bypasses Apple's setup assistant
function bypass_setup() {
  printf "\n"
  print_color "Bypassing Apple Setup Assistant..." $CYAN

  echo "$ADMIN_USERNAME ALL=(ALL:ALL) ALL" >>"$NETBOOT_MOUNT_PATH/etc/sudoers"
  /usr/bin/touch "$NETBOOT_MOUNT_PATH/var/db/.AppleSetupDone"
  /usr/bin/touch "$NETBOOT_MOUNT_PATH/Library/Receipts/.SetupRegComplete"
  /bin/rm -rf "$NETBOOT_MOUNT_PATH/System/Library/CoreServices/Setup Assistant.app"

  print_color "Successfully bypassed Apple Setup Assistant." $GREEN
}

## Disable Misc.
## Disables miscellaneous things for convienience
function disable_misc() {
  printf "\n"
  print_color "Disabling Time Machine prompts" $CYAN
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/Library/Preferences/com.apple.TimeMachine.plist" DoNotOfferNewDisksForBackup -bool YES

  print_color "Removing Dock Fixup" $CYAN
  /bin/rm -rf "$NETBOOT_MOUNT_PATH/System/Library/CoreServices/Dock.app/Contents/Resources/com.apple.dockfixup.plist"

  print_color "Disabling touristd" $CYAN
  /bin/rm -rf "$NETBOOT_MOUNT_PATH/System/Library/LaunchAgents/com.apple.touristd.plist"

  print_color "Disabling App Nap" $CYAN
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/private/var/root/Library/Preferences/.GlobalPreferences.plist" NSAppSleepDisabled -bool YES
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/Users/$ADMIN_USERNAME/Library/Preferences/.GlobalPreferences.plist" NSAppSleepDisabled -bool YES

  print_color "Disabling Persistence" $CYAN
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/private/var/root/Library/Preferences/.GlobalPreferences.plist" ApplePersistence -bool NO
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/Users/$ADMIN_USERNAME/Library/Preferences/.GlobalPreferences.plist" ApplePersistence -bool NO

  print_color "Enabling Dark Mode toggle (CMD+CTRL+Option+T)" $CYAN
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/Library/Preferences/.GlobalPreferences.plist" AppleInterfaceTheme -string "Dark"
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/Library/Preferences/.GlobalPreferences.plist" _HIEnableThemeSwitchHotKey -bool true

  print_color "Disabling Screensaver" $CYAN
  /usr/bin/defaults write "$NETBOOT_MOUNT_PATH/Library/Preferences/com.apple.screensaver.plist" idleTime -int 0

  /usr/bin/plutil -convert xml1 "$NETBOOT_MOUNT_PATH/Library/Preferences/.GlobalPreferences.plist"
}

## Write Info Plist
## Writes the information property list so we can reference things later during boot
function write_info_plist() {
  printf "\n"
  print_color "Writing User Info Settings." $CYAN
  INFO_PLIST="$NETBOOT_MOUNT_PATH/Library/Application Support/AutoNBI/Settings/Info.plist"

  /usr/bin/defaults write "$INFO_PLIST" adminUsername "$ADMIN_USERNAME"

  print_color "Successfully wrote User Info Settings." $GREEN
  enable_vnc
}

## Enable VNC
## Enables VNC on the NetBoot OS
function enable_vnc() {
  printf "\n"
  print_color "Enabling VNC." $CYAN
  /bin/echo "$VNC_PASSWORD" |
    /usr/bin/perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print ""' |
    /usr/bin/tee "$NETBOOT_MOUNT_PATH"/Library/Preferences/com.apple.VNCSettings.txt &>/dev/null

  print_color "Successfully enabled VNC." $GREEN
}

## Set Time Prefs
## Sets the NTP server and time zone to their configured values
function set_time_prefs() {
  printf "\n"
  print_color "Setting Time Server." $CYAN
  TZ_PLIST="$NETBOOT_MOUNT_PATH/Library/Application Support/AutoNBI/Settings/TimeSettings.plist"

  /usr/bin/defaults write "$TZ_PLIST" timeServer "$TIME_SERVER"

  print_color "Set Time Server successfully" $GREEN
  printf "\n"
  print_color "Setting Timezone." $CYAN

  /usr/bin/defaults write "$TZ_PLIST" timeZone "$TIMEZONE"
  print_color "Set Timezone successfully." $GREEN
}

## Copy Other Scripts
## Copy in user provided scripts
function copy_other_scripts() {
  printf "\n"
  print_color "Installing user-provided scripts." $CYAN
  DEST_DIR="$NETBOOT_MOUNT_PATH/Library/Application Support/AutoNBI"

  /bin/mkdir -p "$DEST_DIR/Scripts"
  /bin/cp -r ./Scripts/* "$DEST_DIR/Scripts/"

  /usr/sbin/chown -R root:wheel "$DEST_DIR"
  /bin/chmod -R 755 "$DEST_DIR"

  print_color "Installed user scripts.." $GREEN
}

## Install Startup Scripts
## Installs the startup script LaunchAgent
function install_startup_scripts() {
  printf "\n"
  print_color "Installing startup scripts." $CYAN
  DEST_DIR="$NETBOOT_MOUNT_PATH/Library/Application Support/AutoNBI"

  /bin/mkdir -p "$DEST_DIR/Scripts"
  /bin/cp ./Other/Build/Boot.sh "$DEST_DIR/Scripts"

  /usr/sbin/chown -R root:wheel "$DEST_DIR"
  /bin/chmod -R 755 "$DEST_DIR"

  DEST_DIR="$NETBOOT_MOUNT_PATH/Library/LaunchDaemons/"
  /bin/cp ./Other/Build/com.AutoNBI.boot.plist "$DEST_DIR"
  /usr/sbin/chown root:wheel "$DEST_DIR/com.AutoNBI.boot.plist"

  print_color "Installed startup scripts.." $GREEN
}

## Add Login Items
## Adds custom LaunchAgents to be executed on login/boot
function add_login_items() {
  printf "\n"
  print_color "Adding login items." $CYAN

  for ITEM in ./LoginItems/*.plist; do
    PLIST_NAME=$(basename "$ITEM")

    print_color "Adding login item '$PLIST_NAME' to '$NETBOOT_MOUNT_PATH/Library/LaunchAgents'" $MAGENTA
    /bin/cp "$ITEM" "$NETBOOT_MOUNT_PATH"/Library/LaunchAgents/

    /usr/sbin/chown root:wheel "$NETBOOT_MOUNT_PATH"/Library/LaunchAgents/"$PLIST_NAME"
    /bin/chmod 644 "$NETBOOT_MOUNT_PATH"/Library/LaunchAgents/"$PLIST_NAME"
  done

  print_color "Added login items successfully" $GREEN
}

## Copy Wallpaper Choices
## Copies custom wallpaper to the NetBoot system
function copy_wallpaper_choices() {
  printf "\n"
  print_color "Copying over user-provided wallpaper" $CYAN

  WALLPAPER_DEST="$NETBOOT_MOUNT_PATH/System/Library/Desktop Pictures/"
  WALLPAPER_SRC="$PWD/Wallpaper/"

  /usr/bin/find "$WALLPAPER_SRC" -type f -exec file --mime-type {} \+ | awk -F: '{if ($2 ~/image\//) print $1}' | while read -r IMG; do cp "$IMG" "$WALLPAPER_DEST"; done

  print_color "Copied user-provided wallpaper successfully" $GREEN
}

## Install rc NetBoot
## Installs the custom rc.netboot script (creates a ramdisk)
function install_rc_netboot() {
  printf "\n"
  print_color "Installing modified 'rc.netboot' file" $CYAN

  DEST_DIR="$NETBOOT_MOUNT_PATH/etc/"
  /usr/bin/ditto ./Other/Build/rc.netboot "$DEST_DIR/rc.netboot"
  /usr/sbin/chown -R root:wheel "$DEST_DIR/rc.netboot"
  /bin/chmod -R 755 "$DEST_DIR/rc.netboot"

  print_color "Installed modified 'rc.netboot' file successfully" $GREEN
}

## Create DYLD Caches
## Creates DYLD shared caches on the NetBoot system
function create_dyld_caches() {
  printf "\n"
  print_color "Generating DYLD shared caches..." $CYAN

  spin &
  SPIN_PID=$!

  "$NETBOOT_MOUNT_PATH"/usr/bin/update_dyld_shared_cache -root "$NETBOOT_MOUNT_PATH" -universal_boot -force >>$DEBUG_LOG 2>&1

  # shellcheck disable=SC2181
  if [ ! $? -eq 0 ]; then
    print_color "Unable to generate DYLD shared caches. Please check $DEBUG_LOG for more info" $RED
    exit 0
  fi

  stop_spinner $SPIN_PID

  print_color "Generated DYLD shared caches successfully" $GREEN
}

## Delete launchd Rebuild Caches
## Deletes the launchd rebuild caches file from the NetBoot system
function delete_launchd_rebuild_caches() {
  printf "\n"
  print_color "Deleting launchd rebuild caches." $CYAN

  /bin/rm -rf "$NETBOOT_MOUNT_PATH"/var/db/.launchd_rebuild_caches

  print_color "Deleted launchd rebuild caches successfully." $GREEN
}

## Create XPC Extensions Cache
## Creates the XPC extensions cache on the NetBoot system
function create_xpc_extensions_cache() {
  printf "\n"
  print_color "Creating XPC extensions cache." $CYAN

  spin &
  SPIN_PID=$!

  "$NETBOOT_MOUNT_PATH"/usr/libexec/xpchelper --rebuild-cache --root "$NETBOOT_MOUNT_PATH" >>$DEBUG_LOG 2>&1

  # shellcheck disable=SC2181
  if [ ! $? -eq 0 ]; then
    print_color "Unable to create the XPC extensions cache. Please check $DEBUG_LOG for more info" $RED
    exit 1
  fi

  stop_spinner $SPIN_PID

  print_color "Created XPC extensions cache successfully." $GREEN
}

## Generate Kernel Cache
## Generates the kernel cache on the NetBoot system
function generate_kernel_cache() {
  printf "\n"
  print_color "Generating kernel cache." $CYAN

  spin &
  SPIN_PID=$!

  /bin/mkdir -p "$NETBOOT_FOLDER_PATH"/i386/x86_64
  /usr/bin/touch "$NETBOOT_MOUNT_PATH"/System/Library/Extensions/
  "$NETBOOT_MOUNT_PATH"/usr/sbin/kextcache -update-volume "$NETBOOT_MOUNT_PATH" >>$DEBUG_LOG 2>&1

  # shellcheck disable=SC2181
  if [ ! $? -eq 0 ]; then
    print_color "Unable to generate the kernel cache. Please check $DEBUG_LOG for more info" $RED
    exit 1
  fi

  /usr/sbin/kextcache -arch x86_64 -l -n -K "$NETBOOT_MOUNT_PATH"/System/Library/Kernels/kernel -c "$NETBOOT_FOLDER_PATH"/i386/x86_64/kernelcache "$NETBOOT_MOUNT_PATH"/System/Library/Extensions >>$DEBUG_LOG 2>&1

  # shellcheck disable=SC2181
  if [ ! $? -eq 0 ]; then
    print_color "Unable to create the XPC extensions cache. Please check $DEBUG_LOG for more info" $RED
    exit 1
  fi

  /bin/rm -rf "$NETBOOT_MOUNT_PATH"/usr/standalone/bootcaches.plist

  stop_spinner $SPIN_PID

  print_color "Generated kernel cache successfully." $GREEN
}

## Copy Bootloader
## Copies the bootloader from the Recovery partition, falling back to the regular bootloader if not available
function copy_bootloader() {
  printf "\n"
  print_color "Copying EFI bootloader." $CYAN

  RECOVERY_PARTITION=$(/usr/sbin/diskutil list | grep Recovery | /usr/bin/awk '{ print $NF }')
  RECOVERY_MOUNTPOINT="/Volumes/Recovery"

  if [ -z "$RECOVERY_PARTITION" ]; then
    print_color "Unable to determine Recovery partition device. Cannot copy Recovery boot.efi, using fallback." $YELLOW
    /bin/cp "$NETBOOT_MOUNT_PATH"/System/Library/CoreServices/boot.efi "$NETBOOT_FOLDER_PATH"/i386/booter
  else
    # Magic sauce for a 'recovery' efi bootloader
    print_color "Copying Recovery boot.efi from host system." $MAGENTA
    /bin/mkdir -p "$RECOVERY_MOUNTPOINT"
    /sbin/mount -t apfs "$RECOVERY_PARTITION" "$RECOVERY_MOUNTPOINT"

    # shellcheck disable=SC2012
    FULL_PATH=$(ls -d "$RECOVERY_MOUNTPOINT"/* | head -n 1)
    echo "$FULL_PATH/boot.efi"
    /bin/cp "$FULL_PATH/boot.efi" "$NETBOOT_FOLDER_PATH"/i386/booter

    # shellcheck disable=SC2181
    if [ ! $? -eq 0 ]; then
      print_color "Unable to copy bootloader from '$RECOVERY_MOUNTPOINT'." $RED
      exit 1
    fi

    /sbin/umount "$RECOVERY_MOUNTPOINT"
  fi

  /usr/bin/chflags nouchg "$NETBOOT_FOLDER_PATH"/i386/booter
  /usr/sbin/chown root:staff "$NETBOOT_FOLDER_PATH"/i386/booter

  print_color "Copied EFI bootloader successfully." $GREEN
}

## Copy NetBoot Misc
## Copies the WiFi firmware, NBImageInfo.plist to the NetBoot NBI folder
function copy_netboot_misc() {
  printf "\n"
  print_color "Copying NetBoot settings/definitions." $CYAN

  # Make WiFi firmware folder
  /bin/mkdir -p "$NETBOOT_FOLDER_PATH"/i386/wifi

  # Copy WiFi firmware
  /bin/cp -R "$NETBOOT_MOUNT_PATH"/usr/share/firmware/wifi/ "$NETBOOT_FOLDER_PATH"/i386/wifi/
  /usr/sbin/chown -R root:staff "$NETBOOT_FOLDER_PATH"/i386/wifi/

  # Copy PlatformSupport.plist
  /bin/cp "$NETBOOT_MOUNT_PATH"/System/Library/CoreServices/PlatformSupport.plist "$NETBOOT_FOLDER_PATH"/i386/PlatformSupport.plist

  # Copy NBImageInfo.plist
  /bin/cp ./Other/Build/NBImageInfo.plist "$NETBOOT_FOLDER_PATH"/

  print_color "Copied NetBoot settings/definitions successfully." $GREEN
}

## Update Image Info
## Updates the definitions/values in the NBImageInfo file
function update_image_info() {
  printf "\n"
  print_color "Updating NBImageInfo.plist." $CYAN

  IMAGE_INFO="$NETBOOT_FOLDER_PATH"/NBImageInfo.plist

  # Change permissions so we can modify
  /bin/chmod 777 "$IMAGE_INFO"

  # Change all these settings
  /usr/bin/plutil -replace IsInstall -bool NO "$IMAGE_INFO"
  print_color "IsInstall = NO" $MAGENTA

  /usr/bin/plutil -replace Name -string "$NAME" "$IMAGE_INFO"
  print_color "Name = $NAME" $MAGENTA

  /usr/bin/plutil -replace SupportsDiskless -bool YES "$IMAGE_INFO"
  print_color "SupportsDiskless = YES" $MAGENTA

  /usr/bin/plutil -replace RootPath -string NetBoot.dmg "$IMAGE_INFO"
  print_color "RootPath = NetBoot.dmg" $MAGENTA

  /usr/bin/plutil -replace Index -integer $INDEX "$IMAGE_INFO"
  print_color "Index = $INDEX" $MAGENTA

  /usr/bin/plutil -replace Description -string "$DESCRIPTION" "$IMAGE_INFO"
  print_color "Description = $DESCRIPTION" $MAGENTA

  /usr/bin/plutil -insert ImageType -string netboot "$IMAGE_INFO"
  print_color "ImageType = netboot" $MAGENTA

  /usr/bin/plutil -insert osVersion -string "$OS_VERSION" "$IMAGE_INFO"
  print_color "osVersion = $OS_VERSION" $MAGENTA

  /usr/bin/plutil -replace Type -string "$SERVE_OVER" "$IMAGE_INFO"
  print_color "Type = $SERVE_OVER" $MAGENTA

  /usr/bin/plutil -replace IsEnabled -bool YES "$IMAGE_INFO"
  print_color "IsEnabled = YES" $MAGENTA

  # Correct permissions
  /usr/sbin/chown -R root:staff "$IMAGE_INFO"
  /bin/chmod 644 "$IMAGE_INFO"

  # Convert to XML
  /usr/bin/plutil -convert xml1 "$IMAGE_INFO"

  print_color "Updating NBImageInfo.plist successfully." $GREEN
}

function warmup_netboot_image() {
  reduce_netboot_size &&
    cleanup_netboot_image &&
    disable_software_update &&
    remove_preferences &&
    bypass_setup &&
    disable_misc &&
    write_info_plist &&
    enable_vnc &&
    set_time_prefs

  ## Handing back off to parent function
}

function finalize_netboot_image() {
  copy_other_scripts &&
    install_startup_scripts &&
    add_login_items &&
    copy_wallpaper_choices &&
    install_rc_netboot &&
    create_dyld_caches &&
    delete_launchd_rebuild_caches &&
    create_xpc_extensions_cache &&
    generate_kernel_cache &&
    copy_bootloader &&
    copy_netboot_misc &&
    update_image_info

  ## Handing back off to parent function
}
