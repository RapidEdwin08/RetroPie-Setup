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

rp_module_id="srb2ringracers"
rp_module_desc="Sonic Robo Blast 2 Dr. Robotnik's Ring Racers Ring Racers - 3D Sonic the Hedgehog fan-game based on Sonic Robo Blast 2 built using a modified version of the Doom Legacy source port of Doom"
rp_module_help="Kart Krew is in no way affiliated with SEGA or Sonic Team. We do not claim ownership of any of SEGA's intellectual property used in SRB2.

======================================================
                   MINOR PASSWORDS                  
======================================================                                  
savetheframes / savetheanimals - Skip initial setup
wi-fi warrior - Unlock online play
mustard gas - Unlock addons
chaos zero 64 - TournamentMode, almost everything (TEMP)

======================================================
                   MAJOR PASSWORDS                  
WARNING: These will permanently affect your save file!
======================================================
juicebox - Time Attack, Prison Break, something else...
squish it skew it - Unlock Encore Mode
speed demon - Unlock Gear 3, Hard GP, and Master GP
preorder bonus - Grant 25 Chao Keys
sonic in paynt - Unlock all colors
creature capture - Unlock all followers
cartridge tilt - Unlock most stages
rouge's gallery - Unlock most characters
play it loud - Unlock all alternate music
manhattan project - Unlock all tutorials"
rp_module_licence="GPL2 https://raw.githubusercontent.com/STJr/Kart-Public/master/LICENSE"
rp_module_repo="git https://github.com/KartKrewDev/RingRacers.git :_get_branch_srb2ringracers"
rp_module_section="exp"

function _get_branch_srb2ringracers() {
    local branch_tag=v2.4

    echo $branch_tag
}

function depends_srb2ringracers() {
    local depends=(cmake libsdl2-dev libsdl2-mixer-dev libpng-dev libcurl4-openssl-dev libgme-dev libopenmpt-dev libminiupnpc-dev) # SRB2
    depends+=(libogg-dev libvorbis-dev libvpx-dev zlib1g-dev libyuv-dev libopus-dev) # RingRacers
    #if [[ $(apt-cache search libcurl4t64 | grep 'libcurl4t64 ') == '' ]]; then depends+=(libcurl4); else depends+=(libcurl4t64); fi
    getDepends "${depends[@]}"
}

function sources_srb2ringracers() {
    gitPullOrClone

    # Legacy GL "renderer", "Software"
    ! isPlatform "gl3" && sed -i 's+"renderer", "Software"+"renderer", "Legacy GL"+' "$md_build/src/cvars.cpp" && echo "[Legacy GL]"

    mkdir assets/installer
    downloadAndExtract https://github.com/KartKrewDev/RingRacers/releases/download/$(_get_branch_srb2ringracers)/Dr.Robotnik.s-Ring-Racers-$(_get_branch_srb2ringracers)-Assets.zip "$md_build/assets/installer/"
}

function build_srb2ringracers() {
    mkdir build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$md_inst"
    make -j"$(nproc)"
    md_ret_require="$md_build/build/bin/ringracers_$(_get_branch_srb2ringracers)"
}

function install_srb2ringracers() {
    # Copy and dereference to get srb2ringracers [binary] rather than a symlink to srb2ringracers-version
    cp -L "build/bin/ringracers_$(_get_branch_srb2ringracers)" "$md_inst/ringracers_$(_get_branch_srb2ringracers)"

    # Copy srb2ringracers assets
    cp -R "assets/installer/data" "$md_inst"
    cp -R "assets/installer/models" "$md_inst"
    md_ret_files=(
        'assets/installer/bios.pk3'
        'assets/installer/models.dat'
        'assets/installer/gamecontrollerdb.txt'
        'assets/installer/LICENSE.txt'
        'assets/installer/LICENSE-3RD-PARTY.txt'
        'assets/installer/PASSWORDS.txt'
        'src/sdl/SDL_icon.xpm'
    )
}

function remove_srb2ringracers() {
    if [[ -f "/usr/share/applications/SRB2 Ring Racers.desktop" ]]; then sudo rm -f "/usr/share/applications/SRB2 Ring Racers.desktop"; fi
    if [[ -f "$home/Desktop/SRB2 Ring Racers.desktop" ]]; then rm -f "$home/Desktop/SRB2 Ring Racers.desktop"; fi
    if [[ -f "$romdir/ports/Sonic Robo Blast 2 Ring Racers.sh" ]]; then rm "$romdir/ports/Sonic Robo Blast 2 Ring Racers.sh"; fi
}

function configure_srb2ringracers() {
    addPort "$md_id" "srb2ringracers" "Sonic Robo Blast 2 Ring Racers" "pushd $md_inst; ./ringracers_$(_get_branch_srb2ringracers); popd"
    moveConfigDir "$home/.ringracers"  "$md_conf_root/$md_id"

    cat >"$md_inst/srb2ringracers.sh" << _EOF_
#!/bin/bash
pushd $md_inst; ./ringracers_$(_get_branch_srb2ringracers); popd
_EOF_
    chmod 755 "$md_inst/srb2ringracers.sh"

    local shortcut_name
    shortcut_name="SRB2 Ring Racers"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Dr. Robotnik's Ring Racers
Exec=$md_inst/srb2ringracers.sh
Icon=$md_inst/SDL_icon.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=SRB2;srb2ringracers
StartupWMClass=SRB2RingRacers
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    [[ "$md_mode" == "remove" ]] && remove_srb2ringracers
}
