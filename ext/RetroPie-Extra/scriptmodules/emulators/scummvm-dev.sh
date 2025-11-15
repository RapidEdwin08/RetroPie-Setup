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

rp_module_id="scummvm-dev"
rp_module_desc="ScummVM - Script Creation Utility for Maniac Mansion"
rp_module_help="Place your ScummVM games in: $romdir/scummvm\n\nThe name of your game directories must be suffixed with '.svm' for direct launch in EmulationStation\n\n             Ctrl-F5 for ScummVM MENU"
rp_module_licence="GPL3 https://raw.githubusercontent.com/scummvm/scummvm/master/COPYING"
rp_module_repo="git https://github.com/scummvm/scummvm.git master :_get_commit_scummvm-dev"
rp_module_section="exp"
rp_module_flags="sdl2"

function _get_commit_scummvm-dev() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch_tag=master
    local branch_commit="$(git ls-remote https://github.com/dosbox-staging/dosbox-staging.git $branch_tag HEAD | grep $branch_tag | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo ce9e35fd; # RELEASE: This is 3.1.0git
}

function depends_scummvm-dev() {
    local depends=(
        liba52-0.7.4-dev libmpeg2-4-dev libogg-dev libvorbis-dev libflac-dev libgif-dev libmad0-dev libpng-dev
        libtheora-dev libfaad-dev libfluidsynth-dev libfreetype6-dev zlib1g-dev
        libjpeg-dev libasound2-dev libcurl4-openssl-dev libmikmod-dev libvpx-dev
        fluid-soundfont-gm
    )
    if isPlatform "vero4k"; then
        depends+=(vero3-userland-dev-osmc)
    fi
    if [[ "$md_id" == "scummvm-sdl1" ]]; then
        depends+=(libsdl1.2-dev)
    else
        depends+=(libsdl2-dev)
    fi
    getDepends "${depends[@]}"
}

function sources_scummvm-dev() {
    gitPullOrClone
}

function build_scummvm-dev() {
    rpSwap on 750
    local params=(
        --prefix="$md_inst"
        --enable-release --enable-vkeybd
        --disable-debug --disable-eventrecorder --disable-sonivox
    )
    isPlatform "rpi" && isPlatform "32bit" && params+=(--host=raspberrypi)
    isPlatform "rpi" && [[ "$md_id" == "scummvm-sdl1" ]] && params+=(--opengl-mode=none)
    # stop scummvm using arm-linux-gnueabihf-g++ which is v4.6 on
    # wheezy and doesn't like rpi2 cpu flags
    if isPlatform "rpi"; then
        if [[ "$md_id" == "scummvm-sdl1" ]]; then
            SDL_CONFIG=sdl-config CC="gcc" CXX="g++" ./configure "${params[@]}"
        else
            CC="gcc" CXX="g++" ./configure "${params[@]}"
        fi
    else
        ./configure "${params[@]}"
    fi
    make clean
    make
    strip "$md_build/scummvm"
    rpSwap off
    md_ret_require="$md_build/scummvm"
}

function install_scummvm-dev() {
    make install
    mkdir -p "$md_inst/extra"
    cp -v backends/vkeybd/packs/vkeybd_*.zip "$md_inst/extra"
}

function game_data_scummvm-dev() {
    # Full Throttle Demo
    if [[ ! -f "$romdir/scummvm/FullThrottle.svm/monster.sou" ]] && [[ ! -f "$romdir/scummvm/FullThrottle.svm/MONSTER.SOU" ]]; then
        if [[ -f "$romdir/scummvm/FullThrottle.svm" ]]; then mv "$romdir/scummvm/FullThrottle.svm" "$romdir/scummvm/FullThrottle.svm.bak"; fi
        if [[ -d "$romdir/scummvm/FullThrottle.svm" ]]; then mv "$romdir/scummvm/FullThrottle.svm" "$romdir/scummvm/FullThrottle.BAK"; fi
        downloadAndExtract "https://archive.org/download/FullThrottleDemo/ftdemo.zip" "$romdir/scummvm"
        mv "$romdir/scummvm/ftdemo" "$romdir/scummvm/FullThrottle.svm"
        chmod -R 664 "$romdir/scummvm/FullThrottle.svm"
        chown -R "$__user":"$__user" "$romdir/scummvm/FullThrottle.svm"
    fi

    local icons_dir="$md_conf_root/scummvm/ScummVM/icons"
    [[ "$md_id" == "lr-scummvm" ]] && icons_dir="$biosdir/scummvm/icons"
    if [[ ! -f "$icons_dir/gui-icons-ft.dat" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/emulators/$md_id/$md_id-rp-assets.tar.gz" "$icons_dir"
        mv "$icons_dir/$md_id-rp-assets.tar.gz" "$icons_dir/gui-icons-ft.dat"
        chown "$__user":"$__user" "$icons_dir/gui-icons-ft.dat"
    fi
}

function remove_scummvm-dev() {
    local shortcut_name="ScummVM"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/scummvm/+Start $shortcut_name.sh"

    shortcut_name="Full Throttle"
    if [[ -d "/opt/retropie/libretrocores/lr-scummvm" ]]; then
        sed -i s+Icon=.*+Icon=/opt/retropie/libretrocores/lr-scummvm/FullThrottle_74x74.xpm+ "/usr/share/applications/$shortcut_name.desktop"
        if [[ -f "$home/Desktop/$shortcut_name.desktop" ]]; then sed -i s+Icon=.*+Icon=/opt/retropie/libretrocores/lr-scummvm/FullThrottle_74x74.xpm+ "$home/Desktop/$shortcut_name.desktop"; fi
    else
        rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    fi
}

function gui_scummvm-dev() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      Get Additional Desktop Shortcuts + Icons\n\nGet Desktop Shortcuts for Additional Episodes + Add-Ons that may not have been present at Install\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "Get Shortcuts + Icons" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            game_data_scummvm-dev
            shortcuts_icons_scummvm-dev
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_scummvm-dev() {
    mkRomDir "scummvm"

    local dir
    for dir in .config .local/share; do
        moveConfigDir "$home/$dir/scummvm" "$md_conf_root/scummvm"
    done

    # Create startup script
    rm -f "$romdir/scummvm/+Launch GUI.sh"
    local name="ScummVM"
    [[ "$md_id" == "scummvm-sdl1" ]] && name="ScummVM-SDL1"
    cat > "$romdir/scummvm/+Start $name.sh" << _EOF_
#!/bin/bash
game="\$1"
pushd "$romdir/scummvm" >/dev/null
if ! grep -qs extrapath "\$HOME/.config/scummvm/scummvm.ini"; then
    params="--extrapath="$md_inst/extra""
fi
$md_inst/bin/scummvm --fullscreen \$params --joystick=0 "\$game"
while read id desc; do
    echo "\$desc" > "$romdir/scummvm/\$id.svm"
done < <($md_inst/bin/scummvm --list-targets | tail -n +3)
popd >/dev/null
_EOF_
    chown "$__user":"$__user" "$romdir/scummvm/+Start $name.sh"
    chmod u+x "$romdir/scummvm/+Start $name.sh"
    cp -v "$romdir/scummvm/+Start $name.sh" "$md_inst/scummvm.sh"; chmod 755 "$md_inst/scummvm.sh"

    #addEmulator 1 "$md_id" "scummvm" "bash $romdir/scummvm/+Start\ $name.sh %BASENAME%"
    addEmulator 1 "$md_id" "scummvm" "bash $md_inst/scummvm.sh %BASENAME%"
    addSystem "scummvm"

    [[ "$md_mode" == "remove" ]] && remove_scummvm-dev
    [[ "$md_mode" == "remove" ]] && return

    mkdir -p "$md_conf_root/scummvm/ScummVM"
    mkdir -p "$md_conf_root/scummvm/ScummVM/extra"
    mkdir -p "$md_conf_root/scummvm/ScummVM/icons"
    mkdir -p "$md_conf_root/scummvm/ScummVM/saves"
    mkdir -p "$md_conf_root/scummvm/ScummVM/theme"
    if [[ ! -f "$md_conf_root/scummvm/ScummVM/themes/residualvm.zip" ]]; then cp -v $md_inst/share/scummvm/residualvm.zip "$md_conf_root/scummvm/ScummVM/themes"; fi
    if [[ "$(ls $md_conf_root/scummvm/ScummVM/extra/vkeybd_*)" == '' ]]; then cp -v $md_inst/extra/vkeybd_*.zip "$md_conf_root/scummvm/ScummVM/extra"; fi
    chown -R "$__user":"$__user" "$md_conf_root/scummvm/ScummVM"

    [[ "$md_mode" == "install" ]] && game_data_scummvm-dev
    [[ "$md_mode" == "install" ]] && shortcuts_icons_scummvm-dev

    local sound_font=/opt/retropie/emulators/scummvm/share/scummvm/Roland_SC-55.sf2
    if [[ -f "/usr/share/sounds/sf2/FluidR3_GM.sf2" ]]; then sound_font=/usr/share/sounds/sf2/FluidR3_GM.sf2; fi
    if [[ ! -f "$md_conf_root/scummvm/scummvm.ini" ]]; then
        echo "[scummvm]" > "$md_conf_root/scummvm/scummvm.ini"
        iniConfig "=" "" "$md_conf_root/scummvm/scummvm.ini"
        iniSet "extrapath" "$md_conf_root/scummvm/ScummVM/extra"
        iniSet "themepath" "$md_conf_root/scummvm/theme"
        iniSet "iconspath" "$md_conf_root/scummvm/ScummVM/icons"
        iniSet "savepath" "$md_conf_root/scummvm/ScummVM/saves"
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
        chown "$__user":"$__user" "$md_conf_root/scummvm/scummvm.ini"
    fi

    if ! grep -q 'extra=LucasArts' "$md_conf_root/scummvm/scummvm.ini"; then
        cat >>"$md_conf_root/scummvm/scummvm.ini" << _EOF_


[FullThrottle]
description=FullThrottle
extra=LucasArts
path=$home/RetroPie/roms/scummvm/FullThrottle.svm
extrapath=$md_conf_root/scummvm/ScummVM/extra
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
guioptions=sndNoMIDI vga gameOption4 gameOption5 lang_English
scaler=normal
scale_factor=5
stretch_mode=stretch
_EOF_
        if isPlatform "arm" || isPlatform "rpi"; then
            if ! isPlatform "rpi4" && ! isPlatform "rpi5"; then
                sed 's/\(.*\)scale_factor=5/\1scale_factor=1/' "$md_conf_root/scummvm/scummvm.ini" | sed 's/\(.*\)stretch_mode=stretch/\1stretch_mode=fit/' > /dev/shm/tmp.ini
                mv /dev/shm/tmp.ini "$md_conf_root/scummvm/scummvm.ini"
            fi
        fi
    fi
    chown "$__user":"$__user" "$md_conf_root/scummvm/scummvm.ini"
}

function shortcuts_icons_scummvm-dev() {
    local shortcut_name

    shortcut_name="ScummVM"
    if [[ "$md_id" == "scummvm" ]]; then
        cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Ctrl-F5 for MENU
Exec=$md_inst/scummvm.sh
Icon=$md_inst/share/pixmaps/org.scummvm.scummvm.xpm
Terminal=true
Type=Application
Categories=Game;Emulator
Keywords=Maniac;Mansion;ScummVM
StartupWMClass=ScummVM
Name[en_US]=$shortcut_name
_EOF_
        chmod 755 "$md_inst/$shortcut_name.desktop"
        if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
        rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
    fi

    shortcut_name="Full Throttle"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/scummvm.sh FullThrottle"
Icon=$md_inst/FullThrottle_74x74.xpm
Terminal=true
Type=Application
Categories=Game;Emulator
Keywords=Full;Throttle;Lucas;Arts
StartupWMClass=ScummVM
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/FullThrottle_74x74.xpm" << _EOF_
/* XPM */
static char * FullThrottle_74x74_xpm[] = {
"74 74 280 2",
"   c None",
".  c #955D41",
"+  c #935B3E",
"@  c #8D5033",
"#  c #8A4C2D",
"\$     c #8A4B2C",
"%  c #8B4D2F",
"&  c #9C5F30",
"*  c #8A4C2C",
"=  c #8D4F2D",
"-  c #E7A444",
";  c #8B4D2C",
">  c #B77937",
",  c #BC7E38",
"'  c #BD7F39",
")  c #BE8039",
"!  c #BF803A",
"~  c #BF813A",
"{  c #C0823A",
"]  c #C2843A",
"^  c #C1843A",
"/  c #C1823A",
"(  c #BF8039",
"_  c #D89740",
":  c #FBB64A",
"<  c #894B2C",
"[  c #B07235",
"}  c #EDAA46",
"|  c #FAB54A",
"1  c #894A2C",
"2  c #90522D",
"3  c #BA7D38",
"4  c #F6B249",
"5  c #F9B54A",
"6  c #F9B549",
"7  c #8B4C2C",
"8  c #7C4328",
"9  c #6F3D23",
"0  c #6E3B23",
"a  c #9A662E",
"b  c #C28739",
"c  c #A56F31",
"d  c #96622D",
"e  c #8B582A",
"f  c #865329",
"g  c #845228",
"h  c #855329",
"i  c #8C582A",
"j  c #B47C36",
"k  c #E1A142",
"l  c #FCB74A",
"m  c #AB6D34",
"n  c #9C5F31",
"o  c #BB7C39",
"p  c #8F502D",
"q  c #86492B",
"r  c #764025",
"s  c #6E3C23",
"t  c #D3953E",
"u  c #774625",
"v  c #6C3A23",
"w  c #B17A35",
"x  c #F8B349",
"y  c #F9B44A",
"z  c #B67837",
"A  c #E3A143",
"B  c #8C4C2C",
"C  c #89492C",
"D  c #91532E",
"E  c #F2AD47",
"F  c #7E4428",
"G  c #C68C3A",
"H  c #7B4726",
"I  c #794226",
"J  c #814629",
"K  c #83472A",
"L  c #804629",
"M  c #7D4428",
"N  c #753F25",
"O  c #703D23",
"P  c #B87F37",
"Q  c #F7B249",
"R  c #F5B048",
"S  c #F2AF48",
"T  c #F3AF48",
"U  c #F4B149",
"V  c #F4B048",
"W  c #F6B149",
"X  c #FCB64A",
"Y  c #C78A3B",
"Z  c #90522E",
"\`     c #87492B",
" . c #724024",
".. c #DA9B41",
"+. c #894A2B",
"@. c #B57837",
"#. c #90532E",
"\$.    c #C6883B",
"%. c #794126",
"&. c #845129",
"*. c #B47737",
"=. c #E2A243",
"-. c #C4883A",
";. c #BD8338",
">. c #BC8138",
",. c #BB8138",
"'. c #E0A042",
"). c #CE913D",
"!. c #BC8238",
"~. c #C98D3B",
"{. c #EEAB46",
"]. c #C5873B",
"^. c #733F25",
"/. c #D0933D",
"(. c #713E24",
"_. c #B67E36",
":. c #814F28",
"<. c #774425",
"[. c #E4A343",
"}. c #C4863B",
"|. c #9B6030",
"1. c #784625",
"2. c #723E24",
"3. c #733F24",
"4. c #743F25",
"5. c #B07834",
"6. c #804D28",
"7. c #713D24",
"8. c #6F3C23",
"9. c #95612D",
"0. c #B77A37",
"a. c #FAB64A",
"b. c #92552E",
"c. c #84482A",
"d. c #85482A",
"e. c #B87B37",
"f. c #F7B349",
"g. c #94562E",
"h. c #BA7C38",
"i. c #94572E",
"j. c #C5863B",
"k. c #BC7F39",
"l. c #95582F",
"m. c #C6873B",
"n. c #CE8E3E",
"o. c #BD8039",
"p. c #96582F",
"q. c #C98A3C",
"r. c #A56732",
"s. c #ECA946",
"t. c #CC8D3D",
"u. c #F9B449",
"v. c #8F522E",
"w. c #8D4E2D",
"x. c #9E6131",
"y. c #EDA946",
"z. c #EFAB47",
"A. c #CF903E",
"B. c #93542E",
"C. c #94562F",
"D. c #C3843A",
"E. c #E9A645",
"F. c #DD9C42",
"G. c #EFAC47",
"H. c #95572F",
"I. c #AE7035",
"J. c #EEAA46",
"K. c #9B5E30",
"L. c #D69540",
"M. c #91522D",
"N. c #A26432",
"O. c #EAA945",
"P. c #BF8539",
"Q. c #D2943E",
"R. c #F8B449",
"S. c #9D5F30",
"T. c #F1AD47",
"U. c #E5A344",
"V. c #EBA845",
"W. c #A36E31",
"X. c #734124",
"Y. c #6D3A23",
"Z. c #AE7734",
"\`.    c #EAA745",
" + c #D5943F",
".+ c #90532D",
"++ c #E3A243",
"@+ c #6D3B23",
"#+ c #754025",
"\$+    c #BE8238",
"%+ c #E6A544",
"&+ c #D3943F",
"*+ c #784126",
"=+ c #774525",
"-+ c #ECAA46",
";+ c #8C582B",
">+ c #884A2B",
",+ c #744025",
"'+ c #7A4227",
")+ c #D89A40",
"!+ c #BB8238",
"~+ c #703E23",
"{+ c #824629",
"]+ c #C98E3C",
"^+ c #8F542D",
"/+ c #86492A",
"(+ c #703D24",
"_+ c #B98137",
":+ c #855229",
"<+ c #723E25",
"[+ c #C68B3A",
"}+ c #8C562C",
"|+ c #88492B",
"1+ c #C98B3C",
"2+ c #FBB74A",
"3+ c #995B2F",
"4+ c #C7883B",
"5+ c #985B2F",
"6+ c #985A2F",
"7+ c #C4853B",
"8+ c #C1833A",
"9+ c #975A2F",
"0+ c #96592F",
"a+ c #BF823A",
"b+ c #BF8139",
"c+ c #8F512D",
"d+ c #BF8239",
"e+ c #F6B248",
"f+ c #8E502D",
"g+ c #88492C",
"h+ c #F3B048",
"i+ c #A16432",
"j+ c #8C4E2D",
"k+ c #D79640",
"l+ c #BC7D39",
"m+ c #C3853A",
"n+ c #B37A35",
"o+ c #774126",
"p+ c #8C4D2D",
"q+ c #D59540",
"r+ c #BC7D38",
"s+ c #794726",
"t+ c #7F4528",
"u+ c #B17336",
"v+ c #EBA846",
"w+ c #D5973F",
"x+ c #794127",
"y+ c #864B2B",
"z+ c #C4893A",
"A+ c #F2AF47",
"B+ c #AF7734",
"C+ c #874A2B",
"D+ c #8A4A2C",
"E+ c #B47B36",
"F+ c #82472A",
"G+ c #AB7433",
"H+ c #8E5B2B",
"I+ c #CB8D3D",
"J+ c #99622F",
"K+ c #724124",
"L+ c #BF8538",
"M+ c #794227",
"N+ c #7B4926",
"O+ c #894F2B",
"P+ c #A26C30",
"Q+ c #8B592A",
"R+ c #7F4529",
"S+ c #824729",
"T+ c #AA7333",
"U+ c #894D2B",
"V+ c #754325",
"W+ c #E9A745",
"X+ c #ECAA45",
"Y+ c #7B4327",
"Z+ c #C58B3A",
"\`+    c #905B2C",
" @ c #DB9B41",
".@ c #AF7635",
"+@ c #84472A",
"@@ c #774026",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"            . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .             ",
"          . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .           ",
"          + @ # \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ # @ +           ",
"          % \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ %           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ & * \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ = - \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ ; > , ' ) ! ~ { { ] ^ ^ ^ ^ ] ] ] ^ ^ ^ / ( _ : < \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ [ } | : : : : : : : : : : : : : : : : : : : | < \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ 1 2 3 4 : : : : : : | | 5 5 6 5 | | : : : : | < \$ \$ \$ 7 \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 7 \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ 8 9 0 a 4 : : : : b c d e f g h i a j k l : | < \$ \$ \$ m n \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ o p \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ q r s t : : : | u s s s s s s s s s v w x y 1 \$ \$ \$ z A B 1 1 1 1 1 C C C C 1 1 1 1 1 D E D \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ F G : : : | H I F J K K K L M N O s P Q 1 \$ \$ \$ z | R S S S S T U U U V S S S S S W X D \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ Y : : : | Z \$ \$ \$ \$ \$ \$ \$ \$ \$ \` I  ...+.\$ \$ \$ @.: : : : : : : : : : : : : : : : : : #.\$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$.: : : : #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ %.&.\$ \$ \$ \$ *.: =.-.;.>.,.'.: : : : ).,.!.;.~.{.: #.\$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ].: : : : #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ < ^.\$ \$ \$ \$ *./.(.s s s s _.: : : : :.s s s s <.[.Z \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ }.: : : : #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ K \$ \$ \$ \$ |.1.9 2.3.4.4.5.: : : x 6.4.4.3.7.8.9.= \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ }.: : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ K 4.q \$ \$ \$ \$ 0.a.: : Q b.\$ \$ \$ \$ c.O < \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ }.: : : : D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ d.\` \$ \$ \$ \$ \$ e.a.: : f.g.\$ \$ \$ \$ \$ J \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ }.: : : : #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ h.: : : x i.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ j.: : : : #.\$ \$ \$ \$ \$ g.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ k.: : : y l.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ m.: : : | Z \$ \$ \$ \$ * n.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ o.: : : | p.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ q.: : : 5 Z \$ \$ \$ \$ r.s.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ' : : : | l.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ t.: : : u.v.\$ \$ w.x.y.z.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ' : : : | l.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ A.: : : u.B.C.D.E.Q : z.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ' : : : | l.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ F.: : : : x a.l : : : G.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ' : : : | H.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ I.| : : : : : : : X : : J.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ K.- : : : : L.M.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ N.V : : : : : : 5 O.P.Q.R.s.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ S.T.: : : : : : U.M.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1 F.: : : : : : V.W.X.Y.0 Z.\`.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1  +l : : : : : : : 0.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ .+++: : : : l c @+9 #+^.s \$+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ #.%+l : : : : : &+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ *+=+-+: : : l ;+%.>+\$ < I ,+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ '+X.)+: : : l !+~+{+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ q 7.]+: : : l ^+\$ \$ \$ \$ < '+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ /+(+_+: : : l :+<+>+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ d.[+: : : l .+\$ \$ \$ \$ \$ >+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ d.!.: : : l }+|+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1+: : : l .+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ] : : : 2+3+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 4+: : : X #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ] : : : 2+5+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ].: : : : #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ] : : : 2+5+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ }.: : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ^ : : : 2+6+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 7+: : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 8+: : : 2+9+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ ] : : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 8+: : : : 9+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 8+: : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : : 9+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ / : : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : : 9+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : X D \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : : 0+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : : #.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ a+: : : : 0+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : | Z \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ b+: : : | 0+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : R.c+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ b+: : : | 0+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ d+: : : f.c+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ b+: : : | p.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ d+: : : e+f+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ a+: : : | 0+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ d+: : : | h.1 g+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : : 9+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ { : : : : : h+\`.i+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 8+: : : : 9+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 8+: : : : : x m \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ j+k+: : : : l+7 \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ m+: : : : | n+o+q \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ p+q+: : : : : u.r+1 \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1 _ : : : : G.s+t+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ u+T l : : : : X v+x.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 7 h.: : : : : w+x+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ y+z+x : : A+B+C+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ D+I.R.: : : : l E+\` \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ F+9 9 G+| Q H+s (.q \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ x.I+V : : : l J+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1 K #+K+=.L+@+M+d.< \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \` 7.N+z+f.: | O+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ M+P+Q+R+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ S+2.s s T+: V U+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ +.^.'+\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1 c.4.V+W+X+; \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ t+d.\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ Y+Z+[.; \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ +.< \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1 \`+ @* \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ M+.@\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ +@@@\$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ M \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$           ",
"          1 \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1           ",
"            1 \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ \$ 1             ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    "};
_EOF_
}
