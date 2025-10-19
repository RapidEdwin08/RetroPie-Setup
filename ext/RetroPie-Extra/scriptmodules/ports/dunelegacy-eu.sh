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

rp_module_id="dunelegacy-eu"
rp_module_desc="Enhanced Port for Dune II The Battle for Arrakis (EU)"
rp_module_help="Place Dune II Data Files in [ports/dune2/dunelegacy-eu]:\n $romdir/ports/dune2/dunelegacy-eu"
#rp_module_licence="GNU 2.0 https://sourceforge.net/p/dunedynasty/dunedynasty/ci/master/tree/COPYING"
#rp_module_repo="git git://dunelegacy.git.sourceforge.net/gitroot/dunelegacy/dunelegacy master"
##rp_module_licence="GNU 2.0 https://raw.githubusercontent.com/Shazwazza/DuneLegacy/refs/heads/develop/COPYING"
##rp_module_repo="git https://github.com/Shazwazza/DuneLegacy.git develop"
rp_module_licence="GNU 2.0 https://raw.githubusercontent.com/jvaltane/dunelegacy/refs/heads/master/COPYING" #v0.97.02
rp_module_repo="git https://github.com/jvaltane/dunelegacy master"
rp_module_section="exp"
rp_module_flags="!mali"

function depends_dunelegacy-eu() {
    local depends=(autotools-dev libsdl2-mixer-dev libopusfile0 libsdl2-mixer-2.0-0 libsdl2-ttf-dev libfluidsynth-dev fluidsynth)
    if [[ $(apt-cache search libfluidsynth3) == '' ]]; then
    	depends+=(libfluidsynth1)
    else
    	depends+=(libfluidsynth3)
    fi
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
	getDepends "${depends[@]}"
}

function sources_dunelegacy-eu() {
    gitPullOrClone
}

function build_dunelegacy-eu() {
	sed -i "/*Mix_Init(MIX_INIT_FLUIDSYNTH | MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG)/c\\Mix_Init(MIX_INIT_MID | MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG)" $md_build/src/FileClasses/music/DirectoryPlayer.cpp
	sed -i "/if((Mix_Init(MIX_INIT_FLUIDSYNTH) & MIX_INIT_FLUIDSYNTH) == 0) {/c\\if((Mix_Init(MIX_INIT_MID) & MIX_INIT_MID) == 0) {" $md_build/src/FileClasses/music/XMIPlayer.cpp
	
	if [[ "$__os_debian_ver" -ge 11 ]]; then
		# Bookworm error: field ‘mentatStrings’ has incomplete type ‘std::array<std::unique_ptr<MentatTextFile>, 3>’
		sed -i '1s/^/#include <tuple> \n/' $md_build/src/FileClasses/TextManager.cpp
		sed -i '1s/^/#include <array> \n/' $md_build/src/FileClasses/TextManager.cpp

		# Flickering fix -> Comment 1st instance of  // SDL_RenderPresent(renderer);
		##sed -i 's+SDL_RenderPresent(renderer);+//SDL_RenderPresent(renderer);+g' $md_build/src/Game.cpp
		sed '0,/SDL_RenderPresent(renderer);/s//\/\/SDL_RenderPresent(renderer);/' $md_build/src/Game.cpp > /dev/shm/Game.cpp; sudo mv /dev/shm/Game.cpp $md_build/src/Game.cpp
	fi
	
    if [[ "$__os_debian_ver" -le 10 ]]; then
		params=(--prefix="$md_inst" --with-asound --without-pulse --with-sdl2)
	else
		params=(--prefix="$md_inst")
	fi

	# Hard Code [XDG_CONFIG_HOME/$md_id] DIR # ChangeLog * Linux: Save configuration files to $XDG_CONFIG_HOME/dunelegacy if set; otherwise ~/.config/dunelegacy is used
	sed -i s+getenv\(\"XDG_CONFIG_HOME\"\)+\"$home/.config/$md_id\"+ $md_build/src/misc/fnkdat.cpp

	echo [PARAMS]: ${params[@]}
    autoreconf --install
    ./configure "${params[@]}"
    make -j"$(nproc)"
    md_ret_require=(
        "$md_build/src/dunelegacy"
    )
}

function install_dunelegacy-eu() {
    make install
    md_ret_files=(
        'dunelegacy.svg'
    )
}

function game_data_dunelegacy-eu() {
    if [[ ! -f "$romdir/ports/dune2/data/DUNE2.EXE" ]] && [[ ! -f "$romdir/ports/dune2/data/Dune2.EXE" ]]; then
		mkRomDir "ports/dune2/$md_id"
		downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/$md_id-rp-assets.tar.gz" "$romdir/ports/dune2/$md_id"
		chown -R $__user:$__user "$romdir/ports/dune2/$md_id"
	fi
}

function remove_dunelegacy-eu() {
    local shortcut_name
    shortcut_name="Dune II The Battle for Arrakis"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name.sh"
}

function gui_dunelegacy-eu() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      Get Additional Desktop Shortcuts + Icons\n\nGet Desktop Shortcuts for Additional Episodes + Add-Ons that may not have been present at Install\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "Get Shortcuts + Icons" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            game_data_dunelegacy-eu
            shortcuts_icons_dunelegacy-eu
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_dunelegacy-eu() {
    mkRomDir "ports/dune2/$md_id"
    chown -R $__user:$__user "$romdir/ports/dune2"

    moveConfigDir "$home/.config/$md_id" "$md_conf_root/$md_id"
    if [[ ! -d "$md_conf_root/$md_id/dunelegacy" ]]; then mkdir "$md_conf_root/$md_id/dunelegacy"; fi
    if [[ -d "$md_conf_root/$md_id/dunelegacy/data" ]] && [[ "$(readlink "$md_conf_root/$md_id/dunelegacy/data")" == '' ]]; then # Move files if Not symbolic link
		mv "$md_conf_root/$md_id/dunelegacy/data/*" "$home/RetroPie/roms/ports/dune2/$md_id"
		chown -R $__user:$__user "$romdir/ports/dune2/$md_id"
		rm -Rf "$md_conf_root/$md_id/dunelegacy/data"
	fi
    if [[ ! -d "$md_conf_root/$md_id/dunelegacy/data" ]]; then ln -s "$home/RetroPie/roms/ports/dune2/$md_id" "$md_conf_root/$md_id/dunelegacy/data"; fi
    chown -R $__user:$__user "$md_conf_root/$md_id"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    if (isPlatform "rpi"*) && [[ "$__os_debian_ver" -le 10 ]]; then launch_prefix="XINIT:"; fi
    addPort "$md_id" "$md_id" "Dune II The Battle for Arrakis" "$launch_prefix$md_inst/bin/dunelegacy"
	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "$md_id" "Dune II The Battle for Arrakis" "$launch_prefix$md_inst/$md_id-qjoy.sh"
	fi

    cat >"$md_inst/Dune Legacy.ini" << _EOF_
[General]
Play Intro = true          # Play the intro when starting the game?
Player Name = Pi            # The name of the player
Language = en               # en = English, fr = French, de = German
Scroll Speed = 50           # Amount to scroll the map when the cursor is near the screen border
Show Tutorial Hints = true  # Show tutorial hints during the game

[Video]
# Minimum resolution is 640x480
Width = 960
Height = 540
Physical Width = 1920
Physical Height = 1080
Fullscreen = true
FrameLimit = true           # Limit the frame rate to save energy?
Preferred Zoom Level = 1    # 0 = no zooming, 1 = 2x, 2 = 3x
Scaler = ScaleHD            # Scaler to use: ScaleHD = apply manual drawn mask to upscale, Scale2x = smooth edges, ScaleNN = nearest neighbour, 
RotateUnitGraphics = false  # Freely rotate unit graphics, e.g. carryall graphics

[Audio]
# There are three different possibilities to play music
#  adl       - This option will use the Dune 2 music as used on e.g. SoundBlaster16 cards
#  xmi       - This option plays the xmi files of Dune 2. Sounds more midi-like
#  directory - Plays music from the "music"-directory inside your configuration directory
#              The "music"-directory should contain 5 subdirectories named attack, intro, peace, win and lose
#              Put any mp3, ogg or mid file there and it will be played in the particular situation
Music Type = adl
Play Music = true
Music Volume = 64           # Volume between 0 and 128
Play SFX = true
SFX Volume = 64             # Volume between 0 and 128

[Network]
ServerPort = 28747
MetaServer = http://dunelegacy.sourceforge.net/metaserver/metaserver.php

[AI]
Campaign AI = qBotMedium

[Game Options]
Game Speed = 26                         # The default speed of the game: 32 = very slow, 8 = very fast, 16 = default
Concrete Required = true                # If true building on bare rock will result in 50% structure health penalty
Structures Degrade On Concrete = true   # If true structures will degrade on power shortage even if built on concrete
Fog of War = false                      # If true explored terrain will become foggy when no unit or structure is next to it
Start with Explored Map = false         # If true the complete map is unhidden at the beginning of the game
Instant Build = false                   # If true the building of structures and units does not take any time
Only One Palace = false                 # If true, only one palace can be build per house
Rocket-Turrets Need Power = false       # If true, rocket turrets are dysfunctional on power shortage
Sandworms Respawn = false               # If true, killed sandworms respawn after some time
Killed Sandworms Drop Spice = false     # If true, killed sandworms drop some spice
Manual Carryall Drops = false           # If true, player can request carryall to transport units
Maximum Number of Units Override = -1   # Override the maximum number of units each house is allowed to build (-1 = do not override)
_EOF_
	if [[ ! -f "$md_conf_root/$md_id/dunelegacy/Dune Legacy.ini" ]]; then cp "$md_inst/Dune Legacy.ini" "$md_conf_root/$md_id/dunelegacy/Dune Legacy.ini"; fi
	sed -i s+Play\ Intro\ =.*+Play\ Intro\ =\ true+ "$md_conf_root/$md_id/dunelegacy/Dune Legacy.ini"
	chown $__user:$__user "$md_conf_root/$md_id/dunelegacy/Dune Legacy.ini"

   cat >"$md_inst/$md_id-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Dune II"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
	Axis 1: gradient, dZone 5768, maxSpeed 3, tCurve 0, mouse+h
	Axis 2: gradient, dZone 4615, maxSpeed 3, tCurve 0, mouse+v
	Axis 3: +key 111, -key 0
	Axis 4: gradient, dZone 6461, maxSpeed 15, tCurve 0, mouse+h
	Axis 5: gradient, dZone 6230, maxSpeed 15, tCurve 0, mouse+v
	Axis 6: +key 116, -key 0
	Axis 7: gradient, maxSpeed 2, tCurve 0, mouse+h
	Axis 8: gradient, maxSpeed 2, tCurve 0, mouse+v
	Button 1: mouse 1
	Button 2: mouse 3
	Button 3: mouse 1
	Button 4: mouse 3
	Button 5: mouse 1
	Button 6: mouse 3
	Button 7: key 9
	Button 8: key 36
	Button 9: key 9
	Button 10: mouse 1
	Button 11: mouse 3
	Button 12: key 113
	Button 13: key 114
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

# Run Dune
/opt/retropie/ports/$md_id/bin/dunelegacy

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/$md_id-qjoy.sh"

    [[ "$md_mode" == "install" ]] && game_data_dunelegacy-eu
    [[ "$md_mode" == "install" ]] && shortcuts_icons_dunelegacy-eu
    [[ "$md_mode" == "remove" ]] && remove_dunelegacy-eu
}

function shortcuts_icons_dunelegacy-eu() {
    local shortcut_name
    shortcut_name="Dune II The Battle for Arrakis"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/bin/dunelegacy
Icon=$md_inst/DuneII_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=D2;DuneII;Battle;Arrakis
StartupWMClass=DuneIITheBattleForArrakis
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/DuneII_48x48.xpm" << _EOF_
/* XPM */
static char * DuneII_48x48_xpm[] = {
"48 48 613 2",
"  	c None",
". 	c #3981F7",
"+ 	c #2F7EEF",
"@ 	c #227AE0",
"# 	c #1C7AD7",
"\$ 	c #1878D2",
"% 	c #1973C5",
"& 	c #1972C1",
"* 	c #1972C5",
"= 	c #227EDF",
"- 	c #307FEF",
"; 	c #3081ED",
"> 	c #1C79D6",
", 	c #246DA9",
"' 	c #3F637B",
") 	c #5B5A58",
"! 	c #6C523F",
"~ 	c #784C2A",
"{ 	c #754827",
"] 	c #714525",
"^ 	c #6C4223",
"/ 	c #653F23",
"( 	c #534235",
"_ 	c #40494D",
": 	c #295574",
"< 	c #1966A4",
"[ 	c #1C78D7",
"} 	c #307EEB",
"| 	c #2C7FE9",
"1 	c #1A75C7",
"2 	c #426780",
"3 	c #745B47",
"4 	c #8B562F",
"5 	c #89552F",
"6 	c #87532E",
"7 	c #84512D",
"8 	c #804F2B",
"9 	c #7B4C29",
"0 	c #764927",
"a 	c #663E20",
"b 	c #613A1E",
"c 	c #5B361C",
"d 	c #553319",
"e 	c #413933",
"f 	c #225374",
"g 	c #1672C7",
"h 	c #2E7DE9",
"i 	c #337FF1",
"j 	c #1B77D0",
"k 	c #446882",
"l 	c #875D3E",
"m 	c #925B32",
"n 	c #915A32",
"o 	c #8F5831",
"p 	c #8D5730",
"q 	c #88542E",
"r 	c #86522D",
"s 	c #814F2B",
"t 	c #7C4C29",
"u 	c #774927",
"v 	c #6C4123",
"w 	c #603A1E",
"x 	c #59351B",
"y 	c #533118",
"z 	c #4C2D16",
"A 	c #402F20",
"B 	c #1E5073",
"C 	c #1A78D2",
"D 	c #3480F3",
"E 	c #2A7DE6",
"F 	c #2570AF",
"G 	c #7C624E",
"H 	c #995F35",
"I 	c #985E35",
"J 	c #965D34",
"K 	c #955C33",
"L 	c #935B33",
"M 	c #8E5831",
"N 	c #8C5630",
"O 	c #86532D",
"P 	c #82502C",
"Q 	c #764827",
"R 	c #704525",
"S 	c #6A4122",
"T 	c #643D1F",
"U 	c #5E381D",
"V 	c #57341A",
"W 	c #503017",
"X 	c #4A2B15",
"Y 	c #432712",
"Z 	c #303130",
"\` 	c #1265A8",
" .	c #2B7DE6",
"..	c #267DE3",
"+.	c #3D6D91",
"@.	c #97643D",
"#.	c #9E6237",
"\$.	c #9D6237",
"%.	c #9C6136",
"&.	c #9A6036",
"*.	c #975E34",
"=.	c #945C33",
"-.	c #8F5931",
";.	c #8C5730",
">.	c #81502B",
",.	c #6F4424",
"'.	c #683F21",
").	c #623B1F",
"!.	c #5B371C",
"~.	c #543219",
"{.	c #4D2E16",
"].	c #462913",
"^.	c #3F2410",
"/.	c #352315",
"(.	c #155483",
"_.	c #247ADF",
":.	c #227ADE",
"<.	c #4A6B85",
"[.	c #A2663A",
"}.	c #A36639",
"|.	c #A26539",
"1.	c #A16539",
"2.	c #A06438",
"3.	c #9E6337",
"4.	c #985F35",
"5.	c #955D34",
"6.	c #905931",
"7.	c #7A4B28",
"8.	c #734626",
"9.	c #6D4223",
"0.	c #5F391D",
"a.	c #58351B",
"b.	c #513018",
"c.	c #422712",
"d.	c #3B220F",
"e.	c #341E0D",
"f.	c #164A71",
"g.	c #237DDF",
"h.	c #267AE1",
"i.	c #436F8D",
"j.	c #A6693C",
"k.	c #A7693B",
"l.	c #A6683B",
"m.	c #A5683A",
"n.	c #A4673A",
"o.	c #84522D",
"p.	c #7E4D2A",
"q.	c #6A4022",
"r.	c #633C1F",
"s.	c #4D2D16",
"t.	c #452913",
"u.	c #3E2410",
"v.	c #371F0D",
"w.	c #2F1A0B",
"x.	c #134E77",
"y.	c #277DE3",
"z.	c #307EEC",
"A.	c #35719D",
"B.	c #A96B3E",
"C.	c #AC6C3D",
"D.	c #AB6C3D",
"E.	c #AB6B3C",
"F.	c #AA6A3C",
"G.	c #A8693B",
"H.	c #9F6338",
"I.	c #9C6137",
"J.	c #744726",
"K.	c #502F17",
"L.	c #482A14",
"M.	c #412511",
"N.	c #39200E",
"O.	c #311B0B",
"P.	c #2A170A",
"Q.	c #105991",
"R.	c #307FEC",
"S.	c #3580F6",
"T.	c #2075BC",
"U.	c #A06F49",
"V.	c #B06E3E",
"W.	c #B06F3F",
"X.	c #B06E3F",
"Y.	c #AF6E3E",
"Z.	c #AE6D3E",
"\`.	c #AA6B3C",
" +	c #A5673A",
".+	c #A26639",
"++	c #8D5830",
"@+	c #85522D",
"#+	c #7F4E2A",
"\$+	c #784927",
"%+	c #704424",
"&+	c #694021",
"*+	c #623B1E",
"=+	c #5A361B",
"-+	c #523118",
";+	c #4B2C15",
">+	c #341D0C",
",+	c #2C1808",
"'+	c #221D17",
")+	c #126AB8",
"!+	c #3A82F5",
"~+	c #217ADC",
"{+	c #76706A",
"]+	c #B37040",
"^+	c #B47140",
"/+	c #B57241",
"(+	c #B37140",
"_+	c #B2703F",
":+	c #A96A3C",
"<+	c #A6683A",
"[+	c #9B6136",
"}+	c #87542E",
"|+	c #7B4B29",
"1+	c #643D20",
"2+	c #5D381C",
"3+	c #452813",
"4+	c #3E2310",
"5+	c #361E0C",
"6+	c #2E1909",
"7+	c #261406",
"8+	c #193547",
"9+	c #217CDD",
"0+	c #347FF3",
"a+	c #3572A0",
"b+	c #B67241",
"c+	c #B77342",
"d+	c #B97442",
"e+	c #B97542",
"f+	c #B87442",
"g+	c #B67341",
"h+	c #925A32",
"i+	c #7D4D2A",
"j+	c #6E4324",
"k+	c #673E21",
"l+	c #4F2F17",
"m+	c #472A14",
"n+	c #3F2510",
"o+	c #381F0D",
"p+	c #301A0A",
"q+	c #281507",
"r+	c #261407",
"s+	c #115D96",
"t+	c #3681F1",
"u+	c #1F79DA",
"v+	c #8B7360",
"w+	c #BA7543",
"x+	c #BC7643",
"y+	c #BD7744",
"z+	c #BE7844",
"A+	c #B27040",
"B+	c #784A28",
"C+	c #492B14",
"D+	c #412611",
"E+	c #291607",
"F+	c #1D2D36",
"G+	c #207ADB",
"H+	c #3B82F6",
"I+	c #2E73AC",
"J+	c #BC7644",
"K+	c #BE7845",
"L+	c #C07945",
"M+	c #C17A46",
"N+	c #C27A46",
"O+	c #BB7643",
"P+	c #9A6035",
"Q+	c #7A4B29",
"R+	c #724625",
"S+	c #6B4122",
"T+	c #3A210E",
"U+	c #321C0B",
"V+	c #2A1708",
"W+	c #1161A1",
"X+	c #357FF5",
"Y+	c #297EE7",
"Z+	c #6C7478",
"\`+	c #C27B46",
" @	c #C57C47",
".@	c #C67D48",
"+@	c #C77D48",
"@@	c #C57D47",
"#@	c #C47C47",
"\$@	c #BF7845",
"%@	c #643C1F",
"&@	c #5C371C",
"*@	c #4C2D15",
"=@	c #442712",
"-@	c #331D0B",
";@	c #2B1708",
">@	c #173E58",
",@	c #2B7DE7",
"'@	c #1A7AD7",
")@	c #A97854",
"!@	c #C97F49",
"~@	c #CA8049",
"{@	c #CB804A",
"]@	c #CA7F49",
"^@	c #C87E48",
"/@	c #B77341",
"(@	c #8A552F",
"_@	c #6D4323",
":@	c #653D20",
"<@	c #5D381D",
"[@	c #442813",
"}@	c #3C230F",
"|@	c #21201E",
"1@	c #1B78D6",
"2@	c #2975B6",
"3@	c #C77E48",
"4@	c #CA804A",
"5@	c #CD824B",
"6@	c #CF834B",
"7@	c #D0834C",
"8@	c #CE824B",
"9@	c #B57546",
"0@	c #96643E",
"a@	c #B77444",
"b@	c #AB6B3D",
"c@	c #A7683B",
"d@	c #56331A",
"e@	c #3D230F",
"f@	c #351E0C",
"g@	c #2C1809",
"h@	c #126AB0",
"i@	c #3882F8",
"j@	c #477597",
"k@	c #CE834B",
"l@	c #D1854C",
"m@	c #D3864D",
"n@	c #D4864D",
"o@	c #765C47",
"p@	c #5A5854",
"q@	c #4B4A47",
"r@	c #383632",
"s@	c #724C32",
"t@	c #B16F3F",
"u@	c #9D6337",
"v@	c #996035",
"w@	c #905932",
"x@	c #8B5630",
"y@	c #86532E",
"z@	c #7F4E2B",
"A@	c #5E391D",
"B@	c #4E2E16",
"C@	c #3D2310",
"D@	c #2D1809",
"E@	c #125483",
"F@	c #3A83F8",
"G@	c #3280EF",
"H@	c #647883",
"I@	c #D2854C",
"J@	c #D5874E",
"K@	c #D8894F",
"L@	c #956948",
"M@	c #726F6B",
"N@	c #706D69",
"O@	c #575552",
"P@	c #3C3B39",
"Q@	c #2B2927",
"R@	c #9A633A",
"S@	c #AD6D3D",
"T@	c #A7683C",
"U@	c #A16439",
"V@	c #9B6036",
"W@	c #965E35",
"X@	c #945C34",
"Y@	c #8F5A32",
"Z@	c #144565",
"\`@	c #327FEE",
" #	c #2B7EE8",
".#	c #777877",
"+#	c #CB814A",
"@#	c #D0844C",
"##	c #D4874E",
"\$#	c #DC8C51",
"%#	c #DD8C51",
"&#	c #755D4C",
"*#	c #787471",
"=#	c #716E6B",
"-#	c #3B3A38",
";#	c #292826",
">#	c #644229",
",#	c #AC6C3E",
"'#	c #A06539",
")#	c #915A33",
"!#	c #885530",
"~#	c #87542F",
"{#	c #8C5831",
"]#	c #8E5931",
"^#	c #173B51",
"/#	c #2B80EA",
"(#	c #287EE5",
"_#	c #837971",
":#	c #CD814A",
"<#	c #D6884E",
"[#	c #DB8B50",
"}#	c #DF8E52",
"|#	c #E18F53",
"1#	c #775B45",
"2#	c #615F5C",
"3#	c #5D5A57",
"4#	c #4A4845",
"5#	c #343331",
"6#	c #242322",
"7#	c #724A2D",
"8#	c #B17040",
"9#	c #8E5933",
"0#	c #83512E",
"a#	c #7D4E2C",
"b#	c #7B4C2B",
"c#	c #7C4E2B",
"d#	c #88552F",
"e#	c #8A5530",
"f#	c #6F4324",
"g#	c #193648",
"h#	c #287DE5",
"i#	c #297DE4",
"j#	c #837A71",
"k#	c #D2854D",
"l#	c #D7884F",
"m#	c #E08E52",
"n#	c #E28F53",
"o#	c #BC7A4A",
"p#	c #4A4643",
"q#	c #444340",
"r#	c #363533",
"s#	c #2A2928",
"t#	c #26211C",
"u#	c #B47141",
"v#	c #9F6438",
"w#	c #7F502C",
"x#	c #7B4C2A",
"y#	c #784B29",
"z#	c #774A29",
"A#	c #81502C",
"B#	c #85532D",
"C#	c #442812",
"D#	c #3C220F",
"E#	c #287EE4",
"F#	c #2B80E7",
"G#	c #797976",
"H#	c #DA8A50",
"I#	c #DD8D51",
"J#	c #A76C42",
"K#	c #4B3B2E",
"L#	c #362D27",
"M#	c #463325",
"N#	c #A96C3E",
"O#	c #9C6237",
"P#	c #86542F",
"Q#	c #7F4F2C",
"R#	c #7A4C2A",
"S#	c #764929",
"T#	c #754928",
"U#	c #7F4F2B",
"V#	c #331C0B",
"W#	c #173A51",
"X#	c #2B7DE8",
"Y#	c #317FED",
"Z#	c #667782",
"\`#	c #D98A4F",
" \$	c #CC814A",
".\$	c #C37B46",
"+\$	c #B97543",
"@\$	c #AE6E3E",
"#\$	c #A06439",
"\$\$	c #7F4F2D",
"%\$	c #7A4C2B",
"&\$	c #82512D",
"*\$	c #4A2C15",
"=\$	c #422612",
"-\$	c #144260",
";\$	c #3781F6",
">\$	c #4C7594",
",\$	c #D1844C",
"'\$	c #BC7744",
")\$	c #AD6E3E",
"!\$	c #84522E",
"~\$	c #7D4E2B",
"{\$	c #7C4D2B",
"]\$	c #89552E",
"^\$	c #83512C",
"/\$	c #38200E",
"(\$	c #301B0A",
"_\$	c #11527E",
":\$	c #3980F8",
"<\$	c #2D74B0",
"[\$	c #AD6C3D",
"}\$	c #8F5932",
"|\$	c #8D5831",
"1\$	c #8B5730",
"2\$	c #794A28",
"3\$	c #58341A",
"4\$	c #2E1A09",
"5\$	c #1163A8",
"6\$	c #1A79D3",
"7\$	c #B27B52",
"8\$	c #C87F49",
"9\$	c #BF7945",
"0\$	c #965E34",
"a\$	c #7E4E2A",
"b\$	c #1A78D5",
"c\$	c #287BE2",
"d\$	c #767674",
"e\$	c #C37B47",
"f\$	c #A4663A",
"g\$	c #84512C",
"h\$	c #533219",
"i\$	c #183950",
"j\$	c #277BE5",
"k\$	c #3982F6",
"l\$	c #3774A3",
"m\$	c #115D97",
"n\$	c #3981F6",
"o\$	c #95755B",
"p\$	c #361E0D",
"q\$	c #1F262A",
"r\$	c #1C78D6",
"s\$	c #3182EF",
"t\$	c #407398",
"u\$	c #724525",
"v\$	c #115588",
"w\$	c #3381F0",
"x\$	c #1C77D7",
"y\$	c #877060",
"z\$	c #89542F",
"A\$	c #402511",
"B\$	c #38200D",
"C\$	c #1D2D37",
"D\$	c #1F7BD9",
"E\$	c #3882F4",
"F\$	c #2671B3",
"G\$	c #A96F45",
"H\$	c #351D0C",
"I\$	c #24190F",
"J\$	c #1066AB",
"K\$	c #3783F4",
"L\$	c #2C80E9",
"M\$	c #437192",
"N\$	c #663D20",
"O\$	c #12527E",
"P\$	c #2C7DE6",
"Q\$	c #1F7CDF",
"R\$	c #596D7A",
"S\$	c #613B1E",
"T\$	c #2D1909",
"U\$	c #154361",
"V\$	c #1F77D9",
"W\$	c #5D6A72",
"X\$	c #975E35",
"Y\$	c #5C381C",
"Z\$	c #4E2E17",
"\`\$	c #311B0A",
" %	c #173D58",
".%	c #1F78DA",
"+%	c #217CDC",
"@%	c #4E6A80",
"#%	c #9B6238",
"\$%	c #935C33",
"%%	c #513017",
"&%	c #261508",
"*%	c #14476A",
"=%	c #247DE1",
"-%	c #2F6E9D",
";%	c #885F42",
">%	c #734625",
",%	c #24201A",
"'%	c #115992",
")%	c #267CE0",
"!%	c #2C7DEC",
"~%	c #1B73C5",
"{%	c #53636E",
"]%	c #8C5A34",
"^%	c #784928",
"/%	c #472913",
"(%	c #311E0F",
"_%	c #1A3F58",
":%	c #146FC4",
"<%	c #2C80EE",
"[%	c #3885F5",
"}%	c #267EE3",
"|%	c #1E71B6",
"1%	c #4F606B",
"2%	c #7E5437",
"3%	c #673E20",
"4%	c #553219",
"5%	c #37281B",
"6%	c #1E4158",
"7%	c #1268B3",
"8%	c #267BE3",
"9%	c #3584F7",
"0%	c #1975CB",
"a%	c #2E6691",
"b%	c #485A65",
"c%	c #604E40",
"d%	c #6D4527",
"e%	c #4D311A",
"f%	c #3C3731",
"g%	c #284658",
"h%	c #18598A",
"i%	c #1573CA",
"j%	c #277BE3",
"k%	c #3985F7",
"l%	c #377FF4",
"m%	c #297FE6",
"n%	c #1D78D9",
"o%	c #1877CE",
"p%	c #1B6FB6",
"q%	c #1D68A6",
"r%	c #1D659F",
"s%	c #1B66A5",
"t%	c #186EB5",
"u%	c #1D7AD9",
"v%	c #3580F4",
"                                                                                                ",
"                                                                                                ",
"                                                                                                ",
"                                    . + @ # \$ % & * \$ # = - .                                   ",
"                                ; > , ' ) ! ~ { ] ^ / ( _ : < [ }                               ",
"                            | 1 2 3 4 5 6 7 8 9 0 ] ^ a b c d e f g h                           ",
"                        i j k l m n o p 4 q r s t u ] v a w x y z A B C D                       ",
"                      E F G H I J K L n M N 5 O P t Q R S T U V W X Y Z \`  .                    ",
"                    ..+.@.#.\$.%.&.H *.=.m -.;.5 O >.9 { ,.'.).!.~.{.].^./.(._.                  ",
"                  :.<.[.}.|.1.2.3.\$.&.4.5.L 6.;.5 r 8 7.8.9.a 0.a.b.X c.d.e.f.g.                ",
"                h.i.j.k.k.l.m.n.|.2.3.%.H J L -.;.q o.p.u R q.r.!.~.s.t.u.v.w.x.y.              ",
"              z.A.B.C.C.D.E.F.G.l.n.|.H.I.H J m o 4 6 P 9 J.9.a 0.V K.L.M.N.O.P.Q.R.            ",
"            S.T.U.V.W.W.X.Y.Z.C.\`.G. +.+H.%.H 5.n ++5 @+#+\$+%+&+*+=+-+;+Y d.>+,+'+)+!+          ",
"            ~+{+]+^+/+/+^+(+_+W.Z.D.:+<+|.H.[+I =.6.N }+P |+8.^ 1+2+d {.3+4+5+6+7+8+9+          ",
"          0+a+b+c+d+e+e+d+f+g+^+_+Y.C.:+ +|.#.&.J h+M 5 @+i+Q j+k+0.V l+m+n+o+p+q+r+s+t+        ",
"          u+v+w+x+y+z+z+y+x+w+f+/+A+Y.C.G.n.2.%.4.=.-.4 6 8 B+] &+b x b.C+D+N.O.E+7+F+G+        ",
"        H+I+J+K+L+M+N+N+M+L+z+O+d+/+_+Z.\`.l.|.3.P+5.n ;.q P Q+R+S+r.c y ;+c.T+U+V+7+7+W+X+      ",
"        Y+Z+L+\`+ @.@+@.@@@#@N+\$@x+f+^+W.C.G.n.2.[+*.m M 5 7 t J.^ %@&@~.*@=@d.-@;@7+7+>@,@      ",
"        '@)@#@+@!@~@{@{@]@^@ @N+K+O+/@]+Z.\`.<+1.\$.4.L o (@@+p.{ _@:@<@d s.[@}@>+,+7+7+|@1@      ",
"        2@#@3@4@5@6@7@6@8@9@0@a@M+y+d+^+X.b@c@|.#.H =.-.4 O #+Q j+a U d@{.3+e@f@g@7+7+7+h@      ",
"      i@j@3@{@k@l@m@n@m@o@p@q@r@s@\$@w+b+t@C.G..+u@v@K w@x@y@z@u ,.k+A@d@B@t.C@f@D@7+7+7+E@F@    ",
"      G@H@!@8@I@J@K@K@L@M@N@O@P@Q@R@O+/@_+S@T@U@V@W@X@Y@N 6 8 u ,.k+A@d@B@].C@f@D@7+7+7+Z@\`@    ",
"       #.#+#@###K@\$#%#&#*#=#O@-#;#>#J+c+A+,#'#)#!#~#{#]#N 6 8 u ,.k+A@d@B@3+e@f@g@7+7+7+^#/#    ",
"      (#_#:#l@<#[#}#|#1#2#3#4#5#6#7#J+c+8#j.9#0#a#b#c#d#e#6 z@u f#a A@d@{.3+e@>+,+7+7+7+g#h#    ",
"      i#j#5@k#l#[#m#n#o#p#q#r#s#t#u#x+/@Y.v#~#w#x#y#z#A#q B##+Q j+a <@d s.C#D#>+;@7+7+7+8+E#    ",
"      F#G#:#l@<#H#%#I#[#J#K#L#M#N#L+O+/+Z.O#P#Q#R#S#T#U#}+@+p.{ 9.:@&@~.*@Y d.V#V+7+7+7+W#X#    ",
"      Y#Z#+#7@n@l#\`#\`#l#n@@# \$3@.\$z++\$/+@\$#\$!#\$\$%\$z#z#&\$q @+t J.v r.!.y *\$=\$T+O.E+7+7+7+-\$\`@    ",
"      ;\$>\$!@5@,\$m@####m@@#5@!@ @M+'\$f+(+)\$l.X@!\$~\${\$A#]\$q ^\$|+R+q.).=+b.C+M./\$(\$q+7+7+7+_\$:\$    ",
"        <\$3@~@5@6@@#@#6@ \$!@.@\`+z+w+b+t@[\$k.#\$I }\$|\$M 1\$}+s 2\$R '.w 3\$l+m+^.v.4\$7+7+7+7+5\$      ",
"        6\$7\$3@!@{@ \$+#~@8\$.@.\$9\$O+c+(+Y.E.l.1.I.0\$L ]#4 O a\$Q j+a U d@{.3+e@f@D@7+7+7+'+b\$      ",
"        c\$d\$e\$@@3@3@3@.@#@N+\$@x+f+^+W.C.G.f\$v#[+*.m ++5 g\$t J.v r.!.h\$;+Y d.V#;@7+7+7+i\$j\$      ",
"        k\$l\$9\$M+\`+.\$\`+N+L+z+O+f+/+t@Z.F.<+1.\$.H =.6.x@6 8 2\$] &+b x b.C+M./\$(\$q+7+7+7+m\$n\$      ",
"          [ o\$y+z+K+z+y+x+w+c+^+t@Z.\`.c@}.H.V@J m M 5 @+i+{ _@a U d@B@].u.p\$6+7+7+7+q\$r\$        ",
"          s\$t\$d+w+w+w+d+c+/+(+t@Z.\`.k.}.2.%.I =.6.x@6 s 2\$u\$q.).c y ;+Y d.V#;@7+7+7+v\$w\$        ",
"            x\$y\$/+/+/+^+]+t@Y.[\$F.c@f\$2.\$.H 5.n p z\$7 i+{ j+a 0.V l+L.A\$B\$p+q+7+7+C\$D\$          ",
"            E\$F\$G\$t@t@X.Y.[\$b@:+l.}.2.\$.H J m M (@O 8 B+] q.).!.h\$*@C#}@H\$D@7+7+I\$J\$K\$          ",
"              L\$M\$C.C.b@\`.:+c@ +|.H.I.H J m o 4 6 P |+J.9.N\$A@V l+L.A\$N.O.E+7+7+O\$P\$            ",
"                Q\$R\$G.c@<+n..+2.3.[+H J m -.x@q ^\$i+Q ,.'.S\$=+y ;+=@}@f@T\$7+7+U\$@               ",
"                  V\$W\$|.1.2.3.I.&.X\$K h+o x@q 7 p.u ] S r.Y\$d Z\$m+A\$/\$\`\$E+7+ %.%                ",
"                    +%@%#%[+&.4.J \$%n M 4 q 7 a\$B+R+v :@A@3\$%%X c.d.>+D@&%*%u+                  ",
"                      =%-%;%J =.h+-.p (@6 g\$a\$B+>%^ a w x y *@3+u.v.p+,%'%)%                    ",
"                        !%~%{%]%++x@5 O P i+^%R+9.k+b =+~.{./%A\$N.(%_%:%<%                      ",
"                          [%}%|%1%2%@+8 t u u\$^ 3%b c 4%Z\$L.D+5%6%7%8%                          ",
"                              9%j\$0%a%b%c%d%S+a w c d e%f%g%h%i%j%k%                            ",
"                                    l%m%n%o%p%q%r%s%t%o%u%m%v%                                  ",
"                                                                                                ",
"                                                                                                ",
"                                                                                                "};
_EOF_
}
