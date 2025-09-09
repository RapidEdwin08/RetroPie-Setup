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
rp_module_desc="Blood source port - Ken Silverman's Build Engine"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="Place Game Files in [ports/ksbuild/blood]: \nBLOOD.INI\nBLOOD.RFF\nBLOOD000.DEM...BLOOD003.DEM (optional)\nGUI.RFF\nSOUNDS.RFF\nSURFACE.DAT\nTILES000.ART...TILES017.ART\nVOXEL.DAT\n \n[Cryptic Passage]:\nCRYPTIC.INI\nCRYPTIC.SMK\nCRYPTIC.WAV\nCP01.MAP...CP09.MAP\nCPART07.AR_\nCPART15.AR_\nCPBB01.MAP...CPBB04.MAP\nCPSL.MAP"
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
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/nblood/Blood_48x48.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/nblood/BloodCP_32x64.xpm" "$md_build"
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
		'Blood_48x48.xpm'
		'BloodCP_32x64.xpm'
    )
}

function remove_nblood() {
    if [[ -f "/usr/share/applications/Blood.desktop" ]]; then sudo rm -f "/usr/share/applications/Blood.desktop"; fi
    if [[ -f "$home/Desktop/Blood.desktop" ]]; then rm -f "$home/Desktop/Blood.desktop"; fi
    if [[ -f "/usr/share/applications/Blood Cryptic Passage.desktop" ]]; then sudo rm -f "/usr/share/applications/Blood Cryptic Passage.desktop"; fi
    if [[ -f "$home/Desktop/Blood Cryptic Passage.desktop" ]]; then rm -f "$home/Desktop/Blood Cryptic Passage.desktop"; fi
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
    # [WARN| Could not find main data file "nblood.pk3"!
    ln -s "$md_inst/nblood.pk3" "$md_conf_root/$md_id/nblood.pk3"
    ln -s "$md_inst/dn64widescreen.pk3" "$md_conf_root/$md_id/dn64widescreen.pk3"
    chown -R $__user:$__user "$md_conf_root/$md_id"

	mkRomDir "ports/ksbuild/blood"
	
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
	addPort "$md_id" "nblood" "Blood (NBlood)" "$launch_prefix$md_inst/nblood.sh"
	addPort "$md_id" "nblood-cp" "Blood Cryptic Passage (NBlood)" "$launch_prefix$md_inst/nblood.sh cryptic"

	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "nblood" "Blood (NBlood)" "$launch_prefix$md_inst/nblood-qjoy.sh"
		addPort "$md_id+qjoypad" "nblood-cp" "Blood Cryptic Passage (NBlood)" "$launch_prefix$md_inst/nblood-qjoy.sh cryptic"
	fi

   cat >"$md_inst/$md_id.sh" << _EOF_
#!/bin/bash

# Run $md_id
pushd /opt/retropie/configs/ports/$md_id
if [[ "\$1" == 'cryptic' ]]; then
	VC4_DEBUG=always_sync /opt/retropie/ports/$md_id/$md_id -ini CRYPTIC.INI -j=\$HOME/RetroPie/roms/ports/ksbuild/blood/
else
	VC4_DEBUG=always_sync /opt/retropie/ports/$md_id/$md_id -ini blood.ini -j=\$HOME/RetroPie/roms/ports/ksbuild/blood/
fi
popd

exit 0
_EOF_
    chmod 755 "$md_inst/$md_id.sh"

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

    cat >"$md_inst/Blood.desktop" << _EOF_
[Desktop Entry]
Name=Blood
GenericName=Blood
Comment=Blood
Exec=$md_inst/$md_id.sh
Icon=$md_inst/Blood_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Blood
StartupWMClass=Blood
Name[en_US]=Blood
_EOF_
    chmod 755 "$md_inst/Blood.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Blood.desktop" "$home/Desktop/Blood.desktop"; chown $__user:$__user "$home/Desktop/Blood.desktop"; fi
    mv "$md_inst/Blood.desktop" "/usr/share/applications/Blood.desktop"

    cat >"$md_inst/Blood Cryptic Passage.desktop" << _EOF_
[Desktop Entry]
Name=Blood Cryptic Passage
GenericName=Blood Cryptic Passage
Comment=Blood Cryptic Passage
Exec=$md_inst/$md_id.sh cryptic
Icon=$md_inst/BloodCP_32x64.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Blood;Cryptic;Passage
StartupWMClass=BloodCrypticPassage
Name[en_US]=Blood Cryptic Passage
_EOF_
    chmod 755 "$md_inst/Blood Cryptic Passage.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Blood Cryptic Passage.desktop" "$home/Desktop/Blood Cryptic Passage.desktop"; chown $__user:$__user "$home/Desktop/Blood Cryptic Passage.desktop"; fi
    mv "$md_inst/Blood Cryptic Passage.desktop" "/usr/share/applications/Blood Cryptic Passage.desktop"

    [[ "$md_mode" == "remove" ]] && remove_nblood
}
