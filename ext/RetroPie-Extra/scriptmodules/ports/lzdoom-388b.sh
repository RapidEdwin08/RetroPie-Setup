#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lzdoom-388b"
rp_module_desc="LZDoom (GZDoom Vintage) is a modder-friendly source port for the classic game DOOM\n\nLZDoom uses an OpenGL2 based renderer for better compatibility with lower-end computers\n\nLZDoom v3.88b is compatible with older Mods such as:\nQCDE (Quake Champions Doom Edition)"
rp_module_licence="GPL3 https://raw.githubusercontent.com/drfrag666/gzdoom/master/LICENSE"
rp_module_repo="git https://github.com/drfrag666/lzdoom.git 3.88b :_get_commit_lzdoom-388b"
rp_module_section="exp"
rp_module_flags=""

function _get_commit_lzdoom-388b() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in LZDoom Console
    local branch_tag=3.88b
    local branch_commit="$(git ls-remote https://github.com/drfrag666/lzdoom.git $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 4ce19a12; # 20220226 LZDoom 3.88b
}

function depends_lzdoom-388b() {
    local depends=(
        libev-dev libfluidsynth-dev libgme-dev libsdl2-dev libmpg123-dev libsndfile1-dev zlib1g-dev libbz2-dev
        timidity freepats cmake libopenal-dev libjpeg-dev libgl1-mesa-dev fluid-soundfont-gm
    )
    getDepends "${depends[@]}"
}

function sources_lzdoom-388b() {
    gitPullOrClone

    # Apply Single-Board-Computer Specific Tweaks
    ( isPlatform "rpi"* || isPlatform "arm" ) && applyPatch "$md_data/00_sbc_tweaks.diff"

    # Apply JoyPad Tweaks and Preferences
    applyPatch "$md_data/01_sijl_tweaks.diff"
    applyPatch "$md_data/02_JoyMappings_0SFA.diff"
    applyPatch "$md_data/03_Preferences.diff"

    if isPlatform "arm"; then
        # patch the CMake build file to remove the ARMv8 options, we handle `gcc`'s CPU flags ourselves
        applyPatch "$md_data/01_remove_cmake_arm_options.diff"
        # patch the 21.06 version of LZMA-SDK to disable the CRC32 ARMv8 intrinsics forced for ARM CPUs
        applyPatch "$md_data/02_lzma_sdk_dont_force_arm_crc32.diff"
    fi

    applyPatch "$md_data/03_extra_includes.diff"

    # Enable HW Acceleration + Fullscreen + VSync
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        echo +set vid_renderer [1] +set fullscreen [true] +set vid_vsync [true]
        sed -i 's+vid_renderer, 0,+vid_renderer, 1,+' "$md_build/src/posix/sdl/hardware.cpp"
        sed -i 's+fullscreen, false,+fullscreen, true,+' "$md_build/src/posix/sdl/hardware.cpp"
        sed -i 's+vid_vsync, false,+vid_vsync, true,+' "$md_build/src/v_video.cpp"
    fi

    # Apply Sector light mode
    if isPlatform "arm" || isPlatform "rpi3"; then
        sed -i 's+gl_lightmode, 8 ,+gl_lightmode, 2 ,+' "$md_build/src/gl/renderer/gl_lightdata.cpp"; cat "$md_build/src/gl/renderer/gl_lightdata.cpp" | grep ' gl_lightmode, '
    fi

    # [+gl_lightmode] 0ld Lighting Modes https://www.doomworld.com/forum/topic/99002-what-is-your-favorite-sector-light-mode-for-gzdoom/
    # 0 (Standard): Bright lighting model and stronger fading in bright sectors.
    # 1 (Bright): Bright lighting model and weaker fading in bright sectors.
    # 2 (Doom): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 3 (Dark): Dark lighting model and weaker fading in bright sectors.
    # 4 (Doom Legacy): Emulates lighting of Legacy 1.4's GL renderer.
    # 8 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 16 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
}

function build_lzdoom-388b() {
    rm -rf release
    mkdir -p release
    cd release
    local params=(-DNO_GTK=On -DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DCMAKE_BUILD_TYPE=Release)
    # Note: `-funsafe-math-optimizations` should be avoided, see: https://forum.zdoom.org/viewtopic.php?f=7&t=57781
    cmake "${params[@]}" ..
    make
    md_ret_require="$md_build/release/lzdoom"
}

function install_lzdoom-388b() {
    md_ret_files=(
        'release/brightmaps.pk3'
        'release/lzdoom'
        'release/lzdoom.pk3'
        'release/lights.pk3'
        'release/game_support.pk3'
        'release/soundfonts'
        'README.md'
    )
}

function add_games_lzdoom-388b() {
    local params=("-config $romdir/ports/doom/lzdoom-388b.ini -savedir $romdir/ports/doom/lzdoom-388b-saves")
    ##params=("+fullscreen 1")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"

    if ! ( isPlatform "rpi3" ) && isPlatform "arm"; then
        params+=("'+snd_mididevice -3'"); fi # -5 FluidSynth # -2 Timidity++ # -3 OPL Synth Emulation
    fi

    isPlatform "kms" && params+=("-width %XRES%" "-height %YRES%")

    _add_games_lr-prboom "$launcher_prefix $md_inst/lzdoom -iwad %ROM% ${params[*]}"
}

function configure_lzdoom-388b() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/lzdoom-388b-saves"

    moveConfigDir "$home/.config/lzdoom" "$md_conf_root/doom"

    [[ "$md_mode" == "install" ]] && game_data_lr-prboom
    add_games_${md_id}
}
