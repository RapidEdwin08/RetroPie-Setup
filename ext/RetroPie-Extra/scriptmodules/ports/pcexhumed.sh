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
rp_module_desc="PCExhumed - Powerslave source port"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
#rp_module_repo="https://github.com/Exarkuniv/NBlood.git"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="you need to put the 
STUFF.DAT
DEMO.VCR
BOOK.MOV
in the ports/ksbuild/pcexhumed folder

Recommended (but optional) - Add the games CD audio tracks as OGG files in the format exhumedXX.ogg or trackXX.ogg (where XX is the track number) 
to the same folder as pcexhumed.exe. The game includes tracks 02 to 19. These will provide the game with its music soundtrack 
and add storyline narration by the King Ramses NPC.
"
rp_module_section="exp"
rp_module_flags=""

function depends_pcexhumed() {
   # libsdl1.2-dev libsdl-mixer1.2-dev
   getDepends matchbox-window-manager cmake xorg xinit x11-xserver-utils xinit build-essential nasm libgl1-mesa-dev libglu1-mesa-dev libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev libgtk2.0-dev freepats
}

function sources_pcexhumed() {
	gitPullOrClone
	download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/pcexhumed/pcexhumed.cfg" "$md_build"
	download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/pcexhumed/pcexhumed-qjoy.sh" "$md_build"
}

function build_pcexhumed() {
    cd $md_build
    # RPi4/5 Bookworm # USE_OPENGL=0 = pcexhumed rednukem # USE_OPENGL=1 = nblood (blood)
    make exhumed LTO=0 SDL_TARGET=2 STARTUP_WINDOW=0 USE_OPENGL=0
	md_ret_require="$md_build"
}

function install_pcexhumed() {
    md_ret_files=(        
		'dn64widescreen.pk3'
        'pcexhumed'
        'pcexhumed.pk3'
		'nblood.pk3'
		'pcexhumed.cfg'
		'pcexhumed-qjoy.sh'
    )
}
	
function configure_pcexhumed() {
	if [[ ! -d "$home/.config/pcexhumed" ]]; then mkdir "$home/.config/pcexhumed"; fi
	if [[ ! -f "$home/.config/pcexhumed/pcexhumed.cfg" ]]; then cp -v pcexhumed.cfg "$home/.config/pcexhumed"; fi
	chown -R $__user:$__user "$home/.config/pcexhumed"
	chmod 755 $md_inst/pcexhumed-qjoy.sh

	mkRomDir "ports/ksbuild/pcexhumed"

	addPort "$md_id" "pcexhumed" "PCExhumed - Powerslave Source Port" "XINIT:$md_inst/pcexhumed -j $home/RetroPie/roms/ports/ksbuild/pcexhumed"
	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "pcexhumed" "PCExhumed - Powerslave Source Port" "XINIT:$md_inst/pcexhumed-qjoy.sh"
	fi
}
