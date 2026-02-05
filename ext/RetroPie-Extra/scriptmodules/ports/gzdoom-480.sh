#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="gzdoom-480"
rp_module_desc="GZDoom is a modern feature-rich source port for the classic game DOOM\n\nGZDoom v4.8.0 is the last (GZ) version to support 32bit\n\nGZDoom v4.8.0 is compatible with older Mods such as:\nQCDE (Quake Champions Doom Edition)"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/gzdoom/master/LICENSE"
rp_module_repo="git https://github.com/ZDoom/gzdoom g4.8.0 :_get_commit_gzdoom-480"
rp_module_section="exp"
rp_module_flags="sdl2 !armv6"

function _get_commit_gzdoom-480() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in GZDoom Console
    local branch_tag=g4.8.0; # 32 bit is no longer supported since g4.8.1
    local branch_commit="$(git ls-remote https://github.com/ZDoom/gzdoom $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 08e46766; # 20220606 this is 4.8.0
}

function _get_version_zmusic_gzdoom-480() {
    echo "1.3.0"
}

function depends_gzdoom-480() {
    local depends=(
        cmake libfluidsynth-dev libsdl2-dev libmpg123-dev libsndfile1-dev libbz2-dev
        libopenal-dev libjpeg-dev libgl1-mesa-dev libasound2-dev libmpg123-dev libsndfile1-dev
        libvpx-dev libwebp-dev pkg-config
        zlib1g-dev)
    getDepends "${depends[@]}"
}

function sources_gzdoom-480() {
    gitPullOrClone

    # Apply Single-Board-Computer Specific Tweaks
    ( isPlatform "rpi"* || isPlatform "arm" ) && applyPatch "$md_data/00_sbc_tweaks.diff"

    # Apply JoyPad Tweaks and Preferences
    applyPatch "$md_data/01_sijl_tweaks.diff"
    applyPatch "$md_data/02_JoyMappings_0SFA.diff"
    applyPatch "$md_data/03_Preferences.diff"

    # remove clang-format directives # https://github.com/ZDoom/gzdoom/commit/37da5268e10804fc766b75c4d09a013f501faae4
    applyPatch "$md_data/clang_format.diff"

    # VSync On
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        sed -i 's+vid_vsync, false,+vid_vsync, true,+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    # +set vid_preferbackend # 3 OpenGL ES # 2 Softpoly # 1 Vulkan # 0 OpenGL
    if ! ( isPlatform "gl3" ) && isPlatform "gles"; then
        echo +set vid_preferbackend [OpenGL ES]
        sed -i 's+CUSTOM_CVAR(Int, vid_preferbackend,.*+CUSTOM_CVAR(Int, vid_preferbackend, 3, CVAR_ARCHIVE | CVAR_GLOBALCONFIG | CVAR_NOINITCALL)+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    # +set vid_preferbackend # 1 Vulkan
    if ! ( isPlatform "kms" ) && isPlatform "vulkan"; then
        if ! ( isPlatform "gl3" || isPlatform "gles" ); then
            echo +set vid_preferbackend [Vulkan]
            sed -i 's+CUSTOM_CVAR(Int, vid_preferbackend,.*+CUSTOM_CVAR(Int, vid_preferbackend, 1, CVAR_ARCHIVE | CVAR_GLOBALCONFIG | CVAR_NOINITCALL)+' "$md_build/src/common/rendering/v_video.cpp"
        fi
    fi

    # add 'ZMusic' repo
    cd "$md_build"
    ##gitPullOrClone zmusic https://github.com/ZDoom/ZMusic $(_get_version_zmusic_gzdoom)
    gitPullOrClone zmusic https://github.com/ZDoom/ZMusic

    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt

    # lzma assumes hardware crc support on arm which breaks when building on armv7
    isPlatform "armv7" && applyPatch "$md_data/lzma_armv7_crc.diff"

    # fix build with gcc 12 for armv8 on aarch64 kernel due to -ffast-math options
    if isPlatform "armv8" || isPlatform "aarch64"; then
        if [[ "$__gcc_version" -ge 12 ]]; then applyPatch "$md_data/armv8_gcc12_fix.diff"; fi
    fi

    # Apply Sector light mode
    if isPlatform "arm" || isPlatform "rpi3"; then
        sed -i 's+gl_lightmode, 3,+gl_lightmode, 2,+' "$md_build/src/g_level.cpp"; cat "$md_build/src/g_level.cpp" | grep ' gl_lightmode, '
    else
        sed -i 's+gl_lightmode, 3,+gl_lightmode, 8,+' "$md_build/src/g_level.cpp"; cat "$md_build/src/g_level.cpp" | grep ' gl_lightmode, '
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

function build_gzdoom-480() {
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
    md_ret_require="$md_build/release/gzdoom"
}

function install_gzdoom-480() {
    # 20251010 I'm tired of updating the libzmusic.so.1.* version...
    local libzmusic_ver=libzmusic.so.$(_get_version_zmusic_gzdoom)
    if [[ ! -f "$md_build/release/zmusic/lib/$libzmusic_ver" ]]; then libzmusic_ver="$(basename $(ls $md_build/release/zmusic/lib/libzmusic.so.1.*))"; fi
    echo LIBZMUSIC.SO: [$libzmusic_ver]

    md_ret_files=(
        'release/brightmaps.pk3'
        'release/gzdoom'
        'release/gzdoom.pk3'
        'release/lights.pk3'
        'release/game_support.pk3'
        'release/soundfonts'
        "release/zmusic/lib/libzmusic.so.1"
        ##"release/zmusic/lib/libzmusic.so.$(_get_version_zmusic_gzdoom)"
        "release/zmusic/lib/$libzmusic_ver"
        'README.md'
    )
}

function add_games_gzdoom-480() {
    local params=("-config $romdir/ports/doom/gzdoom-480.ini -savedir $romdir/ports/doom/gzdoom-480-saves")
    ##params=("-fullscreen")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"

    if ! ( isPlatform "rpi3" ) && isPlatform "arm"; then # -5 FluidSynth # -2 Timidity++ # -3 OPL Synth Emulation
        params+=("'+snd_mididevice -3'")
    fi

    isPlatform "kms" && params+=("-width %XRES%" "-height %YRES%")

    _add_games_lr-prboom "$launcher_prefix $md_inst/gzdoom -iwad %ROM% ${params[*]}"
}

function configure_gzdoom-480() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/gzdoom-480-saves"

    moveConfigDir "$home/.config/gzdoom" "$md_conf_root/doom"

    ##[[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && game_data_lr-prboom
    add_games_${md_id}
}

