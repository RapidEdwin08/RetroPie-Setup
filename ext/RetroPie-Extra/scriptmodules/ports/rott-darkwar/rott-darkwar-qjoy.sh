#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Rise Of The Triad"
qjoyLYT=$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5538, xZone 29536, +key 60, -key 59
	Axis 2: gradient, dZone 9230, xZone 28382, +key 116, -key 111
	Axis 3: gradient, dZone 6691, +key 66, -key 0
	Axis 4: gradient, dZone 5307, xZone 28382, maxSpeed 20, mouse+h
	Axis 5: dZone 8768, +key 115, -key 110
	Axis 6: gradient, throttle+, +key 105, -key 0
	Axis 7: +key 114, -key 113
	Axis 8: +key 116, -key 111
	Button 1: key 119
	Button 2: key 65
	Button 3: key 37
	Button 4: key 36
	Button 5: key 117
	Button 6: key 112
	Button 7: key 9
	Button 8: key 36
	Button 9: key 22
	Button 10: key 50
	Button 11: key 38
	Button 12: key 113
	Button 13: key 114
	Button 14: key 111
	Button 15: key 116
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "$HOME/.qjoypad3/$qjoyLAYOUT.lyt" ]; then echo "$qjoyLYT" > "$HOME/.qjoypad3/$qjoyLAYOUT.lyt"; fi

# Run Window Manager
#echo 'xset -dpms s off s noblank; matchbox-window-manager -use_titlebar no &' >> /dev/shm/runcommand.info
xset -dpms s off s noblank
#matchbox-window-manager -use_titlebar no &

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "$qjoyLAYOUT" &

# Detect/Run ROTT P0RT
rottROMdir="$HOME/RetroPie/roms/ports/rott" #rottexpr
if [[ -d "$HOME/RetroPie/roms/ports/rott-darkwar" ]]; then rottROMdir="$HOME/RetroPie/roms/ports/rott-darkwar"; fi #rott/rottexpr
if [[ -d "/dev/shm/rott-darkwar" ]]; then rottROMdir="/dev/shm/rott-darkwar"; fi #rott-darkwar-plus

rottBIN=/opt/retropie/ports/rott-darkwar/rott # rottexpr
if [[ -f /opt/retropie/ports/rott-darkwar/rott-darkwar ]]; then rottBIN=/opt/retropie/ports/rott-darkwar/rott-darkwar; fi #rott/rottexpr

pushd "$rottROMdir"
"$rottBIN" $*
popd

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
