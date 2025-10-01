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

# Script Provided by gvx64 - Updated by RapidEdwin08 20250311
# https://retropie.org.uk/forum/topic/36971/gamecube-wii-error-mario-part-5/2

rp_module_id="dolphin-rpi"
rp_module_desc="Gamecube/Wii Emulator Dolphin v5.0-4544 Optimized for Pi"
rp_module_help="ROM Extensions: .elf .dol .gcm .iso .rvz .wbfs .ciso .gcz .wad .dff\n\nCopy your Gamecube roms to $romdir/gc and Wii roms to $romdir/wii \n \nSample [Hotkeys.ini] :\n$home/.local/share/dolphin-rpi/Config/Hotkeys.ini\n \nKeys/Toggle Pause = \`Button 6\` & \`Button 3\`\nKeys/Stop = \`Button 6\` & \`Button 1\`\nKeys/Reset = \`Button 6\` & \`Button 0\`\nKeys/Toggle Fullscreen = \`Button 6\` & \`Button 2\`\nKeys/Take Screenshot = \`Button 6\` & \`Button 8\`\nKeys/Exit = \`Button 6\` & \`Button 7\`\n \nExamples of Games [dolphin-rpi] is Optimized for:\nMario Kart Double Dash\nResident Evil 4\nMario Golf Toadstool Tour\nMetroid Prime\nZelda Twilight Princess (Gamecube)\nBomberman Generations\nSonic Adventure DX\nThe Last Story (Wii)\nand more..."
rp_module_licence="GPL2 https://github.com/gvx64/dolphin-rpi/blob/master/license.txt"
rp_module_repo="git https://github.com/gvx64/dolphin-rpi.git master"
rp_module_section="exp"
rp_module_flags="!all aarch64"

function depends_dolphin-rpi() {
    local depends=(cmake gcc-11 g++-11 pkg-config libasound2-dev libopenal-dev libevdev-dev libgtk2.0-dev qtbase5-private-dev libxxf86vm-dev x11proto-xinerama-dev libsdl2-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}
 
function sources_dolphin-rpi() {
    gitPullOrClone
    # Hide Font Error: Trying to access Windows-1252 fonts but they are not loaded. /Source/Core/Core/HW/EXI/EXI_DeviceIPL.cpp
    applyPatch "$md_data/01_font_alerts.diff"
}
 
function build_dolphin-rpi() {
    mkdir build
    cd build
    # use the bundled 'speexdsp' libs, distro versions before 1.2.1 trigger a 'cmake' error
    cmake .. -DCMAKE_C_COMPILER=gcc-11 -DCMAKE_CXX_COMPILER=g++-11 -DBUNDLE_SPEEX=ON -DENABLE_AUTOUPDATE=OFF -DENABLE_ANALYTICS=OFF  -DUSE_DISCORD_PRESENCE=O -DENABLE_PULSEAUDIO=ON
    make clean
    make
    md_ret_require="$md_build/build/Binaries/dolphin-emu"
}
 
function install_dolphin-rpi() {
    #copy binaries to /opt/retropie/emulators/dolphin-rpi
    cd build/Binaries/
    mkdir $md_inst
    mkdir $md_inst/bin/
    mv dolphin-emu $md_inst/bin/
    mv dolphin-emu-nogui $md_inst/bin/
    #use $home/.local/share/dolphin-rpi/ as the configuration/settings/save file directory
    cd ..
    mkdir $home/.local/share/dolphin-rpi/
    mkdir $home/.local/share/dolphin-rpi/Config/
    mv ../Data/Sys/GameSettings/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/GC/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/Wii/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/Maps/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/Resources/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/Shaders/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/Themes/ $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/codehandler.bin $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/totaldb.dsy $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-de.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-en.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-es.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-fr.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-it.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-ja.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-ko.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-nl.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-pt.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-ru.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-zh_CN.txt $home/.local/share/dolphin-rpi/
    mv ../Data/Sys/wiitdb-zh_TW.txt $home/.local/share/dolphin-rpi/
    mv ../Data/dolphin-emu.svg $md_inst
}
 
function remove_dolphin-rpi() {
    rm -r $home/.local/share/dolphin-rpi/GameSettings/
    rm -r $home/.local/share/dolphin-rpi/Maps/
    rm -r $home/.local/share/dolphin-rpi/Resources/
    rm -r $home/.local/share/dolphin-rpi/Shaders/
    rm -r $home/.local/share/dolphin-rpi/Themes/
    rm -r $home/.local/share/dolphin-rpi/Config/
    rm $home/.local/share/dolphin-rpi/codehandler.bin
    rm $home/.local/share/dolphin-rpi/totaldb.dsy
    rm $home/.local/share/dolphin-rpi/wiitdb-de.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-en.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-es.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-fr.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-it.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-ja.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-ko.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-nl.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-pt.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-ru.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-zh_CN.txt
    rm $home/.local/share/dolphin-rpi/wiitdb-zh_TW.txt
#   Do not delete GC or Wii save file directories upon emulator uninstall
#    rm -r $home/.local/share/dolphin-rpi/GC/
#    rm -r $home/.local/share/dolphin-rpi/Wii/
#    rm -r $home/.local/share/dolphin-rpi/

    rm -f /usr/share/applications/Dolphin-rpi.desktop
    rm -f "$home/Desktop/Dolphin-rpi.desktop"
    rm -f "$home/RetroPie/roms/gc/+Start RPi-Dolphin.m3u"
    rm -f "$home/RetroPie/roms/wii/+Start RPi-Dolphin.wad"

    # Remove Symbolic Link to Address Error: Could not find resource: /usr/local/share/dolphin-emu/sys/Resources/nobanner.png
    rm -Rf /usr/local/share/dolphin-emu
}
 
function configure_dolphin-rpi() {
    moveConfigDir "$home/.local/share/dolphin-rpi" "$md_conf_root/gc/dolphin-rpi"
    chown -R $__user:$__user "$md_conf_root/gc/dolphin-rpi"
    # Symbolic Link to Address Error: Could not find resource: /usr/local/share/dolphin-emu/sys/Resources/nobanner.png
    if [ ! -d /usr/local/share/dolphin-emu ]; then mkdir /usr/local/share/dolphin-emu; fi
    if [ ! -d /usr/local/share/dolphin-emu/sys ]; then ln -s $md_conf_root/gc/dolphin-rpi /usr/local/share/dolphin-emu/sys; fi

    mkRomDir "gc"
    mkRomDir "wii"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addEmulator 0 "$md_id" "gc" "$launch_prefix$md_inst/bin/dolphin-emu-nogui -e %ROM% -u $home/.local/share/dolphin-rpi/"
    addEmulator 1 "$md_id-gui" "gc" "$launch_prefix$md_inst/bin/dolphin-emu -b -e %ROM% -u $home/.local/share/dolphin-rpi/"
    addEmulator 0 "$md_id" "wii" "$launch_prefix$md_inst/bin/dolphin-emu-nogui -e %ROM% -u $home/.local/share/dolphin-rpi/"
    addEmulator 1 "$md_id-gui" "wii" "$launch_prefix$md_inst/bin/dolphin-emu -b -e %ROM% -u $home/.local/share/dolphin-rpi/"

    isPlatform "kms" && launch_prefix="XINIT-WMC:"
    addEmulator 0 "$md_id-editor" "gc" "$launch_prefix$md_inst/bin/dolphin-emu -u $home/.local/share/dolphin-rpi/"
    addEmulator 0 "$md_id-editor" "wii" "$launch_prefix$md_inst/bin/dolphin-emu -u $home/.local/share/dolphin-rpi/"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addEmulator 0 "$md_id-editor+qjoypad" "gc" "$launch_prefix$md_inst/dolphin-rpi-qjoy.sh"
        addEmulator 0 "$md_id-editor+qjoypad" "wii" "$launch_prefix$md_inst/dolphin-rpi-qjoy.sh"
    fi

    addSystem "gc"
    addSystem "wii"
 
    [[ "$md_mode" == "remove" ]] && return
 
   cat >"$romdir/gc/+Start RPi-Dolphin.m3u" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "gc" ""
_EOF_
   chown $__user:$__user "$romdir/gc/+Start RPi-Dolphin.m3u"

   cat >"$romdir/wii/+Start RPi-Dolphin.wad" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "wii" ""
_EOF_
   chown $__user:$__user "$romdir/wii/+Start RPi-Dolphin.wad"

   if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
   if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'gc_StartRPi-Dolphin = "dolphin-rpi-editor"' ; echo $?) == '1' ]]; then echo 'gc_StartRPi-Dolphin = "dolphin-rpi-editor"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi
   if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'wii_StartRPi-Dolphin = "dolphin-rpi-editor"' ; echo $?) == '1' ]]; then echo 'wii_StartRPi-Dolphin = "dolphin-rpi-editor"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi

    # preset options used for Raspberry Pi 4 (Bookworm) - modify for your build as desired
   if [ ! -f $home/.local/share/dolphin-rpi/Config/Dolphin.ini ]; then cat >"$home/.local/share/dolphin-rpi/Config/Dolphin.ini" <<_EOF_; fi
[Core]
OverclockEnable = False
EnableCheats = False
GFXBackend = Vulkan
CPUCore = 4
Fastmem = True
CPUThread = True
SyncOnSkipIdle = True
FPRF = False
AccurateNaNs = False
AudioLatency = 20
AutoDiscChange = True
[Display]
FullscreenDisplayRes = Auto
Fullscreen = True
RenderToMain = True
KeepWindowOnTop = True
[Interface]
ConfirmStop = False
ThemeName = Clean Pink
[General]
ISOPath0 = "$home/RetroPie/roms/gc"
ISOPath1 = "$home/RetroPie/roms/wii"
ISOPaths = 2
WiiSDCardPath = $home/.local/share/dolphin-rpi/Wii/sd.raw
_EOF_

   if [ ! -f $home/.local/share/dolphin-rpi/Config/GFX.ini ]; then cat >"$home/.local/share/dolphin-rpi/Config/GFX.ini" <<_EOF_; if isPlatform "gles3"; then echo 'PreferGLES = True' >> $home/.local/share/dolphin-rpi/Config/GFX.ini; fi; fi
[Settings]
AspectRatio = 3
_EOF_

    if [ ! -f $home/.local/share/dolphin-rpi/Config/GCPadNew.ini ]; then cat >"$home/.local/share/dolphin-rpi/Config/GCPadNew.ini" <<_EOF_; fi
[GCPad1]
Device = evdev/0/Xbox 360 Wireless Receiver (XBOX)
Buttons/A = \`Button 0\`
Buttons/B = \`Button 2\`
Buttons/X = \`Button 1\`
Buttons/Y = \`Button 3\`
Buttons/Z = \`Button 5\`
Buttons/Start = \`Button 7\`
Main Stick/Up = \`Axis 1-\`
Main Stick/Down = \`Axis 1+\`
Main Stick/Left = \`Axis 0-\`
Main Stick/Right = \`Axis 0-+\`
Main Stick/Modifier = \`Button 9\`
Main Stick/Modifier/Range = 50.000000000000000
C-Stick/Up = \`Axis 4-\`
C-Stick/Down = \`Axis 4+\`
C-Stick/Left = \`Axis 3-\`
C-Stick/Right = \`Axis 3+\`
C-Stick/Modifier = \`Button 10\`
C-Stick/Modifier/Range = 50.000000000000000
Triggers/L = \`Button 4\`
Triggers/R = \`Button 5\`
D-Pad/Up = \`Button 13\`
D-Pad/Down = \`Button 14\`
D-Pad/Left = \`Button 11\`
D-Pad/Right = \`Button 12\`
Triggers/L-Analog = \`Axis 2-+\`
Triggers/R-Analog = \`Axis 5+\`
_EOF_

    if [ ! -f $home/.local/share/dolphin-rpi/Config/WiimoteNew.ini ]; then cat >"$home/.local/share/dolphin-rpi/Config/WiimoteNew.ini" <<_EOF_; fi
[Wiimote1]
Device = evdev/0/Xbox 360 Wireless Receiver (XBOX)
Buttons/A = \`Button 0\`
Buttons/B = \`Button 1\`
Buttons/1 = \`Button 4\`
Buttons/2 = \`Button 5\`
Buttons/- = \`Button 6\`
Buttons/+ = \`Button 7\`
Buttons/Home = \`Button 8\`
IR/Up = Cursor Y-
IR/Down = Cursor Y+
IR/Left = Cursor X-
IR/Right = Cursor X+
Shake/X = Click 2
Shake/Y = Click 2
Shake/Z = Click 2
Extension = Nunchuk
Nunchuk/Buttons/C = \`Button 2\`
Nunchuk/Buttons/Z = \`Button 3\`
Nunchuk/Stick/Up = \`Axis 1-\`
Nunchuk/Stick/Down = \`Axis 1+\`
Nunchuk/Stick/Left = \`Axis 0-\`
Nunchuk/Stick/Right = \`Axis 0-+\`
D-Pad/Up = \`Button 13\`
D-Pad/Down = \`Button 14\`
D-Pad/Left = \`Button 11\`
D-Pad/Right = \`Button 12\`
Nunchuk/Stick/Modifier = \`Button 9\`
Source = 1
[Wiimote2]
Source = 0
[Wiimote3]
Source = 0
[Wiimote4]
Source = 0
[BalanceBoard]
Source = 0
_EOF_

    if [ ! -f $home/.local/share/dolphin-rpi/Config/Hotkeys.ini ]; then cat >"$home/.local/share/dolphin-rpi/Config/Hotkeys.ini" <<_EOF_; fi
[Hotkeys1]
Device = evdev/0/Xbox 360 Wireless Receiver (XBOX)
Keys/Open = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & (\`Control_L\` | \`Control_R\` )) & O
Keys/Toggle Pause = \`Button 6\` & \`Button 3\`
Keys/Stop = \`Button 6\` & \`Button 1\`
Keys/Reset = \`Button 6\` & \`Button 0\`
Keys/Toggle Fullscreen = \`Button 6\` & \`Button 2\`
Keys/Take Screenshot = \`Button 6\` & \`Button 8\`
Keys/Exit = \`Button 6\` & \`Button 7\`
Keys/Disable Emulation Speed Limit = Tab
Keys/Step Into = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F11\`
Keys/Step Over = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F10\`
Keys/Step Out = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F11\`
Keys/Toggle Breakpoint = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F9\`
Keys/Connect Wii Remote 1 = (\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F5\`
Keys/Connect Wii Remote 2 = (\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F6\`
Keys/Connect Wii Remote 3 = (\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F7\`
Keys/Connect Wii Remote 4 = (\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F8\`
Keys/Connect Balance Board = (\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F9\`
Keys/Freelook Decrease Speed = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`1\`
Keys/Freelook Increase Speed = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`2\`
Keys/Freelook Reset Speed = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & F
Keys/Freelook Move Up = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & E
Keys/Freelook Move Down = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & Q
Keys/Freelook Move Left = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & A
Keys/Freelook Move Right = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & D
Keys/Freelook Zoom In = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & W
Keys/Freelook Zoom Out = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & S
Keys/Freelook Reset = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & R
Keys/Load State Slot 1 = \`Button 6\` & \`Button 4\`
Keys/Load State Slot 2 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F2\`
Keys/Load State Slot 3 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F3\`
Keys/Load State Slot 4 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F4\`
Keys/Load State Slot 5 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F5\`
Keys/Load State Slot 6 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F6\`
Keys/Load State Slot 7 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F7\`
Keys/Load State Slot 8 = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F8\`
Keys/Save State Slot 1 = \`Button 6\` & \`Button 5\`
Keys/Save State Slot 2 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F2\`
Keys/Save State Slot 3 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F3\`
Keys/Save State Slot 4 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F4\`
Keys/Save State Slot 5 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F5\`
Keys/Save State Slot 6 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F6\`
Keys/Save State Slot 7 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F7\`
Keys/Save State Slot 8 = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F8\`
Keys/Undo Load State = (!\`Alt_L\` & !(\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F12\`
Keys/Undo Save State = (!\`Alt_L\` & (\`Shift_L\` | \`Shift_R\`) & !(\`Control_L\` | \`Control_R\` )) & \`F12\`
_EOF_

    # Complimentary RE4 INI options - modify for your version as desired
    # G4BD08  Resident Evil 4 (PAL)
    # G4BE08  Resident Evil 4 (NTSC-U)
    # G4BP08  Resident Evil 4 (PAL)
    # RB4E08  Resident Evil 4: Wii Edition (NTSC-U)
    # RB4P08  Resident Evil 4: Wii Edition (PAL)
    # RB4X08  Resident Evil 4: Wii Edition (PAL) 
   if [ ! -f $home/.local/share/dolphin-rpi/GameSettings/G4BE08.ini ]; then cat >"$home/.local/share/dolphin-rpi/GameSettings/G4BE08.ini" <<_EOF_; fi
# G4BE08 - Resident Evil 4 (NTSC-U)
[Core]
GFXBackend = Vulkan
CPUThread = True
EmulationSpeed = 1.
SyncGPU = True
[Display]
Fullscreen = True
[Video_Hacks]
VISkip = True
[Video_Hardware]
VSync = False
[Video_Settings]
AspectRatio = 3
_EOF_

   chown -R $__user:$__user "$home/.local/share/dolphin-rpi"

   local shortcut_name
   shortcut_name="Dolphin-rpi"
   cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=Dolphin-rpi
GenericName=Dolphin-rpi
Comment=Wii/GameCube Emulator
Exec=$md_inst/bin/dolphin-emu -u $home/.local/share/dolphin-rpi/
Icon=$md_inst/dolphin-emu.svg
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=GC;Wii
StartupWMClass=Dolphin-rpi
Name[en_US]=Dolphin-rpi
_EOF_
   chmod 755 "$md_inst/$shortcut_name.desktop"
   if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
   mv "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"

   cat >"$md_inst/dolphin-rpi-qjoy.sh" << _EOF_
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
VC4_DEBUG=always_sync /opt/retropie/emulators/dolphin-rpi/bin/dolphin-emu -u \$HOME/.local/share/dolphin-rpi/

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/dolphin-rpi-qjoy.sh"
}
