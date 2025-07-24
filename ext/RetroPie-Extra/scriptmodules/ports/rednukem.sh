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
   # libsdl1.2-dev libsdl-mixer1.2-dev
   getDepends matchbox cmake xorg xinit x11-xserver-utils xinit build-essential nasm libgl1-mesa-dev libglu1-mesa-dev libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev libgtk2.0-dev freepats
  
}

function sources_rednukem() {
	gitPullOrClone
	download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/rednukem/rednukem.cfg" "$md_build"
}

function build_rednukem() {
    cd $md_build
    # RPi4/5 Bookworm # USE_OPENGL=0 = pcexhumed rednukem # USE_OPENGL=1 = nblood (blood)
    make rr LTO=0 SDL_TARGET=2 STARTUP_WINDOW=0 USE_OPENGL=0
	md_ret_require="$md_build"
}

function install_rednukem() {
    md_ret_files=(        
		'dn64widescreen.pk3'
		'nblood.pk3'
		'rednukem'
		'rednukem.cfg'
    )
}
	
function configure_rednukem() {
	if [[ ! -d "$home/.config/rednukem" ]]; then mkdir "$home/.config/rednukem"; fi
	if [[ ! -f "$home/.config/nblood/rednukem.cfg" ]]; then cp -v nblood.cfg "$home/.config/rednukem"; fi
	chown -R $__user:$__user "$home/.config/rednukem"
	
	mkRomDir "ports/ksbuild/redneck"
	mkRomDir "ports/ksbuild/ridesagain"
	mkRomDir "ports/ksbuild/route66"
	
	launch_prefix=XINIT-WM; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WM)" == '' ]]; then launch_prefix=XINIT; fi
	addPort "$md_id-redneck" "rednukem-redneck" "Rednukem - Redneck Rampage Source Port" "$launch_prefix:$md_inst/rednukem -j $home/RetroPie/roms/ports/ksbuild/redneck"
	addPort "$md_id-ridesagain" "rednukem-ridesagain" "Rednukem - Redneck Rampage Rides Again Source Port" "$launch_prefix:$md_inst/rednukem -j $home/RetroPie/roms/ports/ksbuild/ridesagain"
	addPort "$md_id-route66" "rednukem-route66" "Rednukem - Redneck Rampage Route 66 Source Port" "$launch_prefix:$md_inst/rednukem -j $home/RetroPie/roms/ports/ksbuild/route66 -g $home/RetroPie/roms/ports/ksbuild/route66/RT66.GRP -mx $home/RetroPie/roms/ports/ksbuild/route66/RT66.CON -j $home/RetroPie/roms/ports/ksbuild/redneck"
}
