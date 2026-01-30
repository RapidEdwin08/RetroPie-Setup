#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-dosbox-pure"
rp_module_desc="DOS emulator"
rp_module_help="ROM Extensions: .bat .com .cue .dosz .exe .ins .ima .img .iso .m3u .m3u8 .vhd .zip\n\nCopy your DOS games to $ROMDIR/pc"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/dosbox-pure/main/LICENSE"
rp_module_repo="git https://github.com/libretro/dosbox-pure.git main :_get_commit_lr-dosbox-pure"
rp_module_section="exp"
rp_module_flags=""

function _get_commit_lr-dosbox-pure() {
    # Pull Latest Commit SHA
    local branch_tag=main
    local branch_commit="$(git ls-remote https://github.com/libretro/dosbox-pure.git $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 10945cfc; # 20250730 Make 3dfx Voodoo set to "Auto (default)" use hardware acceleration even on OpenGLES devices - Graphics Issue on rpi3
    #echo 10823c1e; # 20250729 Set version to 1.0-preview2 - Last Commit Before Graphics Issue on rpi3
}

function depends_lr-dosbox-pure() {
    # lr-dosbox-pure will try and use g++ v9 on arm if the system default is v10 due to bugs
    # see https://github.com/libretro/dosbox-pure/commit/603b1c7ae
    isPlatform "arm" && [[ "$__gcc_version" -eq 10 ]] && getDepends g++-9
}

function sources_lr-dosbox-pure() {
    gitPullOrClone

    # Revert [10945cfc] Make 3dfx Voodoo set to "Auto (default)" use hardware acceleration even on OpenGLES devices # https://github.com/libretro/dosbox-pure/commit/10945cfc809171c96007f62ec654c3a078096162
    if isPlatform "rpi3"; then
        sed -i 's+for (int test = -1.*+for (int test = -1; test != (voodoo_perf[0] == '\''a'\'' ? 0 : 5); test\+\+)+' "$md_build/dosbox_pure_libretro.cpp"
        sed -i 's+if (preffered_hw_render == RETRO_HW_CONTEXT_OPENGL).*;+//if (preffered_hw_render == RETRO_HW_CONTEXT_OPENGL) testmax = 4;+' "$md_build/dosbox_pure_libretro.cpp"
    fi
}

function build_lr-dosbox-pure() {
    make clean
    make
    md_ret_require="$md_build/dosbox_pure_libretro.so"
}

function install_lr-dosbox-pure() {
    md_ret_files=(
        'LICENSE'
        'dosbox_pure_libretro.so'
        'README.md'
    )
}

function configure_lr-dosbox-pure() {
    mkRomDir "pc"
    defaultRAConfig "pc"

    addEmulator 0 "$md_id" "pc" "$md_inst/dosbox_pure_libretro.so"
    addSystem "pc"
}
