# LoginItems
This folder contains LaunchAgents (like `com.keaton.LoadSomething.plist`)

## Example:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.autoNBI.LaunchTextEdit</string>
	<key>ProgramArguments</key>
	<array>
		<string>open</string>
		<string>-a</string>
		<string>/Applications/TextEdit.app</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
```