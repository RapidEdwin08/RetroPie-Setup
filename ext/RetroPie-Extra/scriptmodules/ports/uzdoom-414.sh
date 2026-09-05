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

rp_module_id="uzdoom-414"
rp_module_desc="UZDoom is a modern feature-rich source port for the classic game DOOM\n\nUZDoom v4.14.3 is the continuation of GZDoom forked under a"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/uzdoom/master/LICENSE"
rp_module_repo="git https://github.com/UZDoom/UZDoom.git :_get_branch_uzdoom-414 :_get_commit_uzdoom-414"
rp_module_section="exp"
rp_module_flags="sdl2 !armv6"

function _get_branch_uzdoom-414() {
    local branch_tag=4.14.3

    echo $branch_tag
}

function _get_commit_uzdoom-414() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in UZDoom Console
    local branch_tag=$(_get_branch_uzdoom-414)
    local branch_commit="$(git ls-remote https://github.com/UZDoom/UZDoom.git $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 835be65f; # 20251028 Change default texture filtering to None - Trilinear
    #echo 1cb7598a; # 20251128 This is 4.14.3
}

function _get_version_zmusic_uzdoom-414() {
    echo "1.3.0"
}

function depends_uzdoom-414() {
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

function sources_uzdoom-414() {
    gitPullOrClone

    # Add option for testing old lighting modes to menu https://github.com/drfrag666/lzdoom/commit/afa94ae18673a9a91f1deda4b0e6564fb0223779
    applyPatch "$md_data/0ld_lighting_modes.diff"

    # GLES2 for KMSDRM (-X11): +vid_preferbackend 2
    if ( isPlatform "gles" || isPlatform "kms" ) && ( isPlatform "rpi"* || isPlatform "aarch64" ); then
        sed -i 's+vid_preferbackend, 1,+vid_preferbackend, 2,+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    # Apply Single-Board-Computer Specific Tweaks
    ( isPlatform "rpi"* || isPlatform "aarch64" ) && applyPatch "$md_data/00_sbc_tweaks.diff"

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
    ##gitPullOrClone zmusic https://github.com/ZDoom/ZMusic $(_get_version_zmusic_uzdoom-414)

    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt

    # Apply Sector light mode
    if isPlatform "rpi3"; then
        sed -i 's+gl_lightmode, 1,+gl_lightmode, 0,+' "$md_build/src/g_level.cpp"
        cat "$md_build/src/g_level.cpp" | grep ' gl_lightmode, '
    fi

    # [+gl_lightmode] v4.11.x+ Lighting Modes https://www.doomworld.com/forum/topic/140628-so-gzdoom-has-replaced-its-sector-light-options/
    # 0 (Classic): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 1 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 2 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
}

function build_uzdoom-414() {
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
    md_ret_require="$md_build/build/uzdoom"
}

function install_uzdoom-414() {
    # 20251010 I'm tired of updating the libzmusic.so.1.* version...
    local libzmusic_ver=libzmusic.so.$(_get_version_zmusic_uzdoom-414)
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
        ##"release/zmusic/lib/libzmusic.so.$(_get_version_zmusic_uzdoom-414)"
        'README.md'
    )
}

function add_games_uzdoom-414() {
    local params=("-config $romdir/ports/doom/uzdoom-414.ini -savedir $romdir/ports/doom/uzdoom-414-saves")
    ##params=("-fullscreen")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"

    ##params+=("'+snd_mididevice -5'") # -5 FluidSynth # -2 Timidity++ # -3 OPL Synth Emulation
    isPlatform "kms" && params+=("-width %XRES%" "-height %YRES%")

    _add_games_lr-prboom "$launcher_prefix $md_inst/uzdoom -iwad %ROM% ${params[*]}"
}

function configure_uzdoom-414() {
    mkRomDir "ports/doom"
    mkRomDir "ports/doom/mods"
    mkRomDir "ports/doom/uzdoom-414-saves"

    moveConfigDir "$home/.config/$md_id" "$md_conf_root/doom"

    [[ "$md_mode" == "install" ]] && game_data_lr-prboom
    add_games_${md_id}
}
