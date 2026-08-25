#! /usr/bin/env bash

# RetroPie scriptmodule to install the libretro core build of 
# AppleWin, the Apple2e emulator

# Copyright 2025 Gemba @ Github
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# ---
# **Additional Notes**
#
# - This libretro core set the game focus to off by default (`input_auto_game_focus=0`).
# - The toggle game focus is set to button 3. To change, review the information
#   at:
#   `https://retropie.org.uk/docs/RetroArch-Configuration/#determining-button-values`
# - You can cycle through the video modes with right shoulder button
#   (RETRO_DEVICE_ID_JOYPAD_R). You can toggle scanlines with left shoulder
#   button (RETRO_DEVICE_ID_JOYPAD_L).
#
# **References**
#
# - Project site: https://github.com/audetto/AppleWin

rp_module_id="lr-applewin"
rp_module_desc="Apple2e emulator: AppleWin (current) libretro core for RetroArch"
rp_module_help="ROM Extension: .po .dsk .nib .PO .DSK .NIB .zip\n\nCopy your roms to $romdir/apple2"
rp_module_licence="GPL2 https://raw.githubusercontent.com/audetto/AppleWin/master/LICENSE"
rp_module_repo="git https://github.com/audetto/AppleWin.git master"
rp_module_section="opt"
rp_module_flags=""


function depends_lr-applewin() {
    local depends=(
        cmake
        libboost-program-options-dev
        libevdev-dev
        libgles-dev
        libminizip-dev
        libpcap-dev
        libsdl2-dev
        libsdl2-image-dev
        libyaml-dev
        meson
        ninja-build
        xxd
    )
    if [[ "$__os_debian_ver" -gt 10 ]]; then
        depends+=(libslirp-dev)
    fi
    getDepends "${depends[@]}"
}

function sources_lr-applewin() {
    if [[ "$__os_debian_ver" -le 10 ]]; then
        # no libslirp-dev package in Buster
        rm -rf "$md_build/../libslirp"
        gitPullOrClone "$md_build/../libslirp" https://gitlab.freedesktop.org/slirp/libslirp.git
    fi
    gitPullOrClone
    # make sure resources/ will be looked up at /opt/retropie/libretrocores/lr-applewin/
    sed -i s,CMAKE_SOURCE_DIR,\"$md_inst\", \
        $md_build/source/frontends/common2/gnuframe.cpp
}

function build_lr-applewin() {
    if [[ "$__os_debian_ver" -le 10 ]]; then
        # for libslirp
        pushd "$md_build/../libslirp"
        # downgrade meson requirement to match Buster latest version
        sed -i s,"meson_version : .*","meson_version : \'>= 0.56\'", meson.build
        meson build
        ninja -C build install
        ldconfig
        popd
    fi

    # for AppleWin
    if [[ "$__os_debian_ver" -le 10 ]]; then
        # Buster: for GCC8 explicitly link stdc++-fs
        sed -i '/# this only affects common2/i link_libraries("$<$<AND:$<CXX_COMPILER_ID:GNU>,$<VERSION_LESS:$<CXX_COMPILER_VERSION>,9.0>>:-lstdc++fs>")' CMakeLists.txt
    fi
    mkdir target
    cd target
    cmake -DBUILD_LIBRETRO=ON -DCMAKE_BUILD_TYPE=RELEASE ..
    make clean
    make
    md_ret_require="$md_build/target/source/frontends/libretro/applewin_libretro.so"
}

function install_lr-applewin() {
    md_ret_files=(
        'LICENSE'
        'resource/'
        'target/source/frontends/libretro/applewin_libretro.so'
    )
}

function configure_lr-applewin() {
    mkRomDir "apple2"

    if [[ "$md_mode" == "install" ]] ; then
        defaultRAConfig "apple2" "input_auto_game_focus" "0" # 0: off, 1: on, 2: detect
        defaultRAConfig "apple2" "load_dummy_on_core_shutdown" "false"
        # Disable at all if defined in parent Retroarch configs or
        # adjust button number below to your controller setup.
        # cf: https://retropie.org.uk/docs/RetroArch-Configuration/#determining-button-values
        defaultRAConfig "apple2" "input_game_focus_toggle_btn" "3"
    fi

    addEmulator 0 "$md_id" "apple2" "$md_inst/applewin_libretro.so"
    addSystem "apple2"
}
