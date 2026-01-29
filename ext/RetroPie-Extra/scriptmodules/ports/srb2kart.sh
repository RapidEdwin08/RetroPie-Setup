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

rp_module_id="srb2kart"
rp_module_desc="Sonic Robo Blast 2 Kart - 3D Sonic the Hedgehog fan-game based on Sonic Robo Blast 2 built using a modified version of the Doom Legacy source port of Doom"
rp_module_help="Kart Krew is in no way affiliated with SEGA or Sonic Team. We do not claim ownership of any of SEGA's intellectual property used in SRB2."
rp_module_licence="GPL2 https://raw.githubusercontent.com/STJr/Kart-Public/master/LICENSE"
rp_module_repo="git https://github.com/STJr/Kart-Public.git master"
rp_module_section="exp"

function depends_srb2kart() {
    getDepends cmake libsdl2-dev libsdl2-mixer-dev libpng-dev libcurl4-openssl-dev libgme-dev libopenmpt-dev libminiupnpc-dev
}

function sources_srb2kart() {
    local srb2kVER=v1.6
    gitPullOrClone "$md_build" https://github.com/STJr/Kart-Public.git $srb2kVER
    mkdir assets/installer
    downloadAndExtract https://github.com/STJr/Kart-Public/releases/download/$srb2kVER/AssetsLinuxOnly.zip "$md_build/assets/installer/"
}

function build_srb2kart() {
    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$md_inst"
    make -j"$(nproc)"
    md_ret_require="$md_build/build/bin/srb2kart"
}

function install_srb2kart() {
    # Copy and dereference to get srb2kart [binary] rather than a symlink to srb2kart-version
    cp -L 'build/bin/srb2kart' "$md_inst/srb2kart"
    # Clean up any 0lder srb2kart Config/Assets before Installing
    if [[ -f "$md_conf_root/$md_id/kartconfig.cfg" ]]; then rm "$md_conf_root/$md_id/kartconfig.cfg"; fi
    if [[ -f "$md_conf_root/$md_id/kartdata.dat" ]]; then rm "$md_conf_root/$md_id/kartdata.dat"; fi
    if [[ -f "$md_conf_root/$md_id/log.txt" ]]; then rm "$md_conf_root/$md_id/log.txt"; fi
    if [[ -d "$md_inst/mdls" ]]; then rm -Rf "$md_inst/mdls"; fi
    if [[ -f "$md_inst/mdls.dat" ]]; then rm "$md_inst/mdls.dat"; fi
    if [[ -f "$md_inst/srb2.srb" ]]; then rm "$md_inst/srb2.srb"; fi
    if [[ -f "$md_inst/patch.kart" ]]; then rm "$md_inst/patch.kart"; fi
    if [[ -f "$md_inst/README.txt" ]]; then rm "$md_inst/README.txt"; fi
    if [[ ! $(ls "$md_inst/*.kart") == '' ]]; then rm "$md_inst/*.kart"; fi
    if [[ ! $(ls "$md_inst/LICENSE*") == '' ]]; then rm "$md_inst/LICENSE*"; fi
    # Copy srb2kart assets
    cp -R "assets/installer/mdls" "$md_inst"
    md_ret_files=(
        'assets/installer/bonuschars.kart'
        'assets/installer/chars.kart'
        'assets/installer/gfx.kart'
        'assets/installer/maps.kart'
        'assets/installer/music.kart'
        'assets/installer/sounds.kart'
        'assets/installer/srb2.srb'
        'assets/installer/textures.kart'
        'assets/installer/HISTORY.txt'
        'assets/installer/LICENSE.txt'
        'assets/installer/LICENSE-3RD-PARTY.txt'
        'assets/installer/README.txt'
        'assets/installer/mdls.dat'
        'src/sdl12/SDL_icon.xpm'
        'src/sdl/SDL_icon.xpm'
    )
}

function remove_srb2kart() {
    if [[ -f "/usr/share/applications/SRB2 Kart.desktop" ]]; then sudo rm -f "/usr/share/applications/SRB2 Kart.desktop"; fi
    if [[ -f "$home/Desktop/SRB2 Kart.desktop" ]]; then rm -f "$home/Desktop/SRB2 Kart.desktop"; fi
    if [[ -f "$romdir/ports/Sonic Robo Blast 2 Kart.sh" ]]; then rm "$romdir/ports/Sonic Robo Blast 2 Kart.sh"; fi
}

function configure_srb2kart() {
    addPort "$md_id" "srb2kart" "Sonic Robo Blast 2 Kart" "pushd $md_inst; ./srb2kart; popd"
    moveConfigDir "$home/.srb2kart"  "$md_conf_root/$md_id"

    cat >"$md_inst/srb2kart.sh" << _EOF_
#!/bin/bash
pushd $md_inst; ./srb2kart; popd
_EOF_
    chmod 755 "$md_inst/srb2kart.sh"

    local shortcut_name
    shortcut_name="SRB2 Kart"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=SRB2 Kart
GenericName=SRB2 Kart
Comment=Sonic Robo Blast 2 Kart
Exec=$md_inst/srb2kart.sh
Icon=$md_inst/SDL_icon.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=SRB2;SRB2Kart
StartupWMClass=SRB2 Kart
Name[en_US]=SRB2 Kart
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    [[ "$md_mode" == "remove" ]] && remove_srb2kart
}
