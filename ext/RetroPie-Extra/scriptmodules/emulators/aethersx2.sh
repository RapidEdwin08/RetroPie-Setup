#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="aethersx2"
rp_module_desc="PS2 Emulator Optimized for ARM                                                                                                  \n \n AetherSX2-v1.5-3606.AppImage \n \n https://www.aethersx2.com/archive/?dir=desktop/linux \n \n AetherSX2 uses third-party code. You can view the licenses for this code by selecting \"Third-Party Notices\" in the navigation menu of the app (swipe out from the left)."
rp_module_licence="Aethersx2 https://aethersx2.net/terms-conditions"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 rpi4 rpi5"

function depends_aethersx2() {
    getDepends libfuse2 mesa-vulkan-drivers libvulkan-dev libsdl2-dev
}

function sources_aethersx2() {
    download "https://www.aethersx2.com/archive/desktop/linux/AetherSX2-v1.5-3606.AppImage" "$md_build"
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/aethersx2/aethersx2-rp-assets.tar.gz" "$md_build"
}

function install_aethersx2() {
    chmod 755 "AetherSX2-v1.5-3606.AppImage"; mv 'AetherSX2-v1.5-3606.AppImage' "$md_inst"
    chmod 755 "aethersx2.sh"; mv "aethersx2.sh" "$md_inst"
    chmod 755 "AetherSX2.desktop"; mv "AetherSX2.desktop" "$md_inst"
    mv "AetherSX2-128.png" "$md_inst"; mv "PS2BIOSRequired.jpg" "$md_inst"

    if [[ ! -d "$home/.config/aethersx2" ]]; then mkdir "$home/.config/aethersx2"; fi
	if [[ ! -d "$home/.config/aethersx2/inis" ]]; then mkdir "$home/.config/aethersx2/inis"; fi
    if [[ ! -f "$home/.config/aethersx2/inis/PCSX2.ini" ]]; then mv "PCSX2.ini" "$home/.config/aethersx2/inis"; fi
	if [[ ! -d "$home/.config/aethersx2/bios" ]]; then ln -s /home/pi/RetroPie/BIOS "$home/.config/aethersx2/bios"; fi
    chown "$(basename $home)" -R "$home/.config/aethersx2"

    mkdir "$home/RetroPie/roms/ps2"
    mv '+Start AetherSX2.sh' "$home/RetroPie/roms/ps2"
    if [[ ! -f "$home/RetroPie/roms/ps2/gamelist.xml" ]]; then mv 'gamelist.xml' "$home/RetroPie/roms/ps2"; fi
    if [[ ! -d "$home/RetroPie/roms/ps2/media" ]]; then mv 'media' "$home/RetroPie/roms/ps2"; fi
    chown "$(basename $home)" -R "$home/RetroPie/roms/ps2"

    if [[ ! -f "$home/Desktop/AetherSX2.desktop" ]]; then cp "/opt/retropie/emulators/aethersx2/AetherSX2.desktop" "$home/Desktop"; fi
    chown "$(basename $home)" "$home/Desktop/AetherSX2.desktop"
}

function configure_aethersx2() {
    addPort "$md_id" "ps2" "aethersx2" "XINIT: /opt/retropie/emulators/aethersx2/aethersx2.sh %ROM%"
    addSystem "ps2"
}
