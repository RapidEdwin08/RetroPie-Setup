#!/bin/bash

# Use [matchbox-window-manager -use_titlebar no &] for Fullscreen
if [[ "$1" == '' ]]; then
	matchbox-window-manager -use_titlebar no & /opt/retropie/emulators/aethersx2/AetherSX2-v1.5-3606.AppImage -bigpicture -fullscreen
else
	if [ "$(ls ~/RetroPie/BIOS/SCPH*)" == '' ] && [ "$(ls ~/RetroPie/BIOS/scph*)" == '' ] && [ "$(ls ~/RetroPie/BIOS/ps2*)" == '' ]; then #DisplayMissingBIOS
		sudo fbi -T 2 -a -noverbose /opt/retropie/emulators/aethersx2/PS2BIOSRequired.jpg > /dev/null 2>&1; sleep 7; sudo kill $(pgrep fbi) > /dev/null 2>&1; exit 0
	fi
	matchbox-window-manager -use_titlebar no & /opt/retropie/emulators/aethersx2/AetherSX2-v1.5-3606.AppImage -bigpicture -fullscreen "$1"
fi
 
