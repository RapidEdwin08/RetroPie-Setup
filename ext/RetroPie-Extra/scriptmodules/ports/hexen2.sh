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

rp_module_id="hexen2"
rp_module_desc="Hexen II - Hammer of Thyrion source port"
rp_module_licence="GPL2 https://raw.githubusercontent.com/svn2github/uhexen2/master/docs/COPYING"
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

function depends_hexen2() {
    # libsdl1.2-dev libsdl-net1.2-dev libsdl-sound1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev timidity freepats
    depends+=(cmake timidity freepats libmad0-dev libogg-dev libflac-dev libmpg123-dev libsdl2-dev libsdl2-mixer-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_hexen2() {
    gitPullOrClone "$md_build" https://github.com/svn2github/uhexen2.git
}

function build_hexen2() {
    cd "$md_build/engine/hexen2"
    ./build_all.sh
    md_ret_require="$md_build/engine/hexen2/hexen2"
}

function install_hexen2() {
    md_ret_files=(
       'engine/hexen2/hexen2'
    )
}

function game_data_hexen2() {
    if [[ ! -f "$romdir/ports/hexen2/data1/pak0.pak" ]]; then
        downloadAndExtract "https://netix.dl.sourceforge.net/project/uhexen2/Hexen2Demo-Nov.1997/hexen2demo_nov1997-linux-i586.tgz" "$romdir/ports/hexen2" --strip-components 1 "hexen2demo_nov1997/data1"
        chown -R "$__user":"$__user" "$romdir/ports/hexen2/data1"
    fi
}

function configure_hexen2() {
    addPort "$md_id" "hexen2" "Hexen II" "$md_inst/hexen2"

    mkRomDir "ports/hexen2"

    moveConfigDir "$home/.hexen2" "$romdir/ports/hexen2"

    [[ "$md_mode" == "install" ]] && game_data_hexen2
}
