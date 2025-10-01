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

rp_module_id="rott-darkwar"
rp_module_desc="Source Port for Rise of the Triad Dark War\n \nMaster Branch (Bullseye+):\nhttps://github.com/LTCHIPS/rottexpr.git\n \nLegacy Branch (Buster-):\nhttps://github.com/RapidEdwin08/RoTT"
if [[ "$__os_debian_ver" -le 10 ]]; then
    rp_module_licence="GPL2 https://raw.githubusercontent.com/RapidEdwin08/RoTT/master/COPYING"
    rp_module_repo="git https://github.com/RapidEdwin08/RoTT"
    #rp_module_repo="git https://github.com/zerojay/RoTT" # Retired #
    #rp_module_repo="git https://github.com/JohnnyonFlame/RoTT"
    #rp_module_repo="git https://github.com/scooterpsu/RoTT"
    #rp_module_repo="git https://github.com/podulator/RoTT"
else
    rp_module_licence="GPL2 https://raw.githubusercontent.com/LTCHIPS/rottexpr/master/LICENSE.DOC"
    rp_module_repo="git https://github.com/LTCHIPS/rottexpr.git master"
fi
rp_module_help="Location of ROTT Darkwar files:\n$romdir/ports/rott-darkwar"
rp_module_section="exp"
rp_module_flags="!mali"

function depends_rott-darkwar() {
    local depends=(fluidsynth libfluidsynth-dev fluid-soundfont-gs fluid-soundfont-gm zip unzip)
    if [[ "$__os_debian_ver" -le 10 ]]; then
        depends+=(libsdl1.2-dev libsdl-mixer1.2-dev automake autoconf)
    else
        depends+=(autotools-dev libopusfile0 libsdl2-dev libsdl2-mixer-dev libsdl2-mixer-2.0-0 libsdl2-ttf-dev)
    fi
    if [[ $(apt-cache search libfluidsynth3) == '' ]]; then
        depends+=(libfluidsynth1)
    else
        depends+=(libfluidsynth3)
    fi
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)

    echo DEPENDS: "${depends[@]}"
    getDepends "${depends[@]}"
}

function sources_rott-darkwar() {
    gitPullOrClone
}

function build_rott-darkwar() {
    if [[ "$__os_debian_ver" -le 10 ]]; then
        #sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/rott/Makefile"
        sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
        make clean
        make -j"$(nproc)" rott-darkwar
        make -j"$(nproc)" rott-darkwar
        make -j"$(nproc)" rott-darkwar
        md_ret_require=("$md_build/rott-darkwar")
    else
        #sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/rott/Makefile"
        #sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
        cd src
        make -j"$(nproc)" rott
        md_ret_require=("$md_build/src/rott")
    fi
}

function install_rott-darkwar() {
    if [[ "$__os_debian_ver" -le 10 ]]; then local rott_bin="rott-darkwar"; else local rott_bin="src/rott"; fi
    md_ret_files=(
           "$rott_bin"
    )
}

function remove_rott-darkwar() {
    local shortcut_name
    shortcut_name="Rise Of The Triad Dark War"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name.sh"
}

function configure_rott-darkwar() {
    mkRomDir "ports/rott-darkwar"
    chown -R $__user:$__user "$romdir/ports/rott-darkwar"
    moveConfigDir "$home/.rott" "$md_conf_root/rott"

    if [[ "$__os_debian_ver" -le 10 ]]; then local rott_bin="rott-darkwar"; else local rott_bin="src/rott"; fi
    local script="$md_inst/$md_id.sh"
    #create buffer script for launch
 cat > "$script" << _EOF_
#!/bin/bash
# Detect/Run ROTT P0RT
rottROMdir="\$HOME/RetroPie/roms/ports/rott" #rottexpr
if [[ -d "\$HOME/RetroPie/roms/ports/rott-darkwar" ]]; then rottROMdir="\$HOME/RetroPie/roms/ports/rott-darkwar"; fi #rott/rottexpr
if [[ -d "/dev/shm/rott-darkwar" ]]; then rottROMdir="/dev/shm/rott-darkwar"; fi #rott-darkwar-plus

rottBIN=/opt/retropie/ports/rott-darkwar/rott # rottexpr
if [[ -f /opt/retropie/ports/rott-darkwar/rott-darkwar ]]; then rottBIN=/opt/retropie/ports/rott-darkwar/rott-darkwar; fi #rott

pushd "\$rottROMdir"
"\$rottBIN" \$*
popd
_EOF_
    chmod 755 "$script"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    if (isPlatform "rpi") && [[ "$__os_debian_ver" -le 10 ]]; then launch_prefix="XINIT:"; fi
    addPort "$md_id" "rott-darkwar" "Rise Of The Triad Dark War" "$launch_prefix$script"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "rott-darkwar" "Rise Of The Triad Dark War" "$launch_prefix$md_inst/rott-darkwar-qjoy.sh"
    fi

    if [[ ! -d "$md_conf_root/rott/darkwar" ]]; then mkdir "$md_conf_root/rott/darkwar"; chown -R $__user:$__user "$md_conf_root/rott/darkwar"; fi
    if [[ "$__os_debian_ver" -le 10 ]]; then
        cat >"$md_inst/config.rot" << _EOF_
;Rise of the Triad Configuration File
;                  (c) 1995

Version            14

;
; 1 - Mouse Enabled
; 0 - Mouse Disabled
MouseEnabled       1

;
; 1 - UseMouseLook Enabled
; 0 - UseMouseLook Disabled
UseMouseLook       0

;
; 1 - Normal Mouse Enabled
; -1 - Inverse Mouse Enabled
InverseMouse       1

;
; 1 - usejump Enabled
; 0 - usejump Disabled
UseJump            1

;
; 1 - CrossHair Enabled
; 0 - CrossHair Disabled
CrossHair          1

;
; 1 - Joystick Enabled
; 0 - Joystick Disabled
JoystickEnabled    0

;
; 1 - Joypad Enabled
; 0 - Joypad Disabled
JoypadEnabled      0

;
; 0 - Use Joystick Port 1
; 1 - Use Joystick Port 2
JoystickPort       0

;
; 0 - Start in windowed mode
; 1 - Start in fullscreen mode
FullScreen         1

;
; Screen Resolution, supported resolutions: 
; 320x200, 640x480 and 800x600
ScreenWidth        800
ScreenHeight       600

;
; Size of View port.
; (smallest) 0 - 10 (largest)
ViewSize           7

;
; Size of Weaponscale.
; (smallest) 150 - 600 (largest)
Weaponscale           357

;
; Sensitivity of Mouse
; (lowest) 0 - 11 (highest)
MouseAdjustment    4

;
; Threshold of Mouse and Joystick
; (smallest) 1 - 15 (largest)
Threshold          1

;
; 1 - Auto Detail on
; 0 - Auto Detail off
AutoDetail         1

;
; 1 - Light Diminishing on
; 0 - Light Diminishing off
LightDim           0

;
; 1 - Bobbing on
; 0 - Bobbing off
BobbingOn          1

;
; (slowest) 50 - 5 (fastest)
DoubleClickSpeed   20

;
; Menu Flip Speed
; (slowest) 100 - 5 (fastest)
MenuFlipSpeed      15

;
; 0 - Detail Level Low
; 1 - Detail Level Medium
; 2 - Detail Level High
DetailLevel        2

;
; 1 - Floor and Ceiling on
; 0 - Floor and Ceiling off
FloorCeiling       1

;
; 1 - Messages on
; 0 - Messages off
Messages           1

;
; 1 - AutoRun on
; 0 - AutoRun off
AutoRun            1

;
; 0 - Gamma Correction level 1
; 1 - Gamma Correction level 2
; 2 - Gamma Correction level 3
; 3 - Gamma Correction level 4
; 4 - Gamma Correction level 5
GammaIndex         0

;
; Minutes before screen blanking
BlankTime          2

;
; Scan codes for keyboard buttons
Fire               29
Strafe             56
Run                54
Use                57
LookUp             73
LookDn             81
Swap               28
Drop               83
TargetUp           71
TargetDn           79
SelPistol          2
SelDualPistol      3
SelMP40            4
SelMissile         5
AutoRun            58
LiveRemRid         88
StrafeLeft         51
StrafeRight        52
VolteFace          14
Aim                30
Forward            72
Right              77
Backward           80
Left               75
Map                15
SendMessage        20
DirectMessage      44

;
; Mouse buttons
MouseButton0       0
MouseButton1       1
MouseButton2       20
DblClickB0         -1
DblClickB1         3
DblClickB2         -1

;
; Joystick buttons
JoyButton0         3
JoyButton1         3
JoyButton2         5
JoyButton3         4
JoyButton4         6
JoyButton5         0
JoyButton6         7
JoyButton7         14
JoyButton8         18
JoyButton9         2
JoyButton10         19
JoyButton11         23
JoyButton12         21
JoyButton13         20
JoyButton14         22
JoyButton15         -1
JoyAxis0         2
JoyAxis1         0
JoyAxis2         -1
JoyAxis3         1
JoyAxis4         3
JoyAxis5         -1
JoyAxis6         0
JoyAxis7         0

;
; Joystick calibration coordinates
JoyMaxX            230
JoyMaxY            230
JoyMinX            25
JoyMinY            25
AimAssist          1

;
; Easy             -   0
; Medium           -   1
; Hard             -   2
; Crezzy           -   3
DefaultDifficulty      2

;
; Taradino Cassatt   -   0
; Thi Barrett        -   1
; Doug Wendt         -   2
; Lorelei Ni         -   3
; Ian Paul Freeley   -   4
DefaultPlayerCharacter   1

;
; Gray             -   0
; Brown            -   1
; Black            -   2
; Tan              -   3
; Red              -   4
; Olive            -   5
; Blue             -   6
; White            -   7
; Green            -   8
; Purple           -   9
; Orange           -   10
DefaultPlayerColor     0

;
SecretPassword         7d7e4a2d3b6a0319554654231c
_EOF_
    else
        cat >"$md_inst/config.rot" << _EOF_
;Rise of the Triad Configuration File
;                  (c) 1995

Version            14

;
; 1 - Allows Blitzguards to have Random Missile weapons
; 0 - Disallows the above (ROTT Default)
AllowBlitzguardMoreMissileWeps      1

;
; 1 - Allows players to refill their missile weapons by running over one a matching one on the ground
; 0 - Disables the above (ROTT default)
EnableAmmoPickups       1

;
; 1 - Bullet weapons will automatically target enemies. (ROTT default)
; 0 - Disables the above.
AutoAim     1

;
; 1 - Missile weapons will be automatically aimed at targets like bullet weapons.
; 0 - Missile weapons are not automatically aimed at targets. (ROTT default)
AutoAimMissileWeps      1

;
; 1 - Enemies equipped with pistols have a chance of dropping an extra pistol when killed.
; 0 - Enemies will not drop extra pistols at all. (Default)
EnableExtraPistolDrops       1

;
; Field Of View offset
FocalWidthOffset       0

;
; 1 - Mouse Enabled
; 0 - Mouse Disabled
MouseEnabled       1

;
; 1 - UseMouseLook Enabled
; 0 - UseMouseLook Disabled
UseMouseLook       0

;
; 1 - Normal Mouse Enabled
; -1 - Inverse Mouse Enabled
InverseMouse       1

;
; 1 - Allows X and Y movement with Mouse. (Default)
; 0 - Allow only X movement with Mouse.
allowMovementWithMouseYAxis      1

;
; 1 - usejump Enabled
; 0 - usejump Disabled
UseJump            1

;
; 1 - CrossHair Enabled
; 0 - CrossHair Disabled
CrossHair          1

;
; 1 - Joystick Enabled
; 0 - Joystick Disabled
JoystickEnabled    0

;
; 1 - Joypad Enabled
; 0 - Joypad Disabled
JoypadEnabled      0

;
; 0 - Use Joystick Port 1
; 1 - Use Joystick Port 2
JoystickPort       0

;
; 0 - Start in windowed mode
; 1 - Start in fullscreen mode
FullScreen         1

;
; 0 - Don't start in bordered window mode
; 1 - Start in bordered window mode
BorderWindow        0

;
; 0 - Don't start in borderless window mode
; 1 - Start in borderless window mode
BorderlessWindow        0

;
; Screen Resolution, supported resolutions: 
; 320x200, 640x480 and 800x600
ScreenWidth        1920
ScreenHeight       1080

;
; Size of View port.
; (smallest) 0 - 10 (largest)
ViewSize           7

;
; Size of Weaponscale.
; (smallest) 150 - 600 (largest)
Weaponscale           906

;
; HUD Scale.
HUDScale              2

;
; Sensitivity of Mouse
; (lowest) 0 - 11 (highest)
MouseAdjustment    5

;
; Threshold of Mouse and Joystick
; (smallest) 1 - 15 (largest)
Threshold          1

;
; 1 - Auto Detail on
; 0 - Auto Detail off
AutoDetail         1

;
; 1 - Light Diminishing on
; 0 - Light Diminishing off
LightDim           0

;
; 1 - Bobbing on
; 0 - Bobbing off
BobbingOn          1

;
; (slowest) 50 - 5 (fastest)
DoubleClickSpeed   20

;
; Menu Flip Speed
; (slowest) 100 - 5 (fastest)
MenuFlipSpeed      15

;
; 0 - Detail Level Low
; 1 - Detail Level Medium
; 2 - Detail Level High
DetailLevel        2

;
; 1 - Floor and Ceiling on
; 0 - Floor and Ceiling off
FloorCeiling       1

;
; 1 - Messages on
; 0 - Messages off
Messages           1

;
; 1 - AutoRun on
; 0 - AutoRun off
AutoRun            1

;
; 0 - Gamma Correction level 1
; 1 - Gamma Correction level 2
; 2 - Gamma Correction level 3
; 3 - Gamma Correction level 4
; 4 - Gamma Correction level 5
GammaIndex         0

;
; Minutes before screen blanking
BlankTime          2

;
; Scan codes for keyboard buttons
Fire               29
Strafe             56
Run                54
Use                57
LookUp             73
LookDn             81
Swap               83
Drop               28
TargetUp           71
TargetDn           79
SelPistol          2
SelDualPistol      3
SelMP40            4
SelMissile         5
AutoRun            58
LiveRemRid         88
StrafeLeft         51
StrafeRight        52
VolteFace          14
Aim                30
Forward            72
Right              77
Backward           80
Left               75
Map                15
SendMessage        20
DirectMessage      44

;
; Mouse buttons
MouseButton0       0
MouseButton1       1
MouseButton2       20
DblClickB0         -1
DblClickB1         3
DblClickB2         -1

;
; Joystick buttons
JoyButton0         0
JoyButton1         1
JoyButton2         2
JoyButton3         3
DblClickJB0        -1
DblClickJB1        -1
DblClickJB2        -1
DblClickJB3        -1

;
; Joystick calibration coordinates
JoyMaxX            0
JoyMaxY            0
JoyMinX            0
JoyMinY            0

;
; Easy             -   0
; Medium           -   1
; Hard             -   2
; Crezzy           -   3
DefaultDifficulty      2

;
; Taradino Cassatt   -   0
; Thi Barrett        -   1
; Doug Wendt         -   2
; Lorelei Ni         -   3
; Ian Paul Freeley   -   4
DefaultPlayerCharacter   1

;
; Gray             -   0
; Brown            -   1
; Black            -   2
; Tan              -   3
; Red              -   4
; Olive            -   5
; Blue             -   6
; White            -   7
; Green            -   8
; Purple           -   9
; Orange           -   10
DefaultPlayerColor     0

;
SecretPassword         7d7e4a2d3b6a0319554654231c
_EOF_
    fi
    if [[ ! -f "$md_conf_root/rott/darkwar/config.rot" ]]; then
        cp "$md_inst/config.rot" "$md_conf_root/rott/darkwar/config.rot"
        chown $__user:$__user "$md_conf_root/rott/darkwar/config.rot"
    fi

    cat >"$md_inst/sound.rot" << _EOF_
;Rise of the Triad Sound File
;                  (c) 1995

Version            14

;
; Music Modes
; 0  -  Off
; 6  -  On
MusicMode          6

;
; FX Modes
; 0  -  Off
; 6  -  On
FXMode             6

;
; Music Volume
; (low) 0 - 255 (high)
MusicVolume      52

;
; FX Volume
; (low) 0 - 255 (high)
FXVolume         196

;
; Number of Voices
; 1 - 8
NumVoices          8

;
; Stereo or Mono
; 1 - Mono
; 2 - Stereo
NumChannels        2

;
; Resolution
; 8 bit
; 16 bit
NumBits            16

;
; ReverseStereo
; 0 no reversal
; 1 reverse stereo
StereoReverse        0
_EOF_
    if [[ ! -f "$md_conf_root/rott/darkwar/sound.rot" ]]; then
        cp "$md_inst/sound.rot" "$md_conf_root/rott/darkwar/sound.rot"
        chown $__user:$__user "$md_conf_root/rott/darkwar/sound.rot"
    fi

   cat >"$md_inst/rott-darkwar-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="Rise Of The Triad"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
    Axis 1: gradient, dZone 5538, xZone 29536, +key 60, -key 59
    Axis 2: gradient, dZone 9230, xZone 28382, +key 116, -key 111
    Axis 3: gradient, dZone 6691, +key 66, -key 0
    Axis 4: gradient, dZone 5307, xZone 28382, maxSpeed 20, mouse+h
    Axis 5: dZone 8768, +key 115, -key 110
    Axis 6: gradient, throttle+, +key 105, -key 0
    Axis 7: +key 114, -key 113
    Axis 8: +key 116, -key 111
    Button 1: key 119
    Button 2: key 65
    Button 3: key 37
    Button 4: key 36
    Button 5: key 117
    Button 6: key 112
    Button 7: key 9
    Button 8: key 36
    Button 9: key 22
    Button 10: key 50
    Button 11: key 38
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

# Detect/Run ROTT P0RT
rottROMdir="\$HOME/RetroPie/roms/ports/rott" #rottexpr
if [[ -d "\$HOME/RetroPie/roms/ports/rott-darkwar" ]]; then rottROMdir="\$HOME/RetroPie/roms/ports/rott-darkwar"; fi #rott/rottexpr
if [[ -d "/dev/shm/rott-darkwar" ]]; then rottROMdir="/dev/shm/rott-darkwar"; fi #rott-darkwar-plus

rottBIN=/opt/retropie/ports/rott-darkwar/rott # rottexpr
if [[ -f /opt/retropie/ports/rott-darkwar/rott-darkwar ]]; then rottBIN=/opt/retropie/ports/rott-darkwar/rott-darkwar; fi #rott

pushd "\$rottROMdir"
"\$rottBIN" \$*
popd

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1
exit 0
_EOF_
    chmod 755 "$md_inst/rott-darkwar-qjoy.sh"

    [[ "$md_mode" == "remove" ]] && remove_rott-darkwar
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && shortcuts_icons_rott-darkwar
}

function shortcuts_icons_rott-darkwar() {
    local shortcut_name
    shortcut_name="Rise Of The Triad Dark War"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=RoTT Dark War
Exec=$md_inst/$md_id.sh
Icon=$md_inst/ROTTDW_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=D2;ROTT;Dark;War
StartupWMClass=RiseOfTheTriadDarkWar
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    mv "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/ROTTDW_48x48.xpm" << _EOF_
/* XPM */
static char * ROTTDW_48x48_xpm[] = {
"48 48 1023 2",
"   c None",
".  c #6A6B6A",
"+  c #969694",
"@  c #9F9E9D",
"#  c #8C8A89",
"\$     c #7B7978",
"%  c #434140",
"&  c #989794",
"*  c #D9D8D7",
"=  c #C8C6C4",
"-  c #A5A2A1",
";  c #C2BFBD",
">  c #585857",
",  c #605F5D",
"'  c #B8B7B6",
")  c #CBCBCA",
"!  c #C0BDBB",
"~  c #B0AEAD",
"{  c #CDCBC9",
"]  c #A4A19F",
"^  c #2E2D2C",
"/  c #858482",
"(  c #D4D3D1",
"_  c #CECDCB",
":  c #C7C5C3",
"<  c #C6C3C2",
"[  c #B5B2AF",
"}  c #616060",
"|  c #787773",
"1  c #C8C7C5",
"2  c #CBC9C6",
"3  c #A7A6A3",
"4  c #C1BEBD",
"5  c #AEADAB",
"6  c #C7C5C4",
"7  c #AEADAC",
"8  c #A3A4A3",
"9  c #5C5D5E",
"0  c #5B5956",
"a  c #BAB6B1",
"b  c #C8C7C4",
"c  c #C8C4C2",
"d  c #DCDBD8",
"e  c #B8B5B3",
"f  c #B6B4B4",
"g  c #D0CECD",
"h  c #989695",
"i  c #999896",
"j  c #CAC9C7",
"k  c #CAC7C4",
"l  c #9F9A95",
"m  c #55504C",
"n  c #4E4A47",
"o  c #6E6B69",
"p  c #C1C0BE",
"q  c #C2BDBB",
"r  c #B5B3AF",
"s  c #5F5F5F",
"t  c #C4C3C1",
"u  c #BDBCBC",
"v  c #BFBDBC",
"w  c #BBB8B5",
"x  c #373331",
"y  c #453D39",
"z  c #4E4644",
"A  c #302D2B",
"B  c #B4B0AF",
"C  c #ABA7A5",
"D  c #C0BDBA",
"E  c #A29D9A",
"F  c #595857",
"G  c #868684",
"H  c #BFBCBA",
"I  c #9E9A97",
"J  c #483F3B",
"K  c #514742",
"L  c #48403D",
"M  c #2D2928",
"N  c #817E7B",
"O  c #B4B1AD",
"P  c #AEA8A5",
"Q  c #A7A3A1",
"R  c #7F7D7C",
"S  c #514E4C",
"T  c #B6B2AF",
"U  c #B5B1AF",
"V  c #AFAAA8",
"W  c #494645",
"X  c #453D3B",
"Y  c #6D6663",
"Z  c #443D39",
"\`     c #242322",
" . c #4A4746",
".. c #A7A09D",
"+. c #A6A19F",
"@. c #CBC8C5",
"#. c #8F8C8A",
"\$.    c #B7B5B3",
"%. c #D8D7D5",
"&. c #C1BFBE",
"*. c #B9B5B3",
"=. c #5C5653",
"-. c #282322",
";. c #2B2726",
">. c #9C9A99",
",. c #6F6965",
"'. c #272625",
"). c #0F0F0F",
"!. c #605855",
"~. c #A7A4A2",
"{. c #B6B4B3",
"]. c #BDBBB8",
"^. c #767573",
"/. c #5B5958",
"(. c #BEB9B6",
"_. c #D6D5D4",
":. c #B2AEAC",
"<. c #3E3B39",
"[. c #393331",
"}. c #292827",
"|. c #8B8988",
"1. c #B1AEAC",
"2. c #292727",
"3. c #3E3735",
"4. c #3C3937",
"5. c #9B9593",
"6. c #B0AEAC",
"7. c #C0BEBC",
"8. c #9C9B9A",
"9. c #797877",
"0. c #83807E",
"a. c #B8B7B5",
"b. c #B7B4B3",
"c. c #C2C0BF",
"d. c #939392",
"e. c #393330",
"f. c #4D423E",
"g. c #555351",
"h. c #ABA9A7",
"i. c #A29F9E",
"j. c #433F3D",
"k. c #37302E",
"l. c #2B2826",
"m. c #7B7877",
"n. c #B6B4B2",
"o. c #C6C2C0",
"p. c #DFDDDB",
"q. c #949391",
"r. c #716D6B",
"s. c #ADABAA",
"t. c #CBC9C7",
"u. c #BDBBBA",
"v. c #BEBCBB",
"w. c #393736",
"x. c #473F3B",
"y. c #4A403C",
"z. c #9D9997",
"A. c #7D7C7A",
"B. c #6C6968",
"C. c #3F3734",
"D. c #39312D",
"E. c #302E2D",
"F. c #BBB7B4",
"G. c #B2B0AF",
"H. c #C4C1C0",
"I. c #4F4D4C",
"J. c #A9A7A5",
"K. c #DFDEDD",
"L. c #C2C0BE",
"M. c #AFAEAC",
"N. c #807E7D",
"O. c #453E39",
"P. c #5F5954",
"Q. c #2F2826",
"R. c #C0BDBC",
"S. c #84807E",
"T. c #5B5756",
"U. c #A3A1A0",
"V. c #2F2825",
"W. c #60554E",
"X. c #4A413C",
"Y. c #6C6864",
"Z. c #C5C2C1",
"\`.    c #CCCBCA",
" + c #C7C4C2",
".+ c #8B8A89",
"++ c #514F4E",
"@+ c #CECBC8",
"#+ c #E3E2DF",
"\$+    c #C0BBB8",
"%+ c #9F9D9B",
"&+ c #3F3934",
"*+ c #78736F",
"=+ c #5D5753",
"-+ c #47423F",
";+ c #B7B4B2",
">+ c #787574",
",+ c #888584",
"'+ c #A39F9C",
")+ c #565350",
"!+ c #5F5752",
"~+ c #746C65",
"{+ c #403935",
"]+ c #BDBCBA",
"^+ c #DDDCDA",
"/+ c #C0C0BF",
"(+ c #BFBDBB",
"_+ c #50504E",
":+ c #3D3B3A",
"<+ c #868483",
"[+ c #C5C4C4",
"}+ c #CAC8C7",
"|+ c #B1AFAE",
"1+ c #595553",
"2+ c #655F5A",
"3+ c #6E6A68",
"4+ c #49433F",
"5+ c #9E9B98",
"6+ c #6E6C6A",
"7+ c #84827E",
"8+ c #A3A1A1",
"9+ c #787573",
"0+ c #85817E",
"a+ c #5B544F",
"b+ c #716C68",
"c+ c #655C57",
"d+ c #727271",
"e+ c #C0BFBE",
"f+ c #D4D2CF",
"g+ c #D4D0CD",
"h+ c #94928F",
"i+ c #777472",
"j+ c #C9C8C6",
"k+ c #C6C5C0",
"l+ c #B8B5B1",
"m+ c #969291",
"n+ c #362F2C",
"o+ c #635E5B",
"p+ c #3E3633",
"q+ c #BEBBB9",
"r+ c #6E6D6C",
"s+ c #959494",
"t+ c #A3A3A1",
"u+ c #38302E",
"v+ c #76726E",
"w+ c #3E3430",
"x+ c #B3B1AF",
"y+ c #CFCCC8",
"z+ c #D3D1CF",
"A+ c #D9D6D3",
"B+ c #7E7D7B",
"C+ c #474443",
"D+ c #C5C5C4",
"E+ c #CAC9C6",
"F+ c #BDBAB6",
"G+ c #575453",
"H+ c #4D4643",
"I+ c #56514F",
"J+ c #56514D",
"K+ c #B8B5B4",
"L+ c #818281",
"M+ c #7D7C7B",
"N+ c #838181",
"O+ c #6D6B6B",
"P+ c #A7A5A3",
"Q+ c #413E3C",
"R+ c #6A6663",
"S+ c #575452",
"T+ c #6F6863",
"U+ c #4E4C4B",
"V+ c #D2CECD",
"W+ c #AEADAD",
"X+ c #C9C7C6",
"Y+ c #C2C1C0",
"Z+ c #747370",
"\`+    c #CCCCC9",
" @ c #C2C1BF",
".@ c #B5B3B0",
"+@ c #A8A6A4",
"@@ c #423B37",
"#@ c #726E6C",
"\$@    c #67625D",
"%@ c #6F6964",
"&@ c #9E9892",
"*@ c #BBBAB8",
"=@ c #ADA8A2",
"-@ c #A1A09E",
";@ c #93918F",
">@ c #504E4D",
",@ c #908E8D",
"'@ c #7F7A76",
")@ c #484340",
"!@ c #6C6967",
"~@ c #75716D",
"{@ c #403937",
"]@ c #8D8988",
"^@ c #CBC7C6",
"/@ c #C5C3C1",
"(@ c #9A9998",
"_@ c #5E5D5B",
":@ c #AAA8A5",
"<@ c #ACAAA8",
"[@ c #9C9A98",
"}@ c #352F2C",
"|@ c #6C6863",
"1@ c #7F7C79",
"2@ c #6B6865",
"3@ c #68615C",
"4@ c #B9B3B0",
"5@ c #888685",
"6@ c #B3B1AE",
"7@ c #A9A8A5",
"8@ c #898785",
"9@ c #807E7E",
"0@ c #716F6D",
"a@ c #A7A29F",
"b@ c #534C48",
"c@ c #6D6966",
"d@ c #6C6663",
"e@ c #423B38",
"f@ c #AAA5A3",
"g@ c #B6B1AF",
"h@ c #C1BFBD",
"i@ c #898683",
"j@ c #D3D2D0",
"k@ c #B7B4B0",
"l@ c #ADA8A6",
"m@ c #6B6764",
"n@ c #59534F",
"o@ c #716E6C",
"p@ c #7E7C7A",
"q@ c #625E5C",
"r@ c #504B49",
"s@ c #CAC6C3",
"t@ c #797776",
"u@ c #868584",
"v@ c #A1A09D",
"w@ c #747271",
"x@ c #7F7F7D",
"y@ c #817F7D",
"z@ c #B2B0AD",
"A@ c #4E4A48",
"B@ c #75716F",
"C@ c #64605E",
"D@ c #5A5656",
"E@ c #3C3532",
"F@ c #757270",
"G@ c #B3AEAC",
"H@ c #CFCCCB",
"I@ c #656362",
"J@ c #484645",
"K@ c #B9B5B2",
"L@ c #AAA7A4",
"M@ c #423E3B",
"N@ c #5F5D5B",
"O@ c #767472",
"P@ c #949291",
"Q@ c #868380",
"R@ c #B6B2B0",
"S@ c #BCBAB9",
"T@ c #7B7A79",
"U@ c #636160",
"V@ c #797775",
"W@ c #767473",
"X@ c #BCBCBB",
"Y@ c #B3AEAB",
"Z@ c #605D5C",
"\`@    c #807C79",
" # c #8D8A85",
".# c #7F7D79",
"+# c #655E5A",
"@# c #403F3E",
"## c #B3AFAC",
"\$#    c #D4D1CE",
"%# c #BDBBB9",
"&# c #545351",
"*# c #B0AFAD",
"=# c #BBBBBC",
"-# c #AAA6A4",
";# c #BAB7B2",
"># c #696764",
",# c #65605C",
"'# c #64615F",
")# c #646160",
"!# c #8A8887",
"~# c #787370",
"{# c #58514D",
"]# c #2B2827",
"^# c #75726F",
"/# c #A4A1A0",
"(# c #959492",
"_# c #393735",
":# c #5F5C59",
"<# c #8B8884",
"[# c #7A7673",
"}# c #67615D",
"|# c #564D47",
"1# c #7B7876",
"2# c #C3C0BD",
"3# c #BBB8B4",
"4# c #DBD9D6",
"5# c #A4A3A1",
"6# c #9A9A97",
"7# c #C3C0BF",
"8# c #A5A1A0",
"9# c #B6B4B0",
"0# c #8B857E",
"a# c #3D3834",
"b# c #666360",
"c# c #817E7A",
"d# c #63625F",
"e# c #5E5955",
"f# c #4E4A46",
"g# c #51504F",
"h# c #575857",
"i# c #34302E",
"j# c #363433",
"k# c #B4B2B0",
"l# c #4D4B4B",
"m# c #363534",
"n# c #585653",
"o# c #454441",
"p# c #413B39",
"q# c #625C58",
"r# c #74706C",
"s# c #6C6560",
"t# c #58514A",
"u# c #302A27",
"v# c #9A938F",
"w# c #C5C0BD",
"x# c #CDCAC5",
"y# c #B7B3B1",
"z# c #52504F",
"A# c #5F605F",
"B# c #A4A2A1",
"C# c #DAD9D8",
"D# c #ABA9A6",
"E# c #5C544F",
"F# c #827F7B",
"G# c #85827D",
"H# c #4D4642",
"I# c #6A645F",
"J# c #8A8480",
"K# c #575451",
"L# c #201F1F",
"M# c #413E3B",
"N# c #322F2E",
"O# c #212020",
"P# c #383735",
"Q# c #51504C",
"R# c #423E3D",
"S# c #58534F",
"T# c #A49D96",
"U# c #504740",
"V# c #58504B",
"W# c #8D8985",
"X# c #655E57",
"Y# c #382F2B",
"Z# c #58514B",
"\`#    c #BEBAB5",
" \$    c #C2BEB8",
".\$    c #AAA8A6",
"+\$    c #5F5B59",
"@\$    c #8F8E8B",
"#\$    c #D6D4D1",
"\$\$   c #B4B3B2",
"%\$    c #A19C98",
"&\$    c #514B46",
"*\$    c #73706C",
"=\$    c #93908A",
"-\$    c #7C7670",
";\$    c #33312F",
">\$    c #BFBBB8",
",\$    c #9C9896",
"'\$    c #555555",
")\$    c #2A2929",
"!\$    c #494743",
"~\$    c #565450",
"{\$    c #494946",
"]\$    c #3D3C3B",
"^\$    c #83807C",
"/\$    c #C1BEBA",
"(\$    c #B0ACA9",
"_\$    c #BBB6B1",
":\$    c #453D38",
"<\$    c #7E766F",
"[\$    c #7B7571",
"}\$    c #746D68",
"|\$    c #1D1918",
"1\$    c #8D8681",
"2\$    c #BCBAB6",
"3\$    c #B5B3B1",
"4\$    c #4B4A48",
"5\$    c #A8A4A1",
"6\$    c #D1CECD",
"7\$    c #AAA8A7",
"8\$    c #A6A3A0",
"9\$    c #5A5857",
"0\$    c #75716B",
"a\$    c #6F6C69",
"b\$    c #716C69",
"c\$    c #8E8986",
"d\$    c #A5A2A0",
"e\$    c #888582",
"f\$    c #B8B7B4",
"g\$    c #D0CFCD",
"h\$    c #8F8C8B",
"i\$    c #4C4744",
"j\$    c #2F2D2D",
"k\$    c #989592",
"l\$    c #C0B8B5",
"m\$    c #B3AFA9",
"n\$    c #9F9B97",
"o\$    c #76716E",
"p\$    c #AEA8A3",
"q\$    c #4F4540",
"r\$    c #6F6A65",
"s\$    c #837F7A",
"t\$    c #403834",
"u\$    c #605E5C",
"v\$    c #BCB9B5",
"w\$    c #C4C4C0",
"x\$    c #CFCECC",
"y\$    c #D2CFCC",
"z\$    c #645E58",
"A\$    c #75716C",
"B\$    c #6A6662",
"C\$    c #403B38",
"D\$    c #ADA7A2",
"E\$    c #A6A6A5",
"F\$    c #97938E",
"G\$    c #A5A29E",
"H\$    c #908C89",
"I\$    c #A6A29F",
"J\$    c #181616",
"K\$    c #1E1E1E",
"L\$    c #B8B4B2",
"M\$    c #9F9C98",
"N\$    c #95918E",
"O\$    c #9C9794",
"P\$    c #979391",
"Q\$    c #A9A6A5",
"R\$    c #A29B96",
"S\$    c #38312D",
"T\$    c #8F8C88",
"U\$    c #625853",
"V\$    c #A5A4A1",
"W\$    c #C6C4C3",
"X\$    c #8F8E8D",
"Y\$    c #706E6D",
"Z\$    c #BCB8B3",
"\`\$   c #DBD8D6",
" % c #B8B6B3",
".% c #B9B5B1",
"+% c #545150",
"@% c #645E5B",
"#% c #6B655F",
"\$%    c #413B37",
"%% c #9F9895",
"&% c #C3C2C1",
"*% c #86837F",
"=% c #BDB9B5",
"-% c #BFBBB7",
";% c #8E8987",
">% c #9D9A96",
",% c #989593",
"'% c #2C2B2A",
")% c #363737",
"!% c #837D7B",
"~% c #989492",
"{% c #928D8B",
"]% c #ABA4A1",
"^% c #BBB4B2",
"/% c #9C9693",
"(% c #AAA3A0",
"_% c #635C57",
":% c #7D7571",
"<% c #423632",
"[% c #464545",
"}% c #BDB8B7",
"|% c #E6E4E3",
"1% c #C8C5C4",
"2% c #504E4E",
"3% c #51504E",
"4% c #918E88",
"5% c #D6D3D0",
"6% c #D7D5D2",
"7% c #6C635D",
"8% c #766D66",
"9% c #6D6761",
"0% c #524B46",
"a% c #7B7774",
"b% c #D0CECC",
"c% c #817C78",
"d% c #9D9C99",
"e% c #8F8A87",
"f% c #BEB9B4",
"g% c #989591",
"h% c #928E8A",
"i% c #AEAAA6",
"j% c #A29C97",
"k% c #2B2725",
"l% c #232221",
"m% c #837A75",
"n% c #9D9896",
"o% c #9F9A96",
"p% c #ABA8A5",
"q% c #8D8884",
"r% c #75706E",
"s% c #756F6C",
"t% c #5B5653",
"u% c #C2BFBE",
"v% c #666260",
"w% c #6B615C",
"x% c #6C615C",
"y% c #302927",
"z% c #514845",
"A% c #C7C2C1",
"B% c #B7B5B2",
"C% c #928E8B",
"D% c #76716D",
"E% c #CAC7C1",
"F% c #D0CECA",
"G% c #D4D4D0",
"H% c #9B948F",
"I% c #5B5552",
"J% c #8A837E",
"K% c #615750",
"L% c #7A746F",
"M% c #CDCAC8",
"N% c #898583",
"O% c #A09F9D",
"P% c #8C8D89",
"Q% c #7A7571",
"R% c #847D7A",
"S% c #C5C3C0",
"T% c #989490",
"U% c #201D1C",
"V% c #242323",
"W% c #87817E",
"X% c #B8B6B4",
"Y% c #68625F",
"Z% c #7C7976",
"\`%    c #706D68",
" & c #797573",
".& c #6E6A67",
"+& c #6D6A69",
"@& c #52504E",
"#& c #BDB8B6",
"\$&    c #817975",
"%& c #726661",
"&& c #463B37",
"*& c #2C2726",
"=& c #938882",
"-& c #D1CDCA",
";& c #525150",
">& c #9F9792",
",& c #DBD6D3",
"'& c #9D9A97",
")& c #68605A",
"!& c #544C47",
"~& c #5C524B",
"{& c #5A5552",
"]& c #C7C3C0",
"^& c #6C6662",
"/& c #504B46",
"(& c #605C59",
"_& c #706D69",
":& c #918A88",
"<& c #97918E",
"[& c #9E9A99",
"}& c #9D9B9A",
"|& c #2B2929",
"1& c #403D3B",
"2& c #8D8885",
"3& c #8F8785",
"4& c #A19B99",
"5& c #9E9896",
"6& c #8F8A88",
"7& c #565250",
"8& c #4A4442",
"9& c #454341",
"0& c #625F5E",
"a& c #B1ADAB",
"b& c #5E5551",
"c& c #635650",
"d& c #25201F",
"e& c #746E68",
"f& c #BCB8B4",
"g& c #D6D3D1",
"h& c #8B8583",
"i& c #5C5855",
"j& c #B2AEAB",
"k& c #B7B6B3",
"l& c #77716D",
"m& c #36302E",
"n& c #564B46",
"o& c #676360",
"p& c #ACA9A6",
"q& c #7A7574",
"r& c #696868",
"s& c #6C6866",
"t& c #A09D9A",
"u& c #A19F9C",
"v& c #B7B1AD",
"w& c #928B87",
"x& c #524945",
"y& c #504742",
"z& c #453F3A",
"A& c #59514C",
"B& c #585552",
"C& c #817D79",
"D& c #3E3734",
"E& c #463D39",
"F& c #38302D",
"G& c #7E7975",
"H& c #A8A4A2",
"I& c #ADAAA7",
"J& c #8E8C8A",
"K& c #757271",
"L& c #928A86",
"M& c #6E6C6B",
"N& c #9F9C9A",
"O& c #635D5B",
"P& c #3E3635",
"Q& c #272421",
"R& c #88817B",
"S& c #C3C1BD",
"T& c #C9C7C5",
"U& c #5F5E5D",
"V& c #333231",
"W& c #7B7775",
"X& c #C4C0BD",
"Y& c #A4A09C",
"Z& c #4F4A46",
"\`&    c #3C3432",
" * c #666564",
".* c #A5A19F",
"+* c #9B9A99",
"@* c #8A8786",
"#* c #7C7875",
"\$*    c #837E7C",
"%* c #575656",
"&* c #4C4A48",
"** c #353130",
"=* c #504844",
"-* c #7F7875",
";* c #807A77",
">* c #6E6C69",
",* c #605C5A",
"'* c #5F5D5D",
")* c #827C78",
"!* c #726C68",
"~* c #746D67",
"{* c #49423E",
"]* c #3B3736",
"^* c #474544",
"/* c #5D5B5A",
"(* c #8B8684",
"_* c #959290",
":* c #817E7C",
"<* c #989391",
"[* c #565150",
"}* c #362F2D",
"|* c #5A544F",
"1* c #AFACA7",
"2* c #B2B0AE",
"3* c #D0CDCA",
"4* c #BCB9B4",
"5* c #6F6E6D",
"6* c #BEBCB9",
"7* c #BBB6B3",
"8* c #A6A19D",
"9* c #696461",
"0* c #2C2724",
"a* c #393430",
"b* c #7C7876",
"c* c #6D6C6B",
"d* c #424040",
"e* c #463F3C",
"f* c #48423F",
"g* c #48403C",
"h* c #504843",
"i* c #534C47",
"j* c #4A4340",
"k* c #5E5956",
"l* c #6F6D6B",
"m* c #7D7C79",
"n* c #676462",
"o* c #777574",
"p* c #6A6765",
"q* c #807F7D",
"r* c #65615F",
"s* c #7A7774",
"t* c #3E3631",
"u* c #2C2725",
"v* c #3A3736",
"w* c #514F4D",
"x* c #716E6B",
"y* c #6B6562",
"z* c #483B33",
"A* c #382F2C",
"B* c #605B58",
"C* c #B6B2AD",
"D* c #D3D2CE",
"E* c #DEDEDB",
"F* c #7E7C79",
"G* c #4A4745",
"H* c #A59F9C",
"I* c #BFBAB6",
"J* c #CFCDCC",
"K* c #9C9995",
"L* c #332F2B",
"M* c #4F4843",
"N* c #4B4440",
"O* c #3F3634",
"P* c #514A46",
"Q* c #5C5652",
"R* c #6D6965",
"S* c #726F6C",
"T* c #5A5652",
"U* c #534C49",
"V* c #5B5654",
"W* c #73706E",
"X* c #64605F",
"Y* c #5C5C5C",
"Z* c #504F4D",
"\`*    c #54514F",
" = c #595451",
".= c #3A3633",
"+= c #3C3634",
"@= c #39322F",
"#= c #6D6865",
"\$=    c #5D5752",
"%= c #615752",
"&= c #39312E",
"*= c #3B3432",
"== c #322D2B",
"-= c #524540",
";= c #60564D",
">= c #3A3432",
",= c #78726D",
"'= c #ACA8A7",
")= c #ADAAAA",
"!= c #B7B6B5",
"~= c #3D3D3D",
"{= c #817F7E",
"]= c #D2CFCD",
"^= c #ADAAA8",
"/= c #C7C4C4",
"(= c #BDBAB8",
"_= c #3D3937",
":= c #242220",
"<= c #32302E",
"[= c #413F3E",
"}= c #353230",
"|= c #34302F",
"1= c #383533",
"2= c #43403E",
"3= c #33302F",
"4= c #3C3836",
"5= c #3A3532",
"6= c #494542",
"7= c #403C3A",
"8= c #282422",
"9= c #2F2A29",
"0= c #292524",
"a= c #342E2B",
"b= c #231F1D",
"c= c #282523",
"d= c #353434",
"e= c #383635",
"f= c #343230",
"g= c #302D2A",
"h= c #423E3C",
"i= c #302C2A",
"j= c #2F2C2A",
"k= c #23201F",
"l= c #484240",
"m= c #9C9998",
"n= c #B1AEAD",
"o= c #ADABAB",
"p= c #636363",
"q= c #B8B0AD",
"r= c #939191",
"s= c #C1C0BF",
"t= c #B1B0AF",
"u= c #8A8481",
"v= c #726F6D",
"w= c #7C7978",
"x= c #736D6B",
"y= c #858380",
"z= c #85817F",
"A= c #8F8B88",
"B= c #A7A4A1",
"C= c #969492",
"D= c #A3A19F",
"E= c #9B9692",
"F= c #969392",
"G= c #979390",
"H= c #A09C9A",
"I= c #9A9591",
"J= c #95908E",
"K= c #96928E",
"L= c #9C9997",
"M= c #848381",
"N= c #9F9B98",
"O= c #BEBAB7",
"P= c #938F8D",
"Q= c #8B8785",
"R= c #807D7C",
"S= c #918C89",
"T= c #827D7C",
"U= c #AFABA9",
"V= c #BEBAB8",
"W= c #AFABAA",
"X= c #ADACAB",
"Y= c #928F8E",
"Z= c #A5A4A3",
"\`=    c #848485",
" - c #72706E",
".- c #ACA9A7",
"+- c #767474",
"@- c #82807F",
"#- c #939190",
"\$-    c #7F7F7E",
"%- c #9E9D9C",
"&- c #A7A7A7",
"*- c #999897",
"=- c #B0B2B3",
"-- c #A4A4A4",
";- c #9F9D9D",
">- c #B0ADAB",
",- c #969595",
"'- c #AEACAA",
")- c #B3B4B2",
"!- c #B4B2B1",
"~- c #AAAAA9",
"{- c #B6B3B2",
"]- c #ADADAC",
"^- c #A19F9E",
"/- c #A8A5A2",
"(- c #8E8D8C",
"_- c #BCBAB8",
":- c #908C8B",
"<- c #A3A09F",
"[- c #BBB9B7",
"}- c #8E8A88",
"|- c #98918F",
"1- c #7D7A79",
"2- c #8E8A89",
"3- c #858281",
"4- c #BAB7B5",
"5- c #5E5D5D",
"6- c #6B6C6C",
"7- c #898584",
"8- c #9A9897",
"9- c #A2A2A3",
"0- c #CBC8C7",
"a- c #B7B7B6",
"b- c #D2D1D0",
"c- c #BEBDBC",
"d- c #A7A8A7",
"e- c #B7B6B6",
"f- c #BDBBBB",
"g- c #C3C3C3",
"h- c #979593",
"i- c #A6A6A6",
"j- c #A3A19E",
"k- c #A0A1A1",
"l- c #9D9C9B",
"m- c #ABAAA9",
"n- c #908D8D",
"o- c #9A9797",
"p- c #B9B5B4",
"q- c #A7A4A3",
"r- c #A09C9B",
"s- c #C7C6C5",
"t- c #B0ADAC",
"u- c #A39E9C",
"v- c #A39F9E",
"w- c #C8C4C1",
"x- c #CAC8C6",
"y- c #ABA8A6",
"z- c #B3AFAE",
"A- c #959291",
"B- c #B1AFAF",
"C- c #6F6E6E",
"D- c #8A8888",
"E- c #818282",
"F- c #838483",
"G- c #656160",
"H- c #676463",
"I- c #9B9B9A",
"J- c #8D8D8C",
"K- c #898A8A",
"L- c #7D7D7D",
"M- c #4F5052",
"N- c #676665",
"O- c #837F7E",
"P- c #848382",
"Q- c #82817E",
"R- c #848280",
"S- c #6D6C6A",
"T- c #595856",
"U- c #676464",
"V- c #555352",
"W- c #747371",
"X- c #7A7979",
"Y- c #828180",
"Z- c #878685",
"\`-    c #757372",
" ; c #72706F",
".; c #7C7B7A",
"+; c #5E5B5A",
"@; c #6B6969",
"#; c #686664",
"\$;    c #656361",
"%; c #8D8B89",
"&; c #847F7D",
"*; c #7E7B7A",
"=; c #81807F",
"-; c #AAAAA8",
"                                                                                                ",
"                                                                                                ",
"                                                                                                ",
"                                          . + @ # \$ %                                           ",
"                                          & * = - ; >                                           ",
"                                        , ' ) ! ~ { ]                                           ",
"                                      ^ / ( _ : < [ ~ }                                         ",
"                                      | 1 2 3 4 5 6 7 8 9                                       ",
"                                    0 a b c d e ' f g = h                                       ",
"                                    i j ! k l m n o p q r \$                                     ",
"                                  s t u v w x y z A B C D E F                                   ",
"                                  G ' < H I J K L M N O P Q R                                   ",
"                                S T e U V W X Y Z \`  ...+.@.#.                                  ",
"                                \$.%.&.*.=.-.;.>.,.'.).!.~.{.].^.                                ",
"                              /.(._.v :.<.[.}.|.1.2.3.4.5.6.7.8.9.                              ",
"                              0.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.                              ",
"                            r.s.t.u.v.w.x.y.z.A.B.0.C.D.E.F.G.H.u.I.                            ",
"                            J.K.L.M.N.O.P.Q.R.S.T.U.V.W.X.Y.Z.\`. +.+                            ",
"                          ++@+#+\$+%+&+*+=+-+;+>+,+'+)+!+~+{+]+^+/+(+_+                          ",
"                        :+<+[+}+|+1+2+3+4+5+6+7+8+9+0+a+b+c+d+e+f+g+h+                          ",
"                        i+j+k+l+m+n+i+o+p+q+r+s+t+>+6.u+v+,.w+x+y+z+A+B+                        ",
"                      C+&.D+E+F+G+H+I+P.J+K+L+M+N+O+P+Q+R+S+T+U+V+W+X+Y+                        ",
"                      Z+\`+ @.@+@@@#@\$@%@&@*@=@-@;@>@,@'@)@!@~@{@]@^@/@*.(@                      ",
"                    _@:@{ <@[@}@|@1@2@3@4@5@6@7@8@9@0@a@b@c@/.d@e@f@g@H h@                      ",
"                    i@j@k@l@m@n@o@p@q@r@s@t@u@v@w@x@y@z@A@B@C@D@E@F@G@v H@I@                    ",
"                  J@K@t.~.L@M@N@O@P@Q@T.R@S@T@U@V@W@X@Y@Z@\`@ #.#+#@#u.##\$#%#                    ",
"                &#*#=#-#;#>#,#'#)#!#~#{#]#^#H@/#(#p \`@_#:#v+<#[#}#|#1#2#3#4#5#                  ",
"                6#7#8#9#0#a#b#c#d#e#f#g#h#i#j#k#R@l#m#n#o#p#q#r#s#t#u#v#w#x#y#z#                ",
"              A#B#C#D#'+E#~@F#G#H#I#J#K#L#M#N#O#P#Q#R#j#S#T#U#V#W#X#Y#Z#\`# \$z+.\$+\$              ",
"              @\$#\$\$\$;+%\$&\$*\$=\$-\$;\$! *@>\$,\$'\$)\$!\$~\${\$]\$^\$/\$(\$_\$:\$<\$[\$}\$|\$1\$2\$y+3\$3               ",
"            4\$5\$6\$7\$8\$9\$0\$a\$b\$x.c\$d\$v+e\$f\$g\$h\$i\$j\$k\$l\$m\$n\$o\$8.p\$q\$r\$s\$t\$u\$v\$w\$4#x\$B+            ",
"            p@t y\$@.8.z\$A\$B\$C\$D\$E\$F\$G\$E H\$z@I\$J\$K\$L\$M\$\`@N\$O\$P\$Q\$R\$S\$T\$U\$J\$V\$W\$h@d X\$            ",
"          Y\$Z\$\`\$ %.%+%@%#%\$%%%&%*%=%-%;%>%+@,%'%)%!%~%{%]%I\$^%/%|+(%_%:%<%[%~%}%|%1%2%          ",
"        3%4%5%6%/\$7%8%9%0%a%b%c%d%e%f%g%h%i%j%k%l%m%n%o%p%q%r%s%t%u%v%w%x%y%z%+.A%B%C%          ",
"        D%E%F%G%H%I%J%K%L%M%+\$N%O%P%Q%R%r.S%T%U%V%W%X%Y%Z%\`% &.&+&@&#&\$&%&&&*&=&2#-&\$+;&        ",
"      S+>&,&j@'&)&!&~&{&]&)#^&/&(&_&:&<&[&Y@}&|&1&2&3&4&5&6&7&8&N#9&0&a&b&c&d&e&f&g&\$+h&        ",
"      i&j&]&k&l&m&n&o&p&q&r&s&t&u&v&w&x&y&z&A&B&C&,.D&E&F&G&H&I&J&K&L&M&N&O&P&Q&R&S&3#T&U&      ",
"    V&W&X&(\$Y&Z&\`& *.*+*@*#*\$*%*&***t\$=*-*;*>*,*'*^#)*!*~*{*]*^*/*Z%(*_*:*<*[*}*|*1*2*3*4*      ",
"    5*6*7*8*9*0*a*b*m.c*d*e*f*g*h*i*j*k*i+l*m*n*t@o*p*q*r*U@s*c@n t*u*v*w*x*y*z*A*B*C*D*E*F*    ",
"  G*H*! I*J*K*L*M*N*O*P*Q*R*S*c@Q*T*U*V*W*X*Y*Z*\`*@& =r@.=+=@=i\$#=\$=%=&=*===-=;=>=,='=Y@)=!=~=  ",
"  {=]=^=/=e (=_=:=<=[=}=**|=1=2=3=4=5=[.6=7=8=i#9=0=a=e.b=c=d=e=f=g=h=i=j=N#x k=l=C m=n=B#o=p=  ",
"  !#q=r=]@s=t=d\$u=v=w=x=0.y=R 0.z=A=B=C=D=E=,%F=G=H=I=2&J=K=L=M=_*N=O=P=Q=R=S=T=U=V=W=X=Y=Z=\`=  ",
"   -.-+-@-#-\$-h\$%-&-*-=---;-+@>-7\$,-\$\$&-J*'-)-!-~-{-]-^-n=<@/-(-_-:-<-U [-t=}-|-1-/#H=2-3-4-5-  ",
"    6-B+7-8-9-&.L.0-a-b-c-d-e-f-g-U.h-i-!-j-k-h.l-m-n-<+o-p-= q-r-s-t-O=6.u-v-w-x-y-z-Q A-B-    ",
"      C-D-E-F-\$ G-H-I-J-K-L-M-N-O-M+P-Q-R-i+S-0&T-U-V-W-X-Y-Z-\`- ;.;M&+;@;#;\$;%;&;*;=;t&-;      ",
"                                                                                                ",
"                                                                                                ",
"                                                                                                "};
_EOF_
}