#!/bin/sh
################################################################################################
#
# Used by AutoNBI created nbi's on launch to set Time, Screen Sharing & install Certificates
#
################################################################################################

########
#
# Set Time Server & Zone
#
########

# If file exists, read from it & set Time Server & Zone
if [ -f /Library/Application\ Support/AutoNBI/Settings/TimeSettings.plist ]; then

echo "Getting Time Server & Zone settings..."

# Get Time Server from plist
timeServer=$(sudo defaults read /Library/Application\ Support/AutoNBI/Settings/TimeSettings.plist timeServer)

echo "Setting Time Server..."

/usr/sbin/systemsetup -setnetworktimeserver "$timeServer"

echo "Set Time Server"

# Get Time Zone from plist
timeZone=$(sudo defaults read /Library/Application\ Support/AutoNBI/Settings/TimeSettings.plist timeZone)

echo "Setting Time Zone..."

/usr/sbin/systemsetup -settimezone "$timeZone"

echo "Set Time Zone"

# Enable Network time

echo "Enabling Network Time..."

/usr/sbin/systemsetup -setusingnetworktime on

echo "Network Time enabled."

else

echo "TimeSettings.plist does not exist..."

fi

########
#
# Screen Sharing
#
########

# If only the file com.apple.VNCSettings.txt exists
if [ -f /Library/Preferences/com.apple.VNCSettings.txt ]; then

echo "Enabling VNC..."

/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -clientopts -setvnclegacy -vnclegacy yes -restart -agent

echo "VNC enabled..."

else
echo "No files found to enable screen sharing..."
fi


########
#
# Disable Gatekeeper
#
########

spctl --master-disable

echo "GateKeeper disabled..."

########
#
# Energy Saver Preferences
#
########

/usr/bin/pmset -a displaysleep 0 disksleep 0 sleep 0 hibernatemode 0 womp 1 autopoweroffdelay 0 standbydelay 0 ttyskeepawake 0 autopoweroff 0


########
#
# Misc.
#
########
/usr/sbin/systemsetup -setsleep "Never" -setcomputersleep "Never" -setdisplaysleep "Never" -setharddisksleep "Never"  -setwakeonmodem on -setwakeonnetworkaccess on


adminUsername=$(sudo defaults read /Library/Application\ Support/AutoNBI/Settings/Info.plist adminUsername)

/usr/sbin/chown -R "$adminUsername" "/Users/$adminUsername/"
/bin/chmod -R 777 "/Users/$adminUsername/Library/Preferences/.GlobalPreferences.plist"
/usr/bin/defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
/usr/bin/defaults write /Library/Preferences/.GlobalPreferences.plist _HIEnableThemeSwitchHotKey -bool true