#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="gzdoom"
rp_module_desc="GZDoom is a feature centric port for all Doom engine games, based on ZDoom"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/gzdoom/master/LICENSE"
rp_module_repo="git https://github.com/ZDoom/gzdoom :_get_version_gzdoom"
rp_module_section="opt"
rp_module_flags="sdl2 !armv6"

function _get_version_gzdoom() {
    # default GZDoom version
    local gzdoom_version="g4.14.2"

    # 32 bit is no longer supported since g4.8.1
    isPlatform "32bit" && gzdoom_version="g4.8.0"
    echo $gzdoom_version
}

function depends_gzdoom() {
    local depends=(
        cmake libfluidsynth-dev libsdl2-dev libmpg123-dev libsndfile1-dev libbz2-dev
        libopenal-dev libjpeg-dev libgl1-mesa-dev libasound2-dev libmpg123-dev libsndfile1-dev
        libvpx-dev libwebp-dev pkg-config
        zlib1g-dev)
    getDepends "${depends[@]}"
}

function sources_gzdoom() {
    gitPullOrClone
    # Apply Single-Board-Computer Specific Tweaks
    if isPlatform "rpi"* || isPlatform "arm"; then
        applyPatch "$md_data/00_sbc_tweaks.diff"
    fi
    # Apply SDL JoyPad Tweaks https://retropie.org.uk/forum/topic/16078/zdoom-and-gampad-fully-working-in-menu-with-no-keyboard
    applyPatch "$md_data/01_sijl_tweaks.diff"
    applyPatch "$md_data/02_JoyMappings_0SFA.diff"
    applyPatch "$md_data/03_Preferences.diff" #ENABLED
    # add 'ZMusic' repo
    cd "$md_build"
    gitPullOrClone zmusic https://github.com/ZDoom/ZMusic
    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt
    # lzma assumes hardware crc support on arm which breaks when building on armv7
    isPlatform "armv7" && applyPatch "$md_data/lzma_armv7_crc.diff"
    # fix build with gcc 12 for armv8 on aarch64 kernel due to -ffast-math options
    if isPlatform "armv8"; then
		if [[ "$__gcc_version" -eq 12 ]]; then applyPatch "$md_data/armv8_gcc12_fix.diff"; fi
	fi
}

function build_gzdoom() {
    mkdir -p release

    # build 'ZMusic' first
    pushd zmusic
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$md_build/release/zmusic" .
    make
    make install
    popd

    cd release
    local params=(-DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DCMAKE_BUILD_TYPE=Release -DDYN_OPENAL=ON -DCMAKE_PREFIX_PATH="$md_build/release/zmusic")
    ! hasFlag "vulkan" && params+=(-DHAVE_VULKAN=OFF)

    cmake "${params[@]}" ..
    make
    md_ret_require="$md_build/release/$md_id"
}

function install_gzdoom() {
    # 20251010 I'm tired of updating the libzmusic.so.1.* version...
    local libzmusic_ver=libzmusic.so.1.3.0
    if [[ ! -f "$md_build/release/zmusic/lib/$libzmusic_ver" ]]; then libzmusic_ver="$(basename $(ls $md_build/release/zmusic/lib/libzmusic.so.1.*))"; fi
    echo LIBZMUSIC.SO: [$libzmusic_ver]
	md_ret_files=(
        'release/brightmaps.pk3'
        'release/gzdoom'
        'release/gzdoom.pk3'
        'release/lights.pk3'
        'release/game_support.pk3'
        'release/game_widescreen_gfx.pk3'
        'release/soundfonts'
        "release/zmusic/lib/libzmusic.so.1"
        "release/zmusic/lib/$libzmusic_ver"
        'README.md'
    )
}

function add_games_gzdoom() {
    local params=("-fullscreen -config $romdir/ports/doom/gzdoom.ini -savedir $romdir/ports/doom/gzdoom-saves")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"
    
    # https://www.doomworld.com/forum/topic/99002-what-is-your-favorite-sector-light-mode-for-gzdoom/
    # 0 (Standard): Bright lighting model and stronger fading in bright sectors.
    # 1 (Bright): Bright lighting model and weaker fading in bright sectors.
    # 2 (Doom): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 3 (Dark): Dark lighting model and weaker fading in bright sectors.
    # 4 (Legacy): Emulates lighting of Legacy 1.4's GL renderer.
    # 8 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 16 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    params+=("+gl_maplightmode 8")
    
    ## -5 FluidSynth ## -2 Timidity++ ## -3 OPL Synth Emulation
    if isPlatform "arm"; then # FluidSynth is too memory/CPU intensive
        params+=("'+set snd_mididevice -2'")
    else
        params+=("'+snd_mididevice -5'")
    fi
    
    # Music Volume
    #params+=("+snd_musicvolume 1") # Moved to 03_Preferences.diff
    
    # when using the 32bit version on GLES platforms, pre-set the renderer
    if isPlatform "32bit" && hasFlag "gles"; then
        params+=("+set vid_preferbackend 2")
    fi

    if isPlatform "kms"; then
        params+=("-width %XRES%" "-height %YRES%")
    fi

    _add_games_lr-prboom "$launcher_prefix $md_inst/$md_id -iwad %ROM% ${params[*]}"
}

function configure_gzdoom() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/gzdoom-saves"

    moveConfigDir "$home/.config/$md_id" "$md_conf_root/doom"

    [[ "$md_mode" == "remove" ]] && return

    game_data_lr-prboom
    add_games_${md_id}
}

