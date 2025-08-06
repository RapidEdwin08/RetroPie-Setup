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
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

# Version put here to be displayed in Help
#pcsx2_ver="v2.0.2"; # 2f46e5a8406e4832ba60c5ab1ba2fd16a074ab1f 20240712 # Prior Version Reference
pcsx2_ver="v2.4.0"; # e4af1c424451c6b65c5c387404315cef77e9901b 20250629

rp_module_id="pcsx2-x64"
rp_module_desc="PS2 emulator PCSX2 Optimized for x86_64"
rp_module_help="pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage \n \n https://github.com/PCSX2/pcsx2/releases/tag/${pcsx2_ver} \n \n PCSX2 uses third-party code. You can view the licenses for this code by selecting \"Third-Party Notices\" \n \nROM Extensions: .bin .iso .img .mdf .z .z2 .bz2 .cso .chd .ima .gz\n\nCopy your PS2 roms to $romdir/ps2\nCopy the required BIOS file to $biosdir\n \n\"PlayStation\" and \"PS2\" are registered trademarks of Sony Interactive Entertainment.\n \nThis project is not affiliated in any way with \nSony Interactive Entertainment."
rp_module_licence="GPL3 https://raw.githubusercontent.com/PCSX2/pcsx2/master/COPYING.GPLv3"
rp_module_section="exp"
rp_module_flags="!all x86_64"

function depends_pcsx2-x64() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    getDepends libfuse2 mesa-vulkan-drivers libvulkan-dev libsdl2-dev matchbox-window-manager
}

function install_bin_pcsx2-x64() {
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/pcsx2/pcsx2-pc-assets.tar.gz" "$md_build"
    download "https://github.com/PCSX2/pcsx2/releases/download/${pcsx2_ver}/pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage" "$md_build"

    pushd "$md_build"
    chmod 755 "pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage"; mv "pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage" "$md_inst/pcsx2-linux-appimage-x64-Qt.AppImage"
    sed -i s+'/home/pi/'+"$home/"+g "pcsx2.sh"; chmod 755 "pcsx2.sh"; mv "pcsx2.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "pcsx2-qjoy.sh"; chmod 755 "pcsx2-qjoy.sh"; mv "pcsx2-qjoy.sh" "$md_inst"

    chmod 755 "PCSX2.desktop"; cp "PCSX2.desktop" "$md_inst"; cp "PCSX2.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "PCSX2.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/PCSX2.desktop"; fi
    mv "PCSX2-128.xpm" "$md_inst"; mv "PS2BIOSRequired.jpg" "$md_inst"

    if [[ ! -d "$home/.config/PCSX2" ]]; then mkdir "$home/.config/PCSX2"; fi
    if [[ ! -d "$home/.config/PCSX2/inis" ]]; then mkdir "$home/.config/PCSX2/inis"; fi
    sed -i s+'/home/pi/'+"$home/"+g "PCSX2.ini"; sed -i s+'/home/pi/'+"$home/"+g "PCSX2.ini.pcsx2"
    if [[ ! -f "$home/.config/PCSX2/inis/PCSX2.ini" ]]; then mv "PCSX2.ini" "$home/.config/PCSX2/inis"; fi
    if [[ ! -f "$home/.config/PCSX2/inis/PCSX2.ini.pcsx2" ]]; then mv "PCSX2.ini.pcsx2" "$home/.config/PCSX2/inis"; fi
    if [[ ! -d "$home/.config/PCSX2/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.config/PCSX2/bios"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd001.ps2" ]]; then mv "Mcd001.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd002.ps2" ]]; then mv "Mcd002.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -d "$home/.config/PCSX2/gamesettings" ]]; then mkdir "$home/.config/PCSX2/gamesettings"; fi
    if [[ ! -d "$home/.config/PCSX2/covers" ]]; then mkdir "$home/.config/PCSX2/covers"; fi
    if [[ ! -f "$home/.config/PCSX2/covers/uLaunchELF 4.42d.png" ]]; then mv 'uLaunchELF 4.42d.png' "$home/.config/PCSX2/covers"; fi
    chown -R $__user:$__user "$home/.config/PCSX2"
    if [[ ! -d "$md_conf_root/ps2/pcsx2" ]]; then mkdir "$md_conf_root/ps2/pcsx2"; fi
    moveConfigDir "$home/.config/pcsx2" "$md_conf_root/ps2/pcsx2"
    chown -R $__user:$__user -R "$md_conf_root/ps2/pcsx2"

    mkRomDir "ps2"
    chmod 755 '+Start PCSX2.z2'; mv '+Start PCSX2.z2' "$romdir/ps2"
    mkRomDir "ps2/media"; mkRomDir "ps2/media/image"; mkRomDir "ps2/media/marquee"; mkRomDir "ps2/media/video"
    mv 'media/image/PCSX2.png' "$romdir/ps2/media/image"; mv 'media/marquee/PCSX2.png' "$romdir/ps2/media/marquee"; mv 'media/video/PCSX2.mp4' "$romdir/ps2/media/video"
    mv 'media/image/uLaunchELF.png' "$romdir/ps2/media/image"; mv 'media/marquee/uLaunchELF.png' "$romdir/ps2/media/marquee"; mv 'media/video/uLaunchELF.mp4' "$romdir/ps2/media/video"
    if [[ ! -f "$romdir/ps2/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/ps2"; else mv 'gamelist.xml' "$romdir/ps2/gamelist.xml.pcsx2"; fi
    chown -R $__user:$__user -R "$romdir/ps2"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function remove_pcsx2-x64() {
    if [[ -f /usr/share/applications/PCSX2.desktop ]]; then sudo rm -f /usr/share/applications/PCSX2.desktop; fi
    if [[ -f "$home/Desktop/PCSX2.desktop" ]]; then rm -f "$home/Desktop/PCSX2.desktop"; fi
    if [[ -f "$romdir/ps2/+Start PCSX2.z2" ]]; then rm "$romdir/ps2/+Start PCSX2.z2"; fi
}

function configure_pcsx2-x64() {
    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'ps2_StartPCSX2 = "pcsx2"' ; echo $?) == '1' ]]; then echo 'ps2_StartPCSX2 = "pcsx2"' >> /opt/retropie/configs/all/emulators.cfg; fi

    addSystem "ps2"
    local launch_prefix=XINIT-WM; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WM)" == '' ]]; then local launch_prefix=XINIT; fi
    addEmulator 1 "$md_id" "ps2" "$launch_prefix:$md_inst/pcsx2.sh %ROM%"
    local launch_prefix=XINIT-WMC; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WMC)" == '' ]]; then local launch_prefix=XINIT; fi
    addEmulator 0 "$md_id-editor" "ps2" "$launch_prefix:$md_inst/pcsx2.sh --editor"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-editor+qjoypad" "ps2" "$launch_prefix:$md_inst/pcsx2-qjoy.sh --editor"
    fi
}
