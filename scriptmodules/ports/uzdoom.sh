#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="uzdoom"
rp_module_desc="UZDoom is a modder-friendly OpenGL and Vulkan source port based on the DOOM engine"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/uzdoom/master/LICENSE"
rp_module_repo="git https://github.com/UZDoom/UZDoom.git 4.14.3 :_get_commit_uzdoom"
rp_module_section="opt"
rp_module_flags="sdl2 !armv6"

function _get_commit_uzdoom() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in UZDoom Console
    local branch_tag=4.14.3
    local branch_commit="$(git ls-remote https://github.com/UZDoom/UZDoom.git $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 835be65f; # Change default texture filtering to None - Trilinear
    #echo 1cb7598a; # This is 4.14.3
}

function _get_version_zmusic_uzdoom() {
    echo "1.3.0"
}

function depends_uzdoom() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    local depends=(
        cmake libfluidsynth-dev libmpg123-dev libsndfile1-dev libbz2-dev
        libopenal-dev libjpeg-dev libgl1-mesa-dev libasound2-dev pkg-config
        zlib1g-dev)
    local depends=(libsdl2-dev libvpx-dev libwebp-dev)
    getDepends "${depends[@]}"
}

function sources_uzdoom() {
    gitPullOrClone

    # 0ptional Apply Single-Board-Computer Specific Tweaks
    if isPlatform "rpi"* || isPlatform "arm"; then
        applyPatch "$md_data/00_sbc_tweaks.diff" # r_maxparticles 2500
        if isPlatform "rpi5"; then
            sed -i 's/gl_texture_filter_anisotropic, 16.f,/gl_texture_filter_anisotropic, 8.f,/' "$md_build/src/common/rendering/hwrenderer/data/hw_cvars.cpp"
        else
            sed -i 's/gl_texture_filter_anisotropic, 16.f,/gl_texture_filter_anisotropic, 2.f,/' "$md_build/src/common/rendering/hwrenderer/data/hw_cvars.cpp"
        fi
    fi

    # 0ptional Apply SDL JoyPad Tweaks https://retropie.org.uk/forum/topic/16078/zdoom-and-gampad-fully-working-in-menu-with-no-keyboard
    applyPatch "$md_data/01_sijl_tweaks.diff" # Enable JoyPad in Menu
    applyPatch "$md_data/02_JoyMappings_0SFA.diff" # OSFA Axes to Prevent being stuck looking up on Varying JoyPads
    applyPatch "$md_data/03_Preferences.diff" #ENABLED

    # add 'ZMusic' repo
    cd "$md_build"
    gitPullOrClone zmusic https://github.com/ZDoom/ZMusic
    ##gitPullOrClone zmusic https://github.com/ZDoom/ZMusic $(_get_version_zmusic_uzdoom)

    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt

    # lzma assumes hardware crc support on arm which breaks when building on armv7
    isPlatform "armv7" && applyPatch "$md_data/lzma_armv7_crc.diff"

    # fix build with gcc 12 for armv8 on aarch64 kernel due to -ffast-math options
    if isPlatform "armv8"; then
        if [[ "$__gcc_version" -ge 12 ]]; then applyPatch "$md_data/armv8_gcc12_fix.diff"; fi
    fi
}

function build_uzdoom() {
    # build 'ZMusic' first
    pushd zmusic
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$md_build/release/zmusic" .
    make
    make install
    popd

    mkdir -p "$md_build/build"
    cd "$md_build/build"
    local params=(-DCMAKE_BUILD_TYPE=RelWithDebInfo) # options are: Debug Release RelWithDebInfo MinSizeRel
    local params=(-DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DDYN_OPENAL=ON -DCMAKE_PREFIX_PATH="$md_build/release/zmusic")
    ! hasFlag "vulkan" && params+=(-DHAVE_VULKAN=OFF)

    cmake "${params[@]}" ..
    cmake --build .
    md_ret_require="$md_build/build/$md_id"
}

function install_uzdoom() {
    # 20251010 I'm tired of updating the libzmusic.so.1.* version...
    local libzmusic_ver=libzmusic.so.$(_get_version_zmusic_uzdoom)
    if [[ ! -f "$md_build/release/zmusic/lib/$libzmusic_ver" ]]; then libzmusic_ver="$(basename $(ls $md_build/release/zmusic/lib/libzmusic.so.1.*))"; fi
    echo LIBZMUSIC.SO: [$libzmusic_ver]

    md_ret_files=(
        'build/brightmaps.pk3'
        'build/uzdoom'
        'build/uzdoom.pk3'
        'build/lights.pk3'
        'build/game_support.pk3'
        'build/game_widescreen_gfx.pk3'
        'build/soundfonts'
        "release/zmusic/lib/libzmusic.so.1"
        "release/zmusic/lib/$libzmusic_ver"
        ##"release/zmusic/lib/libzmusic.so.$(_get_version_zmusic_uzdoom)"
        'README.md'
        'LICENSE'
    )
}

function add_games_uzdoom() {
    local params=("-fullscreen -config $romdir/ports/doom/uzdoom.ini -savedir $romdir/ports/doom/uzdoom-saves")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"
    
    # https://www.doomworld.com/forum/topic/99002-what-is-your-favorite-sector-light-mode-for-gzdoom/
    # 0 (Standard): Bright lighting model and stronger fading in bright sectors.
    # 1 (Bright): Bright lighting model and weaker fading in bright sectors.
    # 2 (Doom): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 3 (Dark): Dark lighting model and weaker fading in bright sectors.
    # 4 (Legacy): Emulates lighting of Legacy 1.4's GL renderer.
    # 8 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 16 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    ##params+=("+gl_maplightmode 8") # Can still enable but will no longer save to ini after 4.11.x

    # https://www.doomworld.com/forum/topic/140628-so-gzdoom-has-replaced-its-sector-light-options/
    # 0 (Classic): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 1 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 2 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    params+=("+gl_lightmode 1")

    ## -5 FluidSynth ## -2 Timidity++ ## -3 OPL Synth Emulation
    params+=("'+snd_mididevice -5'")

    isPlatform "kms" && params+=("+vid_vsync 1" "-width %XRES%" "-height %YRES%")

    _add_games_lr-prboom "$launcher_prefix $md_inst/$md_id -iwad %ROM% ${params[*]}"
}

function configure_uzdoom() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/uzdoom-saves"

    moveConfigDir "$home/.config/$md_id" "$md_conf_root/doom"

    [[ "$md_mode" == "remove" ]] && return

    game_data_lr-prboom
    add_games_${md_id}
}
