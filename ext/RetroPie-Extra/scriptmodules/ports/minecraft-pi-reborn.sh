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

rp_module_id="minecraft-pi-reborn"
rp_module_desc="Minecraft Pi Edition Reborn"
rp_module_help="Minecraft Pi Edition Reborn (also known as MCPI-Reborn) is a modding project for Minecraft Pi Edition.\n \nMCPI-Repo:\ngithub.com/MCPI-Revival/minecraft-pi-reborn\n \nMCPI-Repo Seeds:\nmcpi-revival.github.io/mcpi-repo/seeds/\n \nMinecraft's sound is NOT Distributed with MCPI-Reborn.\nSound can found in MinecraftPocketEdition v0.6.12 APK.\n \nEXTRACT [libminecraftpe.so] from APK and Place into:\n$home/.minecraft-pi/overrides/libminecraftpe.so\n \nRecommend [PE-a0.11.1-2-x86.apk]:\narchive.org/download/MCPEAlpha/PE-a0.11.1-2-x86.apk"
rp_module_licence="MIT https://raw.githubusercontent.com/MCPI-Revival/minecraft-pi-reborn/master/LICENSE"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 x86_64"

function depends_minecraft-pi-reborn() {
    local depends=(libsdl2-dev libopenal1 libglib2.0-0)
    if [[ $(apt-cache search libfuse2t64 | grep 'libfuse2t64 ') == '' ]]; then
        depends+=(libfuse2)
    else
        depends+=(libfuse2t64)
    fi
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function install_bin_minecraft-pi-reborn() {
    #local minecraftpi_version="latest"
    local minecraftpi_version="2.5.4"
    local minecraftpi_platform=armhf
    if [[ "$__platform_arch" == 'x86_64' ]]; then minecraftpi_platform=amd64; fi
    if isPlatform "aarch64"; then minecraftpi_platform=arm64; fi

    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/ports/minecraft-pi-reborn-rp-assets.tar.gz" "$md_build"
    pushd "$md_build"

    local minecraftpi_appimage=minecraft-pi-reborn-server-"$minecraftpi_version"-"$minecraftpi_platform".AppImage
    download "https://gitea.thebrokenrail.com/minecraft-pi-reborn/minecraft-pi-reborn/releases/download/${minecraftpi_version}/${minecraftpi_appimage}" "$md_build"
    chmod 755 "$minecraftpi_appimage"; mv "$minecraftpi_appimage" "$md_inst"

    minecraftpi_appimage=minecraft-pi-reborn-client-"$minecraftpi_version"-"$minecraftpi_platform".AppImage
    download "https://gitea.thebrokenrail.com/minecraft-pi-reborn/minecraft-pi-reborn/releases/download/${minecraftpi_version}/${minecraftpi_appimage}" "$md_build"
    chmod 755 "$minecraftpi_appimage"; mv "$minecraftpi_appimage" "$md_inst"

    sed -i "s+^app_img=.*+app_img=$minecraftpi_appimage+g" "minecraft.sh"

    sed -i "s+Exec=.*+Exec=$md_inst/$minecraftpi_appimage\ --server+g" "Minecraft Pi Edition Reborn.desktop"
    chmod 755 "Minecraft Pi Edition Reborn.desktop"; cp "Minecraft Pi Edition Reborn.desktop" "$md_inst"; cp "Minecraft Pi Edition Reborn.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "Minecraft Pi Edition Reborn.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/Minecraft Pi Edition Reborn.desktop"; fi

    minecraftpi_appimage=minecraft-pi-reborn-server-"$minecraftpi_version"-"$minecraftpi_platform".AppImage
    sed -i "s+^srv_app_img=.*+srv_app_img=$minecraftpi_appimage+g" "minecraft.sh"

    ##sed -i "s+Exec=.*+Exec=$md_inst/$minecraftpi_appimage+g" "Minecraft Pi Edition Reborn (Server).desktop"
    chmod 755 "Minecraft Pi Edition Reborn (Server).desktop"; cp "Minecraft Pi Edition Reborn (Server).desktop" "$md_inst"; cp "Minecraft Pi Edition Reborn (Server).desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "Minecraft Pi Edition Reborn (Server).desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/Minecraft Pi Edition Reborn (Server).desktop"; fi

    sed -i s+'/home/pi/'+"$home/"+g "minecraft.sh"; chmod 755 "minecraft.sh"; mv "minecraft.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "minecraft-es-server.sh"; chmod 755 "minecraft-es-server.sh"; mv "minecraft-es-server.sh" "$md_inst"
    mv "minecraft-pi-reborn_128x128.xpm" "$md_inst"; mv "minecraft-pi-reborn_256x256.xpm" "$md_inst"

    if [[ ! -d "$home/.minecraft-pi" ]]; then mkdir "$home/.minecraft-pi"; fi
    if [[ ! -f "$home/.minecraft-pi/options.txt" ]]; then mv "options.txt" "$home/.minecraft-pi"; fi
    if [[ ! -f "$home/.minecraft-pi/server.properties" ]]; then mv "server.properties" "$home/.minecraft-pi"; fi
    if [[ ! -f "$home/.minecraft-pi/README-MCPI-Repo-Seeds.txt" ]]; then mv "README-MCPI-Repo-Seeds.txt" "$home/.minecraft-pi"; fi
    if [[ ! -d "$md_conf_root/ports/minecraft-pi-reborn" ]]; then mkdir "$md_conf_root/ports/minecraft-pi-reborn"; fi
    moveConfigDir "$home/.minecraft-pi" "$md_conf_root/ports/minecraft-pi-reborn"
    chown -R $__user:$__user -R "$md_conf_root/ports/minecraft-pi-reborn"

    mkRomDir "ports"
    mkRomDir "ports/media"; mkRomDir "ports/media/image"; mkRomDir "ports/media/marquee"; mkRomDir "ports/media/video"
    mv 'media/image/Minecraft Pi Edition Reborn.png' "$romdir/ports/media/image"; mv 'media/marquee/Minecraft Pi Edition Reborn.png' "$romdir/ports/media/marquee"
    mv 'media/image/Minecraft Pi Edition Reborn (Server).png' "$romdir/ports/media/image"; mv 'media/marquee/Minecraft Pi Edition Reborn (Server).png' "$romdir/ports/media/marquee"
    if [[ ! -f "$romdir/ports/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/ports"; else mv 'gamelist.xml' "$romdir/ports/gamelist.xml.minecraft-pi"; fi
    chown -R $__user:$__user -R "$romdir/ports"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function remove_minecraft-pi-reborn() {
    rm -f "/usr/share/applications/Minecraft Pi Edition Reborn.desktop"
    rm -f "$home/Desktop/Minecraft Pi Edition Reborn.desktop"
    rm -f "$romdir/ports/+Start Minecraft Pi Edition Reborn.sh"

    rm -f "/usr/share/applications/Minecraft Pi Edition Reborn (Server).desktop"
    rm -f "$home/Desktop/Minecraft Pi Edition Reborn (Server).desktop"
    rm -f "$romdir/ports/+Start Minecraft Pi Edition Reborn (Server).sh"
}

function configure_minecraft-pi-reborn() {
    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addPort "$md_id" "minecraft-pi-reborn" "+Start Minecraft Pi Edition Reborn" "$launch_prefix$md_inst/minecraft.sh"

    # --server will call Dialog.sh withOUT retropiemenu launch when called from .desktop Shortcut
    # --es-server will call Dialog.sh with RetroPie-Setup/retropie_packages.sh retropiemenu launch for JoyPad Support when called from ES
    addPort "$md_id-server" "minecraft-pi-reborn-server" "+Start Minecraft Pi Edition Reborn (Server)" "$launch_prefix$md_inst/minecraft.sh --es-server"

    [[ "$md_mode" == "remove" ]] && remove_minecraft-pi-reborn
}
