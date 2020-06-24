#!/bin/bash

# Please, do not modify anything below this line.
# If you choose to ignore this warning and it breaks, you do get to keep both pieces
#----------------------------------------------------------------------------------------------#
# Load the base configuration
source ./Configuration/builder.conf

# Load the downloads configuration
source ./Configuration/deps.conf

# Scripts that need downloading
IFS=$'\n' read -d '' -r -a SCRIPTS_TO_DOWNLOAD < <(plutil -p ./Configuration/scripts.plist | awk -F '=>' '{print $2}' | sed -e 's/\"//g' | sed -e 's/^ *//g' | awk NF)

# Applications that need building
IFS=$'\n' read -d '' -r -a APPLICATIONS_TO_BUILD < <(plutil -p ./Configuration/build.plist | awk -F '=>' '{print $2}' | sed -e 's/\"//g' | sed -e 's/^ *//g' | awk NF)

# Packages that need downloading
IFS=$'\n' read -d '' -r -a PACKAGES_TO_DOWNLOAD < <(plutil -p ./Configuration/packages.plist | awk -F '=>' '{print $2}' | sed -e 's/\"//g' | sed -e 's/^ *//g' | awk NF)

#----------------------------------------------------------------------------------------------#
BASE_SYSTEM_PATH=""
BASE_SYSTEM_MOUNT_PATH=""
OS_VERSION=""
OS_BUILD_VERSION=""
NETBOOT_MOUNT_PATH=""
NETBOOT_SPARSEIMAGE_PATH=""
NETBOOT_FOLDER_PATH=""
SPIN_PID=""
REGULAR_USER=""
SKIP_PACKAGE_INSTALL=false
#----------------------------------------------------------------------------------------------#

#----------------------------------------------------------------------------------------------#
source ./Other/Core/colors.sh            # Shell colors definitions
source ./Other/Core/global-functions.sh  # Global and shared functions
source ./Other/Core/dependencies.sh      # Dependency download functions
source ./Other/Core/build.sh             # Build functions for packages, applications, etc
source ./Other/Core/install.sh           # Install functions for packages, applications, etc
source ./Other/Core/disk-functions.sh    # Disk-related functions
source ./Other/Core/netboot-functions.sh # NetBoot image related functions
source ./Other/Core/flags.sh             # Parses CLI flags
source ./Other/Core/transfer.sh          # SCP transfer support
#----------------------------------------------------------------------------------------------#

trap cleanup EXIT

function finish() {
  /usr/bin/tput bel
  printf "\n\n\n"
  print_color "Done! NetBoot image is available in Products/" $GREEN
  exit 0
}

function start() {
  if "$DEBUG"; then
    set -Eeuxo pipefail
  else
    set -Eeuo pipefail
  fi

  trap notify_error ERR

  # 1. Check for wget
  check_wget

  # 2. Check for root/superuser access
  check_root

  # 3. Absolutely run script with root access
  get_root "$BASE_SYSTEM_PATH" "$SKIP_PACKAGE_INSTALL"

  # 4. Configure/preinit setup
  setup

  # 5. Prompt for AutoDMG image
  prompt_for_base_system

  # 6. Download dependencies
  download_dependencies

  # 7. Build packages and applications
  build_all

  # 8. Mount base system
  mount_base_system

  # 9. Get base system information
  get_base_system_info

  # 10. Create sparseimage
  create_netboot_sparseimage

  # 11. Mount sparseimage
  mount_netboot_sparseimage

  # 12. Copy contents of AutoDMG image to sparseimage
  copy_system_to_netboot_sparseimage

  # 13. Get the NetBoot image ready for installing things
  warmup_netboot_image

  # 14. Install applications and packages
  install_everything

  # 15. Finalize the NetBoot image
  finalize_netboot_image

  # 16. Eject disk images
  eject_disk_images

  # 17. Shrink sparseimage
  shrink_sparseimage

  # 18. Transfer product to SCP host
  transfer

  # 19. Finish
  finish
}

start # <- this is where the magic happens
