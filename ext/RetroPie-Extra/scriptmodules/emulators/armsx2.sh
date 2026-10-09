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

rp_module_id="armsx2"
rp_module_desc="ARMSX2 is a fork of PCSX2 focusing on the fastest native ARM performance possible."
rp_module_help="ROM Extensions: .bin .iso .img .mdf .z .z2 .bz2 .cso .chd .ima .gz\n\nCopy your PS2 roms to $romdir/ps2\nCopy the required BIOS file to $biosdir\n \n\"PlayStation\" and \"PS2\" are registered trademarks of Sony Interactive Entertainment.\n \nThis project is not affiliated in any way with \nSony Interactive Entertainment."
rp_module_licence="GPL3 https://raw.githubusercontent.com/ARMSX2/ARMSX2/refs/heads/master/COPYING.GPLv3"
rp_module_section="exp"
rp_module_flags="!all arm aarch64 !x86"

function depends_armsx2() {
    local depends=(mesa-vulkan-drivers libvulkan-dev libsdl2-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    if [[ $(apt-cache search libfuse2t64 | grep 'libfuse2t64 ') == '' ]]; then
        depends+=(libfuse2)
    else
        depends+=(libfuse2t64)
    fi
    getDepends "${depends[@]}"
}

function install_bin_armsx2() {
    local commitDATE=20261008
    local commitFULL=b1f3196b9ea6aa4e89907b02dffd63b784d13ed2

    local commitNUM=$(echo $commitFULL | cut -c1-10)
    local armsx2APP=ARMSX2-nightly-$commitDATE-$commitNUM-Linux-arm64-4K-pages.AppImage
    local armsx2SDLdir="armsx2-linux-arm64-sdl-sha[$commitNUM]"

    mkdir "$md_build"; pushd "$md_build"
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/armsx2-rp-assets.tar.gz" "$md_build"
    download "https://github.com/ARMSX2/ARMSX2/releases/download/nightly-$commitDATE/$armsx2APP" "$md_build"

    if ( isPlatform "kms" ); then
        downloadAndExtract "https://github.com/ARMSX2/ARMSX2/releases/download/nightly-$commitDATE/ARMSX2-nightly-$commitDATE-$commitNUM-Linux-arm64-SDL-handheld.tar.zst" "$md_build"
        chmod 755 "$md_build/$armsx2SDLdir/armsx2-sdl"
        rm -f "$md_build/$armsx2SDLdir/pcsx2-gsrunner"
        mv "$md_build/$armsx2SDLdir" "$md_inst"
    fi

    sed -i "s+^app_img=.*+app_img=$armsx2APP+g" "armsx2.sh"
    sed -i "s+^app_img=.*+app_img=$armsx2APP+g" "armsx2-qjoy.sh"
    sed -i "s+^app_dir=.*+app_dir=$md_inst/$armsx2SDLdir+g" "armsx2-sdl.sh"
    sed -i "s+Exec=.*+Exec=$md_inst/$armsx2APP+g" "ARMSX2.desktop"

    sed -i s+'/home/pi/'+"$home/"+g "armsx2.sh"; chmod 755 "armsx2.sh"; mv "armsx2.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "armsx2-qjoy.sh"; chmod 755 "armsx2-qjoy.sh"; mv "armsx2-qjoy.sh" "$md_inst"
    sed -i s+'/home/pi/'+"$home/"+g "armsx2-sdl.sh"; chmod 755 "armsx2-sdl.sh"; mv "armsx2-sdl.sh" "$md_inst"

    chmod 755 "$armsx2APP"; mv "$armsx2APP" "$md_inst"
    chmod 755 "ARMSX2.desktop"; cp "ARMSX2.desktop" "$md_inst"; cp "ARMSX2.desktop" "/usr/share/applications/"
    if [[ -d "$home/Desktop" ]]; then mv -f "ARMSX2.desktop" "$home/Desktop"; chown $__user:$__user "$home/Desktop/ARMSX2.desktop"; fi
    mv "ARMSX2-128x128.xpm" "$md_inst"; mv "PS2BIOSRequired.jpg" "$md_inst"

    mkdir -p "$home/.config/ARMSX2/inis"
    mkdir -p "$md_conf_root/ps2/ARMSX2"
    # Basic Settings
    sed -i s+'/home/pi/'+"$home/"+g "PCSX2.ini.armsx2"
    sed -i s+'AspectRatio =.*'+'AspectRatio = Stretch'+g "PCSX2.ini.armsx2" # I don't care what anyone says...
    sed -i s+'EnableFastBoot =.*'+'EnableFastBoot = true'+g "PCSX2.ini.armsx2"
    sed -i s+'EnablePerGameSettings =.*'+'EnablePerGameSettings = true'+g "PCSX2.ini.armsx2"
    sed -i s+'StartFullscreen =.*'+'StartFullscreen = true'+g "PCSX2.ini.armsx2"
    sed -i s+'ConfirmShutdown =.*'+'ConfirmShutdown = false'+g "PCSX2.ini.armsx2"
    sed -i s+'ShowAdvancedSettings =.*'+'ShowAdvancedSettings = true'+g "PCSX2.ini.armsx2"
    sed -i s+'GameListGridView =.*'+'GameListGridView = true'+g "PCSX2.ini.armsx2"
    sed -i s+'WarnAboutUnsafeSettings =.*'+'WarnAboutUnsafeSettings = false'+g "PCSX2.ini.armsx2"
    sed -i s+'LoadTextureReplacements =.*'+'WarnAboutUnsafeSettings = true'+g "PCSX2.ini.armsx2"
    # Missing BIOS after [moveConfigDir] related to [GameList] RecursivePaths [../../RetroPie/BIOS]; USE [$home/.config/ARMSX2/bios] for PCSX2.ini
    sed -i s+'Bios =.*'+'Bios = bios'+g "PCSX2.ini.armsx2"
    sed -i s+'MemoryCards =.*'+'MemoryCards = bios'+g "PCSX2.ini.armsx2"
    # RPi Specific Tweaks
    if isPlatform "rpi"; then
        sed -i s+'^Renderer =.*'+'Renderer = 14'+g "PCSX2.ini.armsx2" # -1 Auto 14 Vulkan
        ##sed -i s+'accurate_blending_unit =.*'+'accurate_blending_unit = 0'+g "PCSX2.ini.armsx2" # Maybe 0 is too low... (it is)
        sed -i s+'EECycleRate =.*'+'EECycleRate = -3'+g "PCSX2.ini.armsx2" # -1 %75 -2 %60 -3 %50
        ##sed -i s+'EECycleSkip =.*'+'EECycleSkip = 2'+g "PCSX2.ini.armsx2" # Do not use
        sed -i s+'EnableThreadPinning =.*'+'EnableThreadPinning = true'+g "PCSX2.ini.armsx2"
        sed -i s+'vuThread =.*'+'vuThread = true'+g "PCSX2.ini.armsx2"
        sed -i s+'vu1Instant =.*'+'vu1Instant = false'+g "PCSX2.ini.armsx2" # Don't use Instant VU1 + Multi-Threaded VU1 Simultaneously
        sed -i s+'SyncToHostRefreshRate =.*'+'SyncToHostRefreshRate = false'+g "PCSX2.ini.armsx2"
        sed -i s+'VsyncEnable =.*'+'VsyncEnable = true'+g "PCSX2.ini.armsx2"
        sed -i s+'VsyncQueueSize =.*'+'VsyncQueueSize = 2'+g "PCSX2.ini.armsx2"
        sed -i s+'^Backend =.*'+'Backend = SDL'+g "PCSX2.ini.armsx2" # Audio
    fi
    if [[ ! -f "$home/.config/ARMSX2/inis/PCSX2.ini" ]]; then cp "PCSX2.ini.armsx2" "$home/.config/ARMSX2/inis/PCSX2.ini"; fi
    if [[ ! -f "$home/.config/ARMSX2/inis/PCSX2.ini.armsx2" ]]; then mv "PCSX2.ini.armsx2" "$home/.config/ARMSX2/inis"; fi
    if [[ ! -d "$home/.config/ARMSX2/bios" ]]; then ln -s "$home/RetroPie/BIOS" "$home/.config/ARMSX2/bios"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd001.ps2" ]]; then mv "Mcd001.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -f "$home/RetroPie/BIOS/Mcd002.ps2" ]]; then mv "Mcd002.ps2" "$home/RetroPie/BIOS"; fi
    if [[ ! -d "$home/.config/ARMSX2/gamesettings" ]]; then mkdir "$home/.config/ARMSX2/gamesettings"; fi
    if [[ ! -f "$home/.config/ARMSX2/gamesettings/SLUS-46651_061F13D7.ini" ]]; then mv "SLUS-46651_061F13D7.ini" "$home/.config/ARMSX2/gamesettings"; fi
    if [[ ! -d "$home/.config/ARMSX2/covers" ]]; then mkdir "$home/.config/ARMSX2/covers"; fi
    if [[ ! -f "$home/.config/ARMSX2/covers/uLaunchELF 4.42d.png" ]]; then mv 'uLaunchELF 4.42d.png' "$home/.config/ARMSX2/covers"; fi
    chown -R $__user:$__user "$home/.config/ARMSX2"
    moveConfigDir "$home/.config/ARMSX2" "$md_conf_root/ps2/ARMSX2"
    chown -R $__user:$__user "$md_conf_root/ps2/ARMSX2"

    mkRomDir "ps2"
    chmod 755 '+Start ARMSX2.z2'; mv '+Start ARMSX2.z2' "$romdir/ps2"
    mkRomDir "ps2/media"; mkRomDir "ps2/media/image"; mkRomDir "ps2/media/marquee"; mkRomDir "ps2/media/video"
    mv 'media/image/ARMSX2.png' "$romdir/ps2/media/image"; mv 'media/marquee/ARMSX2.png' "$romdir/ps2/media/marquee"; mv 'media/video/ARMSX2.mp4' "$romdir/ps2/media/video"
    mv 'media/image/uLaunchELF.png' "$romdir/ps2/media/image"; mv 'media/marquee/uLaunchELF.png' "$romdir/ps2/media/marquee"; mv 'media/video/uLaunchELF.mp4' "$romdir/ps2/media/video"
    if [[ ! -f "$romdir/ps2/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/ps2"; else mv 'gamelist.xml' "$romdir/ps2/gamelist.xml.armsx2"; fi
    chown -R $__user:$__user "$romdir/ps2"

    mv "sx2mcmanager.sh" "$md_inst"; chmod 755 "$md_inst/sx2mcmanager.sh"
    if [[ -f /opt/retropie/configs/all/runcommand-onlaunch.sh ]]; then cat /opt/retropie/configs/all/runcommand-onlaunch.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onlaunch.sh; fi
    echo 'if [[ "$1" == "ps2" ]]; then bash /opt/retropie/emulators/armsx2/sx2mcmanager.sh onlaunch; fi #For Use With [sx2mcmanager]' >> /dev/shm/runcommand-onlaunch.sh
    mv /dev/shm/runcommand-onlaunch.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onlaunch.sh

    if [[ -f /opt/retropie/configs/all/runcommand-onend.sh ]]; then cat /opt/retropie/configs/all/runcommand-onend.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onend.sh; fi
    echo 'if [ "$(head -1 /dev/shm/runcommand.info)" == "ps2" ]; then bash /opt/retropie/emulators/armsx2/sx2mcmanager.sh onend; fi #For Use With [sx2mcmanager]' >> /dev/shm/runcommand-onend.sh
    mv /dev/shm/runcommand-onend.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onend.sh

    mkdir -p /opt/retropie/configs/all/runcommand-menu
    rm -f /opt/retropie/configs/all/runcommand-menu/CacheSX2Cleaner.sh
    cp "CacheSX2Cleaner.sh" "/opt/retropie/configs/all/runcommand-menu"
    chmod 755 /opt/retropie/configs/all/runcommand-menu/CacheSX2Cleaner.sh
    chown $__user:$__user /opt/retropie/configs/all/runcommand-menu/CacheSX2Cleaner.sh
    
    if [[ -f /home/$__user/RetroPie/retropiemenu/Utilities/CacheSX2Cleaner.sh ]]; then
        rm -f /home/$__user/RetroPie/retropiemenu/Utilities/CacheSX2Cleaner.sh
        cp "CacheSX2Cleaner.sh" "/home/$__user/RetroPie/retropiemenu/Utilities"
        chown $__user:$__user "/home/$__user/RetroPie/retropiemenu/Utilities/CacheSX2Cleaner.sh"
    fi
    mv "CacheSX2Cleaner.sh" "$md_inst"; chmod 755 "$md_inst/CacheSX2Cleaner.sh"

    sed -i "s+^pkg_repo_commit=.*+pkg_repo_commit=\"$commitFULL\"+g" 'retropie.pkg'
    sed -i "s+^pkg_repo_date=.*+pkg_repo_date=\"$commitDATE\"+g" 'retropie.pkg'
    sed -i "s+^pkg_date=.*+pkg_date=\"$commitDATE\"+g" 'retropie.pkg'
    mv 'retropie.pkg' "$md_inst"

    if [[ -d "$md_build" ]]; then rm -Rf "$md_build"; fi
    popd
}

function remove_armsx2() {
    rm -f /usr/share/applications/ARMSX2.desktop
    rm -f "$home/Desktop/ARMSX2.desktop"
    rm -f "$romdir/ps2/+Start ARMSX2.z2"
    if [[ -f /opt/retropie/configs/all/runcommand-onstart.sh ]]; then # Clean up Legacy [sx2mcmanager] from runcommand-onstart.sh
        cat /opt/retropie/configs/all/runcommand-onstart.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onstart.sh
        mv /dev/shm/runcommand-onstart.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onstart.sh
    fi
    if [[ -f /opt/retropie/configs/all/runcommand-onlaunch.sh ]]; then
        cat /opt/retropie/configs/all/runcommand-onlaunch.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onlaunch.sh
        mv /dev/shm/runcommand-onlaunch.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onlaunch.sh
    fi
    if [[ -f /opt/retropie/configs/all/runcommand-onend.sh ]]; then
        cat /opt/retropie/configs/all/runcommand-onend.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onend.sh
        mv /dev/shm/runcommand-onend.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onend.sh
    fi
}

function configure_armsx2() {
    addSystem "ps2"

    if ( isPlatform "kms" ); then
        addEmulator 1 "$md_id-sdl+mcmanager" "ps2" "$md_inst/armsx2-sdl.sh --fullscreen-mode %XRES%x%YRES% %ROM%"
        addEmulator 0 "$md_id-sdl" "ps2" "$md_inst/armsx2-sdl.sh --fullscreen-mode %XRES%x%YRES% %ROM%"
        addEmulator 0 "$md_id-sdl-ui" "ps2" "$md_inst/armsx2-sdl.sh --fullscreen-mode %XRES%x%YRES%"
        addEmulator 0 "$md_id-sdl-ui+mcmanager" "ps2" "$md_inst/armsx2-sdl.sh --fullscreen-mode %XRES%x%YRES%"
    fi

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addEmulator 1 "$md_id+mcmanager" "ps2" "$launch_prefix$md_inst/armsx2.sh -bigpicture -fullscreen %ROM%"
    addEmulator 0 "$md_id" "ps2" "$launch_prefix$md_inst/armsx2.sh -bigpicture -fullscreen %ROM%"
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addEmulator 0 "$md_id-ui" "ps2" "$launch_prefix$md_inst/armsx2.sh -bigpicture -fullscreen"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-ui+qjoypad" "ps2" "$launch_prefix$md_inst/armsx2-qjoy.sh -fullscreen"
    fi

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'ps2_StartARMSX2 = "armsx2-ui' ; echo $?) == '1' ]]; then echo 'ps2_StartARMSX2 = "armsx2-ui"' >> /opt/retropie/configs/all/emulators.cfg; fi
    chown $__user:$__user /opt/retropie/configs/all/emulators.cfg

    if [[ -f /opt/retropie/configs/all/runcommand-onstart.sh ]]; then # Clean up Legacy [sx2mcmanager] from runcommand-onstart.sh
        cat /opt/retropie/configs/all/runcommand-onstart.sh | grep -v 'sx2mcmanager' > /dev/shm/runcommand-onstart.sh
        mv /dev/shm/runcommand-onstart.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onstart.sh
    fi

    [[ "$md_mode" == "remove" ]] && remove_armsx2
}
