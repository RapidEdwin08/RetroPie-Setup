#!/usr/bin/env bash

# This file is part of RetroPie-Extra, a supplement to RetroPie.
# For more information, please visit:
#
# https://github.com/RetroPie/RetroPie-Setup
# https://github.com/Exarkuniv/RetroPie-Extra
# https://github.com/RapidEdwin08/RetroPie-Setup
# https://www.richwhitehouse.com/ki/index.php
#
# See the LICENSE file distributed with this source and at
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="biginstinct"
rp_module_desc="BigInstinct Killer Instinct 1/2 Emulator"
rp_module_help="1) Prepare Killer Instinct roms for BigHardMaker:\n$home/bighardmaker/kinst.zip\n$home/bighardmaker/kinst/kinst.chd\n\n$home/bighardmaker/kinst2.zip\n$home/bighardmaker/kinst2/kinst2.chd\n\n2) Create Killer Instinct roms with BigHardMaker:\neg. [PC]  ~/bighardmaker/bighardmaker_x64\neg. [Pi]  ~/bighardmaker/bighardmaker_arm64\n\n3) Copy {.bighard} Killer Instinct roms to:\n$romdir/arcade/kinst.bighard\n$romdir/arcade/kinst2.bighard"
rp_module_licence="MIT https://www.richwhitehouse.com/ki/index.php?content=faq"
rp_module_section="exp"
rp_module_flags="!all aarch64 x86_64"

function depends_biginstinct() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    local depends
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function install_bin_biginstinct() { # https://www.richwhitehouse.com/ki/builds/BigInstinct_Linux64_v101.tar.gz
    local biginstinct_version="v101"
    local biginstinct_platform=Linux64
    if isPlatform "aarch64"; then biginstinct_platform=LinuxARM64; fi
    local biginstinct_tar="BigInstinct_${biginstinct_platform}_${biginstinct_version}.tar.gz"

    mkdir -p "$md_build"
    pushd "$md_build"

    downloadAndExtract "https://www.richwhitehouse.com/ki/builds/${biginstinct_tar}" "$(dirname "$md_inst")" # BigInstinct.tar.gz/biginstinct/*
    chmod 755 "$md_inst/biginstinct"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd

    downloadAndExtract "https://www.richwhitehouse.com/ki/hard/bighardmaker_v10_linux.tar.gz" "$home" # bighardmaker_v10_linux.tar.gz/bighardmaker/*
    if isPlatform "aarch64"; then
        chmod 755 "$home/bighardmaker/bighardmaker_arm64"; chmod 755 "$home/bighardmaker/libchdr_arm64.so"
        rm -f "$home/bighardmaker/bighardmaker_x64"; rm -f "$home/bighardmaker/libchdr_x64.so"
    else
        chmod 755 "$home/bighardmaker/bighardmaker_x64"; chmod 755 "$home/bighardmaker/libchdr_x64.so"
        rm -f "$home/bighardmaker/bighardmaker_arm64"; rm -f "$home/bighardmaker/libchdr_arm64.so"
    fi
    chown -R $__user:$__user "$home/bighardmaker"
}

function game_data_biginstinct() {
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/biginstinct-rp-assets.tar.gz" "$romdir/arcade"
    if [[ ! -f "$romdir/arcade/gamelist.xml" ]]; then mv "$romdir/arcade/gamelist.xml.arcade" "$romdir/arcade/gamelist.xml"; fi
    mv "$romdir/arcade/retropie.pkg" "$md_inst"
    chown -R $__user:$__user "$romdir/arcade"

    mkdir -p "$home/bighardmaker"
    download "https://www.richwhitehouse.com/ki/hard/bighardmaker_v10_linux.tar.gz" "$home/bighardmaker"
    download "https://www.richwhitehouse.com/ki/hard/BigHardMaker_v10_Win_x64.zip" "$home/bighardmaker"
    sed -i "s+^__user=.*+__user=\"$__user\"+g" "$romdir/arcade/run_bighardmaker.sh"
    cp "$romdir/arcade/run_bighardmaker.sh" /dev/shm/tmp.sh; mv /dev/shm/tmp.sh "$home/RetroPie/retropiemenu/run_bighardmaker.sh"
    chmod 755 "$home/RetroPie/retropiemenu/run_bighardmaker.sh"; chown $__user:$__user "$home/RetroPie/retropiemenu/run_bighardmaker.sh"
    mv "$romdir/arcade/run_bighardmaker.sh" "$home/bighardmaker" # biginstinct-rp-assets.tar.gz
    chmod 755 "$home/bighardmaker/run_bighardmaker.sh"
    chown -R $__user:$__user "$home/bighardmaker"
}

function remove_biginstinct() {
    rm -f "/usr/share/applications/biginstinct.desktop"
    rm -f "$home/Desktop/biginstinct.desktop"
    rm -f "/usr/share/applications/BigInstinct.desktop"
    rm -f "$home/Desktop/BigInstinct.desktop"
    rm -f "$romdir/arcade/+Start BigInstinct.chd"
    rm -f "$home/RetroPie/retropiemenu/run_bighardmaker.sh"
}

function configure_biginstinct() {
    mkRomDir "arcade"
    ln -s "$romdir/arcade" "$md_inst/arcade" # Emulator does not see the Symbolic Link :(

    mkdir -p "$home/.biginstinct_userdata"
    mkdir -p "$md_conf_root/arcade"
    moveConfigDir "$home/.biginstinct_userdata" "$md_conf_root/arcade/biginstinct_userdata"
    chown -R $__user:$__user "$md_conf_root/arcade"

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'arcade_StartBigInstinct = "biginstinct-ui"' ; echo $?) == '1' ]]; then echo 'arcade_StartBigInstinct = "biginstinct-ui"' >> /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'arcade_kinst = "biginstinct"' ; echo $?) == '1' ]]; then echo 'arcade_kinst = "biginstinct"' >> /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'arcade_kinst2 = "biginstinct"' ; echo $?) == '1' ]]; then echo 'arcade_kinst2 = "biginstinct"' >> /opt/retropie/configs/all/emulators.cfg; fi

    # Add .bighard to Arcade .7z .bighard .cue .fba .iso .zip
    addSystem "arcade" "Arcade" ".7z .bighard .cue .fba .iso .zip"
    touch "$romdir/arcade/+Start BigInstinct.bighard"; chown -R $__user:$__user "$romdir/arcade"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"

    addEmulator 1 "$md_id" "arcade" "$launch_prefix$md_inst/biginstinct %ROM%"
    addEmulator 0 "$md_id-ui" "arcade" "$launch_prefix$md_inst/biginstinct"

    [[ "$md_mode" == "remove" ]] && remove_biginstinct
    [[ "$md_mode" == "install" ]] && game_data_biginstinct
    [[ "$md_mode" == "install" ]] && shortcuts_icons_biginstinct
}

function shortcuts_icons_biginstinct() {
    #pushd "$md_inst"
    #bash "$md_inst/make_desktop.sh" # Use sh provided to create .desktop shortcut
    #chmod 755 "biginstinct.desktop"; rm -f "/usr/share/applications/biginstinct.desktop"; cp "biginstinct.desktop" "/usr/share/applications/"
    #if [[ -d "$home/Desktop" ]]; then mv -f "biginstinct.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/biginstinct.desktop"; fi
    #popd

    local shortcut_name
    shortcut_name="BigInstinct"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Killer Instinct 1/2 Emulator
Exec=$md_inst/biginstinct
Icon=$md_inst/biginstinct-icon.png
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Arcade;KillerInstinct;Emulator
StartupWMClass=$shortcut_name
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
}
