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
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

# Additional Legacy Branch for Debian Buster and Below
legacy_branch=0; if [[ "$__os_debian_ver" -le 10 ]]; then legacy_branch=1; fi

rp_module_id="rott-huntbgin"
rp_module_desc="Rise of the Triad - The Hunt Begins (Shareware)\n \nMaster Branch (Bullseye+):\nhttps://github.com/LTCHIPS/rottexpr.git\n \nLegacy Branch (Buster-):\nhttps://github.com/zerojay/RoTT"
rp_module_licence="GPL2 https://raw.githubusercontent.com/LTCHIPS/rottexpr/master/LICENSE.DOC"
rp_module_repo="git https://github.com/LTCHIPS/rottexpr.git master"
rp_module_help="Location of ROTT Shareware files:\n$romdir/ports/rott-huntbgin"
rp_module_section="exp"
rp_module_flags="!mali"

rott_romdir="$romdir/ports/rott-huntbgin"
rott_bin="src/rott"
rott_prefix=''

if [[ "$legacy_branch" == '1' ]]; then
    rp_module_licence="GPL2 https://raw.githubusercontent.com/zerojay/RoTT/master/COPYING"
    rp_module_repo="git https://github.com/zerojay/RoTT"
    rott_bin="rott-huntbgin"
    rott_prefix='XINIT:'
fi

function depends_rott-huntbgin() {
    if [[ "$legacy_branch" == '1' ]]; then
        local depends=(libsdl1.2-dev libsdl-mixer1.2-dev automake autoconf unzip xorg)
    else
        if [[ $(apt-cache search libfluidsynth3) == '' ]]; then
            local depends=(libsdl2-dev libsdl2-mixer-dev fluidsynth libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm libfluidsynth1)
        else
            local depends=(libsdl2-dev libsdl2-mixer-dev fluidsynth libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm libfluidsynth3)
        fi
    fi
    getDepends "${depends[@]}"
}

function sources_rott-huntbgin() {
    gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/rott-huntbgin/rott-huntbgin-qjoy.sh" "$md_build"
}

function build_rott-huntbgin() {
    if [[ "$legacy_branch" == '1' ]]; then
        sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/rott/Makefile"
        sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
        make clean
        make rott-huntbgin
        make rott-huntbgin
        make rott-huntbgin
    else
        sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/src/Makefile"
        #sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
        cd src
        make rott
    fi
    md_ret_require=(
        "$md_build/$rott_bin"
        "$md_build/rott-huntbgin-qjoy.sh"
    )
}

function install_rott-huntbgin() {
    md_ret_files=(
        "$rott_bin"
        "rott-huntbgin-qjoy.sh"
    )
}

function game_data_rott-huntbgin() {
    if [[ ! -f "$romdir/ports/rott-huntbgin/HUNTBGIN.WAD" ]]; then
        downloadAndExtract "https://github.com/Exarkuniv/game-data/raw/main/HUNTBGIN.zip" "$rott_romdir"
        mv "$rott_romdir/HUNTBGIN/"* "$rott_romdir"
        rmdir "$rott_romdir/HUNTBGIN/"
    fi
}

function configure_rott-huntbgin() {
    local script="$md_inst/$md_id.sh"
    mkRomDir "ports"
    mkRomDir "$rott_romdir"
    chown -R $__user:$__user "$rott_romdir"
    moveConfigDir "$home/.rott" "$md_conf_root/rott"
    #create buffer script for launch
 cat > "$script" << _EOF_
#!/bin/bash
pushd "$rott_romdir"
"$md_inst/$(basename $rott_bin)" \$*
popd
_EOF_
    chmod +x "$script"
    chmod 755 "$md_inst/rott-huntbgin-qjoy.sh"
    addPort "$md_id" "rott-huntbgin" "Rise Of The Triad - The Hunt Begins (Shareware)" "$rott_prefix$script"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "rott-huntbgin" "Rise Of The Triad - The Hunt Begins (Shareware) +QJoyPad" "XINIT:$md_inst/rott-huntbgin-qjoy.sh"
    fi
    [[ "$md_mode" == "install" ]] && game_data_rott-huntbgin
}
