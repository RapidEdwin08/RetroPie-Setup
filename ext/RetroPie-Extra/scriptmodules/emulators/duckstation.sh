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

rp_module_id="duckstation"
rp_module_desc="DuckStation - PlayStation 1, aka. PSX Emulator"
rp_module_help="[DuckStation.AppImage]\nhttps://github.com/stenzek/duckstation/releases\n \nROM Extensions: .cue .cbn .chd .img .iso .m3u .mdf .pbp .toc .z .znx\n\nCopy your PSX roms to $romdir/psx\nCopy the required BIOS file to $biosdir\n \n\"PlayStation\" and \"PSX\" are registered trademarks of Sony Interactive Entertainment.\n \nThis project is not affiliated in any way with \nSony Interactive Entertainment."
rp_module_licence="Duckstation https://raw.githubusercontent.com/stenzek/duckstation/master/LICENSE"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 x86_64"

function depends_duckstation() {
    local depends=(libfuse2 mesa-vulkan-drivers libvulkan-dev libsdl2-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function install_bin_duckstation() {
    #local duckstation_version="v0.1-9226"
    local duckstation_version="latest"
    local duckstation_platform=armhf
    if [[ "$__platform_arch" == 'x86_64' ]]; then duckstation_platform=x64; fi
    if isPlatform "aarch64"; then duckstation_platform=arm64; fi
    local duckstation_appimage=DuckStation-"$duckstation_platform".AppImage

    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/duckstation/duckstation-rp-assets.tar.gz" "$md_build"
    download "https://github.com/stenzek/duckstation/releases/download/${duckstation_version}/${duckstation_appimage}" "$md_build"

    pushd "$md_build"
    chmod 755 "$duckstation_appimage"; mv "$duckstation_appimage" "$md_inst"
    sed -i "s+app_img=.*+app_img=$duckstation_appimage+g" "duckstation.sh"
    sed -i "s+app_img=.*+app_img=$duckstation_appimage+g" "duckstation-qjoy.sh"
    sed -i s+'/home/pi/'+"$home/"+g "duckstation.sh"; chmod 755 "duckstation.sh"; mv "duckstation.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "duckstation-qjoy.sh"; chmod 755 "duckstation-qjoy.sh"; mv "duckstation-qjoy.sh" "$md_inst"

    sed -i "s+Exec=.*+Exec=$md_inst/$duckstation_appimage+g" "DuckStation.desktop"
    chmod 755 "DuckStation.desktop"; cp "DuckStation.desktop" "$md_inst"; cp "DuckStation.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "DuckStation.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/DuckStation.desktop"; fi
    mv "DuckStation-128.xpm" "$md_inst"; mv "PSXBIOSRequired.jpg" "$md_inst"

    if [[ ! -d "$home/.local/share/duckstation" ]]; then mkdir "$home/.local/share/duckstation"; fi
    sed -i 's+SearchDirectory\ =.*+SearchDirectory\ =\ ../../../../../home/pi/RetroPie/BIOS+g' "settings.ini"
    sed -i s+'/home/pi/'+"$home/"+g "settings.ini"
    if [[ "$__platform_arch" == 'x86_64' ]]; then
        sed -i 's/VSync\ =.*/VSync\ =\ true/g' "settings.ini"
        sed -i 's/SyncToHostRefreshRate\ =.*/SyncToHostRefreshRate\ =\ true/g' "settings.ini" # Questionable
        sed -i 's/ResolutionScale\ =.*/ResolutionScale\ =\ 3/g' "settings.ini"
    fi
    if isPlatform "aarch64"; then
        sed -i 's/VSync\ =.*/VSync\ =\ true/g' "settings.ini"
        sed -i 's/SyncToHostRefreshRate\ =.*/SyncToHostRefreshRate\ =\ true/g' "settings.ini" # Questionable
        sed -i 's/ResolutionScale\ =.*/ResolutionScale\ =\ 2/g' "settings.ini"
    fi
    if isPlatform "rpi5" || isPlatform "rpi4"; then
        sed -i 's/Renderer\ =.*/Renderer\ =\ OpenGL/g' "settings.ini"
        sed -i 's/Adapter\ =.*/Adapter\ =\ V3D\ 7.1.10/g' "settings.ini"
        #if isPlatform "rpi5"; then sed -i 's/ResolutionScale\ =.*/ResolutionScale\ =\ 3/g' "settings.ini"; fi
    fi
    if [[ ! -f "$home/.local/share/duckstation/settings.ini" ]]; then mv "settings.ini" "$home/.local/share/duckstation"; fi
    if [[ ! -d "$home/.local/share/duckstation/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.local/share/duckstation/bios"; fi
    if [[ ! -d "$md_conf_root/psx/duckstation" ]]; then mkdir "$md_conf_root/psx/duckstation"; fi
    moveConfigDir "$home/.local/share/duckstation" "$md_conf_root/psx/duckstation"
    moveConfigDir "$home/.config/duckstation" "$md_conf_root/psx/duckstation"
    chown -R $__user:$__user -R "$md_conf_root/psx/duckstation"

    mkRomDir "psx"
    chmod 755 '+Start DuckStation.m3u'; mv '+Start DuckStation.m3u' "$romdir/psx"
    mkRomDir "psx/media"; mkRomDir "psx/media/image"; mkRomDir "psx/media/marquee"; mkRomDir "psx/media/video"
    mv 'media/image/DuckStation.png' "$romdir/psx/media/image"; mv 'media/marquee/DuckStation.png' "$romdir/psx/media/marquee"; mv 'media/video/DuckStation.mp4' "$romdir/psx/media/video"
    if [[ ! -f "$romdir/psx/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/psx"; else mv 'gamelist.xml' "$romdir/psx/gamelist.xml.duckstation"; fi
    chown -R $__user:$__user -R "$romdir/psx"
    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function remove_duckstation() {
    if [[ -f /usr/share/applications/DOSBox-X.desktop ]]; then sudo rm -f /usr/share/applications/DOSBox-X.desktop; fi
    if [[ -f "$home/Desktop/DuckStation.desktop" ]]; then rm -f "$home/Desktop/DuckStation.desktop"; fi
    if [[ -f "$romdir/psx/+Start DuckStation.m3u" ]]; then rm "$romdir/psx/+Start DuckStation.m3u"; fi
}

function configure_duckstation() {
    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'psx_StartDuckStation = "duckstation"' ; echo $?) == '1' ]]; then echo 'psx_StartDuckStation = "duckstation"' >> /opt/retropie/configs/all/emulators.cfg; fi
    addSystem "psx"
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addEmulator 1 "$md_id" "psx" "$launch_prefix$md_inst/duckstation.sh %ROM%"
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addEmulator 0 "$md_id-editor" "psx" "$launch_prefix$md_inst/duckstation.sh --editor"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-editor+qjoypad" "psx" "$launch_prefix$md_inst/duckstation-qjoy.sh --editor"
    fi

    [[ "$md_mode" == "remove" ]] && remove_duckstation
}
