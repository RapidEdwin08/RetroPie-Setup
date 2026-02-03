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

rp_module_id="dosbox-staging-dev"
rp_module_desc="modern DOS/x86 emulator focusing on ease of use"
rp_module_help="ROM Extensions: [.CONF] [.BAT] [.EXE] [.COM] [.SH]\n \n[.CONF] Files Recommended for Compatibility\n \nPut DOS Games in PC Folder: roms/pc\n \nHide DOS Games in a Hidden Folder: roms/pc/.games\n \nHidden Folder (Linux) /.games == GAMES~1 (DOS)\neg. cd GAMES~1"
rp_module_licence="GPL2 https://raw.githubusercontent.com/dosbox-staging/dosbox-staging/master/COPYING"
rp_module_repo="git https://github.com/dosbox-staging/dosbox-staging.git main :_get_commit_dosbox-staging-dev"
rp_module_section="exp"
rp_module_flags="sdl2"

function _get_commit_dosbox-staging-dev() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch_tag=main
    local branch_commit="$(git ls-remote https://github.com/dosbox-staging/dosbox-staging.git $branch_tag HEAD | grep $branch_tag | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo e3b60f12
}

function depends_dosbox-staging-dev() {
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

function sources_dosbox-staging-dev() {
    gitPullOrClone
    sed -i 's/To activate the keymapper.*/For Fullscreen press [color=light-red]Alt-Enter[color=white]. To activate the keymapper [color=light-red]%s+F1[color=white].%s ║\\n\"/g' "$md_build/src/shell/shell.cpp"
    sed -i 's+www.dosbox-staging.org.*+www.dosbox-staging.org\[color=white\]                         \[color=yellow\]C:\>GAMES~1\[color=white\]  ║\\n\"+g' "$md_build/src/shell/shell.cpp"
    #sed -i 's+www.dosbox-staging.org.*+www.dosbox-staging.org\[color=white\]  Type \[color=light-red\]DOOM\[color=white\] \+ Press ENTER \[color=yellow\]C:\>GAMES~1\[color=white\] ║\\n\"+g' "$md_build/src/shell/shell.cpp"

    # patch kmsdrm # e3b60f12 # Rename sdlmain.cpp|h to sdl_gui.cpp|h
    #if isPlatform "kms"; then applyPatch "$md_data/0.82.x-kmsdrm-fix.diff"; fi

    # Check if we have at least meson>=0.57, otherwise install it locally for the build
    local meson_version="$(meson --version)"
    if compareVersions "$meson_version" lt 0.57; then
        downloadAndExtract "https://github.com/mesonbuild/meson/releases/download/0.61.5/meson-0.61.5.tar.gz" meson --strip-components 1
    fi
}

function build_dosbox-staging-dev() {
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

function install_dosbox-staging-dev() {
    ninja -C build install
    if [[ -f "$md_build/extras/icons/svg/dosbox-staging-32.svg" ]]; then
        md_ret_files=('extras/icons/svg/dosbox-staging-32.svg')
    else
        md_ret_files=('contrib/icons/svg/dosbox-staging-32.svg')
    fi
}

function remove_dosbox-staging-dev() {
    local shortcut_name="DOSBox-Staging"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/pc/+Start $shortcut_name.sh"
}

function configure_dosbox-staging-dev() {
    configure_dosbox
    addEmulator "1" "$md_id" "pc" "$md_inst/dosbox-staging.sh %ROM%" # Overwrite prior [configure_dosbox] entry that pointed to /roms/pc/+Start DOSBox-Staging
    if [[ -d "$romdir/pc" ]]; then chown -R $__user:$__user "$romdir/pc"; fi

    [[ "$md_mode" == "remove" ]] && remove_dosbox-staging-dev
    [[ "$md_mode" == "remove" ]] && return

    mkRomDir "pc/.games"
    if [[ ! -d "$home/DOSGAMES" ]]; then ln -s $romdir/pc/.games "$home/DOSGAMES"; fi
    chown -R $__user:$__user "$romdir/pc/.games"

    #sed -i 's+-freesize 1024+-freesize 2048+g' "$romdir/pc/+Start DOSBox-Staging.sh"
    cp "$romdir/pc/+Start DOSBox-Staging.sh" "$md_inst/dosbox-staging.sh"; chmod 755 "$md_inst/dosbox-staging.sh"
    sed -i 's+running in X+running with ROM, windowed when running withOUT ROM in X+g' "$md_inst/dosbox-staging.sh"
    sed -i 's+\[\[ -n "$DISPLAY" \]\] \&\& params\+=(-fullscreen)+if \[\[ ! "$1" == "" \]\]; then params\+=(-fullscreen); else if \[\[ ! -n "$DISPLAY" \]\]; then params\+=(-fullscreen); fi; fi+g' "$md_inst/dosbox-staging.sh"
    sed -i 's+running in X+running from ES+g' "$romdir/pc/+Start DOSBox-Staging.sh"
    sed -i 's+\[\[ -n "$DISPLAY" \]\] \&\& params\+=(-fullscreen)+params\+=(-fullscreen)+g' "$romdir/pc/+Start DOSBox-Staging.sh"
    chown $__user:$__user "$romdir/pc/+Start DOSBox-Staging.sh"

    local config_dir="$md_conf_root/pc"
    local shell_history="$config_dir/shell_history.txt"
    if [[ ! -f "$shell_history" ]]; then cat > "$shell_history" << _EOF_; fi
exit
intro
_EOF_
    chown -R "$__user":"$__group" "$config_dir"

    local staging_output="opengl"
    if isPlatform "kms"; then
        staging_output="texturenb" # openglnb Deprecated value
    fi

    local config_path=$(su "$__user" -c "\"$md_inst/bin/dosbox\" -printconf")
    if [[ -f "$config_path" ]]; then
        iniConfig " = " "" "$config_path"
        iniSet "cpu_cycles" "max"
        iniSet "cpu_cycles_protected" "auto" # fixed values are not allowed if 'cpu_cycles' is 'max', using 'auto'
        iniSet "output" "$staging_output"
        iniSet "fullscreen" "false" # Dynamically set by DOSBox-Staging.sh instead
        iniSet "fullscreen_mode" "standard" # fullresolution/desktop = Deprecated values
        iniSet "window_size" "default"
        iniSet "vsync" "false" # true = Slower in fullscreen with X
        iniSet "blocksize" "2048"
        iniSet "prebuffer" "50"
        if isPlatform "rpi"; then
            iniSet "core" "dynamic"
        fi
    fi

    [[ "$md_mode" == "install" ]] && shortcuts_icons_dosbox-staging-dev
}

function shortcuts_icons_dosbox-staging-dev() {
    local shortcut_name="DOSBox-Staging"
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
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
}
