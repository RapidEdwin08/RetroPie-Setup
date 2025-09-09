#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="eduke32"
rp_module_desc="Duke3D Source Port - Ken Silverman's Build Engine"
rp_module_help="Place Game Files in [ports/ksbuild]:\n \nports/ksbuild/duke3d\nDUKE3D.GRP\nDUKE.RTS\n \nports/ksbuild/ionfury\nfury.grp\nfury.def\n \nports/ksbuild/duke3d/addons/dc\nports/ksbuild/duke3d/addons/nw\nports/ksbuild/duke3d/addons/vacation\nports/ksbuild/duke3d/addons/nam"
rp_module_licence="GPL2 https://voidpoint.io/terminx/eduke32/-/raw/master/package/common/gpl-2.0.txt?inline=false"
if [[ "$__os_debian_ver" -le 10 ]]; then
    rp_module_repo="git https://voidpoint.io/terminx/eduke32.git master dfc16b08"
elif [[ "$__os_debian_ver" -ge 12 ]] && isPlatform "rpi"; then
    #rp_module_repo="git https://voidpoint.io/dgurney/eduke32.git master 76bc19e2"
    rp_module_repo="git https://voidpoint.io/sirlemonhead/eduke32.git master 3191b5f4"
else
    #rp_module_repo="git https://voidpoint.io/terminx/eduke32.git master"
    rp_module_repo="git https://voidpoint.io/terminx/eduke32.git master 126f35ca"
fi
rp_module_section="opt"

function depends_eduke32() {
    local depends=(
        flac libflac-dev libvorbis-dev libpng-dev libvpx-dev freepats
        libsdl2-dev libsdl2-mixer-dev zip unzip
    )

    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
    getDepends "${depends[@]}"
}

function sources_eduke32() {
    gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/scriptmodules/ports/eduke32/Duke3D_48x48.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/scriptmodules/ports/eduke32/IonFury_64x64.ico" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/scriptmodules/ports/eduke32/eduke32_48x48.xpm" "$md_build"

    if [[ "$__os_debian_ver" -le 10 ]]; then
        # Updated Controller config for legacy terminx
        applyPatch "$md_data/0000-controller-buttons-legacy.diff"
        # r6918 causes a 20+ second delay on startup on ARM devices
        isPlatform "arm" && applyPatch "$md_data/0001-revert-r6918.patch"
        # r7424 gives a black skybox when r_useindexedcolortextures is 0
        applyPatch "$md_data/0002-fix-skybox.patch"
        # r6776 breaks VC4 & GLES 2.0 devices that lack GL_RED internal
        # format support for glTexImage2D/glTexSubImage2D
        isPlatform "gles" && applyPatch "$md_data/0003-replace-gl_red.patch"
        # gcc 6.3.x compiler fix
        applyPatch "$md_data/0004-recast-function.patch"
        # cherry-picked commit fixing a game bug in E1M4 (shrinker ray stuck)
        applyPatch "$md_data/0005-e1m4-shrinker-bug.patch"
        # two more commits r8241 + r8247 fixing a bug in E4M4 (instant death in water)
        applyPatch "$md_data/0006-e4m4-water-bug.patch"
    elif [[ "$__os_debian_ver" -ge 12 ]] && isPlatform "rpi"; then
        # Updated Controller config for sirlemonhead
        applyPatch "$md_data/0000-controller-buttons-sirlemonhead.diff"
        # gcc 6.3.x compiler fix
        applyPatch "$md_data/0004-recast-function.patch"
        # useindexedcolortextures 0FF
        sed -i s+int32_t\ r_useindexedcolortextures\ =.*+int32_t\ r_useindexedcolortextures\ =\ 0\;+ $md_build/source/build/src/polymost.cpp
        # VC4 & V3D + Kernel 6.12.x render shading incorrectly when using [r_usenewshading = 4] + [r_useindexedcolortextures = 0] eg. E1M1 Theatre
        sed -i s+int32_t\ r_usenewshading\ =.*+int32_t\ r_usenewshading\ =\ 3\;+ $md_build/source/build/src/polymost.cpp
    else
        # Updated Controller config for terminx
        applyPatch "$md_data/0000-controller-buttons-terminx.diff"
        # useindexedcolortextures 0FF
        sed -i s+int32_t\ r_useindexedcolortextures\ =.*+int32_t\ r_useindexedcolortextures\ =\ 0\;+ $md_build/source/build/src/polymost.cpp
    fi
}

function build_eduke32() {
    local params=(LTO=0 SDL_TARGET=2 STARTUP_WINDOW=0)

    [[ "$md_id" == "ionfury" ]] && params+=(FURY=1)
    ! isPlatform "x86" && params+=(NOASM=1)
    ! isPlatform "x11" && params+=(HAVE_GTK2=0)
    ! isPlatform "gl3" && params+=(POLYMER=0)
    ! ( isPlatform "gl" || isPlatform "mesa" ) && params+=(USE_OPENGL=0)
    # r7242 requires >1GB memory allocation due to netcode changes.
    isPlatform "arm" && params+=(NETCODE=0)

    make veryclean
    CFLAGS+=" -DSDL_USEFOLDER" make -j"$(nproc)" "${params[@]}"

    if [[ "$md_id" == "ionfury" ]]; then
        md_ret_require="$md_build/fury"
    else
        md_ret_require="$md_build/eduke32"
    fi
}

function install_eduke32() {
    md_ret_files=(
        'mapster32'
        'Duke3D_48x48.xpm'
        'IonFury_64x64.ico'
        'eduke32_48x48.xpm'
    )

    if [[ "$md_id" == "ionfury" ]]; then
        md_ret_files+=('fury')
    else
        md_ret_files+=('eduke32')
    fi
}

function game_data_eduke32() {
    local dest="$romdir/ports/ksbuild/duke3d"
    if [[ "$md_id" == "eduke32" ]]; then
        mkUserDir "$dest"
        if [[ -z "$(find "$dest" -maxdepth 1 -iname duke3d.grp)" ]]; then
            local temp="$(mktemp -d)"
            download "$__archive_url/3dduke13.zip" "$temp"
            unzip -L -o "$temp/3dduke13.zip" -d "$temp" dn3dsw13.shr
            unzip -L -o "$temp/dn3dsw13.shr" -d "$dest" duke3d.grp duke.rts
            rm -rf "$temp"
            chown -R "$__user":"$__group" "$dest"
        fi
    fi
}

function remove_eduke32() {
    if [[ -f "/usr/share/applications/Duke Nukem 3D.desktop" ]]; then sudo rm -f "/usr/share/applications/Duke Nukem 3D.desktop"; fi
    if [[ -f "$home/Desktop/Duke Nukem 3D.desktop" ]]; then rm -f "$home/Desktop/Duke Nukem 3D.desktop"; fi
    if [[ -f "/usr/share/applications/Ion Fury.desktop" ]]; then sudo rm -f "/usr/share/applications/Ion Fury.desktop"; fi
    if [[ -f "$home/Desktop/Ion Fury.desktop" ]]; then rm -f "$home/Desktop/Ion Fury.desktop"; fi
    if [[ -f "$romdir/ports/Ion Fury.sh" ]]; then rm -f "$romdir/ports/Ion Fury.sh"; fi

    if [[ -f /opt/retropie/configs/all/runcommand-onstart.sh ]]; then
        cat /opt/retropie/configs/all/runcommand-onstart.sh | grep -v 'eduke32+' > /dev/shm/runcommand-onstart.sh
        mv /dev/shm/runcommand-onstart.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onstart.sh
    fi
    if [[ -f /opt/retropie/configs/all/runcommand-onend.sh ]]; then
        cat /opt/retropie/configs/all/runcommand-onend.sh | grep -v 'eduke32+' > /dev/shm/runcommand-onend.sh
        mv /dev/shm/runcommand-onend.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onend.sh
    fi
}

function configure_eduke32() {
    local appname="eduke32"
    local portname="duke3d"
    if [[ "$md_id" == "ionfury" ]]; then
        appname="fury"
        portname="ionfury"
    fi
    local config="$md_conf_root/$portname/settings.cfg"

    mkRomDir "ports/ksbuild"
    mkRomDir "ports/ksbuild/$portname"
    mkRomDir "ports/ksbuild/duke3d/addons"
    mkRomDir "ports/ksbuild/duke3d/addons/dc"
    mkRomDir "ports/ksbuild/duke3d/addons/nw"
    mkRomDir "ports/ksbuild/duke3d/addons/vacation"
    mkRomDir "ports/ksbuild/duke3d/addons/nam"
    mkRomDir "ports/ksbuild/ionfury"
    moveConfigDir "$home/.config/$appname" "$md_conf_root/$portname"

    add_games_eduke32 "$portname" "$md_inst/$appname"

    # remove old launch script
    rm -f "$romdir/ports/Duke3D Shareware.sh"

    if [[ "$md_mode" == "install" ]]; then
        game_data_eduke32

        touch "$config"
        iniConfig " " '"' "$config"

        # enforce vsync for kms targets
        isPlatform "kms" && iniSet "r_swapinterval" "1"

        # the VC4 & V3D drivers render menu splash colours incorrectly without this
        if [[ "$__os_debian_ver" -ge 12 ]] && isPlatform "rpi"; then
            iniSet "r_useindexedcolortextures" "0"
            iniSet "r_usenewshading" "3"
        else
            isPlatform "mesa" && iniSet "r_useindexedcolortextures" "0"
        fi

        cat > "$md_conf_root/duke3d/eduke32.cfg" << _EOF_
[Controls]
ControllerButton0 = "Jump"
ControllerButton1 = "Open"
ControllerButton2 = "Toggle_Crouch"
ControllerButton3 = "Quick_Kick"
ControllerButton4 = "Map"
ControllerButton5 = "Third_Person_View"
ControllerButton7 = "Run"
ControllerButton8 = "Center_View"
ControllerButton9 = "Previous_Weapon"
ControllerButton10 = "Next_Weapon"
ControllerButton11 = "AutoRun"
ControllerButton12 = "Inventory"
ControllerButton13 = "Inventory_Left"
ControllerButton14 = "Inventory_Right"
ControllerAnalogDead1 = 3500
ControllerAnalogDead2 = 3500
ControllerAnalogDead3 = 3500
ControllerAnalogDead4 = 3500
_EOF_

        # ionfury.cfg [Controls] "Use/Open" "Reload Walk" "Radar" "MedKit" "Last_Used_Weapon" "Quick_Swap_Electrifryer"
        cat > "$md_conf_root/duke3d/ionfury.cfg" << _EOF_
[Controls]
ControllerButton0 = "Jump"
ControllerButton1 = "Use/Open"
ControllerButton2 = "Toggle_Crouch"
ControllerButton3 = "Reload"
ControllerButton4 = "Map"
ControllerButton5 = "Third_Person_View"
ControllerButton7 = "Walk"
ControllerButton8 = "Center_View"
ControllerButton9 = "Previous_Weapon"
ControllerButton10 = "Next_Weapon"
ControllerButton11 = "Radar"
ControllerButton12 = "MedKit"
ControllerButton13 = "Last_Used_Weapon"
ControllerButton14 = "Quick_Swap_Electrifryer"
ControllerAnalogDead1 = 3500
ControllerAnalogDead2 = 3500
ControllerAnalogDead3 = 3500
ControllerAnalogDead4 = 3500
_EOF_

        # dukeplus.cfg [Controls] "DUKEPLUS_MENU"
        cat > "$md_conf_root/duke3d/dukeplus.cfg" << _EOF_
[Controls]
ControllerButton0 = "Jump"
ControllerButton1 = "Open"
ControllerButton2 = "Toggle_Crouch"
ControllerButton3 = "Quick_Kick"
ControllerButton4 = "Map"
ControllerButton5 = "DUKEPLUS_MENU"
ControllerButton7 = "Run"
ControllerButton8 = "Center_View"
ControllerButton9 = "Previous_Weapon"
ControllerButton10 = "Next_Weapon"
ControllerButton11 = "AutoRun"
ControllerButton12 = "Inventory"
ControllerButton13 = "Inventory_Left"
ControllerButton14 = "Inventory_Right"
ControllerAnalogDead1 = 3500
ControllerAnalogDead2 = 3500
ControllerAnalogDead3 = 3500
ControllerAnalogDead4 = 3500
_EOF_

        # dukeforces.cfg [Controls] "INTERACT"
        cat > "$md_conf_root/duke3d/dukeforces.cfg" << _EOF_
[Controls]
ControllerButton0 = "Jump"
ControllerButton1 = "INTERACT"
ControllerButton2 = "Toggle_Crouch"
ControllerButton3 = "Quick_Kick"
ControllerButton4 = "Map"
ControllerButton5 = "Third_Person_View"
ControllerButton7 = "Run"
ControllerButton8 = "Center_View"
ControllerButton9 = "Previous_Weapon"
ControllerButton10 = "Next_Weapon"
ControllerButton11 = "AutoRun"
ControllerButton12 = "Inventory"
ControllerButton13 = "Inventory_Left"
ControllerButton14 = "Inventory_Right"
ControllerAnalogDead1 = 3500
ControllerAnalogDead2 = 3500
ControllerAnalogDead3 = 3500
ControllerAnalogDead4 = 3500
_EOF_

        chown -R "$__user":"$__group" "$config"
        chown -R $__user:$__user "$md_conf_root/duke3d"
    fi
}

function add_games_eduke32() {
    local portname="$1"
    local binary="$2"
    local game
    local game_args
    local game_path
    local game_launcher
    local num_games=4

    if [[ "$md_id" == "ionfury" ]]; then
        num_games=0
        local game0=('Ion Fury' '' '')
    else
        local game0=('Duke Nukem 3D' '' '-addon 0')
        local game1=('Duke Nukem 3D - Duke It Out In DC' 'addons/dc' '-addon 1')
        local game2=('Duke Nukem 3D - Nuclear Winter' 'addons/nw' '-addon 2')
        local game3=('Duke Nukem 3D - Caribbean - Lifes A Beach' 'addons/vacation' '-addon 3')
        local game4=('NAM' 'addons/nam' '-nam')
    fi

    for ((game=0;game<=num_games;game++)); do
        game_launcher="game$game[0]"
        game_path="game$game[1]"
        game_args="game$game[2]"

        if [[ -d "$romdir/ports/ksbuild/$portname/${!game_path}" ]]; then
           addPort "$md_id" "$portname" "${!game_launcher}" "pushd $md_conf_root/$portname; ${binary}.sh %ROM%; popd" "-j$romdir/ports/ksbuild/$portname/${game0[1]} -j$romdir/ports/ksbuild/$portname/${!game_path} ${!game_args}"
        fi
    done

    if [[ "$md_mode" == "install" ]]; then
        # we need to use a dumb launcher script to strip quotes from runcommand's generated arguments
        cat > "${binary}.sh" << _EOF_
#!/bin/bash
# HACK: force vsync for RPI Mesa driver for now
VC4_DEBUG=always_sync $binary \$*
_EOF_
        chmod 755 "${binary}.sh"
    fi

        cat > "$romdir/ports/Ion Fury.sh" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _PORT_ "duke3d" "-gamegrp \$HOME/RetroPie/roms/ports/ksbuild/ionfury/fury.grp -game_dir \$HOME/RetroPie/roms/ports/ksbuild/ionfury -cfg ionfury.cfg"
_EOF_
        chown $__user:$__user "$romdir/ports/Ion Fury.sh"

    cat > "$md_inst/eduke32_plus.sh" << _EOF_
#!/bin/bash

# Pull [-cfg] Name from [runcommand.info] to Manage saves and configs
game=\$(head -3 /dev/shm/runcommand.info | tail +3 | grep '\-cfg'  | rev | cut -c 5- | awk '{print \$1}' | rev)
cfg_dir=/opt/retropie/configs/ports/duke3d/
last_run=\$cfg_dir/last.run

if [ "\$1" == "onstart" ]; then
    if [ "\$game" == '' ]; then exit 0; fi
    # Create [-cfg] Name Dir for saves - Create [-cfg] Name files based on [eduke32.cfg] and [settings.cfg] if not found
    if [[ ! -f \$cfg_dir/\$game.cfg ]]; then cp \$cfg_dir/eduke32.cfg \$cfg_dir/\$game.cfg > /dev/null 2>&1; fi
    if [[ ! -f \$cfg_dir/"\$game"_settings.cfg ]]; then cp \$cfg_dir/settings.cfg \$cfg_dir/"\$game"_settings.cfg > /dev/null 2>&1; fi
    mkdir \$cfg_dir/\$game > /dev/null 2>&1
    if [[ -f "\$last_run" ]]; then mkdir \$cfg_dir/\$(cat \$last_run); mv \$cfg_dir/save* \$cfg_dir/\$(cat \$last_run)/ > /dev/null 2>&1; fi
    echo \$game > \$last_run
    mv \$cfg_dir/\$game/save* \$cfg_dir > /dev/null 2>&1
    exit 0
fi

if [ "\$1" == "onend" ]; then
    # Move saves to [-cfg] Name Dir
    if [ "\$game" == '' ]; then exit 0; fi
    mv \$cfg_dir/save* \$cfg_dir/\$game/  > /dev/null 2>&1
    rm \$last_run > /dev/null 2>&1
    exit 0
fi
_EOF_
    chmod 755 "$md_inst/eduke32_plus.sh"
    if [[ -f /opt/retropie/configs/all/runcommand-onstart.sh ]]; then cat /opt/retropie/configs/all/runcommand-onstart.sh | grep -v 'eduke32+' > /dev/shm/runcommand-onstart.sh; fi
    echo 'if [[ "$1" == "duke3d" ]]; then bash /opt/retropie/ports/eduke32/eduke32_plus.sh onstart; fi #For Use With [eduke32+]' >> /dev/shm/runcommand-onstart.sh
    mv /dev/shm/runcommand-onstart.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onstart.sh
    if [[ -f /opt/retropie/configs/all/runcommand-onend.sh ]]; then cat /opt/retropie/configs/all/runcommand-onend.sh | grep -v 'eduke32+' > /dev/shm/runcommand-onend.sh; fi
    echo 'if [ "$(head -1 /dev/shm/runcommand.info)" == "duke3d" ]; then bash /opt/retropie/ports/eduke32/eduke32_plus.sh onend; fi #For Use With [eduke32+]' >> /dev/shm/runcommand-onend.sh
    mv /dev/shm/runcommand-onend.sh /opt/retropie/configs/all; chown $__user:$__user /opt/retropie/configs/all/runcommand-onend.sh

    cat >"$md_inst/Duke Nukem 3D.desktop" << _EOF_
[Desktop Entry]
Name=Duke Nukem 3D
GenericName=Duke Nukem 3D
Comment=Duke Nukem 3D
Exec=$md_inst/eduke32 -j$romdir/ports/ksbuild/duke3d/ -addon 0
Icon=$md_inst/Duke3D_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=D3D;Duke;Nukem;3D
StartupWMClass=DukeNukem3D
Name[en_US]=Duke Nukem 3D
_EOF_
    chmod 755 "$md_inst/Duke Nukem 3D.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Duke Nukem 3D.desktop" "$home/Desktop/Duke Nukem 3D.desktop"; chown $__user:$__user "$home/Desktop/Duke Nukem 3D.desktop"; fi
    mv "$md_inst/Duke Nukem 3D.desktop" "/usr/share/applications/Duke Nukem 3D.desktop"

    cat >"$md_inst/Ion Fury.desktop" << _EOF_
[Desktop Entry]
Name=Ion Fury
GenericName=Ion Fury
Comment=Ion Fury
Exec=$md_inst/eduke32 -gamegrp $romdir/ports/ksbuild/ionfury/fury.grp -game_dir $romdir/ports/ksbuild/ionfury -cfg ionfury.cfg
Icon=$md_inst/IonFury_64x64.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=IonFury;Ion Fury
StartupWMClass=IonFury
Name[en_US]=Ion Fury
_EOF_
    chmod 755 "$md_inst/Ion Fury.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Ion Fury.desktop" "$home/Desktop/Ion Fury.desktop"; chown $__user:$__user "$home/Desktop/Ion Fury.desktop"; fi
    mv "$md_inst/Ion Fury.desktop" "/usr/share/applications/Ion Fury.desktop"

    [[ "$md_mode" == "remove" ]] && remove_eduke32
}
