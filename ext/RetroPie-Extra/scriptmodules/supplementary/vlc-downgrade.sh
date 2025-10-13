#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# RetroPie-Extra
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# Workaround for libvlc issue with video previews in ES by Suggested by Lolonois Converted to RetroPie Script by RapidEdwin08
# https://retropie.org.uk/forum/topic/35717/emulationstation-video-previews-on-raspberry-pi-5/17

pkgs=(libvlc5 libvlc-bin libvlccore9 vlc-bin vlc-data vlc-plugin-base)
ver="3.0.20-0+rpt6+deb12u1"
vlc_version=$(dpkg -l | grep libvlc-bin | awk '{print $3}')

rp_module_id="vlc-downgrade"
rp_module_desc="Downgrade VLC for ES Video Snap Delay Issue        Related to libvlc: [v1:3.0.21-0]                         Current Version of libvlc: [v$vlc_version]"
rp_module_section="config"
rp_module_flags="rpi !:\$__os_debian_ver:-gt:12 !:\$__os_debian_ver:-lt:11"

function _downgrade_libvlc() {
    if [[ ! -d /dev/shm/vlc-downgrade ]]; then mkdir /dev/shm/vlc-downgrade; fi
	pushd /dev/shm/vlc-downgrade > /dev/null 2>&1
    for p in "${pkgs[@]}"; do
      arch="arm64"
      if [[ "$p" == "vlc-data" ]] ; then
        arch="all"
      fi
	  wget "http://archive.raspberrypi.org/debian/pool/main/v/vlc/${p}_${ver}_${arch}.deb"
    done
	
	sudo dpkg -i *.deb
	sudo apt-mark hold "${pkgs[@]}"
	popd
	rm -Rf /dev/shm/vlc-downgrade/ > /dev/null 2>&1
}

function _upgrade_libvlc() {
    if [[ ! -d /dev/shm/vlc-downgrade ]]; then mkdir /dev/shm/vlc-downgrade; fi
	pushd /dev/shm/vlc-downgrade > /dev/null 2>&1
    for p in "${pkgs[@]}"; do
      arch="arm64"
      if [[ "$p" == "vlc-data" ]] ; then
        arch="all"
      fi
	  sudo apt-mark unhold "${pkgs[@]}"
	  echo HOLD has been REMOVED for [v$ver]
	  echo Attempting to UPGRADE "${pkgs[@]}"
	  sudo apt-get install "${pkgs[@]}"
    done
}

function _fix_apt_install() {
    sudo apt --fix-broken install -y
}

function gui_vlc-downgrade() {
    local default
    while true; do
        vlc_version=$(dpkg -l | grep libvlc-bin | awk '{print $3}')
		local cmd=(dialog --backtitle "$__backtitle" --cancel-label "Exit" --item-help --help-button --default-item "$default" --menu "Issue with Video Snap Delay in ES Applies to libvlc: [v1:3.0.21-0]\nCurrent VLC Version: $vlc_version\n" 22 76 16)
        local options=(
            1 "Downgrade VLC to [v3.0.20-0]"
            "1 Downgrade VLC to [v3.0.20-0] if experiencing ES Video Snap Delay"
            2 "Remove [HOLD] of [v3.0.20-0] + Upgrade VLC"
            "2 Remove the HOLD of [v3.0.20-0] + Upgrade VLC to Latest Version"
            3 "Fix Broken Install [sudo apt --fix-broken install]"
            "3 Fix Broken Install [sudo apt --fix-broken install]"
		)

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ "${choice[@]:0:4}" == "HELP" ]]; then
            choice="${choice[@]:3}"
            default="${choice/%\ */}"
            choice="${choice#* }"
            printMsgs "dialog" "$choice"
            continue
        fi
        default="$choice"

        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    dialog --defaultno --yesno "This will Attempt to DOWNGRADE VLC to [v$ver]\n \n*ONLY DOWNGRADE IF HAVING VIDEO SNAP DELAY ISSUES IN ES*\n \nMay Interfere with [sudo apt upgrade] until the HOLD is REMOVED\n \nFix Broken Install [sudo apt --fix-broken install] Available If needed\n \nAre you sure you want to continue ?" 22 76 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _downgrade_libvlc
                    ;;
                2)
                    dialog --defaultno --yesno "This will Attempt to REMOVE the HOLD of [v$ver] + Attempt to UPGRADE VLC to Latest Version\n \nAre you sure you want to continue ?" 22 76 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _upgrade_libvlc
                    ;;
                3)
                    dialog --defaultno --yesno "This will Attempt to FIX Broken Install [sudo apt --fix-broken install]\n \nAre you sure you want to continue ?" 22 76 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _fix_apt_install
                    ;;
            esac
        else
            break
        fi
    done
}
