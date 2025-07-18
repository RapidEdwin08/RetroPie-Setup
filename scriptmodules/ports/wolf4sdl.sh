#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# Copy/Paste *.sod Files to sd1/sd2/sd3
# 6e914d15335125872737718470061ad8  audiohed.sod -> audiohed.sd1  audiohed.sd2  audiohed.sd3
# 10020fce0f04d21bd07b1b5b951c360a  audiot.sod   -> audiot.sd1    audiot.sd2    audiot.sd3
# 30b11372b9ec6bc06289eb3e9b2ef0b9  vgadict.sod  -> vgadict.sd1   vgadict.sd2   vgadict.sd3
# 3b85f170098fb48d91d8bedd0cac4e0d  vgagraph.sod -> vgagraph.sd1  vgagraph.sd2  vgagraph.sd3
# fb75007a1167bba05c4acadf90bc30d8  vgahead.sod  -> vgahead.sd1   vgahead.sd2   vgahead.sd3

rp_module_id="wolf4sdl"
rp_module_desc="Wolf4SDL - port of Wolfenstein 3D / Spear of Destiny engine"
rp_module_licence="GPL2 https://raw.githubusercontent.com/AryanWolf3D/Wolf4SDL/master/license-gpl.txt"
rp_module_repo="git https://github.com/AryanWolf3D/Wolf4SDL.git master"
rp_module_section="opt"
rp_module_flags="sdl2"

function depends_wolf4sdl() {
    getDepends libsdl2-dev libsdl2-mixer-dev rename
}

function sources_wolf4sdl() {
    gitPullOrClone
}

function _get_opts_wolf4sdl() {
    echo 'wolf4sdl-sw-v14 -DCARMACIZED -DUPLOAD' # shareware v1.4
    echo 'wolf4sdl-3dr-v14 -DCARMACIZED' # 3d realms / apogee v1.4 full
    echo 'wolf4sdl-gt-v14 -DCARMACIZED -DGOODTIMES' # gt / id / activision v1.4 full
    echo 'wolf4sdl-spear -DCARMACIZED -DGOODTIMES -DSPEAR' # spear of destiny
    echo 'wolf4sdl-spear-sw -DCARMACIZED -DSPEARDEMO -DSPEAR' # spear of destiny demo
}

function add_games_wolf4sdl() {
    declare -A -g games_wolf4sdl=(
        ['vswap.wl1']="Wolfenstein 3D demo"
        ['vswap.wl6']="Wolfenstein 3D"
        ['vswap.sd1']="Wolfenstein 3D - Spear of Destiny Ep 1"
        ['vswap.sd2']="Wolfenstein 3D - Spear of Destiny Ep 2"
        ['vswap.sd3']="Wolfenstein 3D - Spear of Destiny Ep 3"
        ['vswap.sdm']="Wolfenstein 3D - Spear of Destiny Demo"
    )

    add_ports_wolf4sdl "$md_inst/bin/wolf4sdl.sh %ROM%" "wolf3d"
}

function add_ports_wolf4sdl() {
    local port="$2"
    local cmd="$1"
    local game
    local wad

    for game in "${!games_wolf4sdl[@]}"; do
        wad="$romdir/ports/wolf3d/$game"
        if [[ -f "$wad" ]]; then
            addPort "$md_id" "$port" "${games_wolf4sdl[$game]}" "$cmd" "$wad"
        fi
    done
}

function build_wolf4sdl() {
    mkdir -p "bin"
    local opt
    while read -r opt; do
        local bin="${opt%% *}"
        local defs="${opt#* }"
        make clean
        CFLAGS+=" -DVERSIONALREADYCHOSEN -DGPL $defs" make
        mv wolf4sdl "bin/$bin"
        md_ret_require+=("bin/$bin")
    done < <(_get_opts_wolf4sdl)
}

function install_wolf4sdl() {
    mkdir -p "$md_inst/share/man"
    cp -Rv "$md_build/man6" "$md_inst/share/man/"
    md_ret_files=('bin')
}

function game_data_wolf4sdl() {
    pushd "$romdir/ports/wolf3d"
    rename 'y/A-Z/a-z/' *
    popd
    if [[ ! -f "$romdir/ports/wolf3d/vswap.wl6" && ! -f "$romdir/ports/wolf3d/vswap.wl1" ]]; then
        cd "$__tmpdir"
        # Get shareware game data
        downloadAndExtract "http://maniacsvault.net/ecwolf/files/shareware/wolf3d14.zip" "$romdir/ports/wolf3d" -j -LL
    fi
    if [[ ! -f "$romdir/ports/wolf3d/vswap.sdm" && ! -f "$romdir/ports/wolf3d/vswap.sod" ]]; then
        cd "$__tmpdir"
        # Get shareware game data
        downloadAndExtract "http://maniacsvault.net/ecwolf/files/shareware/soddemo.zip" "$romdir/ports/wolf3d" -j -LL
    fi

    chown -R "$__user":"$__group" "$romdir/ports/wolf3d"
}

function configure_wolf4sdl() {
    local game

    mkRomDir "ports/wolf3d"

    # remove obsolete emulator entries
    while read game; do
        delEmulator "${game%% *}" "wolf3d"
    done < <(_get_opts_wolf4sdl; echo -e "wolf4sdl-spear2\nwolf4sdl-spear3")

    if [[ "$md_mode" == "install" ]]; then
        game_data_wolf4sdl
        cat > "$md_inst/bin/wolf4sdl.sh" << _EOF_
#!/bin/bash

function get_md5sum() {
    local file="\$1"

    [[ -n "\$file" ]] && md5sum "\$file" 2>/dev/null | cut -d" " -f1
}

function launch_wolf4sdl() {
    local wad_file="\$1"
    declare -A game_checksums=(
        ['6efa079414b817c97db779cecfb081c9']="wolf4sdl-sw-v14"
        ['a6d901dfb455dfac96db5e4705837cdb']="wolf4sdl-3dr-v14"
        ['b8ff4997461bafa5ef2a94c11f9de001']="wolf4sdl-gt-v14"
        ['b1dac0a8786c7cdbb09331a4eba00652']="wolf4sdl-spear --mission 1"
        ['25d92ac0ba012a1e9335c747eb4ab177']="wolf4sdl-spear --mission 2"
        ['94aeef7980ef640c448087f92be16d83']="wolf4sdl-spear --mission 3"
        ['e3e87518f51414872c454b7d72a45af6']="wolf4sdl-spear --mission 3"
        ['35afda760bea840b547d686a930322dc']="wolf4sdl-spear-sw"
    )
        if [[ "\${game_checksums[\$(get_md5sum \$wad_file)]}" ]] 2>/dev/null; then
            pushd "$romdir/ports/wolf3d"
            $md_inst/bin/\${game_checksums[\$(get_md5sum \$wad_file)]}
            popd
        else
            echo "Error: \$wad_file (md5: \$(get_md5sum \$wad_file)) is not a supported version"
        fi
}

launch_wolf4sdl "\$1"
_EOF_
        chmod +x "$md_inst/bin/wolf4sdl.sh"
    fi

    add_games_wolf4sdl

    moveConfigDir "$home/.wolf4sdl" "$md_conf_root/wolf3d"
}
