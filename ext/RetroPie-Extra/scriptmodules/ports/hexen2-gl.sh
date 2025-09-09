#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# RetroPie-Extra
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="hexen2-gl"
rp_module_desc="Hammer of Thyrion Source Port +GL"
rp_module_licence="GPL2 https://raw.githubusercontent.com/svn2github/uhexen2/master/docs/COPYING"
rp_module_repo="git https://github.com/jpernst/uhexen2-sdl2.git master"
rp_module_help="Place PAK Files in [ports/hexen2/*]:\n \n$romdir/ports/hexen2/data1/\npak0.pak\npak1.pak\nstrings.txt\n \n$romdir/ports/hexen2/portals/\npak3.pak\nstrings.txt\n \nRegistered PAK files must be patched to v1.11 for the Hammer of Thyrion Source Port."
rp_module_section="exp"
rp_module_flags=""

function depends_hexen2-gl() {
    # libsdl1.2-dev libsdl-net1.2-dev libsdl-sound1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev
    depends+=(cmake timidity freepats libmad0-dev libogg-dev libflac-dev libmpg123-dev libsdl2-dev libsdl2-mixer-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_hexen2-gl() {
    gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/HexenII_64x64.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/HexenII_70x70.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/HexenIIPortal_64x64.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/HexenIIPraevus_70x70.xpm" "$md_build"
}

function build_hexen2-gl() {
    cd "$md_build/engine/hexen2"
    ./build_all.sh
    md_ret_require=(
        "$md_build/engine/hexen2/glhexen2"
    )
}

function install_hexen2-gl() {
    md_ret_files=(
       'engine/hexen2/glhexen2'
       'engine/resource/hexen2.ico'
       'engine/resource/h2mp.ico'
       'engine/resource/hexen2.icns'
       'engine/resource/hexenworld.ico'
       'HexenII_64x64.xpm'
       'HexenII_70x70.xpm'
       'HexenIIPortal_64x64.xpm'
       'HexenIIPraevus_70x70.xpm'
    )
}

function game_data_hexen2-gl() {
    if [[ ! -f "$romdir/ports/hexen2/data1/pak0.pak" ]]; then
        downloadAndExtract "https://netix.dl.sourceforge.net/project/uhexen2/Hexen2Demo-Nov.1997/hexen2demo_nov1997-linux-i586.tgz" "$romdir/ports/hexen2" --strip-components 1 "hexen2demo_nov1997/data1"
        chown -R "$__user":"$__user" "$romdir/ports/hexen2/data1"
    fi
}

function remove_hexen2-gl() {
    if [[ -f "/usr/share/applications/HeXen II.desktop" ]]; then sudo rm -f "/usr/share/applications/HeXen II.desktop"; fi
    if [[ -f "$home/Desktop/HeXen II.desktop" ]]; then rm -f "$home/Desktop/HeXen II.desktop"; fi
    if [[ -f "/usr/share/applications/HeXen II Portal Of Praevus.desktop" ]]; then sudo rm -f "/usr/share/applications/HeXen II Portal Of Praevus.desktop"; fi
    if [[ -f "$home/Desktop/HeXen II Portal Of Praevus.desktop" ]]; then rm -f "$home/Desktop/HeXen II Portal Of Praevus.desktop"; fi
}

function configure_hexen2-gl() {
    mkRomDir "ports/hexen2/data1"
    mkRomDir "ports/hexen2/portals"
    moveConfigDir "$home/.hexen2" "$romdir/ports/hexen2"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addPort "$md_id" "hexen2" "Hexen II" "$launch_prefix$md_inst/glhexen2 -f -conwidth 800"
    addPort "$md_id" "hexen2p" "Hexen II Portal Of Praevus" "$launch_prefix$md_inst/glhexen2 -f -conwidth 800 -portals"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "hexen2" "Hexen II" "$launch_prefix$md_inst/hexen2-qjoy.sh"
        addPort "$md_id+qjoypad" "hexen2p" "Hexen II Portal Of Praevus" "$launch_prefix$md_inst/hexen2-qjoy.sh -portals"
    fi

    cat >"$md_inst/data1.config.cfg" << _EOF_
unbindall
bind "TAB" "+showinfo"
bind "ENTER" "invuse"
bind "ESCAPE" "togglemenu"
bind "SPACE" "+crouch"
bind "'" "zoom_in"
bind "+" "sizeup"
bind "," "+moveleft"
bind "-" "impulse 12"
bind "." "+moveright"
bind "/" "+jump"
bind "0" "impulse 0"
bind "1" "impulse 1"
bind "2" "impulse 2"
bind "3" "impulse 3"
bind "4" "impulse 4"
bind "5" "impulse 5"
bind "6" "impulse 6"
bind "7" "impulse 7"
bind "8" "impulse 8"
bind "=" "impulse 10"
bind "[" "invleft"
bind "\" "impulse 44"
bind "]" "invright"
bind "\`" "toggleconsole"
bind "a" "+lookup"
bind "c" "+movedown"
bind "d" "+moveup"
bind "q" "+showdm"
bind "t" "messagemode"
bind "z" "+lookdown"
bind "~" "toggleconsole"
bind "UPARROW" "+forward"
bind "DOWNARROW" "+back"
bind "LEFTARROW" "+left"
bind "RIGHTARROW" "+right"
bind "ALT" "+strafe"
bind "CTRL" "+attack"
bind "SHIFT" "+speed"
bind "F1" "help"
bind "F2" "menu_save"
bind "F3" "menu_load"
bind "F4" "menu_options"
bind "F5" "menu_multiplayer"
bind "F6" "echo Quicksaving...; wait; save quick"
bind "F7" "demos"
bind "F9" "echo Quickloading...; wait; load quick"
bind "F10" "quit"
bind "F11" "zoom_in"
bind "F12" "screenshot"
bind "DEL" "+lookdown"
bind "PGDN" "+lookup"
bind "END" "centerview"
bind "MOUSE1" "+attack"
bind "MOUSE2" "+forward"
bind "PAUSE" "pause"
joystick "0"
cfg_unbindall "1"
m_side "0.8"
m_forward "1"
m_yaw "0.022"
m_pitch "0.022"
mwheelthreshold "120"
sensitivity "3"
lookstrafe "0"
lookspring "0"
cl_backspeed "400"
cl_forwardspeed "400"
_cl_playerclass "4"
_cl_color "0"
_cl_name "player"
bgm_extmusic "1"
_snd_mixahead "0.1"
bgm_mutedvol "0"
bgmvolume "1"
sfx_mutedvol "0"
volume "0.7"
bgmtype "cd"
dmtrans "0"
sbtrans "0"
dm_mode "1"
snow_active "1"
snow_flurry "1"
leak_color "251"
gl_extra_dynamic_lights "0"
gl_colored_dynamic_lights "0"
gl_coloredlight "0"
gl_other_glows "0"
gl_missile_glows "1"
gl_glows "0"
gl_keeptjunctions "1"
gl_purge_maptex "1"
gl_zfix "1"
gl_ztrick "0"
gl_waterripple "2"
r_texture_external "0"
r_wholeframe "1"
r_skyalpha "0.67"
r_wateralpha "0.33"
r_shadows "0"
r_waterwarp "0"
contrans "0"
viewsize "110"
fov_adapt "1"
gl_texture_anisotropy "1"
gl_texturemode "GL_LINEAR_MIPMAP_NEAREST"
gl_constretch "0"
gl_multitexture "0"
gl_lightmapfmt "GL_RGBA"
gl_texture_NPOT "0"
_enable_mouse "1"
vid_config_consize "800"
vid_config_glx "1920"
vid_config_gly "1080"
vid_config_swx "640"
vid_config_swy "480"
vid_config_fscr "1"
vid_config_fsaa "0"
vid_config_gl8bit "0"
gamma "0.75"
crosshaircolor "75"
cl_crossy "0"
cl_crossx "0"
crosshair "1"
net_allowmultiple "0"
external_ents "1"
saved4 "0"
saved3 "0"
saved2 "0"
saved1 "0"
savedgamecfg "0"
max_temp_edicts "30"
sys_adaptive "1"
sys_throttle "0.02"
developer "0"
sv_ce_max_size "0"
sv_ce_scale "0"
sv_update_misc "1"
sv_update_missiles "1"
sv_update_monsters "1"
sv_update_player "1"
sv_altnoclip "1"
_EOF_
    cp "$md_inst/data1.config.cfg" "$md_inst/portals.config.cfg"
    sed -i s+_cl_playerclass.*+_cl_playerclass\ \"5\"+ "$md_inst/portals.config.cfg"
    if [[ ! -f "$romdir/ports/hexen2/data1/config.cfg" ]]; then cp "$md_inst/data1.config.cfg" "$romdir/ports/hexen2/data1/config.cfg"; fi
    if [[ ! -f "$romdir/ports/hexen2/portals/config.cfg" ]]; then cp "$md_inst/portals.config.cfg" "$romdir/ports/hexen2/portals/config.cfg"; fi
    chown -R $__user:$__user "$romdir/ports/hexen2"

   cat >"$md_inst/hexen2-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Hexen II"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
    Axis 1: gradient, dZone 5538, xZone 29536, +key 60, -key 59
    Axis 2: dZone 9230, xZone 28382, +key 116, -key 111
    Axis 3: gradient, +key 65, -key 0
    Axis 4: gradient, dZone 5307, xZone 28382, maxSpeed 18, mouse+h
    Axis 5: dZone 8768, +key 52, -key 38
    Axis 6: gradient, throttle+, +key 105, -key 0
    Axis 7: +key 35, -key 34
    Axis 8: +key 36, -key 23
    Button 1: key 61
    Button 2: key 115
    Button 3: key 65
    Button 4: key 50
    Button 5: key 20
    Button 6: key 21
    Button 7: key 9
    Button 8: key 36
    Button 9: key 29
    Button 10: key 50
    Button 11: key 115
    Button 12: key 34
    Button 13: key 35
    Button 14: key 23
    Button 15: key 36
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run Hexen II
if [[ "\$1" == 'portals' ]]; then
    /opt/retropie/ports/hexen2/glhexen2 -f -conwidth 800 -portals
else
    /opt/retropie/ports/hexen2/glhexen2 -f -conwidth 800
fi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/hexen2-qjoy.sh"

    cat >"$md_inst/HeXen II.desktop" << _EOF_
[Desktop Entry]
Name=HeXen II
GenericName=HeXen II
Comment=HeXen II
Exec=$md_inst/glhexen2 -f -conwidth 800
Icon=$md_inst/HexenII_70x70.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=HX2;HeXenII
StartupWMClass=HeXenII
Name[en_US]=HeXen II
_EOF_
    chmod 755 "$md_inst/HeXen II.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/HeXen II.desktop" "$home/Desktop/HeXen II.desktop"; chown $__user:$__user "$home/Desktop/HeXen II.desktop"; fi
    mv "$md_inst/HeXen II.desktop" "/usr/share/applications/HeXen II.desktop"

    cat >"$md_inst/HeXen II Portal Of Praevus.desktop" << _EOF_
[Desktop Entry]
Name=HeXen II Portal Of Praevus
GenericName=HeXen II Portal Of Praevus
Comment=HeXen II Portal Of Praevus
Exec=$md_inst/glhexen2 -f -conwidth 800 -portals
Icon=$md_inst/HexenIIPraevus_70x70.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=HX2P;HeXenIIPortal
StartupWMClass=HeXenIIPortal
Name[en_US]=HeXen II Portal Of Praevus
_EOF_
    chmod 755 "$md_inst/HeXen II Portal Of Praevus.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/HeXen II Portal Of Praevus.desktop" "$home/Desktop/HeXen II Portal Of Praevus.desktop"; chown $__user:$__user "$home/Desktop/HeXen II Portal Of Praevus.desktop"; fi
    mv "$md_inst/HeXen II Portal Of Praevus.desktop" "/usr/share/applications/HeXen II Portal Of Praevus.desktop"

    [[ "$md_mode" == "install" ]] && game_data_hexen2-gl
    [[ "$md_mode" == "remove" ]] && remove_hexen2-gl
}
