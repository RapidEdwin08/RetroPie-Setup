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

rp_module_id="dhewm3"
rp_module_desc="dhewm3 - Doom 3"
rp_module_licence="GPL3 https://github.com/dhewm/dhewm3/blob/master/COPYING.txt"
rp_module_repo="git https://github.com/dhewm/dhewm3.git"
rp_module_help="Please copybase/pak000.pk4\n\nbase/pak001.pk4\n\nbase/pak002.pk4\n\nbase/pak003.pk4\n\nbase/pak004.pk4\n\nbase/pak005.pk4\n\nbase/pak006.pk4\n\nbase/pak007.pk4\n\nbase/pak008.pk4\n\nand if you have the expansion:\n\nd3xp/pak000.pk4\n\nd3xp/pak001.pk4\n\nInto the $romdir/doom3/base and $romdir/doom3/d3xp directories"
rp_module_section="exp"
rp_module_flags=""

function depends_dhewm3() {
    getDepends cmake libsdl2-dev libopenal-dev libogg-dev libvorbis-dev zlib1g-dev libcurl4-openssl-dev xorg
}

function sources_dhewm3() {
    gitPullOrClone
}

function build_dhewm3() {
    mkdir "$md_build/build"

    cd "$md_build/build"

    cmake "../neo"
    make clean
    make
    md_ret_require="$md_build/build"
}

function install_dhewm3() {
    md_ret_files=(
        "build/dhewm3"
        "build/d3xp.so"
        "build/base.so"
	"base"
    )
}

function configure_dhewm3() {
    if isPlatform "rpi"; then
        addPort "$md_id" "doom3" "Doom 3" "XINIT:$md_inst/dhewm3"
    else
        addPort "$md_id" "doom3" "Doom 3" "$md_inst/dhewm3"
    fi

    mkRomDir "ports/doom3/base"
    mkRomDir "ports/doom3/d3xp"
    chown -R $__user:$__user "$home/RetroPie/roms/ports/doom3"
    chown -R $__user:$__user "$home/RetroPie/roms/ports/doom3/base"

    moveConfigDir "$md_inst/base" "$romdir/ports/doom3/base"
    moveConfigDir "$md_inst/d3xp" "$romdir/ports/doom3/d3xp"
}
