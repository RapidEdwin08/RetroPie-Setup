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

rp_module_id="jftekwar"
rp_module_desc="Tek War Source Port by Jonathon Fowler - Ken Silverman's Build Engine"
rp_module_help="Place Game files in [ports/ksbuild/tekwar]:\n$romdir/ports/ksbuild/tekwar"
rp_module_licence="GPL https://github.com/jonof/jfsw/blob/master/GPL.TXT"
rp_module_repo="git https://github.com/jonof/jftekwar.git master"
rp_module_section="exp"
rp_module_flags=""

function depends_jftekwar() {
    # libsdl1.2-dev libsdl-mixer1.2-dev xorg xinit x11-xserver-utils xinit libgl1-mesa-dev libsdl2-dev libvorbis-dev rename
    local depends=(cmake build-essential libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libfluidsynth-dev libvpx-dev freepats zip unzip rename)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_jftekwar() {
    gitPullOrClone
}

function build_jftekwar() {
    local params=(DATADIR="$romdir/ports/ksbuild/tekwar" RELEASE=1 WITHOUT_GTK=1)
    ( isPlatform "gl" || isPlatform "gles" ) && params+=(USE_POLYMOST=1)
    isPlatform "gl2" && params+=(USE_GL2)
    isPlatform "gl3" && params+=(USE_GL3)
    isPlatform "gles" && params+=(USE_OPENGL=USE_GLES2)
    ! ( isPlatform "gl" || isPlatform "mesa" ) && params+=(USE_POLYMOST=0 USE_OPENGL=0)
    echo [PARAMS]: ${params[@]}
    make -j"$(nproc)" "${params[@]}"
    md_ret_require="$md_build/tekwar"
}

function install_jftekwar() {
    md_ret_files=(        
        'tekwar'
        'rsrc/game_icon.ico'
    )
}

function gamedata_jftekwar() {
    local dest="$romdir/ports/ksbuild/tekwar"
    mkUserDir "$dest"

    if [[ -f "$dest/TEKD1.EXE" ]] || [[ -f "$dest/TEKWAR.EXE" ]]; then
        pushd "$dest"; rename 'y/A-Z/a-z/' *; popd
    fi
    if [[ ! -f "$dest/tekd1.exe" ]] && [[ ! -f "$dest/tekwar.exe" ]]; then # Download Demo Data from JonoF's GIT
        downloadAndExtract "https://www.jonof.id.au/files/buildgames/tekwar.zip" "$dest"
        pushd "$dest"; rename 'y/A-Z/a-z/' *; popd
    fi
    chown -R $__user:$__user "$dest"
}

function remove_jftekwar() {
    local shortcut_name
    shortcut_name="Tek War"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
}

function gui_jftekwar() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      Get Additional Desktop Shortcuts + Icons\n\nGet Desktop Shortcuts for Additional Episodes + Add-Ons that may not have been present at Install\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "Get Shortcuts + Icons" \
        "2" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            gamedata_jftekwar
            shortcuts_icons_jftekwar
            ;;
        2)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_jftekwar() {
    mkRomDir "ports/ksbuild/tekwar"
    chown -R $__user:$__user "$romdir/ports/ksbuild"

    mkdir -p "$home/.jftekwar"
    moveConfigDir "$home/.jftekwar" "$md_conf_root/tekwar"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addPort "$md_id" "tekwar" "Tek War (jftekwar)" "$launch_prefix$md_inst/tekwar %ROM%" ""

    cat >"$md_inst/tekwar.ini" << _EOF_
; Always show configuration options on startup
;   0 - No
;   1 - Yes
forcesetup = 1

; Video mode selection
;   0 - Windowed
;   1 - Fullscreen
fullscreen = 1

; Video resolution
xdim = 1920
ydim = 1080

; Video colour depth
bpp = 8

; Renderer type
;   0  - classic
;   3  - OpenGL Polymost
renderer = 0

; Brightness setting
;   0 - lowest
;   8 - highest
brightness = 3

; Brightness setting method
;   0 - palette
;   1 - shader gamma
;   2 - system gamma
usegammabrightness = 1

; OpenGL mode options
glusetexcache = 1

; Sound sample frequency
;   0 - 6 KHz
;   1 - 8 KHz
;   2 - 11.025 KHz
;   3 - 16 KHz
;   4 - 22.05 KHz
;   5 - 32 KHz
;   6 - 44.1 KHz
;   7 - 48 KHz
samplerate = 4

; Music playback
;   0 - Off
;   1 - On
music = 1

; Enable mouse
;   0 - No
;   1 - Yes
mouse = 1

; Enable joystick
;   0 - No
;   1 - Yes
joystick = 1

; Key Settings
;  Here's a map of all the keyboard scan codes: NOTE: values are listed in hex!
; +---------------------------------------------------------------------------------------------+
; | 01   3B  3C  3D  3E   3F  40  41  42   43  44  57  58          46                           |
; |ESC   F1  F2  F3  F4   F5  F6  F7  F8   F9 F10 F11 F12        SCROLL                         |
; |                                                                                             |
; |29  02  03  04  05  06  07  08  09  0A  0B  0C  0D   0E     D2  C7  C9      45  B5  37  4A   |
; | \` '1' '2' '3' '4' '5' '6' '7' '8' '9' '0'  -   =  BACK    INS HOME PGUP  NUMLK KP/ KP* KP-  |
; |                                                                                             |
; | 0F  10  11  12  13  14  15  16  17  18  19  1A  1B  2B     D3  CF  D1      47  48  49  4E   |
; |TAB  Q   W   E   R   T   Y   U   I   O   P   [   ]    \    DEL END PGDN    KP7 KP8 KP9 KP+   |
; |                                                                                             |
; | 3A   1E  1F  20  21  22  23  24  25  26  27  28     1C                     4B  4C  4D       |
; |CAPS  A   S   D   F   G   H   J   K   L   ;   '   ENTER                    KP4 KP5 KP6    9C |
; |                                                                                      KPENTER|
; |  2A    2C  2D  2E  2F  30  31  32  33  34  35    36            C8          4F  50  51       |
; |LSHIFT  Z   X   C   V   B   N   M   ,   .   /   RSHIFT          UP         KP1 KP2 KP3       |
; |                                                                                             |
; | 1D     38              39                  B8     9D       CB  D0   CD      52    53        |
; |LCTRL  LALT           SPACE                RALT   RCTRL   LEFT DOWN RIGHT    KP0    KP.      |
; +---------------------------------------------------------------------------------------------+
keyforward = 11
keybackward = 1F
keyturnleft = CB
keyturnright = CD
keyrun = 2A
keystrafe = 28
keyfire = 9D
keyuse = 12
keyjump = 39
keycrouch = 2E
keylookup = C9
keylookdown = D1
keycentre = CF
keystrafeleft = 1E
keystraferight = 20
keymap = 0F
keyzoomin = 0D
keyzoomout = 0C
keychat = 14
keyrearview = 13
keyprepareditem = 0
keyhealthmeter = 0
keycrosshairs = 0
keyelapsedtime = 0
keyscore = 0
keyinventory = 1C
keyconceal = 1D
keylooking = 0
keyconsole = 29

; Difficulty
difficulty = 1

; Sound volume
soundvolume = 16

; Music volume
musicvolume = 16

; Mouse Button Actions
;   4 - Run
;   5 - Strafe
;   6 - Fire
;   7 - Use
;   8 - Jump
;   9 - Crouch
mousebutton1 = 6
mousebutton2 = 7

; Mouse sensitivity
mousesensitivity = 8

; Mouse look mode
;   0 - Momentary
;   1 - Toggle
mouselookmode = 0

; Mouse look enabled (if Toggle mode)
mouselook = 0

; Joystick Button Actions (see Mouse Buttons Actions above)
joystickbutton1 = 8
joystickbutton2 = 7
joystickbutton3 = 9
joystickbutton4 = 6

; Head bob
headbob = 1

; Screen size
screensize = 320

; Show reticule
showreticule = 1

; Show time
showtime = 1

; Show score
showscore = 1

; Show rear view
showrearview = 1

; Show prepared item
showprepareditem = 1

; Show health
showhealth = 1

; Show inventory
showinventory = 1
_EOF_
    if [[ ! -f "$home/.jftekwar/tekwar.ini" ]]; then
        cp "$md_inst/tekwar.ini" "$home/.jftekwar/tekwar.ini"
        chown -R $__user:$__user "$home/.jftekwar/tekwar.ini"
    fi

    [[ "$md_mode" == "remove" ]] && remove_jftekwar
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && gamedata_jftekwar
    [[ "$md_mode" == "install" ]] && shortcuts_icons_jftekwar
}

function shortcuts_icons_jftekwar() {
    local shortcut_name
    shortcut_name="Tek War"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/tekwar
Icon=$md_inst/game_icon.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Tek;War
StartupWMClass=TekWar
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
}