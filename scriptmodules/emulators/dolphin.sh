#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="dolphin"
rp_module_desc="Gamecube/Wii emulator Dolphin"
rp_module_help="ROM Extensions: .gcm .iso .wbfs .ciso .gcz .rvz .wad .wbfs\n\nCopy your Gamecube roms to $romdir/gc and Wii roms to $romdir/wii"
rp_module_licence="GPL2 https://raw.githubusercontent.com/dolphin-emu/dolphin/master/COPYING"
rp_module_repo="git https://github.com/dolphin-emu/dolphin.git master :_get_commit_dolphin"
rp_module_section="exp"
rp_module_flags="!all 64bit !:\$__gcc_version:-lt:8"

function _get_commit_dolphin() {
    local commit
    local has_qt6=$(apt-cache -qq madison qt6-base-private-dev | cut -d'|' -f1)
    # current HEAD of dolphin doesn't build without a C++20 capable compiler ..
    [[ "$__gcc_version" -lt 10 ]] && commit="f59f1a2a"
    # .. and without QT6
    [[ -z "$has_qt6" ]] && commit="b9a7f577"
    # support gcc 8.4.0 for Ubuntu 18.04
    [[ "$__gcc_version" -lt 9  ]] && commit="1c0ca09e"
    echo "$commit"
}

function depends_dolphin() {
    local depends=(cmake gettext pkg-config libao-dev libasound2-dev libavcodec-dev libavformat-dev libbluetooth-dev libenet-dev liblzo2-dev libminiupnpc-dev libopenal-dev libpulse-dev libreadline-dev libsfml-dev libsoil-dev libsoundtouch-dev libswscale-dev libusb-1.0-0-dev libxext-dev libxi-dev libxrandr-dev portaudio19-dev zlib1g-dev libudev-dev libevdev-dev libcurl4-openssl-dev libegl1-mesa-dev liblzma-dev)
    # check if qt6 is available, otherwise use qt5
    local has_qt6=$(apt-cache -qq madison qt6-base-private-dev | cut -d'|' -f1)
    if [[ -n "$has_qt6" ]]; then
        depends+=(qt6-base-private-dev)
        # Older Ubuntu versions provide libqt6svg6-dev instead of Debian's qt6-svg-dev
        if [[ -n "$__os_ubuntu_ver" ]] && compareVersions "$__os_ubuntu_ver" lt 23.04; then
            depends+=(libqt6svg6-dev)
        else
            depends+=(qt6-svg-dev)
        fi
    else
        depends+=(qtbase5-private-dev)
    fi
    # on KMS use x11 to start the emulator
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)

    # if using the latest version, add SDL2 as dependency, since it's mandatory
    [[ "$(_get_commit_dolphin)" == "" ]] && depends+=(libsdl2-dev)

    # Trixie
    if [[ ! "$__os_debian_ver" -ge 13 ]]; then depends+=(libmbedtls-dev); fi
    if [[ ! $(dpkg --list | grep libmbedx509-7) == '' ]]; then echo IF BUILD ERROR ON TRIXIE OR NEWER TRY: apt remove libmbedtls-dev libmbedtls21 libmbedx509-7; fi

    getDepends "${depends[@]}"
}

function sources_dolphin() {
    gitPullOrClone
}

function build_dolphin() {
    mkdir build
    cd build
    # use the bundled 'speexdsp' libs, distro versions before 1.2.1 trigger a 'cmake' error
    cmake .. -DBUNDLE_SPEEX=ON -DENABLE_AUTOUPDATE=OFF -DENABLE_ANALYTICS=OFF  -DUSE_DISCORD_PRESENCE=OFF -DCMAKE_INSTALL_PREFIX="$md_inst"
    make clean
    make
    md_ret_require="$md_build/build/Binaries/dolphin-emu"
}

function install_dolphin() {
    cd build
    make install
    cd ..
    mv "$md_build/Data/Dolphin.icns" $md_inst
    mv "$md_build/Data/dolphin-emu.svg" $md_inst
}
 
function remove_dolphin() {
    rm -f /usr/share/applications/Dolphin.desktop
    rm -f "$home/Desktop/Dolphin.desktop"
    rm -f "$home/RetroPie/roms/gc/+Start Dolphin.m3u"
    rm -f "$home/RetroPie/roms/wii/+Start Dolphin.wad"
}
 
function configure_dolphin() {
    mkRomDir "gc"
    mkRomDir "wii"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addEmulator 1 "$md_id" "gc" "$launch_prefix$md_inst/bin/dolphin-emu -b -e %ROM%"
    ##addEmulator 0 "$md_id-nogui" "gc" "$launch_prefix$md_inst/bin/dolphin-emu-nogui -e %ROM%"
    addEmulator 1 "$md_id" "wii" "$launch_prefix$md_inst/bin/dolphin-emu -b -e %ROM%"
    ##addEmulator 0 "$md_id-nogui" "wii" "$launch_prefix$md_inst/bin/dolphin-emu-nogui -e %ROM%"

    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addEmulator 0 "$md_id-editor" "gc" "$launch_prefix$md_inst/bin/dolphin-emu"
    addEmulator 0 "$md_id-editor" "wii" "$launch_prefix$md_inst/bin/dolphin-emu"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-editor+qjoypad" "gc" "$launch_prefix$md_inst/dolphin-qjoy.sh"
        addEmulator 0 "$md_id-editor+qjoypad" "wii" "$launch_prefix$md_inst/dolphin-qjoy.sh"
    fi

    addSystem "gc"
    addSystem "wii"
 
    [[ "$md_mode" == "remove" ]] && return

    # Move the other dolphin-emu options, memory card saves etc
    moveConfigDir "$home/.local/share/dolphin-emu" "$md_conf_root/gc/local"
    mkUserDir "$md_conf_root/gc/local"

    moveConfigDir "$home/.config/dolphin-emu" "$md_conf_root/gc/Config"
    mkUserDir "$md_conf_root/gc/Config"
 
    cat >"$romdir/gc/+Start Dolphin.m3u" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "gc" ""
_EOF_
    chown $__user:$__user "$romdir/gc/+Start Dolphin.m3u"

    cat >"$romdir/wii/+Start Dolphin.wad" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "wii" ""
_EOF_
   chown $__user:$__user "$romdir/wii/+Start Dolphin.wad"

   if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
   if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'gc_StartDolphin = "dolphin-editor"' ; echo $?) == '1' ]]; then echo 'gc_StartDolphin = "dolphin-editor"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi
   if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'wii_StartDolphin = "dolphin-editor"' ; echo $?) == '1' ]]; then echo 'wii_StartDolphin = "dolphin-editor"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi

   # preset a few options on a first installation
   #if [[ ! -f "$md_conf_root/gc/Config/Dolphin.ini" ]]; then cat >"$md_conf_root/gc/Config/Dolphin.ini" <<_EOF_; fi
   if [[ ! -f "$md_conf_root/gc/Config/Dolphin.ini" ]]; then
        cat >"$md_conf_root/gc/Config/Dolphin.ini" <<_EOF_
[Display]
FullscreenDisplayRes = Auto
Fullscreen = True
RenderToMain = True
KeepWindowOnTop = True
[Interface]
ConfirmStop = False
[General]
ISOPath0 = "$home/RetroPie/roms/gc"
ISOPath1 = "$home/RetroPie/roms/wii"
ISOPaths = 2
[Core]
AutoDiscChange = True
CPUThread = True
_EOF_
        if isPlatform "vulkan"; then echo 'GFXBackend = Vulkan' >> $md_conf_root/gc/Config/Dolphin.ini; fi # [Core]
        if [[ ! "$(dpkg --list | grep -i pulseaudio)" == '' ]]; then cat >>"$md_conf_root/gc/Config/Dolphin.ini" <<_EOF_; fi
[DSP]
Backend = Pulse
DSPThread = True
_EOF_
   fi
   if [ ! -f $md_conf_root/gc/Config/GFX.ini ]; then cat >"$md_conf_root/gc/Config/GFX.ini" <<_EOF_; if isPlatform "gles3"; then echo 'PreferGLES = True' >> $md_conf_root/gc/Config/GFX.ini; fi; fi
[Settings]
AspectRatio = 3
_EOF_

   if [ ! -f $md_conf_root/gc/Config/GCPadNew.ini ]; then cat >"$md_conf_root/gc/Config/GCPadNew.ini" <<_EOF_; fi
[GCPad1]
Device = SDL/0/X360 Wireless Controller
Buttons/A = \`Button S\`
Buttons/B = \`Button W\`
Buttons/X = \`Button E\`
Buttons/Y = \`Button N\`
Buttons/Z = \`Shoulder R\`
Buttons/Start = Start
Main Stick/Up = \`Left Y+\`
Main Stick/Down = \`Left Y-\`
Main Stick/Left = \`Left X-\`
Main Stick/Right = \`Left X+\`
Main Stick/Modifier = \`Thumb L\`
Main Stick/Calibration = 100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42
C-Stick/Up = \`Right Y+\`
C-Stick/Down = \`Right Y-\`
C-Stick/Left = \`Right X-\`
C-Stick/Right = \`Right X+\`
C-Stick/Modifier = \`Thumb R\`
C-Stick/Calibration = 100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42
Triggers/L = \`Shoulder L\`
Triggers/R = \`Trigger R\`
D-Pad/Up = \`Button 13\`&\`Pad N\`
D-Pad/Down = \`Button 14\`&\`Pad S\`
D-Pad/Left = \`Button 11\`&\`Pad W\`
D-Pad/Right = \`Button 12\`&\`Pad E\`
Triggers/L-Analog = \`Trigger L\`
Triggers/R-Analog = \`Trigger R\`
[GCPad2]
Device = XInput2/0/Virtual core pointer
[GCPad3]
Device = XInput2/0/Virtual core pointer
[GCPad4]
Device = XInput2/0/Virtual core pointer
_EOF_

   if [ ! -f $md_conf_root/gc/Config/WiimoteNew.ini ]; then cat >"$md_conf_root/gc/Config/WiimoteNew.ini" <<_EOF_; fi
[Wiimote1]
Device = evdev/0/Xbox 360 Wireless Receiver (XBOX)
Buttons/A = SOUTH
Buttons/B = EAST
Buttons/1 = NORTH
Buttons/2 = WEST
Buttons/- = TL
Buttons/+ = TR
Buttons/Home = MODE
D-Pad/Up = \`Axis 7-\`&\`TRIGGER_HAPPY3\`
D-Pad/Down = \`Axis 7+\`&\`TRIGGER_HAPPY4\`
D-Pad/Left = \`Axis 6-\`&\`TRIGGER_HAPPY1\`
D-Pad/Right = \`Axis 6+\`&\`TRIGGER_HAPPY2\`
IR/Up = \`Cursor Y-\`
IR/Down = \`Cursor Y+\`
IR/Left = \`Cursor X-\`
IR/Right = \`Cursor X+\`
Shake/X = \`Click 2\`
Shake/Y = \`Click 2\`
Shake/Z = \`Click 2\`
IRPassthrough/Object 1 X = \`IR Object 1 X\`
IRPassthrough/Object 1 Y = \`IR Object 1 Y\`
IRPassthrough/Object 1 Size = \`IR Object 1 Size\`
IRPassthrough/Object 2 X = \`IR Object 2 X\`
IRPassthrough/Object 2 Y = \`IR Object 2 Y\`
IRPassthrough/Object 2 Size = \`IR Object 2 Size\`
IRPassthrough/Object 3 X = \`IR Object 3 X\`
IRPassthrough/Object 3 Y = \`IR Object 3 Y\`
IRPassthrough/Object 3 Size = \`IR Object 3 Size\`
IRPassthrough/Object 4 X = \`IR Object 4 X\`
IRPassthrough/Object 4 Y = \`IR Object 4 Y\`
IRPassthrough/Object 4 Size = \`IR Object 4 Size\`
IMUAccelerometer/Up = \`Accel Up\`
IMUAccelerometer/Down = \`Accel Down\`
IMUAccelerometer/Left = \`Accel Left\`
IMUAccelerometer/Right = \`Accel Right\`
IMUAccelerometer/Forward = \`Accel Forward\`
IMUAccelerometer/Backward = \`Accel Backward\`
IMUGyroscope/Pitch Up = \`Gyro Pitch Up\`
IMUGyroscope/Pitch Down = \`Gyro Pitch Down\`
IMUGyroscope/Roll Left = \`Gyro Roll Left\`
IMUGyroscope/Roll Right = \`Gyro Roll Right\`
IMUGyroscope/Yaw Left = \`Gyro Yaw Left\`
IMUGyroscope/Yaw Right = \`Gyro Yaw Right\`
Extension = Nunchuk
Nunchuk/Buttons/C = \`Full Axis 2+\`
Nunchuk/Buttons/Z = \`Full Axis 5+\`
Nunchuk/Stick/Up = \`Axis 1-\`
Nunchuk/Stick/Down = \`Axis 1+\`
Nunchuk/Stick/Left = \`Axis 0-\`
Nunchuk/Stick/Right = \`Full Axis 0+\`
Nunchuk/Stick/Calibration = 100.00 141.42 100.00 141.42 100.00 141.42 100.00 141.42
Nunchuk/Shake/X = \`Click 2\`
Nunchuk/Shake/Y = \`Click 2\`
Nunchuk/Shake/Z = \`Click 2\`
Source = 1
Nunchuk/Stick/Modifier = THUMBL
[Wiimote2]
Device = XInput2/0/Virtual core pointer
Source = 0
[Wiimote3]
Device = XInput2/0/Virtual core pointer
Source = 0
[Wiimote4]
Device = XInput2/0/Virtual core pointer
Source = 0
[BalanceBoard]
Device = XInput2/0/Virtual core pointer
Source = 0
_EOF_

   if [ ! -f $md_conf_root/gc/Config/Hotkeys.ini ]; then cat >"$md_conf_root/gc/Config/Hotkeys.ini" <<_EOF_; fi
[Hotkeys]
Device = SDL/0/X360 Wireless Controller
General/Open = @(Ctrl+O)
General/Toggle Pause = Back&\`Button N\`
General/Stop = Back&\`Button E\`
General/Toggle Fullscreen = Back&\`Button W\`
General/Take Screenshot = Guide
General/Open Achievements = @(Alt+A)
Emulation Speed/Disable Emulation Speed Limit = Tab
Stepping/Step Into = F11
Stepping/Step Over = @(Shift+F10)
Stepping/Step Out = @(Shift+F11)
Breakpoint/Toggle Breakpoint = @(Shift+F9)
Wii/Connect Wii Remote 1 = @(Alt+F5)
Wii/Connect Wii Remote 2 = @(Alt+F6)
Wii/Connect Wii Remote 3 = @(Alt+F7)
Wii/Connect Wii Remote 4 = @(Alt+F8)
Wii/Connect Balance Board = @(Alt+F9)
Load State/Load State Slot 1 = F1
Load State/Load State Slot 2 = F2
Load State/Load State Slot 3 = F3
Load State/Load State Slot 4 = F4
Load State/Load State Slot 5 = F5
Load State/Load State Slot 6 = F6
Load State/Load State Slot 7 = F7
Load State/Load State Slot 8 = F8
Save State/Save State Slot 1 = @(Shift+F1)
Save State/Save State Slot 2 = @(Shift+F2)
Save State/Save State Slot 3 = @(Shift+F3)
Save State/Save State Slot 4 = @(Shift+F4)
Save State/Save State Slot 5 = @(Shift+F5)
Save State/Save State Slot 6 = @(Shift+F6)
Save State/Save State Slot 7 = @(Shift+F7)
Save State/Save State Slot 8 = @(Shift+F8)
Other State Hotkeys/Undo Load State = F12
Other State Hotkeys/Undo Save State = @(Shift+F12)
GBA Core/Load ROM = @(\`Ctrl\`+\`Shift\`+\`O\`)
GBA Core/Unload ROM = @(\`Ctrl\`+\`Shift\`+\`W\`)
GBA Core/Reset = @(\`Ctrl\`+\`Shift\`+\`R\`)
GBA Volume/Volume Down = \`KP_Subtract\`
GBA Volume/Volume Up = \`KP_Add\`
GBA Volume/Volume Toggle Mute = \`M\`
GBA Window Size/1x = \`KP_1\`
GBA Window Size/2x = \`KP_2\`
GBA Window Size/3x = \`KP_3\`
GBA Window Size/4x = \`KP_4\`
USB Emulation Devices/Show Skylanders Portal = @(Ctrl+P)
USB Emulation Devices/Show Infinity Base = @(Ctrl+I)
Save State/Save to Selected Slot = Back&\`Shoulder R\`
Load State/Load from Selected Slot = Back&\`Shoulder L\`
General/Exit = Back&Start
General/Reset = Back&\`Button S\`
_EOF_

   chown -R $__user:$__user "$md_conf_root/gc/Config/"

   cat >"$md_inst/dolphin-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Dolphin"
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

# Run Dolphin
VC4_DEBUG=always_sync /opt/retropie/emulators/dolphin/bin/dolphin-emu

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/dolphin-qjoy.sh"

    [[ "$md_mode" == "install" ]] && shortcuts_icons_dolphin
}

function shortcuts_icons_dolphin() {
   local shortcut_name
   shortcut_name="Dolphin"
   cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=Dolphin
GenericName=Dolphin
Comment=Wii/GameCube Emulator
Exec=$md_inst/bin/dolphin-emu
Icon=$md_inst/Dolphin_74x74.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=GC;Wii
StartupWMClass=Dolphin
Name[en_US]=Dolphin
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/Dolphin_74x74.xpm" << _EOF_
/* XPM */
static char * Dolphin_74x74_xpm[] = {
"74 74 351 2",
"   c None",
".  c #2066FF",
"+  c #2065FF",
"@  c #2164FF",
"#  c #2163FF",
"\$     c #2161FF",
"%  c #1989FF",
"&  c #1988FF",
"*  c #1987FF",
"=  c #1986FF",
"-  c #1A85FF",
";  c #1A84FF",
">  c #1A82FF",
",  c #1A81FF",
"'  c #1B80FF",
")  c #1B7FFF",
"!  c #1B7EFF",
"~  c #1B7CFF",
"{  c #1C7BFF",
"]  c #1C7AFF",
"^  c #1C79FF",
"/  c #1C78FF",
"(  c #1D76FF",
"_  c #1F6AFF",
":  c #1F69FF",
"<  c #2068FF",
"[  c #2067FF",
"}  c #2276FF",
"|  c #2483FF",
"1  c #2489FF",
"2  c #248DFF",
"3  c #2487FF",
"4  c #237FFF",
"5  c #2264FF",
"6  c #225DFF",
"7  c #188DFF",
"8  c #188CFF",
"9  c #188BFF",
"0  c #198AFF",
"a  c #208FFF",
"b  c #279AFF",
"c  c #2CA2FF",
"d  c #2FA9FF",
"e  c #30ACFF",
"f  c #31ADFF",
"g  c #2FACFF",
"h  c #2DA7FF",
"i  c #2CA5FF",
"j  c #2A9FFF",
"k  c #2592FF",
"l  c #2187FF",
"m  c #1D77FF",
"n  c #1D75FF",
"o  c #1D74FF",
"p  c #1D73FF",
"q  c #1E72FF",
"r  c #1E70FF",
"s  c #1F6BFF",
"t  c #2075FF",
"u  c #269EFF",
"v  c #29B8FF",
"w  c #2BCAFF",
"x  c #2BCEFF",
"y  c #2ACEFF",
"z  c #29CEFF",
"A  c #28CDFF",
"B  c #27CDFF",
"C  c #26CDFF",
"D  c #24CCFF",
"E  c #23BAFF",
"F  c #2298FF",
"G  c #188FFF",
"H  c #188EFF",
"I  c #2297FF",
"J  c #2FABFF",
"K  c #37BAFF",
"L  c #3DC6FF",
"M  c #42D1FF",
"N  c #42D3FF",
"O  c #41D3FF",
"P  c #40D3FF",
"Q  c #3FD2FF",
"R  c #3ED2FF",
"S  c #3DD2FF",
"T  c #3CD2FF",
"U  c #3BD2FF",
"V  c #3AD1FF",
"W  c #39D1FF",
"X  c #38D1FF",
"Y  c #37D1FF",
"Z  c #36D0FF",
"\`     c #34CFFF",
" . c #30C3FF",
".. c #2BB6FF",
"+. c #27A4FF",
"@. c #228DFF",
"#. c #1E71FF",
"\$.    c #1E6EFF",
"%. c #1F6DFF",
"&. c #2076FF",
"*. c #25ADFF",
"=. c #29CBFF",
"-. c #25CDFF",
";. c #24CDFF",
">. c #23CCFF",
",. c #22CCFF",
"'. c #21CCFF",
"). c #20CCFF",
"!. c #1FCBFF",
"~. c #1ECBFF",
"{. c #1DCBFF",
"]. c #1790FF",
"^. c #259FFF",
"/. c #34B7FF",
"(. c #3ECBFF",
"_. c #3FD3FF",
":. c #36D1FF",
"<. c #35D0FF",
"[. c #34D0FF",
"}. c #33D0FF",
"|. c #32D0FF",
"1. c #31CFFF",
"2. c #30CFFF",
"3. c #2FCFFF",
"4. c #2ECFFF",
"5. c #2DCEFF",
"6. c #29CAFF",
"7. c #25B7FF",
"8. c #229FFF",
"9. c #22A0FF",
"0. c #25C7FF",
"a. c #1FCCFF",
"b. c #1CCBFF",
"c. c #1BCBFF",
"d. c #1791FF",
"e. c #1992FF",
"f. c #2CAEFF",
"g. c #3AC8FF",
"h. c #3AD2FF",
"i. c #2DCFFF",
"j. c #2CCEFF",
"k. c #23CDFF",
"l. c #1ACAFF",
"m. c #19CAFF",
"n. c #18CAFF",
"o. c #17CAFF",
"p. c #29AEFF",
"q. c #39CCFF",
"r. c #31D0FF",
"s. c #1BCAFF",
"t. c #17C9FF",
"u. c #16C9FF",
"v. c #14C9FF",
"w. c #13C9FF",
"x. c #12C8FF",
"y. c #1792FF",
"z. c #1D9CFF",
"A. c #32C4FF",
"B. c #28CEFF",
"C. c #15C9FF",
"D. c #11C8FF",
"E. c #10C8FF",
"F. c #0FC8FF",
"G. c #0EC7FF",
"H. c #0DC7FF",
"I. c #18A2FF",
"J. c #21A5FF",
"K. c #32CDFF",
"L. c #0CC7FF",
"M. c #0BC7FF",
"N. c #0AC6FF",
"O. c #09C6FF",
"P. c #08C6FF",
"Q. c #07C6FF",
"R. c #189DFF",
"S. c #2359FF",
"T. c #1FA7FF",
"U. c #2ECEFF",
"V. c #06C6FF",
"W. c #05C5FF",
"X. c #04C5FF",
"Y. c #03C5FF",
"Z. c #02C5FF",
"\`.    c #01C4FF",
" + c #03C1FF",
".+ c #1C82FF",
"++ c #2457FF",
"@+ c #2455FF",
"#+ c #1CA2FF",
"\$+    c #29CCFF",
"%+ c #06C5FF",
"&+ c #02C4FF",
"*+ c #00C4FF",
"=+ c #00C3FF",
"-+ c #00C2FF",
";+ c #14A0FF",
">+ c #235CFF",
",+ c #2553FF",
"'+ c #22C2FF",
")+ c #00C1FF",
"!+ c #00C0FF",
"~+ c #00BFFF",
"{+ c #08B4FF",
"]+ c #2171FF",
"^+ c #2551FF",
"/+ c #1CB9FF",
"(+ c #00BEFF",
"_+ c #00BDFF",
":+ c #02BAFF",
"<+ c #1C86FF",
"[+ c #264EFF",
"}+ c #19C5FF",
"|+ c #1C77FF",
"1+ c #1E6FFF",
"2+ c #00BCFF",
"3+ c #00BBFF",
"4+ c #00BAFF",
"5+ c #1696FF",
"6+ c #264DFF",
"7+ c #274BFF",
"8+ c #14C8FF",
"9+ c #08C1FF",
"0+ c #0BB7FF",
"a+ c #0AB9FF",
"b+ c #07BBFF",
"c+ c #03C3FF",
"d+ c #02C0FF",
"e+ c #07B7FF",
"f+ c #0BB0FF",
"g+ c #11A4FF",
"h+ c #1694FF",
"i+ c #1C7EFF",
"j+ c #00B9FF",
"k+ c #00B8FF",
"l+ c #00B7FF",
"m+ c #129DFF",
"n+ c #2650FF",
"o+ c #2748FF",
"p+ c #04B8FF",
"q+ c #11A3FF",
"r+ c #00B6FF",
"s+ c #00B5FF",
"t+ c #10A1FF",
"u+ c #264FFF",
"v+ c #2846FF",
"w+ c #06B3FF",
"x+ c #1693FF",
"y+ c #2069FF",
"z+ c #2160FF",
"A+ c #225FFF",
"B+ c #00B4FF",
"C+ c #00B3FF",
"D+ c #00B2FF",
"E+ c #109FFF",
"F+ c #274CFF",
"G+ c #03B4FF",
"H+ c #2162FF",
"I+ c #00B1FF",
"J+ c #00B0FF",
"K+ c #00AFFF",
"L+ c #119BFF",
"M+ c #2847FF",
"N+ c #07ADFF",
"O+ c #1C7DFF",
"P+ c #235AFF",
"Q+ c #00AEFF",
"R+ c #00ADFF",
"S+ c #1690FF",
"T+ c #2940FF",
"U+ c #1397FF",
"V+ c #225EFF",
"W+ c #00ACFF",
"X+ c #00ABFF",
"Y+ c #00AAFF",
"Z+ c #1B81FF",
"\`+    c #2A3DFF",
" @ c #08A6FF",
".@ c #206AFF",
"+@ c #2454FF",
"@@ c #00A9FF",
"#@ c #00A8FF",
"\$@    c #00A7FF",
"%@ c #2269FF",
"&@ c #2A3BFF",
"*@ c #03AAFF",
"=@ c #1E74FF",
"-@ c #2552FF",
";@ c #00A6FF",
">@ c #00A5FF",
",@ c #05A0FF",
"'@ c #284DFF",
")@ c #01A9FF",
"!@ c #254FFF",
"~@ c #00A4FF",
"{@ c #00A3FF",
"]@ c #138EFF",
"^@ c #2B37FF",
"/@ c #00A1FF",
"(@ c #00A0FF",
"_@ c #216DFF",
":@ c #009FFF",
"<@ c #009EFF",
"[@ c #0698FF",
"}@ c #2A41FF",
"|@ c #02A0FF",
"1@ c #2263FF",
"2@ c #009DFF",
"3@ c #009CFF",
"4@ c #009BFF",
"5@ c #1A7BFF",
"6@ c #2C31FF",
"7@ c #0898FF",
"8@ c #009AFF",
"9@ c #0099FF",
"0@ c #0197FF",
"a@ c #2949FF",
"b@ c #1389FF",
"c@ c #0098FF",
"d@ c #0097FF",
"e@ c #197BFF",
"f@ c #00A2FF",
"g@ c #0095FF",
"h@ c #0094FF",
"i@ c #0193FF",
"j@ c #2A46FF",
"k@ c #0891FF",
"l@ c #0093FF",
"m@ c #0092FF",
"n@ c #1C73FF",
"o@ c #0091FF",
"p@ c #0090FF",
"q@ c #048CFF",
"r@ c #2C39FF",
"s@ c #018FFF",
"t@ c #028EFF",
"u@ c #038DFF",
"v@ c #127FFF",
"w@ c #2A47FF",
"x@ c #058BFF",
"y@ c #2168FF",
"z@ c #068AFF",
"A@ c #0789FF",
"B@ c #1878FF",
"C@ c #0888FF",
"D@ c #0987FF",
"E@ c #0986FF",
"F@ c #2360FF",
"G@ c #0A85FF",
"H@ c #1D6DFF",
"I@ c #1875FF",
"J@ c #1A72FF",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                    . + @ # \$                                       ",
"                                        % & * = - ; > , ' ) ! ~ { ] ^ / (                   _ : < [ } | 1 2 3 4 5 6                                 ",
"                                7 8 9 0 & * a b c d d e f g h i j k l m n o p q r       s _ t u v w x y z A B C D E F                               ",
"                          G H 7 8 I J K L M N O P Q R S T U V W X Y Z \`  ...+.@.#.\$.%.s &.*.=.A B C -.;.>.,.'.).!.~.{.                              ",
"                      ].].H ^./.(.N P _.R S T U V W X Y :.<.[.}.|.1.2.3.4.5.x y 6.7.8.9.0.;.>.,.'.).a.~.{.b.c.c.                                    ",
"                    d.e.f.g.Q R S T h.W X Y :.<.[.}.|.1.2.3.4.i.j.x y z A B C ;.k.,.'.).a.~.{.b.c.l.m.n.o.o.                                        ",
"                  d.p.q.U V W X Y Z <.[.|.r.2.3.4.i.j.x y z A B C -.;.>.,.'.).!.~.{.b.s.l.m.n.t.u.v.w.x.x.                                          ",
"              y.z.A.Y :.<.[.}.|.1.2.3.4.j.x y z B.B C -.;.>.,.'.).!.~.{.b.c.l.m.n.o.u.C.v.w.x.D.E.F.G.H.I.                                          ",
"              J.K.|.1.2.3.4.i.j.x y z A B C ;.k.,.'.).a.~.{.b.c.l.m.n.o.u.C.v.w.x.D.E.F.G.H.L.M.N.O.P.Q.R.S.                                        ",
"            T.U.i.j.x y z A B C -.;.>.,.'.).!.~.{.b.c.s.l.m.n.t.u.C.w.x.D.F.G.H.L.M.N.O.P.Q.V.W.X.Y.Z.\`. +.+++@+                                    ",
"          #+\$+B.B C -.;.>.,.'.).a.~.{.b.c.l.m.                                O.Q.%+W.X.Y.&+\`.*+=+=+=+-+-+-+;+>+,+                                  ",
"          '+k.,.'.).a.~.{.b.c.l.m.n.o.u.u.                                            *+=+-+-+-+)+)+)+!+!+!+~+{+]+^+                                ",
"        /+!.~.{.b.s.l.m.n.u.C.v.w.x.D.D.                                                    !+!+~+~+~+(+(+_+_+_+:+<+[+                              ",
"        }+m.n.o.u.C.v.w.x.D.E.F.G.H.L.    ] ^ / |+n o p q r 1+\$.%.                              _+_+2+2+2+3+3+3+4+4+5+6+7+                          ",
"        8+w.x.D.E.F.G.H.L.M.N.O.P.Q.9+0+a+b+c+\`.\`.*+=+d+e+f+g+h+i+_ : < .                           4+4+4+j+j+j+k+k+l+m+n+o+                        ",
"        G.H.L.M.N.O.P.Q.V.W.X.Y.Z.\`.\`.*+=+=+=+-+-+)+)+)+!+!+!+~+~+p+q+- . @ #                           k+l+l+r+r+r+s+s+t+u+v+                      ",
"        O.P.Q.%+W.X.Y.&+\`.*+=+=+=+-+-+-+)+)+!+!+!+~+~+~+(+(+(+_+_+2+2+2+w+x+y+z+A+                        s+s+B+B+C+C+C+D+E+F+                      ",
"      X.Y.&+\`.\`.*+=+=+-+-+-+)+)+)+!+!+!+~+~+(+(+(+_+_+_+2+2+3+3+3+4+4+4+j+j+G+].H+6                           D+I+I+I+J+J+K+L+M+                    ",
"    *+=+=+=+-+-+)+)+)+!+!+!+~+~+~+(+(+_+_+_+2+2+2+3+3+4+4+4+j+j+j+k+k+l+l+l+r+r+N+O+P+S.                        K+K+Q+Q+Q+R+R+S+T+                  ",
"  -+-+)+)+!+!+!+~+~+~+(+(+(+_+_+2+2+2+3+3+3+4+4+j+j+j+k+k+k+l+l+r+r+r+s+s+s+B+B+C+C+U+V+++                        R+W+W+X+X+X+Y+Z+\`+                ",
"!+!+!+~+~+(+(+(+_+_+_+2+2+2+3+3+              k+l+l+l+r+r+s+s+s+B+B+C+C+C+D+D+I+I+I+J+ @.@+@                        Y+@@@@@@#@#@\$@%@&@              ",
"(+(+_+_+_+2+2+2+3+3+3+                        r+s+s+B+B+B+C+C+D+D+    I+J+J+J+K+K+Q+Q+Q+*@=@-@                        \$@\$@;@;@;@>@,@'@              ",
"  2+3+3+3+4+4+4+                                C+C+D+D+I+I+J+J+J+          Q+R+R+W+W+X+X+)@{ !@                        >@~@~@{@{@{@]@^@            ",
"                                                  J+J+K+K+K+Q+Q+R+                Y+@@@@@@#@#@] 6+                          /@/@/@(@(@_@            ",
"                                                    Q+R+R+W+W+W+X+                    \$@;@;@;@>@r 7+                        (@:@<@<@<@[@}@          ",
"                                                      X+X+Y+Y+@@@@#@                      ~@{@{@|@1@                          2@3@3@4@4@5@6@        ",
"                                                        #@#@\$@\$@\$@;@                        /@/@(@7@-@                          8@8@9@9@0@a@        ",
"                                                          ;@>@>@~@~@~@                          <@<@b@                            c@d@d@d@e@        ",
"                                                              {@f@f@/@/@                            4@\$.                            g@g@h@i@j@      ",
"                                                                    (@:@:@                            k@                              l@m@m@n@      ",
"                                                                                                                                      o@p@p@q@r@    ",
"                                                                                                                                        s@s@s@1@    ",
"                                                                                                                                          t@u@v@    ",
"                                                                                                                                          q@q@q@w@  ",
"                                                                                                                                            x@x@y@  ",
"                                                                                                                                            z@A@B@  ",
"                                                                                                                                              C@D@  ",
"                                                                                                                                                E@F@",
"                                                                                                                                                G@H@",
"                                                                                                                                                  I@",
"                                                                                                                                                  J@",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    ",
"                                                                                                                                                    "};
_EOF_
}
