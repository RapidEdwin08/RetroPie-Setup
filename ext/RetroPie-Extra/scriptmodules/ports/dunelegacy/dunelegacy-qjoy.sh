#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Dune II"
qjoyLYT=$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5768, maxSpeed 3, tCurve 0, mouse+h
	Axis 2: gradient, dZone 4615, maxSpeed 3, tCurve 0, mouse+v
	Axis 3: +key 111, -key 0
	Axis 4: gradient, dZone 6461, maxSpeed 15, tCurve 0, mouse+h
	Axis 5: gradient, dZone 6230, maxSpeed 15, tCurve 0, mouse+v
	Axis 6: +key 116, -key 0
	Axis 7: gradient, maxSpeed 2, tCurve 0, mouse+h
	Axis 8: gradient, maxSpeed 2, tCurve 0, mouse+v
	Button 1: mouse 1
	Button 2: mouse 3
	Button 3: mouse 1
	Button 4: mouse 3
	Button 5: mouse 1
	Button 6: mouse 3
	Button 7: key 9
	Button 8: key 36
	Button 9: key 9
	Button 10: mouse 1
	Button 11: mouse 3
	Button 12: key 113
	Button 13: key 114
	Button 14: key 111
	Button 15: key 116
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

# Run Dune
/opt/retropie/ports/dunelegacy/bin/dunelegacy

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
