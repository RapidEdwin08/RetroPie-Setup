#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Blood"
qjoyLYT=$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5538, xZone 29536, +key 40, -key 38
	Axis 2: gradient, dZone 9230, xZone 28382, +key 39, -key 25
	Axis 3: gradient, +key 53, -key 0
	Axis 4: gradient, dZone 5307, xZone 28382, maxSpeed 12, mouse+h
	Axis 5: gradient, dZone 8768, maxSpeed 5, mouse+v
	Axis 6: gradient, throttle+, +key 105, -key 0
	Axis 7: +key 35, -key 34
	Axis 8: +key 36, -key 66
	Button 1: key 65
	Button 2: key 26
	Button 3: key 37
	Button 4: key 50
	Button 5: key 47
	Button 6: key 48
	Button 7: key 9
	Button 8: key 36
	Button 9: key 23
	Button 10: key 50
	Button 11: key 84
	Button 12: key 34
	Button 13: key 35
	Button 14: key 66
	Button 15: key 36
}
')

# Create QJoyPad.lyt if needed
if [ -d "$home/.qjoypad3" ] && [ ! -f "$HOME/.qjoypad3/$qjoyLAYOUT.lyt" ]; then echo "$qjoyLYT" > "$HOME/.qjoypad3/$qjoyLAYOUT.lyt"; fi

# Run Window Manager
echo 'xset -dpms s off s noblank; matchbox-window-manager -use_titlebar no &' >> /dev/shm/runcommand.info
xset -dpms s off s noblank
#matchbox-window-manager -use_titlebar no &

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "Blood" &" >> /dev/shm/runcommand.info
qjoypad "Blood" &

# Run Blood
if [[ "$1" == 'cryptic' ]]; then
	/opt/retropie/ports/nblood/nblood -ini CRYPTIC.INI -j=$HOME/RetroPie/roms/ports/ksbuild/blood/
else
	/opt/retropie/ports/nblood/nblood -ini blood.ini -j=$HOME/RetroPie/roms/ports/ksbuild/blood/
fi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
