#!/usr/bin/env bash

# This file is NOT part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# Remove or Replace PCSX2 script in: $home/RetroPie-Setup/scriptmodules/emulators/pcsx2.sh
#

# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="pcsx2"
rp_module_desc="PS2 emulator PCSX2"
rp_module_help="PCSX2 is an open source PS2 Emulator                                                                                                                                                                                                     \n \n pcsx2-v2.0.2-linux-appimage-x64-Qt.AppImage \n \n https://pcsx2.net \n \n PCSX2 uses third-party code. \n You can view the licenses for this code by selecting \"Third-Party Notices\" \n ROM Extensions: .bin .iso .img .mdf .z .z2 .bz2 .cso .chd .ima .gz\n\nCopy your PS2 roms to $romdir/ps2\n\nCopy the required BIOS file to $biosdir"
rp_module_licence="GPL3 https://raw.githubusercontent.com/PCSX2/pcsx2/master/COPYING.GPLv3"
rp_module_section="exp"
rp_module_flags="!all x86_64"

function depends_pcsx2() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    #getDepends libfuse2 mesa-vulkan-drivers libvulkan-dev libsdl2-dev matchbox
    getDepends libfuse2 libsdl2-dev matchbox
}

function sources_pcsx2() {
    download "https://github.com/PCSX2/pcsx2/releases/download/v2.0.2/pcsx2-v2.0.2-linux-appimage-x64-Qt.AppImage" "$md_build"
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/pcsx2/pcsx2-pc-assets.tar.gz" "$md_build"
}

function install_pcsx2() {
    chmod 755 "pcsx2-v2.0.2-linux-appimage-x64-Qt.AppImage"; mv 'pcsx2-v2.0.2-linux-appimage-x64-Qt.AppImage' "$md_inst"
    homeDIR=$home; sed -i s+'/home/pi/'+"$homeDIR/"+g "pcsx2.sh"
    chmod 755 "pcsx2.sh"; mv "pcsx2.sh" "$md_inst"
    chmod 755 "PCSX2.desktop"; cp "PCSX2.desktop" "$md_inst"; cp "PCSX2.desktop" "/usr/share/applications/"
    mv "PCSX2.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/PCSX2.desktop"
    mv "PCSX2-128.xpm" "$md_inst"; mv "PS2BIOSRequired.jpg" "$md_inst"

    if [[ ! -d "$home/.config/PCSX2" ]]; then mkdir "$home/.config/PCSX2"; fi
    if [[ ! -d "$home/.config/PCSX2/inis" ]]; then mkdir "$home/.config/PCSX2/inis"; fi
    homeDIR=$home; sed -i s+'/home/pi/'+"$homeDIR/"+g "PCSX2.ini"; sed -i s+'/home/pi/'+"$homeDIR/"+g "PCSX2.ini.pcsx2"
    if [[ ! -f "$home/.config/PCSX2/inis/PCSX2.ini" ]]; then mv "PCSX2.ini" "$home/.config/PCSX2/inis"; fi
    if [[ ! -f "$home/.config/PCSX2/inis/PCSX2.ini.pcsx2" ]]; then mv "PCSX2.ini.pcsx2" "$home/.config/PCSX2/inis"; fi
    if [[ ! -d "$home/.config/PCSX2/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.config/PCSX2/bios"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd001.ps2" ]]; then mv "Mcd001.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd002.ps2" ]]; then mv "Mcd002.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -d "$home/.config/PCSX2/gamesettings" ]]; then mkdir "$home/.config/PCSX2/gamesettings"; fi
    if [[ ! -d "$home/.config/PCSX2/covers" ]]; then mkdir "$home/.config/PCSX2/covers"; fi
    if [[ ! -f "$home/.config/PCSX2/covers/uLaunchELF 4.42d.png" ]]; then mv 'uLaunchELF 4.42d.png' "$home/.config/PCSX2/covers"; fi
    chown -R $__user:$__user "$home/.config/PCSX2"

    if [[ ! -d "$home/RetroPie/roms/ps2" ]]; then mkdir "$home/RetroPie/roms/ps2"; fi
    chmod 755 '+Start PCSX2.sh'; mv '+Start PCSX2.sh' "$home/RetroPie/roms/ps2"
    if [[ ! -f "$home/RetroPie/roms/ps2/gamelist.xml" ]]; then mv 'gamelist.xml' "$home/RetroPie/roms/ps2"; fi
    if [[ ! -d "$home/RetroPie/roms/ps2/media" ]]; then mv 'media' "$home/RetroPie/roms/ps2"; fi
    chown -R $__user:$__user "$home/RetroPie/roms/ps2"
}

function configure_pcsx2() {
    addSystem "ps2"
    addEmulator "$md_id" "pcsx2" "ps2" "XINIT: /opt/retropie/emulators/pcsx2/pcsx2.sh %ROM%"
    if [[ $(cat /opt/retropie/configs/ps2/emulators.cfg | grep -q 'default =' ; echo $?) == '1' ]]; then echo 'default = "pcsx2"' >> /opt/retropie/configs/ps2/emulators.cfg; fi
    sed -i 's/default\ =.*/default\ =\ \"pcsx2\"/g' /opt/retropie/configs/ps2/emulators.cfg
}
