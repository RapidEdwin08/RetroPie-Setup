#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-genesis-plus-gx"
rp_module_desc="Sega 8/16 bit emu - Genesis Plus (enhanced) port for libretro"
rp_module_help="ROM Extensions: .bin .cue .gen .gg .iso .md .sg .smd .sms .zip\nCopy your Game Gear roms to $romdir/gamegear\nMasterSystem roms to $romdir/mastersystem\nMegadrive / Genesis roms to $romdir/megadrive\nSG-1000 roms to $romdir/sg-1000\nSegaCD roms to $romdir/segacd\nThe Sega CD requires the BIOS files bios_CD_U.bin and bios_CD_E.bin and bios_CD_J.bin copied to $biosdir"
rp_module_licence="NONCOM https://raw.githubusercontent.com/libretro/Genesis-Plus-GX/master/LICENSE.txt"
rp_module_repo="git https://github.com/libretro/Genesis-Plus-GX.git master :_get_commit_lr-genesis-plus-gx"
rp_module_section="main"

function _get_commit_lr-genesis-plus-gx() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch_tag=master
    local branch_commit="$(git ls-remote https://github.com/libretro/Genesis-Plus-GX.git $branch_tag HEAD | grep $branch_tag  | tail -1 | awk '{ print $1}' | cut -c -8)"

    #echo ee71e47c; # 20260331 add linux-aarch64 build (#401)
    #echo c4d1afb1; # 20260417 Fetch translations & Recreate libretro_core_options_intl.h
    echo $branch_commit
}

function sources_lr-genesis-plus-gx() {
    gitPullOrClone
    if [[ "$(_get_commit_lr-genesis-plus-gx)" == "c4d1afb1" ]]; then
        applyPatch "$md_data/death_and_lead_ee71e47c.diff" # 033df9b7
        applyPatch "$md_data/yx5200_musicpath_ee71e47c.diff" # musicpath [rompath/rombasename] for HW_YX5200
    fi
}

function build_lr-genesis-plus-gx() {
    make -f Makefile.libretro clean
    make -f Makefile.libretro
    md_ret_require="$md_build/genesis_plus_gx_libretro.so"
}

function install_lr-genesis-plus-gx() {
    md_ret_files=(
        'genesis_plus_gx_libretro.so'
        'HISTORY.txt'
        'LICENSE.txt'
        'README.md'
    )
}

function configure_lr-genesis-plus-gx() {
    local system
    local def
    for system in gamegear mastersystem megadrive sg-1000 segacd; do
        def=0
        [[ "$system" == "gamegear" || "$system" == "sg-1000" ]] && def=1
        # always default emulator for non armv6
        ! isPlatform "armv6" && def=1
        mkRomDir "$system"
        defaultRAConfig "$system"
        addEmulator "$def" "$md_id" "$system" "$md_inst/genesis_plus_gx_libretro.so"
        addSystem "$system"
    done
}
