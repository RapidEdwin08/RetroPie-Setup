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

rp_module_id="openbor-v3"
rp_module_desc="OpenBOR - Beat 'em Up Game Engine V3 (.BOR/SDL1)"
rp_module_help="*OpenBOR.PAK games NEED to be EXTRACTED as .BOR Folders*\n \nOpenBOR.BOR folders can be placed in:\n $romdir/openbor/\n \n[openbor-unpak] + [openbor-repak] Utilities are included as Additional Emulator Entries accessible via runcommand\n \n * RESTART ES after [unpak/repak] to Refresh GameList * \n \n    PAK EXTRACT v0.67 by cyperghost also Included\n    /opt/retropie/emulators/openbor-v3/extract.sh"
rp_module_licence="BSD https://raw.githubusercontent.com/rofl0r/openbor/master/LICENSE"
rp_module_repo="git https://github.com/rofl0r/openbor.git master"
rp_module_section="exp"
rp_module_flags="sdl1 !mali !x11 !rpi5"

function depends_openbor() {
    getDepends libsdl1.2-dev libsdl-gfx1.2-dev libogg-dev libvorbisidec-dev libvorbis-dev libpng-dev zlib1g-dev
}

function sources_openbor-v3() {
    gitPullOrClone
    download "http://raw.githubusercontent.com/crcerror/RetroPie-OpenBOR-scripts/master/extract.sh" "$md_build"
    sed -i s+'/home/pi/'+"/home/$__user/"+g "$md_build/extract.sh"
    sed -i s+'roms/ports/openbor/pak'+'roms/openbor/extract-pak'+g "$md_build/extract.sh"
    sed -i s"+pi\!+$__user\!+g" "$md_build/extract.sh"
    sed -i s"+EXTRACT_BOREXE=.*+EXTRACT_BOREXE=\""$md_inst/borpak\""+g" "$md_build/extract.sh"
    sed -i s"+BORROM_DIR=.*+BORROM_DIR=\""$romdir/openbor\""+g" "$md_build/extract.sh"
    sed -i s"+BORPAK_DIR=.*+BORPAK_DIR=\""\$BORROM_DIR/extract-pak\""+g" "$md_build/extract.sh"
    sed -i s'+"Aborting.*+"Aborting... No files to extract in $BORPAK_DIR!"; sleep 5+g' "$md_build/extract.sh"
}

function build_openbor-v3() {
    local params=()
    ! isPlatform "x11" && params+=(NO_GL=1)
    make clean
    make "${params[@]}"
    cd "$md_build/tools/borpak/"
    ./build-linux.sh
    md_ret_require="$md_build/OpenBOR"
}

function install_openbor-v3() {
    md_ret_files=(
       'OpenBOR'
       'tools/borpak/borpak'
       'resources/OpenBOR_Icon_32x32.ico'
       'extract.sh'
    )
}

function remove_openbor-v3() {
    rm -f /usr/share/applications/OpenBOR-V3.desktop
    rm -f "$home/Desktop/OpenBOR-V3.desktop"
    rm -f "$home/RetroPie/roms/openbor/+Start OpenBOR.sh"
    rm -f "$home/RetroPie/retropiemenu/OpenBOR PAK Extract.sh"
    rm -f "$romdir/openbor/extract-pak/README.txt"
}

function configure_openbor-v3() {
    chmod 755 "$md_inst/extract.sh"
    chmod 755 "$md_inst/borpak"

    local dir
    for dir in ScreenShots Saves; do
        mkUserDir "$md_conf_root/$md_id/$dir"
        ln -snf "$md_conf_root/$md_id/$dir" "$md_inst/$dir"
    done
    chown -R $__user:$__user "$md_conf_root/$md_id"
    ln -snf "/dev/shm" "$md_inst/Logs"

    mkRomDir "openbor"
    mkRomDir "openbor/extract-pak"
    echo Place as many .PAK files you want Extract HERE. > "$romdir/openbor/extract-pak/README.txt"
    echo OpenBOR PAK Extract can be ran from RetroPie Menu or [$md_inst/extract.sh] >> "$romdir/openbor/extract-pak/README.txt"
    ln -snf "$romdir/openbor" "$md_inst/Paks"
    chown -R $__user:$__user "$romdir/openbor"

    isPlatform "dispmanx" && setBackend "$md_id" "dispmanx"
    ! isPlatform "dispmanx" && isPlatform "kms" && setBackend "$md_id" "sdl12-compat"

    addEmulator 0 "$md_id-unpak" "$md_id" "$md_inst/$md_id.sh unpak %ROM%"
    addEmulator 0 "$md_id-repak" "$md_id" "$md_inst/$md_id.sh repak %ROM%"
    addEmulator 1 "$md_id" "$md_id" "$md_inst/$md_id.sh %ROM%"
    addSystem "openbor" "OpenBOR" ".pak .sh .bor"
    sed -i s'+_SYS_\ openbor+_SYS_\ openbor-v3+g' /etc/emulationstation/es_systems.cfg
    if [[ -f /opt/retropie/configs/all/emulationstation/es_systems.cfg ]]; then
        sed -i s'+_SYS_\ openbor+_SYS_\ openbor-v3+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
    fi

    cat >"$romdir/openbor/+Start OpenBOR.sh" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "$md_id" ""
_EOF_
    chmod 755 "$romdir/openbor/+Start OpenBOR.sh"
    chown $__user:$__user "$romdir/openbor/+Start OpenBOR.sh"

    local shortcut_name
    shortcut_name="OpenBOR-V3"
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
elif [[ "\$1" == *".pak" ]] || [[ "\$1" == *".PAK" ]]; then # This version of OpenBOR V3 does NOT support Un-Extracted .PAK Files
        echo This version of OpenBOR V3 does NOT support Un-Extracted .PAK Files
        echo Use \'openbor-unpak\' to convert .PAK Files to [.BOR/data] Folders
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

    cat >"$home/RetroPie/retropiemenu/OpenBOR PAK Extract.sh" << _EOF_
#!/bin/bash
$md_inst/extract.sh
_EOF_
    chmod 755 "$home/RetroPie/retropiemenu/OpenBOR PAK Extract.sh"
    chown $__user:$__user "$home/RetroPie/retropiemenu/OpenBOR PAK Extract.sh"

    [[ "$md_mode" == "remove" ]] && remove_openbor-v3
}
