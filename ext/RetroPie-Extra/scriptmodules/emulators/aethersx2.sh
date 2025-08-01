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

rp_module_id="aethersx2"
rp_module_desc="PS2 Emulator Optimized for ARM"
rp_module_help="AetherSX2-v1.5-3606.AppImage \n \n http://web.archive.org/web/20240222085515/https://www.aethersx2.com/archive/?dir=desktop/linux \n \n AetherSX2 uses third-party code. You can view the licenses for this code by selecting \"Third-Party Notices\" \n \nROM Extensions: .bin .iso .img .mdf .z .z2 .bz2 .cso .chd .ima .gz\n\nCopy your PS2 roms to $romdir/ps2\nCopy the required BIOS file to $biosdir\n \n\"PlayStation\" and \"PS2\" are registered trademarks of Sony Interactive Entertainment.\n \nThis project is not affiliated in any way with \nSony Interactive Entertainment."
rp_module_licence="Aethersx2 https://aethersx2.net/terms-conditions"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 !x86"

function depends_aethersx2() {
    getDepends libfuse2 mesa-vulkan-drivers libvulkan-dev libsdl2-dev matchbox-window-manager
}

function install_bin_aethersx2() {
    # Tahleth Suspended Development 202301 - 0riginal site 404 Since 202403 - Pull from http://web.archive.org
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/aethersx2/aethersx2-rp-assets.tar.gz" "$md_build"
    download "http://web.archive.org/web/20240120140213/https://www.aethersx2.com/archive/desktop/linux/AetherSX2-v1.5-3606.AppImage" "$md_build"

    pushd "$md_build"
    chmod 755 "AetherSX2-v1.5-3606.AppImage"; mv 'AetherSX2-v1.5-3606.AppImage' "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "aethersx2.sh"; chmod 755 "aethersx2.sh"; mv "aethersx2.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "aethersx2-qjoy.sh"; chmod 755 "aethersx2-qjoy.sh"; mv "aethersx2-qjoy.sh" "$md_inst"

    chmod 755 "AetherSX2.desktop"; cp "AetherSX2.desktop" "$md_inst"; cp "AetherSX2.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "AetherSX2.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/AetherSX2.desktop"; fi
    mv "AetherSX2-128.xpm" "$md_inst"; mv "PS2BIOSRequired.jpg" "$md_inst"

    if [[ ! -d "$home/.config/aethersx2" ]]; then mkdir "$home/.config/aethersx2"; fi
    if [[ ! -d "$home/.config/aethersx2/inis" ]]; then mkdir "$home/.config/aethersx2/inis"; fi
    sed -i s+'/home/pi/'+"$home/"+g "PCSX2.ini"; sed -i s+'/home/pi/'+"$home/"+g "PCSX2.ini.aethersx2"
    if [[ ! -f "$home/.config/aethersx2/inis/PCSX2.ini" ]]; then mv "PCSX2.ini" "$home/.config/aethersx2/inis"; fi
    if [[ ! -f "$home/.config/aethersx2/inis/PCSX2.ini.aethersx2" ]]; then mv "PCSX2.ini.aethersx2" "$home/.config/aethersx2/inis"; fi
    if [[ ! -d "$home/.config/aethersx2/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.config/aethersx2/bios"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd001.ps2" ]]; then mv "Mcd001.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd002.ps2" ]]; then mv "Mcd002.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -d "$home/.config/aethersx2/gamesettings" ]]; then mkdir "$home/.config/aethersx2/gamesettings"; fi
    if [[ ! -f "$home/.config/aethersx2/gamesettings/SLUS-20062_5E115FB6.ini" ]]; then mv "SLUS-20062_5E115FB6.ini" "$home/.config/aethersx2/gamesettings"; fi
    if [[ ! -f "$home/.config/aethersx2/gamesettings/SLUS-20552_248E6126.ini" ]]; then mv "SLUS-20552_248E6126.ini" "$home/.config/aethersx2/gamesettings"; fi
    if [[ ! -f "$home/.config/aethersx2/gamesettings/SLUS-20946_2C6BE434.ini" ]]; then mv "SLUS-20946_2C6BE434.ini" "$home/.config/aethersx2/gamesettings"; fi
    if [[ ! -d "$home/.config/aethersx2/covers" ]]; then mkdir "$home/.config/aethersx2/covers"; fi
    if [[ ! -f "$home/.config/aethersx2/covers/uLaunchELF 4.42d.png" ]]; then mv 'uLaunchELF 4.42d.png' "$home/.config/aethersx2/covers"; fi
    chown -R $__user:$__user -R "$home/.config/aethersx2"
    if [[ ! -d "$md_conf_root/ps2/aethersx2" ]]; then mkdir "$md_conf_root/ps2/aethersx2"; fi
    moveConfigDir "$home/.config/aethersx2" "$md_conf_root/ps2/aethersx2"
    chown -R $__user:$__user -R "$md_conf_root/ps2/aethersx2"

    mkRomDir "ps2"
    chmod 755 '+Start AetherSX2.z2'; mv '+Start AetherSX2.z2' "$romdir/ps2"
    mkRomDir "ps2/media"; mkRomDir "ps2/media/image"; mkRomDir "ps2/media/marquee"; mkRomDir "ps2/media/video"
    mv 'media/image/AetherSX2.png' "$romdir/ps2/media/image"; mv 'media/marquee/AetherSX2.png' "$romdir/ps2/media/marquee"; mv 'media/video/AetherSX2.mp4' "$romdir/ps2/media/video"
    mv 'media/image/uLaunchELF.png' "$romdir/ps2/media/image"; mv 'media/marquee/uLaunchELF.png' "$romdir/ps2/media/marquee"; mv 'media/video/uLaunchELF.mp4' "$romdir/ps2/media/video"
    if [[ ! -f "$romdir/ps2/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/ps2"; else mv 'gamelist.xml' "$romdir/ps2/gamelist.xml.aethersx2"; fi
    chown -R $__user:$__user -R "$romdir/ps2"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function remove_aethersx2() {
    if [[ -f /usr/share/applications/AetherSX2.desktop ]]; then sudo rm -f /usr/share/applications/AetherSX2.desktop; fi
    if [[ -f "$home/Desktop/AetherSX2.desktop" ]]; then rm -f "$home/Desktop/AetherSX2.desktop"; fi
    if [[ -f "$romdir/ps2/+Start AetherSX2.z2" ]]; then rm "$romdir/ps2/+Start AetherSX2.z2"; fi
}

function configure_aethersx2() {
    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'ps2_StartAetherSX2 = "aethersx2"' ; echo $?) == '1' ]]; then echo 'ps2_StartAetherSX2 = "aethersx2"' >> /opt/retropie/configs/all/emulators.cfg; fi

    addSystem "ps2"
    local launch_prefix=XINIT-WM; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WM)" == '' ]]; then local launch_prefix=XINIT; fi
    addEmulator 1 "$md_id" "ps2" "$launch_prefix:$md_inst/aethersx2.sh %ROM%"
    local launch_prefix=XINIT-WMC; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WMC)" == '' ]]; then local launch_prefix=XINIT; fi
    addEmulator 0 "$md_id-editor" "ps2" "$launch_prefix:$md_inst/aethersx2.sh --editor"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-editor+qjoypad" "ps2" "$launch_prefix:$md_inst/aethersx2-qjoy.sh --editor"
    fi
}
