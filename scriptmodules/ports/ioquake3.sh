#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="ioquake3"
rp_module_desc="Quake 3 source port"
rp_module_help="Place Quake III Game Folders in [ports/quake3]:\nbaseq3\nchronic\ntwctf\nq3ctc"
rp_module_licence="GPL2 https://github.com/ioquake/ioq3/blob/master/COPYING.txt"
rp_module_repo="git https://github.com/ioquake/ioq3 main :_get_commit_ioquake3"
rp_module_section="opt"
rp_module_flags="!videocore"

function _get_commit_ioquake3() {
    # On Buster and Bullseye we have to build using make (an old method) instead of cmake.
    # This is because ioquake3 requires CMake 3.25 or higher which is satisfied only on Bookworm.
    if [[ "$__os_debian_ver" -lt 12 ]]; then
        # This is the latest commit before the Makefile was removed.
        echo 7ac92951f2da597611ab4525023979df2f92047a
    fi
}

function depends_ioquake3() {
    getDepends cmake libsdl2-dev libgl1-mesa-dev
}

function sources_ioquake3() {
    gitPullOrClone
}

function build_ioquake3() {
    if [[ "$__os_debian_ver" -lt 12 ]]; then
        make clean
        I_ACKNOWLEDGE_THE_MAKEFILE_IS_DEPRECATED=1 make
    else
        cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
        cmake --build build --clean-first
    fi
    md_ret_require="$md_build/$(_release_dir)/ioquake3"
}

function _release_dir() {
    if [[ "$__os_debian_ver" -lt 12 ]]; then
        # exact parsing from Makefile
        local arch_ioquake3="$(uname -m | sed -e 's/i.86/x86/' | sed -e 's/^arm.*/arm/' | sed -e 's/aarch64/arm64/')"
        echo "build/release-linux-${arch_ioquake3}"
    else
        echo "build/Release"
    fi
}

function install_ioquake3() {
    md_ret_files=(
        "$(_release_dir)/ioq3ded"
        "$(_release_dir)/ioquake3"
        "$(_release_dir)/renderer_opengl1.so"
        "$(_release_dir)/renderer_opengl2.so"
    )
}

function game_data_ioquake3() {
    if [[ ! -f "$romdir/ports/quake3/pak0.pk3" ]]; then
        downloadAndExtract "$__archive_url/Q3DemoPaks.zip" "$romdir/ports/quake3/baseq3" -j
    fi
    if [[ ! -f "$romdir/ports/quake3/chronic.pk3" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/ports/ioquake3-rp-assets.tar.gz" "$romdir/ports/quake3"
    fi
    # always chown as moveConfigDir in the configure_ script would move the root owned demo files
    chown -R "$__user":"$__group" "$romdir/ports/quake3"
}

function gui_ioquake3() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      Get Additional Desktop Shortcuts + Icons\n\nGet Desktop Shortcuts for Additional Episodes + Add-Ons that may not have been present at Install\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "Get Shortcuts + Icons" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            configure_ioquake3
            #game_data_ioquake3
            #shortcuts_icons_ioquake3
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function remove_ioquake3() {
    local shortcut_name
    shortcut_name="Quake III Arena"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name.sh"

    shortcut_name="Quake III Chronic"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name.sh"

    shortcut_name="Quake III Capture The Flag"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name.sh"

    shortcut_name="Quake III Catch The Chicken"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name.sh"

    rmdir "$md_conf_root/quake3" > /dev/null 2>&1
    for quake3_mod in chronic twctf q3ctc; do
        rmdir "$md_conf_root/quake3-$quake3_mod" > /dev/null 2>&1
    done
}

function configure_ioquake3() {
    local launcher=("$md_inst/ioquake3")
    isPlatform "mesa" && launcher+=("+set cl_renderer opengl1")
    isPlatform "kms" && launcher+=("+set r_mode -1" "+set r_customwidth %XRES%" "+set r_customheight %YRES%")
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        launcher+=("+set r_swapInterval 1")
    fi

    addPort "$md_id" "quake3" "Quake III Arena" "${launcher[*]}"

    # [+set g_gametype] 0 = deathmatch # 1 = one on one (tournament) # 2 = single player deathmatch # 3 = team deathmatch # 4 = capture the flag
    addPort "$md_id-chronic" "quake3-chronic" "Quake III Chronic" "${launcher[*]} +set fs_game chronic +map chronic +set g_gametype 0 +bot_enable 1 +addbot eminem 3 red 1 +addbot dre 3 blue 1"
    addPort "$md_id-twctf" "quake3-twctf" "Quake III Capture The Flag" "${launcher[*]} +set fs_game twctf +map q3wctf2 +set g_gametype 4 +set g_teamAutoJoin 1 +set g_teamForceBalance 1 +bot_enable 1 +addbot major 3 red 1 +addbot visor 3 blue 1 +addbot daemia 3 blue 1"
    addPort "$md_id-q3ctc" "quake3-q3ctc" "Quake III Catch The Chicken" "${launcher[*]} +set fs_game q3ctc +map q3dm7 +set g_gametype 0 +bot_enable 1 +addbot major 3 red 1 +addbot visor 3 blue 1 +set chickmenu 1"

    [[ "$md_mode" == "remove" ]] && remove_ioquake3
    [[ "$md_mode" == "remove" ]] && return

    mkRomDir "ports/quake3/"
    mkRomDir "ports/quake3/baseq3"
    mkRomDir "ports/quake3/chronic"
    mkRomDir "ports/quake3/twctf"
    mkRomDir "ports/quake3/q3ctc"

    moveConfigDir "$md_inst/baseq3" "$romdir/ports/quake3/baseq3"
    moveConfigDir "$md_inst/chronic" "$romdir/ports/quake3/chronic"
    moveConfigDir "$md_inst/twctf" "$romdir/ports/quake3/twctf"
    moveConfigDir "$md_inst/q3ctc" "$romdir/ports/quake3/q3ctc"
    moveConfigDir "$home/.q3a" "$md_conf_root/quake3/ioquake3"
    mkUserDir "$md_conf_root/quake3/ioquake3/baseq3"

    cat >"$md_inst/q3config.cfg" << _EOF_
// generated by quake, do not modify
unbindall
bind TAB "+scores"
bind ENTER "+button2"
bind ESCAPE "togglemenu"
bind SPACE "+moveup"
bind + "sizeup"
bind - "sizedown"
bind / "weapnext"
bind 0 "weapon 10"
bind 1 "weapon 1"
bind 2 "weapon 2"
bind 3 "weapon 3"
bind 4 "weapon 4"
bind 5 "weapon 5"
bind 6 "weapon 6"
bind 7 "weapon 7"
bind 8 "weapon 8"
bind 9 "weapon 9"
bind = "sizeup"
bind [ "weapprev"
bind \ "+mlook"
bind ] "weapnext"
bind _ "sizedown"
bind \` "toggleconsole"
bind a "+moveleft"
bind c "+movedown"
bind d "+moveright"
bind s "+back"
bind t "messagemode"
bind w "+forward"
bind ~ "toggleconsole"
bind PAUSE "pause"
bind UPARROW "+forward"
bind DOWNARROW "+back"
bind LEFTARROW "+left"
bind RIGHTARROW "+right"
bind ALT "+strafe"
bind CTRL "+attack"
bind SHIFT "+speed"
bind DEL "+lookdown"
bind PGDN "+lookup"
bind END "centerview"
bind F1 "vote yes"
bind F2 "vote no"
bind F3 "ui_teamorders"
bind F11 "screenshot"
bind MOUSE1 "+attack"
bind MOUSE2 "+strafe"
bind MOUSE3 "+zoom"
bind MWHEELDOWN "weapnext"
bind MWHEELUP "weapprev"
bind PAD0_A "+moveup"
bind PAD0_B "centerview"
bind PAD0_X "+movedown"
bind PAD0_Y "+speed"
bind PAD0_BACK "+scores"
bind PAD0_START "togglemenu"
bind PAD0_LEFTSTICK_CLICK "+movedown"
bind PAD0_RIGHTSTICK_CLICK "centerview"
bind PAD0_LEFTSHOULDER "+zoom"
bind PAD0_RIGHTSHOULDER "weapnext"
bind PAD0_DPAD_UP "+button3"
bind PAD0_DPAD_DOWN "+button2"
bind PAD0_DPAD_LEFT "weapprev"
bind PAD0_DPAD_RIGHT "weapnext"
bind PAD0_LEFTSTICK_LEFT "+moveleft"
bind PAD0_LEFTSTICK_RIGHT "+moveright"
bind PAD0_LEFTSTICK_UP "+forward"
bind PAD0_LEFTSTICK_DOWN "+back"
bind PAD0_RIGHTSTICK_LEFT "+left"
bind PAD0_RIGHTSTICK_RIGHT "+right"
bind PAD0_RIGHTSTICK_UP "+lookup"
bind PAD0_RIGHTSTICK_DOWN "+lookdown"
bind PAD0_LEFTTRIGGER "+moveup"
bind PAD0_RIGHTTRIGGER "+attack"
seta com_hunkMegs "128"
seta com_altivec "0"
seta com_maxfps "85"
seta com_blood "1"
seta com_ansiColor "0"
seta com_maxfpsUnfocused "0"
seta com_maxfpsMinimized "0"
seta com_busyWait "0"
seta com_introplayed "1"
seta con_autochat "1"
seta vm_cgame "2"
seta vm_game "2"
seta vm_ui "2"
seta dmflags "0"
seta fraglimit "10"
seta timelimit "0"
seta sv_hostname "noname"
seta sv_maxclients "8"
seta sv_minRate "0"
seta sv_maxRate "0"
seta sv_dlRate "100"
seta sv_minPing "0"
seta sv_maxPing "0"
seta sv_floodProtect "1"
seta sv_dlURL ""
seta sv_master3 ""
seta sv_master4 ""
seta sv_master5 ""
seta sv_lanForceRate "1"
seta sv_strictAuth "1"
seta sv_banFile "serverbans.dat"
seta con_autoclear "1"
seta cl_timedemoLog ""
seta cl_autoRecordDemo "0"
seta cl_aviFrameRate "25"
seta cl_aviMotionJpeg "1"
seta cl_yawspeed "140"
seta cl_pitchspeed "140"
seta cl_maxpackets "30"
seta cl_packetdup "1"
seta cl_run "1"
seta sensitivity "5"
seta cl_mouseAccel "0"
seta cl_freelook "1"
seta cl_mouseAccelStyle "0"
seta cl_mouseAccelOffset "5"
seta cl_allowDownload "0"
seta r_inGameVideo "1"
seta cg_autoswitch "1"
seta m_pitch "0.022000"
seta m_yaw "0.022"
seta m_forward "0.25"
seta m_side "0.25"
seta m_filter "0"
seta j_pitch "0.022"
seta j_yaw "-0.022"
seta j_forward "-0.25"
seta j_side "0.25"
seta j_up "0"
seta j_pitch_axis "3"
seta j_yaw_axis "2"
seta j_forward_axis "1"
seta j_side_axis "0"
seta j_up_axis "4"
seta cl_maxPing "800"
seta cl_lanForcePackets "1"
seta cl_guidServerUniq "1"
seta cl_consoleKeys "~ \` 0x7e 0x60"
seta name "Quake Guy"
seta rate "25000"
seta snaps "20"
seta model "sarge"
seta headmodel "sarge"
seta team_model "james"
seta team_headmodel "*james"
seta g_redTeam "Stroggs"
seta g_blueTeam "Pagans"
seta color1 "4"
seta color2 "5"
seta handicap "100"
seta sex "male"
seta cl_anonymous "0"
seta cg_predictItems "1"
seta cl_useMumble "0"
seta cl_mumbleScale "0.0254"
seta cl_voipGainDuringCapture "0.2"
seta cl_voipCaptureMult "2.0"
seta cl_voipUseVAD "0"
seta cl_voipVADThreshold "0.25"
seta cl_voipShowMeter "1"
seta cl_voip "1"
seta cl_cURLLib "libcurl.so.4"
seta cg_viewsize "100"
seta cg_stereoSeparation "0"
seta cl_renderer "opengl2"
seta r_allowExtensions "1"
seta r_ext_compressed_textures "0"
seta r_ext_multitexture "1"
seta r_ext_compiled_vertex_array "1"
seta r_ext_texture_env_add "1"
seta r_ext_framebuffer_object "1"
seta r_ext_texture_float "1"
seta r_ext_framebuffer_multisample "0"
seta r_arb_seamless_cube_map "0"
seta r_arb_vertex_array_object "1"
seta r_ext_direct_state_access "1"
seta r_ext_texture_filter_anisotropic "0"
seta r_ext_max_anisotropy "2"
seta r_picmip "1"
seta r_roundImagesDown "1"
seta r_detailtextures "1"
seta r_texturebits "0"
seta r_colorbits "0"
seta r_stencilbits "8"
seta r_depthbits "0"
seta r_ext_multisample "0"
seta r_overBrightBits "1"
seta r_ignorehwgamma "0"
seta r_mode "-2"
seta r_fullscreen "1"
seta r_noborder "0"
seta r_customwidth "1600"
seta r_customheight "1024"
seta r_customPixelAspect "1"
seta r_simpleMipMaps "1"
seta r_vertexLight "0"
seta r_subdivisions "4"
seta r_stereoEnabled "0"
seta r_greyscale "0"
seta r_hdr "1"
seta r_floatLightmap "0"
seta r_postProcess "1"
seta r_toneMap "1"
seta r_autoExposure "1"
seta r_depthPrepass "1"
seta r_ssao "0"
seta r_normalMapping "1"
seta r_specularMapping "1"
seta r_deluxeMapping "1"
seta r_parallaxMapping "0"
seta r_parallaxMapOffset "0"
seta r_parallaxMapShadows "0"
seta r_cubeMapping "0"
seta r_cubemapSize "128"
seta r_deluxeSpecular "0.3"
seta r_pbr "0"
seta r_baseNormalX "1.0"
seta r_baseNormalY "1.0"
seta r_baseParallax "0.05"
seta r_baseSpecular "0.04"
seta r_baseGloss "0.3"
seta r_glossType "1"
seta r_dlightMode "0"
seta r_pshadowDist "128"
seta r_mergeLightmaps "1"
seta r_imageUpsample "0"
seta r_imageUpsampleMaxSize "1024"
seta r_imageUpsampleType "1"
seta r_genNormalMaps "0"
seta r_drawSunRays "0"
seta r_sunlightMode "1"
seta r_sunShadows "1"
seta r_shadowFilter "1"
seta r_shadowBlur "0"
seta r_shadowMapSize "1024"
seta r_shadowCascadeZNear "8"
seta r_shadowCascadeZFar "1024"
seta r_shadowCascadeZBias "0"
seta r_ignoreDstAlpha "1"
seta r_lodCurveError "250"
seta r_lodbias "0"
seta r_flares "0"
seta r_zproj "64"
seta r_stereoSeparation "64"
seta r_ignoreGLErrors "1"
seta r_fastsky "0"
seta r_drawSun "0"
seta r_dynamiclight "1"
seta r_dlightBacks "1"
seta r_finish "0"
seta r_textureMode "GL_LINEAR_MIPMAP_LINEAR"
seta r_swapInterval "0"
seta r_gamma "1"
seta r_facePlaneCull "1"
seta r_railWidth "16"
seta r_railCoreWidth "6"
seta r_railSegmentLength "32"
seta r_anaglyphMode "0"
seta cg_shadows "1"
seta r_marksOnTriangleMeshes "0"
seta r_vaoCache "0"
seta r_aviMotionJpegQuality "90"
seta r_screenshotJpegQuality "90"
seta r_allowResize "0"
seta r_centerWindow "0"
seta r_preferOpenGLES "-1"
seta in_keyboardDebug "0"
seta in_mouse "1"
seta in_nograb "0"
seta in_joystick "1"
seta joy_threshold "0.300000"
seta s_volume "0.8"
seta s_musicvolume "0.25"
seta s_doppler "1"
seta s_muteWhenMinimized "0"
seta s_muteWhenUnfocused "0"
seta s_useOpenAL "1"
seta s_alPrecache "1"
seta s_alGain "1.0"
seta s_alSources "96"
seta s_alDopplerFactor "1.0"
seta s_alDopplerSpeed "9000"
seta s_alDriver "libopenal.so.1"
seta s_alInputDevice ""
seta s_alDevice ""
seta s_alCapture "1"
seta ui_ffa_fraglimit "20"
seta ui_ffa_timelimit "0"
seta ui_tourney_fraglimit "0"
seta ui_tourney_timelimit "15"
seta ui_team_fraglimit "0"
seta ui_team_timelimit "20"
seta ui_team_friendly "1"
seta ui_ctf_capturelimit "8"
seta ui_ctf_timelimit "30"
seta ui_ctf_friendly "0"
seta g_spScores1 ""
seta g_spScores2 ""
seta g_spScores3 ""
seta g_spScores4 ""
seta g_spScores5 ""
seta g_spAwards ""
seta g_spVideos ""
seta g_spSkill "2"
seta ui_browserMaster "0"
seta ui_browserGameType "0"
seta ui_browserSortKey "4"
seta ui_browserShowFull "1"
seta ui_browserShowEmpty "1"
seta cg_brassTime "2500"
seta cg_drawCrosshair "4"
seta cg_drawCrosshairNames "1"
seta cg_marks "1"
seta server1 ""
seta server2 ""
seta server3 ""
seta server4 ""
seta server5 ""
seta server6 ""
seta server7 ""
seta server8 ""
seta server9 ""
seta server10 ""
seta server11 ""
seta server12 ""
seta server13 ""
seta server14 ""
seta server15 ""
seta server16 ""
seta com_pipefile ""
seta net_enabled "3"
seta net_mcast6addr "ff04::696f:7175:616b:6533"
seta net_mcast6iface ""
seta net_socksEnabled "0"
seta net_socksServer ""
seta net_socksPort "1080"
seta net_socksUsername ""
seta net_socksPassword ""
seta cm_playerCurveClip "1"
seta g_maxGameClients "0"
seta capturelimit "8"
seta g_friendlyFire "0"
seta g_teamAutoJoin "0"
seta g_teamForceBalance "0"
seta g_warmup "20"
seta g_log "games.log"
seta g_logSync "0"
seta g_banIPs ""
seta g_filterBan "1"
seta g_allowVote "1"
seta cg_drawGun "1"
seta cg_zoomfov "22.5"
seta cg_fov "90"
seta cg_gibs "1"
seta cg_draw2D "1"
seta cg_drawStatus "1"
seta cg_drawTimer "0"
seta cg_drawFPS "0"
seta cg_drawSnapshot "0"
seta cg_draw3dIcons "1"
seta cg_drawIcons "1"
seta cg_drawAmmoWarning "1"
seta cg_drawAttacker "1"
seta cg_drawRewards "1"
seta cg_crosshairSize "24"
seta cg_crosshairHealth "1"
seta cg_crosshairX "0"
seta cg_crosshairY "0"
seta cg_simpleItems "0"
seta cg_lagometer "1"
seta cg_railTrailTime "400"
seta cg_runpitch "0.002"
seta cg_runroll "0.005"
seta cg_bobpitch "0.002"
seta cg_bobroll "0.002"
seta cg_teamChatTime "3000"
seta cg_teamChatHeight "0"
seta cg_forceModel "0"
seta cg_deferPlayers "1"
seta cg_drawTeamOverlay "0"
seta cg_drawFriend "1"
seta cg_teamChatsOnly "0"
seta cg_noVoiceChats "0"
seta cg_noVoiceText "0"
seta cg_cameraOrbitDelay "50"
seta cg_scorePlums "1"
seta cg_smoothClients "0"
seta cg_noTaunt "0"
seta cg_noProjectileTrail "0"
seta ui_smallFont "0.25"
seta ui_bigFont "0.4"
seta cg_oldRail "1"
seta cg_oldRocket "1"
seta cg_oldPlasma "1"
seta cg_trueLightning "0.0"
seta in_joystickNo "0"
seta in_joystickUseAnalog "0"
seta com_zoneMegs "24"
_EOF_
    if [[ ! -f "$md_conf_root/quake3/ioquake3/baseq3/q3config.cfg" ]]; then cp "$md_inst/q3config.cfg" "$md_conf_root/quake3/ioquake3/baseq3/q3config.cfg"; fi
    if [[ ! -f "$md_conf_root/quake3/ioquake3/q3config.cfg.ioquake3" ]]; then cp "$md_inst/q3config.cfg" "$md_conf_root/quake3/ioquake3/q3config.cfg.ioquake3"; fi
    sed -i s+seta\ in_joystick.*+seta\ in_joystick\ \"1\"+ "$md_conf_root/quake3/ioquake3/baseq3/q3config.cfg"
    chown $__user:$__user "$md_conf_root/quake3/ioquake3/baseq3/q3config.cfg"
    chown $__user:$__user "$md_conf_root/quake3/ioquake3/q3config.cfg.ioquake3"

    [[ "$md_mode" == "install" ]] && game_data_ioquake3
    [[ "$md_mode" == "install" ]] && shortcuts_icons_ioquake3
}

function shortcuts_icons_ioquake3() {
    local launcher=("$md_inst/ioquake3")
    isPlatform "mesa" && launcher+=("+set cl_renderer opengl1")
    #isPlatform "kms" && launcher+=("+set r_mode -1" "+set r_swapInterval 1")
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        launcher+=("+set r_swapInterval 1")
    fi

    local shortcut_name
    shortcut_name="Quake III Arena"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=${launcher[*]}
Icon=$md_inst/quake3arena_64x64.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Q3;QuakeIII;Arena
StartupWMClass=QuakeIIIArena
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    # [+set g_gametype] 0 = deathmatch # 1 = one on one (tournament) # 2 = single player deathmatch # 3 = team deathmatch # 4 = capture the flag
    shortcut_name="Quake III Chronic"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=A Single Map featuring Eminem & Dr. Dre
Exec=${launcher[*]} +set fs_game chronic +map chronic +set g_gametype 0 +bot_enable 1 +addbot eminem 3 red 1 +addbot dre 3 blue 1
Icon=$md_inst/quake3chronic_72x72.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Q3;QuakeIII;Chronic
StartupWMClass=QuakeIIIChronic
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    shortcut_name="Quake III Capture The Flag"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Three Wave Capture The Flag
Exec=${launcher[*]} +set fs_game twctf +map q3wctf2 +set g_gametype 4 +set g_teamAutoJoin 1 +set g_teamForceBalance 1 +bot_enable 1 +addbot major 3 red 1 +addbot visor 3 blue 1 +addbot daemia 3 blue 1
Icon=$md_inst/quake3ctf_82x82.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Q3;QuakeIII;CTF
StartupWMClass=QuakeIIICaptureTheFlag
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    shortcut_name="Quake III Catch The Chicken"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Catch The Chicken
Exec=${launcher[*]} +set fs_game q3ctc +map q3dm7 +set g_gametype 0 +bot_enable 1 +addbot major 3 red 1 +addbot visor 3 blue 1 +set chickmenu 1
Icon=$md_inst/quake3ctc_72x72.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Q3;QuakeIII;CTF
StartupWMClass=QuakeIIICaptureTheFlag
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/quake3arena_64x64.xpm" << _EOF_
/* XPM */
static char * quake3arena_64x64_xpm[] = {
"64 64 98 2",
"   c None",
".  c #650000",
"+  c #670000",
"@  c #690000",
"#  c #6C0000",
"\$     c #6F0000",
"%  c #720000",
"&  c #740000",
"*  c #770000",
"=  c #790000",
"-  c #7C0000",
";  c #7F0000",
">  c #810000",
",  c #850000",
"'  c #840000",
")  c #870000",
"!  c #860000",
"~  c #890000",
"{  c #8A0000",
"]  c #8D0000",
"^  c #8C0000",
"/  c #8B0000",
"(  c #F90000",
"_  c #8E0000",
":  c #F50000",
"<  c #910000",
"[  c #F40000",
"}  c #F10000",
"|  c #F20000",
"1  c #930000",
"2  c #F00000",
"3  c #ED0000",
"4  c #960000",
"5  c #EC0000",
"6  c #E90000",
"7  c #980000",
"8  c #E70000",
"9  c #E40000",
"0  c #9B0000",
"a  c #E30000",
"b  c #E00000",
"c  c #9E0000",
"d  c #DF0000",
"e  c #DD0000",
"f  c #DC0000",
"g  c #A00000",
"h  c #DB0000",
"i  c #D80000",
"j  c #D90000",
"k  c #A30000",
"l  c #D70000",
"m  c #D40000",
"n  c #D30000",
"o  c #D20000",
"p  c #A50000",
"q  c #D10000",
"r  c #D00000",
"s  c #CF0000",
"t  c #CE0000",
"u  c #A80000",
"v  c #CB0000",
"w  c #AB0000",
"x  c #C70000",
"y  c #AD0000",
"z  c #C20000",
"A  c #C30000",
"B  c #B00000",
"C  c #BF0000",
"D  c #B20000",
"E  c #BE0000",
"F  c #BA0000",
"G  c #B50000",
"H  c #B60000",
"I  c #B80000",
"J  c #AE0000",
"K  c #BD0000",
"L  c #AA0000",
"M  c #A60000",
"N  c #A20000",
"O  c #A10000",
"P  c #C40000",
"Q  c #9C0000",
"R  c #9D0000",
"S  c #990000",
"T  c #CA0000",
"U  c #950000",
"V  c #CC0000",
"W  c #D50000",
"X  c #880000",
"Y  c #830000",
"Z  c #800000",
"\`     c #DE0000",
" . c #780000",
".. c #E10000",
"+. c #730000",
"@. c #E60000",
"#. c #EA0000",
"\$.    c #EE0000",
"                                                                                                                                ",
"                                                                                                                                ",
"                                                                                                                                ",
"                                                                                                                                ",
"                                                                .                                                               ",
"                                                                +                                                               ",
"                                                                @                                                               ",
"                                                                #                                                               ",
"                                                                \$                                                               ",
"                                                                %                                                               ",
"                                                                &                                                               ",
"                                                                *                                                               ",
"                                                                =                                                               ",
"                                                                -                                                               ",
"                                                                ;                                                               ",
"                                                                > >                                                             ",
"                                                              , ' ,                                                             ",
"                                                              ) ! !                                                             ",
"                                                              ~ ~ {                                                             ",
"                                                              ] ^ /                                                             ",
"          (                                                   _ _ _                                                   (         ",
"        :                                                     < < <                                                     [       ",
"      } |                                                     1 1 1                                                     2 2     ",
"    3 3                                                       4 4 4                                                       5 3   ",
"    6 6                                                       7 7 7                                                       8 8   ",
"    9 9 9                                                     0 0 0                                                     a a a   ",
"      b b b b                                                 c c c                                                 b d d d     ",
"      e f f f f e e                                           g g g                                           h h h h h h f     ",
"          i i i i i i i i j                                   k k k                                   l l l l l l l l l         ",
"              m m m m m m m m m m m n m o                     p p p                     o o n n n n n n n n n n n n             ",
"                  q q r s s s s s s s s s s s s s s s s t     u u u     t s s s s s s s s s s s s s s s s s s s                 ",
"                          v v v v v v v v v v v v v v v v     w w w w   v v v v v v v v v v v v v v v v                         ",
"                                  x x x x x x x x x x x x     y y y y   x x x x x x x x x x x x                                 ",
"                                            z z A A A A A     B B B     A A A A z z z                                           ",
"                                                    C C C     D D D     E E E                                                   ",
"                                                    F F F     G G G     F F F                                                   ",
"                                                    H H H     I I I     H H H                                                   ",
"                                                    D D D     F F F     D D D                                                   ",
"                                                    J J J     K K K     J J J                                                   ",
"                                                    L L L     C C C     L L L                                                   ",
"                                                    M M M     z z z     p p M                                                   ",
"                                                    N O O     P P P     O O O                                                   ",
"                                                    Q R R     x x x     R R R                                                   ",
"                                                      S 7     T T v     S S                                                     ",
"                                                      U U     v V v     U U                                                     ",
"                                                      < <     t s s     < <                                                     ",
"                                                      ] ]     o q q     ^ ]                                                     ",
"                                                      ~ ~       m W     X X                                                     ",
"                                                      ' Y       l l     ' '                                                     ",
"                                                      Z         j         Z                                                     ",
"                                                      -         f         -                                                     ",
"                                                      *         \`          .                                                    ",
"                                                      &         ..        +.                                                    ",
"                                                                9                                                               ",
"                                                                @.                                                              ",
"                                                                6                                                               ",
"                                                                #.                                                              ",
"                                                                \$.                                                              ",
"                                                                2                                                               ",
"                                                                |                                                               ",
"                                                                                                                                ",
"                                                                                                                                ",
"                                                                                                                                ",
"                                                                                                                                "};
_EOF_

    cat >"$md_inst/quake3chronic_72x72.xpm" << _EOF_
/* XPM */
static char * quake3chronic_72x72_xpm[] = {
"72 72 551 2",
"   c None",
".  c #0A1D0C",
"+  c #0A1F0D",
"@  c #0B240E",
"#  c #0D2910",
"\$     c #143F19",
"%  c #071809",
"&  c #113415",
"*  c #1B5522",
"=  c #16441B",
"-  c #1F5F26",
";  c #081809",
">  c #091D0B",
",  c #236B2B",
"'  c #08190A",
")  c #1E5E26",
"!  c #26732F",
"~  c #091B0B",
"{  c #091C0B",
"]  c #26732E",
"^  c #297C33",
"/  c #091D0C",
"(  c #2E8638",
"_  c #2D8938",
":  c #0A200D",
"<  c #020602",
"[  c #3C9346",
"}  c #308D3B",
"|  c #030C04",
"1  c #0A1F0C",
"2  c #4FA559",
"3  c #318E3C",
"4  c #113615",
"5  c #041005",
"6  c #0C270F",
"7  c #60B269",
"8  c #328C3C",
"9  c #15411A",
"0  c #051306",
"a  c #103314",
"b  c #6EBD76",
"c  c #31873A",
"d  c #194D1F",
"e  c #061507",
"f  c #79C782",
"g  c #2F8339",
"h  c #1D5C25",
"i  c #071708",
"j  c #184D1E",
"k  c #85CF8D",
"l  c #2E7F37",
"m  c #206127",
"n  c #091C0C",
"o  c #1E6226",
"p  c #8CD494",
"q  c #2D7C36",
"r  c #22682A",
"s  c #081A0A",
"t  c #216D2A",
"u  c #96DA9D",
"v  c #2C7A35",
"w  c #246E2D",
"x  c #2E7E37",
"y  c #9BDDA2",
"z  c #2B7834",
"A  c #256E2D",
"B  c #010401",
"C  c #3E8E47",
"D  c #9FDEA6",
"E  c #2B7633",
"F  c #27742F",
"G  c #030903",
"H  c #0A1E0C",
"I  c #133917",
"J  c #4C9C54",
"K  c #A2DFA9",
"L  c #2A7432",
"M  c #25712E",
"N  c #0E2B11",
"O  c #040D05",
"P  c #0F2F13",
"Q  c #15401A",
"R  c #0B230E",
"S  c #103113",
"T  c #216529",
"U  c #194C1E",
"V  c #071608",
"W  c #5CAE65",
"X  c #A1DFA8",
"Y  c #297231",
"Z  c #236A2C",
"\`     c #144019",
" . c #051106",
".. c #103214",
"+. c #22672A",
"@. c #184C1E",
"#. c #184A1E",
"\$.    c #2A7E34",
"%. c #184A1D",
"&. c #091A0A",
"*. c #0D2A11",
"=. c #6DB875",
"-. c #286F30",
";. c #22652A",
">. c #194F1F",
",. c #061307",
"'. c #0D2810",
"). c #267430",
"!. c #22692B",
"~. c #0B220D",
"{. c #174A1D",
"]. c #2E8B39",
"^. c #1B5622",
"/. c #081B0A",
"(. c #020803",
"_. c #133E18",
":. c #76C27E",
"<. c #9DDEA5",
"[. c #276D2F",
"}. c #1F5E26",
"|. c #1C5723",
"1. c #0F3013",
"2. c #2B8135",
"3. c #0D2B11",
"4. c #409A4A",
"5. c #2C8236",
"6. c #000000",
"7. c #194E1F",
"8. c #80C988",
"9. c #276C2F",
"0. c #1C5523",
"a. c #206428",
"b. c #1A5221",
"c. c #297B33",
"d. c #1A5120",
"e. c #216229",
"f. c #65BC6E",
"g. c #071709",
"h. c #89D091",
"i. c #98DCA0",
"j. c #266A2E",
"k. c #1A4F20",
"l. c #226A2B",
"m. c #44964D",
"n. c #71BB79",
"o. c #0F3113",
"p. c #040F05",
"q. c #8ED796",
"r. c #96DB9D",
"s. c #25682D",
"t. c #194C20",
"u. c #236C2C",
"v. c #246D2C",
"w. c #22662A",
"x. c #15431B",
"y. c #061508",
"z. c #54A55D",
"A. c #71B978",
"B. c #0F2F12",
"C. c #061407",
"D. c #95DA9D",
"E. c #92DA9B",
"F. c #24652B",
"G. c #194A1E",
"H. c #256F2D",
"I. c #246D2D",
"J. c #1D5824",
"K. c #3A8D43",
"L. c #88D190",
"M. c #2F7E38",
"N. c #091B0A",
"O. c #2E8538",
"P. c #97DC9F",
"Q. c #8ED897",
"R. c #22622A",
"S. c #18491E",
"T. c #256F2E",
"U. c #1D5B24",
"V. c #1B5421",
"W. c #4D9354",
"X. c #7ACA83",
"Y. c #54A75D",
"Z. c #15421A",
"\`.    c #0C240E",
" + c #44944D",
".+ c #94DB9C",
"++ c #8AD793",
"@+ c #215F28",
"#+ c #18481E",
"\$+    c #0D2C11",
"%+ c #0B210D",
"&+ c #123A17",
"*+ c #2C8537",
"=+ c #297B32",
"-+ c #0E2E12",
";+ c #051006",
">+ c #25722E",
",+ c #2B6F33",
"'+ c #69B371",
")+ c #84D28C",
"!+ c #74C47D",
"~+ c #55AA5E",
"{+ c #398E42",
"]+ c #276E2F",
"^+ c #1C5924",
"/+ c #15441B",
"(+ c #529F5A",
"_+ c #91DA9A",
":+ c #86D58F",
"<+ c #205C27",
"[+ c #246C2C",
"}+ c #103515",
"|+ c #050F06",
"1+ c #22682B",
"2+ c #2E8438",
"3+ c #3D9D48",
"4+ c #3DA74A",
"5+ c #31913C",
"6+ c #1F5D26",
"7+ c #17441C",
"8+ c #010301",
"9+ c #081A0B",
"0+ c #2B6E33",
"a+ c #65A96C",
"b+ c #96DC9F",
"c+ c #8ED997",
"d+ c #83D08B",
"e+ c #77C880",
"f+ c #6BBD74",
"g+ c #61B169",
"h+ c #52A95C",
"i+ c #4A9C52",
"j+ c #428F4B",
"k+ c #378840",
"l+ c #2C8136",
"m+ c #277931",
"n+ c #246F2D",
"o+ c #206328",
"p+ c #1E6026",
"q+ c #1E5F26",
"r+ c #0C250F",
"s+ c #0D2A10",
"t+ c #59AF62",
"u+ c #8DD996",
"v+ c #81D48B",
"w+ c #1F5A26",
"x+ c #18471D",
"y+ c #15431A",
"z+ c #051307",
"A+ c #1F6026",
"B+ c #236C2B",
"C+ c #246F2C",
"D+ c #287B31",
"E+ c #32873C",
"F+ c #3B8D44",
"G+ c #40984A",
"H+ c #46A451",
"I+ c #4FAB59",
"J+ c #56B561",
"K+ c #5DBF68",
"L+ c #64C56F",
"M+ c #5ABE65",
"N+ c #48A152",
"O+ c #327B3A",
"P+ c #16411B",
"Q+ c #1B5322",
"R+ c #26722F",
"S+ c #206128",
"T+ c #1D5524",
"U+ c #3E7F45",
"V+ c #6AAC71",
"W+ c #84CB8C",
"X+ c #92D99B",
"Y+ c #96DC9E",
"Z+ c #95DC9D",
"\`+    c #92DB9B",
" @ c #8FDA98",
".@ c #8CD895",
"+@ c #88D692",
"@@ c #86D590",
"#@ c #86D48F",
"\$@    c #82D38B",
"%@ c #7ED187",
"&@ c #52AE5C",
"*@ c #0E2D11",
"=@ c #62B56C",
"-@ c #89D892",
";@ c #7DD287",
">@ c #1E5825",
",@ c #17461D",
"'@ c #287831",
")@ c #78CF82",
"!@ c #79D083",
"~@ c #77D082",
"{@ c #76D081",
"]@ c #77D181",
"^@ c #76D181",
"/@ c #77D282",
"(@ c #76D180",
"_@ c #72CE7D",
":@ c #66C171",
"<@ c #53A35C",
"[@ c #317639",
"}@ c #194A1F",
"|@ c #1B5221",
"1@ c #0E2C11",
"2@ c #020702",
"3@ c #1C5622",
"4@ c #1C5422",
"5@ c #296730",
"6@ c #498D51",
"7@ c #62A96A",
"8@ c #74C07C",
"9@ c #80D089",
"0@ c #89D792",
"a@ c #8ED996",
"b@ c #8CD995",
"c@ c #8BD894",
"d@ c #8AD893",
"e@ c #52A55B",
"f@ c #071508",
"g@ c #14411A",
"h@ c #66BF70",
"i@ c #84D68E",
"j@ c #78D082",
"k@ c #1C5423",
"l@ c #17451D",
"m@ c #1C5623",
"n@ c #1D5A24",
"o@ c #23692B",
"p@ c #75D080",
"q@ c #7BD386",
"r@ c #7AD285",
"s@ c #79D284",
"t@ c #78D282",
"u@ c #70CF7B",
"v@ c #68C773",
"w@ c #5CB867",
"x@ c #4EA158",
"y@ c #3A8543",
"z@ c #226229",
"A@ c #16421B",
"B@ c #206227",
"C@ c #000100",
"D@ c #051005",
"E@ c #133D18",
"F@ c #206228",
"G@ c #1A4D20",
"H@ c #24622B",
"I@ c #33803C",
"J@ c #46924F",
"K@ c #56A55F",
"L@ c #60B16A",
"M@ c #6ABC73",
"N@ c #7FD389",
"O@ c #85D68F",
"P@ c #45964E",
"Q@ c #184D1F",
"R@ c #69C574",
"S@ c #7FD489",
"T@ c #72CE7C",
"U@ c #1B5222",
"V@ c #17451C",
"W@ c #1A4E20",
"X@ c #1F6127",
"Y@ c #6ACB75",
"Z@ c #75D180",
"\`@    c #71CE7B",
" # c #4CA356",
".# c #3C8D45",
"+# c #2C7B35",
"@# c #215E28",
"## c #184A1F",
"\$#    c #16441C",
"%# c #16431B",
"&# c #1A4F21",
"*# c #123B17",
"=# c #1D5924",
"-# c #16431C",
";# c #68BF72",
"># c #80D58A",
",# c #7ED488",
"'# c #338D3D",
")# c #061408",
"!# c #64C46F",
"~# c #7AD284",
"{# c #6CCC77",
"]# c #1A4C1F",
"^# c #216428",
"/# c #1B5422",
"(# c #61C16C",
"_# c #6FCF7A",
":# c #67C772",
"<# c #1F6027",
"[# c #000101",
"}# c #216429",
"|# c #63B96D",
"1# c #7BD385",
"2# c #78D182",
"3# c #287932",
"4# c #5ABA65",
"5# c #74D07F",
"6# c #67C872",
"7# c #194C1F",
"8# c #184E1F",
"9# c #56BB62",
"0# c #68CD74",
"a# c #60C36B",
"b# c #081909",
"c# c #030B04",
"d# c #010201",
"e# c #0C2810",
"f# c #22692A",
"g# c #5EB368",
"h# c #6ECD79",
"i# c #040E05",
"j# c #50AF5B",
"k# c #6ECE79",
"l# c #61C56D",
"m# c #1E5C25",
"n# c #4CB358",
"o# c #62CB6E",
"p# c #57BF63",
"q# c #18491D",
"r# c #25702E",
"s# c #040D04",
"t# c #57AD61",
"u# c #62C86E",
"v# c #030A04",
"w# c #44A64F",
"x# c #67CC73",
"y# c #5BC167",
"z# c #216328",
"A# c #051206",
"B# c #0E2D12",
"C# c #45AA50",
"D# c #5AC867",
"E# c #4EBB5A",
"F# c #17471D",
"G# c #020502",
"H# c #061608",
"I# c #16401B",
"J# c #4EA859",
"K# c #5ABF66",
"L# c #3B9746",
"M# c #60CA6C",
"N# c #55BE61",
"O# c #236A2B",
"P# c #030A03",
"Q# c #3AA347",
"R# c #53C660",
"S# c #46B453",
"T# c #103213",
"U# c #45A450",
"V# c #62CA6E",
"W# c #4FB95B",
"X# c #051207",
"Y# c #308C3B",
"Z# c #58C765",
"\`#    c #4EB95A",
" \$    c #33953F",
".\$    c #4BC359",
"+\$    c #3FAD4C",
"@\$    c #1A5021",
"#\$    c #1E5D25",
"\$\$   c #0C260F",
"%\$    c #3E9C49",
"&\$    c #46B253",
"*\$    c #287B32",
"=\$    c #50C45E",
"-\$    c #46B553",
";\$    c #2D8637",
">\$    c #42C051",
",\$    c #38A645",
"'\$    c #15411B",
")\$    c #19501F",
"!\$    c #389343",
"~\$    c #52C560",
"{\$    c #3FA84B",
"]\$    c #0F2E12",
"^\$    c #46C054",
"/\$    c #3EB04C",
"(\$    c #010402",
"_\$    c #297E33",
":\$    c #3DB64B",
"<\$    c #349D40",
"[\$    c #133C18",
"}\$    c #328B3D",
"|\$    c #4AC358",
"1\$    c #37A144",
"2\$    c #3EB74C",
"3\$    c #39AA46",
"4\$    c #236B2C",
"5\$    c #081B0B",
"6\$    c #39AC47",
"7\$    c #30923C",
"8\$    c #153F1A",
"9\$    c #040C04",
"0\$    c #2C8437",
"a\$    c #31923C",
"b\$    c #010502",
"c\$    c #35A142",
"d\$    c #36A142",
"e\$    c #2D8737",
"f\$    c #153E1A",
"g\$    c #287A32",
"h\$    c #3DB84C",
"i\$    c #2C8436",
"j\$    c #32963E",
"k\$    c #153E19",
"l\$    c #1E5E25",
"m\$    c #32973E",
"n\$    c #143E19",
"o\$    c #17491D",
"p\$    c #3AAD48",
"q\$    c #2F8D3A",
"r\$    c #308F3B",
"s\$    c #216329",
"t\$    c #36A343",
"u\$    c #2C8336",
"v\$    c #143C19",
"w\$    c #1E5D26",
"x\$    c #2D8838",
"y\$    c #194D20",
"z\$    c #33983F",
"A\$    c #2D8738",
"B\$    c #144119",
"C\$    c #113816",
"D\$    c #1E5B25",
"E\$    c #1A5220",
"F\$    c #308E3A",
"G\$    c #297A32",
"H\$    c #143B18",
"I\$    c #1B5121",
"J\$    c #143F18",
"K\$    c #26742F",
"L\$    c #133A18",
"M\$    c #277530",
"N\$    c #2A7F34",
"O\$    c #133918",
"P\$    c #1A5321",
"Q\$    c #26712F",
"R\$    c #020703",
"S\$    c #1D5B25",
"T\$    c #216629",
"U\$    c #206027",
"V\$    c #16471C",
"W\$    c #2A8035",
"X\$    c #123916",
"Y\$    c #1B5321",
"Z\$    c #010101",
"                                                                                                                                                ",
"                                                                        .                                                                       ",
"                                                                      + @                                                                       ",
"                                                                      # \$ %                                                                     ",
"                                                                      & * %                                                                     ",
"                                                                      = - ;                                                                     ",
"                                                                    > * , '                                                                     ",
"                                                                    > ) ! ~                                                                     ",
"                                                                    { ] ^ {                                                                     ",
"                                                                    / ( _ : <                                                                   ",
"                                                                    . [ } # |                                                                   ",
"                                                                    1 2 3 4 5                                                                   ",
"                                                                    6 7 8 9 0                                                                   ",
"                                                                    a b c d e                                                                   ",
"                                                                    \$ f g h i                                                                   ",
"                                                                    j k l m ;                                                                   ",
"                                                                  n o p q r s                                                                   ",
"                                                                  / t u v w ~                                                                   ",
"                                                                  { x y z A / B                                                                 ",
"                      / >                                         / C D E F : G                                       H / >                     ",
"                  . 4 I :                                         . J K L M N O                                       / P Q R {                 ",
"              H S T U / V                                         1 W X Y Z \`  .                                        { ..+.@.H               ",
"            . #.\$.%.&.|                                           *.=.D -.;.>.,.                                          ' '.).!.~.            ",
"          H {.].^./.(.                                            _.:.<.[.}.|.V                                             % 1.2., H           ",
"          3.4.5.H | 6.                                            7.8.y 9.0.a.%                                               s b.c.d.s         ",
"        . e.f.b.g.6.                                            . ^.h.i.j.k.l.'                                                 @ M A ~.        ",
"        1 m.n.o.p.                                              / a.q.r.s.t.u.'                                                 { v.w.x.y.      ",
"        # z.A.B.C.                                              . A D.E.F.G.H.~                                                 { I.0.J.g.      ",
"        '.K.L.M.N N.%                                           { O.P.Q.R.S.T.~.(.                                          / : U.! J.V.V       ",
"        / r W.X.Y.w Z.\`./ { {                                   /  +.+++@+#+T.\$+|                                 / / / %+&+) *+=+#+T.-+;+      ",
"        ~ 1.>+,+'+)+!+~+{+]+^+/+4 *.R : H . / / . . . H H H     ~.(+_+:+<+#+[+}+|+C.~ / H H . / / / H 1 : R *.& Z.* 1+2+3+4+5+6+7+[+d ' 8+      ",
"          9+o.v.w.0+a+h.b+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+h U.r+  s+t+u+v+w+x+w.y+z+s d.p+p+A+B+C+D+5.E+F+G+H+I+J+K+L+M+N+O+G.P+Q+T.%.s (.        ",
"            % : * R+S+T+U+V+W+X+Y+Y+Z+.+\`+ @.@+++@@@#@\$@%@&@*@g.a =@-@;@>@,@}.d.y.' '@)@!@)@~@{@]@^@]@/@/@(@_@:@<@[@}@P+P+|@A o+1@; 2@6.        ",
"                ' r+3@n+Z 4@S.5@6@7@8@9@0@a@c+u+u+b@c@d@-@e@R f@g@h@i@j@k@l@m@n@V ; o@p@q@r@s@t@(@u@v@w@x@y@z@A@A@A@#+S+w B@a s  .C@6.          ",
"                  D@; H E@F@I.o@J.}@x+G@H@I@J@K@L@M@N@O@i@P@> f@Q@R@S@T@U@V@W@o+% g.X@Y@Z@\`@ #.#+#@###\$#%#A@7+&#F@[++.#.@ '  .8+6.              ",
"                      G C.' : *#=#!.A w.4@x+7+7+-#-#;#>#,#'#s )#Q@!#~#{#k.7+]#^#% y./#(#_#:#d.7+-#-#\$#W@<#I.Z - /+r+s y.| [#6.                  ",
"                            G ,.% ~ \`.y+- I.A }#\$#%#|#1#2#3#'  .\` 4#5#6#7#7+k@n@V ,.8#9#0#a#d -#m@I.w a.j # > b#C.c#d#6.                        ",
"                                    | C.; ~ e#f#W@A@g#Z@h#v.; i#..j#k#l##.%#m#d.C. .\` n#o#p#q#A@r#a { ' C.s#B 6.6.                              ",
"                                          8+g.V.=#P+t#_#u#o+V v## w#x#y#x+A@z#/+A#O B#C#D#E#F#A@[+&.G#6.6.                                      ",
"                                            H#/+z#I#J#0#K#^.)#2@: L#M#N#V@P+O#4 p.P#%+Q#R#S#7+,@+.' C@                                          ",
"                                              T#O#Q U#V#W#>.X#B ~ Y#Z#\`#7+P+I.\$+c#  /  \$.\$+\$-#@\$#\$g.6.                                          ",
"                                              \$\$I.Q %\$D#&\$Z.5   s *\$=\$-\$A@Q I.~.2@  { ;\$>\$,\$'\$m#)\$C.                                            ",
"                                              . w Q !\$~\${\$]\$s#  s , ^\$/\$P+Q w ~ (\$  ~ _\$:\$<\$Q w.[\$ .                                            ",
"                                              { O#A@}\$|\$1\$%+G   ' X@2\$3\$Q P+4\$' C@  5\$w 6\$7\$8\$[+*@9\$                                            ",
"                                              { ^#S.0\$>\$a\$/ b\$  ' V.6\$c\$8\$-#!.'     s a.d\$e\$f\$w : 2@                                            ",
"                                              n ^.J.g\$h\$i\$~ 8+  % j d\$j\$k\$#.a.g.    ' l\$m\$*\$n\$v.s d#                                            ",
"                                                o\$F@n+p\$^ s C@    *#m\$q\$n\$0.|.y.    ' Q@r\$r#A@!.' 6.                                            ",
"                                                B.u.s\$t\$v.'       '.r\$u\$v\$w\$)\$,.      9 x\$T y\$<#g.                                              ",
"                                                1 M =#z\$}#g.      1 A\$3#v\$}#B\$5       C\$2.D\$D\$E\$C.                                              ",
"                                                / I.@\$F\$h V       . G\$w H\$u.N s#      N '@I\$}#J\$;+                                              ",
"                                                { r W@;\$d C.      n K\$T L\$r#: (.      %+M\$S.n+\$\$c#                                              ",
"                                                { - I\$N\$Z.A#      { l.6+O\$4\$> B       . T.P+[+. b\$                                              ",
"                                                ~ P\$J.'@C\$p.      { X@J.H\$u.~ d#      / o@8\$4\$~ d#                                              ",
"                                                  g@o+Q\$N c#      ~ U.J.8\$+.' 6.      { +.F#o+' 6.                                              ",
"                                                  o.+.T.~.R\$      { %.D\$V@<#%         ~ B@4@#\$g.                                                ",
"                                                  %+u.4\$. 8+        \$ F@7.U.V         { S\$}##.C.                                                ",
"                                                  / O#1+~ [#        a T\$|.j C.        { * K\$*# .                                                ",
"                                                  { u.v.'           \$\$!.U\$9 A#          V\$W\$# |                                                 ",
"                                                  { X@r ;           H 4\$}#}+p.          X\$N\$1 G#                                                ",
"                                                  { Y\$) g.          . r 1+'.v#          B#! ~ Z\$                                                ",
"                                                    E@* H#          > +.I.1 G#          \$\$}.'                                                   ",
"                                                    N 9 C.          ~ F@M { d#          : = g.                                                  ",
"                                                    1 R  .          { #\$! s C@          > \$\$y.                                                  ",
"                                                      %             { V.O#'               '                                                     ",
"                                                                      y+) g.                                                                    ",
"                                                                      a /#V                                                                     ",
"                                                                      '.E@C.                                                                    ",
"                                                                      1 %+ .                                                                    ",
"                                                                        i                                                                       ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                "};
_EOF_

    cat >"$md_inst/quake3ctf_82x82.xpm" << _EOF_
/* XPM */
static char * quake3ctf_82x82_xpm[] = {
"82 82 772 2",
"   c None",
".  c #570000",
"+  c #580000",
"@  c #6A0101",
"#  c #860505",
"\$     c #510000",
"%  c #7B0404",
"&  c #A51313",
"*  c #4E0000",
"=  c #8E0909",
"-  c #B61B1B",
";  c #540000",
">  c #A11212",
",  c #C51F1F",
"'  c #560000",
")  c #B01A1A",
"!  c #D32525",
"~  c #530000",
"{  c #BE1E1E",
"]  c #DC2929",
"^  c #260000",
"/  c #CD2B2B",
"(  c #E52E2E",
"_  c #600101",
":  c #300000",
"<  c #D83A3A",
"[  c #ED3535",
"}  c #6A0202",
"|  c #370000",
"1  c #5D0000",
"2  c #E24646",
"3  c #F03C3C",
"4  c #3E0000",
"5  c #630101",
"6  c #EC5757",
"7  c #F13D3D",
"8  c #900B0B",
"9  c #440000",
"0  c #710303",
"a  c #F36969",
"b  c #A11616",
"c  c #480000",
"d  c #860707",
"e  c #F57777",
"f  c #F13C3C",
"g  c #4B0000",
"h  c #991212",
"i  c #F78383",
"j  c #F13B3B",
"k  c #BF1B1B",
"l  c #4F0000",
"m  c #A81A1A",
"n  c #F98E8E",
"o  c #F03A3A",
"p  c #CB2121",
"q  c #B91F1F",
"r  c #FA9999",
"s  c #F03838",
"t  c #D72222",
"u  c #200000",
"v  c #C82C2C",
"w  c #FBA0A0",
"x  c #F03737",
"y  c #E12121",
"z  c #2B0000",
"A  c #D33535",
"B  c #FDA7A7",
"C  c #E92525",
"D  c #5F0000",
"E  c #320000",
"F  c #DF4242",
"G  c #FDADAD",
"H  c #F03636",
"I  c #EB2222",
"J  c #740303",
"K  c #3A0000",
"L  c #590000",
"M  c #EB5555",
"N  c #FEADAD",
"O  c #F03434",
"P  c #ED1E1E",
"Q  c #880B0B",
"R  c #410000",
"S  c #5A0000",
"T  c #550000",
"U  c #6B0202",
"V  c #F06868",
"W  c #FEAEAE",
"X  c #F03333",
"Y  c #EE1B1B",
"Z  c #981515",
"\`     c #450000",
" . c #760404",
".. c #A20D0D",
"+. c #7F0404",
"@. c #800707",
"#. c #F47575",
"\$.    c #EE3131",
"%. c #ED1717",
"&. c #A81717",
"*. c #490000",
"=. c #640101",
"-. c #9B0A0A",
";. c #960C0C",
">. c #5D0101",
",. c #680202",
"'. c #B91A1A",
"). c #C61C1C",
"!. c #6F0303",
"~. c #500000",
"{. c #3B0000",
"]. c #921313",
"^. c #F78181",
"/. c #ED2F2F",
"(. c #EB1010",
"_. c #BA1C1C",
":. c #4D0000",
"<. c #520000",
"[. c #A01010",
"}. c #D12222",
"|. c #8D0C0C",
"1. c #820A0A",
"2. c #DE2828",
"3. c #CA2121",
"4. c #610101",
"5. c #A11717",
"6. c #F98D8D",
"7. c #FDABAB",
"8. c #EB2D2D",
"9. c #E90A0A",
"0. c #C62323",
"a. c #920D0D",
"b. c #E72B2B",
"c. c #B61A1A",
"d. c #820B0B",
"e. c #E82E2E",
"f. c #D62626",
"g. c #620101",
"h. c #0B0000",
"i. c #B31C1C",
"j. c #FA9797",
"k. c #FDAAAA",
"l. c #E92C2C",
"m. c #E60505",
"n. c #D32222",
"o. c #1D0000",
"p. c #A01212",
"q. c #F03030",
"r. c #BD1E1E",
"s. c #650202",
"t. c #E03939",
"u. c #EB3C3C",
"v. c #7B0606",
"w. c #0A0000",
"x. c #C22525",
"y. c #FA9E9E",
"z. c #FCA9A9",
"A. c #E82B2B",
"B. c #E40202",
"C. c #DF2323",
"D. c #3C0000",
"E. c #C72020",
"F. c #EC2A2A",
"G. c #A11414",
"H. c #B51C1C",
"I. c #F56E6E",
"J. c #C22323",
"K. c #220000",
"L. c #000000",
"M. c #CE2B2B",
"N. c #FCA6A6",
"O. c #FCA7A7",
"P. c #E62A2A",
"Q. c #E20000",
"R. c #E42626",
"S. c #2F0000",
"T. c #4C0000",
"U. c #7E0707",
"V. c #E62424",
"W. c #DE2424",
"X. c #E64E4E",
"Y. c #F67979",
"Z. c #930E0E",
"\`.    c #460000",
" + c #DC3939",
".+ c #FCA5A5",
"++ c #E52828",
"@+ c #E00000",
"#+ c #E62323",
"\$+    c #6E0202",
"%+ c #D92525",
"&+ c #DD1B1B",
"*+ c #A61515",
"=+ c #8F0C0C",
"-+ c #F57676",
";+ c #F36F6F",
">+ c #6F0404",
",+ c #E74D4D",
"'+ c #FCA3A3",
")+ c #E32626",
"!+ c #DE0000",
"~+ c #E82020",
"{+ c #810A0A",
"]+ c #3D0000",
"^+ c #CC2323",
"/+ c #D30D0D",
"(+ c #CD1F1F",
"_+ c #A71616",
":+ c #F77B7B",
"<+ c #F47171",
"[+ c #7C0707",
"}+ c #230000",
"|+ c #670101",
"1+ c #EC5D5D",
"2+ c #FCAAAA",
"3+ c #E12323",
"4+ c #DC0000",
"5+ c #E71E1E",
"6+ c #8F1010",
"7+ c #420000",
"8+ c #D22424",
"9+ c #CD0606",
"0+ c #D82121",
"a+ c #9F1212",
"b+ c #F35959",
"c+ c #FA9898",
"d+ c #DB3737",
"e+ c #7A0707",
"f+ c #7A0606",
"g+ c #F26969",
"h+ c #FCA8A8",
"i+ c #FA9D9D",
"j+ c #DF2121",
"k+ c #DB0000",
"l+ c #E41A1A",
"m+ c #A31515",
"n+ c #470000",
"o+ c #B81D1D",
"p+ c #E12929",
"q+ c #CA0505",
"r+ c #D32020",
"s+ c #210000",
"t+ c #6D0202",
"u+ c #E52424",
"v+ c #F36464",
"w+ c #F98F8F",
"x+ c #EE5C5C",
"y+ c #C52929",
"z+ c #910D0D",
"A+ c #670202",
"B+ c #890D0D",
"C+ c #F57575",
"D+ c #FBA6A6",
"E+ c #FA9A9A",
"F+ c #DD1E1E",
"G+ c #D90000",
"H+ c #E11313",
"I+ c #820707",
"J+ c #B41D1D",
"K+ c #DF3333",
"L+ c #E03131",
"M+ c #C70909",
"N+ c #DA1B1B",
"O+ c #AA1515",
"P+ c #0C0000",
"Q+ c #A51414",
"R+ c #EB2121",
"S+ c #EC3B3B",
"T+ c #F78484",
"U+ c #F99393",
"V+ c #F67878",
"W+ c #E95454",
"X+ c #BB2222",
"Y+ c #860808",
"Z+ c #5B0000",
"\`+    c #9B1111",
" @ c #F67F7F",
".@ c #FBA3A3",
"+@ c #F99797",
"@@ c #DC1C1C",
"#@ c #D70000",
"\$@    c #DC0E0E",
"%@ c #C11F1F",
"&@ c #6E0303",
"*@ c #810707",
"=@ c #990E0E",
"-@ c #CD2C2C",
";@ c #E34242",
">@ c #ED4F4F",
",@ c #E34141",
"'@ c #CF2323",
")@ c #C40101",
"!@ c #D41616",
"~@ c #D02121",
"{@ c #5E0101",
"]@ c #380000",
"^@ c #A81616",
"/@ c #E92323",
"(@ c #E70F0F",
"_@ c #EB4747",
":@ c #F58484",
"<@ c #FBA1A1",
"[@ c #FA9393",
"}@ c #F47272",
"|@ c #EE6161",
"1@ c #E75050",
"2@ c #DB3F3F",
"3@ c #D13434",
"4@ c #C82A2A",
"5@ c #BC1E1E",
"6@ c #B11616",
"7@ c #A81313",
"8@ c #A01111",
"9@ c #9A0F0F",
"0@ c #8F0B0B",
"a@ c #8C0A0A",
"b@ c #820808",
"c@ c #7C0606",
"d@ c #750505",
"e@ c #6B0000",
"f@ c #910909",
"g@ c #963030",
"h@ c #831111",
"i@ c #800000",
"j@ c #820000",
"k@ c #8D0606",
"l@ c #730000",
"m@ c #620000",
"n@ c #880909",
"o@ c #8E0B0B",
"p@ c #930D0D",
"q@ c #9B0F0F",
"r@ c #A41212",
"s@ c #AA1414",
"t@ c #B21717",
"u@ c #BC1F1F",
"v@ c #C82828",
"w@ c #D13030",
"x@ c #DA3838",
"y@ c #E44545",
"z@ c #EC5353",
"A@ c #F06060",
"B@ c #F36B6B",
"C@ c #F06C6C",
"D@ c #E86262",
"E@ c #D94545",
"F@ c #CA1B1B",
"G@ c #C50303",
"H@ c #DA1C1C",
"I@ c #CD2121",
"J@ c #D82323",
"K@ c #E91D1D",
"L@ c #E20606",
"M@ c #E42E2E",
"N@ c #ED6969",
"O@ c #F68F8F",
"P@ c #FBA5A5",
"Q@ c #FAA2A2",
"R@ c #FA9C9C",
"S@ c #F99292",
"T@ c #F88E8E",
"U@ c #F78686",
"V@ c #F78080",
"W@ c #F67C7C",
"X@ c #F47474",
"Y@ c #F27070",
"Z@ c #F16666",
"\`@    c #EF4F4F",
" # c #7B0000",
".# c #7A0000",
"+# c #C12323",
"@# c #F36868",
"## c #F26868",
"\$#    c #F46C6C",
"%# c #F46D6D",
"&# c #F57171",
"*# c #F57474",
"=# c #F57878",
"-# c #F57D7D",
";# c #F58080",
"># c #F58383",
",# c #F58686",
"'# c #F58989",
")# c #F58B8B",
"!# c #F28484",
"~# c #E97070",
"{# c #D94949",
"]# c #CA1717",
"^# c #C50101",
"/# c #C40000",
"(# c #D21515",
"_# c #AC1717",
":# c #5C0101",
"<# c #0E0000",
"[# c #A21515",
"}# c #DC2424",
"|# c #E81F1F",
"1# c #E00B0B",
"2# c #DD0000",
"3# c #DF3030",
"4# c #E75D5D",
"5# c #F07D7D",
"6# c #F69393",
"7# c #FA9F9F",
"8# c #FBA4A4",
"9# c #FAA3A3",
"0# c #FAA1A1",
"a# c #F9A1A1",
"b# c #F9A0A0",
"c# c #F89F9F",
"d# c #F89E9E",
"e# c #F29999",
"f# c #BE4A4A",
"g# c #C26363",
"h# c #F38E8E",
"i# c #F89292",
"j# c #F89191",
"k# c #F79090",
"l# c #F78F8F",
"m# c #F78E8E",
"n# c #F68E8E",
"o# c #F68D8D",
"p# c #F38484",
"q# c #ED7878",
"r# c #E36464",
"s# c #D74545",
"t# c #CB1D1D",
"u# c #C60000",
"v# c #C70404",
"w# c #D61919",
"x# c #E02424",
"y# c #BB1D1D",
"z# c #700505",
"A# c #050000",
"B# c #971010",
"C# c #CE2121",
"D# c #E52121",
"E# c #E31818",
"F# c #DC0606",
"G# c #D80000",
"H# c #D80808",
"I# c #DB2E2E",
"J# c #E14D4D",
"K# c #E86767",
"L# c #EE7B7B",
"M# c #F38888",
"N# c #F79494",
"O# c #F89999",
"P# c #F99D9D",
"Q# c #F99E9E",
"R# c #F89D9D",
"S# c #F89C9C",
"T# c #F79C9C",
"U# c #C16A6A",
"V# c #808000",
"W# c #C18762",
"X# c #F78D8D",
"Y# c #F68A8A",
"Z# c #F27F7F",
"\`#    c #EE7474",
" \$    c #E76666",
".\$    c #DF5454",
"+\$    c #D63A3A",
"@\$    c #CD2020",
"#\$    c #C80101",
"\$\$   c #C70000",
"%\$    c #C50000",
"&\$    c #C70303",
"*\$    c #D21212",
"=\$    c #DE2020",
"-\$    c #AD1717",
";\$    c #6D0404",
">\$    c #400000",
",\$    c #190000",
"'\$    c #4A0000",
")\$    c #740404",
"!\$    c #AB1515",
"~\$    c #D02020",
"{\$    c #E32121",
"]\$    c #E31B1B",
"^\$    c #DB0D0D",
"/\$    c #D50202",
"(\$    c #D20000",
"_\$    c #D00000",
":\$    c #D10808",
"<\$    c #D21A1A",
"[\$    c #D52C2C",
"}\$    c #DA4141",
"|\$    c #DE5151",
"1\$    c #E25E5E",
"2\$    c #E97171",
"3\$    c #F79797",
"4\$    c #D27979",
"5\$    c #FFFF00",
"6\$    c #D26D6D",
"7\$    c #E75F5F",
"8\$    c #D83535",
"9\$    c #CE1212",
"0\$    c #CC0303",
"a\$    c #CA0000",
"b\$    c #C80000",
"c\$    c #C70101",
"d\$    c #CC0808",
"e\$    c #D71717",
"f\$    c #DF2020",
"g\$    c #D72121",
"h\$    c #870A0A",
"i\$    c #1B0000",
"j\$    c #010000",
"k\$    c #270000",
"l\$    c #9B1010",
"m\$    c #C21D1D",
"n\$    c #DA2222",
"o\$    c #E42121",
"p\$    c #DF1919",
"q\$    c #D60C0C",
"r\$    c #CF0202",
"s\$    c #CC0000",
"t\$    c #CB0000",
"u\$    c #C90000",
"v\$    c #D12727",
"w\$    c #9C3F3F",
"x\$    c #9C3838",
"y\$    c #DA4545",
"z\$    c #CD0707",
"A\$    c #D61515",
"B\$    c #DD2222",
"C\$    c #CA1F1F",
"D\$    c #A91515",
"E\$    c #2C0000",
"F\$    c #0D0000",
"G\$    c #250000",
"H\$    c #5B0101",
"I\$    c #770404",
"J\$    c #DD2323",
"K\$    c #E22323",
"L\$    c #DB1A1A",
"M\$    c #CC0404",
"N\$    c #CE2020",
"O\$    c #D17070",
"P\$    c #BD3232",
"Q\$    c #D41313",
"R\$    c #E02020",
"S\$    c #E12424",
"T\$    c #CD2222",
"U\$    c #AE1919",
"V\$    c #840808",
"W\$    c #3F0000",
"X\$    c #2A0000",
"Y\$    c #100000",
"Z\$    c #790505",
"\`\$   c #BF1E1E",
" % c #DA1A1A",
".% c #CB1818",
"+% c #B15050",
"@% c #A31F1F",
"#% c #CA0303",
"\$%    c #DD2626",
"%% c #8A0C0C",
"&% c #170000",
"*% c #030000",
"=% c #140000",
"-% c #850909",
";% c #C81212",
">% c #942F2F",
",% c #8E0D0D",
"'% c #CD0A0A",
")% c #C61E1E",
"!% c #330000",
"~% c #6D0303",
"{% c #E02222",
"]% c #C60D0D",
"^% c #830A0A",
"/% c #820101",
"(% c #B31919",
"_% c #040000",
":% c #5F0101",
"<% c #DC2323",
"[% c #C30000",
"}% c #C40909",
"|% c #D81A1A",
"1% c #D42323",
"2% c #C40303",
"3% c #C20606",
"4% c #C00000",
"5% c #DC2020",
"6% c #C80D0D",
"7% c #C00404",
"8% c #810000",
"9% c #BF0000",
"0% c #E02323",
"a% c #6C0404",
"b% c #350000",
"c% c #B41B1B",
"d% c #CF1515",
"e% c #BE0202",
"f% c #912020",
"g% c #8B0202",
"h% c #BD0000",
"i% c #DB2424",
"j% c #9C1111",
"k% c #D61C1C",
"l% c #BD0101",
"m% c #A73333",
"n% c #990404",
"o% c #C00303",
"p% c #D32424",
"q% c #800B0B",
"r% c #DD2121",
"s% c #BA0000",
"t% c #BF4040",
"u% c #A90404",
"v% c #C40D0D",
"w% c #DE2222",
"x% c #B90000",
"y% c #D54A4A",
"z% c #962525",
"A% c #931717",
"B% c #BA0505",
"C% c #CB1414",
"D% c #060000",
"E% c #DB2626",
"F% c #D34444",
"G% c #C14444",
"H% c #B82C2C",
"I% c #B80303",
"J% c #D31C1C",
"K% c #9B1212",
"L% c #BC0505",
"M% c #CE3B3B",
"N% c #DF4F4F",
"O% c #A71818",
"P% c #B52222",
"Q% c #CE3131",
"R% c #B50202",
"S% c #DB2222",
"T% c #800D0D",
"U% c #C32121",
"V% c #C00D0D",
"W% c #CA3333",
"X% c #DE4848",
"Y% c #6E0000",
"Z% c #7C0303",
"\`%    c #B40101",
" & c #360000",
".& c #B21B1B",
"+& c #C91414",
"@& c #C62C2C",
"#& c #DD4141",
"\$&    c #B31D1D",
"%& c #7C7C00",
"&& c #7E0000",
"*& c #6F0000",
"=& c #6A0303",
"-& c #E32C2C",
";& c #C32222",
">& c #B30101",
",& c #290000",
"'& c #991313",
")& c #D21C1C",
"!& c #C12525",
"~& c #DE3A3A",
"{& c #710000",
"]& c #790000",
"^& c #7F0101",
"/& c #820202",
"(& c #740000",
"_& c #690000",
":& c #DD2828",
"<& c #BE1B1B",
"[& c #B70505",
"}& c #D12121",
"|& c #D81F1F",
"1& c #DE3434",
"2& c #980E0E",
"3& c #D72626",
"4& c #BB1414",
"5& c #BC0D0D",
"6& c #C22121",
"7& c #0F0000",
"8& c #6B0101",
"9& c #B91717",
"0& c #E03030",
"a& c #830808",
"b& c #000080",
"c& c #808080",
"d& c #D12323",
"e& c #B80F0F",
"f& c #C51414",
"g& c #B01919",
"h& c #D92323",
"i& c #B71111",
"j& c #E02C2C",
"k& c #720505",
"l& c #008080",
"m& c #C71E1E",
"n& c #B80C0C",
"o& c #CF1C1C",
"p& c #971212",
"q& c #DD2727",
"r& c #BB0D0D",
"s& c #D61F1F",
"t& c #BE1111",
"u& c #D82525",
"v& c #B21A1A",
"w& c #C21212",
"x& c #D82222",
"y& c #AE1717",
"z& c #C91717",
"A& c #280000",
"B& c #981313",
"C& c #D51D1D",
"D& c #A21818",
"E& c #CA1818",
"F& c #B80808",
"G& c #C62020",
"H& c #940D0D",
"I& c #D61E1E",
"J& c #820606",
"K& c #DF2222",
"L& c #C31D1D",
"M& c #D01B1B",
"N& c #BE0E0E",
"O& c #BA1B1B",
"P& c #830909",
"Q& c #E22525",
"R& c #C01E1E",
"S& c #080000",
"T& c #690101",
"U& c #E82C2C",
"V& c #BB1E1E",
"W& c #7E0505",
"X& c #D52020",
"Y& c #AB1919",
"Z& c #760505",
"\`&    c #EB2B2B",
" * c #5C0000",
".* c #E02929",
"+* c #AF1818",
"@* c #CD1919",
"#* c #E92D2D",
"\$*    c #981111",
"%* c #D32626",
"&* c #9E1010",
"** c #D92020",
"=* c #D31E1E",
"-* c #890808",
";* c #5E0000",
">* c #E02A2A",
",* c #C11E1E",
"'* c #8E0C0C",
")* c #D42121",
"!* c #750303",
"~* c #D22222",
"{* c #7F0707",
"]* c #660101",
"^* c #BA1414",
"/* c #880606",
"(* c #390000",
"_* c #E02828",
":* c #990707",
"<* c #2D0000",
"[* c #B91D1D",
"}* c #D92828",
"|* c #1E0000",
"1* c #AA1818",
"2* c #CE2323",
"3* c #C01D1D",
"4* c #870707",
"5* c #B11A1A",
"6* c #9B0E0E",
"7* c #740202",
"                                                                                                                                                                    ",
"                                                                                                                                                                    ",
"                                                                                . +                                                                                 ",
"                                                                                @ # \$                                                                               ",
"                                                                                % & *                                                                               ",
"                                                                              + = - *                                                                               ",
"                                                                              ; > , \$                                                                               ",
"                                                                              ' ) ! ~                                                                               ",
"                                                                              . { ] . ^                                                                             ",
"                                                                              ; / ( _ :                                                                             ",
"                                                                              . < [ } |                                                                             ",
"                                                                              1 2 3 % 4                                                                             ",
"                                                                              5 6 7 8 9                                                                             ",
"                                                                              0 a 7 b c                                                                             ",
"                                                                            . d e f ) g                                                                             ",
"                                                                            ; h i j k l                                                                             ",
"                                                                            ' m n o p \$                                                                             ",
"                                                                            ' q r s t ; u                                                                           ",
"                                                                            ; v w x y + z                                                                           ",
"                                                                            ' A B x C D E                                                                           ",
"                                                                            . F G H I J K                                                                           ",
"                                                                            L M N O P Q R                                                                           ",
"                      S T 1 T                                               U V W X Y Z \`                                             L _ + T                       ",
"                    '  ...+.;                                               @.#.W \$.%.&.*.                                            L =.-.;.>.;                   ",
"                L ,.'.).!.~.{.                                            . ].^.G /.(._.:.                                              <.. [.}.|.T l               ",
"              . 1.2.3.4.*.                                                + 5.6.7.8.9.0.*                                                   <.a.b.c.S :.            ",
"            L d.e.f.g.\` h.                                                . i.j.k.l.m.n.l o.                                                  <.p.q.r.T             ",
"            s.t.u.v.*.w.                                                  ' x.y.z.A.B.C.\$ ^                                                   D.; E.F.G.\$           ",
"          . H.I.J.\$ K.L.                                                  T M.N.O.P.Q.R.S S.                                                    T.U.V.W.,.9         ",
"          =.X.Y.Z.\`.L.                                                    ~  +z..+++@+#+\$+|                                                       . %+&+*+:.        ",
"        S =+-+;+>+K L.                                                    . ,+z.'+)+!+~+{+]+                                                      ; ^+/+(+~.        ",
"        . _+:+<+[+*.}+                                                    |+1+2+w 3+4+5+6+7+                                                      ' 8+9+0++ ^       ",
"        ' a+b+c+d+e+~ :.                                                  f+g+h+i+j+k+l+m+n+                                                + ' 4.o+p+q+r+~ s+      ",
"          t+u+v+w+x+y+z+A+. T T '                                       L B+C+D+E+F+G+H+H.g                                         L ' . 4.I+J+K+L+M+N+O+T.P+      ",
"          ; Q+R+S+T+U+V+W+A X+[.Y+0 _ Z+. T ' . + + + L                 . \`+ @.@+@@@#@\$@%@T.                L + L L + . ' + Z+_ &@*@=@H.-@;@>@,@'@)@!@~@{@]@        ",
"            T ^@/@(@_@:@<@<@[@T+}@|@1@2@3@4@5@6@7@8@9@0@a@b@b@c@d@d@>.T e@f@g@h@i@i@i@j@k@l@m@; f+b@b@b@n@o@p@q@r@s@t@u@v@w@x@y@z@A@B@C@D@E@F@)@G@H@I@A+9 h.        ",
"              ~ Q J@K@L@M@N@O@.@z.O.P@Q@R@+@S@T@U@V@W@-+X@Y@Y@g+Z@\`@a@ #i@i@i@i@i@i@i@i@i@i@i@.#+#@#g+##a \$#%#&#*#=#-#;#>#,#'#)#!#~#{#]#^#/#)@(#C._#:#9 <#L.        ",
"                * :#[#}#|#1#2#3#4#5#6#7#.@8#.@9#Q@Q@0#a#b#b#c#d#e#f#i@i@i@i@i@i@i@i@i@i@i@i@i@i@i@g#h#i#j#j#k#l#m#n#o#)#p#q#r#s#t#u#/#/#v#w#x#y#z#l ]@A#L.          ",
"                  D.:.>.B#C#D#E#F#G#H#I#J#K#L#M#N#O#P#Q#R#R#S#T#U#i@i@i@i@i@i@i@i@i@V#V#V#V#V#V#V#V#W#m#X#Y#,#Z#\`# \$.\$+\$@\$#\$\$\$u#%\$&\$*\$=\$t -\$;\$* >\$,\$L.              ",
"                      ]@'\$; )\$!\$~\${\$]\$^\$/\$(\$_\$:\$<\$[\$}\$|\$1\$2\$3\$4\$i@i@i@i@i@i@L.L.i@V#V#5\$5\$5\$5\$5\$5\$V#i@6\$7\$8\$n.9\$0\$a\$b\$b\$\$\$c\$d\$e\$f\$g\$'.h\$Z+T.{.i\$j\$L.                ",
"                          k\$>\$T.T !.l\$m\$n\$o\$p\$q\$r\$s\$t\$a\$u\$v\$h#w\$i@i@i@i@L.i@i@i@V#V#5\$5\$5\$5\$5\$5\$V#i@i@x\$y\$s\$t\$a\$u\$#\$z\$A\$f\$B\$C\$D\$c@Z+* 7+E\$F\$L.L.                    ",
"                                G\$D.*.\$ H\$I\$m+, J\$K\$L\$M\$\$\$N\$O\$i@i@i@L.L.i@L.L.V#V#5\$5\$5\$5\$5\$V#V#i@i@i@i@P\$a\$u\$Q\$R\$S\$T\$U\$V\$4.~ g W\$X\$<#j\$L.                          ",
"                                      Y\$S.>\$'\$\$ L Z\$\`\$ %u#.%+%i@i@L.i@L.L.L.V#V#5\$5\$5\$5\$V#V#i@L.i@i@i@i@@%b\$#%\$%%%{@~ T.7+E &%*%L.L.                                ",
"                                              =%: c -%f\$%\$;%>%i@L.i@L.L.L.i@V#5\$5\$5\$V#V#V#i@L.i@L.i@i@i@,%u#'%)%l !%i\$L.L.L.                                        ",
"                                                  {.~%{%/#]%^%i@L.i@L.L.V#V#V#V#V#V#V#V#V#V#V#V#V#V#i@i@/%/#(#(%*._%L.                                              ",
"                                                    :%<%[%}%i@L.i@L.L.V#V#V#V#V#V#V#V#V#5\$5\$5\$5\$V#i@i@i@i@[%|%a+9 j\$                                                ",
"                                                    ' 1%2%3%i@L.i@L.V#V#V#V#V#V#V#V#V#V#5\$5\$5\$V#i@L.i@i@i@4%5%-%4 L.                                                ",
"                                                    ; , 6%7%I+L.i@L.L.L.L.L.L.L.L.i@V#V#V#V#V#i@i@L.i@i@8%9%0%a%b%                                                  ",
"                                                    T c%d%e%f%L.i@L.L.L.L.L.L.L.i@V#V#V#V#V#i@L.i@L.i@i@g%h%i%>.X\$                                                  ",
"                                                    T j%k%l%m%i@L.i@L.L.L.L.L.i@V#V#V#V#i@i@L.i@i@i@i@i@n%o%p%\$ o.                                                  ",
"                                                    T q%r%s%t%i@L.i@L.L.L.L.i@V#V#V#V#i@L.L.i@i@L.i@i@i@u%v%, :.<#                                                  ",
"                                                      ~%w%x%y%z%i@L.i@L.L.L.V#V#V#V#i@L.L.i@i@L.i@i@i@A%B%C%J+'\$D%                                                  ",
"                                                      S E%x%F%G%i@i@L.i@i@i@V#V#V#L.L.L.i@i@L.i@i@i@i@H%I%J%K%\`                                                     ",
"                                                      ~ n.L%M%N%O%i@i@L.i@V#V#i@i@i@i@i@i@L.i@i@i@i@P%Q%R%S%T%4                                                     ",
"                                                      ; U%V%W%X%5@Y%i@i@V#V#i@L.L.L.L.i@i@i@i@i@i@Z%3#4@\`%B\$;\$ &                                                    ",
"                                                      T .&+&@&#&\$&g m@%&V#i@i@i@i@i@i@i@i@i@i@&&*&=&-&;&>&%++ ,&                                                    ",
"                                                      T '&)&!&~&O%c     {&]&^&/&i@i@i@8% #(&_&    5 :&<&[&}&~.i\$                                                    ",
"                                                      ~ q%|&5@1&2&L.5\$5\$5\$5\$5\$5\$5\$5\$5\$5\$5\$5\$5\$5\$5\$Z+3&4&5&6&* 7&                                                    ",
"                                                        8&n\$9&0&a&5\$5\$L.L.5\$5\$b&5\$5\$L.L.5\$5\$c&c&c&' d&e&f&g&g j\$                                                    ",
"                                                        + h&i&j&k&5\$5\$L.L.L.l&b&5\$5\$L.c&5\$5\$5\$5\$c&' m&n&o&p&\`                                                       ",
"                                                        ' N\$e&q&,.5\$5\$L.L.L.l&b&5\$5\$b&c&5\$5\$c&c&L.T r.r&s&1.W\$                                                      ",
"                                                        ~ %@t&u&:%5\$5\$L.L.5\$5\$b&5\$5\$L.L.5\$5\$c&L.L.~ v&w&x&8& &                                                      ",
"                                                        ; y&z&p%+ L.5\$5\$5\$5\$l&l&5\$5\$b&b&5\$5\$b&L.L.~ r@.%J@L A&                                                      ",
"                                                        ~ B&C&@\$; 7&        ~ D&E&F&G&~.D%        T H&I&N\$~ i\$                                                      ",
"                                                        ~ J&K&L&~.w.        <.a.M&N&O&:.L.        <.P&Q&R&* S&                                                      ",
"                                                          T&U&V&:.A#          W&X&f&Y&*.            Z&\`&-\$g L.                                                      ",
"                                                           *.*+*'\$            } n\$@*K%\`             } #*\$*\`                                                         ",
"                                                          T %*&*\`.            4.**=*-*>\$            ;*>*J&W\$                                                        ",
"                                                          ~ ,*'*7+            S )*n\$!*K             L ~*T&b%                                                        ",
"                                                          T s@{*4             T C#0%]*!%            + ^* *z                                                         ",
"                                                          ~ /*t+(*            T )%_*1 X\$            T :*<.o.                                                        ",
"                                                            + T <*            T [*}*T |*            ;  **                                                           ",
"                                                              D.              ~ 1*2*\$ F\$              *.                                                            ",
"                                                                              ; 9@3** D%                                                                            ",
"                                                                              T 4*5*g                                                                               ",
"                                                                                J 6*c                                                                               ",
"                                                                                g.7*9                                                                               ",
"                                                                                ; <.b%                                                                              ",
"                                                                                                                                                                    ",
"                                                                                                                                                                    ",
"                                                                                                                                                                    ",
"                                                                                                                                                                    "};
_EOF_

    cat >"$md_inst/quake3ctc_72x72.xpm" << _EOF_
/* XPM */
static char * quake3ctc_72x72_xpm[] = {
"72 72 483 2",
"   c None",
".  c #0A1D0C",
"+  c #0A1F0D",
"@  c #0B240E",
"#  c #0D2910",
"\$     c #143F19",
"%  c #071809",
"&  c #113415",
"*  c #1B5522",
"=  c #16441B",
"-  c #1F5F26",
";  c #081809",
">  c #091D0B",
",  c #236B2B",
"'  c #08190A",
")  c #1E5E26",
"!  c #26732F",
"~  c #091B0B",
"{  c #091C0B",
"]  c #26732E",
"^  c #297C33",
"/  c #091D0C",
"(  c #2E8638",
"_  c #2D8938",
":  c #0A200D",
"<  c #020602",
"[  c #3C9346",
"}  c #308D3B",
"|  c #030C04",
"1  c #0A1F0C",
"2  c #4FA559",
"3  c #318E3C",
"4  c #113615",
"5  c #041005",
"6  c #0C270F",
"7  c #60B269",
"8  c #328C3C",
"9  c #15411A",
"0  c #051306",
"a  c #103314",
"b  c #6EBD76",
"c  c #31873A",
"d  c #194D1F",
"e  c #061507",
"f  c #79C782",
"g  c #2F8339",
"h  c #1D5C25",
"i  c #071708",
"j  c #184D1E",
"k  c #85CF8D",
"l  c #2E7F37",
"m  c #206127",
"n  c #091C0C",
"o  c #1E6226",
"p  c #8CD494",
"q  c #2D7C36",
"r  c #22682A",
"s  c #081A0A",
"t  c #216D2A",
"u  c #96DA9D",
"v  c #2C7A35",
"w  c #246E2D",
"x  c #2E7E37",
"y  c #9BDDA2",
"z  c #2B7834",
"A  c #256E2D",
"B  c #010401",
"C  c #3E8E47",
"D  c #9FDEA6",
"E  c #2B7633",
"F  c #27742F",
"G  c #030903",
"H  c #0A1E0C",
"I  c #133917",
"J  c #4C9C54",
"K  c #A2DFA9",
"L  c #2A7432",
"M  c #25712E",
"N  c #0E2B11",
"O  c #040D05",
"P  c #0F2F13",
"Q  c #15401A",
"R  c #0B230E",
"S  c #103113",
"T  c #216529",
"U  c #194C1E",
"V  c #071608",
"W  c #5CAE65",
"X  c #A1DFA8",
"Y  c #297231",
"Z  c #236A2C",
"\`     c #144019",
" . c #051106",
".. c #103214",
"+. c #22672A",
"@. c #184C1E",
"#. c #184A1E",
"\$.    c #2A7E34",
"%. c #184A1D",
"&. c #091A0A",
"*. c #0D2A11",
"=. c #6DB875",
"-. c #286F30",
";. c #22652A",
">. c #194F1F",
",. c #061307",
"'. c #0D2810",
"). c #267430",
"!. c #22692B",
"~. c #0B220D",
"{. c #174A1D",
"]. c #2E8B39",
"^. c #1B5622",
"/. c #081B0A",
"(. c #020803",
"_. c #133E18",
":. c #76C27E",
"<. c #9DDEA5",
"[. c #276D2F",
"}. c #1F5E26",
"|. c #1C5723",
"1. c #0F3013",
"2. c #2B8135",
"3. c #0D2B11",
"4. c #409A4A",
"5. c #2C8236",
"6. c #000000",
"7. c #194E1F",
"8. c #80C988",
"9. c #276C2F",
"0. c #1C5523",
"a. c #206428",
"b. c #1A5221",
"c. c #297B33",
"d. c #1A5120",
"e. c #216229",
"f. c #65BC6E",
"g. c #071709",
"h. c #89D091",
"i. c #98DCA0",
"j. c #266A2E",
"k. c #1A4F20",
"l. c #226A2B",
"m. c #44964D",
"n. c #71BB79",
"o. c #0F3113",
"p. c #040F05",
"q. c #8ED796",
"r. c #96DB9D",
"s. c #25682D",
"t. c #194C20",
"u. c #236C2C",
"v. c #246D2C",
"w. c #22662A",
"x. c #15431B",
"y. c #061508",
"z. c #54A55D",
"A. c #71B978",
"B. c #0F2F12",
"C. c #061407",
"D. c #95DA9D",
"E. c #92DA9B",
"F. c #24652B",
"G. c #194A1E",
"H. c #256F2D",
"I. c #246D2D",
"J. c #1D5824",
"K. c #3A8D43",
"L. c #88D190",
"M. c #2F7E38",
"N. c #091B0A",
"O. c #1B1B17",
"P. c #2B2B23",
"Q. c #1D5B24",
"R. c #1B5421",
"S. c #4D9354",
"T. c #7ACA83",
"U. c #54A75D",
"V. c #15421A",
"W. c #0C240E",
"X. c #CBD7DF",
"Y. c #0B210D",
"Z. c #123A17",
"\`.    c #2C8537",
" + c #297B32",
".+ c #18481E",
"++ c #256F2E",
"@+ c #0E2E12",
"#+ c #051006",
"\$+    c #25722E",
"%+ c #2B6F33",
"&+ c #69B371",
"*+ c #84D28C",
"=+ c #74C47D",
"-+ c #55AA5E",
";+ c #398E42",
">+ c #276E2F",
",+ c #1C5924",
"'+ c #15441B",
")+ c #22682B",
"!+ c #2E8438",
"~+ c #3D9D48",
"{+ c #3DA74A",
"]+ c #31913C",
"^+ c #1F5D26",
"/+ c #17441C",
"(+ c #246C2C",
"_+ c #010301",
":+ c #081A0B",
"<+ c #2B6E33",
"[+ c #65A96C",
"}+ c #96DC9F",
"|+ c #8ED997",
"1+ c #83D08B",
"2+ c #77C880",
"3+ c #6BBD74",
"4+ c #61B169",
"5+ c #52A95C",
"6+ c #4A9C52",
"7+ c #428F4B",
"8+ c #378840",
"9+ c #2C8136",
"0+ c #277931",
"a+ c #246F2D",
"b+ c #206328",
"c+ c #1E6026",
"d+ c #1E5F26",
"e+ c #0C250F",
"f+ c #1F6026",
"g+ c #236C2B",
"h+ c #246F2C",
"i+ c #287B31",
"j+ c #32873C",
"k+ c #3B8D44",
"l+ c #40984A",
"m+ c #46A451",
"n+ c #4FAB59",
"o+ c #56B561",
"p+ c #5DBF68",
"q+ c #64C56F",
"r+ c #5ABE65",
"s+ c #48A152",
"t+ c #327B3A",
"u+ c #16411B",
"v+ c #1B5322",
"w+ c #26722F",
"x+ c #206128",
"y+ c #1D5524",
"z+ c #3E7F45",
"A+ c #6AAC71",
"B+ c #84CB8C",
"C+ c #92D99B",
"D+ c #96DC9E",
"E+ c #95DC9D",
"F+ c #94DB9C",
"G+ c #92DB9B",
"H+ c #8FDA98",
"I+ c #8CD895",
"J+ c #8AD793",
"K+ c #88D692",
"L+ c #86D590",
"M+ c #86D48F",
"N+ c #82D38B",
"O+ c #7ED187",
"P+ c #52AE5C",
"Q+ c #0E2D11",
"R+ c #87A7B7",
"S+ c #287831",
"T+ c #78CF82",
"U+ c #79D083",
"V+ c #77D082",
"W+ c #76D081",
"X+ c #77D181",
"Y+ c #76D181",
"Z+ c #77D282",
"\`+    c #76D180",
" @ c #72CE7D",
".@ c #66C171",
"+@ c #53A35C",
"@@ c #317639",
"#@ c #194A1F",
"\$@    c #1B5221",
"%@ c #0E2C11",
"&@ c #020702",
"*@ c #1C5622",
"=@ c #1C5422",
"-@ c #18491E",
";@ c #296730",
">@ c #498D51",
",@ c #62A96A",
"'@ c #74C07C",
")@ c #80D089",
"!@ c #89D792",
"~@ c #8ED996",
"{@ c #8DD996",
"]@ c #8CD995",
"^@ c #8BD894",
"/@ c #8AD893",
"(@ c #89D892",
"_@ c #52A55B",
":@ c #23692B",
"<@ c #75D080",
"[@ c #7BD386",
"}@ c #7AD285",
"|@ c #79D284",
"1@ c #78D282",
"2@ c #70CF7B",
"3@ c #68C773",
"4@ c #5CB867",
"5@ c #4EA158",
"6@ c #3A8543",
"7@ c #226229",
"8@ c #16421B",
"9@ c #206227",
"0@ c #000100",
"a@ c #051005",
"b@ c #133D18",
"c@ c #206228",
"d@ c #18471D",
"e@ c #1A4D20",
"f@ c #24622B",
"g@ c #33803C",
"h@ c #46924F",
"i@ c #56A55F",
"j@ c #60B16A",
"k@ c #6ABC73",
"l@ c #7FD389",
"m@ c #85D68F",
"n@ c #84D68E",
"o@ c #45964E",
"p@ c #1F6127",
"q@ c #6ACB75",
"r@ c #75D180",
"s@ c #71CE7B",
"t@ c #4CA356",
"u@ c #3C8D45",
"v@ c #2C7B35",
"w@ c #215E28",
"x@ c #184A1F",
"y@ c #16441C",
"z@ c #16431B",
"A@ c #1A4F21",
"B@ c #123B17",
"C@ c #1D5924",
"D@ c #16431C",
"E@ c #68BF72",
"F@ c #80D58A",
"G@ c #7ED488",
"H@ c #338D3D",
"I@ c #1B5422",
"J@ c #61C16C",
"K@ c #6FCF7A",
"L@ c #67C772",
"M@ c #1A4E20",
"N@ c #1F6027",
"O@ c #000101",
"P@ c #15431A",
"Q@ c #216429",
"R@ c #63B96D",
"S@ c #7BD385",
"T@ c #78D182",
"U@ c #287932",
"V@ c #47778B",
"W@ c #184E1F",
"X@ c #56BB62",
"Y@ c #68CD74",
"Z@ c #60C36B",
"\`@    c #1C5623",
" # c #081909",
".# c #030B04",
"+# c #010201",
"@# c #0C2810",
"## c #22692A",
"\$#    c #5EB368",
"%# c #6ECD79",
"&# c #4CB358",
"*# c #62CB6E",
"=# c #57BF63",
"-# c #18491D",
";# c #25702E",
"># c #040D04",
",# c #57AD61",
"'# c #62C86E",
")# c #0E2D12",
"!# c #45AA50",
"~# c #5AC867",
"{# c #4EBB5A",
"]# c #17471D",
"^# c #020502",
"/# c #061608",
"(# c #216328",
"_# c #16401B",
":# c #4EA859",
"<# c #5ABF66",
"[# c #061408",
"}# c #030A03",
"|# c #3AA347",
"1# c #53C660",
"2# c #46B453",
"3# c #17461D",
"4# c #103213",
"5# c #236A2B",
"6# c #45A450",
"7# c #62CA6E",
"8# c #4FB95B",
"9# c #051207",
"0# c #33953F",
"a# c #4BC359",
"b# c #3FAD4C",
"c# c #1A5021",
"d# c #1E5D25",
"e# c #0C260F",
"f# c #3E9C49",
"g# c #46B253",
"h# c #2D8637",
"i# c #42C051",
"j# c #38A645",
"k# c #15411B",
"l# c #1E5C25",
"m# c #19501F",
"n# c #389343",
"o# c #52C560",
"p# c #3FA84B",
"q# c #0F2E12",
"r# c #297E33",
"s# c #3DB64B",
"t# c #349D40",
"u# c #133C18",
"v# c #328B3D",
"w# c #4AC358",
"x# c #37A144",
"y# c #081B0B",
"z# c #39AC47",
"A# c #30923C",
"B# c #153F1A",
"C# c #040C04",
"D# c #216428",
"E# c #2C8437",
"F# c #31923C",
"G# c #010502",
"H# c #36A142",
"I# c #2D8737",
"J# c #153E1A",
"K# c #287A32",
"L# c #3DB84C",
"M# c #2C8436",
"N# c #1E5E25",
"O# c #32973E",
"P# c #287B32",
"Q# c #143E19",
"R# c #17491D",
"S# c #3AAD48",
"T# c #184D1F",
"U# c #308F3B",
"V# c #216329",
"W# c #36A343",
"X# c #2D8838",
"Y# c #194D20",
"Z# c #33983F",
"\`#    c #113816",
" \$    c #1E5B25",
".\$    c #1A5220",
"+\$    c #308E3A",
"@\$    c #1B5121",
"#\$    c #143F18",
"\$\$   c #277530",
"%\$    c #DBDBDB",
"&\$    c #2A7F34",
"*\$    c #051206",
"=\$    c #1A5321",
"-\$    c #236B2C",
";\$    c #14411A",
">\$    c #26712F",
",\$    c #020703",
"'\$    c #1D5B25",
")\$    c #CBCBCB",
"!\$    c #26742F",
"~\$    c #16471C",
"{\$    c #2A8035",
"]\$    c #123916",
"^\$    c #1B5321",
"/\$    c #010101",
"(\$    c #EBEBEB",
"                                                                                                                                                ",
"                                                                        .                                                                       ",
"                                                                      + @                                                                       ",
"                                                                      # \$ %                                                                     ",
"                                                                      & * %                                                                     ",
"                                                                      = - ;                                                                     ",
"                                                                    > * , '                                                                     ",
"                                                                    > ) ! ~                                                                     ",
"                                                                    { ] ^ {                                                                     ",
"                                                                    / ( _ : <                                                                   ",
"                                                                    . [ } # |                                                                   ",
"                                                                    1 2 3 4 5                                                                   ",
"                                                                    6 7 8 9 0                                                                   ",
"                                                                    a b c d e                                                                   ",
"                                                                    \$ f g h i                                                                   ",
"                                                                    j k l m ;                                                                   ",
"                                                                  n o p q r s                                                                   ",
"                                                                  / t u v w ~                                                                   ",
"                                                                  { x y z A / B                                                                 ",
"                      / >                                         / C D E F : G                                       H / >                     ",
"                  . 4 I :                                         . J K L M N O                                       / P Q R {                 ",
"              H S T U / V                                         1 W X Y Z \`  .                                        { ..+.@.H               ",
"            . #.\$.%.&.|                                           *.=.D -.;.>.,.                                          ' '.).!.~.            ",
"          H {.].^./.(.                                            _.:.<.[.}.|.V                                             % 1.2., H           ",
"          3.4.5.H | 6.                                            7.8.y 9.0.a.%                                               s b.c.d.s         ",
"        . e.f.b.g.6.                                            . ^.h.i.j.k.l.'                                                 @ M A ~.        ",
"        1 m.n.o.p.                                              / a.q.r.s.t.u.'                                                 { v.w.x.y.      ",
"        # z.A.B.C.                                              . A D.E.F.G.H.~                                                 { I.0.J.g.      ",
"        '.K.L.M.N N.%                                         O.P.P.P.P.P.P.P.P.P.                                          / : Q.! J.R.V       ",
"        / r S.T.U.w V.W./ { {                                 O.X.X.X.X.X.X.X.X.P.                                / / / Y.Z.) \`. +.+++@+#+      ",
"        ~ 1.\$+%+&+*+=+-+;+>+,+'+4 *.R : H . / / . . . H H H   O.X.X.X.X.X.X.X.X.P.C.~ / H H . / / / H 1 : R *.& V.* )+!+~+{+]+^+/+(+d ' _+      ",
"          :+o.v.w.<+[+h.}+|+1+2+3+4+5+6+7+8+9+0+a+b+c+d+h Q.e+O.X.X.O.O.O.O.X.X.P.s d.c+c+f+g+h+i+5.j+k+l+m+n+o+p+q+r+s+t+G.u+v+++%.s (.        ",
"            % : * w+x+y+z+A+B+C+D+D+E+F+G+H+I+J+K+L+M+N+O+P+Q+O.R+R+P.P.O.O.R+R+P.' S+T+U+T+V+W+X+Y+X+Z+Z+\`+ @.@+@@@#@u+u+\$@A b+%@; &@6.        ",
"                ' e+*@a+Z =@-@;@>@,@'@)@!@~@|+{@{@]@^@/@(@_@R O.R+R+P.O.O.O.O.O.O.; :@<@[@}@|@1@\`+2@3@4@5@6@7@8@8@8@.+x+w 9@a s  .0@6.          ",
"                  a@; H b@c@I.:@J.#@d@e@f@g@h@i@j@k@l@m@n@o@> O.R+R+P.O.P.P.P.P.P.g.p@q@r@s@t@u@v@w@x@y@z@8@/+A@c@(++.#.@ '  ._+6.              ",
"                      G C.' : B@C@!.A w.=@d@/+/+D@D@E@F@G@H@s O.R+R+P.O.P.O.P.P.P.y.I@J@K@L@d./+D@D@y@M@N@I.Z - '+e+s y.| O@6.                  ",
"                            G ,.% ~ W.P@- I.A Q@y@z@R@S@T@U@' O.V@V@P.O.P.O.V@V@P.,.W@X@Y@Z@d D@\`@I.w a.j # >  #C..#+#6.                        ",
"                                    | C.; ~ @###M@8@\$#r@%#v.; O.V@V@P.P.P.O.V@V@P. .\` &#*#=#-#8@;#a { ' C.>#B 6.6.                              ",
"                                          _+g.R.C@u+,#K@'#b+V O.V@V@V@V@V@V@V@V@P.O )#!#~#{#]#8@(+&.^#6.6.                                      ",
"                                            /#'+(#_#:#Y@<#^.[#O.V@V@V@V@V@V@V@V@P.}#Y.|#1#2#/+3#+.' 0@                                          ",
"                                              4#5#Q 6#7#8#>.9#O.O.O.O.O.O.O.O.O.O.  / 0#a#b#D@c#d#g.6.                                          ",
"                                              e#I.Q f#~#g#V.5 O.P.P.P.P.P.P.P.P.O.  { h#i#j#k#l#m#C.                                            ",
"                                              . w Q n#o#p#q#>#O.X.X.X.X.X.X.X.X.O.  ~ r#s#t#Q w.u# .                                            ",
"                                              { 5#8@v#w#x#Y.G O.X.X.X.X.X.X.X.X.O.  y#w z#A#B#(+Q+C#                                            ",
"                                              { D#-@E#i#F#/ G#O.O.O.O.X.X.O.O.O.O.  s a.H#I#J#w : &@                                            ",
"                                              n ^.J.K#L#M#~ _+O.O.O.O.R+R+O.O.O.O.  ' N#O#P#Q#v.s +#                                            ",
"                                                R#c@a+S#^ s 0@O.O.O.O.R+R+O.O.O.O.  ' T#U#;#8@!.' 6.                                            ",
"                                                B.u.V#W#v.'   O.O.O.O.R+R+O.O.O.O.    9 X#T Y#N@g.                                              ",
"                                                1 M C@Z#Q@g.  O.O.O.O.V@V@O.O.O.O.    \`#2. \$ \$.\$C.                                              ",
"                                                / I.c#+\$h V   O.O.O.O.V@V@O.O.O.O.    N S+@\$Q@#\$#+                                              ",
"                                                { r M@h#d C.  O.O.O.O.V@V@O.O.O.O.    Y.\$\$-@a+e#.#                                              ",
"                                    %\$          { - @\$&\$V.*\$  O.O.O.O.O.O.O.O.O.O.    . ++u+(+. G#                                              ",
"                                    %\$          ~ =\$J.S+\`#p.  O.O.O.O.O.O.O.O.O.O.    / :@B#-\$~ +#              %\$                              ",
"                                  %\$%\$            ;\$b+>\$N .#  O.X.X.X.X.X.X.X.X.O.    { +.]#b+' 6.              %\$                              ",
"                                %\$%\$%\$            o.+.++~.,\$  O.X.X.X.X.X.X.X.X.O.    ~ 9@=@d#g.              %\$%\$                              ",
"                                %\$%\$              Y.u.-\$. _+  O.X.X.O.O.O.O.X.X.O.    { '\$Q@#.C.              %\$)\$                              ",
"                                %\$%\$              / 5#)+~ O@  O.R+R+O.O.O.O.R+R+O.    { * !\$B@ .              %\$)\$                              ",
"                                %\$                { u.v.'     O.R+R+O.O.O.O.O.O.O.      ~\${\$# |               %\$                                ",
"                                                  { p@r ;     O.R+R+O.O.O.O.O.O.O.      ]\$&\$1 ^#                                                ",
"                                                  { ^\$) g.    O.R+R+O.O.O.O.O.O.O.      )#! ~ /\$                                                ",
"                                                    b@* /#    O.V@V@O.O.O.O.V@V@O.      e#}.'                                                   ",
"                                                    N 9 C.    O.V@V@O.O.O.O.V@V@O.      : = g.                                                  ",
"                                                    1 R  .    O.V@V@V@V@V@V@V@V@O.      > e#y.                    %\$                            ",
"                                                      %       O.V@V@V@V@V@V@V@V@O.        '                 %\$%\$%\$%\$                            ",
"                            %\$                                O.O.O.O.O.O.O.O.O.O.                      %\$%\$%\$%\$%\$                              ",
"                            %\$%\$%\$                                    a I@V                             %\$                                      ",
"                            %\$%\$%\$%\$                                  '.b@C.                                                                    ",
"                                %\$%\$                              (\$(\$1 Y. .                                                                    ",
"                                %\$%\$                                (\$(\$i                                                                       ",
"                                  %\$%\$                                (\$(\$(\$                                                                    ",
"                                                                          (\$                                                                    ",
"                                                                                                                                                "};
_EOF_
}
