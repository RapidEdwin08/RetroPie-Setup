#!/usr/bin/env bash

# This file is part of RetroPie-Extra, a supplement to RetroPie.
# For more information, please visit:
#
# https://github.com/RetroPie/RetroPie-Setup
# https://github.com/Exarkuniv/RetroPie-Extra
#
# See the LICENSE file distributed with this source and at
# https://raw.githubusercontent.com/Exarkuniv/RetroPie-Extra/master/LICENSE
#

rp_module_id="rott-huntbgin"
rp_module_desc="ROTT - Rise of the Triad - The Hunt Begins (Shareware)"
rp_module_licence="GPL2 https://raw.githubusercontent.com/LTCHIPS/rottexpr/master/LICENSE.DOC"
rp_module_help=
rp_module_repo="git https://github.com/LTCHIPS/rottexpr.git master"
rp_module_section="exp"
rp_module_flags="!mali !x86"

function depends_rott-huntbgin() {
    #getDepends libsdl2-dev libsdl2-mixer-dev fluidsynth libfluidsynth1 libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm
	getDepends libsdl2-dev libsdl2-mixer-dev fluidsynth libfluidsynth3 libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm
}

function sources_rott-huntbgin() {
    gitPullOrClone
}

function build_rott-huntbgin() {
    sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/src/Makefile"
    cd src
    make rott
    md_ret_require=(
        "$md_build/src/rott"
    )
}

function install_rott-huntbgin() {
   md_ret_files=(
          'src/rott'
    )
}

function game_data_rott-huntbgin() {
    if [[ ! -f "$romdir/ports/rott/HUNTBGIN.WAD" ]]; then
        downloadAndExtract "https://github.com/Exarkuniv/game-data/raw/main/HUNTBGIN.zip" "$romdir/ports/rott"
    mv "$romdir/ports/rott/HUNTBGIN/"* "$romdir/ports/rott/"
    rmdir "$romdir/ports/rott/HUNTBGIN/"
    chown -R $user:$user "$romdir/ports/rott"
    fi

    chown -R $user:$user "$romdir/ports/rott"
}

function configure_rott-huntbgin() {
    local script="$md_inst/$md_id.sh"
    mkRomDir "ports"
    mkRomDir "ports/rott"
    moveConfigDir "$home/.rott" "$md_conf_root/rott"
	#create buffer script for launch
 cat > "$script" << _EOF_
#!/bin/bash
pushd "$romdir/ports/rott"
"$md_inst/rott" \$*
popd
_EOF_
    
	chmod +x "$script"
    addPort "$md_id" "rott-huntbgin" "Rise Of The Triad - The Hunt Begins (Shareware)" "$script"

    [[ "$md_mode" == "install" ]] && game_data_rott-huntbgin
}
