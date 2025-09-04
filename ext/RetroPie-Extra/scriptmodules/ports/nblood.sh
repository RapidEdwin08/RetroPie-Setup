#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# RetroPie-Extra
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="nblood"
rp_module_desc="Nblood - Blood source port"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="you need to put the \n\BLOOD.INI, \n\BLOOD.RFF, \n\BLOOD000.DEM, ..., BLOOD003.DEM (optional), \n\GUI.RFF, \n\SOUNDS.RFF, \n\SURFACE.DAT, \n\TILES000.ART, ..., TILES017.ART, \n\VOXEL.DAT in ports/ksbuild/blood
,\n\Cryptic Passage,\n\
CP01.MAP, ..., CP09.MAP,\n\CPART07.AR_,\n\CPART15.AR_,\n\CPBB01.MAP, ..., CPBB04.MAP,\n\CPSL.MAP,\n\CRYPTIC.INI\n\CRYPTIC.SMK \n\CRYPTIC.WAV"
rp_module_section="exp"
rp_module_flags=""

function depends_nblood() {
	# libsdl1.2-dev libsdl-mixer1.2-dev xorg xinit x11-xserver-utils
	local depends=(cmake build-essential libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev freepats)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
	isPlatform "kms" && depends+=(xorg matchbox-window-manager)
	getDepends "${depends[@]}"
}

function sources_nblood() {
	gitPullOrClone
}

function build_nblood() {
    cd $md_build
    local params=(LTO=0 SDL_TARGET=2 RENDERTYPE=SDL STARTUP_WINDOW=0)
    if isPlatform "rpi"; then # For Best Results on RPi make blood exhumed rr with USE_OPENGL=0 POLYMER=0
    	params+=(USE_OPENGL=0 POLYMER=0 NETCODE=0)
    else
    	isPlatform "gl" && params+=(USE_OPENGL=1)
    	! ( isPlatform "gl" || isPlatform "mesa" ) && params+=(USE_OPENGL=0)
    	isPlatform "gl3" && params+=(POLYMER=1)
    	! isPlatform "gl3" && params+=(POLYMER=0)
    	isPlatform "arm" && params+=(NETCODE=0)
    fi
    echo [PARAMS]: ${params[@]}
    make -j"$(nproc)" blood "${params[@]}"
	md_ret_require="$md_build"
}

function install_nblood() {
    md_ret_files=(        
		'dn64widescreen.pk3'
		'nblood'
		'nblood.pk3'
    )
}
	
function configure_nblood() {
	if [[ ! -d "$home/.config/nblood" ]]; then mkdir "$home/.config/nblood"; fi
	if [[ ! -f "$home/.config/nblood/nblood_cvars.cfg" ]]; then touch "$home/.config/nblood/nblood_cvars.cfg"; fi
	if [[ "$(cat "$home/.config/nblood/nblood_cvars.cfg" | grep r_vsync)" == '' ]]; then
		echo 'r_vsync "1"' >> "$home/.config/nblood/nblood_cvars.cfg"
	else
		sed -i 's+r_vsync.*+r_vsync "1"+g' "$home/.config/nblood/nblood_cvars.cfg"
	fi
	chown -R $__user:$__user "$home/.config/nblood"
    moveConfigDir "$home/.config/nblood" "$md_conf_root/nblood"
    chown -R $__user:$__user "$md_conf_root/nblood"

	mkRomDir "ports/ksbuild/blood"
	
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
	addPort "$md_id" "nblood" "Nblood - Blood Source Port" "$launch_prefix$md_inst/nblood -ini blood.ini -j $home/RetroPie/roms/ports/ksbuild/blood"
	addPort "$md_id" "nblood-cp" "NBlood - Blood Cryptic Passage Source Port" "$launch_prefix$md_inst/nblood -ini CRYPTIC.INI -j $home/RetroPie/roms/ports/ksbuild/blood"

	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "nblood" "Nblood - Blood Source Port" "$launch_prefix$md_inst/nblood-qjoy.sh"
		addPort "$md_id+qjoypad" "nblood-cp" "NBlood - Blood Cryptic Passage Source Port" "$launch_prefix$md_inst/nblood-qjoy.sh cryptic"
	fi

    cat >"$md_inst/nblood.cfg" << _EOF_
[Setup]
CacheSize = 100663296
ConfigVersion = 107
ForceSetup = 1
NoAutoLoad = 1
InputJoystick = 0
InputMouse = 1

[Screen Setup]
Polymer = 0
ScreenBPP = 8
ScreenHeight = 1080
ScreenMode = 1
ScreenWidth = 1920
MaxRefreshFreq = 0

[Controls]
MouseButton0 = "Weapon_Fire"
MouseButtonClicked0 = ""
MouseButton1 = "Weapon_Special_Fire"
MouseButtonClicked1 = ""
MouseButton2 = ""
MouseButtonClicked2 = ""
MouseButton3 = ""
MouseButtonClicked3 = ""
MouseButton4 = "Previous_Weapon"
MouseButtonClicked4 = ""
MouseButton5 = "Next_Weapon"
MouseButtonClicked5 = ""
MouseButton6 = ""
MouseButtonClicked6 = ""
MouseButton7 = ""
MouseButtonClicked7 = ""
MouseButton8 = ""
MouseButton9 = ""

[Comm Setup]
PlayerName = "Player"
CommbatMacro#0 = "I love the smell of napalm..."
CommbatMacro#1 = "Is that gasoline I smell?"
CommbatMacro#2 = "Ta da!"
CommbatMacro#3 = "Who wants some, huh? Who's next?"
CommbatMacro#4 = "I have something for you."
CommbatMacro#5 = "You just gonna stand there..."
CommbatMacro#6 = "That'll teach ya!"
CommbatMacro#7 = "Ooh, that wasn't a bit nice."
CommbatMacro#8 = "Amateurs!"
CommbatMacro#9 = "Fool! You are already dead."

[Game Options]
WeaponsV10x = 0
VanillaMode = 0
_EOF_
	if [[ ! -f "$home/.config/nblood/nblood.cfg" ]]; then
		cp "$md_inst/nblood.cfg" "$home/.config/nblood/nblood.cfg"
		chown -R $__user:$__user "$home/.config/nblood/nblood.cfg"
	fi

   cat >"$md_inst/nblood-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Blood"
qjoyLYT=\$(
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
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run Blood
pushd /opt/retropie/configs/ports/nblood
if [[ "\$1" == 'cryptic' ]]; then
	VC4_DEBUG=always_sync /opt/retropie/ports/nblood/nblood -ini CRYPTIC.INI -j=\$HOME/RetroPie/roms/ports/ksbuild/blood/
else
	VC4_DEBUG=always_sync /opt/retropie/ports/nblood/nblood -ini blood.ini -j=\$HOME/RetroPie/roms/ports/ksbuild/blood/
fi
popd

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/nblood-qjoy.sh"
}
