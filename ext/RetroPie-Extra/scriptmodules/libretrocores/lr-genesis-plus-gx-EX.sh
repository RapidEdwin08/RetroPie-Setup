#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# [lr-genesis-plus-gx-EX + Expanded Rom Size Support] https://github.com/BillyTimeGames/Genesis-Plus-GX-Expanded-Rom-Size.git +P4PR1UM Compatibility (202507)

rp_module_id="lr-genesis-plus-gx-EX"
rp_module_desc="Fork of lr-genesis-plus-gx + Expanded Rom Size Support"
rp_module_help="ROM Extensions: .bin .cue .gen .gg .iso .md .sg .smd .sms .zip\nCopy your Game Gear roms to $romdir/gamegear\nMasterSystem roms to $romdir/mastersystem\nMegadrive / Genesis roms to $romdir/megadrive\nSG-1000 roms to $romdir/sg-1000\nSegaCD roms to $romdir/segacd\nThe Sega CD requires the BIOS files bios_CD_U.bin and bios_CD_E.bin and bios_CD_J.bin copied to $biosdir"
rp_module_licence="NONCOM https://raw.githubusercontent.com/libretro/Genesis-Plus-GX/master/LICENSE.txt"
rp_module_repo="git https://github.com/RapidEdwin08/Genesis-Plus-GX-Expanded-Rom-Size.git master"
rp_module_section="exp"

function sources_lr-genesis-plus-gx-EX() {
    gitPullOrClone "$md_build" https://github.com/RapidEdwin08/Genesis-Plus-GX-Expanded-Rom-Size.git
}

function build_lr-genesis-plus-gx-EX() {
    make -f Makefile.libretro clean
    make -f Makefile.libretro
    md_ret_require="$md_build/genesis_plus_gx_libretro.so"
}

function install_lr-genesis-plus-gx-EX() {
    md_ret_files=(
        'genesis_plus_gx_libretro.so'
        'HISTORY.txt'
        'LICENSE.txt'
        'README.md'
    )
}

function configure_lr-genesis-plus-gx-EX() {
    local system
    local def
    for system in gamegear mastersystem megadrive sg-1000 segacd; do
        def=0
        [[ "$system" == "gamegear" || "$system" == "sg-1000" ]] && def=1
        # always default emulator for non armv6
        ! isPlatform "armv6" && def=1
        mkRomDir "$system"
        addEmulator "$def" "$md_id" "$system" "$md_inst/genesis_plus_gx_libretro.so"
        addSystem "$system"
    done

    if [ "$(cat /opt/retropie/configs/all/emulators.cfg | grep -e megadrive_paprium -e megadrive_Paprium)" == '' ]; then
        echo 'megadrive_paprium = "lr-genesis-plus-gx-EX"' >> /opt/retropie/configs/all/emulators.cfg
        echo 'megadrive_Paprium = "lr-genesis-plus-gx-EX"' >> /opt/retropie/configs/all/emulators.cfg
    fi
}
