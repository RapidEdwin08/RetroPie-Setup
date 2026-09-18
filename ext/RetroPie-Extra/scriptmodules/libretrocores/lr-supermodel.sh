#!/usr/bin/env bash

# This file is part of RetroPie-Extra, a supplement to RetroPie.
# For more information, please visit:
#
# https://github.com/RetroPie/RetroPie-Setup
# https://github.com/Exarkuniv/RetroPie-Extra
# https://github.com/RapidEdwin08/RetroPie-Setup
#
# See the LICENSE file distributed with this source and at
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#

rp_module_id="lr-supermodel"
rp_module_desc="Libretro version of Super Model 3 Emulator"
rp_module_help="Copy your Sega Model 3 roms to $romdir/arcade"
rp_module_licence="GPL3 https://raw.githubusercontent.com/libretro/Libretro-Supermodel/master/Docs/LICENSE.txt"
rp_module_repo="git https://github.com/libretro/Libretro-Supermodel.git master"
rp_module_section="exp"
rp_module_flags="all !armv6 !armv7"

function depends_lr-supermodel() {
    local depends=(build-essential libgl1-mesa-dev libglu1-mesa-dev zlib1g-dev)
    #( isPlatform "rpi"* || isPlatform "kms" ) && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_lr-supermodel() {
    gitPullOrClone
}

function _get_so_lr-supermodel() {
    local super_so=supermodel_libretro.so
    isPlatform "aarch64" && super_so=supermodel_libretro_aarch64.so

    echo $super_so
}

function build_lr-supermodel() {
    pushd "$md_build/libretro"
    make clean

    if ( isPlatform "aarch64" ); then
        isPlatform "rpi"* && make platform=rpi64 -j$(nproc)
        ! isPlatform "rpi"* && make platform=aarch64 -j$(nproc)
    else
        make -j$(nproc)
    fi

    popd
    md_ret_require="$md_build/$(_get_so_lr-supermodel)"
}

function install_lr-supermodel() {
    md_ret_files=(
        'Docs/README.md'
        'Docs/LICENSE.txt'
        'Docs/CONTROL_PROFILES.md'
        "$(_get_so_lr-supermodel)"
    )
}

function configure_lr-supermodel() {
    mkRomDir "arcade"
    addSystem "arcade"

    defaultRAConfig "arcade"

    addEmulator 0 "$md_id" "arcade" "$md_inst/$(_get_so_lr-supermodel)"
}
