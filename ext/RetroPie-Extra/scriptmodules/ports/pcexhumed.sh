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

rp_module_id="pcexhumed"
rp_module_desc="Powerslave/Exhumed source port - Ken Silverman's Build Engine"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="Place Game Files in [ports/ksbuild/pcexhumed]: \nSTUFF.DAT\nDEMO.VCR\nBOOK.MOV\n \nOptional [CD Audio]:\ntrack02.ogg...track19.ogg\nexhumed02.ogg...exhumed19.ogg"
rp_module_section="exp"
rp_module_flags=""

function depends_pcexhumed() {
	# libsdl1.2-dev libsdl-mixer1.2-dev xorg xinit x11-xserver-utils
	local depends=(cmake build-essential libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev freepats)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
	isPlatform "kms" && depends+=(xorg matchbox-window-manager)
	getDepends "${depends[@]}"
}

function sources_pcexhumed() {
	gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/pcexhumed/Powerslave_48x48.xpm" "$md_build"
}

function build_pcexhumed() {
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
    make -j"$(nproc)" exhumed "${params[@]}"
	md_ret_require="$md_build"
}

function install_pcexhumed() {
    md_ret_files=(        
		'dn64widescreen.pk3'
        'pcexhumed'
        'pcexhumed.pk3'
		'nblood.pk3'
		'Powerslave_48x48.xpm'
    )
}

function game_data_pcexhumed() {
    if [[ ! -f "$romdir/ports/ksbuild/pcexhumed/STUFF.DAT" ]] && [[ ! -f "$romdir/ports/ksbuild/pcexhumed/BOOK.MOV" ]]; then
		mkRomDir "ports/ksbuild/pcexhumed"
		downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/pcexhumed/pcexhumed-rp-assets.tar.gz" "$romdir/ports/ksbuild/pcexhumed"
		chown -R $__user:$__user "$romdir/ports/ksbuild/pcexhumed"
	fi
}

function remove_pcexhumed() {
    if [[ -f "/usr/share/applications/Powerslave (Exhumed).desktop" ]]; then sudo rm -f "/usr/share/applications/Powerslave (Exhumed).desktop"; fi
    if [[ -f "$home/Desktop/Powerslave (Exhumed).desktop" ]]; then rm -f "$home/Desktop/Powerslave (Exhumed).desktop"; fi
}

function configure_pcexhumed() {
	if [[ ! -d "$home/.config/pcexhumed" ]]; then mkdir "$home/.config/pcexhumed"; fi
	if [[ ! -f "$home/.config/pcexhumed/pcexhumed_cvars.cfg" ]]; then touch "$home/.config/pcexhumed/pcexhumed_cvars.cfg"; fi
	if [[ "$(cat "$home/.config/pcexhumed/pcexhumed_cvars.cfg" | grep r_vsync)" == '' ]]; then
		echo 'r_vsync "1"' >> "$home/.config/pcexhumed/pcexhumed_cvars.cfg"
	else
		sed -i 's+r_vsync.*+r_vsync "1"+g' "$home/.config/pcexhumed/pcexhumed_cvars.cfg"
	fi
	chown -R $__user:$__user "$home/.config/pcexhumed"
    moveConfigDir "$home/.config/pcexhumed" "$md_conf_root/$md_id"
    # [WARN| Could not find main data file "nblood.pk3"!
    ln -s "$md_inst/nblood.pk3" "$md_conf_root/$md_id/nblood.pk3"
    ln -s "$md_inst/pcexhumed.pk3" "$md_conf_root/$md_id/pcexhumed.pk3"
    ln -s "$md_inst/dn64widescreen.pk3" "$md_conf_root/$md_id/dn64widescreen.pk3"
    chown -R $__user:$__user "$md_conf_root/$md_id"
	chmod 755 $md_inst/pcexhumed-qjoy.sh

	mkRomDir "ports/ksbuild/pcexhumed"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
	addPort "$md_id" "pcexhumed" "PCExhumed - Powerslave Source Port" "$launch_prefix$md_inst/pcexhumed.sh"
	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "pcexhumed" "PCExhumed - Powerslave Source Port" "$launch_prefix$md_inst/pcexhumed-qjoy.sh"
	fi

   cat >"$md_inst/$md_id.sh" << _EOF_
#!/bin/bash

# Run $md_id
pushd /opt/retropie/configs/ports/$md_id
VC4_DEBUG=always_sync /opt/retropie/ports/$md_id/$md_id  -j \$HOME/RetroPie/roms/ports/ksbuild/$md_id
popd

exit 0
_EOF_
    chmod 755 "$md_inst/$md_id.sh"

    cat >"$md_inst/pcexhumed.cfg" << _EOF_
[Setup]
CacheSize = 100663296
ForceSetup = 1
NoAutoLoad = 1

[Screen Setup]
ScreenBPP = 8
ScreenHeight = 1024
ScreenMode = 2
ScreenWidth = 1280
MaxRefreshFreq = 0
WindowPosX = -1
WindowPosY = -1
WindowPositioning = 0
FullScreen = 0
ScreenSize = 0
Gamma = 2

[Controls]
MouseButton0 = "Fire"
MouseButtonClicked0 = ""
MouseButton1 = "Strafe"
MouseButtonClicked1 = ""
MouseButton2 = "Move_Forward"
MouseButtonClicked2 = ""
MouseButton3 = ""
MouseButtonClicked3 = ""
MouseButton4 = ""
MouseButtonClicked4 = ""
MouseButton5 = ""
MouseButtonClicked5 = ""
MouseButton6 = ""
MouseButtonClicked6 = ""
MouseButton7 = ""
MouseButtonClicked7 = ""
MouseButton8 = ""
MouseButton9 = ""
MouseAnalogAxes0 = "analog_strafing"
MouseDigitalAxes0_0 = ""
MouseDigitalAxes0_1 = ""
MouseAnalogScale0 = 65536
MouseAnalogAxes1 = "analog_moving"
MouseDigitalAxes1_0 = ""
MouseDigitalAxes1_1 = ""
MouseAnalogScale1 = 65536
ControllerButton0 = ""
ControllerButtonClicked0 = ""
ControllerButton1 = ""
ControllerButtonClicked1 = ""
ControllerButton2 = ""
ControllerButtonClicked2 = ""
ControllerButton3 = ""
ControllerButtonClicked3 = ""
ControllerButton4 = ""
ControllerButtonClicked4 = ""
ControllerButton5 = ""
ControllerButtonClicked5 = ""
ControllerButton6 = ""
ControllerButtonClicked6 = ""
ControllerButton7 = ""
ControllerButtonClicked7 = ""
ControllerButton8 = ""
ControllerButtonClicked8 = ""
ControllerButton9 = ""
ControllerButtonClicked9 = ""
ControllerButton10 = ""
ControllerButtonClicked10 = ""
ControllerButton11 = ""
ControllerButtonClicked11 = ""
ControllerButton12 = ""
ControllerButtonClicked12 = ""
ControllerButton13 = ""
ControllerButtonClicked13 = ""
ControllerButton14 = ""
ControllerButtonClicked14 = ""
ControllerButton15 = ""
ControllerButtonClicked15 = ""
ControllerButton16 = ""
ControllerButtonClicked16 = ""
ControllerButton17 = ""
ControllerButtonClicked17 = ""
ControllerButton18 = ""
ControllerButtonClicked18 = ""
ControllerButton19 = ""
ControllerButtonClicked19 = ""
ControllerButton20 = ""
ControllerButtonClicked20 = ""
ControllerButton21 = ""
ControllerButtonClicked21 = ""
ControllerButton22 = ""
ControllerButtonClicked22 = ""
ControllerButton23 = ""
ControllerButtonClicked23 = ""
ControllerButton24 = ""
ControllerButtonClicked24 = ""
ControllerButton25 = ""
ControllerButtonClicked25 = ""
ControllerButton26 = ""
ControllerButtonClicked26 = ""
ControllerButton27 = ""
ControllerButtonClicked27 = ""
ControllerButton28 = ""
ControllerButtonClicked28 = ""
ControllerButton29 = ""
ControllerButtonClicked29 = ""
ControllerButton30 = ""
ControllerButtonClicked30 = ""
ControllerButton31 = ""
ControllerButtonClicked31 = ""
ControllerButton32 = ""
ControllerButtonClicked32 = ""
ControllerButton33 = ""
ControllerButtonClicked33 = ""
ControllerButton34 = ""
ControllerButtonClicked34 = ""
ControllerButton35 = ""
ControllerButtonClicked35 = ""
ControllerAnalogAxes0 = "analog_turning"
ControllerDigitalAxes0_0 = ""
ControllerDigitalAxes0_1 = ""
ControllerAnalogScale0 = 0
ControllerAnalogInvert0 = 0
ControllerAnalogDead0 = 0
ControllerAnalogSaturate0 = 0
ControllerAnalogAxes1 = "analog_turning"
ControllerDigitalAxes1_0 = ""
ControllerDigitalAxes1_1 = ""
ControllerAnalogScale1 = 0
ControllerAnalogInvert1 = 0
ControllerAnalogDead1 = 0
ControllerAnalogSaturate1 = 0
ControllerAnalogAxes2 = "analog_turning"
ControllerDigitalAxes2_0 = ""
ControllerDigitalAxes2_1 = ""
ControllerAnalogScale2 = 0
ControllerAnalogInvert2 = 0
ControllerAnalogDead2 = 0
ControllerAnalogSaturate2 = 0
ControllerAnalogAxes3 = "analog_turning"
ControllerDigitalAxes3_0 = ""
ControllerDigitalAxes3_1 = ""
ControllerAnalogScale3 = 0
ControllerAnalogInvert3 = 0
ControllerAnalogDead3 = 0
ControllerAnalogSaturate3 = 0
ControllerAnalogAxes4 = "analog_turning"
ControllerDigitalAxes4_0 = ""
ControllerDigitalAxes4_1 = ""
ControllerAnalogScale4 = 0
ControllerAnalogInvert4 = 0
ControllerAnalogDead4 = 0
ControllerAnalogSaturate4 = 0
ControllerAnalogAxes5 = "analog_turning"
ControllerDigitalAxes5_0 = ""
ControllerDigitalAxes5_1 = ""
ControllerAnalogScale5 = 0
ControllerAnalogInvert5 = 0
ControllerAnalogDead5 = 0
ControllerAnalogSaturate5 = 0
ControllerAnalogAxes6 = "analog_turning"
ControllerDigitalAxes6_0 = ""
ControllerDigitalAxes6_1 = ""
ControllerAnalogScale6 = 0
ControllerAnalogInvert6 = 0
ControllerAnalogDead6 = 0
ControllerAnalogSaturate6 = 0
ControllerAnalogAxes7 = "analog_turning"
ControllerDigitalAxes7_0 = ""
ControllerDigitalAxes7_1 = ""
ControllerAnalogScale7 = 0
ControllerAnalogInvert7 = 0
ControllerAnalogDead7 = 0
ControllerAnalogSaturate7 = 0
ControllerAnalogAxes8 = "analog_turning"
ControllerDigitalAxes8_0 = ""
ControllerDigitalAxes8_1 = ""
ControllerAnalogScale8 = 0
ControllerAnalogInvert8 = 0
ControllerAnalogDead8 = 0
ControllerAnalogSaturate8 = 0
_EOF_
	if [[ ! -f "$home/.config/pcexhumed/pcexhumed.cfg" ]]; then
		cp "$md_inst/pcexhumed.cfg" "$home/.config/pcexhumed/pcexhumed.cfg"
		chown -R $__user:$__user "$home/.config/pcexhumed/pcexhumed.cfg"
	fi

   cat >"$md_inst/pcexhumed-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Exhumed"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5538, xZone 29536, +key 40, -key 38
	Axis 2: gradient, dZone 9230, xZone 28382, +key 39, -key 25
	Axis 3: gradient, dZone 3922, +key 37, -key 0
	Axis 4: gradient, dZone 5768, xZone 28382, maxSpeed 15, mouse+h
	Axis 5: gradient, dZone 8768, maxSpeed 10, mouse+v
	Axis 6: gradient, throttle+, +key 105, -key 0
	Axis 7: +key 35, -key 34
	Axis 8: +key 116, -key 111
	Button 1: key 65
	Button 2: key 26
	Button 3: key 37
	Button 4: key 66
	Button 5: key 47
	Button 6: key 48
	Button 7: key 9
	Button 8: key 36
	Button 9: key 23
	Button 10: key 50
	Button 11: key 110
	Button 12: key 34
	Button 13: key 35
	Button 14: key 111
	Button 15: key 116
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run PCExhumed
pushd /opt/retropie/configs/ports/pcexhumed
VC4_DEBUG=always_sync /opt/retropie/ports/pcexhumed/pcexhumed  -j \$HOME/RetroPie/roms/ports/ksbuild/pcexhumed
popd

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/pcexhumed-qjoy.sh"

    cat >"$md_inst/Powerslave (Exhumed).desktop" << _EOF_
[Desktop Entry]
Name=Powerslave (Exhumed)
GenericName=Powerslave (Exhumed)
Comment=Powerslave (Exhumed)
Exec=$md_inst/$md_id.sh
Icon=$md_inst/Powerslave_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Powerslave;Exhumed
StartupWMClass=PowerslaveExhumed
Name[en_US]=Powerslave (Exhumed)
_EOF_
    chmod 755 "$md_inst/Powerslave (Exhumed).desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Powerslave (Exhumed).desktop" "$home/Desktop/Powerslave (Exhumed).desktop"; chown $__user:$__user "$home/Desktop/Powerslave (Exhumed).desktop"; fi
    mv "$md_inst/Powerslave (Exhumed).desktop" "/usr/share/applications/Powerslave (Exhumed).desktop"

    [[ "$md_mode" == "install" ]] && game_data_pcexhumed
    [[ "$md_mode" == "remove" ]] && remove_pcexhumed
}
