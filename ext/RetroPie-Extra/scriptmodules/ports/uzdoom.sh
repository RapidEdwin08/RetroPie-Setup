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

rp_module_id="uzdoom"
rp_module_desc="UZDoom is a modder-friendly OpenGL and Vulkan source port based on the DOOM engine"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/uzdoom/master/LICENSE"
#rp_module_repo="git https://github.com/UZDoom/UZDoom.git trunk 5104cc43" # g4.15pre-717-g5104cc431-m
#rp_module_repo="git https://github.com/UZDoom/UZDoom.git trunk da87fb3d" # g4.15pre-718-gda87fb3d9-m
#rp_module_repo="git https://github.com/UZDoom/UZDoom.git trunk dd38edbb" # g4.15pre-730-gdd38edbba-m
rp_module_repo="git https://github.com/UZDoom/UZDoom.git trunk 18ecb597" # g4.15pre-731-g18ecb5973-m
rp_module_section="exp"
rp_module_flags="sdl2 !armv6"

function depends_uzdoom() {
    local depends=(
        cmake libfluidsynth-dev libmpg123-dev libsndfile1-dev libbz2-dev
        libopenal-dev libjpeg-dev libgl1-mesa-dev libasound2-dev pkg-config
        zlib1g-dev)
    local depends=(libsdl2-dev libvpx-dev libwebp-dev)
    local depends=(build-essential libgtk2.0-dev waylandpp-dev ninja-build)
    getDepends "${depends[@]}"
}

function sources_uzdoom() {
    gitPullOrClone

    # 0ptional Apply Single-Board-Computer Specific Tweaks
    if isPlatform "rpi"* || isPlatform "arm"; then applyPatch "$md_data/00_sbc_tweaks.diff"; fi

    # 0ptional Apply JoyPad + Preference Tweaks
    applyPatch "$md_data/01_HapticsOff.diff"
    applyPatch "$md_data/02_JoyMappings.diff"
    applyPatch "$md_data/03_Preferences.diff"

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
    mkdir -p "$md_build/build"
    cd "$md_build/build"
    local params=(-DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DDYN_OPENAL=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_SHARED_LIBS=OFF -G Ninja)
    ! hasFlag "vulkan" && params+=(-DHAVE_VULKAN=OFF)

    cmake "${params[@]}" ..
    cmake --build .
    md_ret_require="$md_build/build/$md_id"
}

function install_uzdoom() {
    md_ret_files=(
        'build/brightmaps.pk3'
        'build/uzdoom'
        'build/uzdoom.pk3'
        'build/lights.pk3'
        'build/game_support.pk3'
        'build/game_widescreen_gfx.pk3'
        'build/soundfonts'
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
    ##params+=("+gl_maplightmode 8") # Can still enable but will not save to ini

    # https://www.doomworld.com/forum/topic/140628-so-gzdoom-has-replaced-its-sector-light-options/
    # 0 (Classic): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 1 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 2 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    
    ## -5 FluidSynth ## -2 Timidity++ ## -3 OPL Synth Emulation
    if isPlatform "arm"; then
        params+=("+gl_lightmode 0") # Classic (Faster)
        params+=("'+set snd_mididevice -3'") # FluidSynth is too memory/CPU intensive
    else
        params+=("+gl_lightmode 1")
        params+=("'+snd_mididevice -5'")
    fi
    
    # when using the 32bit version on GLES platforms, pre-set the renderer
    if isPlatform "32bit" && hasFlag "gles"; then
        params+=("+set vid_preferbackend 2")
    fi

    if isPlatform "kms"; then
        params+=("+vid_vsync 1" "-width %XRES%" "-height %YRES%")
    fi

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
