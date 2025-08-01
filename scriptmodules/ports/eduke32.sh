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

rp_module_id="eduke32"
rp_module_desc="Duke3D Source Port\n \nMaster Branch (Bullseye+):\nhttps://voidpoint.io/sirlemonhead/eduke32.git \nmaster 3191b5f4\n \nLegacy Branch (Buster-):\nhttps://voidpoint.io/terminx/eduke32.git \nmaster dfc16b08"
rp_module_licence="GPL2 https://voidpoint.io/terminx/eduke32/-/raw/master/package/common/gpl-2.0.txt?inline=false"
if [[ "$__os_debian_ver" -le 10 ]]; then
    rp_module_repo="git https://voidpoint.io/terminx/eduke32.git master dfc16b08"
else
    rp_module_repo="git https://voidpoint.io/sirlemonhead/eduke32.git master 3191b5f41670ee9341f0298e155172c0ef760031"
    #rp_module_repo="git https://voidpoint.io/terminx/eduke32.git master 19c21b9ab10b0c17147c9ad951cc15279ed33f77"
    #rp_module_repo="git https://voidpoint.io/terminx/eduke32.git master 17844a2f651d4347258ae2fe59ec42dc3110506e"
    #rp_module_repo="git https://voidpoint.io/dgurney/eduke32.git master 76bc19e2e55023ea5a17c212eab0e1e5db217315"
fi
rp_module_section="opt"

function depends_eduke32() {
    local depends=(
        flac libflac-dev libvorbis-dev libpng-dev libvpx-dev freepats
        libsdl2-dev libsdl2-mixer-dev
    )

    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
    getDepends "${depends[@]}"
}

function sources_eduke32() {
    gitPullOrClone

    if [[ "$__os_debian_ver" -le 10 ]]; then
        # r6918 causes a 20+ second delay on startup on ARM devices
        isPlatform "arm" && applyPatch "$md_data/0001-revert-r6918.patch"
        # r7424 gives a black skybox when r_useindexedcolortextures is 0
        applyPatch "$md_data/0002-fix-skybox.patch"
        # r6776 breaks VC4 & GLES 2.0 devices that lack GL_RED internal
        # format support for glTexImage2D/glTexSubImage2D
        isPlatform "gles" && applyPatch "$md_data/0003-replace-gl_red.patch"
        # gcc 6.3.x compiler fix
        applyPatch "$md_data/0004-recast-function.patch"
        # cherry-picked commit fixing a game bug in E1M4 (shrinker ray stuck)
        applyPatch "$md_data/0005-e1m4-shrinker-bug.patch"
        # two more commits r8241 + r8247 fixing a bug in E4M4 (instant death in water)
        applyPatch "$md_data/0006-e4m4-water-bug.patch" # Already included in sirlemonhead's eduke32 fork
    fi
    # useindexedcolortextures 0FF
    sudo sed -i s+int32_t\ r_useindexedcolortextures\ =\ 1\;+int32_t\ r_useindexedcolortextures\ =\ 0\;+ $md_build/source/build/src/polymost.cpp
}

function build_eduke32() {
    local params=(LTO=0 SDL_TARGET=2)

    [[ "$md_id" == "ionfury" ]] && params+=(FURY=1)
    ! isPlatform "x86" && params+=(NOASM=1)
    ! isPlatform "x11" && params+=(HAVE_GTK2=0)
    ! isPlatform "gl3" && params+=(POLYMER=0)
    ! ( isPlatform "gl" || isPlatform "mesa" ) && params+=(USE_OPENGL=0)
    # r7242 requires >1GB memory allocation due to netcode changes.
    isPlatform "arm" && params+=(NETCODE=0)

    make veryclean
    CFLAGS+=" -DSDL_USEFOLDER" make -j $(nproc) "${params[@]}"

    if [[ "$md_id" == "ionfury" ]]; then
        md_ret_require="$md_build/fury"
    else
        md_ret_require="$md_build/eduke32"
    fi
}

function install_eduke32() {
    md_ret_files=('mapster32')

    if [[ "$md_id" == "ionfury" ]]; then
        md_ret_files+=('fury')
    else
        md_ret_files+=('eduke32')
    fi
}

function game_data_eduke32() {
    local dest="$romdir/ports/ksbuild/duke3d"
    if [[ "$md_id" == "eduke32" ]]; then
        mkUserDir "$dest"
        if [[ -z "$(find "$dest" -maxdepth 1 -iname duke3d.grp)" ]]; then
            local temp="$(mktemp -d)"
            download "$__archive_url/3dduke13.zip" "$temp"
            unzip -L -o "$temp/3dduke13.zip" -d "$temp" dn3dsw13.shr
            unzip -L -o "$temp/dn3dsw13.shr" -d "$dest" duke3d.grp duke.rts
            rm -rf "$temp"
            chown -R "$__user":"$__group" "$dest"
        fi
    fi
}

function configure_eduke32() {
    local appname="eduke32"
    local portname="duke3d"
    if [[ "$md_id" == "ionfury" ]]; then
        appname="fury"
        portname="ionfury"
    fi
    local config="$md_conf_root/$portname/settings.cfg"

    mkRomDir "ports/ksbuild"
    mkRomDir "ports/ksbuild/$portname"
    moveConfigDir "$home/.config/$appname" "$md_conf_root/$portname"

    add_games_eduke32 "$portname" "$md_inst/$appname"

    # remove old launch script
    rm -f "$romdir/ports/Duke3D Shareware.sh"

    if [[ "$md_mode" == "install" ]]; then
        game_data_eduke32

        touch "$config"
        iniConfig " " '"' "$config"

        # enforce vsync for kms targets
        isPlatform "kms" && iniSet "r_swapinterval" "1"

        # the VC4 & V3D drivers render menu splash colours incorrectly without this
        isPlatform "mesa" && iniSet "r_useindexedcolortextures" "0"

        chown -R "$__user":"$__group" "$config"
    fi
}

function add_games_eduke32() {
    local portname="$1"
    local binary="$2"
    local game
    local game_args
    local game_path
    local game_launcher
    local num_games=4

    if [[ "$md_id" == "ionfury" ]]; then
        num_games=0
        local game0=('Ion Fury' '' '')
    else
        local game0=('Duke Nukem 3D' '' '-addon 0')
        local game1=('Duke Nukem 3D - Duke It Out In DC' 'addons/dc' '-addon 1')
        local game2=('Duke Nukem 3D - Nuclear Winter' 'addons/nw' '-addon 2')
        local game3=('Duke Nukem 3D - Caribbean - Lifes A Beach' 'addons/vacation' '-addon 3')
        local game4=('NAM' 'addons/nam' '-nam')
    fi

    for ((game=0;game<=num_games;game++)); do
        game_launcher="game$game[0]"
        game_path="game$game[1]"
        game_args="game$game[2]"

        if [[ -d "$romdir/ports/ksbuild/$portname/${!game_path}" ]]; then
           addPort "$md_id" "$portname" "${!game_launcher}" "pushd $md_conf_root/$portname; ${binary}.sh %ROM%; popd" "-j$romdir/ports/ksbuild/$portname/${game0[1]} -j$romdir/ports/ksbuild/$portname/${!game_path} ${!game_args}"
        fi
    done

    if [[ "$md_mode" == "install" ]]; then
        # we need to use a dumb launcher script to strip quotes from runcommand's generated arguments
        cat > "${binary}.sh" << _EOF_
#!/bin/bash
# HACK: force vsync for RPI Mesa driver for now
VC4_DEBUG=always_sync $binary \$*
_EOF_

        chmod +x "${binary}.sh"
    fi
}
