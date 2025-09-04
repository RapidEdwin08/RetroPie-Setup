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

rp_module_id="rednukem"
rp_module_desc="Rednukem - Redneck Rampage source port"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
#rp_module_repo="https://github.com/Exarkuniv/NBlood.git"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="you need to put the REDNECK.GRP, REDNECK.RTS, optionally CD audio tracks as OGG file in the format trackXX.ogg (where XX is the track number)
ports/ksbuild/rednukem"
rp_module_section="exp"
rp_module_flags=""

function depends_rednukemd() {
	# libsdl1.2-dev libsdl-mixer1.2-dev xorg xinit x11-xserver-utils
	local depends=(cmake build-essential libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev freepats)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
	isPlatform "kms" && depends+=(xorg matchbox-window-manager)
	getDepends "${depends[@]}"
}

function sources_rednukem() {
	gitPullOrClone
}

function build_rednukem() {
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
    make -j"$(nproc)" rr "${params[@]}"
	md_ret_require="$md_build"
}

function install_rednukem() {
    md_ret_files=(        
		'dn64widescreen.pk3'
		'nblood.pk3'
		'rednukem'
    )
}
	
function configure_rednukem() {
	if [[ ! -d "$home/.config/rednukem" ]]; then mkdir "$home/.config/rednukem"; fi
	if [[ ! -f "$home/.config/rednukem/rednukem_cvars.cfg" ]]; then touch "$home/.config/rednukem/rednukem_cvars.cfg"; fi
	if [[ "$(cat "$home/.config/rednukem/rednukem_cvars.cfg" | grep r_vsync)" == '' ]]; then
		echo 'r_vsync "1"' >> "$home/.config/rednukem/rednukem_cvars.cfg"
	else
		sed -i 's+r_vsync.*+r_vsync "1"+g' "$home/.config/rednukem/rednukem_cvars.cfg"
	fi
	chown -R $__user:$__user "$home/.config/rednukem"
    moveConfigDir "$home/.config/rednukem" "$md_conf_root/$md_id-redneck"
    chown -R $__user:$__user "$md_conf_root/$md_id-redneck"
	
	mkRomDir "ports/ksbuild/redneck"
	mkRomDir "ports/ksbuild/ridesagain"
	mkRomDir "ports/ksbuild/route66"
	
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
	addPort "$md_id-redneck" "rednukem-redneck" "Rednukem - Redneck Rampage Source Port" "$launch_prefix$md_inst/rednukem -j $home/RetroPie/roms/ports/ksbuild/redneck"
	addPort "$md_id-ridesagain" "rednukem-ridesagain" "Rednukem - Redneck Rampage Rides Again Source Port" "$launch_prefix$md_inst/rednukem -j $home/RetroPie/roms/ports/ksbuild/ridesagain"
	addPort "$md_id-route66" "rednukem-route66" "Rednukem - Redneck Rampage Route 66 Source Port" "$launch_prefix$md_inst/rednukem -j $home/RetroPie/roms/ports/ksbuild/route66 -g $home/RetroPie/roms/ports/ksbuild/route66/RT66.GRP -mx $home/RetroPie/roms/ports/ksbuild/route66/RT66.CON -j $home/RetroPie/roms/ports/ksbuild/redneck"

    cat >"$md_inst/rednukem.cfg" << _EOF_
[Misc]
Executions = 6

[Setup]
ConfigVersion = 342
ForceSetup = 1
NoAutoLoad = 1
CacheSize = 201326592
SelectedGRP = "REDNECK.GRP"

[Screen Setup]
ScreenBPP = 8
ScreenHeight = 1080
ScreenMode = 2
ScreenWidth = 1920
WindowPositioning = 0
WindowPosX = -1
WindowPosY = -1
MaxRefreshFreq = 0
Out = 0
Password = ""

[Controls]
MouseButton0 = "Fire"
MouseButton1 = "Jetpack"
MouseButton2 = "MedKit"
MouseButton4 = "Previous_Weapon"
MouseButton5 = "Next_Weapon"
MouseAnalogAxes0 = "analog_turning"
MouseAnalogAxes1 = "analog_moving"
ControllerButton0 = "Jump"
ControllerButton1 = "Open"
ControllerButton2 = "Crouch"
ControllerButton3 = "NightVision"
ControllerButton4 = "Map"
ControllerButton7 = "Run"
ControllerButton8 = "Center_View"
ControllerButton9 = "Previous_Weapon"
ControllerButton10 = "Next_Weapon"
ControllerButton11 = "AutoRun"
ControllerButton12 = "Inventory"
ControllerButton13 = "Inventory_Left"
ControllerButton14 = "Inventory_Right"
ControllerButton15 = "Third_Person_View"
ControllerAnalogAxes0 = "analog_strafing"
ControllerAnalogScale0 = 98304
ControllerAnalogInvert0 = 0
ControllerAnalogAxes1 = "analog_moving"
ControllerAnalogScale1 = 98304
ControllerAnalogInvert1 = 0
ControllerAnalogAxes2 = "analog_turning"
ControllerAnalogInvert2 = 0
ControllerAnalogAxes3 = "analog_lookingupanddown"
ControllerAnalogInvert3 = 0
ControllerDigitalAxes4_1 = "Alt_Fire"
ControllerAnalogInvert4 = 0
ControllerDigitalAxes5_1 = "Fire"
ControllerAnalogInvert5 = 0
ControllerAnalogInvert6 = 0
ControllerAnalogInvert7 = 0
ControllerAnalogInvert8 = 0
ControllerAnalogScale2 = 98304

[Comm Setup]
PlayerName = ""
RTSName = "REDNECK.RTS"
CommbatMacro#0 = "An inspiration for birth control."
CommbatMacro#1 = "You're gonna die for that!"
CommbatMacro#2 = "It hurts to be you."
CommbatMacro#3 = "Lucky son of a bitch."
CommbatMacro#4 = "Hmmm... payback time."
CommbatMacro#5 = "You bottom dwelling scum sucker."
CommbatMacro#6 = "Damn, you're ugly."
CommbatMacro#7 = "Ha ha ha... wasted!"
CommbatMacro#8 = "You suck!"
CommbatMacro#9 = "AARRRGHHHHH!!!"

[MapTimes]
MD4_6d3ff15258aa7426d96daf06eac6e080 = 359
_EOF_
	if [[ ! -f "$home/.config/rednukem/rednukem.cfg" ]]; then
		cp "$md_inst/rednukem.cfg" "$home/.config/rednukem/rednukem.cfg"
		chown -R $__user:$__user "$home/.config/rednukem/rednukem.cfg"
	fi
}
