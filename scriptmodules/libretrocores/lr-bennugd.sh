#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-bennugd"
rp_module_desc="BennuGD as a libretro core"
rp_module_help="ROM Extensions: .dat .dcb\n\nCopy your games to $romdir/bennugd"
rp_module_licence="GPL3"
rp_module_repo="git https://github.com/diekleinekuh/BennuGD_libretro.git master"
rp_module_section="exp"
rp_module_flags=""

function depends_lr-bennugd() {
    getDepends cmake libssl-dev libogg-dev libvorbis-dev libmikmod-dev libpng-dev zlib1g-dev libfreetype6-dev
}


function sources_lr-bennugd() {
    gitPullOrClone
}

function build_lr-bennugd() {
    mkdir build
    cd build
    cmake .. -DNO_SYSTEM_DEPENDENCIES=OFF -DCMAKE_BUILD_TYPE=Release
    cmake  --build . --clean-first -j
    md_ret_require="$md_build/build/bennugd_libretro.so"
}

function install_lr-bennugd() {
    md_ret_files=(
        'build/bennugd_libretro.so'
    )
}

function game_data_lr-bennugd() {
    if [[ ! -f "$romdir/bennugd/media/image/Skull.png" ]] || [[ ! -f "/opt/retropie/configs/bennugd/BennuGD/Skull.rmp" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/libretrocores/bennugd-rp-assets.tar.gz" "$romdir/bennugd"

        if [[ ! -f "/opt/retropie/configs/bennugd/BennuGD/Skull.rmp" ]]; then
            mkdir -p /opt/retropie/configs/bennugd/BennuGD
            mv "$romdir/bennugd/Skull.rmp" "/opt/retropie/configs/bennugd/BennuGD"
            chown -R $__user:$__user "/opt/retropie/configs/bennugd/BennuGD"
        else
            rm -f "$romdir/bennugd/Skull.rmp"
        fi

        if [[ ! -f "$romdir/bennugd/gamelist.xml" ]] && [[ ! -f "/opt/retropie/configs/all/emulationstation/gamelists/bennugd/gamelist.xml" ]]; then mv "$romdir/bennugd/gamelist.xml.bennugd" "$romdir/bennugd/gamelist.xml"; fi
        chown -R $__user:$__user "$romdir/bennugd"
    fi
}

function configure_lr-bennugd() {
    mkRomDir "bennugd"
    defaultRAConfig "bennugd"

    addEmulator 1 "$md_id" "bennugd" "$md_inst/bennugd_libretro.so"

    addSystem "bennugd" "BennuGD" ".dat .dcb"

    #local core_config="$md_conf_root/bennugd/retroarch-core-options.cfg"
    local core_config="/opt/retropie/configs/all/retroarch-core-options.cfg"
    iniConfig " = " '"' "$core_config"
    iniSet "bennugd_mouse_emulation" "right analog" "$core_config"
    chown "$__user":"$__group" "$core_config"

    # Extra Systems for carbon-2021: bennugd cdimono1 cd-i cloud doom godot-engine j2me jaguarcd openbor ti83 wine
    if [[ ! -f "/etc/emulationstation/themes/carbon-2021/art/systems/bennugd.svg" ]] && [[ -d "/etc/emulationstation/themes/carbon-2021" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/supplementary/emulationstation-es-x-rp-assets.tar.gz" "/etc/emulationstation/themes"
    fi

    [[ "$md_mode" == "install" ]] && game_data_lr-bennugd
}
