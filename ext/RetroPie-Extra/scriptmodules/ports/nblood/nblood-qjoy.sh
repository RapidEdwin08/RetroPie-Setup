#!/bin/bash
# https://github.com/RapidEdwin08/

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
	/opt/retropie/ports/nblood/nblood -ini CRYPTIC.INI -j=/home/pi/RetroPie/roms/ports/ksbuild/blood/
else
	/opt/retropie/ports/nblood/nblood -ini blood.ini -j=/home/pi/RetroPie/roms/ports/ksbuild/blood/
fi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
