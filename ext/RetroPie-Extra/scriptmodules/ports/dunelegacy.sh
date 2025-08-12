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

# Additional Legacy Branch for Debian Buster and Below
legacy_branch=0; if [[ "$__os_debian_ver" -le 10 ]]; then legacy_branch=1; fi

rp_module_id="dunelegacy"
rp_module_desc="Dune Legacy - Dune 2 Building of a Dynasty port"
rp_module_help="Please put your data files in the roms/ports/dunelegacy/data folder"
rp_module_licence="GNU 2.0 https://sourceforge.net/p/dunedynasty/dunedynasty/ci/master/tree/COPYING"
rp_module_repo="git git://dunelegacy.git.sourceforge.net/gitroot/dunelegacy/dunelegacy master"
#rp_module_repo="git https://github.com/Shazwazza/DuneLegacy.git develop"
#rp_module_repo="git https://github.com/henricj/dunelegacy.git modernize"
rp_module_section="exp"
rp_module_flags="!mali"

function depends_dunelegacy() {
    local depends=(matchbox-window-manager autotools-dev libsdl2-mixer-dev libopusfile0 libsdl2-mixer-2.0-0 libsdl2-ttf-dev xorg x11-xserver-utils libfluidsynth-dev fluidsynth)
    if [[ $(apt-cache search libfluidsynth3) == '' ]]; then
    	depends+=(libfluidsynth1)
    else
    	depends+=(libfluidsynth3)
    fi
	getDepends "${depends[@]}"
}

function sources_dunelegacy() {
    gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/dunelegacy/dunelegacy-qjoy.sh" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/dunelegacy/Dune%20Legacy.ini" "$md_build"
}

function build_dunelegacy() {
	sed -i "/*Mix_Init(MIX_INIT_FLUIDSYNTH | MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG)/c\\Mix_Init(MIX_INIT_MID | MIX_INIT_FLAC | MIX_INIT_MP3 | MIX_INIT_OGG)" $md_build/src/FileClasses/music/DirectoryPlayer.cpp
	sed -i "/if((Mix_Init(MIX_INIT_FLUIDSYNTH) & MIX_INIT_FLUIDSYNTH) == 0) {/c\\if((Mix_Init(MIX_INIT_MID) & MIX_INIT_MID) == 0) {" $md_build/src/FileClasses/music/XMIPlayer.cpp
	
	if [[ "$legacy_branch" == '0' ]]; then
		# Bookworm error: field ‘mentatStrings’ has incomplete type ‘std::array<std::unique_ptr<MentatTextFile>, 3>’
		sed -i '1s/^/#include <tuple> \n/' $md_build/src/FileClasses/TextManager.cpp
		sed -i '1s/^/#include <array> \n/' $md_build/src/FileClasses/TextManager.cpp
		
		# Flickering fix -> Comment 1st instance of  // SDL_RenderPresent(renderer);
		##sed -i 's+SDL_RenderPresent(renderer);+//SDL_RenderPresent(renderer);+g' $md_build/src/Game.cpp
		sed '0,/SDL_RenderPresent(renderer);/s//\/\/SDL_RenderPresent(renderer);/' $md_build/src/Game.cpp > /dev/shm/Game.cpp; sudo mv /dev/shm/Game.cpp $md_build/src/Game.cpp
	fi
	
    if [[ "$legacy_branch" == '1' ]]; then
		params=(--prefix="$md_inst")
	else
		params=(--prefix="$md_inst" --with-asound --without-pulse --with-sdl2)
	fi

	echo [PARAMS]: ${params[@]}
    autoreconf --install
    ./configure "${params[@]}"
    make -j"$(nproc)"
    md_ret_require=(
        "$md_build/src/dunelegacy"
    )
}

function install_dunelegacy() {
    make install
    md_ret_files=(
        'Dune%20Legacy.ini'
        'dunelegacy-qjoy.sh'
        'dunelegacy.svg'
    )
}

function game_data_dunelegacy() {
    if [[ ! -f "$romdir/ports/dune2/data/DUNE2.EXE" ]] && [[ ! -f "$romdir/ports/dune2/data/Dune2.EXE" ]]; then
		mkRomDir "ports/dune2/data"
		downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/dunelegacy/dunelegacy-rp-assets.tar.gz" "$romdir/ports/dune2/data"
		chown -R $__user:$__user "$romdir/ports/dune2"
	fi
}

function remove_dunelegacy() {
    if [[ -f "/usr/share/applications/Dune II.desktop" ]]; then sudo rm -f "/usr/share/applications/Dune II.desktop"; fi
    if [[ -f "$home/Desktop/Dune II.desktop" ]]; then rm -f "$home/Desktop/Dune II.desktop"; fi
    if [[ -f "$romdir/ports/Dune II.sh" ]]; then rm "$romdir/ports/Dune II.sh"; fi
}

function configure_dunelegacy() {
    moveConfigDir "$home/.config/dunelegacy" "$md_conf_root/dunelegacy"
    mv "$md_inst/Dune%20Legacy.ini" "$md_inst/Dune Legacy.ini"
	if [[ ! -f "$md_conf_root/dunelegacy/Dune Legacy.ini" ]]; then
		cp "$md_inst/Dune Legacy.ini" "$md_conf_root/dunelegacy/Dune Legacy.ini"
		chown -R $__user:$__user "$md_conf_root/dunelegacy/Dune Legacy.ini"
	fi
    mkRomDir "ports/dune2/data"
    ln -s "$home/RetroPie/roms/ports/dune2/data" "$home/.config/dunelegacy"
    chmod 755 "$md_inst/dunelegacy-qjoy.sh"
    local launch_prefix=XINIT-WMC; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WMC)" == '' ]]; then local launch_prefix=XINIT; fi
    addPort "$md_id" "dunelegacy" "Dune Legacy" "$launch_prefix:$md_inst/bin/dunelegacy"
	if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
		addPort "$md_id+qjoypad" "dunelegacy" "Dune Legacy" "$launch_prefix:$md_inst/dunelegacy-qjoy.sh"
	fi

    cat >"$md_inst/Dune II.desktop" << _EOF_
[Desktop Entry]
Name=Dune II
GenericName=Dune II
Comment=Dune Legacy
Exec=$md_inst/bin/dunelegacy
Icon=$md_inst/dunelegacy.svg
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=D2;DuneII
StartupWMClass=Dune II
Name[en_US]=Dune II
_EOF_
    chmod 755 "$md_inst/Dune II.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Dune II.desktop" "$home/Desktop/Dune II.desktop"; chown $__user:$__user "$home/Desktop/Dune II.desktop"; fi
    mv "$md_inst/Dune II.desktop" "/usr/share/applications/Dune II.desktop"

    [[ "$md_mode" == "install" ]] && game_data_dunelegacy
    [[ "$md_mode" == "remove" ]] && remove_dunelegacy
}
