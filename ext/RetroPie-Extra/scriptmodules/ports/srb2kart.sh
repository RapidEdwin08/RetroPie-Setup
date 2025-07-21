#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

# Input version of srb2kart
srb2kVER=v1.6

rp_module_id="srb2kart"
rp_module_desc="Sonic Robo Blast 2 Kart - 3D Sonic the Hedgehog fan-game based on Sonic Robo Blast 2 built using a modified version of the Doom Legacy source port of Doom"
rp_module_licence="GPL2 https://raw.githubusercontent.com/STJr/Kart-Public/master/LICENSE"
rp_module_section="exp"

function depends_srb2kart() {
    getDepends cmake libsdl2-dev libsdl2-mixer-dev
}

function sources_srb2kart() {
    gitPullOrClone "$md_build" https://github.com/STJr/Kart-Public.git $srb2kVER
    mkdir assets/installer
    downloadAndExtract https://github.com/STJr/Kart-Public/releases/download/$srb2kVER/AssetsLinuxOnly.zip "$md_build/assets/installer/"
}

function build_srb2kart() {
    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$md_inst"
    make
    md_ret_require="$md_build/build/bin/srb2kart"
}

function install_srb2kart() {
    # Copy and dereference to get srb2kart [binary] rather than a symlink to srb2kart-version
    cp -L 'build/bin/srb2kart' "$md_inst/srb2kart"
    # Clean up any 0lder srb2kart Config/Assets before Installing
    if [[ -f "$md_conf_root/$md_id/kartconfig.cfg" ]]; then rm "$md_conf_root/$md_id/kartconfig.cfg"; fi
    if [[ -f "$md_conf_root/$md_id/kartdata.dat" ]]; then rm "$md_conf_root/$md_id/kartdata.dat"; fi
    if [[ -f "$md_conf_root/$md_id/log.txt" ]]; then rm "$md_conf_root/$md_id/log.txt"; fi
    if [[ -d "$md_inst/mdls" ]]; then rm -Rf "$md_inst/mdls"; fi
    if [[ -f "$md_inst/mdls.dat" ]]; then rm "$md_inst/mdls.dat"; fi
    if [[ -f "$md_inst/srb2.srb" ]]; then rm "$md_inst/srb2.srb"; fi
    if [[ -f "$md_inst/patch.kart" ]]; then rm "$md_inst/patch.kart"; fi
    if [[ -f "$md_inst/README.txt" ]]; then rm "$md_inst/README.txt"; fi
    if [[ ! $(ls "$md_inst/*.kart") == '' ]]; then rm "$md_inst/*.kart"; fi
    if [[ ! $(ls "$md_inst/LICENSE*") == '' ]]; then rm "$md_inst/LICENSE*"; fi
    # Copy srb2kart assets
    cp -R "assets/installer/mdls" "$md_inst"
    md_ret_files=(
        'assets/installer/bonuschars.kart'
        'assets/installer/chars.kart'
        'assets/installer/gfx.kart'
        'assets/installer/maps.kart'
        'assets/installer/music.kart'
        'assets/installer/sounds.kart'
        'assets/installer/srb2.srb'
        'assets/installer/textures.kart'
        'assets/installer/HISTORY.txt'
        'assets/installer/LICENSE.txt'
        'assets/installer/LICENSE-3RD-PARTY.txt'
        'assets/installer/README.txt'
        'assets/installer/mdls.dat'
    )
}

function configure_srb2kart() {
    addPort "$md_id" "srb2kart" "Sonic Robo Blast 2 Kart" "pushd $md_inst; ./srb2kart; popd"
    moveConfigDir "$home/.srb2kart"  "$md_conf_root/$md_id"
}

