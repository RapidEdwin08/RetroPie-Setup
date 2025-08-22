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

rp_module_id="chocolate-doom"
rp_module_desc="Chocolate Doom - Enhanced port of the official DOOM source"
rp_module_licence="GPL2 https://raw.githubusercontent.com/chocolate-doom/chocolate-doom/sdl2-branch/COPYING"
rp_module_help="Location of [iWAD] files:\n$romdir/ports/doom/\n \nRe-Install [chocolate-doom] to Auto-Create entries for each [iWAD] for EmulationStation.\nRun 'chocolate-doom-setup' to configure your Controls and Options."
if [[ "$__os_debian_ver" -le 10 ]]; then
   rp_module_repo="git https://github.com/chocolate-doom/chocolate-doom.git master 15cfe539f9818152cecb14d9a0cda9aca40fa018"
else
   rp_module_repo="git https://github.com/chocolate-doom/chocolate-doom.git master"
fi
rp_module_section="exp"
rp_module_flags="!mali"

function depends_chocolate-doom() {
    local depends=(libsdl2-dev libsdl2-net-dev libsdl2-mixer-dev libsamplerate0-dev libpng-dev automake autoconf freepats)
    if [[ $(apt-cache search python3-pil) == '' ]]; then
      depends+=(python-pil)
   else
      depends+=(python3-pil)
   fi
   getDepends "${depends[@]}"
}

function sources_chocolate-doom() {
    gitPullOrClone
}

function build_chocolate-doom() {
    ./autogen.sh
    ./configure --prefix="$md_inst"
    make -j"$(nproc)"
    md_ret_require="$md_build/src/chocolate-doom"
    md_ret_require="$md_build/src/chocolate-hexen"
    md_ret_require="$md_build/src/chocolate-heretic"
    md_ret_require="$md_build/src/chocolate-strife"
}

function install_chocolate-doom() {
    md_ret_files=(
        'src/chocolate-doom'
        'src/chocolate-hexen'
        'src/chocolate-heretic'
        'src/chocolate-strife'
        'src/chocolate-doom-setup'
        'src/chocolate-hexen-setup'
        'src/chocolate-heretic-setup'
        'src/chocolate-strife-setup'
        'src/chocolate-setup'
        'src/chocolate-server'
    )
}

function game_data_chocolate-doom() {
    mkRomDir "ports"
    mkRomDir "ports/doom"
    if [[ ! -f "$romdir/ports/doom/doom1.wad" ]]; then
        wget "$__archive_url/doom1.wad" -O "$romdir/ports/doom/doom1.wad"
    fi

    if [[ ! -f "$romdir/ports/doom/freedoom1.wad" ]]; then
        wget "https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip"
        unzip freedoom-0.13.0.zip
        mv freedoom-0.13.0/* "$romdir/ports/doom"
        rm -rf freedoom-0.13.0
        rm freedoom-0.13.0.zip
    fi
}

function configure_chocolate-doom() {
    moveConfigDir "$home/.local/share/chocolate-doom" "$md_conf_root/ports/chocolate-doom"
    chown -R $__user:$__user "$md_conf_root/ports/chocolate-doom"

    # Temporary until the official RetroPie WAD selector is complete.
    if [[ -f "$romdir/ports/doom/doom1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doom1.wad"
       addPort "$md_id" "chocolate-doom1" "Chocolate Doom Shareware" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doom1.wad"
    fi

    if [[ -f "$romdir/ports/doom/doom.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doom.wad"
       addPort "$md_id" "chocolate-doom" "Chocolate Doom Registered" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doom.wad"
    fi

    if [[ -f "$romdir/ports/doom/freedoom1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/freedoom1.wad"
       addPort "$md_id" "chocolate-freedoom1" "Chocolate Free Doom: Phase 1" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/freedoom1.wad"
    fi

    if [[ -f "$romdir/ports/doom/freedoom2.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/freedoom2.wad"
       addPort "$md_id" "chocolate-freedoom2" "Chocolate Free Doom: Phase 2" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/freedoom2.wad"
    fi

    if [[ -f "$romdir/ports/doom/doom2.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doom2.wad"
       addPort "$md_id" "chocolate-doom2" "Chocolate Doom II: Hell on Earth" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doom2.wad"
    fi

    if [[ -f "$romdir/ports/doom/doomu.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doomu.wad"
       addPort "$md_id" "chocolate-doomu" "Chocolate Ultimate Doom" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doomu.wad"
    fi

    if [[ -f "$romdir/ports/doom/tnt.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/tnt.wad"
       addPort "$md_id" "chocolate-doomtnt" "Chocolate Final Doom - TNT: Evilution" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/tnt.wad"
    fi

    if [[ -f "$romdir/ports/doom/plutonia.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/plutonia.wad"
       addPort "$md_id" "chocolate-doomplutonia" "Chocolate Final Doom - The Plutonia Experiment" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/plutonia.wad"
    fi

    if [[ -f "$romdir/ports/doom/heretic1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/heretic1.wad"
       addPort "$md_id" "chocolate-heretic1" "Chocolate Heretic Shareware" "$md_inst/chocolate-heretic -iwad $romdir/ports/doom/heretic1.wad"
    fi

    if [[ -f "$romdir/ports/doom/heretic.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/heretic.wad"
       addPort "$md_id" "chocolate-heretic" "Chocolate Heretic Registered" "$md_inst/chocolate-heretic -iwad $romdir/ports/doom/heretic.wad"
    fi

    if [[ -f "$romdir/ports/doom/hexen.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/hexen.wad"
       addPort "$md_id" "chocolate-hexen" "Chocolate Hexen" "$md_inst/chocolate-hexen -iwad $romdir/ports/doom/hexen.wad"
    fi

    if [[ -f "$romdir/ports/doom/hexdd.wad" && -f "$romdir/ports/doom/hexen.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/hexdd.wad"
       addPort "$md_id" "chocolate-hexdd" "Chocolate Hexen: Deathkings of the Dark Citadel" "$md_inst/chocolate-hexen -iwad $romdir/ports/doom/hexen.wad -file $romdir/ports/doom/hexdd.wad"
    fi

    if [[ -f "$romdir/ports/doom/strife1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/strife1.wad"
       addPort "$md_id" "chocolate-strife1" "Chocolate Strife" "$md_inst/chocolate-strife -iwad $romdir/ports/doom/strife1.wad"
    fi

    [[ "$md_mode" == "install" ]] && game_data_chocolate-doom
    [[ "$md_mode" == "remove" ]] && return

}
