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

# Version + Platform put here to be displayed in Help #vtarget="v0.1-9226"
vtarget="latest"
ptarget=armhf
if [[ "$__platform_arch" == 'x86_64' ]]; then ptarget=x64; fi
if isPlatform "aarch64"; then ptarget=arm64; fi

rp_module_id="duckstation"
rp_module_desc="DuckStation - PlayStation 1, aka. PSX Emulator                                                                                                                                                                                    \n \n DuckStation-$ptarget.AppImage ($vtarget) \n \n https://github.com/stenzek/duckstation/releases \n \n\"PlayStation\" and \"PSX\" are registered trademarks of Sony Interactive Entertainment Europe Limited.\n \nThis project is not affiliated in any way with \nSony Interactive Entertainment."
rp_module_licence="Duckstation https://raw.githubusercontent.com/stenzek/duckstation/master/LICENSE"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 x86_64"

function depends_duckstation() {
    getDepends libfuse2 mesa-vulkan-drivers libvulkan-dev libsdl2-dev matchbox
}

#function install_bin_duckstation() {
function sources_duckstation() {
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/duckstation/duckstation-rp-assets.tar.gz" "$md_build"
    download "https://github.com/stenzek/duckstation/releases/download/${vtarget}/DuckStation-${ptarget}.AppImage" "$md_build"
}

function install_duckstation() {
    chmod 755 "DuckStation-"$ptarget".AppImage"; mv "DuckStation-"$ptarget".AppImage" "$md_inst"
    homeDIR=$home; sed -i s+'/home/pi/'+"$homeDIR/"+g "duckstation.sh"
    sed -i "s+emu_AppImage=.*+emu_AppImage=DuckStation-$ptarget.AppImage+g" "duckstation.sh"
    chmod 755 "duckstation.sh"; mv "duckstation.sh" "$md_inst"
    sed -i "s+Exec=.*+Exec=$md_inst/DuckStation-$ptarget.AppImage+g" "DuckStation.desktop"
    chmod 755 "DuckStation.desktop"; cp "DuckStation.desktop" "$md_inst"; cp "DuckStation.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv "DuckStation.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/DuckStation.desktop"; fi
    mv "DuckStation-128.xpm" "$md_inst"; mv "PSXBIOSRequired.jpg" "$md_inst"
    if [[ ! -d "$home/.local/share/duckstation" ]]; then mkdir "$home/.local/share/duckstation"; fi
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
        if isPlatform "rpi5"; then sed -i 's/ResolutionScale\ =.*/ResolutionScale\ =\ 3/g' "settings.ini"; fi
    fi
    if [[ ! -f "$home/.local/share/duckstation/settings.ini" ]]; then mv "settings.ini" "$home/.local/share/duckstation"; fi
    if [[ ! -d "$home/.local/share/duckstation/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.local/share/duckstation/bios"; fi
    if [[ ! -d "$md_conf_root/psx/duckstation" ]]; then mkdir "$md_conf_root/psx/duckstation"; fi
    moveConfigDir "$home/.local/share/duckstation" "$md_conf_root/psx/duckstation"
    chown -R $__user:$__user -R "$md_conf_root/psx/duckstation"
    mkRomDir "psx"
    chmod 755 '+Start DuckStation.m3u'; mv '+Start DuckStation.m3u' "$romdir/psx"
    if [[ ! -f "$romdir/psx/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/psx"; fi
    if [[ ! -d "$romdir/psx/media" ]]; then mv 'media' "$romdir/psx"; fi
    chown -R $__user:$__user -R "$romdir/psx"
}

function remove_duckstation() {
    sudo rm -f /usr/share/applications/DOSBox-X.desktop
    if [[ -f "$home/Desktop/DuckStation.desktop" ]]; then rm -f "$home/Desktop/DuckStation.desktop"; fi
    rm "$romdir/psx/+Start DuckStation.m3u"
}

function configure_duckstation() {
    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'default =' ; echo $?) == '1' ]]; then echo 'psx_StartDuckStation = "duckstation"' >> /opt/retropie/configs/all/emulators.cfg; fi
    addSystem "psx"
    launch_prefix=XINIT-WM; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WM)" == '' ]]; then launch_prefix=XINIT; fi
    addEmulator 0 "$md_id" "psx" "$launch_prefix:$md_inst/duckstation.sh %ROM%"
    launch_prefix=XINIT-WMC; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WMC)" == '' ]]; then launch_prefix=XINIT; fi
    addEmulator 1 "$md_id-editor" "psx" "$launch_prefix:$md_inst/duckstation.sh --editor"
    if [[ $(cat /opt/retropie/configs/psx/emulators.cfg | grep -q 'default =' ; echo $?) == '1' ]]; then echo 'default = "duckstation"' >> /opt/retropie/configs/psx/emulators.cfg; fi
    sed -i 's/default\ =.*/default\ =\ \"duckstation\"/g' /opt/retropie/configs/psx/emulators.cfg
}
