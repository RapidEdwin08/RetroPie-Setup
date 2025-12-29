#!/usr/bin/env bash

# This file is part of RetroPie-Extra, a supplement to RetroPie.
# For more information, please visit:
#
# https://github.com/RetroPie/RetroPie-Setup
# https://github.com/Exarkuniv/RetroPie-Extra
# https://github.com/FollyMaddy/RetroPie-Share
# https://github.com/RapidEdwin08/RetroPie-Setup
#
# See the LICENSE file distributed with this source and at
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi
 
rp_module_id="borked3ds"
rp_module_desc="3DS Emulator borked3ds"
rp_module_help="ROM Extension: .3ds .3dsx .elf .axf .cci .cxi .app\n\nCopy your 3DS roms to $romdir/3ds"
rp_module_licence="GPL2 https://github.com/Borked3DS/Borked3DS/blob/master/license.txt"
rp_module_section="exp"
rp_module_flags="64bit"
 
function depends_borked3ds() {
    if compareVersions $__gcc_version lt 7; then
        md_ret_errors+=("Sorry, you need an OS with gcc 7.0 or newer to compile borked3ds")
        return 1
    fi

    local depends=(
        build-essential cmake clang clang-format libsdl2-dev libssl-dev libxcb-cursor-dev
        qt6-l10n-tools qt6-tools-dev qt6-tools-dev-tools qt6-base-dev qt6-base-private-dev qt6-multimedia-dev libqt6sql6
        libasound2-dev xorg-dev libx11-dev libxext-dev libpipewire-0.3-dev libsndio-dev libgl-dev
        libswscale-dev libavformat-dev libavcodec-dev libglut3.12 libglut-dev freeglut3-dev
        libvulkan-dev mesa-vulkan-drivers
    )

    # Additional libraries required for running
    depends+=(libinput-dev)

    # seems to work without, depends that are removed (not tested yet on x86_64): libc++-dev ffmpeg libavdevice-dev
    if [[ "$__platform_arch" == 'x86_64' ]]; then
        depends+=(libc++-dev ffmpeg libavdevice-dev)
    fi

    # package(s) that may not be available in bookworm for x86_64
    if [[ ! $(apt-cache search libfdk-aac-dev | grep 'libfdk-aac-dev ') == '' ]]; then
        depends+=(libfdk-aac-dev)
    fi

    # robin-map-dev is in the source and found when using https://github.com/rtiangha/Borked3DS.git
    isPlatform "aarch64" && depends+=(robin-map-dev)

    # use libqt6core6t64 for Trixie or higher
    if compareVersions $__gcc_version lt 14; then
        depends+=(libqt6core6)
    else
        depends+=(libqt6core6t64)
    fi

    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_borked3ds() {
#backup of all forks, replace in if function when needed
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-regression 
#gitPullOrClone "$md_build" https://github.com/borked3ds/Borked3DS.git
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vulkan-validation
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git mobile-gpus
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git gpu-revert
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git opengles-dev
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git opengles-dev
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-revert
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-revert-mem-alloc
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-revert-0
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-revert-1
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-revert-2
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git vk-revert-3
#gitPullOrClone "$md_build" https://github.com/Borked3DS/Borked3DS.git
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git opengles-dev-v2
#gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git fix-gcc12
#gitPullOrClone "$md_build" https://github.com/gvx64/Borked3DS-rpi.git

    if isPlatform "aarch64"; then
        gitPullOrClone "$md_build" https://github.com/gvx64/Borked3DS-rpi.git
    else
        gitPullOrClone "$md_build" https://github.com/rtiangha/Borked3DS.git
    fi

    #do this after cloning Borked3ds, otherwise the $md_build will already exist and cloning will fail
    #Borked3DS requires a cmake 3.5 as minimum, we will use the 4.0.2 binary when using Bookworm or lower
    #find the files on "https://cmake.org/files/v4.0/" (cmake-4.0.2.tar.gz is source only)
    if compareVersions $__gcc_version lt 14; then
        if isPlatform "aarch64"; then
            downloadAndExtract https://cmake.org/files/v4.0/cmake-4.0.2-linux-aarch64.tar.gz "$md_build"
        else
            downloadAndExtract https://cmake.org/files/v4.0/cmake-4.0.2-linux-x86_64.tar.gz "$md_build"
        fi
        mv cmake-4.0.2* cmake-4.0.2
    fi
}
 
function build_borked3ds() {
    local extra_build_options
    isPlatform "aarch64" && extra_build_options="-DDYNARMIC_USE_BUNDLED_EXTERNALS=OFF"
    mkdir build
    cd build
    #Borked3DS requires a cmake 3.5 as minimum, we will use the 4.0.2 binary when using Bookworm or lower
    if compareVersions $__gcc_version lt 14; then
        $md_build/cmake-4.0.2/bin/cmake .. -DCMAKE_BUILD_TYPE=Release $extra_build_options
        $md_build/cmake-4.0.2/bin/cmake --build . -- -j"$(nproc)"
    else
        cmake .. -DCMAKE_BUILD_TYPE=Release $extra_build_options
        cmake --build . -- -j"$(nproc)"
    fi
    md_ret_require="$md_build/build/bin"
}
 
function install_borked3ds() {
    md_ret_files=(
    'build/bin/Release/borked3ds'
    #'build/bin/Release/borked3ds-cli'
    #'build/bin/Release/borked3ds-room'
    #'build/bin/Release/tests'
    )

    # 0ptional gamelist and artwork 3ds
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/borked3ds-rp-assets.tar.gz" "$md_build"
    mkRomDir "3ds/media"; mkRomDir "3ds/media/image"; mkRomDir "3ds/media/marquee"; mkRomDir "3ds/media/video"
    mv 'media/image/BigPEmu.png' "$romdir/3ds/media/image"; mv 'media/marquee/BigPEmu.png' "$romdir/3ds/media/marquee"
    if [[ ! -f "$romdir/3ds/gamelist.xml" ]]; then mv 'gamelist.xml' "$romdir/3ds"; else mv 'gamelist.xml' "$romdir/3ds/gamelist.xml.3ds"; fi
    chown -R $__user:$__user "$romdir/3ds"
}

function remove_borked3ds() {
    rm -f /usr/share/applications/Borked 3DS.desktop
    rm -f "$home/Desktop/Borked 3DS.desktop"
    rm -f "$home/RetroPie/roms/3ds/+Start Borked3DS.gui"
}

function configure_borked3ds() {
    mkdir -p "$home/.config/borked3ds-emu"
    mkdir -p "$md_conf_root/3ds/borked3ds"
    moveConfigDir "$home/.config/borked3ds-emu" "$md_conf_root/3ds/borked3ds"
    chown -R $__user:$__user "$md_conf_root/3ds/borked3ds"

    mkRomDir "3ds"
    ensureSystemretroconfig "3ds"
    local launch_prefix
    local launch_extension
    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    #isPlatform "aarch64" && launch_extension="env MESA_EXTENSION_OVERRIDE=GL_OES_texture_buffer;"
    addEmulator 0 "$md_id-ui" "3ds" "$launch_extension$launch_prefix$md_inst/borked3ds"
    addEmulator 1 "$md_id-roms" "3ds" "$launch_extension$launch_prefix$md_inst/borked3ds %ROM%"
    #addEmulator 1 "$md_id-room" "3ds" "$launch_extension$launch_prefix$md_inst/borked3ds-room"
    #addEmulator 2 "$md_id-cli" "3ds" "$launch_extension$launch_prefix$md_inst/borked3ds-cli"
    #addEmulator 3 "$md_id-tests" "3ds" "$launch_extension$launch_prefix$md_inst/tests"
    addSystem "3ds" "3ds" ".3ds .3dsx .elf .axf .cci .cxi .app .gui"

    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-ui+qjoypad" "3ds" "$launch_prefix$md_inst/borked3ds-qjoy.sh"
    fi

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q '3ds_StartBorked3DS = "borked3ds-ui' ; echo $?) == '1' ]]; then echo '3ds_StartBorked3DS = "borked3ds-ui"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi

    touch "$romdir/3ds/+Start Borked3DS.gui"; chown -R $__user:$__user "$romdir/3ds"
    chown $__user:$__user "$romdir/3ds/+Start Borked3DS.gui"

   cat >"$md_inst/borked3ds-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Borked3DS"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
    Axis 1: gradient, dZone 5768, maxSpeed 3, tCurve 0, mouse+h
    Axis 2: gradient, dZone 4615, maxSpeed 3, tCurve 0, mouse+v
    Axis 3: +key 111, -key 0
    Axis 4: gradient, dZone 5076, maxSpeed 3, tCurve 0, mouse+h
    Axis 5: gradient, dZone 4615, maxSpeed 3, tCurve 0, mouse+v
    Axis 6: +key 116, -key 0
    Axis 7: gradient, maxSpeed 2, tCurve 0, mouse+h
    Axis 8: gradient, maxSpeed 2, tCurve 0, mouse+v
    Button 1: mouse 1
    Button 2: mouse 3
    Button 3: mouse 1
    Button 4: mouse 3
    Button 5: mouse 1
    Button 6: mouse 3
    Button 7: key 9
    Button 8: key 36
    Button 9: key 9
    Button 10: mouse 1
    Button 11: mouse 3
    Button 12: key 113
    Button 13: key 114
    Button 14: key 111
    Button 15: key 116
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run Borked3DS
VC4_DEBUG=always_sync $md_inst/borked3ds

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/borked3ds-qjoy.sh"

    [[ "$md_mode" == "remove" ]] && remove_borked3ds
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && shortcuts_icons_borked3ds
}

function gui_borked3ds() {
    #special charachters ■□▪▫▬▲►▼◄◊○◌●☺☻←↑→↓↔↕⇔
    local csv=()
    csv=(
`□menu_item□□to_do□□□□□help_to_do□`
'□Add/Remove GL_OES_texture_buffer (Mesa Extension Overide)□□patch_es_systems_cfg_borked3ds□□□□□printMsgs dialog "@gvx64:\nI added support for GL_OES_texture_buffer in Borked3ds-rpi. This is a GLES 3.2 extension that the Pi does not completely support, but the code in Borked3ds-rpi does not depend on the problematic portions of this extension and so we can tap into this GLES 3.2 functionality on the Pi by using an environment variable override. to launch within Retropie with GL_OES_texture_buffer support enabled, edit the contents of /etc/emulationstation/es_systems.cfg so that the 3DS entry appears as follows. This will theoretically give better performance than the fall-back code path that uses 2D texture LUTs and it should be more accelerated in games that have fog/lighting effects (that said, I am not noticing much of an improvement on my Pi4, maybe because it is GPU is too weak for it to matter)."□'
# next are a few examples
#'□Enable Gles□□iniConfig "=" "" "/home/$user/.config/borked3ds-emu/qt-config.ini";iniSet "use_gles" "true"□□□□□printMsgs dialog "NO HELP"□'
#'□Disable Gles□□iniConfig "=" "" "/home/$user/.config/borked3ds-emu/qt-config.ini";iniSet "use_gles" "false"□□□□□printMsgs dialog "NO HELP"□'
#'□Overwrite qt-config.ini from pastebin (@DTEAM)□□curl https://pastebin.com/raw/KXEmXpjQ > "/home/$user/.config/borked3ds-emu/qt-config.ini"□□□□□printMsgs dialog "NO HELP"□'
    )
    build_menu_borked3ds
}

function build_menu_borked3ds() {
    local options=()
    local default
    local i
    local run
    IFS="□"
    for i in ${!csv[@]}; do set ${csv[$i]}; options+=("$i" "$2");done
    while true; do
        local cmd=(dialog --colors --no-collapse --help-button --menu "Choose an option" 22 76 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        default="$choice"
        IFS="□"
        if [[ -n "$choice" ]]; then
            joy2keyStop
            joy2keyStart 0x00 0x00 kich1 kdch1 0x20 0x71
            clear
            if [[ $choice == HELP* ]];then
            run="$(set ${csv[${choice/* /}]};echo $9)"
            else
            run="$(set ${csv[$choice]};echo $4)"
            fi
            joy2keyStop
            joy2keyStart
            unset IFS
        eval $run
        joy2keyStart
        else
            break
        fi
    done
    unset IFS
}

function patch_es_systems_cfg_borked3ds() {
local patch_option
local patch_msgs
if [[ $(cat /etc/emulationstation/es_systems.cfg) == *"buffer;"* ]];then
patch_msgs=Remove
patch_option=-R
else
patch_msgs=Add
patch_option=
fi
printMsgs dialog "$patch_msgs :\n'env MESA_EXTENSION_OVERRIDE=GL_OES_texture_buffer'\nin /etc/emulationstation/es_systems.cfg\n\nJust use this option again to reverse !"
patch $patch_option /etc/emulationstation/es_systems.cfg << _EOF_
@@ -1 +1 @@
-    <command>/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ 3ds %ROM%</command>
+    <command>env MESA_EXTENSION_OVERRIDE=GL_OES_texture_buffer;/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ 3ds %ROM%</command>
_EOF_
}

function shortcuts_icons_borked3ds() {
    local shortcut_name
    shortcut_name="Borked 3DS"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/borked3ds
Icon=$md_inst/Borked3DS_72x65.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=3DS;Borked3DS
StartupWMClass=Borked3DS
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/Borked3DS_72x65.xpm" << _EOF_
/* XPM */
static char * Borked3DS_72x65_xpm[] = {
"72 65 973 2",
"   c None",
".  c #BABBBD",
"+  c #A9AAAE",
"@  c #D1D2D3",
"#  c #FDFDFD",
"\$     c #FAFBFC",
"%  c #C8C9CC",
"&  c #BBBCC0",
"*  c #B0B0B5",
"=  c #A4A6A8",
"-  c #CBCCCF",
";  c #E1E1E2",
">  c #E4E4E5",
",  c #E1E1E3",
"'  c #E2E2E3",
")  c #E2E3E4",
"!  c #D9DAD9",
"~  c #969897",
"{  c #8E9191",
"]  c #DEE0E1",
"^  c #FDFEFD",
"/  c #FFFFFD",
"(  c #FEFFFE",
"_  c #FDFEFE",
":  c #E5E6E5",
"<  c #DDDEDF",
"[  c #B8B9BB",
"}  c #C8C9CB",
"|  c #E1E2E2",
"1  c #E0E1E1",
"2  c #E2E2E1",
"3  c #D8D9D8",
"4  c #A1A3A2",
"5  c #9B9DA0",
"6  c #C5C6C9",
"7  c #E1E2E1",
"8  c #D8D8D9",
"9  c #B0B0B1",
"0  c #CACCCE",
"a  c #F9FBFA",
"b  c #FEFEFE",
"c  c #FFFFFF",
"d  c #F4F5F5",
"e  c #B7B8B9",
"f  c #97999D",
"g  c #B9BDBE",
"h  c #F8FCFC",
"i  c #FDFDFB",
"j  c #B2B4B5",
"k  c #2C2E31",
"l  c #4B4B50",
"m  c #D1D2D4",
"n  c #9D9D9F",
"o  c #E7E7E7",
"p  c #D7D8D8",
"q  c #C8CAC9",
"r  c #F4F5F4",
"s  c #CDCED1",
"t  c #B6B5B8",
"u  c #EFF0F1",
"v  c #FDFFFE",
"w  c #FEFEFC",
"x  c #FDFDFC",
"y  c #DFDFE2",
"z  c #8B8A90",
"A  c #CBCDCE",
"B  c #FCFEFD",
"C  c #FEFFFF",
"D  c #CACBCC",
"E  c #17181E",
"F  c #939497",
"G  c #D5D6D7",
"H  c #B1B4B6",
"I  c #F0F1F1",
"J  c #FEFEFD",
"K  c #87888A",
"L  c #0D1115",
"M  c #191D22",
"N  c #A6AAAB",
"O  c #535657",
"P  c #F3F4F5",
"Q  c #5F6063",
"R  c #23242A",
"S  c #E1E2E3",
"T  c #F1F2F2",
"U  c #BABCBE",
"V  c #CBCDCF",
"W  c #F8F9F7",
"X  c #E6E7E7",
"Y  c #C1C3C7",
"Z  c #AAABAF",
"\`     c #AAABAC",
" . c #FBFCFD",
".. c #EAEAEC",
"+. c #9F9FA2",
"@. c #D6D7D9",
"#. c #CBCCCE",
"\$.    c #858689",
"%. c #929494",
"&. c #DDDEDD",
"*. c #D9DADA",
"=. c #777877",
"-. c #9FA0A0",
";. c #F4F5F6",
">. c #F7F8F8",
",. c #FCFDFD",
"'. c #C1C1C4",
"). c #ABABAF",
"!. c #F5F6F6",
"~. c #E1E3E3",
"{. c #A1A1A4",
"]. c #E0E1E2",
"^. c #FEFEFB",
"/. c #C8C9CA",
"(. c #CFD1D2",
"_. c #FBFEFC",
":. c #AFB0B0",
"<. c #FDFFFD",
"[. c #EAEBEB",
"}. c #E7E8E9",
"|. c #E8E8E7",
"1. c #E6E5E7",
"2. c #C7C7CA",
"3. c #F0F2F2",
"4. c #F4F6F6",
"5. c #C3C4C5",
"6. c #E6E7E8",
"7. c #E7E8E8",
"8. c #E6E6E6",
"9. c #E7E7E6",
"0. c #E7E8E7",
"a. c #E7E6E7",
"b. c #E7E7E8",
"c. c #E7E9E9",
"d. c #F9FAFA",
"e. c #FAFBFB",
"f. c #D1D1D3",
"g. c #8B8C8E",
"h. c #BBBCBD",
"i. c #F3F4F2",
"j. c #F0F2F3",
"k. c #CCCCCD",
"l. c #AFB1B1",
"m. c #F1F1F1",
"n. c #FFFFFE",
"o. c #515154",
"p. c #717175",
"q. c #74757A",
"r. c #5E5F63",
"s. c #38393E",
"t. c #ACADAE",
"u. c #F9F9FA",
"v. c #BBBCBF",
"w. c #606367",
"x. c #6E6F73",
"y. c #67686D",
"z. c #68696E",
"A. c #6F7074",
"B. c #6F7073",
"C. c #6E7073",
"D. c #6F7174",
"E. c #6D6E73",
"F. c #626368",
"G. c #CBCBCE",
"H. c #FEFFFD",
"I. c #F3F3F3",
"J. c #BABABB",
"K. c #8B8D8D",
"L. c #CCCFD0",
"M. c #9B9EA2",
"N. c #E8E8E9",
"O. c #AEAFAF",
"P. c #D7D7D9",
"Q. c #7D7E7E",
"R. c #E3E5E4",
"S. c #717276",
"T. c #A6A7AB",
"U. c #D4D4D7",
"V. c #E8E7E7",
"W. c #E5E5E3",
"X. c #A3A4A6",
"Y. c #727677",
"Z. c #BEC0C2",
"\`.    c #C9C8C9",
" + c #C9C8C8",
".+ c #CCCBCA",
"++ c #DBDBDA",
"@+ c #DDDCDB",
"#+ c #D9D8D8",
"\$+    c #CBCACC",
"%+ c #CAC8CC",
"&+ c #DBDDDC",
"*+ c #A1A2A2",
"=+ c #BEC0C0",
"-+ c #FCFCFC",
";+ c #C7C7C8",
">+ c #F2F3F4",
",+ c #C9C9CC",
"'+ c #CBCDD0",
")+ c #BFC1C1",
"!+ c #F6F6F6",
"~+ c #8E8F91",
"{+ c #BFC0C1",
"]+ c #313235",
"^+ c #9FA2A4",
"/+ c #999A9B",
"(+ c #B5B6B7",
"_+ c #C9CCCC",
":+ c #A3A3A5",
"<+ c #A4A4A7",
"[+ c #FEFDFE",
"}+ c #EBEBEC",
"|+ c #AFB1B0",
"1+ c #A7A7AC",
"2+ c #BEBEC1",
"3+ c #9A9B9F",
"4+ c #FBFBFC",
"5+ c #DADDDD",
"6+ c #F5F5F6",
"7+ c #909092",
"8+ c #8B8D91",
"9+ c #C3C5C6",
"0+ c #FBFAFB",
"a+ c #ECEFEE",
"b+ c #C1C2C5",
"c+ c #A6A5AA",
"d+ c #A3A3A7",
"e+ c #A5A4A8",
"f+ c #BDC0C0",
"g+ c #D6D6D9",
"h+ c #98999D",
"i+ c #AEAFB1",
"j+ c #CCCECF",
"k+ c #FEFEFF",
"l+ c #BEC0BF",
"m+ c #969798",
"n+ c #C4C4C6",
"o+ c #CACACC",
"p+ c #F9F9F9",
"q+ c #D0D0D2",
"r+ c #B3B7B9",
"s+ c #F7F8F9",
"t+ c #EDEDEE",
"u+ c #838286",
"v+ c #FCFEFC",
"w+ c #B8B9BC",
"x+ c #F3F4F6",
"y+ c #F5F7F5",
"z+ c #808182",
"A+ c #D7D8DA",
"B+ c #AAAAAE",
"C+ c #AAAAAD",
"D+ c #D3D3D5",
"E+ c #F4F3F5",
"F+ c #B7B7BA",
"G+ c #B4B8B7",
"H+ c #919496",
"I+ c #B8BABC",
"J+ c #BFC1C0",
"K+ c #D2D3D5",
"L+ c #A9A9AC",
"M+ c #D4D5D5",
"N+ c #E2E3E3",
"O+ c #959697",
"P+ c #EAEBEC",
"Q+ c #FCFCFB",
"R+ c #A0A1A2",
"S+ c #F6F6F5",
"T+ c #A9A9AD",
"U+ c #D0D2D3",
"V+ c #A2A5A8",
"W+ c #ABACB0",
"X+ c #BEBFC0",
"Y+ c #FDFDFE",
"Z+ c #EAEBED",
"\`+    c #E0DFE2",
" @ c #F6F8F4",
".@ c #CCCCCC",
"+@ c #F5F5F5",
"@@ c #D6D7D8",
"#@ c #A8AAAA",
"\$@    c #919498",
"%@ c #96989C",
"&@ c #FAFAFA",
"*@ c #CBCBCB",
"=@ c #949598",
"-@ c #F7FBF6",
";@ c #F3F3F4",
">@ c #C8C9C8",
",@ c #F0F0F1",
"'@ c #F7F7F8",
")@ c #F8F9F9",
"!@ c #F2F3F3",
"~@ c #F3F4F4",
"{@ c #EEEFEF",
"]@ c #F5F9F7",
"^@ c #DEDFDF",
"/@ c #B4B5B6",
"(@ c #D2D5D6",
"_@ c #BDBDBF",
":@ c #B0AFB3",
"<@ c #76797E",
"[@ c #C4C5C3",
"}@ c #9D9D9E",
"|@ c #CDCECE",
"1@ c #C9CACB",
"2@ c #FDFEFF",
"3@ c #C0C2C4",
"4@ c #CECED0",
"5@ c #B9BBBD",
"6@ c #BFBFC2",
"7@ c #F7F7F9",
"8@ c #FBFCFB",
"9@ c #F3F5F4",
"0@ c #B7B8BB",
"a@ c #ECEFF0",
"b@ c #F8F8FA",
"c@ c #B3B3B7",
"d@ c #505159",
"e@ c #959799",
"f@ c #E4E5E5",
"g@ c #F8F7F8",
"h@ c #C6C7C9",
"i@ c #F2F4F5",
"j@ c #F8F8F8",
"k@ c #EFEFEF",
"l@ c #A3A4A8",
"m@ c #979899",
"n@ c #AFAFB3",
"o@ c #E8E7E8",
"p@ c #FEFDFD",
"q@ c #DADADA",
"r@ c #ACACB0",
"s@ c #B8BABD",
"t@ c #FFFEFF",
"u@ c #EDEEED",
"v@ c #919392",
"w@ c #89898D",
"x@ c #9E9CA1",
"y@ c #BDBFC0",
"z@ c #FBFBFB",
"A@ c #DBDBDB",
"B@ c #9F9FA4",
"C@ c #9C9C9F",
"D@ c #C8C8C9",
"E@ c #8E8F93",
"F@ c #9A9DA0",
"G@ c #CCCBCF",
"H@ c #D4D5D6",
"I@ c #FFFEFE",
"J@ c #D8DADB",
"K@ c #A3A3A8",
"L@ c #A8A6AB",
"M@ c #9C9EA0",
"N@ c #B9BABB",
"O@ c #DFE0E1",
"P@ c #A7A9A8",
"Q@ c #9D9F9F",
"R@ c #E9EAE9",
"S@ c #F7F7F7",
"T@ c #BCBDBE",
"U@ c #C7C8C8",
"V@ c #FBFDFA",
"W@ c #AAACAD",
"X@ c #E5E7E7",
"Y@ c #BCBDC0",
"Z@ c #F5F7F7",
"\`@    c #E6E6E7",
" # c #C3C3C4",
".# c #D0D3D3",
"+# c #CDCECF",
"@# c #AFAFB2",
"## c #85868A",
"\$#    c #B4B4B8",
"%# c #B9BABA",
"&# c #DDDFDF",
"*# c #FCFEFE",
"=# c #D0D0D1",
"-# c #E9EAEC",
";# c #B6B7B9",
"># c #B4B5B9",
",# c #BABABA",
"'# c #B3B5B6",
")# c #BFC0C2",
"!# c #B7B8BA",
"~# c #E6E7E9",
"{# c #BCBDBF",
"]# c #E7E9EA",
"^# c #C5C5C6",
"/# c #AEAFB2",
"(# c #DEDDE0",
"_# c #BBBFBD",
":# c #BABABD",
"<# c #C0C1C2",
"[# c #D7D7D7",
"}# c #FCFDFA",
"|# c #B2B3B6",
"1# c #97989C",
"2# c #DADADC",
"3# c #EFF0EF",
"4# c #B9BABE",
"5# c #A9ACB1",
"6# c #A1A5A8",
"7# c #565860",
"8# c #A1A8A8",
"9# c #A0A1A7",
"0# c #EAEAEB",
"a# c #DDDDDD",
"b# c #919195",
"c# c #AEAEAE",
"d# c #ADAEAD",
"e# c #8D9093",
"f# c #FAFBFA",
"g# c #B3B4B6",
"h# c #A0A3A7",
"i# c #898B91",
"j# c #E8E9E9",
"k# c #DBDEDD",
"l# c #E1E1E1",
"m# c #EBECEC",
"n# c #A1A2A4",
"o# c #E4E6E6",
"p# c #AAADB2",
"q# c #E1E2E4",
"r# c #B2B3B5",
"s# c #D6D6D8",
"t# c #808386",
"u# c #F1F2F4",
"v# c #C0C0C2",
"w# c #D7D6D8",
"x# c #5F6268",
"y# c #DCDEDF",
"z# c #F3F4F3",
"A# c #9A9C9C",
"B# c #B2B4B6",
"C# c #B0B0B3",
"D# c #494B52",
"E# c #B3B5B7",
"F# c #EEEEEE",
"G# c #A5A3A8",
"H# c #B9BABD",
"I# c #97979B",
"J# c #A5A7AA",
"K# c #CECDD2",
"L# c #969498",
"M# c #9F9FA1",
"N# c #CECED2",
"O# c #D8D8DB",
"P# c #DADBDD",
"Q# c #DBDBDD",
"R# c #D5D5D8",
"S# c #CACACD",
"T# c #DADADD",
"U# c #D6DADC",
"V# c #D9DADC",
"W# c #C8CCCE",
"X# c #D3D4D6",
"Y# c #E2E4E4",
"Z# c #A4A7A8",
"\`#    c #B8BBBE",
" \$    c #D8D9DB",
".\$    c #D7D9D7",
"+\$    c #A4A5A7",
"@\$    c #B6B6B8",
"#\$    c #B0B1B5",
"\$\$   c #6E6D73",
"%\$    c #515157",
"&\$    c #47484E",
"*\$    c #525458",
"=\$    c #535459",
"-\$    c #525358",
";\$    c #515357",
">\$    c #BABBBE",
",\$    c #B2B3B7",
"'\$    c #AAADB0",
")\$    c #B2B4B7",
"!\$    c #C2C2C5",
"~\$    c #5E6064",
"{\$    c #B4B5B7",
"]\$    c #C3C3C5",
"^\$    c #C2C3C6",
"/\$    c #C2C3C5",
"(\$    c #9A9BA0",
"_\$    c #9C9DA0",
":\$    c #C1C4C6",
"<\$    c #B2B3B8",
"[\$    c #B3B4B7",
"}\$    c #AEB0B3",
"|\$    c #A9ABAD",
"1\$    c #BDBEC2",
"2\$    c #C0C1C4",
"3\$    c #DFE0E0",
"4\$    c #E8EAEB",
"5\$    c #EDEEEF",
"6\$    c #7E7F83",
"7\$    c #F1F2F3",
"8\$    c #86878B",
"9\$    c #CCCDCF",
"0\$    c #FDFFFF",
"a\$    c #A2A3A5",
"b\$    c #EBECED",
"c\$    c #83868C",
"d\$    c #FAFAFB",
"e\$    c #EBEBEB",
"f\$    c #75757A",
"g\$    c #919395",
"h\$    c #FCFDFC",
"i\$    c #AEAFB0",
"j\$    c #C5C5C8",
"k\$    c #D6D8DA",
"l\$    c #A5A5A8",
"m\$    c #BEBFC1",
"n\$    c #C1C2C2",
"o\$    c #B7B7B8",
"p\$    c #CACACB",
"q\$    c #C9CBCB",
"r\$    c #C5C7C8",
"s\$    c #B5B5B7",
"t\$    c #C4C5C6",
"u\$    c #A8A9AD",
"v\$    c #C5C6C7",
"w\$    c #C8C9C9",
"x\$    c #B9BBBC",
"y\$    c #F5F7F4",
"z\$    c #8F9093",
"A\$    c #C2C3C4",
"B\$    c #B6B7B8",
"C\$    c #CFD0D1",
"D\$    c #D0D1D2",
"E\$    c #D2D2D3",
"F\$    c #D2D2D2",
"G\$    c #D2D2D1",
"H\$    c #D1D1D2",
"I\$    c #CCD1CE",
"J\$    c #CCD1CD",
"K\$    c #D8D9DA",
"L\$    c #ECEDEA",
"M\$    c #E9EBEA",
"N\$    c #A0A1A1",
"O\$    c #A6A5A7",
"P\$    c #A6A6A5",
"Q\$    c #A6A5A9",
"R\$    c #A5A5A7",
"S\$    c #C4C4C7",
"T\$    c #8A8B8E",
"U\$    c #919297",
"V\$    c #89898E",
"W\$    c #E8EAEA",
"X\$    c #E2E3E5",
"Y\$    c #D3D3D4",
"Z\$    c #E8E8E8",
"\`\$   c #EAEBEA",
" % c #E9EBEB",
".% c #E7E9E8",
"+% c #CED0D2",
"@% c #A7A8AA",
"#% c #88898B",
"\$%    c #D2D4D6",
"%% c #E5E5E6",
"&% c #EEEDEF",
"*% c #848387",
"=% c #A1A2A3",
"-% c #545559",
";% c #404246",
">% c #3F4044",
",% c #4B4C4F",
"'% c #8D8E90",
")% c #DFE1E2",
"!% c #F1F3F2",
"~% c #818285",
"{% c #B8BABB",
"]% c #8C8D8E",
"^% c #9FA0A3",
"/% c #F0F1F2",
"(% c #C6C5C7",
"_% c #F5F4F6",
":% c #DCDDDE",
"<% c #DDDEDE",
"[% c #B6B8B8",
"}% c #D0D1D1",
"|% c #474849",
"1% c #CDCDD0",
"2% c #EDECED",
"3% c #EBEAEC",
"4% c #5A5B5E",
"5% c #46484B",
"6% c #9B9B9E",
"7% c #FDFEFC",
"8% c #BCBCBE",
"9% c #C1C3C5",
"0% c #FBFEF9",
"a% c #898B8C",
"b% c #14161D",
"c% c #15191C",
"d% c #8F9294",
"e% c #D9DADB",
"f% c #EBECEA",
"g% c #858787",
"h% c #CED0CF",
"i% c #5F6061",
"j% c #4A4C4E",
"k% c #EAECED",
"l% c #C4C5C8",
"m% c #1A1A22",
"n% c #99989C",
"o% c #FCFDFE",
"p% c #ABACAF",
"q% c #FBFDFC",
"r% c #63666D",
"s% c #56595F",
"t% c #ABADAE",
"u% c #F4F4F4",
"v% c #EEF0EE",
"w% c #929595",
"x% c #13151A",
"y% c #101318",
"z% c #7F8083",
"A% c #E7E7E9",
"B% c #E6E6E8",
"C% c #F5F6F5",
"D% c #8F9094",
"E% c #28292D",
"F% c #595B5D",
"G% c #B1B2B4",
"H% c #13151C",
"I% c #959497",
"J% c #BEC0C1",
"K% c #F7F8F7",
"L% c #8F9091",
"M% c #4F5259",
"N% c #E3E4E4",
"O% c #DCDCDD",
"P% c #F2F2F3",
"Q% c #6D6F6E",
"R% c #212329",
"S% c #5E5F62",
"T% c #D5D6D5",
"U% c #B9BBBB",
"V% c #EDEDEC",
"W% c #B8B9BA",
"X% c #323338",
"Y% c #2E3036",
"Z% c #9DA0A2",
"\`%    c #FAFDFB",
" & c #B2B2B4",
".& c #45474A",
"+& c #17191F",
"@& c #ECEDED",
"#& c #34343B",
"\$&    c #2F3134",
"%& c #9EA1A3",
"&& c #DADADB",
"*& c #E9EAEA",
"=& c #939698",
"-& c #DDDDE1",
";& c #242428",
">& c #0C1019",
",& c #0E1218",
"'& c #B3B3B6",
")& c #FBFEFD",
"!& c #8E8E91",
"~& c #0E1017",
"{& c #0D1019",
"]& c #424347",
"^& c #F8F8F9",
"/& c #D7D6D9",
"(& c #D0D0D3",
"_& c #BBBCBC",
":& c #2D2E34",
"<& c #10131A",
"[& c #2D3035",
"}& c #393C3F",
"|& c #2F3235",
"1& c #13161C",
"2& c #424349",
"3& c #C5C6C8",
"4& c #FBFDFD",
"5& c #86888A",
"6& c #D5D6D6",
"7& c #848589",
"8& c #989A9E",
"9& c #BBBEC0",
"0& c #BCBABE",
"a& c #ACABAB",
"b& c #5C5C60",
"c& c #8B8D8E",
"d& c #EAE7EB",
"e& c #6E7071",
"f& c #9C9C9D",
"g& c #D4D4D4",
"h& c #808281",
"i& c #696B6E",
"j& c #BCBBBE",
"k& c #F3F3F5",
"l& c #F1F1F3",
"m& c #96989B",
"n& c #646669",
"o& c #606264",
"p& c #77787B",
"q& c #AFB1B2",
"r& c #7B7D7F",
"s& c #EFEFF0",
"t& c #AFAFB1",
"u& c #EFF0F0",
"v& c #FBFBF9",
"w& c #CFD0D2",
"x& c #ADADB0",
"y& c #F1F1F2",
"z& c #424345",
"A& c #0E1115",
"B& c #121319",
"C& c #9FA1A1",
"D& c #F8F9FA",
"E& c #AAABAE",
"F& c #FAF9F9",
"G& c #ECECEC",
"H& c #838486",
"I& c #C4C5C5",
"J& c #ECEBEC",
"K& c #93969A",
"L& c #F6F7F8",
"M& c #7F8284",
"N& c #1D2024",
"O& c #29292F",
"P& c #B6B9B8",
"Q& c #D1D2D2",
"R& c #98999A",
"S& c #CFD1D3",
"T& c #ECEEEE",
"U& c #8A8D8F",
"V& c #838688",
"W& c #88888A",
"X& c #E4E4E6",
"Y& c #FCFFFE",
"Z& c #949697",
"\`&    c #C6C6C8",
" * c #98989B",
".* c #EBECEE",
"+* c #CDCDCE",
"@* c #B8BABA",
"#* c #F5F7F6",
"\$*    c #DBDBDC",
"%* c #F2F3F2",
"&* c #EDF0F0",
"** c #D0D1D3",
"=* c #1D1F25",
"-* c #0D1016",
";* c #3D3C42",
">* c #E8E6EA",
",* c #FCFFFF",
"'* c #D5D4D6",
")* c #A7A9A9",
"!* c #BEBDC2",
"~* c #96969B",
"{* c #9C9BA0",
"]* c #DCDEDD",
"^* c #ACAEB1",
"/* c #ACAEB0",
"(* c #FBFCFC",
"_* c #C0C0C0",
":* c #A6A7A9",
"<* c #7D7E81",
"[* c #0E1119",
"}* c #0D1018",
"|* c #36353B",
"1* c #A1A0A4",
"2* c #A4A8A9",
"3* c #B8B8BB",
"4* c #C1C3C3",
"5* c #84878B",
"6* c #9E9EA2",
"7* c #EFF1F1",
"8* c #FEFFFC",
"9* c #CBCCCC",
"0* c #4E4F52",
"a* c #0D1017",
"b* c #6B6C6F",
"c* c #A0A0A2",
"d* c #F8FAF9",
"e* c #686B71",
"f* c #96999B",
"g* c #ADADAF",
"h* c #EEF0EF",
"i* c #E5E7E5",
"j* c #3D3D40",
"k* c #333439",
"l* c #2D3034",
"m* c #101319",
"n* c #282A30",
"o* c #33353A",
"p* c #323539",
"q* c #9A9B9B",
"r* c #FCFDFB",
"s* c #8D8D8F",
"t* c #F0F2F1",
"u* c #DFE0E2",
"v* c #939293",
"w* c #A8ACAF",
"x* c #9B9BA0",
"y* c #E5E6E6",
"z* c #222328",
"A* c #0D1015",
"B* c #15161B",
"C* c #E4E5E7",
"D* c #E4E5E6",
"E* c #7C7D81",
"F* c #EAECEB",
"G* c #929495",
"H* c #969799",
"I* c #96979A",
"J* c #949597",
"K* c #8E8F92",
"L* c #7F7F81",
"M* c #979798",
"N* c #929396",
"O* c #757578",
"P* c #F8F8F7",
"Q* c #CDCED0",
"R* c #98999C",
"S* c #C1C2C3",
"T* c #C3C4C6",
"U* c #111319",
"V* c #0E1117",
"W* c #2C2B31",
"X* c #DCDDDC",
"Y* c #7F7F84",
"Z* c #ECECEB",
"\`*    c #E3E2E1",
" = c #FBFBFA",
".= c #D2D3D6",
"+= c #A5A6A9",
"@= c #68696D",
"#= c #EAEBE9",
"\$=    c #515254",
"%= c #2F3035",
"&= c #E2E2E6",
"*= c #ADAEB0",
"== c #A4A4A6",
"-= c #B5B8B9",
";= c #D9D9DC",
">= c #C1C1C3",
",= c #909193",
"'= c #4A4B4B",
")= c #313233",
"!= c #9C9D9F",
"~= c #CECFD1",
"{= c #767777",
"]= c #ECEDEC",
"^= c #939595",
"/= c #222427",
"(= c #6D6F72",
"_= c #F0F1F3",
":= c #ECECED",
"<= c #F5F5F4",
"[= c #CBCDCD",
"}= c #ADAFAF",
"|= c #A3A4A5",
"1= c #000000",
"2= c #464748",
"3= c #DBDADC",
"4= c #ACADAF",
"5= c #FCFCFD",
"6= c #8F8F91",
"7= c #999B9E",
"8= c #F6F7F7",
"9= c #B0B1B2",
"0= c #E5E6E8",
"a= c #818384",
"b= c #6D6E6F",
"c= c #CECED1",
"d= c #B1B2B5",
"e= c #CFD0D0",
"f= c #C0C0C1",
"g= c #9FA0A4",
"h= c #C7C8CA",
"i= c #EEEEEF",
"j= c #EAEAEA",
"k= c #EDEEEE",
"l= c #C3C4C4",
"m= c #9B9CA0",
"n= c #EDEFEF",
"o= c #B3B3B5",
"p= c #BBBBBC",
"q= c #F6F8F6",
"r= c #F1F2F1",
"s= c #AAABAD",
"t= c #A4A6A6",
"u= c #AFB1B4",
"v= c #999B9C",
"w= c #AEB0B0",
"x= c #ACADAD",
"y= c #ABADAD",
"z= c #54575D",
"A= c #878A8E",
"B= c #939799",
"C= c #949498",
"D= c #898D90",
"E= c #8B8E91",
"F= c #ABAFB0",
"G= c #A5A9AB",
"H= c #A6A9AB",
"I= c #A8A8AB",
"J= c #AFAEB1",
"K= c #BEBDBF",
"L= c #BBB9BC",
"M= c #919398",
"N= c #B8B9BD",
"O= c #BEBCC0",
"P= c #9A9EA0",
"Q= c #DDDEE0",
"R= c #F6F6F8",
"S= c #74747A",
"T= c #BDBCBE",
"U= c #BEBDC0",
"V= c #BFBDC1",
"W= c #BFBDC0",
"X= c #BEBCBF",
"Y= c #8A8D93",
"Z= c #AAAEB4",
"\`=    c #B7B9BD",
" - c #BBBABD",
".- c #ACAAAD",
"+- c #AAA9AC",
"@- c #B7B5BA",
"#- c #BEBCC1",
"\$-    c #BEBDC1",
"%- c #BEBEC0",
"&- c #BDBEC0",
"*- c #ABABAE",
"=- c #A2A2A6",
"-- c #4F5257",
";- c #A9AAAC",
">- c #ABACAE",
",- c #ACACAE",
"'- c #ACACAF",
")- c #A8A8AA",
"!- c #A0A1A3",
"~- c #929297",
"{- c #A1A2A6",
"]- c #A0A1A5",
"^- c #9F9FA3",
"/- c #717277",
"(- c #797B7D",
"_- c #DEDFE0",
":- c #F9F8FA",
"<- c #B5B4B6",
"[- c #4F5052",
"}- c #86888B",
"|- c #A1A1A6",
"1- c #A1A1A5",
"2- c #999A9D",
"3- c #5B5C61",
"4- c #95999C",
"5- c #ACACB1",
"6- c #A3A2A7",
"7- c #ABABB0",
"8- c #ACABB0",
"9- c #A1A0A5",
"0- c #A5A6A7",
"a- c #9CA0A2",
"b- c #5A5D64",
"c- c #AFB0B4",
"d- c #AFAEB2",
"e- c #B2B2B5",
"f- c #B0B1B3",
"g- c #6C6D71",
"h- c #AEAFB3",
"i- c #ACADB1",
"j- c #787B7E",
"k- c #AFAEB3",
"l- c #AEAEB2",
"m- c #9E9FA2",
"n- c #AEAEB3",
"                                                            . +                                                                                 ",
"                                                          @ # \$ %                                           & *                                 ",
"                    = - ; > , ' ' ; ) ! ~             { ] ^ / ( _ : < [ } | 1 2 ' ' ' ' ' ' ' ' ' | 1 3 4     5 6 1 7 | 8 9                     ",
"                  0 a b c c c c c c c d e f           g h ( / c c i j k l m n o c c c c c c c c c b p q r s       t u v w x y z                 ",
"                A B C b c c c c c c c D E F G           H I J c c # K L M N O p c c c c c c c c c P Q R S _ T U       V W / / X             Y Z ",
"              \`  .C c c c c c c c C _ ..+.@.#.\$.F         %.&._ C v *.=.-.;.>.,.C C C C C C C C C  .'.).!.( C _ ~.=     {.].# ^./.        (._.:.",
"              *.<.( c c c c c # [.}.}.|.1.2.  3.4..           5.6.}.7.8.9.|.7.}.}.}.}.}.}.}.}.}.}.0.a.b.6.}.}.c.d.e.f.g.    h.i.j.      k._ ( l.",
"              m.n.c c c c c b ; o.p.q.r.s.t.T J u.v.              w.x.y.z.x.A.B.B.B.B.B.B.B.B.B.B.C.x.D.x.E.x.F.G.( H.I.J.    K.L.M.    N.( ^ O.",
"              >.c c c c c c n.P.Q.R.(.S.T.U.V.W.X.                Y.Z.\`. +.+++@+@+@+@+@+@+@+@+@+@+@+@+#+\$+%+&+*+=+C C c -+;+            >+ .,+  ",
"    '+)+      !+c c c c c c ( P.~+{+]+^+/+            (+_+                                                  :+<+=+C C c c [+}+|+      1+>.2+    ",
"  3+4+_ 5+    6+c c c c c c ( @.7+} 8+              9+0+a+b+c+                                              d+e+f+C C c c c c -+g+    h+i+      ",
"  j+k+C l+    6+c c c c c c ( @.m+n+              o+p+q+r+s+t+u+                                            d+e+f+C C c c c c b v+w+            ",
"  x+C y+z+    6+c c c c c c ( A+B+C+            D+E+F+    G+H+                                              d+e+f+C C c c c c c _ I+            ",
"J+^ H.K+      6+c c c c c c ( A+  L+          M+N+O+                                                        d+e+f+C C c c c c c _ I+            ",
"P+b Q+R+      S+n.c c b c c ( @.  T+        U+}                                                             V+W+X+C C b b b c c Y+I+            ",
"H Z+\`+         @/ c -+.@+@c ( @@  T+      /.#@                                                              \$@%@X+C C &@*@&@c c Y+I+      =@    ",
"              -@( -+;@>@,@'@_ @@  L+    =                                                                       {+C )@!@;+T p+c # I+    L+~@{@t.",
"              ]@v ^@/@,.(@_@^ @@  :@  <@                                                    [@}@                {+v |@1@2@3@4@c x 5@  6@p+c C ;.",
"              7@v 8@9@0@a@b@_ @.  c@d@                                                  e@f@J g@h@              {+C d.>+[ i@\$ c x 5@  . j@b k@l@",
"    m@        n@o@p@# q@j@c ( @.  r@                                                  s@6+c t@b u@v@        w@x@y@C C z@A@-+c C r B@    C@D@E@  ",
"        F@B+      G@&@b c c ( @@  T+                                                H@,.I@b -+J@            K@L@y@C C c c c c [.M@              ",
"        N@4+O@P@    X c c c ( @@  T+                                            Q@R@b b b S@T@              d+e+f+C C n.c C C U@                ",
"        J.# b V@W@  X@( c c ( @@  T+                                          Y@Z@C b b \`@C@                d+e+f+C C x  #.#+#@###\$#            ",
"        J.b b H.%#  I C c c ( @@  T+                                          &#*#C -+=#                    d+e+f+C C J ' -#;#{.##>#            ",
"        ,#b b ( '#)#_ C c c ( @@  T+                                            !#~#i+            {#]#;#    d+e+f+C C c c b p+^###>#      /#    ",
"  (#_#  :#b b ( '#<#v C c c ( @@  T+                                                            [#}#>+|#    d+e+f+C C c c c # ;+S.1#    |+:.    ",
"  2#3#  4#Y+c ( '#<#v C c c ( @@  T+                              5#6#7#                  8#  9#0#a#b#      d+e+f+C C c c # c#d#        e#      ",
"  q+f#    1 ,.( g#<#v C c c ( @@  T+                            h#i#                  +.j#k#                d+e+f+C C c c b l#m#H@              ",
"  n#o#      p#q#r#<#v C c c ( s#  T+                          t#                    <#u#v#                  d+e+f+C C c c c b c v+4#            ",
"                  )#v C c c n.w#  L+                        x#                    y#z#A#                    d+e+f+C C c c c c c x 5@  c@B#      ",
"                  )+_ C c c n.s#  C#                      D#                      E#F#D                     d+G#X+( ( c c c c c x H#  I#J#      ",
"              K#L#M#I ,@,@,@,@N#  < 2.O#P#Q#Q#Q#Q#Q#Q#g+R#S#A+T#Q#Q#Q#T#U#P#P#V#W#    X#Y#Z#        \`#P#P# \$.\$+\$@\$,@,@,@,@,@,@,@u #\$            ",
"              \$\$%\$&\$*\$*\$                                                                                                =\$-\$*\$;\$                ",
"              >\$,\$'\$)\$!\$~\${\$]\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$^\$/\$b+(\$        _\$b+^\$^\$^\$^\$^\$:\$^\$!\$z.<\$[\$}\$|\$1\$              ",
"            2\$;.3\$4\$5\$}.6\$b@( ( C C C C C C C C C C C C C C C C C C C C C C C C C C C 7\$8\$      9\$d.( C C C C C 0\$C b a\$- 5\$b\$Y#b\$-             ",
"      c\$    {\$d\$,.,.^ e\$f\$'@( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( ( J _ I ;#  g\$O@# ( ( ( ( ( ( ( ( h\$i\$} ^ J H.,.j\$    s k\$    ",
"              l\$m\$n+n\$o\$  @\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$p\$1@1@1@1@q\$r\$E@    s\$p\$p\$p\$p\$p\$p\$1@1@t\$  u\$v\$p\$w\$x\$      ~@y\$z\$  ",
"                                                                                                                                        g#A\$    ",
"                                          B\$C\$D\$E\$F\$F\$F\$F\$F\$F\$F\$F\$F\$F\$F\$F\$F\$F\$F\$G\$H\$C\$I\$J\$K\$1#                                                  ",
"                                          L\$M\$N\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$O\$P\$O\$Q\$R\$O\$Q@        S\$T\$                                        ",
"  U\$V\$      ,+[.[.[.W\$X\$Y\$H\$l#Z\$\`\$ % %.%B.i.+%                                                    @%B #%\$%[.[.[.[. %\`\$[.[.[.[.[.0#%%            ",
"  Z+&%*%    !+b # %%=%-%;%>%,%'%)%_ v !%~%W {%                                                    ]%h\$^%y#C c b _ /%b+(%_%b c c c c /@          ",
":%b <%    [%h\$^ }%|%B.1%2%3%/.4%5%< _ 3\$6%7%h.                                                      8@8%9%C c n.0%a%b%c%d%b n.n.c c e%          ",
"f%f%g%    h%C !%i%j%k%b b b ^ l%m%n%o%@ p%q%[%                                          r%s%        !%H\$t%Y+u%) v%w%x%y%z%\$ A%B%\$ ( C%          ",
"  D%      !%C ) E%F%P / c c x G%H%I%,.J%'.K%L%                                        M%            N%O%a\$P%Q%R%S%T%)#U%V%W%X%Y%Z%\`%7%O.        ",
"         &# c m#.&+&I#3\$@&~.t.#&\$&@@7%%&&&u%                                                        g+*&=&-&;&>&,&'&)&)&^ !&~&{&]&^&k+/&        ",
"        (&c b # _&:&<&[&}&|&1&2&3&4&J 5&}.k@                                                6&d D 7&8&9&  0&a&b&c&d&Y@e&f&g&h&i&j&p@c k&        ",
"        l&c c c -+ \$m&n&o&p&q&~#_ c &@r&s&q@                                            t&u&^.v&w&        x&&@!+z@y&z&A&B&C&D&'@b c c Y+L+      ",
"      E&b c c c c b ,.d.F&&@^ v ( c G&H&D&I&                                          X#-+b J&\`         K&L&b c c d\$M&N&O&P&^ c c c c b Q&      ",
"R&    S&b c c c C T&U&V&W&X&Y&<.n.c ' Z&_ \`&                                     *c@.*x &@+*              @*#*C c c P 6&\$*f#( c c c c c %*      ",
"      &*b c c C 2@**=*-*;*>*,*k+k+c '*)*# !*                                  ~*{*  [\$]*@%                  ^*x / c c c c c c c c c c c v+/*    ",
"    *+w J (*_*:*:*<*[*}*|*1*2*|#u.c 3*4*8@b#                                5*                            6*7*( c c c c c c c c c c c c 8*9*    ",
"    k.c c z#0*~&}*}*a*a*a*a*a*b*j@b c**.d*                                e*                            f*g*c c c c c c c c c c c c c c c h*    ",
"    5\$c c i*j*k*l*m*a*a*n*o*p*q*r*Y+s*N%t*                                                            G u*v*-+c c c c c c c c c c c c c c f#w*  ",
"  x*Y+c c p+y*f@^\$z*A*B*;#C*D*T J d E*t*F*G*H*I*I*I*I*I*I*I*I*I*I*J*K*L*M*m+I*I*I*I*I*I*H*N*            6 O*P*Q*R*;+4+o%Y+4&o%c c c c c c b S*  ",
"  h@c c c c c ( T*U*V*W*X*( c c ( P+Y**#C _ _ _ _ _ _ _ _ _ _ _ _ _ ^ Z*\`* =^ b _ _ _ _ _  ..=          +=@=#=\$=}*%=&=*===-=[ 6+c c c c c c 8.  ",
"  ;=I@c c c c ( ].T@T@>=K%( c c ( ].,=( C C C C C C C C C C C C C ( D\$'=)=!=4+c C C C C C b ^ ~=      g*z#{=]=^=/=(=_=b\$0#b\$:=# c c c c c c <=  ",
"  1%b c c c c c c c c b b c c c n.[=}=b c c c c c c c c c c c c c J |=1=1=2=#*C c c c c c Y+3=      4=^&5=6=| )@W\$;.k+c c c c c c c c c c c {@  ",
"  7=8=c c c c c c c c c c c c c H.9=1@b c c c c n.c c c c c c c c / 0=a=b=;+B C c c c n.,.c=      d=^&I@k+g*e=( 0\$C c C c n.c c c c c c c # f=  ",
"    g=\`@h\$C C ( ( ( C C C C ,*_ z#b#h={@i=k@k@!.!+I.{@{@{@{@{@{@{@{@F#m#j=F#F#k@{@F#{@k=l=      m=}+k@{@n=o=p=Y+D&)%q%u X@7%O@q=( ( ( v r='.    ",
"    M%  s=|=a\$t=                                                                                              u=#\$A.y@v=]%l=  w=W%x=y=)*  z=    ",
"      A=B=                                        C=                                                                                    D=      ",
"        E=F=F=G=H=I=J=K=K=L=K     M=N=O=O=Y@P=  Q=R=C+S=F+T=U=V=V=V=V=V=V=V=W=W=U=X=X.      Y=Z=\`= -.-+-@-#-\$-V=V=W=W=W=W=W=W=%-&-r#*-=-        ",
"        --1#;->-,-'-)-!-~-      {-'-==]-^-/-(-_-b b :-<-[-}-R+|-|-|-|-|-|-1-=%c*2-3-      4-+ 5-6-1-7-8-9-|-|-|-|-|-|-|-|-|-|-{.!-0-a-b-        ",
"            c-C#d-e-f-G%1#    g-*-@#@#h-i-j-D*b c c c z@v\$~%f-k-k-k-k-k-k-l-i+/#m-        h#n-k-k-k-k-k-k-k-k-k-k-k-k-k-k-k-k-/#d=;#            "};
_EOF_
}
