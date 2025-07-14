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
rp_module_desc="rott - Rise of the Triad - The Hunt Begins (Shareware)"
rp_module_licence="GPL2 https://raw.githubusercontent.com/zerojay/RoTT/master/COPYING"
rp_module_help="Please add your shareware version ROTT files to $romdir/ports/rott-huntbgin/huntbgin to play."
rp_module_repo="git https://github.com/zerojay/RoTT"
rp_module_section="exp"
rp_module_flags="!mali !x86"

function depends_rott-huntbgin() {
    getDepends libsdl1.2-dev libsdl-mixer1.2-dev automake autoconf unzip xorg
}

function sources_rott-huntbgin() {
    gitPullOrClone
}

function build_rott-huntbgin() {
    sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/rott/Makefile"
    sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
    make clean
    make rott-huntbgin
    make rott-huntbgin
    make rott-huntbgin
    md_ret_require=(
        "$md_build/rott-huntbgin"
    )
}

function install_rott-huntbgin() {
   md_ret_files=(
          'rott-huntbgin'
    )
}

function game_data_rott-huntbgin() {
    if [[ ! -f "$romdir/ports/rott-huntbgin/HUNTBGIN.WAD" ]]; then
        downloadAndExtract "https://github.com/Exarkuniv/game-data/raw/main/HUNTBGIN.zip" "$romdir/ports/rott-huntbgin"
    mv "$romdir/ports/$md_id/HUNTBGIN/"* "$romdir/ports/$md_id/"
    rmdir "$romdir/ports/$md_id/HUNTBGIN/"
    chown -R $user:$user "$romdir/ports/$md_id"
    fi

    chown -R $user:$user "$romdir/ports/$md_id"
}

function configure_rott-huntbgin() {
    local script="$md_inst/$md_id.sh"
    mkRomDir "ports"
    mkRomDir "ports/$md_id"
    moveConfigDir "$home/.rott" "$md_conf_root/rott"
	#create buffer script for launch
 cat > "$script" << _EOF_
#!/bin/bash
pushd "$romdir/ports/rott-huntbgin"
"$md_inst/rott-huntbgin" \$*
popd
_EOF_
    
	chmod +x "$script"
    addPort "$md_id" "rott-huntbgin" "Rise Of The Triad - The Hunt Begins (Shareware)" "XINIT:$script"

    [[ "$md_mode" == "install" ]] && game_data_rott-huntbgin
}
