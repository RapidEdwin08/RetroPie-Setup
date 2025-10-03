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
    local depends=(cmake gettext pkg-config libao-dev libasound2-dev libavcodec-dev libavformat-dev libbluetooth-dev libenet-dev liblzo2-dev libminiupnpc-dev libopenal-dev libpulse-dev libreadline-dev libsfml-dev libsoil-dev libsoundtouch-dev libswscale-dev libusb-1.0-0-dev libxext-dev libxi-dev libxrandr-dev portaudio19-dev zlib1g-dev libudev-dev libevdev-dev libmbedtls-dev libcurl4-openssl-dev libegl1-mesa-dev liblzma-dev)
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
    if [[ -f /usr/share/applications/Dolphin.desktop ]]; then sudo rm -f /usr/share/applications/Dolphin.desktop; fi
    if [[ -f "$home/Desktop/Dolphin.desktop" ]]; then rm "$home/Desktop/Dolphin.desktop"; fi
    if [[ -f "$home/RetroPie/roms/gc/+Start Dolphin.m3u" ]]; then rm "$home/RetroPie/roms/gc/+Start Dolphin.m3u"; fi
    if [[ -f "$home/RetroPie/roms/wii/+Start Dolphin.wad" ]]; then rm "$home/RetroPie/roms/wii/+Start Dolphin.wad"; fi
}
 
function configure_dolphin() {
    mkRomDir "gc"
    mkRomDir "wii"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addEmulator 0 "$md_id" "gc" "$launch_prefix$md_inst/bin/dolphin-emu-nogui -e %ROM%"
    addEmulator 1 "$md_id-gui" "gc" "$launch_prefix$md_inst/bin/dolphin-emu -b -e %ROM%"
    addEmulator 0 "$md_id" "wii" "$launch_prefix$md_inst/bin/dolphin-emu-nogui -e %ROM%"
    addEmulator 1 "$md_id-gui" "wii" "$launch_prefix$md_inst/bin/dolphin-emu -b -e %ROM%"

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
    if [[ ! -f "$md_conf_root/gc/Config/Dolphin.ini" ]]; then cat >"$md_conf_root/gc/Config/Dolphin.ini" <<_EOF_; fi
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
_EOF_

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
   local shortcut_name
   shortcut_name="Dolphin"
   cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=Dolphin
GenericName=Dolphin
Comment=Wii/GameCube Emulator
Exec=$md_inst/bin/dolphin-emu
Icon=$md_inst/Dolphin.icns
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
}
