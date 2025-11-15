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

rp_module_id="lr-scummvm"
rp_module_desc="ScummVM - Script Creation Utility for Maniac Mansion Port for libretro"
rp_module_help="Place your ScummVM games in: $romdir/scummvm\n\nThe name of your game directories must be suffixed with '.svm' for direct launch in EmulationStation"
rp_module_licence="GPL3 https://raw.githubusercontent.com/libretro/scummvm/master/COPYING"
rp_module_repo="git https://github.com/libretro/scummvm.git master"
rp_module_section="exp"

function depends_lr-scummvm() {
    getDepends zip fluid-soundfont-gm
}

function sources_lr-scummvm() {
    gitPullOrClone
}

function build_lr-scummvm() {
    local gl_platform=OPENGL
    isPlatform "gles" && gl_platform=OPENGLES2
    cd backends/platform/libretro
    make clean
    make USE_MT32EMU=1 FORCE_${gl_platform}=1
    make datafiles
    md_ret_require="$md_build/backends/platform/libretro/scummvm_libretro.so"
}

function install_lr-scummvm() {
    md_ret_files=(
        "backends/platform/libretro/scummvm_libretro.so"
        "backends/platform/libretro/scummvm.zip"
        "COPYING"
    )
}

function configure_lr-scummvm() {
    addEmulator 0 "$md_id" "scummvm" "$md_inst/romdir-launcher.sh %ROM%"
    addSystem "scummvm"
    [[ "$md_mode" == "remove" ]] && remove_lr-scummvm
    [[ "$md_mode" == "remove" ]] && return

    # ensure rom dir and system retroconfig
    mkRomDir "scummvm"
    defaultRAConfig "scummvm"

    # unpack the data files to system dir
    runCmd unzip -q -o "$md_inst/scummvm.zip" -d "$biosdir"
    mkdir -p "$biosdir/scummvm/icons"
    mkdir -p "$biosdir/scummvm/saves"
    chown -R "$__user":"$__user" "$biosdir/scummvm"

    # basic initial configuration (if config file not found)
    local sound_font="$biosdir/scummvm/extra/Roland_SC-55.sf2"
    if [[ -f "/usr/share/sounds/sf2/FluidR3_GM.sf2" ]]; then sound_font="/usr/share/sounds/sf2/FluidR3_GM.sf2"; fi
    if [[ ! -f "$biosdir/scummvm.ini" ]]; then
        echo "[scummvm]" > "$biosdir/scummvm.ini"
        iniConfig "=" "" "$biosdir/scummvm.ini"
        iniSet "extrapath" "$biosdir/scummvm/extra"
        iniSet "themepath" "$biosdir/scummvm/theme"
        iniSet "iconspath" "$biosdir/scummvm/icons"
        iniSet "savepath" "$biosdir/scummvm/saves"
        iniSet "browser_lastpath" "$home/RetroPie/roms/scummvm"
        iniSet "soundfont" "$sound_font"
        iniSet "gui_theme" "residualvm"
        iniSet "gui_launcher_chooser" "grid"
        iniSet "gui_scale" "175"
        iniSet "fullscreen" "true"
        iniSet "aspect_ratio" "true"
        iniSet "subtitles" "true"
        iniSet "multi_midi" "true"
        iniSet "gm_device" "fluidsynth"
        iniSet "sfx_volume" "169"
        iniSet "music_volume" "179"
        iniSet "speech_volume" "192"
        iniSet "music_driver" "auto"
        iniSet "mt32_device" "mt32"
        iniSet "midi_gain" "100"
        iniSet "kbdmouse_speed" "3"
        iniSet "confirm_exit" "false"
        iniSet "gfx_mode" "opengl"
        chown "$__user":"$__user" "$biosdir/scummvm.ini"
    fi

    if ! grep -q 'extra=LucasArts' "$biosdir/scummvm.ini"; then
        cat >>"$biosdir/scummvm.ini" << _EOF_


[FullThrottle]
description=FullThrottle
extra=LucasArts
path=$home/RetroPie/roms/scummvm/FullThrottle.svm
extrapath=$biosdir/scummvm/extra
engineid=scumm
enhancements=1
gameid=ft
original_gui=true
original_gui_text_status=1
language=en
dimuse_low_latency_mode=false
shader=default
platform=pc
aspect_ratio=true
stretch_mode=stretch
guioptions=sndNoMIDI vga gameOption4 gameOption5 lang_English
_EOF_
        chown "$__user":"$__user" "$biosdir/scummvm.ini"
    fi

    # enable speed hack core option if running in arm platform
    isPlatform "arm" && setRetroArchCoreOption "scummvm_speed_hack" "enabled"

    # on videocore platforms, disable the HW GL context since it leads to a crash
    isPlatform "videocore" && setRetroArchCoreOption "scummvm_video_hw_acceleration" "disabled"

    # create retroarch launcher for lr-scummvm with support for rom directories
    # containing svm files inside (for direct game directory launching in ES)
    cat > "$md_inst/romdir-launcher.sh" << _EOF_
#!/usr/bin/env bash
ROM=\$1; shift
SVM_FILES=()
[[ -d \$ROM ]] && mapfile -t SVM_FILES < <(compgen -G "\$ROM/*.svm")
[[ \${#SVM_FILES[@]} -eq 1 ]] && ROM=\${SVM_FILES[0]}
$emudir/retroarch/bin/retroarch \\
    -L "$md_inst/scummvm_libretro.so" \\
    --config "$md_conf_root/scummvm/retroarch.cfg" \\
    "\$ROM" "\$@"
_EOF_
    chmod +x "$md_inst/romdir-launcher.sh"

    [[ "$md_mode" == "install" ]] && game_data_scummvm
}
