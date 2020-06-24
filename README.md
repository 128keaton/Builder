# Builder
*Effectively replaces AutoNBI/AutoCasperNBI*

## Features
* Downloads and installs Xcode Command Line tools (python3 is required for outset)
* Downloads and installs `outset`, `set-desktop-catalina.sh`, `dockutil`, `pycreateuserpkg`
* Clones, builds, and installs macOS Utilities from source
* Automagically packages our custom payload
* Sets the network time-server and timezone.
* Compresses the NetBoot set when complete.
* Reuse of a previously created image, useful for quick updates.


## Prerequisites

Please download and install these dependencies before continuing.

* [Homebrew](https://brew.sh)
* [AutoDMG](https://github.com/MagerValp/AutoDMG/releases)
* wget (use `brew install wget`)

## Building a base macOS image

Make sure you have downloaded a copy of 'Install macOS Catalina' and it is in your Applications folder before continuing.

First, run the `wrap-catalina.sh` located in `Other/`
```bash
$ cd Other/ && wrap-catalina.sh
```

When done, there should be a mounted volume named 'Catalina' with the installer app inside the root folder. 

Open AutoDMG and drag the application from the Finder window to AutoDMG
Click 'Build'

## Building a NetBoot set

**Please rename the `builder.example.conf` to `builder.conf` and configure appropriately**


Once you have your clean image from AutoDMG, make sure you have it ready.

Run the `builder.sh` script like so:
```bash
$ ./builder.sh
```

The script will prompt you automatically for a super user password, no need to run as root.

## Flags
1.  `--skip-packages` or `-skippkg`

Set this to `true` if you want to skip installing packages on the NetBoot volume. 
This can greatly speed up building if you are troubleshooting.
```bash
$ ./builder.sh --skip-packages=true 
```


2. `--base-disk-image` or `-dmg`

Set this to the path of your base system disk image so you aren't prompted to input the disk image.
```bash
$ ./builder.sh --base-disk-image=/Volumes/Scratch/osx-10.15.5-19F2200.apfs.dmg 
```

## Adding Things
### Packages:
Simply put your `.pkg` file in `Packages/`. The package should be installed automatically when bundling.

### Downloaded Packages:
Append your package URL to the `packages.plist` file in `Configuration/` and it will automatically be downloaded and installed.

### Applications:
Put your `.app` in `Applications/`, and it will automatically be installed.

### Applications to build:
This requires a bit of setup. Basically, your app needs to be hosted on a Git repository somewhere accessible via HTTP/SSH. 
Then, the builder script looks for a `build.sh` script in the project root. Look at the [example](https://github.com/128keaton/macOS-Utilities/blob/05893bc91787667e5ab285f9f1d3067b6fce572a/build.sh)
 here for an idea of whats expected. Essentially, the script needs to build and archive the application and copy the `.app` into a folder `Output/` in the app project root.
 If you've done all of that, then just add your repo URL to the `packages.plist` file in `Configuration`.
 
### Downloaded Scripts:
*Note: The script must be publicly accessible via HTTP/S*

Add the script URL to the `scripts.plist` file in `Configuration` and it will be automatically downloaded and installed

### Login Items:
To add a `LaunchAgent` property list to the system, create a new `.plist` in the `LoginItems` folder in the root of the project.

Here is an example, `com.autonbi.LaunchBarTimer.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.autonbi.LaunchBarTimer</string>
	<key>ProgramArguments</key>
	<array>
		<string>open</string>
		<string>-a</string>
		<string>/Applications/BarTimer.app</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
```

The `Label` setting needs to match the name of the `.plist`, omitting the extension.
If you wanted to say a message with the built-in TTS system, you could set the `ProgramArguments` array to:
```xml
<array>
	<string>say</string>
	<string>"Hello World"</string>
</array>
```

## Creating installation media
First, download an `Install macOS XXX.app`.
Next, run the command below, replacing the variables with the appropriate file paths:
```bash
sudo hdiutil create -srcfolder /path/to/your/Install\ macOS\ Blah.app ~/Desktop/Output.dmg
```

Finally, move the resulting disk image to your NFS share.

## Troubleshooting
*You done sauced it, didn't ya?*

### Build errors on built Application
Make sure your repository is the *same name* as the final `.app` name. Sorry!

## Notes
* You can use tab completion on the prompt for a base system.

 
## Credits
* [MacMule](https://macmule.com/) - Creator of AutoCasperNBI, from much was borrowed
* [Greg Neagle](https://github.com/gregneagle/pycreateuserpkg) - Creator of pycreateuserpkg, for without we'd have no users
* [Stéphane Sudre](http://s.sudre.free.fr/index.html) - Creator of Packages, also creator of a _great_ website
