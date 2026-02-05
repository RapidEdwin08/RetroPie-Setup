#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lzdoom"
rp_module_desc="LZDoom (GZDoom Vintage) is a modder-friendly source port for the classic game DOOM\n\nLZDoom uses an OpenGL2 based renderer for better compatibility with lower-end computers\n\nLZDoom v4.14.3a is compatible with Newer Mods such as:\nMyHouse.wad"
rp_module_licence="GPL3 https://raw.githubusercontent.com/drfrag666/gzdoom/master/LICENSE"
rp_module_repo="git https://github.com/drfrag666/lzdoom.git l4.14.3a :_get_commit_lzdoom"
rp_module_section="opt"
rp_module_flags=""

function _get_commit_lzdoom() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in LZDoom Console
    local branch_tag=l4.14.3
    local branch_commit="$(git ls-remote https://github.com/drfrag666/lzdoom.git $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 0af10dc9; # 20251208 This is l4.14.3a - Fix VM Abort with Crusader A_CrusaderSweepLeft and Right pointers.
    #echo 0d3cc5bb; # 20251210 Revert "fixed DECORATE code generation for direct functions."
}

function _get_version_zmusic_lzdoom() {
    echo "1.3.0"
}

function depends_lzdoom() {
    local depends=(
        libev-dev libfluidsynth-dev libgme-dev libsdl2-dev libmpg123-dev libsndfile1-dev zlib1g-dev libbz2-dev
        timidity freepats cmake libopenal-dev libjpeg-dev libgl1-mesa-dev fluid-soundfont-gm
    )
    getDepends "${depends[@]}"
}

function sources_lzdoom() {
    gitPullOrClone

    # lightning modes
    sed -i 's+lightning modes+lighting modes+' "$md_build/wadsrc/static/language.def"

    # Apply Single-Board-Computer Specific Tweaks
    ( isPlatform "rpi"* || isPlatform "arm" ) && applyPatch "$md_data/00_sbc_tweaks.diff"

    # Apply JoyPad Tweaks and Preferences
    applyPatch "$md_data/01_sijl_tweaks.diff"
    applyPatch "$md_data/02_JoyMappings_0SFA.diff"
    applyPatch "$md_data/03_Preferences.diff"

    # VSync On
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        sed -i 's+vid_vsync, false,+vid_vsync, true,+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    # add 'ZMusic' repo
    cd "$md_build"
    gitPullOrClone zmusic https://github.com/ZDoom/ZMusic
    ##gitPullOrClone zmusic https://github.com/ZDoom/ZMusic $(_get_version_zmusic_lzdoom)

    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt

    # lzma assumes hardware crc support on arm which breaks when building on armv7
    isPlatform "armv7" && applyPatch "$md_data/lzma_armv7_crc.diff"

    # fix build with gcc 12 for armv8 on aarch64 kernel due to -ffast-math options
    if isPlatform "armv8"; then
        if [[ "$__gcc_version" -ge 12 ]]; then applyPatch "$md_data/armv8_gcc12_fix.diff"; fi
    fi

    # Apply Sector light mode
    if isPlatform "arm" || isPlatform "rpi3"; then
        sed -i 's+gl_lightmode, 1,+gl_lightmode, 0,+' "$md_build/src/g_level.cpp"; cat "$md_build/src/g_level.cpp" | grep ' gl_maplightmode, '
    fi

    # [+gl_lightmode] v4.11.x+ Lighting Modes https://www.doomworld.com/forum/topic/140628-so-gzdoom-has-replaced-its-sector-light-options/
    # 0 (Classic): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 1 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 2 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
}

function build_lzdoom() {
    # build 'ZMusic' first
    pushd zmusic
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$md_build/release/zmusic" .
    make
    make install
    popd

    rm -rf build
    mkdir -p build
    cd build
    local params=(-DCMAKE_BUILD_TYPE=RelWithDebInfo) # options are: Debug Release RelWithDebInfo MinSizeRel
    local params=(-DNO_GTK=On -DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DCMAKE_PREFIX_PATH="$md_build/release/zmusic")
    # Note: `-funsafe-math-optimizations` should be avoided, see: https://forum.zdoom.org/viewtopic.php?f=7&t=57781
    cmake "${params[@]}" ..
    make
    md_ret_require="$md_build/build/$md_id"
}

function install_lzdoom() {
    # 20251010 I'm tired of updating the libzmusic.so.1.* version...
    local libzmusic_ver=libzmusic.so.$(_get_version_zmusic_lzdoom)
    if [[ ! -f "$md_build/release/zmusic/lib/$libzmusic_ver" ]]; then libzmusic_ver="$(basename $(ls $md_build/release/zmusic/lib/libzmusic.so.1.*))"; fi
    echo LIBZMUSIC.SO: [$libzmusic_ver]

    md_ret_files=(
        'build/brightmaps.pk3'
        'build/lzdoom'
        'build/lzdoom.pk3'
        'build/lights.pk3'
        'build/game_support.pk3'
        'build/game_widescreen_gfx.pk3'
        'build/soundfonts'
        "release/zmusic/lib/libzmusic.so.1"
        "release/zmusic/lib/$libzmusic_ver"
        'README.md'
        'LICENSE'
    )
}

function add_games_lzdoom() {
    local params=("-config $romdir/ports/doom/lzdoom.ini -savedir $romdir/ports/doom/lzdoom-saves")
    ##params=("+fullscreen 1")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"

    ##params+=("'+snd_mididevice -5'") # -5 FluidSynth # -2 Timidity++ # -3 OPL Synth Emulation
    isPlatform "kms" && params+=("-width %XRES%" "-height %YRES%")

    _add_games_lr-prboom "$launcher_prefix $md_inst/$md_id -iwad %ROM% ${params[*]}"
}

function configure_lzdoom() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/lzdoom-saves"

    moveConfigDir "$home/.config/$md_id" "$md_conf_root/doom"

    [[ "$md_mode" == "install" ]] && game_data_lr-prboom
    add_games_${md_id}
}
