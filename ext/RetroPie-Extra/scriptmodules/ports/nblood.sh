#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="nblood"
rp_module_desc="Nblood - Blood source port"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
#rp_module_repo="https://github.com/Exarkuniv/NBlood.git"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="you need to put the \n\BLOOD.INI, \n\BLOOD.RFF, \n\BLOOD000.DEM, ..., BLOOD003.DEM (optional), \n\GUI.RFF, \n\SOUNDS.RFF, \n\SURFACE.DAT, \n\TILES000.ART, ..., TILES017.ART, \n\VOXEL.DAT in ports/ksbuild/blood
,\n\Cryptic Passage,\n\
CP01.MAP, ..., CP09.MAP,\n\CPART07.AR_,\n\CPART15.AR_,\n\CPBB01.MAP, ..., CPBB04.MAP,\n\CPSL.MAP,\n\CRYPTIC.INI\n\CRYPTIC.SMK \n\CRYPTIC.WAV"
rp_module_section="exp"
rp_module_flags=""

function depends_nblood() {
   # libsdl1.2-dev libsdl-mixer1.2-dev
   getDepends matchbox cmake xorg xinit x11-xserver-utils xinit build-essential nasm libgl1-mesa-dev libglu1-mesa-dev libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev libgtk2.0-dev freepats
}

function sources_nblood() {
	gitPullOrClone
	download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/nblood/nblood.cfg" "$md_build"
	download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/nblood/nblood-qjoy.sh" "$md_build"
}

function build_nblood() {
    cd $md_build
    # RPi4/5 Bookworm # USE_OPENGL=0 = pcexhumed rednukem # USE_OPENGL=1 = nblood (blood)
    make blood LTO=0 SDL_TARGET=2 STARTUP_WINDOW=0
	md_ret_require="$md_build"
}

function install_nblood() {
    md_ret_files=(        
		'dn64widescreen.pk3'
		'nblood'
		'nblood.pk3'
		'nblood.cfg'
		'nblood-qjoy.sh'
    )
}
	
function configure_nblood() {
	if [[ ! -d "$home/.config/nblood" ]]; then mkdir "$home/.config/nblood"; fi
	if [[ ! -f "$home/.config/nblood/nblood.cfg" ]]; then cp -v nblood.cfg "$home/.config/nblood"; fi
	chown -R $__user:$__user "$home/.config/nblood"
	chmod 755 $md_inst/nblood-qjoy.sh

	mkRomDir "ports/ksbuild/blood"
	
	addPort "$md_id" "nblood" "Nblood - Blood Source Port" "XINIT:$md_inst/nblood -ini blood.ini -j $home/RetroPie/roms/ports/ksbuild/blood"
	addPort "$md_id" "nblood-cp" "NBlood - Blood Cryptic Passage Source Port" "XINIT:$md_inst/nblood -ini CRYPTIC.INI -j $home/RetroPie/roms/ports/ksbuild/blood"

	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "nblood" "Nblood - Blood Source Port +QJoyPad" "XINIT:$md_inst/nblood-qjoy.sh"
		addPort "$md_id+qjoypad" "nblood-cp" "NBlood - Blood Cryptic Passage Source Port +QJoyPad" "XINIT:$md_inst/nblood-qjoy.sh cryptic"
	fi
}
