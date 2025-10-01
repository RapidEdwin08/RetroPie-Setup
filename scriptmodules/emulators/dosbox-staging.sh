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

rp_module_id="dosbox-staging"
rp_module_desc="modern DOS/x86 emulator focusing on ease of use"
rp_module_help="ROM Extensions: [.CONF] [.BAT] [.EXE] [.COM] [.SH]\n \n[.CONF] Files Recommended for Compatibility\n \nPut DOS Games in PC Folder: roms/pc\n \nHide DOS Games in a Hidden Folder: roms/pc/.games\n \nHidden Folder (Linux) /.games == GAMES~1 (DOS)\neg. cd GAMES~1"
rp_module_licence="GPL2 https://raw.githubusercontent.com/dosbox-staging/dosbox-staging/master/COPYING"
rp_module_repo="git https://github.com/dosbox-staging/dosbox-staging.git :_get_branch_dosbox-staging"
rp_module_section="opt"
rp_module_flags="sdl2"

function _get_branch_dosbox-staging() {
    # use 0.80.1 for VideoCore devices, 0.81 and later require OpenGL
    if isPlatform "videocore"; then
        echo "v0.80.1"
        return
    fi
    # gcc in Debian 10 (buster) cannot compile 0.82 and later
    if [[ "$__os_debian_ver" -lt 11 ]]; then
        echo "v0.81.2"
        return
    fi
    download https://api.github.com/repos/dosbox-staging/dosbox-staging/releases/latest - | grep -m 1 tag_name | cut -d\" -f4
}

function depends_dosbox-staging() {
    local depends
    depends=(cmake libasound2-dev libglib2.0-dev libopusfile-dev libpng-dev libsdl2-dev libsdl2-net-dev libspeexdsp-dev meson ninja-build zlib1g-dev)
    if [[ "$__os_debian_ver" -ge 11 ]]; then
        depends+=(libslirp-dev libfluidsynth-dev)
    else
        # the slirp subproject requires libsdl2-image-dev to build
        depends+=(libsdl2-image-dev)
    fi

    getDepends "${depends[@]}"
}

function sources_dosbox-staging() {
    gitPullOrClone
    sed -i 's/To activate the keymapper.*/For Fullscreen press [color=light-red]Alt-Enter[color=white]. To activate the keymapper [color=light-red]%s+F1[color=white].%s ║\\n\"/g' "$md_build/src/shell/shell.cpp"
    sed -i 's+www.dosbox-staging.org.*+www.dosbox-staging.org\[color=white\]                         \[color=yellow\]C:\>GAMES~1\[color=white\]  ║\\n\"+g' "$md_build/src/shell/shell.cpp"
    #sed -i 's+www.dosbox-staging.org.*+www.dosbox-staging.org\[color=white\]  Type \[color=light-red\]DOOM\[color=white\] \+ Press ENTER \[color=yellow\]C:\>GAMES~1\[color=white\] ║\\n\"+g' "$md_build/src/shell/shell.cpp"

    # Check if we have at least meson>=0.57, otherwise install it locally for the build
    local meson_version="$(meson --version)"
    if compareVersions "$meson_version" lt 0.57; then
        downloadAndExtract "https://github.com/mesonbuild/meson/releases/download/0.61.5/meson-0.61.5.tar.gz" meson --strip-components 1
    fi
}

function build_dosbox-staging() {
    local params=(-Dprefix="$md_inst" -Ddatadir="resources" -Dtry_static_libs="iir,mt32emu")
    # use the build local Meson installation if found
    local meson_cmd="meson"
    [[ -f "$md_build/meson/meson.py" ]] && meson_cmd="python3 $md_build/meson/meson.py"

    # disable speexdsp simd support on armv6 devices
    isPlatform "armv6" && params+=(-Dspeexdsp:simd=false)

    $meson_cmd setup "${params[@]}" build
    $meson_cmd compile -j${__jobs} -C build

    md_ret_require=(
        "$md_build/build/dosbox"
    )
}

function install_dosbox-staging() {
    ninja -C build install
    md_ret_files=(        
        'contrib/icons/svg/dosbox-staging-32.svg'
        'contrib/icons/old/dosbox-old.ico'
    )
}

function remove_dosbox-staging() {
    local shortcut_name="DOSBox-Staging"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/pc/+Start $shortcut_name.sh"
}

function configure_dosbox-staging() {
    configure_dosbox
    if [[ -d "$romdir/pc" ]]; then chown -R $__user:$__user "$romdir/pc"; fi

    [[ "$md_mode" == "remove" ]] && remove_dosbox-staging
    [[ "$md_mode" == "remove" ]] && return

    mkRomDir "pc/.games"
    if [[ ! -d "$home/DOSGAMES" ]]; then ln -s $romdir/pc/.games "$home/DOSGAMES"; fi
    chown -R $__user:$__user "$romdir/pc/.games"

    cp "$romdir/pc/+Start DOSBox-Staging.sh" "$md_inst/dosbox-staging.sh"; chmod 755 "$md_inst/dosbox-staging.sh"
    sed -i 's+\[\[ -n "$DISPLAY" \]\] \&\& params\+=(-fullscreen)+if \[\[ ! "$0" == "/opt/retropie/emulators/dosbox-staging/dosbox-staging.sh" \]\] \&\& \[\[ -n "$DISPLAY" \]\]; then params\+=(-fullscreen); fi+g' "$md_inst/dosbox-staging.sh"

    local config_dir="$md_conf_root/pc"
    chown -R "$__user":"$__group" "$config_dir"

    local staging_output="texturenb"
    if isPlatform "kms"; then
        staging_output="openglnb"
    fi

    local config_path=$(su "$__user" -c "\"$md_inst/bin/dosbox\" -printconf")
    if [[ -f "$config_path" ]]; then
        iniConfig " = " "" "$config_path"
        if isPlatform "rpi"; then
            iniSet "fullscreen" "true"
            iniSet "fullresolution" "original"
            iniSet "vsync" "true"
            iniSet "output" "$staging_output"
            iniSet "core" "dynamic"
            iniSet "blocksize" "2048"
            iniSet "prebuffer" "50"
        fi
    fi

    [[ "$md_mode" == "install" ]] && shortcuts_icons_dosbox-staging
}

function shortcuts_icons_dosbox-staging() {
    local shortcut_name
    shortcut_name="DOSBox-Staging"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/dosbox-staging.sh
Icon=$md_inst/dosbox-staging-32.svg
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=DOS;DOSBox-Staging
StartupWMClass=DOSBox-Staging
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    mv "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"
}
