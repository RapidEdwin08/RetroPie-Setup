#!/usr/bin/env bash

# This file is part of RetroPie-Extra, a supplement to RetroPie.
# For more information, please visit:
#
# https://github.com/RetroPie/RetroPie-Setup
# https://github.com/Exarkuniv/RetroPie-Extra
# https://github.com/RapidEdwin08/RetroPie-Setup
# https://www.richwhitehouse.com/jaguar/index.php
#
# See the LICENSE file distributed with this source and at
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="bigpemu"
rp_module_desc="BigPEmu Atari Jaguar/CD Emulator"
rp_module_help="BigPEmu is an Atari Jaguar compatibile with every game in the Jaguar Retail library plus Jaguar CD Support.\n\nCopy your Atari Jaguar/CD roms to:\n$romdir/atarijaguar\n$romdir/jaguarcd"
rp_module_licence="MIT https://www.richwhitehouse.com/jaguar/index.php?content=faq"
rp_module_section="exp"
rp_module_flags="!all aarch64 x86_64"

function depends_bigpemu() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    local depends
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function install_bin_bigpemu() {
    local bigpemu_version="v119"
    local bigpemu_platform=Linux64
    if isPlatform "aarch64"; then bigpemu_platform=LinuxARM64; fi
    local bigpemu_tar="BigPEmu_${bigpemu_platform}_${bigpemu_version}.tar.gz"

    mkdir -p "$md_build"
    pushd "$md_build"

    downloadAndExtract "https://www.richwhitehouse.com/jaguar/builds/${bigpemu_tar}" "$(dirname "$md_inst")" # bigpemu.tar.gz/bigpemu/*
    chmod 755 "$md_inst/bigpemu"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function game_data_bigpemu() {
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/bigpemu-rp-assets.tar.gz" "$romdir/atarijaguar"
    if [[ ! -f "$romdir/atarijaguar/gamelist.xml" ]]; then mv "$romdir/atarijaguar/gamelist.xml.jaguar" "$romdir/atarijaguar/gamelist.xml"; fi
    mv "$romdir/atarijaguar/media/image/BigPEmu-atarijaguar.png" "$romdir/atarijaguar/media/image/BigPEmu.png"; rm -f "$romdir/atarijaguar/media/image/BigPEmu-jaguarcd.png"
    mv "$romdir/atarijaguar/retropie.pkg" "$md_inst"
    chown -R $__user:$__user "$romdir/atarijaguar"

    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/bigpemu-rp-assets.tar.gz" "$romdir/jaguarcd"
    if [[ ! -f "$romdir/jaguarcd/gamelist.xml" ]]; then mv "$romdir/jaguarcd/gamelist.xml.jaguar" "$romdir/jaguarcd/gamelist.xml"; fi
    mv "$romdir/jaguarcd/media/image/BigPEmu-jaguarcd.png" "$romdir/jaguarcd/media/image/BigPEmu.png"; rm -f "$romdir/jaguarcd/media/image/BigPEmu-atarijaguar.png"
    mv "$romdir/jaguarcd/retropie.pkg" "$md_inst"
    chown -R $__user:$__user "$romdir/jaguarcd"
}

function remove_bigpemu() {
    rm -f "/usr/share/applications/bigpemu.desktop"
    rm -f "$home/Desktop/bigpemu.desktop"
    rm -f "/usr/share/applications/BigPEmu.desktop"
    rm -f "$home/Desktop/BigPEmu.desktop"
    rm -f "$romdir/atarijaguar/+Start BigPEmu.gui"
    rm -f "$romdir/jaguarcd/+Start BigPEmu.gui"
}

function configure_bigpemu() {
    mkRomDir "atarijaguar"
    mkRomDir "jaguarcd"

    mkdir -p "$home/.bigpemu_userdata"
    mkdir -p "$md_conf_root/atarijaguar"
    moveConfigDir "$home/.bigpemu_userdata" "$md_conf_root/atarijaguar"
    chown -R $__user:$__user "$md_conf_root/atarijaguar"

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'atarijaguar_StartBigPEmu = "bigpemu-ui"' ; echo $?) == '1' ]]; then echo 'atarijaguar_StartBigPEmu = "bigpemu-ui"' >> /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'jaguarcd_StartBigPEmu = "bigpemu-ui"' ; echo $?) == '1' ]]; then echo 'jaguarcd_StartBigPEmu = "bigpemu-ui"' >> /opt/retropie/configs/all/emulators.cfg; fi

    # atarijaguar .j64 .jag .zip 
    addSystem "atarijaguar" "Atari Jaguar" ".bigpimg .cof .rom .abs .cue .cdi .j64 .jag .zip .gui"
    touch "$romdir/atarijaguar/+Start BigPEmu.gui"; chown -R $__user:$__user "$romdir/atarijaguar"

    # jaguarcd .bigpimg .cof .rom .abs .cue .cdi
    addSystem "jaguarcd" "Atari Jaguar CD" ".bigpimg .cof .rom .abs .cue .cdi .j64 .jag .zip .gui"
    touch "$romdir/jaguarcd/+Start BigPEmu.gui"; chown -R $__user:$__user "$romdir/jaguarcd"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"

    addEmulator 1 "$md_id" "atarijaguar" "$launch_prefix$md_inst/bigpemu %ROM%"
    addEmulator 0 "$md_id-ui" "atarijaguar" "$launch_prefix$md_inst/bigpemu"

    addEmulator 1 "$md_id" "jaguarcd" "$launch_prefix$md_inst/bigpemu %ROM%"
    addEmulator 0 "$md_id-ui" "jaguarcd" "$launch_prefix$md_inst/bigpemu"

    [[ "$md_mode" == "remove" ]] && remove_bigpemu
    [[ "$md_mode" == "install" ]] && game_data_bigpemu
    [[ "$md_mode" == "install" ]] && shortcuts_icons_bigpemu
}

function shortcuts_icons_bigpemu() {
    #pushd "$md_inst"
    #bash "$md_inst/make_desktop.sh" # Use sh provided to create .desktop shortcut
    #chmod 755 "bigpemu.desktop"; rm -f "/usr/share/applications/bigpemu.desktop"; cp "bigpemu.desktop" "/usr/share/applications/"
    #if [[ -d "$home/Desktop" ]]; then mv -f "bigpemu.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/bigpemu.desktop"; fi
    #popd

    local shortcut_name
    shortcut_name="BigPEmu"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Atari Jaguar Emulator
Exec=$md_inst/bigpemu
Icon=$md_inst/bigpemu-icon.png
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Atari;Jaguar;Emulator
StartupWMClass=$shortcut_name
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
}
