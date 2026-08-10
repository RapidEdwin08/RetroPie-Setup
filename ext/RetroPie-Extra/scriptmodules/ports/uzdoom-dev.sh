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
rp_module_desc="UZDoom is a modern feature-rich source port for the classic game DOOM\n\nUZDoom v5.0.0+ is the continuation of ZDoom and GZDoom"
rp_module_licence="GPL3 https://raw.githubusercontent.com/ZDoom/uzdoom/master/LICENSE"
rp_module_repo="git https://github.com/UZDoom/UZDoom.git :_get_branch_uzdoom-dev :_get_commit_uzdoom-dev"
rp_module_section="exp"
rp_module_flags="sdl2 !armv6"

function _get_branch_uzdoom-dev() {
    ##local branch_tag=trunk
    local branch_tag=5.0

    echo $branch_tag
}

function _get_commit_uzdoom-dev() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source - Prevent <unknown version> in UZDoom Console
    local branch_tag=$(_get_branch_uzdoom-dev)
    local branch_commit="$(git ls-remote https://github.com/UZDoom/UZDoom.git $branch_tag HEAD | grep $branch_tag  | tail -1 | awk '{ print $1}' | cut -c -8)"

    #echo b4c521ec; # 20251014 Change default texture filtering to None - Trilinear
    #echo 00b63359; # 20260307 Cleared Behaviors on the previous pawn when spawning a new one #trunk
    #echo 0ffcba95; # 20260413 Add auto-theme detection for linux #5.0 # Introduced gdbus timeout at Start-Up on KMSDRM
    #echo 7b8bea80; # 20260728 This is 5.0.0-rc.1 #5.0
    #echo 08b19217; # 20260809 P_DrawRailTrail reverts to using the playerpawn for sound-position calculations if player->camera is null #trunk
    echo $branch_commit
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

    # 0ptional Apply JoyPad + Preference Tweaks
    applyPatch "$md_data/JoyMappings.diff"

    # 0ffcba95 Introduced gdbus timeout at Start-Up on KMSDRM # gdbus takes too long and/or hits timeout on some systems. Don't call if not needed
    isPlatform "kms" && applyPatch "$md_data/dark_theme_linux.diff" # result = Dark;

    # GLES2 for KMSDRM (-X11): BACKEND_OPENGLES # +vid_preferbackend 2
    # OpenGL on KMSDRM (-X11): Unsupported OpenGL version. At least OpenGL 3.3 required to run UZDoom
    # Vulkan on KMSDRM (-X11): ERROR: Could not restore CRTC # ERROR: Could not set videomode on CRTC # ERROR: Could not queue pageflip: -13 # Initialization of Vulkan failed: No Vulkan device found supports the minimum requirements of this application
    # Vulkan on KMSDRM (+X11): Works but poor performance on Raspberry Pi aarch64
    if ( isPlatform "gles" || isPlatform "kms" ) && ( isPlatform "rpi"* || isPlatform "aarch64" ); then ##applyPatch "$md_data/backend_default_gles2.diff"
        sed -i 's+vid_preferbackend, BACKEND_DEFAULT,+vid_preferbackend, BACKEND_OPENGLES,+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    ##! 0ptional Single-Board-Computer Specific Tweaks # Bring on Potato Mode already...
    if ( isPlatform "rpi"* || isPlatform "arm" ); then ##applyPatch "$md_data/sbc_tweaks.diff"
        sed -i 's+gl_fogmode, 2,+gl_fogmode, 0,+' "$md_build/src/common/rendering/hwrenderer/data/hw_cvars.cpp"
        sed -i 's+gl_seamless, true,+gl_seamless, false,+' "$md_build/src/common/rendering/hwrenderer/data/hw_cvars.cpp"
        sed -i 's+gl_precache, false,+gl_precache, true,+' "$md_build/src/common/rendering/hwrenderer/data/hw_cvars.cpp"
        sed -i 's+gl_shadowmap_filter, 1,+gl_shadowmap_filter, 0,+' "$md_build/src/common/rendering/hwrenderer/data/hw_cvars.cpp"
        sed -i 's+gl_shadowmap_quality, 1024,+gl_shadowmap_quality, 128,+' "$md_build/src/common/rendering/hwrenderer/data/hw_shadowmap.cpp"
        sed -i 's+transsouls, 0.75f,+transsouls, 1.f,+' "$md_build/src/common/rendering/v_video.cpp"
        sed -i 's+r_maxparticles, 4000,+r_maxparticles, 100,+' "$md_build/src/g_cvars.cpp"
        sed -i 's+r_vanillatrans, 0,+r_vanillatrans, 1,+' "$md_build/src/r_data/r_vanillatrans.cpp"
        sed -i 's+gl_light_particles, true,+gl_light_particles, false,+' "$md_build/src/rendering/hwrenderer/hw_dynlightdata.cpp"
    fi

    ##! 0ptional Preferences
    if ( isPlatform "64bit" ); then ##applyPatch "$md_data/Preferences.diff"
        sed -i 's+con_scale, 0,+con_scale, 3,+' "$md_build/src/common/console/c_console.cpp"
        sed -i 's+uiscale, 0,+uiscale, 2,+' "$md_build/src/common/rendering/v_video.cpp"
        sed -i 's+crosshaircolor,     0xff0000,+crosshaircolor,     0x00ff1e,+' "$md_build/src/common/statusbar/base_sbar.cpp"
        sed -i 's+crosshairscale, 1.0,+crosshairscale, 0.75,+' "$md_build/src/common/statusbar/base_sbar.cpp"
        sed -i 's+con_scaletext, 0,+con_scaletext, 3,+' "$md_build/src/console/c_notifybuffer.cpp"
        sed -i 's+cl_run,     false,+cl_run,     true,+' "$md_build/src/g_game.cpp"
        sed -i 's+cl_analog_run,               true,+cl_analog_run,               false,+' "$md_build/src/g_game.cpp"
        sed -i 's+disableautosave, 0,+disableautosave, 1,+' "$md_build/src/g_game.cpp"
        sed -i 's+hud_scale, -1,+hud_scale, 0,+' "$md_build/src/g_statusbar/shared_sbar.cpp"
        sed -i 's+st_scale, -1,+st_scale, 2,+' "$md_build/src/g_statusbar/shared_sbar.cpp"
        sed -i 's+crosshair, 1,+crosshair, 2,+' "$md_build/src/g_statusbar/shared_sbar.cpp"
        sed -i 's+crosshairforce, false,+crosshairforce, true,+' "$md_build/src/g_statusbar/shared_sbar.cpp"
        sed -i 's+snd_mastervolume, 0.5f,+snd_mastervolume, 1.f,+' "$md_build/src/common/audio/sound/i_sound.cpp"
    fi

    # 0ptional Haptics 0FF in Menus [MyHouse.wad]
    sed -i 's+haptics_do_menus,  true,+haptics_do_menus,  false,+' "$md_build/src/common/engine/m_haptics.cpp"

    # 0ptional Haptics 0FF for Player Actions [Firing]
    ##sed -i 's+haptics_do_action, true,+haptics_do_action, false,+' "$md_build/src/common/engine/m_haptics.cpp"

    # 0ptional Haptics Strength [0-10]
    ##sed -i 's+haptics_strength, 10,+haptics_strength, 0,+' "$md_build/src/common/engine/m_haptics.cpp"

    ##! 0ptional VSync On
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        sed -i 's+vid_vsync, false,+vid_vsync, true,+' "$md_build/src/common/rendering/v_video.cpp"
    fi

    # workaround for Ubuntu 20.04 older vpx/wepm dev libraries
    sed -i 's/IMPORTED_TARGET libw/IMPORTED_TARGET GLOBAL libw/' CMakeLists.txt

    # lzma assumes hardware crc support on arm which breaks when building on armv7
    isPlatform "armv7" && applyPatch "$md_data/lzma_armv7_crc.diff"

    # fix build with gcc 12 for armv8 on aarch64 kernel due to -ffast-math options
    if isPlatform "armv8"; then
        if [[ "$__gcc_version" -ge 12 ]]; then applyPatch "$md_data/armv8_gcc12_fix.diff"; fi
    fi

    # Disable [i_exit_on_not_found] ERROR_ABORT [1]
    sed -i 's+i_exit_on_not_found, REQUIRE_DEFAULT,+i_exit_on_not_found, 1,+' "$md_build/src/common/utility/findfile.cpp"

    # Apply Sector light mode
    isPlatform "rpi3" && sed -i 's+gl_lightmode, 1,+gl_lightmode, 0,+' "$md_build/src/g_level.cpp"

    # [+gl_lightmode] v4.11.x+ Lighting Modes https://www.doomworld.com/forum/topic/140628-so-gzdoom-has-replaced-its-sector-light-options/
    # 0 (Classic): Dark lighting model and weaker fading in bright sectors plus some added brightening near the current position. Requires GLSL features to be enabled.
    # 1 (Software): Emulates ZDoom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
    # 2 (Vanilla): Emulates vanilla Doom software lighting. Requires GLSL 1.30 or greater (OpenGL 3.0+).
}

function build_uzdoom-dev() {
    local make_jproc="-j$(nproc)"
    isPlatform "rpi3" && make_jproc=''
    rpSwap on 2304
    mkdir -p "$md_build/build"
    cd "$md_build/build"
    local params=(-DCMAKE_BUILD_TYPE=RelWithDebInfo) # options are: Debug Release RelWithDebInfo MinSizeRel
    local params=(-DCMAKE_INSTALL_PREFIX="$md_inst" -DPK3_QUIET_ZIPDIR=ON -DDYN_OPENAL=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DBUILD_SHARED_LIBS=OFF -G Ninja)
    ! isPlatform "vulkan" && params+=(-DHAVE_VULKAN=OFF)
    isPlatform "vulkan" && params+=(-DHAVE_VULKAN=ON)
    if ( isPlatform "vulkan" ) && ( isPlatform "kms" ) then params+=(-DVULKAN_USE_WAYLAND=0); fi
    isPlatform "gles" && params+=(-DHAVE_GLES2=ON)

    cmake "${params[@]}" ..
    cmake --build . $make_jproc
    rpSwap off
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
    local params=("-config $romdir/ports/doom/uzdoom-dev.ini -savedir $romdir/ports/doom/uzdoom-dev-saves")
    ##params=("-fullscreen")
    local launcher_prefix="DOOMWADDIR=$romdir/ports/doom"

    ##params+=("'+snd_mididevice -5'") # -5 FluidSynth # -2 Timidity++ # -3 OPL Synth Emulation
    isPlatform "kms" && params+=("-width %XRES%" "-height %YRES%")

    # GLES2 for KMSDRM (-X11): BACKEND_OPENGLES # +vid_preferbackend 2
    ##if ( isPlatform "gles" || isPlatform "kms" ) && ( isPlatform "rpi"* || isPlatform "aarch64" ); then params+=("+vid_preferbackend 2"); fi

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
