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

rp_module_id="uzdoom-dev"
rp_module_desc="UZDoom is a modern feature-rich source port for the classic game DOOM\n\nUZDoom v4.14.3 is the continuation of ZDoom and GZDoom"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/uzdoom/master/LICENSE"
rp_module_repo="git https://github.com/UZDoom/UZDoom.git trunk :_get_commit_uzdoom-dev"
rp_module_section="exp"
rp_module_flags="sdl2 !armv6"

function _get_commit_uzdoom-dev() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in UZDoom Console
    local branch_tag=trunk
    local branch_commit="$(git ls-remote https://github.com/UZDoom/UZDoom.git $branch_tag HEAD | grep $branch_tag  | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo b4c521ec; # 20251014 Change default texture filtering to None - Trilinear
    #echo c34025d8; # 20260129 clean up vid_fsdwmhack
}

function depends_uzdoom-dev() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    local depends=(
        cmake libfluidsynth-dev libmpg123-dev libsndfile1-dev libbz2-dev
        libopenal-dev libjpeg-dev libgl1-mesa-dev libasound2-dev pkg-config
        zlib1g-dev)
    local depends=(libsdl2-dev libvpx-dev libwebp-dev)
    local depends=(build-essential libgtk2.0-dev waylandpp-dev ninja-build)
    getDepends "${depends[@]}"
}

function sources_uzdoom-dev() {
    gitPullOrClone

    # 0ptional Apply Single-Board-Computer Specific Tweaks
    ( isPlatform "rpi"* || isPlatform "arm" ) && applyPatch "$md_data/00_sbc_tweaks.diff"

    # 0ptional Add option for testing old lighting modes to menu https://github.com/drfrag666/lzdoom/commit/afa94ae18673a9a91f1deda4b0e6564fb0223779
    applyPatch "$md_data/01_0ld_lighting_modes.diff"

    # 0ptional Apply JoyPad + Preference Tweaks
    applyPatch "$md_data/02_JoyMappings.diff"
    applyPatch "$md_data/03_Preferences.diff"

    # 0ptional Haptics 0FF [haptics_strength, 0]
    ##sed -i 's+CUSTOM_CVARD(Int, haptics_strength,.*+CUSTOM_CVARD(Int, haptics_strength, 0, CVAR_ARCHIVE | CVAR_GLOBALCONFIG, \"Translate linear haptics to audio taper\")+' "$md_build/src/common/engine/m_haptics.cpp"

    # 0ptional Haptics 0FF in Menus [MyHouse.wad]
    sed -i 's+CVARD(Bool, haptics_do_menus,.*+CVARD(Bool, haptics_do_menus,  false, CVAR_ARCHIVE | CVAR_GLOBALCONFIG, \"allow haptic feedback for menus\");     // MyHouse.wad+' "$md_build/src/common/engine/m_haptics.cpp"

    # 0ptional Haptics 0FF for Player Actions [Firing]
    sed -i 's+CVARD(Bool, haptics_do_action,.*+CVARD(Bool, haptics_do_action, false, CVAR_ARCHIVE | CVAR_GLOBALCONFIG, \"allow haptic feedback for player doing things\");+' "$md_build/src/common/engine/m_haptics.cpp"

    # 0ptional VSync On
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        sed -i 's+CUSTOM_CVAR (Bool, vid_vsync,.*+CUSTOM_CVAR (Bool, vid_vsync, true, CVAR_ARCHIVE|CVAR_GLOBALCONFIG)+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt

    # lzma assumes hardware crc support on arm which breaks when building on armv7
    isPlatform "armv7" && applyPatch "$md_data/lzma_armv7_crc.diff"

    # fix build with gcc 12 for armv8 on aarch64 kernel due to -ffast-math options
    if isPlatform "armv8"; then
        if [[ "$__gcc_version" -ge 12 ]]; then applyPatch "$md_data/armv8_gcc12_fix.diff"; fi
    fi

    # Temp fix for trunk build until PR is Sync'd https://github.com/UZDoom/UZDoom/issues/653
    # print(f"inconsistent language mapping {languages[po_id]} / {_po_files[po_id]["meta"]["id"]}")
    # print(f"inconsistent language mapping {languages[po_id]} / {_po_files[po_id]['meta']['id']}")
    sed -i "s+print(f\"inconsistent language mapping.*+print(f\"inconsistent language mapping {languages[po_id]} / {_po_files[po_id]['meta']['id']}\")+" "$md_build/libraries/Translation/scripts/compile.py"
}

function build_uzdoom-dev() {
    mkdir -p "$md_build/build"
    cd "$md_build/build"
    local params=(-DCMAKE_BUILD_TYPE=RelWithDebInfo) # options are: Debug Release RelWithDebInfo MinSizeRel
    local params=(-DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DDYN_OPENAL=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_SHARED_LIBS=OFF -G Ninja)
    ! hasFlag "vulkan" && params+=(-DHAVE_VULKAN=OFF)

    cmake "${params[@]}" ..
    cmake --build .
    md_ret_require="$md_build/build/uzdoom"
}

function install_uzdoom-dev() {
    md_ret_files=(
        'build/brightmaps.pk3'
        'build/uzdoom'
        'build/uzdoom.pk3'
        'build/lights.pk3'
        'build/game_support.pk3'
        'build/game_widescreen_gfx.pk3'
        'build/soundfonts'
        'README.md'
    )
}

function add_games_uzdoom-dev() {
    local params=("-fullscreen -config $romdir/ports/doom/uzdoom-dev.ini -savedir $romdir/ports/doom/uzdoom-dev-saves")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"
    
    # [+gl_maplightmode] 0ld Lighting Modes https://www.doomworld.com/forum/topic/99002-what-is-your-favorite-sector-light-mode-for-gzdoom/
    # 0 (Standard): Bright lighting model and stronger fading in bright sectors.
    # 1 (Bright): Bright lighting model and weaker fading in bright sectors.
    # 2 (Doom): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 3 (Dark): Dark lighting model and weaker fading in bright sectors.
    # 4 (Doom Legacy): Emulates lighting of Legacy 1.4's GL renderer.
    # 8 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 16 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # +gl_maplightmode will no longer save to ini after 4.11.x

    # [+gl_lightmode] +4.11.x Lighting Modes https://www.doomworld.com/forum/topic/140628-so-gzdoom-has-replaced-its-sector-light-options/
    # 0 (Classic): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 1 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 2 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).

    params+=("+gl_maplightmode 4") # Apply Sector light mode (Doom Legacy) using [gl_maplightmode]
    ##params+=("+gl_lightmode 2") # g4.8.0 Sector light mode (Doom) for Low-end HW
    ##params+=("+gl_lightmode 0") # u4.14.3 Sector light mode (Classic) for Low-end HW

    ## -5 FluidSynth ## -2 Timidity++ ## -3 OPL Synth Emulation
    params+=("'+snd_mididevice -5'")

    # VSync On ## Moved to Source
    ##if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then params+=("+vid_vsync 1"); fi

    if isPlatform "kms"; then
        params+=("-width %XRES%" "-height %YRES%")
    fi

    _add_games_lr-prboom "$launcher_prefix $md_inst/uzdoom -iwad %ROM% ${params[*]}"
}

function configure_uzdoom-dev() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/uzdoom-dev-saves"

    moveConfigDir "$home/.config/$md_id" "$md_conf_root/doom"

    [[ "$md_mode" == "install" ]] && game_data_lr-prboom
    add_games_${md_id}
}
