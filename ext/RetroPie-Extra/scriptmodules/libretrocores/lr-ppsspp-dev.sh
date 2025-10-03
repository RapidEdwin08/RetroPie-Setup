#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-ppsspp-dev"
rp_module_desc="PlayStation Portable emu - PPSSPP port for libretro"
rp_module_help="ROM Extensions: .iso .pbp .cso\n\nCopy your PlayStation Portable roms to $romdir/psp"
rp_module_licence="GPL2 https://raw.githubusercontent.com/RetroPie/ppsspp/master/LICENSE.TXT"
#rp_module_repo="git https://github.com/hrydgard/ppsspp.git master"
#rp_module_repo="git https://github.com/hrydgard/ppsspp.git master 40a53315" # 20250910 Delete reference to prebuilt libfreetype, pull in the source instead - CMake Error at ext/freetype/CMakeLists.txt:223 (message): In-source builds are not permitted! Make a separate folder for building
rp_module_repo="git https://github.com/hrydgard/ppsspp.git master 28f8ce64" # 20250910 Add freetype as a submodule (2.14.0) - Last Commit Before CMake Error
rp_module_section="exp"
rp_module_flags=""

function depends_lr-ppsspp-dev() {
    depends_ppsspp-dev
}

function sources_lr-ppsspp-dev() {
    sources_ppsspp-dev
}

function build_lr-ppsspp-dev() {
    build_ppsspp-dev
}

function install_lr-ppsspp-dev() {
    md_ret_files=(
        'ppsspp/lib/ppsspp_libretro.so'
        'ppsspp/assets'
    )
}

function configure_lr-ppsspp-dev() {
    mkRomDir "psp"
    defaultRAConfig "psp"

    if [[ "$md_mode" == "install" ]]; then
        mkUserDir "$biosdir/PPSSPP"
        cp -Rv "$md_inst/assets/"* "$biosdir/PPSSPP/"
        chown -R "$__user":"$__group" "$biosdir/PPSSPP"

        # the core needs a save file directory, use the same folder as standalone 'ppsspp'
        iniConfig " = " "" "$configdir/psp/retroarch.cfg"
        iniSet "savefile_directory" "$home/.config/ppsspp"
        moveConfigDir "$home/.config/ppsspp" "$md_conf_root/psp"
    fi

    addEmulator 1 "$md_id" "psp" "$md_inst/ppsspp_libretro.so"
    addSystem "psp"

    # if we are removing the last remaining psp emu - remove the symlink
    if [[ "$md_mode" == "remove" ]]; then
        if [[ -h "$home/.config/ppsspp" && ! -f "$md_conf_root/psp/emulators.cfg" ]]; then
            rm -f "$home/.config/ppsspp"
        fi
    fi
}
