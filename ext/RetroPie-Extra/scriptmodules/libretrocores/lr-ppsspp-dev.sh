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
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="lr-ppsspp-dev"
rp_module_desc="PlayStation Portable emu - PPSSPP port for libretro - latest development version"
rp_module_help="ROM Extensions: .iso .pbp .cso\n\nCopy your PlayStation Portable roms to $romdir/psp"
rp_module_licence="GPL2 https://raw.githubusercontent.com/RetroPie/ppsspp/master/LICENSE.TXT"
rp_module_repo="git https://github.com/hrydgard/ppsspp.git master :_get_commit_lr-ppsspp-dev"
rp_module_section="exp"
rp_module_flags=""

function _get_commit_lr-ppsspp-dev() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch=master
    local branch_commit="$(git ls-remote https://github.com/hrydgard/ppsspp.git $branch HEAD | grep $branch | tail -1 | awk '{ print $1}' | cut -c -8)"

    ##echo $branch_commit
    #echo 40a53315; # 20250910 Delete reference to prebuilt libfreetype, pull in the source instead - CMake Error at ext/freetype/CMakeLists.txt:223 (message): In-source builds are not permitted! Make a separate folder for building
    #echo 28f8ce64; # 20250910 Add freetype as a submodule (2.14.0) - Last Commit Before CMake Error
    #echo eb859735; # 20260303 v1.20.1
}

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
    addSystem "psp" "PSP" ".gui"

    # if we are removing the last remaining psp emu - remove the symlink
    if [[ "$md_mode" == "remove" ]]; then
        if [[ -h "$home/.config/ppsspp" && ! -f "$md_conf_root/psp/emulators.cfg" ]]; then
            rm -f "$home/.config/ppsspp"
        fi
    fi
}
