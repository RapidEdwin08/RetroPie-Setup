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

rp_module_id="openbor-v4"
rp_module_desc="OpenBOR - Beat 'em Up Game Engine V4 (.PAK/SDL2)"
rp_module_help="*   OpenBOR.PAK games do NOT need to be Extracted   *\n \nOpenBOR.PAK files can be placed in:\n $romdir/openbor/\n \n[openbor-unpak] + [openbor-repak] Utilities are included as Additional Emulator Entries accessible via runcommand\n \n * RESTART ES after [unpak/repak] to Refresh GameList * "
rp_module_licence="BSD https://raw.githubusercontent.com/DCurrent/openbor/refs/heads/master/LICENSE"
rp_module_repo="git https://github.com/DCurrent/openbor.git master"
rp_module_section="exp"
rp_module_flags="sdl2 !mali !rpi3"

function depends_openbor-v4() {
    getDepends libogg-dev libvorbisidec-dev libvorbis-dev libpng-dev zlib1g-dev libvpx-dev libsdl2-dev libsdl2-mixer-dev libsdl2-image-dev libsdl2-gfx-dev
}

function sources_openbor-v4() {
    gitPullOrClone
}

function build_openbor-v4() {
    btarget=universal; dtarget="UNIVERSAL"
    if [[ "$__platform_arch" =~ (i386|i686) ]]; then btarget=x86; dtarget="X86"; fi
    if [[ "$__platform_arch" == 'x86_64' ]]; then btarget=amd64; dtarget="AMD64"; fi
    if isPlatform "aarch64"; then btarget=arm64; dtarget="ARM64"; fi
    cmake -DBUILD_LINUX=ON -DUSE_SDL=ON -DTARGET_ARCH=$dtarget -S . -B build.lin.$btarget && cmake --build build.lin.$btarget --config Release -- -j
    cd "$md_build/tools/borpak/source"
    chmod 755 ./build.sh; ./build.sh Linux
    md_ret_require=(
        "$md_build/build.lin.$btarget/OpenBOR"
        "$md_build/tools/borpak/source/borpak"
    )
}

function install_openbor-v4() {
    md_ret_files=(
       "build.lin.$btarget/OpenBOR"
       'tools/borpak/source/borpak'
       'engine/resources/OpenBOR_Icon_32x32.ico'
    )
}

function remove_openbor-v4() {
    rm -f /usr/share/applications/OpenBOR.desktop
    rm -f "$home/Desktop/OpenBOR.desktop"
    rm -f "$home/RetroPie/roms/openbor/+Start OpenBOR.sh"
}

function configure_openbor-v4() {
    chmod 755 "$md_inst/borpak"

    local dir
    for dir in ScreenShots Saves; do
        mkUserDir "$md_conf_root/$md_id/$dir"
        ln -snf "$md_conf_root/$md_id/$dir" "$md_inst/$dir"
    done
    chown -R $__user:$__user "$md_conf_root/$md_id"
    ln -snf "/dev/shm" "$md_inst/Logs"

    mkRomDir "openbor"
    ln -snf "$romdir/openbor" "$md_inst/Paks"
    chown -R $__user:$__user "$romdir/openbor"

    addEmulator 0 "$md_id-unpak" "$md_id" "$md_inst/$md_id.sh unpak %ROM%"
    addEmulator 0 "$md_id-repak" "$md_id" "$md_inst/$md_id.sh repak %ROM%"
    addEmulator 1 "$md_id" "$md_id" "$md_inst/$md_id.sh %ROM%"
    addSystem "openbor" "OpenBOR" ".pak .sh .bor"
    sed -i s'+_SYS_\ openbor+_SYS_\ openbor-v4+g' /etc/emulationstation/es_systems.cfg
    if [[ -f /opt/retropie/configs/all/emulationstation/es_systems.cfg ]]; then
        sed -i s'+_SYS_\ openbor+_SYS_\ openbor-v4+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
    fi

    cat >"$romdir/openbor/+Start OpenBOR.sh" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "$md_id" ""
_EOF_
    chmod 755 "$romdir/openbor/+Start OpenBOR.sh"
    chown $__user:$__user "$romdir/openbor/+Start OpenBOR.sh"

    local shortcut_name
    shortcut_name="OpenBOR"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=OpenBOR
GenericName=OpenBOR
Comment=Open Source Beats Of Rage Engine
Exec=$md_inst/$md_id.sh
Icon=$md_inst/OpenBOR_Icon_32x32.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=BOR;BeatsOfRage
StartupWMClass=OpenBOR
Name[en_US]=OpenBOR
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/$md_id.sh" << _EOF_
#!/bin/bash
app_dir=$md_inst
bp_name=\$(basename "\$2")
bp_name=\${bp_name%.*}
bp_dir=\$(dirname "\$2")

# Start OpenBOR
if [[ "\$1" == '' ]] || [[ "\$1" == *"+Start OpenBOR"* ]]; then
        pushd "\$app_dir"; \$app_dir/OpenBOR; popd
elif [[ "\$1" == *".sh" ]] || [[ "\$1" == *".SH" ]]; then
        bash "\$1"
elif [[ "\$1" == *".bor" ]] || [[ "\$1" == *".BOR" ]]; then # This version of OpenBOR V4 does NOT support Extracted .BOR/data Folders
        echo This version of OpenBOR V4 does NOT support Extracted [.BOR] Folders like rofl0r\'s Fork of OpenBOR V3 [https://github.com/rofl0r/openbor.git]
        echo Use \'openbor-repak\' to convert .BOR/data Folders to .PAK
        exit 0
elif [[ "\$1" == "unpak" ]]; then # borpak (Extract) .PAK Files to .BOR/data Folders
        newBOR=\$bp_name-BOR.bor
        if [[ -d "\$bp_dir/\$newBOR" ]]; then newBOR=\$bp_name-BOR-\$(date +"%Y%m%d%H%M%S").bor; fi
        if [[ ! -f "\$2" ]]; then echo [\$(basename "\$2")] is NOT [.PAK] a File!; exit 0; fi
        if [[ ! -f "\$app_dir/borpak" ]]; then echo [\$app_dir/borpak] is MISSING!; exit 0; fi
        mkdir -p "\$bp_dir/\$newBOR"
        pushd "\$bp_dir"; printf "%s\n" "Y" | \$app_dir/borpak -d "\$newBOR" "\$(basename "\$2")"; popd
        echo New BOR: "\$bp_dir/\$newBOR"
        ##echo Restarting ES to Refresh GameList; touch /tmp/es-restart; pkill -f "/opt/retropie/supplementary/.*/emulationstation([^.]|$)" &
        exit 0
elif [[ "\$1" == "repak" ]]; then # borpak (Repack) .BOR/data Folders to .PAK Files
        newPAK=\$bp_name-PAK.pak
        if [[ -f "\$bp_dir/\$newPAK" ]]; then newPAK=\$bp_name-PAK-\$(date +"%Y%m%d%H%M%S").pak; fi
        if [[ ! -d "\$2" ]]; then echo [\$(basename "\$2")] is NOT a [.BOR] Directory!; exit 0; fi
        if [[ ! -d "\$2/data" ]]; then echo [\$(basename "\$2")] is MISSING [data] Directory!; exit 0; fi
        if [[ ! -f "\$app_dir/borpak" ]]; then echo [\$app_dir/borpak] is MISSING!; exit 0; fi
        pushd "\$2"; printf "%s\n" "Y" | \$app_dir/borpak -b -d data "\$newPAK"
        mv "\$newPAK" "\$bp_dir"; #mv "\$2" "\$2.original"
        popd; echo New PAK: "\$bp_dir/\$newPAK"
        ##echo Restarting ES to Refresh GameList; touch /tmp/es-restart; pkill -f "/opt/retropie/supplementary/.*/emulationstation([^.]|$)" &
        exit 0
else
        pushd "\$app_dir"; \$app_dir/OpenBOR "\$@"; popd
fi

_EOF_
    chmod 755 "$md_inst/$md_id.sh"

    [[ "$md_mode" == "remove" ]] && remove_openbor-v4
}
