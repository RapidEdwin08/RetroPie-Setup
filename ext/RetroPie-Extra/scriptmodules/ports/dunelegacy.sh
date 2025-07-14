#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

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
    if [[ $(apt-cache search libfluidsynth3) == '' ]]; then
		getDepends autotools-dev libsdl2-mixer-dev libopusfile0 libsdl2-mixer-2.0-0 libsdl2-ttf-dev xorg matchbox-window-manager x11-xserver-utils libfluidsynth-dev libfluidsynth1 fluidsynth
	else
		getDepends autotools-dev libsdl2-mixer-dev libopusfile0 libsdl2-mixer-2.0-0 libsdl2-ttf-dev xorg matchbox-window-manager x11-xserver-utils libfluidsynth-dev libfluidsynth3 fluidsynth
	fi
}

function sources_dunelegacy() {
    gitPullOrClone 
}

function build_dunelegacy() {
    if [[ "$__os_debian_ver" -le 10 ]]; then
		params=(--prefix="$md_inst")
	else
		params=(--prefix="$md_inst" --with-asound --without-pulse --with-sdl2)
	fi
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
	
	echo [PARAMS]: ${params[@]}
    autoreconf --install
    ./configure "${params[@]}"
    make -j4
	md_ret_require="$md_build/src/dunelegacy"
}

function install_dunelegacy() {
    make install
}

function game_data_dunelegacy() {
    if [[ ! -f "$romdir/ports/dune2/data/DUNE2.EXE" ]]; then
		if [[ ! -d "$romdir/ports/dune2/data" ]]; then mkdir "$romdir/ports/dune2/data"; fi
		downloadAndExtract "https://github.com/Exarkuniv/game-data/raw/main/dune-II.zip" "$romdir/ports/dune2"
		mv "$romdir/ports/dune2/dune-ii-the-building-of-a-dynasty/"* "$romdir/ports/dune2/data"
		rmdir "$romdir/ports/dune2/dune-ii-the-building-of-a-dynasty/"
		chown -R $user:$user "$romdir/ports/dune2"
	fi
}

function configure_dunelegacy() {
    mkRomDir "ports/dune2/data"
    moveConfigDir "$home/.config/dunelegacy" "$md_conf_root/dunelegacy"
    addPort "$md_id" "dunelegacy" "Dune Legacy" "XINIT: $md_inst/bin/dunelegacy"     	
    ln -s "/home/pi/RetroPie/roms/ports/dune2/data" "$home/.config/dunelegacy" 

    [[ "$md_mode" == "install" ]] && game_data_dunelegacy
}
