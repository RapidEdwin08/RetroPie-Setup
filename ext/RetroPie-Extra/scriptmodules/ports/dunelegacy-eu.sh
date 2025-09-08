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
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/DuneII_48x48.ico" "$md_build"
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
        'DuneII_48x48.ico'
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
    if [[ -f "/usr/share/applications/Dune II The Battle for Arrakis.desktop" ]]; then sudo rm -f "/usr/share/applications/Dune II The Battle for Arrakis.desktop"; fi
    if [[ -f "$home/Desktop/Dune II The Battle for Arrakis.desktop" ]]; then rm -f "$home/Desktop/Dune II The Battle for Arrakis.desktop"; fi
    if [[ -f "$romdir/ports/Dune II The Battle for Arrakis.sh" ]]; then rm "$romdir/ports/Dune II The Battle for Arrakis.sh"; fi
}

function configure_dunelegacy-eu() {
    mkRomDir "ports/dune2/$md_id"
    moveConfigDir "$home/.config/$md_id" "$md_conf_root/$md_id"
    if [[ ! -d "$md_conf_root/$md_id/dunelegacy" ]]; then mkdir "$md_conf_root/$md_id/dunelegacy"; fi
    chown -R $__user:$__user "$md_conf_root/$md_id/dunelegacy"
    ln -s "$home/RetroPie/roms/ports/dune2/$md_id" "$md_conf_root/$md_id/dunelegacy/data"
    chown -R $__user:$__user "$md_conf_root/$md_id"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
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

    cat >"$md_inst/Dune II The Battle for Arrakis.desktop" << _EOF_
[Desktop Entry]
Name=Dune II The Battle for Arrakis
GenericName=Dune II The Battle for Arrakis
Comment=Dune II The Battle for Arrakis
Exec=$md_inst/bin/dunelegacy
Icon=$md_inst/DuneII_48x48.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=D2;DuneII;Battle;Arrakis
StartupWMClass=Dune II The Battle for Arrakis
Name[en_US]=Dune II The Battle for Arrakis
_EOF_
    chmod 755 "$md_inst/Dune II The Battle for Arrakis.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Dune II The Battle for Arrakis.desktop" "$home/Desktop/Dune II The Battle for Arrakis.desktop"; chown $__user:$__user "$home/Desktop/Dune II The Battle for Arrakis.desktop"; fi
    mv "$md_inst/Dune II The Battle for Arrakis.desktop" "/usr/share/applications/Dune II The Battle for Arrakis.desktop"

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
    [[ "$md_mode" == "remove" ]] && remove_dunelegacy-eu
}
