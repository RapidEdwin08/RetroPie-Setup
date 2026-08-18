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

rp_module_id="lr-yabasanshiro"
rp_module_desc="Saturn & ST-V emulator - Yabasanshiro port for libretro"
rp_module_help="ROM Extensions: .iso .cue .zip .ccd .mds\n\nCopy your Sega Saturn & ST-V roms to $romdir/saturn\n\nCopy the required BIOS file saturn_bios.bin / stvbios.zip to $biosdir/yabasanshiro"
rp_module_licence="GPL2 https://raw.githubusercontent.com/ALLRiPPED/yabause/yabasanshiro/LICENSE"
rp_module_repo="git https://github.com/ALLRiPPED/yabause.git :_get_branch_lr-yabasanshiro :_get_commit_lr-yabasanshiro"
rp_module_section="exp"
rp_module_flags=""

function _get_branch_lr-yabasanshiro() {
    local branch_tag=master
    if ( isPlatform "rpi"* ) && [[ "$__os_debian_ver" -le 11 ]]; then
        local branch_tag=yabasanshiro
    fi

    echo $branch_tag
}

function _get_commit_lr-yabasanshiro() {
    # Pull Latest Commit SHA
    local branch_tag=$(_get_branch_lr-yabasanshiro)
    local branch_commit="$(git ls-remote https://github.com/ALLRiPPED/yabause.git $branch_tag HEAD | grep $branch_tag  | tail -1 | awk '{ print $1}' | cut -c -8)"

    [[ "$(_get_branch_lr-yabasanshiro)" == "yabasanshiro" ]] && branch_commit=73c67668

    #branch_commit=73c67668; # yabasanshiro # Merge pull request libretro#221 from joolswills/PlayRecorder_disable
    #branch_commit=4c96b96f; # master # Merge pull request libretro#298 from DisasterMo/crowdin-sync
    echo $branch_commit
}

function sources_lr-yabasanshiro() {
    gitPullOrClone
    [[ "$(_get_branch_lr-yabasanshiro)" == "yabasanshiro" ]] && applyPatch "$md_data/01_shader_hack_rpi4.diff"
}

function build_lr-yabasanshiro() {
    local params=()
    ! isPlatform "x86" && params+=(HAVE_SSE=0)
    if isPlatform "arm"; then
        params+=(USE_ARM_DRC=1 DYNAREC_DEVMIYAX=1 ARCH_IS_LINUX=1)
        isPlatform "neon" && params+=(HAVE_NEON=1)
    elif isPlatform "aarch64"; then
        params+=(USE_AARCH64_DRC=1 DYNAREC_DEVMIYAX=0)
    fi
    if [[ "$(_get_branch_lr-yabasanshiro)" == "yabasanshiro" ]] && ( isPlatform "gles" ); then
        params+=(FORCE_GLES=1)
    fi

    cd yabause/src/libretro
    make clean
    make "${params[@]}"
    if [[ "$(_get_branch_lr-yabasanshiro)" == "yabasanshiro" ]]; then
        md_ret_require="$md_build/yabause/src/libretro/yabasanshiro_libretro.so"
    else
        md_ret_require="$md_build/yabause/src/libretro/yabause_libretro.so"
    fi
}

function install_lr-yabasanshiro() {
    if [[ "$(_get_branch_lr-yabasanshiro)" == "yabasanshiro" ]]; then
        md_ret_files=(
            'yabause/src/libretro/yabasanshiro_libretro.so'
            'LICENSE'
            'README.md'
        )
    else
        md_ret_files=(
            'yabause/src/libretro/yabause_libretro.so'
            'yabause/ChangeLog'
            'yabause/COPYING'
            'README.md'
        )
    fi
}

function configure_lr-yabasanshiro() {
    mkRomDir "saturn"
    ensureSystemretroconfig "saturn"

    if [[ "$(_get_branch_lr-yabasanshiro)" == "yabasanshiro" ]]; then
        addEmulator 1 "$md_id" "saturn" "$md_inst/yabasanshiro_libretro.so"
    else
        addEmulator 1 "$md_id" "saturn" "$md_inst/yabause_libretro.so"
    fi
    addSystem "saturn"
}
