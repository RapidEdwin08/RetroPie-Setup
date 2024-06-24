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


rp_module_id="rott-darkwar"
rp_module_desc="ROTT - Rise of the Triad - Dark War"
rp_module_licence="GPL2 https://raw.githubusercontent.com/LTCHIPS/rottexpr/master/LICENSE.DOC"
rp_module_help="Please add your full version ROTT files to $romdir/ports/rott/ to play."
rp_module_repo="git https://github.com/LTCHIPS/rottexpr.git master"
rp_module_section="exp"
rp_module_flags="!mali !x86"

function depends_rott-darkwar() {
    #getDepends libsdl2-dev libsdl2-mixer-dev fluidsynth libfluidsynth1 libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm
	getDepends libsdl2-dev libsdl2-mixer-dev fluidsynth libfluidsynth3 libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm

}

function sources_rott-darkwar() {
    gitPullOrClone
}

function build_rott-darkwar() {
    cd src
    make rott
    md_ret_require=(
       "$md_build/src/rott"
    )
}

function install_rott-darkwar() {
   md_ret_files=(
          'src/rott'
    )
}

function configure_rott-darkwar() {
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
    addPort "$md_id" "rott-darkwar" "Rise Of The Triad - Dark War" "$script"
}
