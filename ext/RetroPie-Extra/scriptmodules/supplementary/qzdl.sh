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

rp_module_id="qzdl"
rp_module_desc="Qt version of ZDL - ZDoom [WAD] Launcher"
rp_module_help="- General Settings [Source Ports]:\n/opt/retropie/ports/uzdoom/uzdoom\n/opt/retropie/ports/lzdoom/lzdoom\n \n- General Settings [IWADs]:\n$home/RetroPie/roms/ports/doom/doomu.wad\n$home/RetroPie/roms/ports/doom/doom2.wad\n \n- General Settings [Always Add These Parameters]:\nDOOMWADDIR=$home/RetroPie/roms/ports/doom\n-config $home/RetroPie/roms/ports/doom/uzdoom.ini\n-savedir $home/RetroPie/roms/ports/doom/uzdoom-saves\n \nExtra Command Line Arguments: +logfile /dev/shm/ZDL.log\n \nAdjust ZDL Theme [-platformtheme qt5ct]: Qt5 Settings"
rp_module_licence="GNU3 https://raw.githubusercontent.com/qbasicer/qzdl/refs/heads/master/LICENSE"
rp_module_repo="git https://github.com/qbasicer/qzdl.git master :_get_commit_qzdl"
rp_module_section="exp"
rp_module_flags=""

function _get_commit_qzdl() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch_tag=master
    local branch_commit="$(git ls-remote https://github.com/qbasicer/qzdl.git $branch_tag HEAD | grep $branch_tag | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
}

function depends_qzdl() {
    #local depends=(qtcreator qtdeclarative5-dev)
    local depends=(cmake qtbase5-dev qt5-qmake qtbase5-dev-tools qtchooser qt5ct whiptail)
    if [[ ! $(apt-cache search qt5-default) == '' ]]; then
        depends+=(qt5-default)
    fi
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_qzdl() {
    gitPullOrClone
}

function build_qzdl() {
    cd $md_build
    mkdir build
    cd build
    cmake ..
    make -j"$(nproc)"
    md_ret_require="$md_build/build/zdl"
}

function install_qzdl() {
    md_ret_files=(
        'build/zdl'
        'bmp_logo.xpm'
        'ico_icon.xpm'
    )
}

function remove_qzdl() {
    if [[ -f /usr/share/applications/ZDL.desktop ]]; then sudo rm -f /usr/share/applications/ZDL.desktop; fi
    if [[ -f "$home/Desktop/ZDL.desktop" ]]; then rm "$home/Desktop/ZDL.desktop"; fi
    if [[ -f "$home/RetroPie/roms/ports/+Start ZDL.sh" ]]; then rm "$home/RetroPie/roms/ports/+Start ZDL.sh"; fi
}

function configure_qzdl() {
    mkRomDir "ports"
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addPort "$md_id" "zdl" "+Start ZDL" "$launch_prefix$md_inst/zdl -platformtheme qt5ct"
    sed -i s'+_PORT_+_SYS_+g' "$romdir/ports/+Start ZDL.sh"

    local shortcut_name
    shortcut_name="ZDL"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=ZDL
GenericName=ZDL
Comment=ZDoom WAD Launcher
Exec=$md_inst/zdl -platformtheme qt5ct
Icon=$md_inst/ico_icon.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=ZDL;ZDoom;WAD;Launcher
StartupWMClass=ZDL
Name[en_US]=ZDL
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    [[ "$md_mode" == "remove" ]] && remove_qzdl
}
