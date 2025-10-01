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
rp_module_help="Place PAK Files in [ports/hexen2/*]:\n \n$romdir/ports/hexen2/data1/\npak0.pak\npak1.pak\nstrings.txt\n \n$romdir/ports/hexen2/portals/\npak3.pak\nstrings.txt\n \nRegistered PAK files must be patched to v1.11 for the Hammer of Thyrion Source Port.

  Corresponding MIDI names for CD Audio tracks

   HeXen II [data1/music]:
   track02  ->  casa1      track10  ->  meso2
   track03  ->  casa2      track11  ->  meso3
   track04  ->  casa3      track12  ->  roma1
   track05  ->  casa4      track13  ->  roma2
   track06  ->  egyp1      track14  ->  roma3
   track07  ->  egyp2      track15  ->  casb1
   track08  ->  egyp3      track16  ->  casb2
   track09  ->  meso1      track17  ->  casb3

   Portal Of Praevus [portals/music]:
   track02  ->  tulku7     track07  ->  tulku10
   track03  ->  tulku1     track08  ->  tulku6
   track04  ->  tulku4     track09  ->  tulku5
   track05  ->  tulku2     track10  ->  tulku8
   track06  ->  tulku9     track11  ->  tulku3

Track12 not associated to anything and can be left as is
The Remaining Audio Tracks can be Copied/Pasted/Renamed

   Portal Of Praevus [portals/music]:
   tulku7 -> casa1     tulku2 -> casa4
   tulku1 -> casa2     tulku9 -> casb1
   tulku4 -> casa3"
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
    )
}

function game_data_hexen2-gl() {
    if [[ ! -f "$romdir/ports/hexen2/data1/pak0.pak" ]]; then
        downloadAndExtract "https://netix.dl.sourceforge.net/project/uhexen2/Hexen2Demo-Nov.1997/hexen2demo_nov1997-linux-i586.tgz" "$romdir/ports/hexen2" --strip-components 1 "hexen2demo_nov1997/data1"
        chown -R "$__user":"$__user" "$romdir/ports/hexen2/data1"
    fi
}

function remove_hexen2-gl() {
    local shortcut_name
    shortcut_name="HeXen II"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"

    shortcut_name="HeXen II Portal Of Praevus"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
}

function configure_hexen2-gl() {
    mkRomDir "ports/hexen2/data1"
    mkRomDir "ports/hexen2/portals"
    chown -R $__user:$__user "$romdir/ports/hexen2"

    moveConfigDir "$home/.hexen2" "$romdir/ports/hexen2"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addPort "$md_id" "hexen2" "Hexen II" "$launch_prefix$md_inst/glhexen2 -f -conwidth 800"
    addPort "$md_id" "hexen2p" "Hexen II Portal Of Praevus" "$launch_prefix$md_inst/glhexen2 -f -conwidth 800 -portals"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "hexen2" "Hexen II" "$launch_prefix$md_inst/$md_id-qjoy.sh"
        addPort "$md_id+qjoypad" "hexen2p" "Hexen II Portal Of Praevus" "$launch_prefix$md_inst/$md_id-qjoy.sh -portals"
    fi

    # Unknown Commands in hexen2-gl: sys_delay "0" r_transwater "1" _windowed_mouse "0" vid_stretch_by_2 "1" vid_config_y "600" vid_config_x "800" _vid_default_mode_win "3" _vid_default_mode "0" _vid_wait_override "0" vid_nopageflip "0" sys_quake2 "1"
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
bind "\\" "impulse 44"
bind "]" "invright"
bind "\`" "toggleconsole"
bind "a" "+lookup"
bind "c" "+movedown"
bind "d" "+moveup"
bind "q" "+showdm"
bind "t" "messagemode"
bind "y" "+infoplaque"
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
bind "MOUSE3" "+back"
bind "MWHEELUP" "impulse 10"
bind "MWHEELDOWN" "+jump"
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
_cl_name "Corvus"
bgm_extmusic "1"
_snd_mixahead "0.1"
bgm_mutedvol "0"
bgmvolume "1"
sfx_mutedvol "0"
volume "0.4"
bgmtype "midi"
dmtrans "0"
sbtrans "0"
dm_mode "1"
snow_active "1"
snow_flurry "1"
leak_color "251"
gl_extra_dynamic_lights "1"
gl_colored_dynamic_lights "1"
gl_coloredlight "1"
gl_other_glows "1"
gl_missile_glows "0"
gl_glows "1"
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
viewsize "100"
fov_adapt "1"
gl_texture_anisotropy "1"
gl_texturemode "GL_NEAREST_MIPMAP_LINEAR"
gl_constretch "1"
gl_multitexture "1"
gl_lightmapfmt "gl_rgba"
gl_texture_NPOT "1"
_enable_mouse "1"
vid_config_consize "800"
vid_config_glx "1920"
vid_config_gly "1080"
vid_config_swx "640"
vid_config_swy "480"
vid_config_fscr "1"
vid_config_fsaa "0"
vid_config_gl8bit "0"
gamma "0.8"
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
sv_ce_max_size "5"
sv_ce_scale "5"
sv_update_misc "1"
sv_update_missiles "1"
sv_update_monsters "1"
sv_update_player "1"
sv_altnoclip "1"
+mlook
_EOF_
    if (isPlatform "rpi3") || (isPlatform "rpi4"); then
        sed -i s+gl_extra_dynamic_lights.*+gl_extra_dynamic_lights\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_colored_dynamic_lights.*+gl_colored_dynamic_lights\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_coloredlight.*+gl_coloredlight\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_other_glows.*+gl_other_glows\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_glows.*+gl_glows\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_texturemode.*+gl_texturemode\ \"GL_NEAREST_MIPMAP_NEAREST\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_lightmapfmt.*+gl_lightmapfmt\ \"gl_luminance\"+ "$md_inst/data1.config.cfg"
        sed -i s+gl_texture_NPOT.*+gl_texture_NPOT\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+snow_active.*+snow_active\ \"0\"+ "$md_inst/data1.config.cfg"
        sed -i s+snow_flurry.*+snow_flurry\ \"0\"+ "$md_inst/data1.config.cfg"
    fi
    if (isPlatform "rpi3"); then
        sed -i s+vid_config_consize.*+vid_config_consize\ \"640\"+ "$md_inst/data1.config.cfg"
        sed -i s+vid_config_glx.*+vid_config_glx\ \"640\"+ "$md_inst/data1.config.cfg"
        sed -i s+vid_config_gly.*+vid_config_gly\ \"480\"+ "$md_inst/data1.config.cfg"
        sed -i s+vid_config_swx.*+vid_config_swx\ \"320\"+ "$md_inst/data1.config.cfg"
        sed -i s+vid_config_swy.*+vid_config_swy\ \"200\"+ "$md_inst/data1.config.cfg"
        sed -i s+vid_config_gl8bit.*+vid_config_gl8bit\ \"1\"+ "$md_inst/data1.config.cfg"
    fi

    cp "$md_inst/data1.config.cfg" "$md_inst/portals.config.cfg"
    sed -i s+_cl_playerclass.*+_cl_playerclass\ \"5\"+ "$md_inst/portals.config.cfg"
    if [[ ! -f "$romdir/ports/hexen2/data1/config.cfg" ]]; then cp "$md_inst/data1.config.cfg" "$romdir/ports/hexen2/data1/config.cfg"; fi
    if [[ ! -f "$romdir/ports/hexen2/portals/config.cfg" ]]; then cp "$md_inst/portals.config.cfg" "$romdir/ports/hexen2/portals/config.cfg"; fi
    chown -R $__user:$__user "$romdir/ports/hexen2"

   cat >"$md_inst/$md_id-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="HeXen II"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
    Axis 1: gradient, dZone 5538, xZone 29536, +key 60, -key 59
    Axis 2: dZone 9230, xZone 28382, +key 116, -key 111
    Axis 3: gradient, +key 50, -key 0
    Axis 4: gradient, dZone 5307, xZone 28382, maxSpeed 18, mouse+h
    Axis 5: dZone 8768, +key 52, -key 38
    Axis 6: gradient, +key 105, -key 0
    Axis 7: +key 35, -key 34
    Axis 8: +key 36, -key 23
    Button 1: key 61
    Button 2: key 36
    Button 3: key 65
    Button 4: key 29
    Button 5: key 20
    Button 6: key 21
    Button 7: key 9
    Button 8: key 127
    Button 9: key 49
    Button 10: key 65
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
    $md_inst/glhexen2 -f -conwidth 800 -portals
else
    $md_inst/glhexen2 -f -conwidth 800
fi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/$md_id-qjoy.sh"

    [[ "$md_mode" == "remove" ]] && remove_hexen2-gl
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && game_data_hexen2-gl
    [[ "$md_mode" == "install" ]] && shortcuts_icons_hexen2-gl
}

function shortcuts_icons_hexen2-gl() {
    local shortcut_name
    shortcut_name="HeXen II"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/glhexen2 -f -conwidth 800
Icon=$md_inst/HexenII_70x70.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=HX2;HeXenII
StartupWMClass=HeXenII
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    mv "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"

    shortcut_name="HeXen II Portal Of Praevus"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/glhexen2 -f -conwidth 800 -portals
Icon=$md_inst/HexenIIPraevus_70x70.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=HX2P;HeXenIIPortal
StartupWMClass=HeXenIIPortalPraevus
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    mv "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/HexenII_70x70.xpm" << _EOF_
/* XPM */
static char * HexenII_70x70_xpm[] = {
"70 70 338 2",
"   c None",
".  c #840000",
"+  c #420000",
"@  c #400000",
"#  c #C20000",
"$  c #350000",
"%  c #1A0000",
"&  c #460000",
"*  c #C40000",
"=  c #AB0000",
"-  c #E40000",
";  c #9A0000",
">  c #4D0000",
",  c #000000",
"'  c #550000",
")  c #FB0000",
"!  c #BF0000",
"~  c #190000",
"{  c #E70000",
"]  c #4F0000",
"^  c #020000",
"/  c #290000",
"(  c #300000",
"_  c #6D0000",
":  c #F50000",
"<  c #360000",
"[  c #410000",
"}  c #FA0000",
"|  c #3F0000",
"1  c #7C0000",
"2  c #770000",
"3  c #480000",
"4  c #DA0000",
"5  c #3E0000",
"6  c #120000",
"7  c #900000",
"8  c #850000",
"9  c #210000",
"0  c #720000",
"a  c #CC0000",
"b  c #180000",
"c  c #930000",
"d  c #FF0000",
"e  c #530000",
"f  c #540000",
"g  c #D70000",
"h  c #270000",
"i  c #1D0000",
"j  c #C10000",
"k  c #440000",
"l  c #2C0000",
"m  c #D80000",
"n  c #4B0000",
"o  c #A10000",
"p  c #8F0000",
"q  c #0B0000",
"r  c #740000",
"s  c #D00000",
"t  c #1B0000",
"u  c #340000",
"v  c #220000",
"w  c #6B0000",
"x  c #430000",
"y  c #9D0000",
"z  c #1F0000",
"A  c #6E0000",
"B  c #6A0000",
"C  c #660000",
"D  c #650000",
"E  c #820000",
"F  c #BC0000",
"G  c #890000",
"H  c #BA0000",
"I  c #C00000",
"J  c #9B0000",
"K  c #E90000",
"L  c #2F0000",
"M  c #040000",
"N  c #7A0000",
"O  c #970000",
"P  c #E00000",
"Q  c #380000",
"R  c #390000",
"S  c #ED0000",
"T  c #3B0000",
"U  c #C90000",
"V  c #2D0000",
"W  c #580000",
"X  c #DF0000",
"Y  c #A40000",
"Z  c #C60000",
"\`  c #8D0000",
" . c #010000",
".. c #E10000",
"+. c #7D0000",
"@. c #130000",
"#. c #510000",
"$. c #FD0000",
"%. c #F80000",
"&. c #9E0000",
"*. c #5B0000",
"=. c #940000",
"-. c #830000",
";. c #640000",
">. c #F70000",
",. c #2E0000",
"'. c #B40000",
"). c #EB0000",
"!. c #320000",
"~. c #810000",
"{. c #D10000",
"]. c #E50000",
"^. c #FE0000",
"/. c #690000",
"(. c #950000",
"_. c #070000",
":. c #A20000",
"<. c #730000",
"[. c #310000",
"}. c #090000",
"|. c #3C0000",
"1. c #D50000",
"2. c #AD0000",
"3. c #260000",
"4. c #C30000",
"5. c #CB0000",
"6. c #E80000",
"7. c #F90000",
"8. c #490000",
"9. c #DC0000",
"0. c #330000",
"a. c #B90000",
"b. c #610000",
"c. c #620000",
"d. c #F20000",
"e. c #C70000",
"f. c #230000",
"g. c #4A0000",
"h. c #AF0000",
"i. c #570000",
"j. c #F40000",
"k. c #E60000",
"l. c #370000",
"m. c #880000",
"n. c #A90000",
"o. c #630000",
"p. c #EF0000",
"q. c #5D0000",
"r. c #AA0000",
"s. c #0A0000",
"t. c #030000",
"u. c #8C0000",
"v. c #BE0000",
"w. c #DD0000",
"x. c #BB0000",
"y. c #1E0000",
"z. c #B80000",
"A. c #B50000",
"B. c #2B0000",
"C. c #DB0000",
"D. c #910000",
"E. c #780000",
"F. c #CA0000",
"G. c #520000",
"H. c #E20000",
"I. c #150400",
"J. c #710000",
"K. c #CE0000",
"L. c #7F0000",
"M. c #960000",
"N. c #E30000",
"O. c #0B0200",
"P. c #5C1200",
"Q. c #4B0F00",
"R. c #C80000",
"S. c #4C0E00",
"T. c #140400",
"U. c #E52C00",
"V. c #490E00",
"W. c #D90000",
"X. c #250000",
"Y. c #8F1C00",
"Z. c #1E0500",
"\`. c #861A00",
" + c #FF3200",
".+ c #460E00",
"++ c #1C0000",
"@+ c #200000",
"#+ c #981E00",
"$+ c #6E1500",
"%+ c #CD2800",
"&+ c #450D00",
"*+ c #B60000",
"=+ c #0E0000",
"-+ c #9D1F00",
";+ c #C02500",
">+ c #1F0600",
",+ c #430D00",
"'+ c #670000",
")+ c #5F0000",
"!+ c #160000",
"~+ c #A22000",
"{+ c #2E0900",
"]+ c #360B00",
"^+ c #400C00",
"/+ c #9C0000",
"(+ c #080000",
"_+ c #A82100",
":+ c #661400",
"<+ c #480E00",
"[+ c #3E0C00",
"}+ c #AE2200",
"|+ c #551100",
"1+ c #571100",
"2+ c #3C0B00",
"3+ c #8E0000",
"4+ c #DE0000",
"5+ c #AC0000",
"6+ c #B42300",
"7+ c #3F0C00",
"8+ c #641300",
"9+ c #3A0B00",
"0+ c #AE0000",
"a+ c #CD0000",
"b+ c #B92500",
"c+ c #280800",
"d+ c #631300",
"e+ c #380B00",
"f+ c #790000",
"g+ c #060000",
"h+ c #BD2600",
"i+ c #130400",
"j+ c #5E1200",
"k+ c #EA0000",
"l+ c #A50000",
"m+ c #D60000",
"n+ c #9F0000",
"o+ c #4E0000",
"p+ c #C32700",
"q+ c #E72D00",
"r+ c #581200",
"s+ c #340B00",
"t+ c #3D0000",
"u+ c #EC0000",
"v+ c #3A0000",
"w+ c #2A0000",
"x+ c #EE0000",
"y+ c #C52700",
"z+ c #C82700",
"A+ c #531000",
"B+ c #310A00",
"C+ c #8A0000",
"D+ c #F10000",
"E+ c #FC0000",
"F+ c #F00000",
"G+ c #C12700",
"H+ c #B22200",
"I+ c #4D0F00",
"J+ c #1A0500",
"K+ c #A70000",
"L+ c #A60000",
"M+ c #BD2500",
"N+ c #9A1E00",
"O+ c #470E00",
"P+ c #D62A00",
"Q+ c #450000",
"R+ c #240000",
"S+ c #B82400",
"T+ c #841900",
"U+ c #420D00",
"V+ c #A92100",
"W+ c #4C0000",
"X+ c #F60000",
"Y+ c #D30000",
"Z+ c #B22300",
"\`+ c #6D1500",
" @ c #3B0B00",
".@ c #7F1900",
"+@ c #110000",
"@@ c #280000",
"#@ c #B00000",
"\$@ c #BD0000",
"%@ c #140000",
"&@ c #AF2200",
"*@ c #581100",
"=@ c #370A00",
"-@ c #561100",
";@ c #590000",
">@ c #680000",
",@ c #AA2100",
"'@ c #410C00",
")@ c #320A00",
"!@ c #170000",
"~@ c #6F0000",
"{@ c #100000",
"]@ c #A80000",
"^@ c #A52000",
"/@ c #2A0800",
"(@ c #2B0900",
"_@ c #F12F00",
":@ c #070200",
"<@ c #A00000",
"[@ c #0D0000",
"}@ c #050000",
"|@ c #800000",
"1@ c #0F0000",
"2@ c #A01F00",
"3@ c #270800",
"4@ c #5E0000",
"5@ c #750000",
"6@ c #7B1900",
"7@ c #210600",
"8@ c #961D00",
"9@ c #D40000",
"0@ c #470000",
"a@ c #470D00",
"b@ c #1C0500",
"c@ c #5A0000",
"d@ c #180500",
"e@ c #170400",
"f@ c #F30000",
"g@ c #600000",
"h@ c #120300",
"i@ c #180400",
"j@ c #6C0000",
"k@ c #B10000",
"l@ c #990000",
"m@ c #040100",
"n@ c #CF0000",
"o@ c #0C0000",
"p@ c #8B0000",
"q@ c #560000",
"r@ c #7E0000",
"s@ c #B20000",
"t@ c #C50000",
"u@ c #7B0000",
"v@ c #B30000",
"w@ c #5C0000",
"                                                                                                                                            ",
"                                                                                                                                            ",
"                                    . +                                                                                                     ",
"                                    @ # $ % +                                                                                               ",
"                                      & * = - ; > ,                                                                                         ",
"                                        ' ) ! ~ { ] ^                                                                             /         ",
"                                      (   _ : < [ } | ,                                                                         1 2         ",
"                                    3 4 5 6 7 8 9 0 a b ,                                                                     c d e ,       ",
"                                  f { d g h i j k l m n ,                                                                   o d p q ,       ",
"                              r s d d d d = t u a v w x ,                                                                 y d # z ,         ",
"                            3 A B C D C E F F G d H I < ,                                                               J d K L , ,         ",
"                                          M N d d d d L ,                                                             O d P Q , ,           ",
"                                            R S d d d T ,                                                         k = d U V , ,             ",
"                                              _ d d d W , ,                                                     k X d Y 9 , ,               ",
"                                                Z d d \`  .,                                                   & ..d +.@., ,                 ",
"                                                #.$.d %.L ,                                                 ] { d d &.*.l ,                 ",
"                                          5       =.d d -. .,                                             ;.>.d d d d S ,.,                 ",
"                                          &.'.b   R ).d %.!.,                                           ~.d {.].d ^.= u , ,                 ",
"                                            '.C ,   /.d d (._.,                                   v v :.d * a %.<.[.}.,                     ",
"                                            |.1.k , t 2.d ^.[ ,                               Q 3.i 4.d 5.6.7.#.M ,                         ",
"                                              8.9.0., u K d a.6 ,                           b.c.h ..d 5.d d.x , ,                           ",
"                                                b.e.f., g.} d e ,                       k h.i.R j.d.5.6.k.l., ,                             ",
"                                                  m.n.i , o.d 9.z ,                   <.p.@ q.^.X 5.d 9.,., ,                               ",
"                                                    :.r.i s.\` d 0 t.              + ! d.$ u.d v.X d w.l , ,                                 ",
"                                                      x.= y.0.d ) + ,           n w.K 0.z.d.v.d d X V , , , ,                   ,           ",
"                                                      5 s A.u p.p.{ B.,       *.d.C.|.C.X 5.d d P ,., , , , , ,                 , ,         ",
"                                                        < D.d p.p.d H % ,   E.$.F.G.d.9.{.d d H.L , ,   , , , ,               , I.,         ",
"                                                            J.d K.K.d L.z M.d H r $.5.v.].d N.( , ,     , O., , ,           , P.Q.,         ",
"                                                              o d 5.d.d X d A.y d R.v.d d C.L , ,       , S., , ,           T.U.V.,         ",
"                                                              b.d d.5.d d d 7.d d.W.X d F X., ,         , Y.Z., ,         , \`. +.+,         ",
"                                                              3 ^.d X X d d d X 5.d d J ++, @+          , #+$+, ,         , %+ +&+,         ",
"                                                                *+d d v.d d d X d d N @.=+C '           , -+;+, , ,       >+ + +,+,         ",
"                                                                '+d d X X X X d d )+}.f.&.c !+,         , ~+ +{+, ,       ]+ + +^+,         ",
"                                                                x d d d.Z K.d d /+(+l.1.7 t ,           , _+ +:+, ,       <+ + +[+,         ",
"                                                                *.d d 5.X v.d d !.f.{ E.6 ,             , }+ +|+, ,       1+ + +2+,         ",
"                                                            3+4+S '+. ^.d X X d J.5+)+(+,               , 6+ +7+, ,       8+ + +9+,         ",
"                                                        5 0+d a+,.% 2 ^.d X X d d q.M ,                 , b+ +c+, ,       d+ + +e+,         ",
"                                                      x K.d v.h q h.d 6.d d 5.d.f+g+,                   , h+ +i+, ,       j+ + +]+,         ",
"                                                    e k+d l+@+, & d m+f.n+d X X o+, ,                   , p+q+ ., ,       r+ + +s+,         ",
"                                                  A ) $.0 @., t+u+: v+, w+x+d.5.n+i &                   , y+z+, , ,       A+ + +B+,         ",
"                                                C+d D+g.M , + p.E+' , }.W F+d d d {.m.                  , G+H+, , ,       I+ + +J+,         ",
"                                              K+d w.< , , & D+j.> t.v \` ! 3.L+d d p.z ,                 , M+N+, ,         O+ +P+, ,         ",
"                                          Q+# d v.w+, , n j.k.5 , h 4.m+( , R+* d d ' ,                 , S+T+, ,         U+ +V+, ,         ",
"                                        W+C.d J y., , ] X+Y+[., f.H F.( , ,   T a d \` ,                 , Z+\`+, ,          @ +.@, ,         ",
"                                      1 %.d E.+@, ^ ' %.a.@@, v #@2.@@, ,       Q \$@H.%@,               , &@*@, ,         =@ +-@, ,         ",
"                                  k 4 d 7.;@_., q >@E+n+y., y.l+u.++,             l.>.& ,               , ,@'@, ,         )@ +{+, ,         ",
"                                T { d D+x , , !@-.d G %@, l n.~@{@,                 ]@X h ,             , ^@/@, ,         (@_@:@,           ",
"                                  u.p.| , , X.<@^.0 [@, v+R.e }@,                   |@d o 1@,           , 2@T., ,         3@;+, ,           ",
"                                > 4+| , , ,.a.) 4@}@t.] 1.| , ,                     5@d d C  .          , 6@ .,           7@8@, ,           ",
"                              G.4 5 , , Q Y+j.o+ .+@_ 9@u , ,                       0@^.&.} Q+,         , a@, ,           b@\`+, ,           ",
"                            c@C.v+, , + k.k+[ , @+(.* V , ,                           m+&.~@k+[.,       , d@, ,           e@,+, ,           ",
"                          o.C.l., , 8.f@Y+< , L v.#@h ,                               g@$.++z.Z 9 ,     , , , ,           h@i@,             ",
"                        j@1.0., , g.j.k@/ , | X ; ++,                                   5+5.b ).l@{@,   , , , ,           m@, ,             ",
"                      2 n@( q , 8.: u.% g+i.: . @.,                                     x p.n 8.d C ,   , , ,             , , ,             ",
"                    . R.V y.2 [ D+C [@@.f+$.~@o@,                                         | h }.p@: l., , , ,             , , ,             ",
"                  7 v.w+, W $.).3  .R+o d.q@g+,                                                 ( g A.%@, ,               , ,               ",
"                /+A.@@, ++5.x+| , 0.R.# $ , ,                                                     > ) c., ,               , ,               ",
"              K+= R+, i p@k+|., k k.|@y.,                                                           r@d.0.,                                 ",
"            s@:.9 , V s@- Q t.*.C.> M ,                                                               t@2.{@,                               ",
"          x.= z t.k w.j !., |.; ( , ,                                                                 c@d 3 ,                               ",
"        F a.f.X.u@) p@i ,   h                                                                           U W+,                               ",
"      ! e.y.q@- f@c@}.,                                                                                 3 l.,                               ",
"    3 ;.++v@d /+[., ,                                                                                                                       ",
"      n ..1.0@}.,                                                                                                                           ",
"    C >.|@i , ,                                                                                                                             ",
"  w@F+q@_.,                                                                                                                                 ",
"| 5+5 , ,                                                                                                                                   ",
"                                                                                                                                            ",
"                                                                                                                                            ",
"                                                                                                                                            "};
_EOF_

    cat >"$md_inst/HexenIIPraevus_70x70.xpm" << _EOF_
/* XPM */
static char * HexenIIPraevus_70x70_xpm[] = {
"70 70 997 2",
"   c None",
".  c #815F2C",
"+  c #88632D",
"@  c #835F2C",
"#  c #8E6630",
"\$  c #956C37",
"%  c #89612E",
"&  c #956D38",
"*  c #946D3A",
"=  c #926832",
"-  c #A27C47",
";  c #8D642C",
">  c #A7804A",
",  c #926B38",
"'  c #85612C",
")  c #82612D",
"!  c #946B36",
"~  c #785927",
"{  c #8F6731",
"]  c #906831",
"^  c #9D7541",
"/  c #89622D",
"(  c #775526",
"_  c #9B723F",
":  c #8D6733",
"<  c #7D5927",
"[  c #6C4A1A",
"}  c #6F5025",
"|  c #815F29",
"1  c #7E5B28",
"2  c #926C37",
"3  c #98723D",
"4  c #825C28",
"5  c #604716",
"6  c #6D4C21",
"7  c #7C5C2D",
"8  c #825B24",
"9  c #886531",
"0  c #805E2B",
"a  c #A67E48",
"b  c #8C642C",
"c  c #89612C",
"d  c #77531E",
"e  c #62421A",
"f  c #6F4D20",
"g  c #7C5C30",
"h  c #825F2A",
"i  c #7B5722",
"j  c #A47D4A",
"k  c #8B652E",
"l  c #79592A",
"m  c #8C632E",
"n  c #815C2B",
"o  c #755222",
"p  c #75552B",
"q  c #71542D",
"r  c #744F1C",
"s  c #64410E",
"t  c #8D662F",
"u  c #9C7541",
"v  c #7D5E29",
"w  c #6B4B24",
"x  c #845D2B",
"y  c #8C652E",
"z  c #76582E",
"A  c #704E22",
"B  c #6D4917",
"C  c #98703C",
"D  c #83612C",
"E  c #8D6A35",
"F  c #775218",
"G  c #765427",
"H  c #8F6630",
"I  c #906732",
"J  c #78582D",
"K  c #724F1E",
"L  c #99723D",
"M  c #A37D48",
"N  c #7B5621",
"O  c #85622B",
"P  c #7A5822",
"Q  c #8B632D",
"R  c #6B4E26",
"S  c #7A592F",
"T  c #7D623B",
"U  c #75562F",
"V  c #6F4A18",
"W  c #936D38",
"X  c #96703B",
"Y  c #7D5822",
"Z  c #82602E",
"\`  c #715229",
" . c #734D15",
".. c #724F1C",
"+. c #8B632F",
"@. c #745628",
"#. c #705530",
"\$. c #755C39",
"%. c #74511A",
"&. c #7D5C26",
"*. c #744F1A",
"=. c #76572A",
"-. c #6D4F2B",
";. c #855E28",
">. c #855F2B",
",. c #8C632B",
"'. c #715326",
"). c #6B4F23",
"!. c #641313",
"~. c #343434",
"{. c #5F4422",
"]. c #765E3B",
"^. c #856740",
"/. c #704F23",
"(. c #614318",
"_. c #785014",
":. c #6A4F30",
"<. c #8A642F",
"[. c #936933",
"}. c #865D27",
"|. c #6D4F22",
"1. c #614924",
"2. c #6C4F24",
"3. c #7A2208",
"4. c #6E0C0C",
"5. c #5F4A28",
"6. c #916D3C",
"7. c #906E3E",
"8. c #7F5E34",
"9. c #7C561A",
"0. c #66441A",
"a. c #755423",
"b. c #7C5E35",
"c. c #806138",
"d. c #725123",
"e. c #654725",
"f. c #7E6647",
"g. c #6A4D23",
"h. c #634B35",
"i. c #73310B",
"j. c #6A0D0D",
"k. c #614B24",
"l. c #93754A",
"m. c #896637",
"n. c #7C5825",
"o. c #714B17",
"p. c #765830",
"q. c #755C3A",
"r. c #644B31",
"s. c #635245",
"t. c #6A452B",
"u. c #735B41",
"v. c #664323",
"w. c #73624D",
"x. c #833307",
"y. c #61170F",
"z. c #671B0E",
"A. c #542C1D",
"B. c #7C6035",
"C. c #79592B",
"D. c #4B3C26",
"E. c #6B5335",
"F. c #776245",
"G. c #6E5732",
"H. c #605A59",
"I. c #584E45",
"J. c #696664",
"K. c #594837",
"L. c #534A44",
"M. c #5F574F",
"N. c #5F5656",
"O. c #880202",
"P. c #7D1C05",
"Q. c #64240E",
"R. c #6D310C",
"S. c #621212",
"T. c #543A23",
"U. c #3D3430",
"V. c #785727",
"W. c #8A6C43",
"X. c #94703F",
"Y. c #604A25",
"Z. c #3F2F2A",
"\`. c #5D5F5D",
" + c #565454",
".+ c #565656",
"++ c #504E4A",
"@+ c #595958",
"#+ c #5F615F",
"\$+ c #686868",
"%+ c #890202",
"&+ c #65130C",
"*+ c #6B360D",
"=+ c #71360B",
"-+ c #740906",
";+ c #392B32",
">+ c #342E39",
",+ c #724F21",
"'+ c #8E6835",
")+ c #917349",
"!+ c #72542D",
"~+ c #4F3522",
"{+ c #555755",
"]+ c #5D4233",
"^+ c #6F4326",
"/+ c #5D5D5D",
"(+ c #6C4A3A",
"_+ c #65524A",
":+ c #585958",
"<+ c #8D0202",
"[+ c #670808",
"}+ c #2C2C2C",
"|+ c #66350B",
"1+ c #64190E",
"2+ c #6D180C",
"3+ c #600606",
"4+ c #2E2E2E",
"5+ c #524120",
"6+ c #7B5825",
"7+ c #82602C",
"8+ c #5C4220",
"9+ c #542219",
"0+ c #823107",
"a+ c #474747",
"b+ c #595959",
"c+ c #4F4F49",
"d+ c #4E524E",
"e+ c #595651",
"f+ c #636160",
"g+ c #4C4C4C",
"h+ c #860202",
"i+ c #7C0505",
"j+ c #4E1010",
"k+ c #530C0C",
"l+ c #5E2613",
"m+ c #71250B",
"n+ c #78310A",
"o+ c #770600",
"p+ c #443B2A",
"q+ c #614521",
"r+ c #604320",
"s+ c #3F2D2D",
"t+ c #682C10",
"u+ c #7E1705",
"v+ c #9A0706",
"w+ c #8D4B1C",
"x+ c #4C4A4A",
"y+ c #5A5C5A",
"z+ c #4F534D",
"A+ c #50504C",
"B+ c #5B5B59",
"C+ c #797979",
"D+ c #4A4A4A",
"E+ c #784520",
"F+ c #861809",
"G+ c #950000",
"H+ c #780D0A",
"I+ c #352E35",
"J+ c #2D2D2D",
"K+ c #501717",
"L+ c #610F0F",
"M+ c #70240E",
"N+ c #813709",
"O+ c #582018",
"P+ c #3C2D32",
"Q+ c #363036",
"R+ c #402B24",
"S+ c #72350B",
"T+ c #6D120C",
"U+ c #A00400",
"V+ c #934E1C",
"W+ c #A06741",
"X+ c #4C4A45",
"Y+ c #4C403B",
"Z+ c #4D3F31",
"\`+ c #4F3726",
" @ c #524C44",
".@ c #545454",
"+@ c #474947",
"@@ c #7F4827",
"#@ c #7A411A",
"\$@ c #841505",
"%@ c #960000",
"&@ c #820202",
"*@ c #4A1919",
"=@ c #561717",
"-@ c #660E0E",
";@ c #770606",
">@ c #622712",
",@ c #671705",
"'@ c #712A0B",
")@ c #5A0808",
"!@ c #920602",
"~@ c #89410C",
"{@ c #984006",
"]@ c #7E0303",
"^@ c #484A48",
"/@ c #503D3B",
"(@ c #4F4B44",
"_@ c #4B463D",
":@ c #52504A",
"<@ c #4A4C4A",
"[@ c #6E0909",
"}@ c #8A3106",
"|@ c #683612",
"1@ c #811A07",
"2@ c #9A0000",
"3@ c #AF0000",
"4@ c #8E0000",
"5@ c #8A0000",
"6@ c #5E1010",
"7@ c #4A1D1D",
"8@ c #680D0D",
"9@ c #681708",
"0@ c #7D2D03",
"a@ c #7B2B08",
"b@ c #9F0000",
"c@ c #AB0000",
"d@ c #B20000",
"e@ c #A40000",
"f@ c #940604",
"g@ c #75431A",
"h@ c #88341B",
"i@ c #970000",
"j@ c #511F1F",
"k@ c #60312F",
"l@ c #64332D",
"m@ c #692E28",
"n@ c #443B39",
"o@ c #3D3D3D",
"p@ c #3F2E2E",
"q@ c #780606",
"r@ c #81200F",
"s@ c #724117",
"t@ c #77140D",
"u@ c #7D0505",
"v@ c #5D1111",
"w@ c #5E0A0A",
"x@ c #5B1111",
"y@ c #5A1414",
"z@ c #5F1010",
"A@ c #6E240C",
"B@ c #893C06",
"C@ c #70200C",
"D@ c #4D1313",
"E@ c #620F0F",
"F@ c #730909",
"G@ c #A80000",
"H@ c #A20202",
"I@ c #944913",
"J@ c #A82C07",
"K@ c #A90000",
"L@ c #950202",
"M@ c #531A1A",
"N@ c #3C2A2A",
"O@ c #602016",
"P@ c #904D30",
"Q@ c #894329",
"R@ c #5E2117",
"S@ c #363030",
"T@ c #4F1C1C",
"U@ c #8A0202",
"V@ c #9B0000",
"W@ c #9C1502",
"X@ c #8E3F0D",
"Y@ c #791008",
"Z@ c #680B0B",
"\`@ c #3A2727",
" # c #591313",
".# c #591515",
"+# c #751908",
"@# c #6B0A0A",
"## c #471B1B",
"\$# c #7A0303",
"%# c #7D0303",
"&# c #700606",
"*# c #760606",
"=# c #700909",
"-# c #8C0402",
";# c #8E330C",
"># c #C71600",
",# c #C60000",
"'# c #B30000",
")# c #6A0A0A",
"!# c #641711",
"~# c #890D06",
"{# c #872D09",
"]# c #76150B",
"^# c #5B1414",
"/# c #630F0F",
"(# c #A30000",
"_# c #BF0000",
":# c #B70300",
"<# c #8F3008",
"[# c #71190E",
"}# c #441D1D",
"|# c #4D1D1D",
"1# c #6E0707",
"2# c #5D0B0B",
"3# c #471D1D",
"4# c #4B1E1E",
"5# c #730E0B",
"6# c #863113",
"7# c #C02E02",
"8# c #C80000",
"9# c #7A0505",
"0# c #710909",
"a# c #6E120C",
"b# c #892F19",
"c# c #804A29",
"d# c #821007",
"e# c #6C0C0C",
"f# c #AC0000",
"g# c #BB0000",
"h# c #B22502",
"i# c #8A3208",
"j# c #6C130C",
"k# c #2F2F2F",
"l# c #4A1B1B",
"m# c #4E1515",
"n# c #362828",
"o# c #431B1B",
"p# c #510D0D",
"q# c #780603",
"r# c #74320F",
"s# c #A24104",
"t# c #9A0400",
"u# c #A70000",
"v# c #870000",
"w# c #820000",
"x# c #7E0805",
"y# c #92300A",
"z# c #84320B",
"A# c #840705",
"B# c #840202",
"C# c #800303",
"D# c #A00000",
"E# c #A23902",
"F# c #75320F",
"G# c #720C09",
"H# c #58271C",
"I# c #5A1914",
"J# c #5D1D16",
"K# c #740606",
"L# c #672A16",
"M# c #813509",
"N# c #913504",
"O# c #900000",
"P# c #830000",
"Q# c #860000",
"R# c #7E0D05",
"S# c #831F05",
"T# c #7C2C0A",
"U# c #830905",
"V# c #8B0000",
"W# c #8C0000",
"X# c #980000",
"Y# c #9C2F02",
"Z# c #964208",
"\`#  c #6B2913",
" \$  c #780806",
".\$  c #583823",
"+\$  c #5A422C",
"@\$  c #5D3526",
"#\$  c #8B291B",
"\$\$  c #720606",
"%\$  c #7E0503",
"&\$  c #612514",
"*\$  c #762F08",
"=\$  c #892804",
"-\$  c #850000",
";\$  c #7D0A05",
">\$  c #81310B",
",\$  c #803C0D",
"'\$  c #7F0C05",
")\$  c #8D0200",
"!\$  c #872C07",
"~\$  c #78320E",
"{\$  c #760B08",
"]\$  c #670E0E",
"^\$  c #563624",
"/\$  c #5B4428",
"(\$  c #966D3A",
"_\$  c #960202",
":\$  c #B40000",
"<\$  c #352B2B",
"[\$  c #620505",
"}\$  c #7D0503",
"|\$  c #5F301B",
"1\$  c #7A2B05",
"2\$  c #911100",
"3\$  c #8F0000",
"4\$  c #830705",
"5\$  c #802403",
"6\$  c #834409",
"7\$  c #810705",
"8\$  c #982702",
"9\$  c #77380D",
"0\$  c #6D230E",
"a\$  c #3F282E",
"b\$  c #6F120C",
"c\$  c #956F3B",
"d\$  c #910000",
"e\$  c #8F0404",
"f\$  c #3E1F1F",
"g\$  c #710606",
"h\$  c #800503",
"i\$  c #7C310A",
"j\$  c #872707",
"k\$  c #920604",
"l\$  c #760700",
"m\$  c #742D06",
"n\$  c #800705",
"o\$  c #A60000",
"p\$  c #9F0200",
"q\$  c #933B06",
"r\$  c #7F2A05",
"s\$  c #491F1F",
"t\$  c #392B2B",
"u\$  c #750808",
"v\$  c #7D0805",
"w\$  c #8E6430",
"x\$  c #363630",
"y\$  c #6F3310",
"z\$  c #8C2004",
"A\$  c #980404",
"B\$  c #7C0808",
"C\$  c #780000",
"D\$  c #7B0D05",
"E\$  c #843C0E",
"F\$  c #A91800",
"G\$  c #9B0704",
"H\$  c #79260E",
"I\$  c #6F320C",
"J\$  c #7B0B05",
"K\$  c #AA0000",
"L\$  c #A72602",
"M\$  c #783110",
"N\$  c #7F0300",
"O\$  c #650000",
"P\$  c #4C1919",
"Q\$  c #8A622D",
"R\$  c #8B6734",
"S\$  c #41382A",
"T\$  c #583C26",
"U\$  c #554024",
"V\$  c #692612",
"W\$  c #672710",
"X\$  c #462328",
"Y\$  c #850505",
"Z\$  c #7C0303",
"\`\$  c #7D2E0A",
" % c #9C2504",
".% c #813631",
"+% c #694B3C",
"@% c #63503F",
"#% c #62483F",
"\$%  c #95241F",
"%% c #962104",
"&% c #7E2805",
"*% c #600D0D",
"=% c #4F1A1A",
"-% c #313131",
";% c #790808",
">% c #946B38",
",% c #9E7742",
"'% c #9F7843",
")% c #97713D",
"!% c #916C38",
"~% c #7A5622",
"{% c #78511C",
"]% c #A78049",
"^% c #83643B",
"/% c #725B3B",
"(% c #8F6E40",
"_% c #705327",
":% c #4B3927",
"<% c #7B370C",
"[% c #69250F",
"}% c #541919",
"|% c #541717",
"1% c #7B0808",
"2% c #7E0F05",
"3% c #842907",
"4% c #5F5651",
"5% c #626058",
"6% c #61635B",
"7% c #5F625B",
"8% c #615349",
"9% c #802E09",
"0% c #6C0A0A",
"a% c #720B0B",
"b% c #970604",
"c% c #78531C",
"d% c #77592E",
"e% c #8F6936",
"f% c #9B7441",
"g% c #886D48",
"h% c #7E6648",
"i% c #8B6838",
"j% c #483428",
"k% c #4B2521",
"l% c #842902",
"m% c #61130F",
"n% c #810503",
"o% c #7E2809",
"p% c #75250F",
"q% c #6A2904",
"r% c #810000",
"s% c #7E0505",
"t% c #690F13",
"u% c #691417",
"v% c #AD0000",
"w% c #866230",
"x% c #755B33",
"y% c #715531",
"z% c #836335",
"A% c #7B5A2F",
"B% c #715121",
"C% c #6F4C1D",
"D% c #664B20",
"E% c #3F2E28",
"F% c #782C00",
"G% c #771B08",
"H% c #601D12",
"I% c #7D310C",
"J% c #5F5952",
"K% c #65645A",
"L% c #63675E",
"M% c #64655E",
"N% c #792E10",
"O% c #740E08",
"P% c #682310",
"Q% c #810F05",
"R% c #933502",
"S% c #AE8A59",
"T% c #99733E",
"U% c #7F5D28",
"V% c #78511B",
"W% c #744D17",
"X% c #3A3027",
"Y% c #4A361B",
"Z% c #6B3C19",
"\`%  c #871A02",
" & c #7F3007",
".& c #691914",
"+& c #661C17",
"@& c #723A12",
"#& c #661E19",
"\$&  c #6F1B10",
"%& c #802D07",
"&& c #7D3407",
"*& c #622E14",
"=& c #74230B",
"-& c #780B06",
";& c #502020",
">& c #A27A44",
",& c #916934",
"'& c #825F28",
")& c #6D4717",
"!& c #6D411C",
"~& c #781F0A",
"{& c #792D08",
"]& c #626057",
"^& c #65675C",
"/& c #706553",
"(& c #625A51",
"_& c #5A463F",
":& c #782508",
"<& c #6D3C15",
"[& c #720909",
"}& c #7A2A0A",
"|& c #833509",
"1& c #6F170C",
"2& c #523722",
"3& c #524226",
"4& c #936B36",
"5& c #8F6732",
"6& c #A37D46",
"7& c #8F6734",
"8& c #76421A",
"9& c #7C350E",
"0& c #761B08",
"a& c #503835",
"b& c #5B3634",
"c& c #4C4543",
"d& c #554141",
"e& c #51443B",
"f& c #791D08",
"g& c #7B4312",
"h& c #8C2A04",
"i& c #882202",
"j& c #71110B",
"k& c #4A3C2A",
"l& c #6D5128",
"m& c #826236",
"n& c #523A22",
"o& c #845F2B",
"p& c #7F5C27",
"q& c #A37B45",
"r& c #976F39",
"s& c #774019",
"t& c #753915",
"u& c #7D2307",
"v& c #7C380C",
"w& c #782D10",
"x& c #87480C",
"y& c #731109",
"z& c #78260A",
"A& c #724015",
"B& c #963A04",
"C& c #69190F",
"D& c #584323",
"E& c #7E5F34",
"F& c #8A693D",
"G& c #715939",
"H& c #8D6B3C",
"I& c #9F7944",
"J& c #6F4D18",
"K& c #884F25",
"L& c #744022",
"M& c #833007",
"N& c #7F2E07",
"O& c #7E3B1D",
"P& c #7E4418",
"Q& c #7A1708",
"R& c #76330D",
"S& c #764316",
"T& c #333333",
"U& c #303036",
"V& c #513C23",
"W& c #694D21",
"X& c #7B5B2B",
"Y& c #886940",
"Z& c #9F7E50",
"\`&  c #AC844D",
" * c #86612F",
".* c #664219",
"+* c #B00503",
"@* c #7E390F",
"#* c #854517",
"\$*  c #8A1A04",
"%* c #8B2E06",
"&* c #813607",
"** c #870C02",
"=* c #85350E",
"-* c #713F17",
";* c #74330B",
">* c #39332C",
",* c #433622",
"'* c #694612",
")* c #7A5A2C",
"!* c #8E6E41",
"~* c #947040",
"{* c #856230",
"]* c #76501B",
"^* c #B70000",
"/* c #642D1D",
"(* c #8B3D19",
"_* c #831907",
":* c #782B0A",
"<* c #962210",
"[* c #753E1F",
"}* c #66321A",
"|* c #920202",
"1* c #7C5A25",
"2* c #735732",
"3* c #755C36",
"4* c #765A30",
"5* c #775726",
"6* c #89662E",
"7* c #B60000",
"8* c #830505",
"9* c #820505",
"0* c #7F3D19",
"a* c #702010",
"b* c #5F241B",
"c* c #8F4012",
"d* c #6A1B0F",
"e* c #6D4217",
"f* c #75521F",
"g* c #7B5C2F",
"h* c #835E29",
"i* c #775627",
"j* c #916933",
"k* c #A17B47",
"l* c #B90000",
"m* c #C10000",
"n* c #B50000",
"o* c #C20000",
"p* c #740808",
"q* c #864413",
"r* c #955112",
"s* c #671812",
"t* c #9C0000",
"u* c #683F12",
"v* c #795422",
"w* c #7F5923",
"x* c #A07945",
"y* c #A27B46",
"z* c #9D0000",
"A* c #890000",
"B* c #A20000",
"C* c #AE0000",
"D* c #940000",
"E* c #442727",
"F* c #2F3636",
"G* c #4C2428",
"H* c #611216",
"I* c #690D0D",
"J* c #79561F",
"K* c #84612D",
"L* c #906935",
"M* c #926933",
"N* c #880000",
"O* c #750606",
"P* c #3F2828",
"Q* c #601212",
"R* c #770808",
"S* c #8A0404",
"T* c #A10000",
"U* c #8C0202",
"V* c #825D2A",
"W* c #9B743F",
"X* c #8B0404",
"Y* c #9E0000",
"Z* c #A50000",
"\`*  c #7A0A08",
" = c #990202",
".= c #6D0A0A",
"+= c #730606",
"@= c #571616",
"#= c #6D0C0C",
"\$=  c #6F090C",
"%= c #8E6734",
"&= c #950200",
"*= c #712F10",
"== c #956D3C",
"-= c #804E29",
";= c #980202",
">= c #670B0B",
",= c #3E2323",
"'= c #303030",
")= c #422626",
"!= c #93200A",
"~= c #7E562A",
"{= c #734E21",
"]= c #674012",
"^= c #810803",
"/= c #8D6634",
"(= c #790505",
"_= c #711209",
":= c #705022",
"<= c #A17943",
"[= c #AA824C",
"}= c #8C512B",
"|= c #5E1313",
"1= c #392C2C",
"2= c #511414",
"3= c #541212",
"4= c #5B1814",
"5= c #7A4015",
"6= c #895E2A",
"7= c #81643B",
"8= c #7C5D2C",
"9= c #754F18",
"0= c #60390D",
"a= c #910804",
"b= c #830202",
"c= c #8C6430",
"d= c #940202",
"e= c #7B0505",
"f= c #6C3E11",
"g= c #845E2D",
"h= c #95703E",
"i= c #B08550",
"j= c #A9814A",
"k= c #885E34",
"l= c #581C18",
"m= c #39342E",
"n= c #7C623D",
"o= c #593313",
"p= c #714F20",
"q= c #895D31",
"r= c #906937",
"s= c #936A36",
"t= c #85602B",
"u= c #775018",
"v= c #623C0F",
"w= c #780303",
"x= c #87632C",
"y= c #920000",
"z= c #6F0F09",
"A= c #664210",
"B= c #7B5221",
"C= c #916736",
"D= c #A37B48",
"E= c #AE844D",
"F= c #A97E4B",
"G= c #966F42",
"H= c #815F31",
"I= c #B08F63",
"J= c #AF8B59",
"K= c #957549",
"L= c #8C642F",
"M= c #8D6939",
"N= c #8C6632",
"O= c #7F5B28",
"P= c #75511C",
"Q= c #64421D",
"R= c #603716",
"S= c #910404",
"T= c #633E11",
"U= c #6B4213",
"V= c #795421",
"W= c #A27A43",
"X= c #AB7F4A",
"Y= c #A68049",
"Z= c #A47E47",
"\`=  c #AF8750",
" - c #B19062",
".- c #AF8B5C",
"+- c #966C38",
"@- c #77521D",
"#- c #71501E",
"\$-  c #755320",
"%- c #7A5217",
"&- c #73330F",
"*- c #603715",
"=- c #784910",
"-- c #724913",
";- c #714410",
">- c #6E440E",
",- c #75511D",
"'- c #866331",
")- c #957342",
"!- c #A57D48",
"~- c #A37C45",
"{- c #A9824C",
"]- c #AF8A57",
"^- c #A57D47",
"/- c #8C6633",
"(- c #795828",
"_- c #785A2E",
":- c #755730",
"<- c #714F1B",
"[- c #5D1E11",
"}- c #5D1313",
"|- c #71240E",
"1- c #7A5725",
"2- c #896732",
"3- c #866131",
"4- c #7A5525",
"5- c #7E5B2A",
"6- c #8D6935",
"7- c #99723E",
"8- c #9C7642",
"9- c #785624",
"0- c #705229",
"a- c #67471E",
"b- c #602C15",
"c- c #600F0A",
"d- c #462323",
"e- c #6C321A",
"f- c #906D3B",
"g- c #A47C45",
"h- c #976A37",
"i- c #8A5727",
"j- c #86602B",
"k- c #693E16",
"l- c #601A12",
"m- c #612C1A",
"n- c #997141",
"o- c #96713B",
"p- c #98723E",
"q- c #936D3A",
"r- c #845A2A",
"s- c #785320",
"t- c #724715",
"u- c #634119",
"v- c #7A5327",
"w- c #88602E",
"x- c #825D28",
"y- c #6E491F",
"z- c #442525",
"A- c #881908",
"B- c #6A3A19",
"C- c #612114",
"D- c #621A0F",
"E- c #591915",
"F- c #5B1116",
"G- c #4E271E",
"H- c #5D4323",
"I- c #52291D",
"J- c #4B2121",
"K- c #640E0E",
"L- c #511B1B",
"                                                                                                                                            ",
"                                                                                                                                            ",
"                                                                                                                                            ",
"                                                                                                                            .               ",
"                                                                                                                            +         @     ",
"                                                                                                                                    #       ",
"                                                                                                                          \$         %       ",
"                                                                                                                          &       *         ",
"                                                                                                                          =     -           ",
"                                                                                                                        ; +   > ,           ",
"                '                                                                                                       )     !             ",
"                                                                                                                        ~   { ]   ^         ",
"      /           &                                                                                                     (   @   _           ",
"        :         &                                                                                             <     [ } | 1 2             ",
"          3         !                                                                                           4 5   6 7 8 9 0             ",
"            a       b                                                                                           c d e f g h i               ",
"              j       k                                               l                                         m n o p q r s               ",
"              t u     v                                               w                                         x y t z A B                 ",
"        C       D E   F |                                             G                                           H I J K                   ",
"          L M     N O   P       Q                                     R                                           S T U V                   ",
"              W X   Y Z \`  .../ +.                                    @.                                          #.\$.%.                    ",
"                  &.*.=.-.;.>.,.                                    '.} ).                                !.~.{.].^./.                      ",
"                    (._.:.<.[.}.                                    |.1.2.                              3.4.5.6.7.8.9.                      ",
"                      0.a.b.c.d.                                    e.f.g.h.                            i.j.k.l.m.n.                        ",
"                        o.p.q.r.                                  s.t.u.v.w.                          x.y.z.A.B.C.D.                        ",
"                          V E.F.G.                              H.I.J.K.L.M.N.                      O.P.Q.R.S.T.{.U.                        ",
"                            V.W.X.Y.Z.                          \`. +.+++@+#+\$+                      %+&+*+=+-+;+>+                          ",
"                            ,+'+)+!+~+                          {+]+^+/+(+_+:+                    <+[+}+|+1+2+3+4+                          ",
"                            5+6+7+8+9+0+                        a+b+c+d+e+f+g+                  h+i+j+k+l+m+n+o+                            ",
"                            p+q+r+s+t+u+            v+w+        x+y+z+A+B+C+D+      E+F+      G+H+I+J+K+L+M+N+                              ",
"                            O+P+Q+R+S+T+            U+V+W+      X+Y+Z+\`+ @.@+@    @@#@\$@    %@&@O.*@4+=@-@;@                                ",
"                              >@4+,@'@)@O.          !@~@{@]@    ^@/@(@_@:@D+<@  [@}@|@1@2@3@4@5@&@6@7@6@8@                                  ",
"                                9@0@a@k+O.b@c@d@e@  f@g@h@i@h+6@j@k@l@m@n@o@p@q@5@r@s@t@h+u@v@w@w@x@y@z@                                    ",
"                                A@B@C@D@E@F@G@c@4@b@H@I@J@K@L@M@N@O@P@Q@R@S@T@U@V@W@X@Y@-@Z@\`@J+ #.#                                        ",
"                                  +#@###\$#%#&#*#=#i+-#;#>#,#'#)#L+!#~#{#]#^#/#(#_#:#<#[#K+}#4+7@v@                                          ",
"                                    )#|#1#2#3#x@6@4#5#6#7#8#3@9#0#a#b#c#d#e#e#f#g#h#i#j#k#l#L+                                              ",
"                                      6@7@m#n#o#p#n#q#r#s#t#u#v#w#x#y#z#A#B#C#K@D#E#F#G#=@H#                                                ",
"                                          y@I#J#^#y@K#L#M#N#O#P#Q#R#S#T#U#V#W#X#Y#Z#\`# \$.\$+\$                                                ",
"                                            @\$#\$4@\$\$y@%\$&\$*\$=\$w#-\$;\$>\$,\$'\$5@5@)\$!\$~\${\$]\$^\$/\$                                                ",
"                        (\$                  _\$:\$U@]\$<\$[\$}\$|\$1\$2\$3\$4\$5\$6\$7\$i@%@8\$9\$0\$)#a\$b\$                                                  ",
"                          c\$              %@d\$e\$/#2#f\$.#g\$h\$i\$j\$b@k\$l\$m\$n\$o\$p\$q\$r\$\$\$s\$t\$u\$v\$                                                ",
"                          w\$      x\$y\$z\$L@A\$G+B\$<\$o#z@    C\$D\$E\$F\$G\$H\$I\$J\$K\$L\$M\$N\$O\$L+P\$4#F@                                                ",
"                          Q\$R\$  S\$T\$U\$V\$W\$X\$Y\$/### #      3#Z\$\`\$ %.%+%@%#%\$%%%&%*%    =%-%;%%@                                              ",
"          >%,%'%^ )%!%~%{%& ]%^%/%(%_%:%<%[%}%|%6@        1%g\$2%3%4%5%6%7%8%9%q@0%    v@|%a%V@b%                                            ",
"                    c%z d%e%f%g%h%i%v j%k%l%m%6@            @#n%o%{\$p%q%G#r%i\$q@s%      =@e#t%u%v%                                          ",
"                      w%x%y%z%A%B%C%D%E%J+F%G%              H%&@I%J%K%L%M%8%N%O%P%        |%N@4#Q%R%                                        ",
"                S%T%U%Y a.V%W%    X%Y%4+                    Z%\`% &.&+&@&#&\$&%&&&          z@-@*&=&-&;&                                      ",
"            ,%>&,&    '&)&                                  !&~&{&]&^&/&(&_&:&<&          [&}&|&1&2&3&~.      \$ 4&                          ",
"          5&&     6&7&                                      8&9&0&a&b&c&d&e&f&g&          h&i&j&k&l&m&n&      o&                            ",
"      p&o&      q&r&                                        s&t&u&v&w&x&y&9\$z&A&          B&C&~.D&E&F&G&H&I&+.J&                            ",
"              ,&                                            K&L&M&N&O&P&Q&R&y\$S&            T&U&V&W&X&Y&Z&\`& *.*                            ",
"                                                          O#+*@*#*\$*%*&***=*-*;*<+              >*,*'*)*!*~*{*]*                            ",
"                                                        ^*(#<+=#/*(*_*:*<*[*}*K#c@|*<+                  1*2*3*4*5*6*                        ",
"                                                    h+i@v%7*8*_\$9*0*a*b*c*d*0%9#G@G@U@i+                e*f*g*h*i*7+j*k*                    ",
"                                                  e@3@l*m*n*_#o*d\$p*q*r*s*j.]@]@t*'#v%b@5@9#              u*v*w*7+      x*y*                ",
"                                              z*W#A*G@B*o\$C*b@D*Q#K#E*F*G*H**#I*G@z*2@K\$u#G+W#Z\$            J*  K*L*        M*              ",
"                                            &@O#i@4@u@8*N*7*D*-\$O*L+N@P*Q*=#0#R*^*S*\$\$&@T*c@%@U*Y\$            V*  M*W*                      ",
"                                            X*Y*G@_#Z*&@\`* =u#.=w#+==@@=.=]\$.#F@v%#=\$=v#N*2@2@\$#-@              ,&  %=y*                    ",
"                                            *#i@v%d@&=*===-=;=@=y@8@>=x@,='=)=9#!=~={=]=^=O#G@V#.=                    /=                    ",
"                                            (=O#(#z*_=:=<=[=}=|=T&1=2=3=}+J+4=5=6=7=8=9=0=a=Z*b=B#                (\$    c=                  ",
"                                            t*d\$d=e=f=g=h=i=j=k=l=m=n=q.}+o=p=q=r=s=t=u=v=w=X#i+O.                        x=                ",
"                                            d@%+y=z=A=B=C=D=E=F=G=H=I=J=K=x L=M=N=O=P=Q=R=&@z*&@                                            ",
"                                              4@<+S=T=A=U=V='+W=X=Y=Z=\`= -.-+-p&@-#-\$-%-&-D*G+<+                                            ",
"                                                O*e=*-=---;->-,-'-)-!-~-{-]-^-/-(-_-:-<-[-O.=#                                              ",
"                                                  }-y@/#8@|-1-2-3-4-5-6-7-8-W*/-9-0-a-b-c-=%}-                                              ",
"                                                    d-S.e-f-g-6&W*h-i-Y /-7-s=j-k-l-T@=#E@/#                                                ",
"                                                    I*m-n-o-p-q-R\$r-s-t-u-v-w-x-y-=@M@(=z-                                                  ",
"                                                      u\$A-B-C-D-E-S@=@}-T@F-G-H-I-@=J-;@.#                                                  ",
"                                                            K-z@z@=@|#K-4#|%N@T&|#=@T&R*                                                    ",
"                                                                    s\$^#L-4#\`@                                                              "};
_EOF_
}
