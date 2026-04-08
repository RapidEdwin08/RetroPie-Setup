#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="tyrquake"
rp_module_desc="Quake 1 engine - TyrQuake port"
rp_module_licence="GPL2 https://disenchant.net/git/tyrquake.git/plain/gnu.txt"
rp_module_repo="git https://github.com/RetroPie/tyrquake.git master"
rp_module_section="opt"

function depends_tyrquake() {
    local depends=(libsdl2-dev)
    if isPlatform "gl" || isPlatform "mesa"; then
        depends+=(libgl1-mesa-dev)
    fi

    getDepends "${depends[@]}"
}

function sources_tyrquake() {
    gitPullOrClone
}

function build_tyrquake() {
    local params=(USE_SDL=Y USE_XF86DGA=N)
    make clean
    make "${params[@]}" bin/tyr-quake bin/tyr-glquake
    md_ret_require=(
        "$md_build/bin/tyr-quake"
        "$md_build/bin/tyr-glquake"
    )
}

function install_tyrquake() {
    md_ret_files=(
        'changelog.txt'
        'readme.txt'
        'readme-id.txt'
        'gnu.txt'
        'bin'
    )
}

function _add_games_tyrquake() {
    local cmd="$1"
    declare -A games=(
        ['id1']="Quake"
        ['hipnotic']="Quake I Mission Pack 1 (hipnotic)"
        ['rogue']="Quake I Mission Pack 2 (rogue)"
        ['dopa']="Quake I Episode 5 (dopa)"
    )
    local dir
    local pak
    for dir in "${!games[@]}"; do
        pak="$romdir/ports/quake/$dir/pak0.pak"
        if [[ -f "$pak" ]]; then
            addPort "$md_id" "quake" "${games[$dir]}" "$cmd" "$pak"
        fi
    done

    if [[ ! "$(ls -1 "$romdir/ports/quake/honey" 2>/dev/null)" == '' ]]; then
        addPort "$md_id" "quake" "Quake I AddOn Honey" "$binary ${params[*]}" "$romdir/ports/quake/honey/pak0.pak"
    fi
}

function add_games_tyrquake() {
    ##local params=("-basedir $romdir/ports/quake")
    ##params+=("-game %QUAKEDIR%")
    ##local binary="$md_inst/bin/tyr-quake"
    local params=("%ROM%")
    local binary="$md_inst/tyrquake.sh"

    isPlatform "kms" && params+=("-width %XRES%" "-height %YRES%")
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then
        params+=("+set vid_vsync 2")
        ##binary="$md_inst/bin/tyr-glquake"
    fi

    _add_games_tyrquake "$binary ${params[*]}"
}

function configure_tyrquake() {
    mkRomDir "ports/quake"

    [[ "$md_mode" == "install" ]] && game_data_lr-tyrquake

    add_games_tyrquake

    moveConfigDir "$home/.tyrquake" "$md_conf_root/quake/tyrquake"

    local binary="$md_inst/bin/tyr-quake"
    if ( isPlatform "kms" || isPlatform "mesa" ) || ( isPlatform "gl" || isPlatform "vulkan" ); then binary="$md_inst/bin/tyr-glquake"; fi
    cat >"$md_inst/tyrquake.sh" << _EOF_
#!/bin/bash

# get Params: remove everything up to pak - [+map dm7sp]
quake_params="\${@##*pak}"

# get basedir: remove everything up to /quake/ - [dm7sp/pak0.pak +map dm7sp]
quake_dir="\${1##*/quake/}"

# get basedir: remove filename - [dm7sp]
quake_dir="\${quake_dir%/*}"

# Logging
echo -game: [\$quake_dir] +Params: [\$quake_params] >> /dev/shm/runcommand.log

# Called by [emulators.cfg] with %ROM% instead of %QUAKEDIR%
if [[ "\$quake_dir" == 'id1' ]]; then # [-game id1] fails to play Shareware Episode
    $binary -basedir $romdir/ports/quake
else
    $binary -basedir $romdir/ports/quake -game \$quake_dir \$quake_params
fi

_EOF_
    chmod 755 "$md_inst/tyrquake.sh"
}
