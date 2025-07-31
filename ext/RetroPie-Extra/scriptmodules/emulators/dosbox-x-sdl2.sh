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

rp_module_id="dosbox-x-sdl2"
rp_module_desc="DOSBox-X (SDL2)\n \nDOSBox-X is an open-source DOS emulator for running DOS applications and games +Support for DOS-based Windows such as Windows 3.x and Windows 9x."
rp_module_help="ROM Extensions: [.CONF] [.BAT] [.EXE] [.COM] [.SH]\n \n[.CONF] Files Recommended for Compatibility\n \nPut DOS Games in PC Folder: roms/pc\n \nHide DOS Games in a Hidden Folder: roms/pc/.games\n \nHidden Folder (Linux) /.games == GAMES~1 (DOS)\neg. cd GAMES~1"
rp_module_licence="GNU https://raw.githubusercontent.com/joncampbell123/dosbox-x/master/COPYING"
rp_module_repo="git https://github.com/joncampbell123/dosbox-x.git master"
rp_module_section="exp"
rp_module_flags="sdl2"

function depends_dosbox-x-sdl2() {
    local depends=(
        automake libncurses-dev nasm fluid-soundfont-gm whiptail
        libpcap-dev libfluidsynth-dev ffmpeg libavformat-dev
        libswscale-dev libavcodec-dev xorg matchbox)
    isPlatform "64bit" && depends+=(libavdevice59)
    isPlatform "32bit" && depends+=(libavdevice58)
    #depends+=(libsdl-net1.2-dev)
    depends+=(libsdl2-dev libsdl2-mixer-dev libsdl2-net-dev)
    getDepends "${depends[@]}"
    echo "${depends[@]}"
}

function sources_dosbox-x-sdl2() {
    gitPullOrClone
    sed -i 's/HAVE FUN WITH DOSBox-X.*/Type DOOM and Press ENTER | [F12+F] Fullscreen | [F12+ESC] MenuBar | C:\\\>GAMES~1/g' "$md_build/contrib/translations/en/en_US.lng"
    sed -i 's/HAVE FUN WITH DOSBox-X.*/Type DOOM and Press ENTER | [F12+F] Fullscreen | [F12+ESC] MenuBar | C:\\\>GAMES~1"\)\;/g' "$md_build/src/shell/shell.cpp"
    sed -i 's+--enable-debug=heavy.*+--enable-debug --prefix=/usr --enable-sdl2 "${@}" "${opt}" || exit 1+g' "$md_build/build-debug-sdl2"
}

function build_dosbox-x-sdl2() {
    ./build-debug-sdl2 --prefix="$md_inst"
}

function install_dosbox-x-sdl2() {
    make install
}

function game_data_dosbox-x-sdl2() { # Can DOSBox-X Run Doom?
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/dosbox-x/dosbox-x-rp-assets.tar.gz" "$md_inst/share/dosbox-x/drivez"
    if [[ ! -d "$romdir/pc/.games/DOOMSW" ]]; then cp -R "$md_inst/share/dosbox-x/drivez/DOOM" "$romdir/pc/.games/DOOMSW"; chown -R $__user:$__user "$romdir/pc/.games/DOOMSW"; fi; chown -R $__user:$__user "$md_inst/share/dosbox-x/drivez/DOOM"
    sed -i s+'/home/pi/'+"$home/"+g "$md_inst/share/dosbox-x/drivez/DOOM.conf"; mv "$md_inst/share/dosbox-x/drivez/DOOM.conf" "$romdir/pc/Doom (Shareware) v1.2.conf"; chown $__user:$__user "$romdir/pc/Doom (Shareware) v1.2.conf"
    mkRomDir "pc/media"; mkRomDir "pc/media/image"; mkRomDir "pc/media/marquee"; mkRomDir "pc/media/video"
    mv "$md_inst/share/dosbox-x/drivez/media/image/DOSBox-X.png" "$romdir/pc/media/image"; mv "$md_inst/share/dosbox-x/drivez/media/marquee/DOSBox-X.png" "$romdir/pc/media/marquee"
    mv "$md_inst/share/dosbox-x/drivez/media/image/DOSBox-Staging.png" "$romdir/pc/media/image"; mv "$md_inst/share/dosbox-x/drivez/media/marquee/DOSBox-Staging.png" "$romdir/pc/media/marquee"
    mv "$md_inst/share/dosbox-x/drivez/media/image/Doom 1 (Shareware).jpg" "$romdir/pc/media/image"; mv "$md_inst/share/dosbox-x/drivez/media/marquee/Doom.png" "$romdir/pc/media/marquee"
    rm -Rf "$md_inst/share/dosbox-x/drivez/media"
    if [[ ! -f "$romdir/pc/gamelist.xml" ]]; then mv "$md_inst/share/dosbox-x/drivez/gamelist.xml" "$romdir/pc"; else mv -f "$md_inst/share/dosbox-x/drivez/gamelist.xml" "$romdir/pc/gamelist.xml.dosbox-x"; fi
    chown -R $__user:$__user -R "$romdir/pc"
}

function remove_dosbox-x-sdl2() {
    if [[ -f /usr/share/applications/DOSBox-X.desktop ]]; then sudo rm -f /usr/share/applications/DOSBox-X.desktop; fi
    if [[ -f "$home/Desktop/DOSBox-X.desktop" ]]; then rm -f "$home/Desktop/DOSBox-X.desktop"; fi
    if [[ -f "$romdir/pc/+Start DOSBox-X.sh" ]]; then rm "$romdir/pc/+Start DOSBox-X.sh"; fi
    if [[ -f "$md_conf_root/dosbox-x/README.TXT" ]]; then rm -f "$md_conf_root/dosbox-x/README.TXT"; fi
}

function configure_dosbox-x-sdl2() {
    mkRomDir "pc"
    mkRomDir "pc/.games"
    moveConfigDir "$home/.config/dosbox-x" "$md_conf_root/pc"
    if [[ ! -d "$md_conf_root/pc/GAMES" ]]; then ln -s $romdir/pc/.games "$md_conf_root/pc/GAMES"; fi
    chown -R $__user:$__user "$romdir/pc/.games"

    sed -i "s+Exec=.*+Exec=$md_inst/bin/dosbox-x\ -defaultdir\ $md_conf_root/pc\ -nopromptfolder \-c\ \"MOUNT C \"$home/RetroPie/roms/pc\"\"+g" "$md_inst/share/applications/com.dosbox_x.DOSBox-X.desktop"
    sed -i "s+Icon=.*+Icon=$md_inst/share/icons/hicolor/scalable/apps/dosbox-x.svg+g" "$md_inst/share/applications/com.dosbox_x.DOSBox-X.desktop"
    chmod 755 "$md_inst/share/applications/com.dosbox_x.DOSBox-X.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/share/applications/com.dosbox_x.DOSBox-X.desktop" "$home/Desktop/DOSBox-X.desktop"; chown $__user:$__user "$home/Desktop/DOSBox-X.desktop"; fi
    mv "$md_inst/share/applications/com.dosbox_x.DOSBox-X.desktop" "/usr/share/applications/DOSBox-X.desktop"

    local script="$md_inst/$md_id.sh"
    cat > "$script" << _EOF_
#!/bin/bash
dos_exe=\$(basename "\$1")
dos_dir=\$(dirname "\$1")

# Attempt to pull DOS Short~1 Names~2 for 8-Character Limit
dos_bat=\$(echo \$dos_exe | rev | cut -d "." -f2- | rev)
short_name=\$(echo "\$dos_bat" | cut -c-6)
short_num=\$(ls -1trp "\$dos_dir" | grep -v / | grep "\$short_name" | nl -w1 -s'+++' | grep "\$dos_exe" | rev | cut -d "+" -f4- | rev)
if [[ \${#dos_bat} -ge 9 ]] ; then dos_bat=\$short_name~\$short_num; fi

# DOSBox-X Params
params+=(-defaultdir /opt/retropie/configs/pc)
if [[ "\$1" == *"+Start DOSBox-X"* ]] || [[ "\$1" == '' ]]; then
    params=(-c "@MOUNT C \$HOME/RetroPie/roms/pc");
elif [[ "\$1" == *".EXE" ]] || [[ "\$1" == *".exe" ]]; then
    params=(-c "@MOUNT C \"\$dos_dir\"" -c @C: -c \"\$dos_exe\" -fs)
elif [[ "\$1" == *".COM" ]] || [[ "\$1" == *".com" ]]; then
    params=(-c "@MOUNT C \"\$dos_dir\"" -c @C: -c \"\$dos_exe\" -fs)
elif [[ "\$1" == *".BAT" ]] || [[ "\$1" == *".bat" ]]; then
    params=(-c "@MOUNT C \"\$dos_dir\"" -c @C: -c \$dos_bat -fs)
elif [[ "\$1" == *".CONF" ]] || [[ "\$1" == *".conf" ]]; then
    params=(-userconf -conf "\$1" -fs)
elif [[ "\$1" == *".SH" ]] || [[ "\$1" == *".sh" ]]; then
    bash "\$1"; exit
else
    params=(-c "@MOUNT C \"\$1\"" -c "@C:" -fs)
fi

if [[ ! "\$1" == *"+Start DOSBox-X"* ]] && [[ ! "\$1" == '' ]]; then
    params+=(-exit)
fi
echo "\${params[@]}" >> /dev/shm/runcommand.info

# Start DOSBox-X
xset -dpms s off s noblank
matchbox-window-manager -use_titlebar no &
/opt/retropie/emulators/dosbox-x-sdl2/bin/dosbox-x "\${params[@]}"
_EOF_

    chmod +x "$script"
    local launch_prefix=XINIT-WMC; if [[ "$(cat $home/RetroPie-Setup/scriptmodules/supplementary/runcommand/runcommand.sh | grep XINIT-WMC)" == '' ]]; then local launch_prefix=XINIT; fi
    addPort "$md_id" "dosbox-x" "+Start DOSBox-X" "$launch_prefix:$script"
    mv "$romdir/ports/+Start DOSBox-X.sh" "$romdir/pc/+Start DOSBox-X.sh"
    sed -i 's+_PORT_.*+_SYS_ "dosbox-x" ""+g' "$romdir/pc/+Start DOSBox-X.sh"
    chown $__user:$__user "$romdir/pc/+Start DOSBox-X.sh"

    addEmulator "1" "$md_id" "pc" "$launch_prefix:$script %ROM%"
    addSystem "pc"
    echo "Called by $romdir/pc/+Start DOSBox-X.sh" > "$md_conf_root/dosbox-x/README.TXT"; chown $__user:$__user "$md_conf_root/dosbox-x/README.TXT"

    [[ "$md_mode" == "install" ]] && game_data_dosbox-x-sdl2
}
