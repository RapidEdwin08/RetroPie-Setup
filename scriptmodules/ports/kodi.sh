#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="kodi"
rp_module_desc="Kodi - Open source home theatre software"
rp_module_licence="GPL2 https://raw.githubusercontent.com/xbmc/xbmc/master/LICENSE.md"
rp_module_section="opt"
rp_module_flags="!mali !osmc !xbian"

function _update_hook_kodi() {
    # to show as installed in retropie-setup 4.x
    hasPackage kodi && mkdir -p "$md_inst"
}

function depends_kodi() {
    # Raspberry Pi OS
    if [[ "$__os_id" = "Raspbian" ]] && isPlatform "rpi"; then
        if [[ "$__os_debian_ver" -le 10 ]]; then
            if [[ "$md_mode" == "install" ]]; then
                # remove old repository
                rm -f /etc/apt/sources.list.d/mene.list
                echo "deb http://pipplware.pplware.pt/pipplware/dists/$__os_codename/main/binary/ ./" >/etc/apt/sources.list.d/pipplware.list
                download http://pipplware.pplware.pt/pipplware/key.asc - | apt-key add - &>/dev/null
            else
                rm -f /etc/apt/sources.list.d/pipplware.list
                apt-key del 4096R/BAA567BB >/dev/null
            fi
        fi
        if [[ "$__os_debian_ver" -gt 10 ]]; then
            # install Kodi from the RPI repos directly
            # make sure we're not installing Debian/Raspbian version by pinning the origin of the packages
            local apt_pin_file="/etc/apt/preferences.d/01-rpie-pin-kodi"
            if [[ ! -f "$apt_pin_file" ]]; then
                echo -e "Package: kodi*\nPin: release o=Raspberry Pi Foundation\nPin-Priority: 900" > "$apt_pin_file"
            fi
        fi
    # ubuntu
    elif [[ -n "$__os_ubuntu_ver" ]] && isPlatform "x86"; then
        if [[ "$md_mode" == "install" ]]; then
            apt-add-repository -y ppa:team-xbmc/ppa
        else
            apt-add-repository --remove -y ppa:team-xbmc/ppa
        fi
    # others
    else
        md_ret_errors+=("Sorry, but kodi is not installable for your OS/Platform via RetroPie-Setup")
        return 1
    fi

    # required for reboot/shutdown options. Don't try and remove if removing dependencies
    #[[ "$md_mode" == "install" ]] && getDepends policykit-1
    if [[ "$md_mode" == "install" ]]; then
        if [[ $(apt-cache search policykit-1 | grep 'policykit-1 ') == '' ]]; then
            getDepends polkitd
        else
            getDepends policykit-1
        fi
    fi

    addUdevInputRules
}

function install_bin_kodi() {
    # force aptInstall to get a fresh list before installing
    __apt_update=0

    # not all the kodi packages may be available depending on repository
    # so we will check and install what's available
    local all_pkgs=(kodi kodi-peripheral-joystick kodi-inputstream-adaptive kodi-vfs-libarchive kodi-vfs-sftp kodi-vfs-nfs)
    compareVersions "$__os_ubuntu_ver" lt 22.04 && all_pkgs+=(kodi-inputstream-rtmp)
    local avail_pkgs=()
    local pkg
    for pkg in "${all_pkgs[@]}"; do
        # check if the package is available - we use "madison" rather than "show"
        # as madison won't show referenced virtual packages which we don't want
        local ret=$(apt-cache madison "$pkg" 2>/dev/null)
        [[ -n "$ret" ]] && avail_pkgs+=("$pkg")
    done
    aptInstall "${avail_pkgs[@]}"
}

function remove_kodi() {
    aptRemove kodi
    rp_callModule kodi depends remove
    rm -f "$romdir/ports/Kodi.sh"
    rm -f "$romdir/kodi/Kodi.sh"
    rm -f "$romdir/ports/+Start Kodi.sh"
    rm -f "$romdir/kodi/+Start Kodi.sh"
}

function configure_kodi() {
    moveConfigDir "$home/.kodi" "$md_conf_root/kodi"

    addPort "$md_id" "kodi" "+Start Kodi" "kodi-standalone"

    addSystem "kodi" "kodi" ".sh" "pc" "kodi" "bash %ROM%" "$home/RetroPie/roms/kodi"
    # <command>/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ kodi %ROM%</command> -->> <command>bash %ROM%</command>
    sed -i 's+/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ kodi+bash+g' /etc/emulationstation/es_systems.cfg
    if [ -f /opt/retropie/configs/all/emulationstation/es_systems.cfg ]; then
        sed -i 's+/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ kodi+bash+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
        chown $__user:$__user /opt/retropie/configs/all/emulationstation/es_systems.cfg
    fi
    if [[ ! -f "$romdir/kodi/+Start Kodi.sh" ]]; then cp "$romdir/ports/+Start Kodi.sh" "$romdir/kodi/+Start Kodi.sh"; chown $__user:$__user "$romdir/kodi/+Start Kodi.sh"; fi

    [[ "$md_mode" == "install" ]] && shortcuts_icons_kodi
    [[ "$md_mode" == "remove" ]] && remove_kodi
}

function shortcuts_icons_kodi() {
    local shortcut_name
    shortcut_name="Kodi"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name Media Center (formerly XBMC) 
Exec=kodi --standalone -fs
Icon=kodi
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Kodi;XBMC
StartupWMClass=Kodi
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/kodi.desktop"; rm -f "/usr/share/applications/kodi-fs.desktop"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
}
