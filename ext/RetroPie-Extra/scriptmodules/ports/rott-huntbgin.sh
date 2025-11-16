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

rp_module_id="rott-huntbgin"
rp_module_desc="Source Port for Rise of the Triad The Hunt Begins (Shareware)\n \nMaster Branch (Bullseye+):\nhttps://github.com/LTCHIPS/rottexpr.git\n \nLegacy Branch (Buster-):\nhttps://github.com/RapidEdwin08/RoTT"
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
rp_module_help="Location of ROTT Shareware files:\n$romdir/ports/rott-huntbgin"
rp_module_section="exp"
rp_module_flags="!mali"

function depends_rott-huntbgin() {
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

function sources_rott-huntbgin() {
    gitPullOrClone
}

function build_rott-huntbgin() {
    if [[ "$__os_debian_ver" -le 10 ]]; then
        sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/rott/Makefile"
        sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
        make clean
        make -j"$(nproc)" rott-huntbgin
        make -j"$(nproc)" rott-huntbgin
        make -j"$(nproc)" rott-huntbgin
        md_ret_require=("$md_build/rott-huntbgin")
    else
        sed -i 's/SHAREWARE   ?= 0/SHAREWARE   ?= 1/g' "$md_build/src/Makefile"
        #sed -i 's/SUPERROTT   ?= 1/SUPERROTT   ?= 0/g' "$md_build/rott/Makefile"
        cd src
        make -j"$(nproc)" rott
        md_ret_require=("$md_build/src/rott")
    fi
}

function install_rott-huntbgin() {
    if [[ "$__os_debian_ver" -le 10 ]]; then local rott_bin="rott-huntbgin"; else local rott_bin="src/rott"; fi
    md_ret_files=(
           "$rott_bin"
    )
}

function game_data_rott-huntbgin() {
    if [[ ! -f "$romdir/ports/rott-huntbgin/HUNTBGIN.WAD" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/ports/rott-huntbgin-rp-assets.tar.gz" "$romdir/ports/rott-huntbgin"
    fi
}

function remove_rott-huntbgin() {
    local shortcut_name
    shortcut_name="Rise Of The Triad Hunt Begins"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/ports/$shortcut_name (Shareware).sh"
}

function gui_rott-huntbgin() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      Get Additional Desktop Shortcuts + Icons\n\nGet Desktop Shortcuts for Additional Episodes + Add-Ons that may not have been present at Install\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "Get Shortcuts + Icons" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            game_data_rott-huntbgin
            shortcuts_icons_rott-huntbgin
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_rott-huntbgin() {
    mkRomDir "ports/rott-huntbgin"
    chown -R $__user:$__user "$romdir/ports/rott-huntbgin"
    moveConfigDir "$home/.rott" "$md_conf_root/rott"

    if [[ "$__os_debian_ver" -le 10 ]]; then local rott_bin="rott-huntbgin"; else local rott_bin="src/rott"; fi
    local script="$md_inst/$md_id.sh"
    #create buffer script for launch
 cat > "$script" << _EOF_
#!/bin/bash
# Detect/Run ROTT P0RT
rottROMdir="\$HOME/RetroPie/roms/ports/rott" #rottexpr
if [[ -d "\$HOME/RetroPie/roms/ports/rott-huntbgin" ]]; then rottROMdir="\$HOME/RetroPie/roms/ports/rott-huntbgin"; fi #rott/rottexpr

rottBIN=/opt/retropie/ports/rott-huntbgin/rott # rottexpr
if [[ -f /opt/retropie/ports/rott-huntbgin/rott-huntbgin ]]; then rottBIN=/opt/retropie/ports/rott-huntbgin/rott-huntbgin; fi #rott

pushd "\$rottROMdir"
"\$rottBIN" \$*
popd
_EOF_
    chmod 755 "$script"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    if (isPlatform "rpi") && [[ "$__os_debian_ver" -le 10 ]]; then launch_prefix="XINIT:"; fi
    addPort "$md_id" "rott-huntbgin" "Rise Of The Triad The Hunt Begins (Shareware)" "$launch_prefix$script"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        addPort "$md_id+qjoypad" "rott-huntbgin" "Rise Of The Triad The Hunt Begins (Shareware)" "$launch_prefix$md_inst/rott-huntbgin-qjoy.sh"
    fi

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
Weaponscale           336

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
DefaultPlayerCharacter   0

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
DefaultPlayerCharacter   0

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
    if [[ ! -f "$md_conf_root/rott/config.rot" ]]; then
        cp "$md_inst/config.rot" "$md_conf_root/rott/config.rot"
        chown $__user:$__user "$md_conf_root/rott/config.rot"
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
    if [[ ! -f "$md_conf_root/rott/sound.rot" ]]; then
        cp "$md_inst/sound.rot" "$md_conf_root/rott/sound.rot"
        chown $__user:$__user "$md_conf_root/rott/sound.rot"
    fi

   cat >"$md_inst/rott-huntbgin-qjoy.sh" << _EOF_
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
if [[ -d "\$HOME/RetroPie/roms/ports/rott-huntbgin" ]]; then rottROMdir="\$HOME/RetroPie/roms/ports/rott-huntbgin"; fi #rott/rottexpr

rottBIN=/opt/retropie/ports/rott-huntbgin/rott # rottexpr
if [[ -f /opt/retropie/ports/rott-huntbgin/rott-huntbgin ]]; then rottBIN=/opt/retropie/ports/rott-huntbgin/rott-huntbgin; fi #rott

pushd "\$rottROMdir"
"\$rottBIN" \$*
popd

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1

# Restart qjoypad IF DTWPID qjoypad@Desktop is Enabled + startx is running
if [[ -f /etc/xdg/autostart/qjoypad-start.desktop ]] && pgrep -f startx &> /dev/null 2>&1; then qjoypad-start > /dev/null 2>&1; fi

exit 0
_EOF_
    chmod 755 "$md_inst/rott-huntbgin-qjoy.sh"

    [[ "$md_mode" == "remove" ]] && remove_rott-huntbgin
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && game_data_rott-huntbgin
    [[ "$md_mode" == "install" ]] && shortcuts_icons_rott-huntbgin
}

function shortcuts_icons_rott-huntbgin() {
    local exec_name="$md_inst/$md_id.sh"
    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then exec_name=$md_inst/$md_id-qjoy.sh; fi
    local shortcut_name
    shortcut_name="Rise Of The Triad Hunt Begins"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=RoTT Hunt Begins
Exec=$exec_name
Icon=$md_inst/ROTTHB_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=D2;ROTT;Hunt;Begins
StartupWMClass=RiseOfTheTriadHuntBegins
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/ROTTHB_48x48.xpm" << _EOF_
/* XPM */
static char * ROTTHB_48x48_xpm[] = {
"48 48 200 2",
"   c None",
".  c #FF8700",
"+  c #F6820C",
"@  c #B7603D",
"#  c #F6820F",
"\$     c #432056",
"%  c #B8603D",
"&  c #00005B",
"*  c #F6820D",
"=  c #442056",
"-  c #B9603D",
";  c #F7820D",
">  c #462156",
",  c #BA613C",
"'  c #361957",
")  c #944C48",
"!  c #C76A35",
"~  c #F7820C",
"{  c #482256",
"]  c #0F045A",
"^  c #EB9018",
"/  c #BB623B",
"(  c #683451",
"_  c #FAAC00",
":  c #F7830C",
"<  c #492356",
"[  c #AC5941",
"}  c #F8BD00",
"|  c #BC623B",
"1  c #01005B",
"2  c #D9722A",
"3  c #F6CC00",
"4  c #F6CD00",
"5  c #F7830B",
"6  c #4B2456",
"7  c #2F1557",
"8  c #F88608",
"9  c #F4D900",
"0  c #8B474B",
"a  c #FD9600",
"b  c #F3DF00",
"c  c #4B2455",
"d  c #C26538",
"e  c #FBAA00",
"f  c #BE633B",
"g  c #06025A",
"h  c #E87B1D",
"i  c #F9BB00",
"j  c #F8830A",
"k  c #4D2555",
"l  c #5A2C53",
"m  c #FD8600",
"n  c #F6CA00",
"o  c #BD633A",
"p  c #A55644",
"q  c #FF8800",
"r  c #F4D800",
"s  c #F8830C",
"t  c #4E2655",
"u  c #D36F2E",
"v  c #FE9400",
"w  c #F3DE00",
"x  c #BE633A",
"y  c #210D58",
"z  c #F5820D",
"A  c #FBA700",
"B  c #F88309",
"C  c #4F2655",
"D  c #80414D",
"E  c #F9B900",
"F  c #BF643A",
"G  c #BC623C",
"H  c #F7C800",
"I  c #F9840B",
"J  c #502755",
"K  c #02015B",
"L  c #E37822",
"M  c #F5D600",
"N  c #C06439",
"O  c #FC8601",
"P  c #FE9100",
"Q  c #F98408",
"R  c #522855",
"S  c #914B48",
"T  c #FD9900",
"U  c #F3DD00",
"V  c #C16539",
"W  c #1B0A5A",
"X  c #C96A34",
"Y  c #FCA500",
"Z  c #F4DC00",
"\`     c #FCA600",
" . c #F9840A",
".. c #532854",
"+. c #B45E3D",
"@. c #FD9E00",
"#. c #512755",
"\$.    c #C16538",
"%. c #0B035B",
"&. c #FBAB00",
"*. c #E8811F",
"=. c #5B2D54",
"-. c #B35D3F",
";. c #FD8601",
">. c #FD9700",
",. c #0A035B",
"'. c #542955",
"). c #B25D3E",
"!. c #FAB200",
"~. c #F6CF00",
"{. c #EF8818",
"]. c #6A3552",
"^. c #A25444",
"/. c #FC8603",
"(. c #C26539",
"_. c #A45543",
":. c #FAAB02",
"<. c #FAB000",
"[. c #D06D2E",
"}. c #08025B",
"|. c #954D48",
"1. c #F98409",
"2. c #552A54",
"3. c #F9A402",
"4. c #F5D500",
"5. c #F79F08",
"6. c #AC5940",
"7. c #17075A",
"8. c #F79D08",
"9. c #F5D400",
"0. c #C26638",
"a. c #85444C",
"b. c #F79D07",
"c. c #F4DB00",
"d. c #F8C100",
"e. c #E07E26",
"f. c #693452",
"g. c #E07C26",
"h. c #F8BF00",
"i. c #562A54",
"j. c #773C50",
"k. c #F5960E",
"l. c #F7A507",
"m. c #B15C3F",
"n. c #200C5A",
"o. c #F8A107",
"p. c #F5960D",
"q. c #C46638",
"r. c #663352",
"s. c #F18F14",
"t. c #F4D600",
"u. c #F7C700",
"v. c #E38423",
"w. c #6F3850",
"x. c #E48023",
"y. c #F8C200",
"z. c #FA8407",
"A. c #582B54",
"B. c #552955",
"C. c #EC881B",
"D. c #F6CE00",
"E. c #F7AC04",
"F. c #B55F3D",
"G. c #250F59",
"H. c #F8A504",
"I. c #F6CB00",
"J. c #C36637",
"K. c #432057",
"L. c #E68121",
"M. c #F9BA00",
"N. c #E48921",
"O. c #753B4F",
"P. c #E58321",
"Q. c #462157",
"R. c #FA8408",
"S. c #592C54",
"T. c #321658",
"U. c #DE7627",
"V. c #FA9804",
"W. c #BA643B",
"X. c #2B1259",
"Y. c #FB8E04",
"Z. c #DF7527",
"\`.    c #C56737",
" + c #250F5A",
".+ c #D6702D",
"++ c #E97B1F",
"@+ c #7A3E4E",
"#+ c #592B54",
"\$+    c #10045A",
"%+ c #C76834",
"&+ c #BF6439",
"*+ c #07025B",
"=+ c #A05341",
"-+ c #5C2D53",
";+ c #371956",
">+ c #341758",
",+ c #C66836",
"'+ c #CF6D2D",
")+ c #BE6438",
"                                              . .                                               ",
"                                              . .                                               ",
"                                            . + + .                                             ",
"                                            . @ @ .                                             ",
"                                          . # \$ \$ # .                                           ",
"                                          . % & & % .                                           ",
"                                        . * = & & = * .                                         ",
"                                        . - & & & & - .                                         ",
"                                      . ; > & & & & > ; .                                       ",
"                                      . , & & ' ' & & , .                                       ",
"                                    . + > & & ) ) & & > + .                                     ",
"                                    . , & & & ! ! & & & , .                                     ",
"                                  . ~ { & & ] ^ ^ ] & & { ~ .                                   ",
"                                  . / & & & ( _ _ ( & & & / .                                   ",
"                                . : < & & & [ } } [ & & & < : .                                 ",
"                                . | & & & 1 2 3 4 2 1 & & & | .                                 ",
"                              . 5 6 & & & 7 8 9 9 8 7 & & & 6 5 .                               ",
"                              . | & & & & 0 a b b a 0 & & & & | .                               ",
"                            . : c & & & & d e b b e d & & & & c : .                             ",
"                            . f & & & & g h i b b i h g & & & & f .                             ",
"                          . j k & & & & l m n b b n m l & & & & k j .                           ",
"                          . o & & & & & p q r b b r q p & & & & & o .                           ",
"                        . s t & & & & & u v w b b w v u & & & & & t s .                         ",
"                        . x & & & & & y z A b b b b A z y & & & & & x .                         ",
"                      . B C & & & & & D . E b b b b E . D & & & & & C B .                       ",
"                      . F & & & & & & G . H b b b b H . G & & & & & & F .                       ",
"                    . I J & & & & & K L q M b b b b M q L K & & & & & J I .                     ",
"                    . N & & & & & & k O P w b b b b w P O k & & & & & & N .                     ",
"                  . Q R & & & & & & S . T U b b b b U T . S & & & & & & R Q .                   ",
"                  . V & & & & & & & W X . Y Z b b Z \` . X W & & & & & & & V .                   ",
"                .  ...& & & & & & ] +.J | . @.9 9 @.. | #.+.] & & & & & & .. ..                 ",
"                . \$.& & & & & & %.\$.&.*.=.-.;.>.>.;.-.=.*.&.\$.,.& & & & & & \$..                 ",
"              . Q '.& & & & & & ).!.w ~.{.].^././.^.].{.~.w !.).& & & & & & '.Q .               ",
"              . (.& & & & & 1 _.:.w b w <.[.}.|.|.}.[.<.w b w :._.1 & & & & & (..               ",
"            . 1.2.& & & & & |.3.U b 4.5.6.7.& & & & 7.6.8.9.b U 3.|.& & & & & 2.1..             ",
"            . 0.& & & & & a.b.c.b d.e.f.& & & & & & & & f.g.h.w c.b.a.& & & & & 0..             ",
"          . Q i.& & & & j.k.9 r l.m.n.& & & & & & & & & & n.m.o.M 9 p.j.& & & & i.Q .           ",
"          . q.& & & & r.s.t.u.v.w.& & & & & & & & & & & & & & w.x.y.M s.r.& & & & q..           ",
"        . z.A.& & & B.C.D.E.F.G.& & & & & & & & & & & & & & & & G.F.H.I.C.B.& & & A.z..         ",
"        . J.& & & K.L.M.N.O.& & & & & & & & & & & & & & & & & & & & O.P.!.L.Q.& & & J..         ",
"      . R.S.& & T.U.V.W.X.& & & & & & & & & & & & & & & & & & & & & & X./ Y.Z.T.& & S.R..       ",
"      . \`.& &  +.+++@+& & & & & & & & & & & & & & & & & & & & & & & & & & @+++.+G.& & \`..       ",
"    . z.#+& \$+%+&+T.& & & & & & & & & & & & & & & & & & & & & & & & & & & & T.&+%+\$+& #+z..     ",
"    . \`.& *+=+D & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & D =+*+& \`..     ",
"  . R.-+& ;+>+& & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & >+;+& -+R..   ",
"  . ,+& & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & & ,+.   ",
". . '+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+)+'+. . ",
". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . "};
_EOF_
}
