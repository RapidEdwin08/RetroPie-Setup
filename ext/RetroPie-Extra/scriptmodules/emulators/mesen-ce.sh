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

rp_module_id="mesen-ce"
rp_module_desc="MesenCE is a community-managed fork of Mesen multi-system emulator for NES, SNES, Game Boy, Game Boy Advance, PC Engine, SMS/Game Gear, and WonderSwan."
rp_module_help="ROM Folders: nes, snes, gb, gbc, gba, pcengine, mastersystem, gamegear, wonderswan, wonderswancolor.\n\n   * Required Microsoft .NET 10 SDK Dependencies *\n\n[dotnet-sdk-10.0] CAN BE UNINSTALLED WITH:\nsudo apt-get remove dotnet-sdk-10.0 dotnet-apphost-pack-10.0 aspnetcore-targeting-pack-10.0 dotnet-targeting-pack-10.0 aspnetcore-runtime-10.0 dotnet-runtime-10.0 dotnet-runtime-deps-10.0 dotnet-hostfxr-10.0 dotnet-host\n\n[packages-microsoft-prod] CAN BE UNINSTALLED WITH:\nsudo dpkg --purge packages-microsoft-prod"
rp_module_licence="GNU https://raw.githubusercontent.com/RapidEdwin08/MesenCE/refs/heads/master/LICENSE"
rp_module_repo="git https://github.com/RapidEdwin08/MesenCE.git master"
rp_module_section="exp"
rp_module_flags="!all aarch64 x86_64 !:\$__os_debian_ver:-gt:13 !:\$__os_debian_ver:-lt:12"

function depends_mesen-ce() {
    local depends=(cmake clang zlib1g zlib1g-dev libsdl2-dev libsdl2-mixer-dev libsdl2-net-dev)
    #depends+=(libsdl-net1.2-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"

    if [[ "$md_mode" == "install" ]] && [[ $(dotnet --list-sdks | grep ^10.) == '' ]]; then net10sdk_mesen-ce; fi
}

function net10sdk_mesen-ce() {
    # .NET 10 SKD
    if [[ "$__os_debian_ver" -ge 13 ]] || [[ "$__os_debian_ver" -le 12 ]]; then
        wget https://packages.microsoft.com/config/debian/$__os_debian_ver/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb; rm -f packages-microsoft-prod.deb
    fi

    sudo apt-get update && sudo apt-get install -y dotnet-sdk-10.0

    echo ''
    dotnet --list-sdks
    echo ''
    echo *Microsoft .NET 10 SDK Installed*
    echo [dotnet-sdk-10.0] CAN BE UNINSTALLED WITH: [sudo apt-get remove -y dotnet-sdk-10.0 dotnet-apphost-pack-10.0 aspnetcore-targeting-pack-10.0 dotnet-targeting-pack-10.0 aspnetcore-runtime-10.0 dotnet-runtime-10.0 dotnet-runtime-deps-10.0 dotnet-hostfxr-10.0 dotnet-host]
    echo ''
    echo *Microsoft Prod Packages Installed*
    echo [packages-microsoft-prod] CAN BE UNINSTALLED WITH: [sudo dpkg --purge packages-microsoft-prod]
    echo ''
}

function remove_net10sdk_mesen-ce() {
    choice=$(dialog --title "REMOVE .NET 10 SDK + MS Prod Packages" --menu "      ARE YOU SURE ?\n\n$(dotnet --list-sdks)" 15 60 5 \
        "1" "REMOVE .NET 10 SDK + MS Prod Packages" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            sudo apt-get remove -y dotnet-sdk-10.0 dotnet-apphost-pack-10.0 aspnetcore-targeting-pack-10.0 dotnet-targeting-pack-10.0 aspnetcore-runtime-10.0 dotnet-runtime-10.0 dotnet-runtime-deps-10.0 dotnet-hostfxr-10.0 dotnet-host
            sudo dpkg --purge packages-microsoft-prod
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function sources_mesen-ce() {
    gitPullOrClone
}

function _release_mesen-ce() {
    local mesence_platform=linux-x64
    if isPlatform "aarch64"; then mesence_platform=linux-arm64; fi
    echo "bin/$mesence_platform/Release/$mesence_platform/publish"
}

function build_mesen-ce() {
    make clean
    make -j"$(nproc)"
    md_ret_require="$md_build/$(_release_mesen-ce)/Mesen"
}

function install_mesen-ce() {
     md_ret_files=(
        "$(_release_mesen-ce)/libHarfBuzzSharp.so"
        "$(_release_mesen-ce)/libSkiaSharp.so"
        "$(_release_mesen-ce)/Mesen"
        "$(_release_mesen-ce)/Mesen.pdb"
    )
}

function game_data_mesen-ce() { # Can Mesen-CE Run D00M LRG?
    if [[ ! -f "$romdir/snes/media/image/Doom_(2025)_(LRG).png" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/mesen-ce-rp-assets.tar.gz" "$romdir/snes"
        if [[ ! -f "$romdir/snes/gamelist.xml" ]] && [[ ! -f "/opt/retropie/configs/all/emulationstation/gamelists/snes/gamelist.xml" ]]; then mv "$romdir/snes/gamelist.xml.snes" "$romdir/snes/gamelist.xml"; fi
        chown -R $__user:$__user "$romdir/snes"
    fi
}

function remove_mesen-ce() {
    local shortcut_name
    shortcut_name="MesenCE"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/snes/+Start MesenCE.bs"
}

function gui_mesen-ce() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      INSTALL/REMOVE .NET 10 SDK + MS Prod Packages\n\nSee [Package Help] for Details\n\n$(dotnet --list-sdks)" 15 60 5 \
        "1" "INSTALL .NET 10 SDK + MS Prod Packages" \
        "2" "REMOVE  .NET 10 SDK + MS Prod Packages" \
        "3" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            net10sdk_mesen-ce
            ;;
        2)
            remove_net10sdk_mesen-ce
            ;;
        3)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_mesen-ce() {
    moveConfigDir "$home/.config/MesenCE" "$md_conf_root/snes/MesenCE"

    local launch_prefix
    local system
    local qjoyui
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then qjoyui=1; fi
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    for system in nes snes gb gbc gba pcengine mastersystem gamegear wonderswan wonderswancolor; do
        mkRomDir "$system"
        defaultRAConfig "$system"
        addEmulator 0 "$md_id" "$system" "${launch_prefix}$md_inst/mesence.sh %ROM% --fullscreen"
        addEmulator 0 "$md_id-ui" "$system" "${launch_prefix}$md_inst/mesence.sh %ROM%"
        if [[ "$qjoyui" == '1' ]]; then
            addEmulator 0 "$md_id-ui-qjoy" "$system" "${launch_prefix}$md_inst/mesence-qjoy.sh %ROM%"
        fi
        addSystem "$system"
    done

    [[ "$md_mode" == "remove" ]] && remove_mesen-ce
    [[ "$md_mode" == "remove" ]] && return

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'snes_Doom_2025_LRG = "mesen-ce"' ; echo $?) == '1' ]]; then echo 'snes_Doom_2025_LRG = "mesen-ce"' >> /opt/retropie/configs/all/emulators.cfg; fi
    if [[ "$qjoyui" == '1' ]]; then
        if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'snes_StartMesenCE = "mesen-ce-ui-qjoy"' ; echo $?) == '1' ]]; then echo 'snes_StartMesenCE = "mesen-ce-ui-qjoy"' >> /opt/retropie/configs/all/emulators.cfg; fi
    else
        if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'snes_StartMesenCE = "mesen-ce-ui"' ; echo $?) == '1' ]]; then echo 'snes_StartMesenCE = "mesen-ce-ui"' >> /opt/retropie/configs/all/emulators.cfg; fi
    fi
    chown $__user:$__user /opt/retropie/configs/all/emulators.cfg

    touch "$romdir/snes/+Start MesenCE.bs"; chown -R $__user:$__user "$romdir/snes"

    cat >"$md_inst/mesence.sh" << _EOF_
#!/bin/bash

# Run $md_id
if [[ "\$1" == '' ]] || [[ "\$1" == *"+Start Mesen"* ]]; then
    VC4_DEBUG=always_sync $md_inst/Mesen
else
    VC4_DEBUG=always_sync $md_inst/Mesen \$*
fi
_EOF_
    chmod 755 "$md_inst/mesence.sh"

    cat >"$md_inst/mesence-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="MesenCE"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
    Axis 3: dZone 25309, xZone 3163, +mouse 3, -key 0
    Axis 4: gradient, maxSpeed 3, tCurve 0, mouse+h
    Axis 5: gradient, maxSpeed 3, tCurve 0, mouse+v
    Axis 6: dZone 25309, xZone 3163, +mouse 1, -key 0
    Button 11: mouse 1
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run $md_id
if [[ "\$1" == '' ]] || [[ "\$1" == *"+Start Mesen"* ]]; then
    VC4_DEBUG=always_sync $md_inst/Mesen
else
    VC4_DEBUG=always_sync $md_inst/Mesen \$*
fi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1

# Restart qjoypad IF DTWPID qjoypad@Desktop is Enabled + startx is running
if [[ -f /etc/xdg/autostart/qjoypad-start.desktop ]] && pgrep -f startx &> /dev/null 2>&1; then qjoypad-start > /dev/null 2>&1; fi

exit 0
_EOF_
    chmod 755 "$md_inst/mesence-qjoy.sh"

    [[ "$md_mode" == "install" ]] && game_data_mesen-ce
    [[ "$md_mode" == "install" ]] && shortcuts_icons_mesen-ce
}

function shortcuts_icons_mesen-ce() {
    local shortcut_name
    shortcut_name="MesenCE"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Community fork of Mesen Multi-System Emulator
Exec=$md_inst/Mesen
Icon=$md_inst/MesenCE_64x64.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Mesen
StartupWMClass=MesenCE
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/MesenCE_64x64.xpm" << _EOF_
/* XPM */
static char * MesenCE_64x64_xpm[] = {
"64 64 10 1",
"   c #40B342",
".  c #3A8034",
"+  c #FFFFFF",
"@  c #204D1D",
"#  c #6EB960",
"\$ c #229034",
"%  c #1A461A",
"&  c #236324",
"*  c #052D10",
"=  c #1B5F22",
"                                                            ....",
"                                                            ....",
"                                                            ....",
"                                                            ....",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++########################++++++++++++++++@@@@",
"    ++++++++++++++++########################++++++++++++++++@@@@",
"    ++++++++++++++++########################++++++++++++++++@@@@",
"    ++++++++++++++++########################++++++++++++++++@@@@",
"    ++++++++########\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$%%%%&&&&++++++++@@@@",
"    ++++++++########\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$%%%%&&&&++++++++@@@@",
"    ++++++++########\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$%%%%&&&&++++++++@@@@",
"    ++++++++########\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$%%%%&&&&++++++++@@@@",
"    ++++####\$\$\$\$\$\$\$\$####++++++++++++++++%%%%********&&&&++++@@@@",
"    ++++####\$\$\$\$\$\$\$\$####++++++++++++++++%%%%********&&&&++++@@@@",
"    ++++####\$\$\$\$\$\$\$\$####++++++++++++++++%%%%********&&&&++++@@@@",
"    ++++####\$\$\$\$\$\$\$\$####++++++++++++++++%%%%********&&&&++++@@@@",
"    ++++\$\$\$\$\$\$\$\$####++++++++\$\$\$\$\$\$\$\$++++++++&&&&********++++@@@@",
"    ++++\$\$\$\$\$\$\$\$####++++++++\$\$\$\$\$\$\$\$++++++++&&&&********++++@@@@",
"    ++++\$\$\$\$\$\$\$\$####++++++++\$\$\$\$\$\$\$\$++++++++&&&&********++++@@@@",
"    ++++\$\$\$\$\$\$\$\$####++++++++\$\$\$\$\$\$\$\$++++++++&&&&********++++@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$++++====****++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$++++====****++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$++++====****++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$++++====****++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$====********++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$====********++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$====********++++++++&&&&****&&&&@@@@",
"    ####\$\$\$\$####++++++++\$\$\$\$====********++++++++&&&&****&&&&@@@@",
"    ++++####\$\$\$\$####++++++++********++++++++&&&&****&&&&++++@@@@",
"    ++++####\$\$\$\$####++++++++********++++++++&&&&****&&&&++++@@@@",
"    ++++####\$\$\$\$####++++++++********++++++++&&&&****&&&&++++@@@@",
"    ++++####\$\$\$\$####++++++++********++++++++&&&&****&&&&++++@@@@",
"    ++++++++####\$\$\$\$====++++++++++++++++********&&&&++++++++@@@@",
"    ++++++++####\$\$\$\$====++++++++++++++++********&&&&++++++++@@@@",
"    ++++++++####\$\$\$\$====++++++++++++++++********&&&&++++++++@@@@",
"    ++++++++####\$\$\$\$====++++++++++++++++********&&&&++++++++@@@@",
"    ++++++++++++%%%%&&&&****************&&&&&&&&++++++++++++@@@@",
"    ++++++++++++%%%%&&&&****************&&&&&&&&++++++++++++@@@@",
"    ++++++++++++%%%%&&&&****************&&&&&&&&++++++++++++@@@@",
"    ++++++++++++%%%%&&&&****************&&&&&&&&++++++++++++@@@@",
"    ++++++++++++++++++++&&&&&&&&&&&&&&&&++++++++++++++++++++@@@@",
"    ++++++++++++++++++++&&&&&&&&&&&&&&&&++++++++++++++++++++@@@@",
"    ++++++++++++++++++++&&&&&&&&&&&&&&&&++++++++++++++++++++@@@@",
"    ++++++++++++++++++++&&&&&&&&&&&&&&&&++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++@@@@",
"....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",
"....@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"};
_EOF_
}
