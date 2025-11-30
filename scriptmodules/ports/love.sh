#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="love"
rp_module_desc="Love - 2d Game Engine"
rp_module_help="Copy your Love games to $romdir/love"
rp_module_licence="ZLIB https://raw.githubusercontent.com/love2d/love/master/license.txt"
rp_module_repo="git https://github.com/love2d/love 11.5"
rp_module_section="opt"

function depends_love() {
    local depends=(autotools-dev automake libtool pkg-config libfreetype6-dev libluajit-5.1-dev libphysfs-dev libsdl2-dev libopenal-dev libogg-dev libtheora-dev libvorbis-dev libflac-dev libflac++-dev libmodplug-dev libmpg123-dev libmng-dev libjpeg-dev)

    getDepends "${depends[@]}"
}

function sources_love() {
    gitPullOrClone
}

function build_love() {
    ./platform/unix/automagic
    local params=(--prefix="$md_inst")

    # workaround for https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65612 on gcc 5.x+
    if isPlatform "x86"; then
        CXXFLAGS+=" -lgcc_s -lgcc" ./configure "${params[@]}"
    else
        ./configure "${params[@]}"
    fi

    make clean
    make
    md_ret_require="$md_build/src/love"
}

function install_love() {
    make install
}

function game_data_love() {
    # get Mari0 1.6.2 (freeware game data)
    if [[ ! -f "$romdir/love/mari0.love" ]]; then
        downloadAndExtract "https://github.com/Stabyourself/mari0/archive/1.6.2.tar.gz" "$__tmpdir/mari0" --strip-components 1

        # Update [game.lua] to QUIT on JoyPad Press Back # inlcude CHANGES.diff
        cp "$__tmpdir/mari0/game.lua" "$__tmpdir/mari0/game.lua.0riginal"
        cat >>"$__tmpdir/mari0/game.lua" <<_EOF_

function love.gamepadpressed(joystick, button)
    if joystick:isGamepadDown("back") then love.event.quit()
    end
end

_EOF_
        diff -ur "$__tmpdir/mari0/game.lua.0riginal" "$__tmpdir/mari0/game.lua" > "$__tmpdir/mari0/CHANGES.diff"
        rm -f "$__tmpdir/mari0/game.lua.0riginal"

        # Compress [game.love]
        pushd "$__tmpdir/mari0"
        zip -qr "$romdir/love/mari0.love" .
        popd
        rm -fr "$__tmpdir/mari0"
        chown "$__user":"$__group" "$romdir/love/mari0.love"
    fi

    # Get DOOM'd
    if [[ ! -f "$romdir/love/DOOM'd.love" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/ports/love-rp-assets.tar.gz" "$romdir/love"
        if [[ ! -f "$romdir/love/gamelist.xml" ]] && [[ ! -f "/opt/retropie/configs/all/emulationstation/gamelists/love/gamelist.xml" ]]; then mv "$romdir/love/gamelist.xml.love" "$romdir/love/gamelist.xml"; fi
        chown -R $__user:$__user -R "$romdir/love"
    fi
}

function configure_love() {
    setConfigRoot ""

    moveConfigDir "$home/.local/share/love" "$md_conf_root/love"
    chown -R $__user:$__user "$md_conf_root/love"

    mkRomDir "love"

    addEmulator 1 "$md_id" "love" "$md_inst/bin/love %ROM%"
    addSystem "love"

    [[ "$md_mode" == "install" ]] && game_data_love
}
