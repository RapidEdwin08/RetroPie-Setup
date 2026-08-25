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
rp_module_help="Minecraft Pi Edition Reborn (also known as MCPI-Reborn) is a modding project for Minecraft Pi Edition.\n\nMinecraft's sound is NOT Distributed with MCPI-Reborn.\nSound can found in MinecraftPocketEdition v0.6.12 APK\n\nEXTRACT [libminecraftpe.so] from APK and Place into:\n$home/.minecraft-pi/overrides/libminecraftpe.so\n\nIF USING PI RECOMMEND USERS *UN-CHECK* THESE SETTINGS:\n [ ] Multithreaded Chunk Rebuilding \n [ ] Use OpenGL Display Lists \n [ ] Proper Entity Shading \n [ ] Disable V-Sync\n\nIF USING PI RECOMMEND USERS *CHECK* THESE SETTINGS:\n [X] Increase Render Chunk Size\n\nIF USING QJOYPAD RECOMMEND USERS *CHECK* THESE SETTINGS: \n [X] Disable Raw Mouse Motion\n\nMCPI-Repo:\ngithub.com/MCPI-Revival/minecraft-pi-reborn\n\nMCPI-Repo Seeds:\nmcpi-revival.github.io/mcpi-repo/seeds/"
rp_module_licence="MIT https://raw.githubusercontent.com/MCPI-Revival/minecraft-pi-reborn/master/LICENSE"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 x86_64"

function _mcpe_link_minecraft-pi-reborn() {
    # Add Minecraft Pocket Edition (alpha) Link here to Attempt to Download and Extract {/lib/armeabi-v7a/libminecraftpe.so}
    #echo https://archive.org/download/MCPEAlpha/PE-a0.11.1-2-x86.apk
    echo https://dn721800.ca.archive.org/0/items/minecraft-pocket-edition-library/Minecraft%20PE%200.9.0-build5.apk
}

function depends_minecraft-pi-reborn() {
    local depends=(libsdl2-dev libopenal1)
    if [[ $(apt-cache search libfuse2t64 | grep 'libfuse2t64 ') == '' ]]; then
        depends+=(libfuse2 libglib2.0-0)
    else
        depends+=(libfuse2t64 libglib2.0-0t64)
    fi
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    depends+=(build-essential python3-venv python3-tk p7zip-full)
    getDepends "${depends[@]}"
}

function install_bin_minecraft-pi-reborn() {
    #local minecraftpi_version="latest"
    local minecraftpi_version="3.0.3"
    local minecraftpi_platform=armhf
    if [[ "$__platform_arch" == 'x86_64' ]]; then minecraftpi_platform=amd64; fi
    if isPlatform "aarch64"; then minecraftpi_platform=arm64; fi

    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/ports/minecraft-pi-reborn-rp-assets.tar.gz" "$md_build"
    pushd "$md_build"

    minecraftpi_appimage=minecraft-pi-reborn-"$minecraftpi_version"-"$minecraftpi_platform".AppImage
    download "https://gitea.thebrokenrail.com/minecraft-pi-reborn/minecraft-pi-reborn/releases/download/${minecraftpi_version}/${minecraftpi_appimage}" "$md_build"
    chmod 755 "$minecraftpi_appimage"; mv "$minecraftpi_appimage" "$md_inst"

    sed -i "s+^app_img=.*+app_img=$minecraftpi_appimage+g" "minecraft.sh"
    sed -i "s+^app_img=.*+app_img=$minecraftpi_appimage+g" "minecraft-qjoy.sh"

    sed -i "s+Exec=.*+Exec=$md_inst/$minecraftpi_appimage+g" "Minecraft Pi Edition Reborn.desktop"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        sed -i "s+Exec=.*+Exec=$md_inst/minecraft-qjoy.sh+g" "Minecraft Pi Edition Reborn.desktop"
    fi
    chmod 755 "Minecraft Pi Edition Reborn.desktop"; cp "Minecraft Pi Edition Reborn.desktop" "$md_inst"; cp "Minecraft Pi Edition Reborn.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "Minecraft Pi Edition Reborn.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/Minecraft Pi Edition Reborn.desktop"; fi

    ##sed -i "s+Exec=.*+Exec=$md_inst/$minecraftpi_appimage+g" "Minecraft Pi Edition Reborn (Server).desktop"
    chmod 755 "Minecraft Pi Edition Reborn (Server).desktop"; cp "Minecraft Pi Edition Reborn (Server).desktop" "$md_inst"; cp "Minecraft Pi Edition Reborn (Server).desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "Minecraft Pi Edition Reborn (Server).desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/Minecraft Pi Edition Reborn (Server).desktop"; fi

    sed -i s+'/home/pi/'+"$home/"+g "Minecraft Pi Edit (MCPIedit).desktop"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        sed -i "s+Exec=.*+Exec=$md_inst/mcpiedit-qjoy.sh+g" "Minecraft Pi Edit (MCPIedit).desktop"
    fi
    chmod 755 "Minecraft Pi Edit (MCPIedit).desktop"; cp "Minecraft Pi Edit (MCPIedit).desktop" "$md_inst"; cp "Minecraft Pi Edit (MCPIedit).desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "Minecraft Pi Edit (MCPIedit).desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/Minecraft Pi Edit (MCPIedit).desktop"; fi

    sed -i s+'/home/pi/'+"$home/"+g "mcpiedit.sh"; chmod 755 "mcpiedit.sh"; mv "mcpiedit.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "mcpiedit-qjoy.sh"; chmod 755 "mcpiedit-qjoy.sh"; mv "mcpiedit-qjoy.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "minecraft.sh"; chmod 755 "minecraft.sh"; mv "minecraft.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "minecraft-qjoy.sh"; chmod 755 "minecraft-qjoy.sh"; mv "minecraft-qjoy.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "minecraft-es-server.sh"; chmod 755 "minecraft-es-server.sh"; mv "minecraft-es-server.sh" "$md_inst"
    mv "minecraft-pi-reborn_128x128.xpm" "$md_inst"; mv "minecraft-pi-reborn_256x256.xpm" "$md_inst"; mv "mcpiedit_256x256.xpm" "$md_inst"

    mkdir -p "$home/.minecraft-pi"
    mkdir -p "$home/.minecraft-pi/overrides"
    if [[ ! -f "$home/.minecraft-pi/options.txt" ]]; then mv "options.txt" "$home/.minecraft-pi"; fi
    if [[ ! -f "$home/.minecraft-pi/server.properties" ]]; then mv "server.properties" "$home/.minecraft-pi"; fi
    if [[ ! -f "$home/.minecraft-pi/README-MCPI-Reborn.txt" ]]; then mv "README-MCPI-Reborn.txt" "$home/.minecraft-pi"; fi
    if [[ ! -f "$home/.minecraft-pi/RecommendedSettingsForPi.png" ]]; then mv "RecommendedSettingsForPi.png" "$home/.minecraft-pi"; fi

    if [[ ! -d "$home/.minecraft-pi/games/com.mojang/minecraftWorlds/Server" ]]; then
        mkdir -p "$home/.minecraft-pi/games/com.mojang/minecraftWorlds"
        mv ./Server "$home/.minecraft-pi/games/com.mojang/minecraftWorlds"
    fi

    if [[ ! -d "$md_conf_root/minecraft-pi-reborn" ]]; then mkdir "$md_conf_root/minecraft-pi-reborn"; fi
    moveConfigDir "$home/.minecraft-pi" "$md_conf_root/minecraft-pi-reborn"
    chown -R $__user:$__user "$md_conf_root/minecraft-pi-reborn"

    mkRomDir "ports"
    mkRomDir "ports/media"; mkRomDir "ports/media/image"; mkRomDir "ports/media/marquee"; mkRomDir "ports/media/video"
    mv 'media/image/Minecraft Pi Edition Reborn.png' "$romdir/ports/media/image"; mv 'media/marquee/Minecraft Pi Edition Reborn.png' "$romdir/ports/media/marquee"
    mv 'media/image/Minecraft Pi Edition Reborn (Server).png' "$romdir/ports/media/image"; mv 'media/marquee/Minecraft Pi Edition Reborn (Server).png' "$romdir/ports/media/marquee"
    mv 'media/image/MCPIedit.png' "$romdir/ports/media/image"; mv 'media/marquee/MCPIedit.png' "$romdir/ports/media/marquee"
    if [[ ! -f "$romdir/ports/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/ports"; else mv 'gamelist.xml' "$romdir/ports/gamelist.xml.minecraft-pi"; fi
    if [[ ! -f "$romdir/ports/README-MCPI-Reborn.txt" ]]; then cp "$home/.minecraft-pi/README-MCPI-Reborn.txt" "$romdir/ports"; fi
    chown -R $__user:$__user "$romdir/ports"

    sed -i "s+url=.*+url=\"https://gitea.thebrokenrail.com/minecraft-pi-reborn/minecraft-pi-reborn/releases/download/${minecraftpi_version}/${minecraftpi_appimage}\"+g" 'retropie.pkg'
    mv 'retropie.pkg' "$md_inst"

    popd
    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi

    ### MCPIedit ###
    rm -Rf "$home/.mcpiedit" # Remove 0ld MCPIedit Folder
    git clone https://github.com/RapidEdwin08/MCPIedit.git "$home/.mcpiedit"

    # Install MCPIedit modules in isolated virtual environment
    pushd "$home/.mcpiedit" # Path of ./virtual_environment
    python3 -m venv envmcpiedit
    source envmcpiedit/bin/activate
    pip3 install mutf8 pynbt tk
    deactivate
    popd

    chown -R $__user:$__user "$home/.mcpiedit"
    touch $md_inst/mcpiedit.on
}

function remove_minecraft-pi-reborn() {
    for _shortcut in "Minecraft Pi Edition Reborn" "Minecraft Pi Edition Reborn (Server)" "MCPIedit" "Minecraft Pi Edition Reborn (Editor)" "Minecraft Pi Edit (MCPIedit)"; do
        rm -f "/usr/share/applications/$_shortcut.desktop"
        rm -f "$home/Desktop/$_shortcut.desktop"
        rm -f "$romdir/ports/+Start $_shortcut.sh"
    done

    rm -f "$home/.qjoypad3/Minecraft.lyt" # Remove 0ld v2 Layout
    rm -f "$home/.qjoypad3/Minecraft-v3.lyt" # Remove v3 Layout

    rm -Rf envmcpiedit # Remove 0ld isolated virtual environment
    rm -Rf "$home/.mcpiedit" # Remove 0ld MCPIedit Folder

    rm -f "$home/.minecraft-pi/RecommendedSettingsForPi.png"
    rm -f "$home/.minecraft-pi/README-MCPI-Reborn.txt"
    rm -f "$romdir/ports/README-MCPI-Reborn.txt"

    rm -f "$romdir/ports/media/marquee/MCPIedit.png"
    rm -f "$romdir/ports/media/marquee/Minecraft Pi Edition Reborn.png"
    rm -f "$romdir/ports/media/marquee/Minecraft Pi Edition Reborn (Server).png"
}

function game_audio_minecraft-pi-reborn() {
    rm -Rf /dev/shm/mc; mkUserDir /dev/shm/mc
    pushd /dev/shm/mc > /dev/null 2>&1
    #wget -q https://dn721800.ca.archive.org/0/items/minecraft-pocket-edition-library/Minecraft%20PE%200.9.0-build5.apk -O /dev/shm/mc/mcpe.zip
    echo "$(_mcpe_link_minecraft-pi-reborn)"
    wget -q "$(_mcpe_link_minecraft-pi-reborn)" -O /dev/shm/mc/mcpe.zip
    if [[ ! "$?" == "0" ]]; then
        rm -Rf /dev/shm/mc
        popd
        md_ret_errors+=("$md_desc Failed to Download {libminecraftpe.so} MinecraftPocketEdition alpha \n\nTry here:\n\nhttps://download1638.mediafire.com/skz80sv2sm8ge7rJ5w-lvGDpGxeSk-GQ_SxwbFNb2q_HiDNpJLi-EpkOlkQv223ObBOmrJQ0eh86J_lvgdL9GzWMC4820cdMAeTCs4w9zVX9LkUhHdHanUaYOHqKwFmltj4gnfnWnvadpAYssR7u3bHlo93Y3FaKprQnWlwCYUtFrw/g2dxfbjbgwxz931/PE-a0.11.1-2-x86.apk")
        return
    fi

    7z x /dev/shm/mc/mcpe.zip -aoa
    if [[ ! -f "/home/$__user/.minecraft-pi/overrides/libminecraftpe.so" ]]; then
        mkUserDir "/home/$__user/.minecraft-pi"; mkUserDir "/home/$__user/.minecraft-pi/overrides"
        mv '/dev/shm/mc/lib/armeabi-v7a/libminecraftpe.so' "/home/$__user/.minecraft-pi/overrides/libminecraftpe.so"
    fi
    chown -R $__user:$__user "/home/$__user/.minecraft-pi"
    chown $__user:$__user "/home/$__user/.minecraft-pi/overrides/libminecraftpe.so"
    popd
    rm -Rf /dev/shm/mc

    dialog --no-collapse --title "Finished" --ok-label Back --msgbox "[/home/$__user/.minecraft-pi/overrides]:\n$(ls /home/$__user/.minecraft-pi/overrides )"  25 75
}

function gui_minecraft-pi-reborn() {
    local _mcpiedit_at_start=ENABLED
    if [[ ! -f "$md_inst/mcpiedit.on" ]]; then _mcpiedit_at_start=DISABLED; fi
    if [[ ! -d "/home/$__user/.minecraft-pi/overrides" ]]; then mkUserDir /home/$__user/.minecraft-pi/overrides; fi
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "\nToggle MCPIEdit at Start-Up: $_mcpiedit_at_start \n\nAttempt to Download MinecraftPocketEdition Audio File(s)\n\nSee [Package Help] for Details\n\n[/home/$__user/.minecraft-pi/overrides]:\n$(ls /home/$__user/.minecraft-pi/overrides )" 25 75 5 \
        "1" "ENABLE  MCPIedit at Start-Up" \
        "2" "DISABLE MCPIedit at Start-Up" \
        "3" "GET {libminecraftpe.so} MinecraftPocketEdition (alpha)" \
        "4" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            echo "ENABLED  MCPIedit at Start-Up"
            touch $md_inst/mcpiedit.on
            gui_minecraft-pi-reborn
            ;;
        2)
            echo "DISABLED MCPIedit at Start-Up"
            rm -f $md_inst/mcpiedit.on
            gui_minecraft-pi-reborn
            ;;
        3)
            game_audio_minecraft-pi-reborn
            ;;
        4)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_minecraft-pi-reborn() {
    local launch_prefix
    isPlatform "rpi"* && launch_prefix="XINIT-WMC:"
    isPlatform "kms" && launch_prefix="XINIT-WMC:"

    # (No Argument) will Run AppImage with 0ptions Screen at Start # --default will Skip the 0ptions Screen # --server runs as dediated server [server.properties]
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "minecraft-pi-reborn" "+Start Minecraft Pi Edition Reborn" "$launch_prefix$md_inst/minecraft-qjoy.sh --default"
        addPort "cfg-$md_id+qjoypad" "minecraft-pi-reborn" "+Start Minecraft Pi Edition Reborn" "$launch_prefix$md_inst/minecraft-qjoy.sh"
    fi

    addPort "$md_id" "minecraft-pi-reborn" "+Start Minecraft Pi Edition Reborn" "$launch_prefix$md_inst/minecraft.sh --default"
    addPort "cfg-$md_id" "minecraft-pi-reborn" "+Start Minecraft Pi Edition Reborn" "$launch_prefix$md_inst/minecraft.sh"

    # --server will call Dialog.sh withOUT retropiemenu launch when called from .desktop Shortcut
    # --es-server will call Dialog.sh with RetroPie-Setup/retropie_packages.sh retropiemenu launch for JoyPad Support when called from ES
    addPort "$md_id-server" "minecraft-pi-reborn-server" "+Start Minecraft Pi Edition Reborn (Server)" "$md_inst/minecraft.sh --es-server"

    # MCPIedit
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id-edit+qjoypad" "minecraft-pi-reborn-edit" "+Start MCPIedit" "$launch_prefix$md_inst/mcpiedit-qjoy.sh"
    fi
    addPort "$md_id-edit" "minecraft-pi-reborn-edit" "+Start MCPIedit" "$launch_prefix$md_inst/mcpiedit.sh"

    [[ "$md_mode" == "remove" ]] && remove_minecraft-pi-reborn
}
