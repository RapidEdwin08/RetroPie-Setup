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

rp_module_id="pcsx2-x64"
rp_module_desc="PS2 emulator PCSX2 Optimized for x86_64"
rp_module_help="[pcsx2-linux-appimage-x64-Qt.AppImage]\nhttps://github.com/PCSX2/pcsx2/releases/ \n \n PCSX2 uses third-party code. You can view the licenses for this code by selecting \"Third-Party Notices\" \n \nROM Extensions: .bin .iso .img .mdf .z .z2 .bz2 .cso .chd .ima .gz\n\nCopy your PS2 roms to $romdir/ps2\nCopy the required BIOS file to $biosdir\n \n\"PlayStation\" and \"PS2\" are registered trademarks of Sony Interactive Entertainment.\n \nThis project is not affiliated in any way with \nSony Interactive Entertainment."
rp_module_licence="GPL3 https://raw.githubusercontent.com/PCSX2/pcsx2/master/COPYING.GPLv3"
rp_module_section="exp"
rp_module_flags="!all x86_64"

function depends_pcsx2-x64() {
    if ! isPlatform "64bit" ; then
        #dialog --ok --msgbox "Installer is for a 64bit system Only!" 22 76 2>&1 >/dev/tty
        md_ret_errors+=("$md_desc Installer is for a 64bit system Only!")
    fi
    local depends=(mesa-vulkan-drivers libvulkan-dev libsdl2-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    if [[ $(apt-cache search libfuse2t64 | grep 'libfuse2t64 ') == '' ]]; then
        depends+=(libfuse2)
    else
        depends+=(libfuse2t64)
    fi
    getDepends "${depends[@]}"
}

function install_bin_pcsx2-x64() {
    #local pcsx2_ver="v2.0.2"; # 2f46e5a8 20240712
    local pcsx2_ver="v2.4.0"; # e4af1c42 20250629

    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/pcsx2-x64-rp-assets.tar.gz" "$md_build"
    download "https://github.com/PCSX2/pcsx2/releases/download/${pcsx2_ver}/pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage" "$md_build"

    pushd "$md_build"
    chmod 755 "pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage"; mv "pcsx2-${pcsx2_ver}-linux-appimage-x64-Qt.AppImage" "$md_inst/pcsx2-linux-appimage-x64-Qt.AppImage"
    sed -i s+'/home/pi/'+"$home/"+g "pcsx2.sh"; chmod 755 "pcsx2.sh"; mv "pcsx2.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "pcsx2-qjoy.sh"; chmod 755 "pcsx2-qjoy.sh"; mv "pcsx2-qjoy.sh" "$md_inst"

    chmod 755 "PCSX2.desktop"; cp "PCSX2.desktop" "$md_inst"; cp "PCSX2.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "PCSX2.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/PCSX2.desktop"; fi
    mv "PCSX2-128.xpm" "$md_inst"; mv "PS2BIOSRequired.jpg" "$md_inst"

    mkdir -p "$home/.config/PCSX2/inis"
    mkdir -p "$md_conf_root/ps2/PCSX2"
    # Basic Settings
    sed -i s+'/home/pi/'+"$home/"+g "PCSX2.ini.pcsx2"
    sed -i s+'EnableFastBoot =.*'+'EnableFastBoot = true'+g "PCSX2.ini.pcsx2"
    sed -i s+'AspectRatio =.*'+'AspectRatio = Stretch'+g "PCSX2.ini.pcsx2" # I don't care what anyone says...
    sed -i s+'upscale_multiplier =.*'+'upscale_multiplier = 2'+g "PCSX2.ini.pcsx2"
    sed -i s+'EnablePerGameSettings =.*'+'EnablePerGameSettings = true'+g "PCSX2.ini.pcsx2"
    sed -i s+'StartFullscreen =.*'+'StartFullscreen = true'+g "PCSX2.ini.pcsx2"
    sed -i s+'ConfirmShutdown =.*'+'ConfirmShutdown = false'+g "PCSX2.ini.pcsx2"
    sed -i s+'GameListGridView =.*'+'GameListGridView = true'+g "PCSX2.ini.pcsx2"
    # Missing BIOS after moveConfigDir related to [GameList] RecursivePaths [../../RetroPie/BIOS]; USE [$home/.config/PCSX2/bios] for PCSX2.ini
    sed -i s+'Bios =.*'+'Bios = bios'+g "PCSX2.ini.pcsx2"
    sed -i s+'MemoryCards =.*'+'MemoryCards = bios'+g "PCSX2.ini.pcsx2"
    if [[ ! -f "$home/.config/PCSX2/inis/PCSX2.ini" ]]; then cp "PCSX2.ini.pcsx2" "$home/.config/PCSX2/inis/PCSX2.ini"; fi
    if [[ ! -f "$home/.config/PCSX2/inis/PCSX2.ini.pcsx2" ]]; then mv "PCSX2.ini.pcsx2" "$home/.config/PCSX2/inis"; fi
    if [[ ! -d "$home/.config/PCSX2/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.config/PCSX2/bios"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd001.ps2" ]]; then mv "Mcd001.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd002.ps2" ]]; then mv "Mcd002.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -d "$home/.config/PCSX2/gamesettings" ]]; then mkdir "$home/.config/PCSX2/gamesettings"; fi
    if [[ ! -f "$home/.config/PCSX2/gamesettings/SLUS-46651_061F13D7.ini" ]]; then mv "SLUS-46651_061F13D7.ini" "$home/.config/PCSX2/gamesettings"; fi
    if [[ ! -d "$home/.config/PCSX2/covers" ]]; then mkdir "$home/.config/PCSX2/covers"; fi
    if [[ ! -f "$home/.config/PCSX2/covers/uLaunchELF 4.42d.png" ]]; then mv 'uLaunchELF 4.42d.png' "$home/.config/PCSX2/covers"; fi
    chown -R $__user:$__user "$home/.config/PCSX2"
    moveConfigDir "$home/.config/PCSX2" "$md_conf_root/ps2/PCSX2"
    chown -R $__user:$__user "$md_conf_root/ps2/PCSX2"

    mkRomDir "ps2"
    chmod 755 '+Start PCSX2.z2'; mv '+Start PCSX2.z2' "$romdir/ps2"
    mkRomDir "ps2/media"; mkRomDir "ps2/media/image"; mkRomDir "ps2/media/marquee"; mkRomDir "ps2/media/video"
    mv 'media/image/PCSX2.png' "$romdir/ps2/media/image"; mv 'media/marquee/PCSX2.png' "$romdir/ps2/media/marquee"; mv 'media/video/PCSX2.mp4' "$romdir/ps2/media/video"
    mv 'media/image/uLaunchELF.png' "$romdir/ps2/media/image"; mv 'media/marquee/uLaunchELF.png' "$romdir/ps2/media/marquee"; mv 'media/video/uLaunchELF.mp4' "$romdir/ps2/media/video"
    if [[ ! -f "$romdir/ps2/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/ps2"; else mv 'gamelist.xml' "$romdir/ps2/gamelist.xml.pcsx2"; fi
    chown -R $__user:$__user "$romdir/ps2"

    mv "sx2mcmanager.sh" "$md_inst"; chmod 755 "$md_inst/sx2mcmanager.sh"
    if [[ -f /opt/retropie/configs/all/runcommand-onstart.sh ]]; then cat /opt/retropie/configs/all/runcommand-onstart.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onstart.sh; fi
    echo 'if [[ "$1" == "ps2" ]]; then bash /opt/retropie/emulators/pcsx2-x64/sx2mcmanager.sh onstart; fi #For Use With [sx2mcmanager]' >> /dev/shm/runcommand-onstart.sh
    mv /dev/shm/runcommand-onstart.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onstart.sh
    if [[ -f /opt/retropie/configs/all/runcommand-onend.sh ]]; then cat /opt/retropie/configs/all/runcommand-onend.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onend.sh; fi
    echo 'if [ "$(head -1 /dev/shm/runcommand.info)" == "ps2" ]; then bash /opt/retropie/emulators/pcsx2-x64/sx2mcmanager.sh onend; fi #For Use With [sx2mcmanager]' >> /dev/shm/runcommand-onend.sh
    mv /dev/shm/runcommand-onend.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onend.sh

    if [[ ! -f /opt/retropie/configs/all/runcommand-menu/CacheSX2Cleaner.sh ]]; then
        mkdir -p /opt/retropie/configs/all/runcommand-menu
        cp "CacheSX2Cleaner.sh" "/opt/retropie/configs/all/runcommand-menu"
        chmod 755 /opt/retropie/configs/all/runcommand-menu/CacheSX2Cleaner.sh
        chown $__user:$__user /opt/retropie/configs/all/runcommand-menu/CacheSX2Cleaner.sh
    fi
    mv "CacheSX2Cleaner.sh" "$md_inst"; chmod 755 "$md_inst/CacheSX2Cleaner.sh"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function remove_pcsx2-x64() {
    rm -f /usr/share/applications/PCSX2.desktop
    rm -f "$home/Desktop/PCSX2.desktop"
    rm -f "$romdir/ps2/+Start PCSX2.z2"
    if [[ -f /opt/retropie/configs/all/runcommand-onstart.sh ]]; then
        cat /opt/retropie/configs/all/runcommand-onstart.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onstart.sh
        mv /dev/shm/runcommand-onstart.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onstart.sh
    fi
    if [[ -f /opt/retropie/configs/all/runcommand-onend.sh ]]; then
        cat /opt/retropie/configs/all/runcommand-onend.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onend.sh
        mv /dev/shm/runcommand-onend.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onend.sh
    fi
}

function configure_pcsx2-x64() {
    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'ps2_StartPCSX2 = "pcsx2-x64-editor"' ; echo $?) == '1' ]]; then echo 'ps2_StartPCSX2 = "pcsx2-x64-editor"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi

    addSystem "ps2"
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addEmulator 1 "$md_id" "ps2" "$launch_prefix$md_inst/pcsx2.sh %ROM%"
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addEmulator 0 "$md_id-editor" "ps2" "$launch_prefix$md_inst/pcsx2.sh --editor"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-editor+qjoypad" "ps2" "$launch_prefix$md_inst/pcsx2-qjoy.sh --editor"
    fi

    [[ "$md_mode" == "remove" ]] && remove_pcsx2-x64
}
