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
# Workaround for GPU Reset Issues on RPi3 Suggested by mitu Converted to RetroPie Script by RapidEdwin08
# https://retropie.org.uk/forum/topic/35734/a-temporary-unofficial-patch-fixes-the-gpu-reset-malfunction-on-the-rpi-3-and-rpi-zero-2/13
#

rp_module_id="vc4-dkms"
rp_module_desc="Modified vc4 Linux kernel module for RPi3 + KMS\n\nhttps://github.com/cmitu/vc4-dkms/\n\nDownstream Raspberry Pi Linux kernel version with the following modifications/patches:\n\n- workaround for GPU reset error\n  raspberrypi/linux#5780\n\n- enable interlaced video modes for the DPI port\n  raspberrypi/linux#2668"
rp_module_section="config"
rp_module_flags="!all rpi3 !:\$__os_debian_ver:-gt:13 !:\$__os_debian_ver:-lt:12"

function _install_vc4dkms() {
    getDepends dkms
    if [[ ! -d /opt/vc4-dkms ]]; then
        pushd /opt > /dev/null 2>&1
        git clone https://github.com/cmitu/vc4-dkms
        dkms add vc4-dkms
        popd
    fi
    pushd /opt > /dev/null 2>&1
    dkms install vc4-dkms/1.0
    popd
}

function _remove_vc4dkms() {
    getDepends dkms
    if [[ ! -d /opt/vc4-dkms ]]; then
        pushd /opt > /dev/null 2>&1
        git clone https://github.com/cmitu/vc4-dkms
        dkms add vc4-dkms
        popd
    fi
    pushd /opt > /dev/null 2>&1
    dkms remove -m vc4-dkms -v 1.0
    popd
}

function _clean_vc4dkms() {
    rm -Rf /opt/vc4-dkms
}

function gui_vc4-dkms() {
    local default
    while true; do
		local cmd=(dialog --backtitle "$__backtitle" --cancel-label "Back" --item-help --help-button --default-item "$default" --menu "Temporary Workaround for GPU RESET Issue that Applies to RPi3 + KMS\n\nREBOOT REQUIRED for changes to take effect\n\n dkms status:\n$(dkms status | grep vc4-dkms)" 22 76 16)
        local options=(
            1 "Install Modified [vc4-dkms] Linux kernel module"
            "1 sudo dkms install vc4-dkms/1.0"
            2 "Remove Modified [vc4-dkms] Linux kernel module"
            "2 sudo dkms remove -m vc4-dkms -v 1.0"
            3 "Clean Up [vc4-dkms] Source"
            "3 sudo rm -Rf /opt/vc4-dkms"
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
                    dialog --defaultno --yesno "This will Attempt to INSTALL Modified [vc4-dkms] Linux kernel module\n \nAre you sure you want to continue ?\n\n dkms status:\n$(dkms status | grep vc4-dkms)" 22 76 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _install_vc4dkms
                    ;;
                2)
                    dialog --defaultno --yesno "This will Attempt to REMOVE Modified [vc4-dkms] Linux kernel module\n \nAre you sure you want to continue ?\n\n dkms status:\n$(dkms status | grep vc4-dkms)" 22 76 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _remove_vc4dkms
                    ;;
                3)
                    dialog --defaultno --yesno "This will Attempt to CLEAN [vc4-dkms] Source from [/opt/vc4-dkms]\n \nAre you sure you want to continue ?\n\n$(ls /opt/vc4-dkms/* 2>/dev/null)" 22 76 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _clean_vc4dkms
                    ;;
            esac
        else
            break
        fi
    done
}
