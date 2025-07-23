#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="hexen2-gl"
rp_module_desc="Hexen II - Hammer of Thyrion source port +GL"
rp_module_licence="GPL2 https://raw.githubusercontent.com/svn2github/uhexen2/master/docs/COPYING"
rp_module_repo="git https://github.com/jpernst/uhexen2-sdl2.git master"
rp_module_help="For registered version, please add your full version PAK files to $romdir/ports/hexen2/data1/ to play. These files for the registered version are required: pak0.pak, pak1.pak and strings.txt. The registered pak files must be patched to 1.11 for Hammer of Thyrion."
rp_module_section="exp"
rp_module_flags=""

function depends_hexen2-gl() {
      # libsdl1.2-dev libsdl-net1.2-dev libsdl-sound1.2-dev libsdl-mixer1.2-dev libsdl-image1.2-dev
      getDepends matchbox cmake timidity freepats libmad0-dev libogg-dev libflac-dev libmpg123-dev libsdl2-dev libsdl2-mixer-dev
      }

function sources_hexen2-gl() {
    gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/hexen2-gl/data1.config.cfg" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/hexen2-gl/portals.config.cfg" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/hexen2-gl/hexen2-qjoy.sh" "$md_build"
}

function build_hexen2-gl() {
    cd "$md_build/engine/hexen2"
    ./build_all.sh
    md_ret_require=(
        "$md_build/engine/hexen2/glhexen2"
        "$md_build/data1.config.cfg"
        "$md_build/portals.config.cfg"
        "$md_build/hexen2-qjoy.sh"
    )
}

function install_hexen2-gl() {
    md_ret_files=(
       'engine/hexen2/glhexen2'
       'data1.config.cfg'
       'portals.config.cfg'
       'hexen2-qjoy.sh'
    )
}

function game_data_hexen2-gl() {
    if [[ ! -f "$romdir/ports/hexen2/data1/pak0.pak" ]]; then
        downloadAndExtract "https://netix.dl.sourceforge.net/project/uhexen2/Hexen2Demo-Nov.1997/hexen2demo_nov1997-linux-i586.tgz" "$romdir/ports/hexen2" --strip-components 1 "hexen2demo_nov1997/data1"
        chown -R "$__user":"$__user" "$romdir/ports/hexen2/data1"
    fi
}

function configure_hexen2-gl() {
    mkRomDir "ports/hexen2/data1"
    mkRomDir "ports/hexen2/portals"
    moveConfigDir "$home/.hexen2" "$romdir/ports/hexen2"
    if [[ ! -f "$romdir/ports/hexen2/data1/config.cfg" ]]; then cp "$md_inst/data1.config.cfg" "$romdir/ports/hexen2/data1/config.cfg"; fi
    if [[ ! -f "$romdir/ports/hexen2/portals/config.cfg" ]]; then cp "$md_inst/portals.config.cfg" "$romdir/ports/hexen2/portals/config.cfg"; fi
    chown -R $__user:$__user "$romdir/ports/hexen2"
    chmod 755 "$md_inst/hexen2-qjoy.sh"
    addPort "$md_id" "hexen2" "Hexen II" "XINIT:$md_inst/glhexen2 -f -conwidth 800"
    addPort "$md_id" "hexen2p" "Hexen II - Portals of Praevus" "XINIT:$md_inst/glhexen2 -f -conwidth 800 -portals"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "hexen2" "Hexen II +QJoyPad" "XINIT:$md_inst/hexen2-qjoy.sh"
        addPort "$md_id+qjoypad" "hexen2p" "Hexen II - Portals of Praevus +QJoyPad" "XINIT:$md_inst/hexen2-qjoy.sh -portals"
    fi
    [[ "$md_mode" == "install" ]] && game_data_hexen2
}
