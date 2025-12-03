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

rp_module_id="desktop-system"
rp_module_desc="Add Desktop ES System [desktop = XINIT:startx] \nNOTE: This does NOT Install any Desktop Environments"
rp_module_licence="GPL3 https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/LICENSE.md"
rp_module_section="config"
rp_module_flags=""

function gui_desktop-system() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "Add Desktop ES System [desktop = XINIT:startx] \nNOTE: This does NOT Install any Desktop Environments\n \n- /etc/emulationstation/es_systems.cfg:\n  <system>\n    <name>desktop</name>\n    <fullname>desktop</fullname>\n    <path>$romdir/desktop</path>\n    <extension>.sh .SH</extension>\n    <command>bash %ROM%</command>\n    <platform>pc</platform>\n    <theme>desktop</theme>\n  </system>\n \n- $md_conf_root/ports/desktop/emulators.cfg:\n  desktop = \"XINIT:startx\"" 25 60 5 \
        "1" "ADD [_PORT_ desktop] System" \
        "2" "DEL [_PORT_ desktop] System" \
        "3" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            md_mode=install
            configure_desktop-system
            echo ADD [desktop] ES System COMPLETE...; sleep 3
            #gui_desktop-system
            ;;
        2)
            md_mode=remove
            configure_desktop-system
            echo DELETE [desktop] ES System COMPLETE...; sleep 3
            #gui_desktop-system
            ;;
        3)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function remove_desktop-system() {
    delSystem "desktop"
    delEmulator "desktop" "desktop"
    rm -f "$md_conf_root/ports/desktop/emulators.cfg" 2>/dev/null
    rmdir "$md_conf_root/ports/desktop" 2>/dev/null
    rm -f "$romdir/ports/Desktop.sh" 2>/dev/null
    rm -f "$romdir/desktop/Desktop.sh" 2>/dev/null
    rmdir "$romdir/desktop" 2>/dev/null
    rm -f "$romdir/ports/+Start Desktop.sh" 2>/dev/null
    rm -f "$romdir/desktop/+Start Desktop.sh" 2>/dev/null
}

function configure_desktop-system() {
    addPort "desktop" "desktop" "+Start Desktop" "XINIT:startx"
    addSystem "desktop" "desktop" ".sh" "pc" "desktop" "bash %ROM%" "$home/RetroPie/roms/desktop"
    # <command>/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ desktop %ROM%</command> -->> <command>bash %ROM%</command>
    sed -i 's+/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ desktop+bash+g' /etc/emulationstation/es_systems.cfg
    sed -i 's+<platform>desktop</platform>+<platform>pc</platform>+g' /etc/emulationstation/es_systems.cfg
    if [ -f /opt/retropie/configs/all/emulationstation/es_systems.cfg ]; then
        sed -i 's+/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ desktop+bash+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
        sed -i 's+<platform>desktop</platform>+<platform>pc</platform>+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
        chown $__user:$__user /opt/retropie/configs/all/emulationstation/es_systems.cfg
    fi
    mv "$md_conf_root/desktop" "$md_conf_root/ports" 2>/dev/null; chown -R $__user:$__user "$md_conf_root/ports/desktop" 2>/dev/null; rmdir "$md_conf_root/desktop" 2>/dev/null
    mkRomDir "desktop"
    if [[ ! -f "$romdir/desktop/+Start Desktop.sh" ]]; then cp "$romdir/ports/+Start Desktop.sh" "$romdir/desktop/+Start Desktop.sh" 2>/dev/null; chown $__user:$__user "$romdir/desktop/+Start Desktop.sh" 2>/dev/null; fi

    [[ "$md_mode" == "remove" ]] && remove_desktop-system
}
