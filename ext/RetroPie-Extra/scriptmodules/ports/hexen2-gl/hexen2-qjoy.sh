#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Hexen II"
qjoyLYT=$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5538, xZone 29536, +key 60, -key 59
	Axis 2: dZone 9230, xZone 28382, +key 116, -key 111
	Axis 3: gradient, +key 65, -key 0
	Axis 4: gradient, dZone 5307, xZone 28382, maxSpeed 18, mouse+h
	Axis 5: dZone 8768, +key 52, -key 38
	Axis 6: gradient, throttle+, +key 105, -key 0
	Axis 7: +key 35, -key 34
	Axis 8: +key 36, -key 23
	Button 1: key 61
	Button 2: key 115
	Button 3: key 65
	Button 4: key 50
	Button 5: key 20
	Button 6: key 21
	Button 7: key 9
	Button 8: key 36
	Button 9: key 29
	Button 10: key 50
	Button 11: key 115
	Button 12: key 34
	Button 13: key 35
	Button 14: key 23
	Button 15: key 36
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "$HOME/.qjoypad3/$qjoyLAYOUT.lyt" ]; then echo "$qjoyLYT" > "$HOME/.qjoypad3/$qjoyLAYOUT.lyt"; fi

# Run Window Manager
echo 'xset -dpms s off s noblank; matchbox-window-manager -use_titlebar no &' >> /dev/shm/runcommand.info
xset -dpms s off s noblank
matchbox-window-manager -use_titlebar no &

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "$qjoyLAYOUT" &

# Run Hexen II
if [[ "$1" == 'portals' ]]; then
	/opt/retropie/ports/hexen2/glhexen2 -f -conwidth 800 -portals
else
	/opt/retropie/ports/hexen2/glhexen2 -f -conwidth 800
fi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
