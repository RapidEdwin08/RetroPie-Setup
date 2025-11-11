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
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="pcexhumed"
rp_module_desc="Powerslave/Exhumed source port - Ken Silverman's Build Engine"
rp_module_licence="GPL3 https://github.com/OpenMW/osg/blob/3.4/LICENSE.txt"
rp_module_repo="git https://github.com/nukeykt/NBlood.git master"
rp_module_help="Place Game Files in [ports/ksbuild/pcexhumed]: \nSTUFF.DAT\nDEMO.VCR\nBOOK.MOV\n \nOptional [CD Audio]:\ntrack02.ogg...track19.ogg\nexhumed02.ogg...exhumed19.ogg"
rp_module_section="exp"
rp_module_flags=""

function depends_pcexhumed() {
	# libsdl1.2-dev libsdl-mixer1.2-dev xorg xinit x11-xserver-utils
	local depends=(cmake build-essential libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev freepats)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
	isPlatform "kms" && depends+=(xorg matchbox-window-manager)
	getDepends "${depends[@]}"
}

function sources_pcexhumed() {
	gitPullOrClone
}

function build_pcexhumed() {
    cd $md_build
    local params=(LTO=0 SDL_TARGET=2 RENDERTYPE=SDL STARTUP_WINDOW=0)
    if isPlatform "rpi"; then # For Best Results on RPi make blood exhumed rr with USE_OPENGL=0 POLYMER=0
    	params+=(USE_OPENGL=0 POLYMER=0 NETCODE=0)
    else
    	isPlatform "gl" && params+=(USE_OPENGL=1)
    	! ( isPlatform "gl" || isPlatform "mesa" ) && params+=(USE_OPENGL=0)
    	isPlatform "gl3" && params+=(POLYMER=1)
    	! isPlatform "gl3" && params+=(POLYMER=0)
    	isPlatform "arm" && params+=(NETCODE=0)
    fi
    echo [PARAMS]: ${params[@]}
    make -j"$(nproc)" exhumed "${params[@]}"
	md_ret_require="$md_build"
}

function install_pcexhumed() {
    md_ret_files=(        
		'dn64widescreen.pk3'
        'pcexhumed'
        'pcexhumed.pk3'
		'nblood.pk3'
    )
}

function game_data_pcexhumed() {
    if [[ ! -f "$romdir/ports/ksbuild/pcexhumed/STUFF.DAT" ]] && [[ ! -f "$romdir/ports/ksbuild/pcexhumed/BOOK.MOV" ]]; then
		mkRomDir "ports/ksbuild/pcexhumed"
		downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/pcexhumed/pcexhumed-rp-assets.tar.gz" "$romdir/ports/ksbuild/pcexhumed"
		chown -R $__user:$__user "$romdir/ports/ksbuild/pcexhumed"
	fi
}

function remove_pcexhumed() {
    local shortcut_name
    shortcut_name="Powerslave (Exhumed)"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
}

function gui_pcexhumed() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      Get Additional Desktop Shortcuts + Icons\n\nGet Desktop Shortcuts for Additional Episodes + Add-Ons that may not have been present at Install\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "Get Shortcuts + Icons" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            game_data_pcexhumed
            shortcuts_icons_pcexhumed
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_pcexhumed() {
	if [[ ! -d "$home/.config/pcexhumed" ]]; then mkdir "$home/.config/pcexhumed"; fi
	if [[ ! -f "$home/.config/pcexhumed/pcexhumed_cvars.cfg" ]]; then touch "$home/.config/pcexhumed/pcexhumed_cvars.cfg"; fi
	if [[ "$(cat "$home/.config/pcexhumed/pcexhumed_cvars.cfg" | grep r_vsync)" == '' ]]; then
		echo 'r_vsync "1"' >> "$home/.config/pcexhumed/pcexhumed_cvars.cfg"
	else
		sed -i 's+r_vsync.*+r_vsync "1"+g' "$home/.config/pcexhumed/pcexhumed_cvars.cfg"
	fi
	chown -R $__user:$__user "$home/.config/pcexhumed"
    moveConfigDir "$home/.config/pcexhumed" "$md_conf_root/$md_id"
    # [WARN| Could not find main data file "nblood.pk3"!
    ln -s "$md_inst/nblood.pk3" "$md_conf_root/$md_id/nblood.pk3"
    ln -s "$md_inst/pcexhumed.pk3" "$md_conf_root/$md_id/pcexhumed.pk3"
    ln -s "$md_inst/dn64widescreen.pk3" "$md_conf_root/$md_id/dn64widescreen.pk3"
    chown -R $__user:$__user "$md_conf_root/$md_id"
	chmod 755 $md_inst/pcexhumed-qjoy.sh

	mkRomDir "ports/ksbuild/pcexhumed"
	chown -R $__user:$__user "$romdir/ports/ksbuild"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
	addPort "$md_id" "pcexhumed" "Powerslave (PCExhumed)" "$launch_prefix$md_inst/pcexhumed.sh"
	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "pcexhumed" "Powerslave (PCExhumed)" "$launch_prefix$md_inst/pcexhumed-qjoy.sh"
	fi

   cat >"$md_inst/$md_id.sh" << _EOF_
#!/bin/bash

# Run $md_id
pushd /opt/retropie/configs/ports/$md_id
VC4_DEBUG=always_sync /opt/retropie/ports/$md_id/$md_id -j \$HOME/RetroPie/roms/ports/ksbuild/$md_id
popd

exit 0
_EOF_
    chmod 755 "$md_inst/$md_id.sh"

    cat >"$md_inst/pcexhumed.cfg" << _EOF_
[Setup]
CacheSize = 100663296
ForceSetup = 1
NoAutoLoad = 1

[Screen Setup]
ScreenBPP = 8
ScreenHeight = 1024
ScreenMode = 2
ScreenWidth = 1280
MaxRefreshFreq = 0
WindowPosX = -1
WindowPosY = -1
WindowPositioning = 0
FullScreen = 0
ScreenSize = 0
Gamma = 2

[Controls]
MouseButton0 = "Fire"
MouseButtonClicked0 = ""
MouseButton1 = "Strafe"
MouseButtonClicked1 = ""
MouseButton2 = "Move_Forward"
MouseButtonClicked2 = ""
MouseButton3 = ""
MouseButtonClicked3 = ""
MouseButton4 = ""
MouseButtonClicked4 = ""
MouseButton5 = ""
MouseButtonClicked5 = ""
MouseButton6 = ""
MouseButtonClicked6 = ""
MouseButton7 = ""
MouseButtonClicked7 = ""
MouseButton8 = ""
MouseButton9 = ""
MouseAnalogAxes0 = "analog_strafing"
MouseDigitalAxes0_0 = ""
MouseDigitalAxes0_1 = ""
MouseAnalogScale0 = 65536
MouseAnalogAxes1 = "analog_moving"
MouseDigitalAxes1_0 = ""
MouseDigitalAxes1_1 = ""
MouseAnalogScale1 = 65536
ControllerButton0 = ""
ControllerButtonClicked0 = ""
ControllerButton1 = ""
ControllerButtonClicked1 = ""
ControllerButton2 = ""
ControllerButtonClicked2 = ""
ControllerButton3 = ""
ControllerButtonClicked3 = ""
ControllerButton4 = ""
ControllerButtonClicked4 = ""
ControllerButton5 = ""
ControllerButtonClicked5 = ""
ControllerButton6 = ""
ControllerButtonClicked6 = ""
ControllerButton7 = ""
ControllerButtonClicked7 = ""
ControllerButton8 = ""
ControllerButtonClicked8 = ""
ControllerButton9 = ""
ControllerButtonClicked9 = ""
ControllerButton10 = ""
ControllerButtonClicked10 = ""
ControllerButton11 = ""
ControllerButtonClicked11 = ""
ControllerButton12 = ""
ControllerButtonClicked12 = ""
ControllerButton13 = ""
ControllerButtonClicked13 = ""
ControllerButton14 = ""
ControllerButtonClicked14 = ""
ControllerButton15 = ""
ControllerButtonClicked15 = ""
ControllerButton16 = ""
ControllerButtonClicked16 = ""
ControllerButton17 = ""
ControllerButtonClicked17 = ""
ControllerButton18 = ""
ControllerButtonClicked18 = ""
ControllerButton19 = ""
ControllerButtonClicked19 = ""
ControllerButton20 = ""
ControllerButtonClicked20 = ""
ControllerButton21 = ""
ControllerButtonClicked21 = ""
ControllerButton22 = ""
ControllerButtonClicked22 = ""
ControllerButton23 = ""
ControllerButtonClicked23 = ""
ControllerButton24 = ""
ControllerButtonClicked24 = ""
ControllerButton25 = ""
ControllerButtonClicked25 = ""
ControllerButton26 = ""
ControllerButtonClicked26 = ""
ControllerButton27 = ""
ControllerButtonClicked27 = ""
ControllerButton28 = ""
ControllerButtonClicked28 = ""
ControllerButton29 = ""
ControllerButtonClicked29 = ""
ControllerButton30 = ""
ControllerButtonClicked30 = ""
ControllerButton31 = ""
ControllerButtonClicked31 = ""
ControllerButton32 = ""
ControllerButtonClicked32 = ""
ControllerButton33 = ""
ControllerButtonClicked33 = ""
ControllerButton34 = ""
ControllerButtonClicked34 = ""
ControllerButton35 = ""
ControllerButtonClicked35 = ""
ControllerAnalogAxes0 = "analog_turning"
ControllerDigitalAxes0_0 = ""
ControllerDigitalAxes0_1 = ""
ControllerAnalogScale0 = 0
ControllerAnalogInvert0 = 0
ControllerAnalogDead0 = 0
ControllerAnalogSaturate0 = 0
ControllerAnalogAxes1 = "analog_turning"
ControllerDigitalAxes1_0 = ""
ControllerDigitalAxes1_1 = ""
ControllerAnalogScale1 = 0
ControllerAnalogInvert1 = 0
ControllerAnalogDead1 = 0
ControllerAnalogSaturate1 = 0
ControllerAnalogAxes2 = "analog_turning"
ControllerDigitalAxes2_0 = ""
ControllerDigitalAxes2_1 = ""
ControllerAnalogScale2 = 0
ControllerAnalogInvert2 = 0
ControllerAnalogDead2 = 0
ControllerAnalogSaturate2 = 0
ControllerAnalogAxes3 = "analog_turning"
ControllerDigitalAxes3_0 = ""
ControllerDigitalAxes3_1 = ""
ControllerAnalogScale3 = 0
ControllerAnalogInvert3 = 0
ControllerAnalogDead3 = 0
ControllerAnalogSaturate3 = 0
ControllerAnalogAxes4 = "analog_turning"
ControllerDigitalAxes4_0 = ""
ControllerDigitalAxes4_1 = ""
ControllerAnalogScale4 = 0
ControllerAnalogInvert4 = 0
ControllerAnalogDead4 = 0
ControllerAnalogSaturate4 = 0
ControllerAnalogAxes5 = "analog_turning"
ControllerDigitalAxes5_0 = ""
ControllerDigitalAxes5_1 = ""
ControllerAnalogScale5 = 0
ControllerAnalogInvert5 = 0
ControllerAnalogDead5 = 0
ControllerAnalogSaturate5 = 0
ControllerAnalogAxes6 = "analog_turning"
ControllerDigitalAxes6_0 = ""
ControllerDigitalAxes6_1 = ""
ControllerAnalogScale6 = 0
ControllerAnalogInvert6 = 0
ControllerAnalogDead6 = 0
ControllerAnalogSaturate6 = 0
ControllerAnalogAxes7 = "analog_turning"
ControllerDigitalAxes7_0 = ""
ControllerDigitalAxes7_1 = ""
ControllerAnalogScale7 = 0
ControllerAnalogInvert7 = 0
ControllerAnalogDead7 = 0
ControllerAnalogSaturate7 = 0
ControllerAnalogAxes8 = "analog_turning"
ControllerDigitalAxes8_0 = ""
ControllerDigitalAxes8_1 = ""
ControllerAnalogScale8 = 0
ControllerAnalogInvert8 = 0
ControllerAnalogDead8 = 0
ControllerAnalogSaturate8 = 0
_EOF_
	if [[ ! -f "$home/.config/pcexhumed/pcexhumed.cfg" ]]; then
		cp "$md_inst/pcexhumed.cfg" "$home/.config/pcexhumed/pcexhumed.cfg"
		chown -R $__user:$__user "$home/.config/pcexhumed/pcexhumed.cfg"
	fi

   cat >"$md_inst/pcexhumed-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Exhumed"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5538, xZone 29536, +key 40, -key 38
	Axis 2: gradient, dZone 9230, xZone 28382, +key 39, -key 25
	Axis 3: gradient, dZone 3922, +key 37, -key 0
	Axis 4: gradient, dZone 5768, xZone 28382, maxSpeed 15, mouse+h
	Axis 5: gradient, dZone 8768, maxSpeed 10, mouse+v
	Axis 6: gradient, throttle+, +key 105, -key 0
	Axis 7: +key 35, -key 34
	Axis 8: +key 116, -key 111
	Button 1: key 65
	Button 2: key 26
	Button 3: key 37
	Button 4: key 66
	Button 5: key 47
	Button 6: key 48
	Button 7: key 9
	Button 8: key 36
	Button 9: key 23
	Button 10: key 50
	Button 11: key 110
	Button 12: key 34
	Button 13: key 35
	Button 14: key 111
	Button 15: key 116
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run $md_id
pushd /opt/retropie/configs/ports/$md_id
VC4_DEBUG=always_sync /opt/retropie/ports/$md_id/$md_id -j \$HOME/RetroPie/roms/ports/ksbuild/$md_id
popd

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1

# Restart qjoypad IF DTWPID qjoypad@Desktop is Enabled + startx is running
if [[ -f /etc/xdg/autostart/qjoypad-start.desktop ]] && pgrep -f startx &> /dev/null 2>&1; then qjoypad-start > /dev/null 2>&1; fi

exit 0
_EOF_
    chmod 755 "$md_inst/pcexhumed-qjoy.sh"

    [[ "$md_mode" == "remove" ]] && remove_pcexhumed
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && game_data_pcexhumed
    [[ "$md_mode" == "install" ]] && shortcuts_icons_pcexhumed
}

function shortcuts_icons_pcexhumed() {
    local exec_name="$md_inst/$md_id.sh"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then exec_name=$md_inst/$md_id-qjoy.sh; fi
    local shortcut_name
    shortcut_name="Powerslave (Exhumed)"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$exec_name
Icon=$md_inst/Powerslave_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Powerslave;Exhumed
StartupWMClass=PowerslaveExhumed
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/Powerslave_48x48.xpm" << _EOF_
/* XPM */
static char * Powerslave_48x48_xpm[] = {
"48 48 1279 2",
"  	c None",
". 	c #EEA425",
"+ 	c #ECB840",
"@ 	c #F8BE2D",
"# 	c #F3AF29",
"\$ 	c #B77E3F",
"% 	c #F7B419",
"& 	c #F7ED7D",
"* 	c #FAF88D",
"= 	c #F7C42C",
"- 	c #D69232",
"; 	c #AB753E",
"> 	c #E5A727",
", 	c #F2E55E",
"' 	c #F5ED6A",
") 	c #F3BD2D",
"! 	c #C3863C",
"~ 	c #965F32",
"{ 	c #B97D3A",
"] 	c #E3A733",
"^ 	c #F4B023",
"/ 	c #C98635",
"( 	c #A46D39",
"_ 	c #8F552D",
": 	c #A7703B",
"< 	c #AE743D",
"[ 	c #996134",
"} 	c #7B4A25",
"| 	c #9D663C",
"1 	c #BEA178",
"2 	c #BBA47F",
"3 	c #7A502D",
"4 	c #643F26",
"5 	c #9F7B53",
"6 	c #CABD98",
"7 	c #A87547",
"8 	c #8B5331",
"9 	c #4F3323",
"0 	c #5C402A",
"a 	c #714C30",
"b 	c #98683E",
"c 	c #A16538",
"d 	c #AC6838",
"e 	c #915028",
"f 	c #824926",
"g 	c #A55F31",
"h 	c #AA6C3C",
"i 	c #98653B",
"j 	c #916447",
"k 	c #7D5039",
"l 	c #7A4121",
"m 	c #683E2C",
"n 	c #512819",
"o 	c #462514",
"p 	c #4C2616",
"q 	c #52301E",
"r 	c #452B1F",
"s 	c #41221C",
"t 	c #5B3F2A",
"u 	c #A2764A",
"v 	c #97572A",
"w 	c #9E5A2D",
"x 	c #90512A",
"y 	c #7D4927",
"z 	c #9F592C",
"A 	c #95562D",
"B 	c #9F6437",
"C 	c #9C7851",
"D 	c #8F5832",
"E 	c #88512B",
"F 	c #A56B3E",
"G 	c #9C673F",
"H 	c #754125",
"I 	c #785A3F",
"J 	c #412319",
"K 	c #472415",
"L 	c #582C1C",
"M 	c #472518",
"N 	c #391D18",
"O 	c #41241D",
"P 	c #391E19",
"Q 	c #3D2D24",
"R 	c #593930",
"S 	c #A06537",
"T 	c #CAB08C",
"U 	c #B58B65",
"V 	c #794223",
"W 	c #502C21",
"X 	c #9F663A",
"Y 	c #CCB393",
"Z 	c #B78A5D",
"\` 	c #895432",
" .	c #7D5030",
"..	c #93572F",
"+.	c #A46A3B",
"@.	c #83512B",
"#.	c #885934",
"\$.	c #9D7350",
"%.	c #744A2F",
"&.	c #5D3822",
"*.	c #492E29",
"=.	c #633D2C",
"-.	c #673C23",
";.	c #54311E",
">.	c #381C17",
",.	c #43291D",
"'.	c #43261B",
").	c #2D1115",
"!.	c #563A25",
"~.	c #865B38",
"{.	c #794E30",
"].	c #623B22",
"^.	c #9B562A",
"/.	c #A36637",
"(.	c #A2582B",
"_.	c #8C552E",
":.	c #60402D",
"<.	c #A65F2F",
"[.	c #9F5D30",
"}.	c #A25F31",
"|.	c #AC7042",
"1.	c #BC8252",
"2.	c #AB734D",
"3.	c #9E693D",
"4.	c #754729",
"5.	c #8D5A31",
"6.	c #774A2A",
"7.	c #603E29",
"8.	c #633C25",
"9.	c #775742",
"0.	c #846649",
"a.	c #41231C",
"b.	c #3C2634",
"c.	c #74452D",
"d.	c #653A21",
"e.	c #402119",
"f.	c #371C18",
"g.	c #442D1F",
"h.	c #341917",
"i.	c #995B2F",
"j.	c #995E33",
"k.	c #71482C",
"l.	c #5B463D",
"m.	c #A16D50",
"n.	c #7C4727",
"o.	c #C39865",
"p.	c #B8A67E",
"q.	c #8A6A4D",
"r.	c #D6BD8F",
"s.	c #855531",
"t.	c #935128",
"u.	c #917461",
"v.	c #5B3A25",
"w.	c #BF7B3F",
"x.	c #BD7A3E",
"y.	c #8F5D36",
"z.	c #8A5834",
"A.	c #633F29",
"B.	c #65432C",
"C.	c #97653B",
"D.	c #593A26",
"E.	c #3A201F",
"F.	c #6F4843",
"G.	c #492419",
"H.	c #110E11",
"I.	c #502E2B",
"J.	c #6B3F2A",
"K.	c #4E2E20",
"L.	c #2F1215",
"M.	c #43261A",
"N.	c #402019",
"O.	c #9B5A37",
"P.	c #9E5C30",
"Q.	c #875330",
"R.	c #66402D",
"S.	c #724931",
"T.	c #784324",
"U.	c #BB7D41",
"V.	c #CEB285",
"W.	c #DACCA6",
"X.	c #C48D4F",
"Y.	c #9E6031",
"Z.	c #6C3D23",
"\`.	c #855D41",
" +	c #AE7642",
".+	c #C87F3E",
"++	c #BB7942",
"@+	c #9B6236",
"#+	c #7C5032",
"\$+	c #5F3E29",
"%+	c #7E5235",
"&+	c #A06538",
"*+	c #593537",
"=+	c #261026",
"-+	c #7F4824",
";+	c #865037",
">+	c #64321D",
",+	c #3F2018",
"'+	c #150D10",
")+	c #0F0D11",
"!+	c #3B2B38",
"~+	c #523533",
"{+	c #432316",
"]+	c #3D2318",
"^+	c #3D231B",
"/+	c #503D40",
"(+	c #704E4B",
"_+	c #5E4D50",
":+	c #3D3B41",
"<+	c #281A1B",
"[+	c #572D19",
"}+	c #8E5129",
"|+	c #B38F62",
"1+	c #B88A51",
"2+	c #93582D",
"3+	c #784123",
"4+	c #432F22",
"5+	c #766152",
"6+	c #B68056",
"7+	c #B67C4F",
"8+	c #7F6763",
"9+	c #7C5235",
"0+	c #69442D",
"a+	c #6D4930",
"b+	c #945F35",
"c+	c #7F5138",
"d+	c #271D37",
"e+	c #401C19",
"f+	c #8F5027",
"g+	c #7F4F35",
"h+	c #472321",
"i+	c #331C1B",
"j+	c #1A1819",
"k+	c #0C0D08",
"l+	c #1E1C2A",
"m+	c #3E3441",
"n+	c #4D2A1F",
"o+	c #351916",
"p+	c #432312",
"q+	c #251514",
"r+	c #2E1812",
"s+	c #381F13",
"t+	c #5C391E",
"u+	c #70401F",
"v+	c #94572B",
"w+	c #9D592B",
"x+	c #8E532C",
"y+	c #94603F",
"z+	c #AE6835",
"A+	c #9B592D",
"B+	c #824C25",
"C+	c #6B452C",
"D+	c #6A4C44",
"E+	c #5B453C",
"F+	c #6C4D38",
"G+	c #865835",
"H+	c #64462E",
"I+	c #935E35",
"J+	c #A46636",
"K+	c #3A303D",
"L+	c #291329",
"M+	c #4A2920",
"N+	c #6B3F26",
"O+	c #663E27",
"P+	c #502722",
"Q+	c #3D201C",
"R+	c #311A1A",
"S+	c #131313",
"T+	c #080908",
"U+	c #11130B",
"V+	c #292438",
"W+	c #42282E",
"X+	c #391B14",
"Y+	c #442215",
"Z+	c #502A19",
"\`+	c #6C3D22",
" @	c #956537",
".@	c #8C522C",
"+@	c #AC6834",
"@@	c #B59F7D",
"#@	c #8C6243",
"\$@	c #A99776",
"%@	c #A17145",
"&@	c #90552F",
"*@	c #A88E70",
"=@	c #B48758",
"-@	c #96542B",
";@	c #996738",
">@	c #9B6C45",
",@	c #A57749",
"'@	c #8D6442",
")@	c #744F33",
"!@	c #A56A38",
"~@	c #89573B",
"{@	c #2E273B",
"]@	c #38201F",
"^@	c #563827",
"/@	c #603824",
"(@	c #5F3924",
"_@	c #633F2A",
":@	c #5F2E1C",
"<@	c #402114",
"[@	c #281314",
"}@	c #0A0A09",
"|@	c #080808",
"1@	c #0F0F0D",
"2@	c #1C1926",
"3@	c #2F253A",
"4@	c #3C1F19",
"5@	c #4C2819",
"6@	c #5F311D",
"7@	c #78492B",
"8@	c #7A4D2E",
"9@	c #5A311E",
"0@	c #92522B",
"a@	c #B68E6C",
"b@	c #A36F4D",
"c@	c #B39373",
"d@	c #8D4B2A",
"e@	c #9A522A",
"f@	c #B39576",
"g@	c #A76B42",
"h@	c #66301A",
"i@	c #73482A",
"j@	c #AA703D",
"k@	c #BE7C40",
"l@	c #BB7B45",
"m@	c #AD764B",
"n@	c #AC6F43",
"o@	c #624443",
"p@	c #402B2D",
"q@	c #47251A",
"r@	c #7F4726",
"s@	c #743E20",
"t@	c #784021",
"u@	c #7E4828",
"v@	c #6C371D",
"w@	c #552A1A",
"x@	c #371914",
"y@	c #1E0F12",
"z@	c #0A0A08",
"A@	c #0B0C09",
"B@	c #10110D",
"C@	c #181222",
"D@	c #160F13",
"E@	c #40231C",
"F@	c #503533",
"G@	c #554442",
"H@	c #48352E",
"I@	c #402820",
"J@	c #49271B",
"K@	c #481A11",
"L@	c #5C2313",
"M@	c #4B150F",
"N@	c #421211",
"O@	c #471614",
"P@	c #461915",
"Q@	c #492217",
"R@	c #4A2B1F",
"S@	c #43261E",
"T@	c #634540",
"U@	c #81604E",
"V@	c #A66E48",
"W@	c #A96C3A",
"X@	c #A26643",
"Y@	c #60423E",
"Z@	c #582F21",
"\`@	c #5C301C",
" #	c #87522A",
".#	c #764120",
"+#	c #85421D",
"@#	c #864C26",
"##	c #592B29",
"\$#	c #42211E",
"%#	c #30161A",
"&#	c #080505",
"*#	c #010101",
"=#	c #0A0909",
"-#	c #251B1B",
";#	c #3C201A",
">#	c #46251B",
",#	c #78301B",
"'#	c #834225",
")#	c #7F4D2F",
"!#	c #422318",
"~#	c #471811",
"{#	c #461710",
"]#	c #441F16",
"^#	c #4F2B1C",
"/#	c #74482D",
"(#	c #91532C",
"_#	c #85411E",
":#	c #612F1A",
"<#	c #321D17",
"[#	c #3E2E29",
"}#	c #6E5747",
"|#	c #835331",
"1#	c #765138",
"2#	c #56291A",
"3#	c #573124",
"4#	c #5D342C",
"5#	c #582B2B",
"6#	c #623123",
"7#	c #653721",
"8#	c #5E3020",
"9#	c #4E3034",
"0#	c #3F201E",
"a#	c #2E161B",
"b#	c #040404",
"c#	c #121212",
"d#	c #3B2725",
"e#	c #4F2018",
"f#	c #522125",
"g#	c #782615",
"h#	c #912211",
"i#	c #8A4421",
"j#	c #7C4A2A",
"k#	c #553420",
"l#	c #412017",
"m#	c #461714",
"n#	c #462C1E",
"o#	c #65412F",
"p#	c #764731",
"q#	c #8D3218",
"r#	c #802F16",
"s#	c #621F13",
"t#	c #551B14",
"u#	c #4B2419",
"v#	c #3E241A",
"w#	c #59433A",
"x#	c #624433",
"y#	c #462516",
"z#	c #472827",
"A#	c #4C2B2D",
"B#	c #4E282C",
"C#	c #532D30",
"D#	c #5E3425",
"E#	c #532F26",
"F#	c #482B26",
"G#	c #3F2424",
"H#	c #250F20",
"I#	c #0D0D0D",
"J#	c #0B0B0B",
"K#	c #070707",
"L#	c #321915",
"M#	c #712D1B",
"N#	c #630F10",
"O#	c #511418",
"P#	c #5E0F0E",
"Q#	c #781810",
"R#	c #8F2D14",
"S#	c #843F1D",
"T#	c #693F26",
"U#	c #482B1B",
"V#	c #461F16",
"W#	c #543925",
"X#	c #7E4123",
"Y#	c #8D2B1A",
"Z#	c #861C1C",
"\`#	c #6B1210",
" \$	c #5E0909",
".\$	c #5D0A0B",
"+\$	c #671B13",
"@\$	c #5A2B1A",
"#\$	c #3F261F",
"\$\$	c #442819",
"%\$	c #291412",
"&\$	c #3E2924",
"*\$	c #48392D",
"=\$	c #4A3225",
"-\$	c #5D3428",
";\$	c #7B3E23",
">\$	c #593023",
",\$	c #372529",
"'\$	c #191110",
")\$	c #52271A",
"!\$	c #402012",
"~\$	c #220912",
"{\$	c #0C0809",
"]\$	c #0F0F0F",
"^\$	c #4D2617",
"/\$	c #621F11",
"(\$	c #130202",
"_\$	c #030000",
":\$	c #240709",
"<\$	c #7A100B",
"[\$	c #922215",
"}\$	c #80321E",
"|\$	c #792213",
"1\$	c #6D1C14",
"2\$	c #6F2E17",
"3\$	c #8C2110",
"4\$	c #8B110C",
"5\$	c #3E1A1B",
"6\$	c #160304",
"7\$	c #060303",
"8\$	c #060404",
"9\$	c #3C1011",
"0\$	c #602B19",
"a\$	c #281616",
"b\$	c #261112",
"c\$	c #020101",
"d\$	c #1F1614",
"e\$	c #311D1B",
"f\$	c #43241A",
"g\$	c #63331C",
"h\$	c #773E1E",
"i\$	c #4D2C31",
"j\$	c #271B33",
"k\$	c #593119",
"l\$	c #532918",
"m\$	c #3C1E13",
"n\$	c #280814",
"o\$	c #1A080E",
"p\$	c #050505",
"q\$	c #000000",
"r\$	c #150F0F",
"s\$	c #512C24",
"t\$	c #4C251C",
"u\$	c #0C0000",
"v\$	c #6C1C02",
"w\$	c #5A2102",
"x\$	c #0C0103",
"y\$	c #3C110E",
"z\$	c #4C2222",
"A\$	c #431212",
"B\$	c #310F13",
"C\$	c #491312",
"D\$	c #3E1010",
"E\$	c #240506",
"F\$	c #2D0202",
"G\$	c #7E2904",
"H\$	c #350202",
"I\$	c #010000",
"J\$	c #250C0E",
"K\$	c #592918",
"L\$	c #221211",
"M\$	c #040304",
"N\$	c #020202",
"O\$	c #2A1712",
"P\$	c #6A371D",
"Q\$	c #884722",
"R\$	c #3A1E24",
"S\$	c #270914",
"T\$	c #6B3C1F",
"U\$	c #523128",
"V\$	c #4C2517",
"W\$	c #331816",
"X\$	c #240A14",
"Y\$	c #0E080A",
"Z\$	c #160E0D",
"\`\$	c #522521",
" %	c #491819",
".%	c #100000",
"+%	c #8C1F02",
"@%	c #691D02",
"#%	c #48090D",
"\$%	c #52090D",
"%%	c #410A11",
"&%	c #440A0E",
"*%	c #190407",
"=%	c #050000",
"-%	c #2F0101",
";%	c #9A2903",
">%	c #3B0202",
",%	c #280A0C",
"'%	c #5D1712",
")%	c #230D0D",
"!%	c #2A1813",
"~%	c #6D381C",
"{%	c #8A4822",
"]%	c #563320",
"^%	c #1E0810",
"/%	c #603827",
"(%	c #4E2F26",
"_%	c #3B2122",
":%	c #2F121A",
"<%	c #27101A",
"[%	c #130A0D",
"}%	c #0F0C0C",
"|%	c #491814",
"1%	c #671712",
"2%	c #2A0D0B",
"3%	c #060304",
"4%	c #4E0807",
"5%	c #9B1208",
"6%	c #890F0B",
"7%	c #5F0B0F",
"8%	c #7D0E09",
"9%	c #710C0A",
"0%	c #0F0102",
"a%	c #160101",
"b%	c #1A0A0C",
"c%	c #4D1714",
"d%	c #591210",
"e%	c #220E0D",
"f%	c #060102",
"g%	c #240D13",
"h%	c #3B2019",
"i%	c #5E2F25",
"j%	c #724024",
"k%	c #5E3426",
"l%	c #301918",
"m%	c #492826",
"n%	c #3E211D",
"o%	c #362024",
"p%	c #2F121E",
"q%	c #24151D",
"r%	c #140C0F",
"s%	c #10090C",
"t%	c #0E0E0F",
"u%	c #361C19",
"v%	c #642421",
"w%	c #94140C",
"x%	c #77100C",
"y%	c #4F0B10",
"z%	c #42151A",
"A%	c #620B0D",
"B%	c #94100A",
"C%	c #8A100B",
"D%	c #97130E",
"E%	c #741010",
"F%	c #6F1212",
"G%	c #8A0F0C",
"H%	c #750F0C",
"I%	c #400F0F",
"J%	c #450D0E",
"K%	c #650B0D",
"L%	c #94110A",
"M%	c #711E19",
"N%	c #441D1A",
"O%	c #100A0A",
"P%	c #160309",
"Q%	c #341919",
"R%	c #482423",
"S%	c #54282D",
"T%	c #572C2B",
"U%	c #513532",
"V%	c #3B2928",
"W%	c #563125",
"X%	c #4A2725",
"Y%	c #3E2117",
"Z%	c #341A1A",
"\`%	c #271224",
" &	c #221A26",
".&	c #060606",
"+&	c #131315",
"@&	c #3A2121",
"#&	c #5C2826",
"\$&	c #8B150F",
"%&	c #8A120D",
"&&	c #89170F",
"*&	c #72211D",
"=&	c #6F2322",
"-&	c #641E1F",
";&	c #791A16",
">&	c #5F242B",
",&	c #312633",
"'&	c #59252A",
")&	c #771510",
"!&	c #7B1E12",
"~&	c #6F1E13",
"{&	c #6D2014",
"]&	c #86180F",
"^&	c #8B150D",
"/&	c #7A1C12",
"(&	c #54211B",
"_&	c #311513",
":&	c #030202",
"<&	c #120207",
"[&	c #2B0D15",
"}&	c #3C2018",
"|&	c #472C2E",
"1&	c #492B2B",
"2&	c #4D2F30",
"3&	c #562B2A",
"4&	c #5E392F",
"5&	c #654130",
"6&	c #653D27",
"7&	c #633920",
"8&	c #4C2715",
"9&	c #432311",
"0&	c #2C0F15",
"a&	c #190C0E",
"b&	c #0C0C0C",
"c&	c #151212",
"d&	c #3F271B",
"e&	c #503930",
"f&	c #5D2D24",
"g&	c #533029",
"h&	c #583229",
"i&	c #67261F",
"j&	c #68271C",
"k&	c #732218",
"l&	c #6B2525",
"m&	c #0D0605",
"n&	c #3F2026",
"o&	c #7F2616",
"p&	c #692C18",
"q&	c #723017",
"r&	c #6B3323",
"s&	c #592F29",
"t&	c #5E2C26",
"u&	c #63341F",
"v&	c #47332F",
"w&	c #28191A",
"x&	c #030303",
"y&	c #130308",
"z&	c #270E14",
"A&	c #3F2119",
"B&	c #4C2615",
"C&	c #55281C",
"D&	c #5C2D1C",
"E&	c #76351A",
"F&	c #844520",
"G&	c #7F4D27",
"H&	c #592F1E",
"I&	c #462918",
"J&	c #270814",
"K&	c #16080D",
"L&	c #090909",
"M&	c #0D0C0C",
"N&	c #2F2827",
"O&	c #3A404F",
"P&	c #37384B",
"Q&	c #282B39",
"R&	c #32262E",
"S&	c #7A1614",
"T&	c #7C291E",
"U&	c #731E1A",
"V&	c #661717",
"W&	c #070505",
"X&	c #220408",
"Y&	c #301718",
"Z&	c #891B10",
"\`&	c #702614",
" *	c #7B321C",
".*	c #462D37",
"+*	c #2D2D3A",
"@*	c #383B4F",
"#*	c #494750",
"\$*	c #2D3240",
"%*	c #0D0A11",
"&*	c #130C0E",
"**	c #240713",
"=*	c #3D1F15",
"-*	c #452410",
";*	c #4B2514",
">*	c #4E2619",
",*	c #562A1B",
"'*	c #67381F",
")*	c #724326",
"!*	c #7D4725",
"~*	c #442626",
"{*	c #40231E",
"]*	c #3A2018",
"^*	c #32151C",
"/*	c #2C0B1E",
"(*	c #28151F",
"_*	c #1D191B",
":*	c #151515",
"<*	c #141414",
"[*	c #080809",
"}*	c #161824",
"|*	c #16181D",
"1*	c #0A0A0B",
"2*	c #380F16",
"3*	c #430C12",
"4*	c #6D1611",
"5*	c #82130E",
"6*	c #84120C",
"7*	c #3D0A08",
"8*	c #430609",
"9*	c #5D1910",
"0*	c #801A10",
"a*	c #831C10",
"b*	c #5A2A1A",
"c*	c #331D26",
"d*	c #231212",
"e*	c #25202F",
"f*	c #242B3A",
"g*	c #121318",
"h*	c #0A0A0A",
"i*	c #221C25",
"j*	c #28191F",
"k*	c #39201B",
"l*	c #3B2119",
"m*	c #3B2117",
"n*	c #3B2118",
"o*	c #402823",
"p*	c #482E2B",
"q*	c #4A2929",
"r*	c #412529",
"s*	c #392019",
"t*	c #33171D",
"u*	c #2D0D21",
"v*	c #26151F",
"w*	c #1D1B1C",
"x*	c #1E191C",
"y*	c #1C1C1C",
"z*	c #1A1A1A",
"A*	c #0F0608",
"B*	c #3D0C0F",
"C*	c #180B0E",
"D*	c #3E130F",
"E*	c #690C0E",
"F*	c #5B1712",
"G*	c #681C12",
"H*	c #611C13",
"I*	c #692016",
"J*	c #6A1D14",
"K*	c #76110E",
"L*	c #291611",
"M*	c #0C090B",
"N*	c #2C1723",
"O*	c #0B080C",
"P*	c #1D181C",
"Q*	c #2E1321",
"R*	c #381E19",
"S*	c #371D1D",
"T*	c #38211B",
"U*	c #38221B",
"V*	c #39221D",
"W*	c #38221C",
"X*	c #3D2728",
"Y*	c #442A2D",
"Z*	c #492823",
"\`*	c #391F18",
" =	c #2B0C1A",
".=	c #290A1B",
"+=	c #1D1717",
"@=	c #171715",
"#=	c #111111",
"\$=	c #101010",
"%=	c #080203",
"&=	c #010103",
"*=	c #41070D",
"==	c #270806",
"-=	c #432013",
";=	c #391212",
">=	c #3C1A14",
",=	c #401313",
"'=	c #361413",
")=	c #431514",
"!=	c #3B1514",
"~=	c #351612",
"{=	c #401611",
"]=	c #080405",
"^=	c #141521",
"/=	c #020204",
"(=	c #2A0918",
"_=	c #2A091A",
":=	c #2B0F1C",
"<=	c #321F20",
"[=	c #3C261C",
"}=	c #3D261D",
"|=	c #402A1E",
"1=	c #4F2F23",
"2=	c #5D3C32",
"3=	c #3C343E",
"4=	c #45231A",
"5=	c #391B17",
"6=	c #2D1315",
"7=	c #271715",
"8=	c #1A110F",
"9=	c #17080D",
"0=	c #0B0806",
"a=	c #020203",
"b=	c #131221",
"c=	c #37060C",
"d=	c #260808",
"e=	c #401D0F",
"f=	c #862310",
"g=	c #4F2217",
"h=	c #551E12",
"i=	c #7E1310",
"j=	c #962311",
"k=	c #461E10",
"l=	c #431912",
"m=	c #12070A",
"n=	c #240E11",
"o=	c #301114",
"p=	c #2E1215",
"q=	c #391A17",
"r=	c #421F18",
"s=	c #4A2718",
"t=	c #603B25",
"u=	c #604C4A",
"v=	c #53575B",
"w=	c #533B3B",
"x=	c #5B3020",
"y=	c #52291B",
"z=	c #482513",
"A=	c #3A1F16",
"B=	c #2D1015",
"C=	c #250A13",
"D=	c #1E0D11",
"E=	c #141408",
"F=	c #180D0C",
"G=	c #11100D",
"H=	c #161222",
"I=	c #342B2A",
"J=	c #100F0F",
"K=	c #480604",
"L=	c #020001",
"M=	c #130607",
"N=	c #57281D",
"O=	c #432419",
"P=	c #7E3E28",
"Q=	c #5F3324",
"R=	c #652D1D",
"S=	c #662E20",
"T=	c #251110",
"U=	c #110507",
"V=	c #411C19",
"W=	c #251818",
"X=	c #341B15",
"Y=	c #723D20",
"Z=	c #844621",
"\`=	c #8E4A24",
" -	c #8B5029",
".-	c #935229",
"+-	c #9D5628",
"@-	c #9F5829",
"#-	c #9A5D31",
"\$-	c #9C6641",
"%-	c #7A6963",
"&-	c #464452",
"*-	c #3E3041",
"=-	c #4F3223",
"--	c #44211B",
";-	c #3E251A",
">-	c #351815",
",-	c #290A14",
"'-	c #230C13",
")-	c #240C12",
"!-	c #1C100E",
"~-	c #1B0F0D",
"{-	c #190D11",
"]-	c #191423",
"^-	c #4B312D",
"/-	c #13110F",
"(-	c #410505",
"_-	c #030102",
":-	c #050102",
"<-	c #180806",
"[-	c #120706",
"}-	c #140704",
"|-	c #030304",
"1-	c #4B2324",
"2-	c #2C0E19",
"3-	c #141010",
"4-	c #472C29",
"5-	c #6A4129",
"6-	c #75472A",
"7-	c #774528",
"8-	c #7D4C2A",
"9-	c #80512E",
"0-	c #82522D",
"a-	c #88562E",
"b-	c #8B552D",
"c-	c #7E593F",
"d-	c #615358",
"e-	c #676064",
"f-	c #181B4E",
"g-	c #2D3046",
"h-	c #351F1D",
"i-	c #29181A",
"j-	c #280914",
"k-	c #1C120E",
"l-	c #0D0F06",
"m-	c #060705",
"n-	c #181825",
"o-	c #62292C",
"p-	c #1B1516",
"q-	c #2C060C",
"r-	c #070302",
"s-	c #110607",
"t-	c #512123",
"u-	c #2E0D18",
"v-	c #2E1A14",
"w-	c #41281D",
"x-	c #4D2D20",
"y-	c #51291B",
"z-	c #512A1C",
"A-	c #472C1C",
"B-	c #552C1C",
"C-	c #613D2E",
"D-	c #3F3E4C",
"E-	c #22284E",
"F-	c #2C272E",
"G-	c #2C1417",
"H-	c #270D17",
"I-	c #280815",
"J-	c #200C11",
"K-	c #090F05",
"L-	c #141322",
"M-	c #4D212B",
"N-	c #3C2021",
"O-	c #1E0C13",
"P-	c #2E1710",
"Q-	c #271813",
"R-	c #1B0D0A",
"S-	c #100908",
"T-	c #0D0705",
"U-	c #160C09",
"V-	c #100A09",
"W-	c #23100B",
"X-	c #20150E",
"Y-	c #261613",
"Z-	c #080707",
"\`-	c #4F1F21",
" ;	c #2F111D",
".;	c #43271D",
"+;	c #4A311F",
"@;	c #543326",
"#;	c #573023",
"\$;	c #563023",
"%;	c #572C21",
"&;	c #592D1E",
"*;	c #623926",
"=;	c #6C422B",
"-;	c #60493D",
";;	c #36364E",
">;	c #11145A",
",;	c #2E2D47",
"';	c #372019",
");	c #251C20",
"!;	c #2B0F1F",
"~;	c #2C0C1E",
"{;	c #1D1619",
"];	c #191919",
"^;	c #181818",
"/;	c #13101D",
"(;	c #2D2B39",
"_;	c #422932",
":;	c #2B1D1E",
"<;	c #301C17",
"[;	c #4A1D13",
"};	c #5E1F18",
"|;	c #511F16",
"1;	c #552415",
"2;	c #832C16",
"3;	c #49281A",
"4;	c #572417",
"5;	c #2D1A12",
"6;	c #211A18",
"7;	c #241713",
"8;	c #431B1B",
"9;	c #422428",
"0;	c #221F2B",
"a;	c #3C2224",
"b;	c #412426",
"c;	c #44292B",
"d;	c #472C2F",
"e;	c #4B3031",
"f;	c #4A3031",
"g;	c #4B2F30",
"h;	c #5C3633",
"i;	c #694232",
"j;	c #564A48",
"k;	c #2C3D59",
"l;	c #262D52",
"m;	c #392624",
"n;	c #2D1D20",
"o;	c #291427",
"p;	c #291528",
"q;	c #271327",
"r;	c #211F22",
"s;	c #202020",
"t;	c #1F1F1F",
"u;	c #232731",
"v;	c #312F46",
"w;	c #412D30",
"x;	c #56372D",
"y;	c #4A2219",
"z;	c #310F10",
"A;	c #421313",
"B;	c #460E10",
"C;	c #551D14",
"D;	c #261212",
"E;	c #350F13",
"F;	c #361F17",
"G;	c #5A3726",
"H;	c #543828",
"I;	c #472E3D",
"J;	c #2A2D3C",
"K;	c #1D1D26",
"L;	c #3D282E",
"M;	c #42282C",
"N;	c #412A2F",
"O;	c #492B31",
"P;	c #493237",
"Q;	c #4F2F35",
"R;	c #543732",
"S;	c #623F35",
"T;	c #664B3A",
"U;	c #47464D",
"V;	c #30364D",
"W;	c #3A3438",
"X;	c #38211A",
"Y;	c #28191D",
"Z;	c #25141C",
"\`;	c #1C0A11",
" >	c #2D2632",
".>	c #393646",
"+>	c #634138",
"@>	c #754226",
"#>	c #6A2D18",
"\$>	c #6D1B11",
"%>	c #5D1410",
"&>	c #611411",
"*>	c #671D14",
"=>	c #602B1A",
"->	c #764528",
";>	c #764C2D",
">>	c #483C46",
",>	c #263146",
"'>	c #17181A",
")>	c #5B3B28",
"!>	c #5F3C27",
"~>	c #693E29",
"{>	c #764829",
"]>	c #7D4E2C",
"^>	c #8A5531",
"/>	c #75593F",
"(>	c #535759",
"_>	c #40393B",
":>	c #41271D",
"<>	c #311E1B",
"[>	c #221A1D",
"}>	c #24181B",
"|>	c #260A14",
"1>	c #210A12",
"2>	c #13080B",
"3>	c #16060C",
"4>	c #1E222F",
"5>	c #3F333E",
"6>	c #6A4035",
"7>	c #883319",
"8>	c #9A120A",
"9>	c #8C120B",
"0>	c #8B120C",
"a>	c #92110B",
"b>	c #891B0F",
"c>	c #833A1D",
"d>	c #5D3F3D",
"e>	c #232737",
"f>	c #16171B",
"g>	c #613E29",
"h>	c #653D23",
"i>	c #6C3D20",
"j>	c #704021",
"k>	c #7D4C28",
"l>	c #874F29",
"m>	c #655F53",
"n>	c #514C5A",
"o>	c #333649",
"p>	c #422A1E",
"q>	c #30191D",
"r>	c #291420",
"s>	c #2B0E1E",
"t>	c #2A111E",
"u>	c #22151B",
"v>	c #171A21",
"w>	c #35313F",
"x>	c #653639",
"y>	c #96170F",
"z>	c #A21309",
"A>	c #A51208",
"B>	c #A21409",
"C>	c #892819",
"D>	c #533636",
"E>	c #252A3F",
"F>	c #4D2D2A",
"G>	c #5A2F2D",
"H>	c #5B2E2B",
"I>	c #5B2E2A",
"J>	c #613A29",
"K>	c #69412A",
"L>	c #6F432B",
"M>	c #6E4C3A",
"N>	c #505153",
"O>	c #2D3551",
"P>	c #3A231F",
"Q>	c #3B221E",
"R>	c #392018",
"S>	c #34191C",
"T>	c #2D0C20",
"U>	c #2C0F20",
"V>	c #280E1D",
"W>	c #131314",
"X>	c #352B31",
"Y>	c #493239",
"Z>	c #643436",
"\`>	c #672A31",
" ,	c #623433",
".,	c #402E35",
"+,	c #24212C",
"@,	c #4C2A2D",
"#,	c #583530",
"\$,	c #543132",
"%,	c #5A3530",
"&,	c #5F3930",
"*,	c #69412F",
"=,	c #674336",
"-,	c #4A4751",
";,	c #2C2A4F",
">,	c #41363E",
",,	c #442C2F",
"',	c #402929",
"),	c #392623",
"!,	c #312125",
"~,	c #2A142B",
"{,	c #2A132C",
"],	c #211928",
"^,	c #16171C",
"/,	c #21222B",
"(,	c #232323",
"_,	c #1C1C1D",
":,	c #0F0E0F",
"<,	c #523131",
"[,	c #5C3736",
"},	c #604238",
"|,	c #69463C",
"1,	c #6A4D3E",
"2,	c #584744",
"3,	c #585252",
"4,	c #464951",
"5,	c #3F3545",
"6,	c #4F302F",
"7,	c #4D271A",
"8,	c #402213",
"9,	c #351B17",
"0,	c #211316",
"a,	c #64361F",
"b,	c #6D3D20",
"c,	c #6F3F21",
"d,	c #7A4A2D",
"e,	c #685142",
"f,	c #373840",
"g,	c #363852",
"h,	c #3E384B",
"i,	c #3D333F",
"j,	c #3D231D",
"k,	c #3F2214",
"l,	c #3A2017",
"m,	c #2C1715",
"n,	c #593326",
"o,	c #5E3327",
"p,	c #5A3327",
"q,	c #59352A",
"r,	c #4D474A",
"s,	c #2B2F46",
"t,	c #222851",
"u,	c #2A2B44",
"v,	c #342225",
"w,	c #301715",
"x,	c #502F2C",
"y,	c #4E282D",
"z,	c #41292D",
"A,	c #3F3738",
"B,	c #323A55",
"C,	c #252539",
"D,	c #312D42",
"E,	c #312D35",
"F,	c #34292A",
"G,	c #2B201F",
"H,	c #57382D",
"I,	c #4D3432",
"J,	c #403A3C",
"K,	c #3D353A",
"L,	c #342C3B",
"M,	c #362E36",
"N,	c #3B2D35",
"O,	c #26283C",
"P,	c #423438",
"Q,	c #343037",
"R,	c #282728",
"                                            . + @ #                                             ",
"                                          \$ % & * = -                                           ",
"                                          ; > , ' ) !                                           ",
"                                          ~ { ] ^ / (                                           ",
"                                            _ : < [ }                                           ",
"                                        | 1 2 3 4 5 6 7 8                                       ",
"                                  9 0 a b c d e f g h i j k l m                                 ",
"                          n o p q r s t u v w x y z A B C D E F G H I                           ",
"                      J K L M N O P Q R S T U V W X Y Z \`  ...+.@.#.\$.%.&.                      ",
"                *.=.-.;.>.,.'.).!.~.{.].^./.(._.:.<.[.}.|.1.2.3.4.5.6.7.8.9.0.                  ",
"                a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.A.B.%.C.D.E.F.              ",
"                G.H.I.J.K.L.M.N.O.P.Q.R.S.T.U.V.W.X.Y.Z.\`. +.+++@+#+\$+%+&+*+=+-+;+              ",
"              >+,+'+)+!+~+{+]+^+/+(+_+:+<+[+}+|+1+2+3+4+5+6+7+8+9+0+a+b+c+d+e+f+g+              ",
"              h+i+j+k+l+m+n+o+p+q+r+s+t+u+v+w+x+y+z+A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+              ",
"            P+Q+R+S+T+U+V+W+X+Y+Z+\`+ @.@+@@@#@\$@%@&@*@=@-@;@>@,@'@)@!@~@{@]@^@/@(@_@            ",
"            :@<@[@}@|@1@2@3@4@5@6@7@8@9@0@a@b@c@d@e@f@g@h@i@j@k@l@m@n@o@p@q@r@s@t@u@            ",
"          v@w@x@y@z@|@A@B@C@D@E@F@G@H@I@J@K@L@M@N@O@P@Q@R@S@T@U@V@W@X@Y@Z@\`@ #.#+#@#            ",
"          ##\$#%#&#*#*#*#*#*#=#-#;#>#,#'#)#(@!#~#{#]#^#/#(#_#:#<#[#}#|#1#2#3#4#5#6#7#8#          ",
"          9#0#a#b#*#*#*#*#b#c#d#e#f#g#h#i#j#k#l#m#n#o#p#q#r#s#t#u#v#w#x#y#z#A#B#C#D#E#          ",
"          F#G#H#I#J#|@|@|@K#L#M#N#O#P#Q#R#S#T#U#V#W#X#Y#Z#\`# \$.\$+\$@\$#\$\$\$%\$&\$*\$=\$-\$;\$>\$,\$        ",
"        '\$)\$!\$~\${\$|@|@|@|@]\$^\$/\$(\$_\$_\$:\$<\$[\$}\$|\$1\$2\$3\$4\$5\$6\$7\$8\$9\$0\$a\$b\$c\$d\$e\$f\$g\$h\$i\$j\$        ",
"        k\$l\$m\$n\$o\$p\$q\$q\$q\$r\$s\$t\$q\$u\$v\$w\$x\$y\$z\$A\$B\$C\$D\$E\$F\$G\$H\$I\$J\$K\$L\$M\$q\$q\$N\$O\$P\$Q\$R\$S\$        ",
"      T\$U\$V\$W\$X\$Y\$p\$q\$q\$q\$Z\$\`\$ %*#.%+%@%I\$N\$#%\$%%%&%*%=%-%;%>%*#,%'%)%q\$q\$q\$*#!%~%{%]%^%        ",
"      /%(%_%:%<%[%K#K#K#K#}%|%1%2%3%*#*#*#4%5%6%7%8%9%0%q\$a%N\$b%c%d%e%q\$q\$f%g%h%i%j%k%l%        ",
"      m%n%o%p%q%r%|@s%|@|@t%u%v%w%x%y%z%A%B%C%D%E%F%G%H%I%J%K%L%M%N%O%q\$q\$P%Q%R%S%T%-\$U%V%      ",
"    W%X%Y%Z%\`% &]\$p\$p\$p\$.&+&@&#&\$&%&&&*&=&-&;&>&,&'&)&!&~&{&]&^&/&(&_&:&<&[&}&|&1&2&3&4&5&6&    ",
"    7&8&9&0&S\$a&b&N\$q\$q\$N\$c&d&e&f&g&h&i&j&k&l&m&c\$n&o&p&q&r&s&t&u&v&w&x&y&z&A&B&C&C&D&E&F&G&    ",
"    H&I&>.n\$J&K&L&L&p\$x&x&M&N&O&P&Q&R&S&T&U&V&W&X&Y&Z&\`& *.*+*@*#*\$*%*N\$&***=*-*;*>*,*'*)*!*    ",
"  ~*{*]*^*/*(*_*:*<*S+]\$|@.&[*}*|*1*2*3*4*5*6*7*8*9*0*a*b*c*d*e*f*g*q\$h*i*j*k*l*m*n*n*o*p*q*    ",
"  r*s*t*u*v*w*x*y*z*<*I#|@A*q\$q\$q\$c\$B*C*D*E*F*G*H*I*J*K*L*M*N*O*N\$*#x&]\$P*Q*R*S*T*U*V*W*X*Y*    ",
"  Z*\`* =.=+=@=#=\$=h*N\$*#N\$%=q\$&=q\$x&*===-=;=>=,='=)=!=~={=]=^=/=*#*#q\$N\$K&(=_=:=<=[=}=|=1=2=    ",
"  3=4=5=6=7=8=9=9=0=N\$a=N\$N\$*#b=<*b#c=d=e=f=g=3\$h=i=j=k=l=N\$J#\$=]\$*#p\$m=n=o=p=o=q=r=s=n+t=u=    ",
"  v=w=x=y=z=A=B=n\$C=D=E=F=G=N\$H=I=J=K=L=M=N=O=P=Q=R=S=T=U=*#L&V=W=b#X=\`@Y=Z=\`= -.-+-@-#-\$-%-    ",
"    &-*-=---;->-,-'-)-!-~-{-N\$]-^-/-(-q\$q\$_-:-<-[-}-8\$*#q\$q\$|-1-2-3-4-5-6-7-8-9-0-a-b-c-d-e-    ",
"      f-g-h-i-j-J&k-l-m-N\$*#q\$n-o-p-q-r-N\$q\$q\$q\$q\$q\$q\$*#s-*#/=t-u-v-w-x-y-z-^#A-B-/@C-D-        ",
"        E-F-G-H-I-J-K-K#b#p\$b#L-M-N-O-P-Q-R-S-T-U-V-W-X-Y-N\$Z-\`- ;.;+;@;#;\$;%;&;*;=;-;;;        ",
"        >;,;';);!;~;{;];];^;S+/;(;_;:;<;[;};|;1;2;3;4;5;6;7;8;9;0;a;b;c;d;e;f;g;h;i;j;k;        ",
"          l;m;n;o;p;q;r;s;t;S+  u;v;w;x;y;z;A;B;C;D;E;F;G;H;I;J;K;L;M;N;O;P;Q;R;S;T;U;          ",
"          V;W;X;Y;Z;H-\`;[%K#*#     >.>+>@>#>\$>%>&>*>=>->;>>>,>'>  )>)>!>O+~>{>]>^>/>(>          ",
"            _>:><>[>}>|>1>2>3>      4>5>6>7>8>9>0>a>b>c>d>e>f>    g>\$+h>i>j>k>l>^>m>n>          ",
"            o>p>R*q>r>s>/*t>u>        v>w>x>y>z>A>B>C>D>E>        F>G>H>I>J>K>L>M>N>            ",
"            O>P>Q>R>S>T>T>U>V>          W>X>Y>Z>\`> ,.,+,          @,#,\$,%,&,*,=,-,              ",
"            ;,>,,,',),!,~,{,],              ^,/,(,_,:,            <,[,},|,1,2,3,4,              ",
"              5,6,7,-*8,9,B=0,                                    a,b,c,d,e,f,g,                ",
"                h,i,j,k,m*l,m,                                    n,o,p,q,r,s,                  ",
"                  t,u,v,R>R>w,                                    x,y,z,A,B,C,                  ",
"                      D,E,F,G,                                    H,I,J,K,L,                    ",
"                        M,N,O,                                    P,Q,R,                        "};
_EOF_
}
