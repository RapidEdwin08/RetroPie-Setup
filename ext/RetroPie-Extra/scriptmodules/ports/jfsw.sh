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

rp_module_id="jfsw"
rp_module_desc="Shadow Warrior Source Port by Jonathon Fowler - Ken Silverman's Build Engine"
rp_module_help="Place Game files in [ports/ksbuild/shadowwarrior]:\n$romdir/ports/ksbuild/shadowwarrior \n \n[Shadow Warrior]: sw.grp  sw.rts\n \n[Wanton Destruction]: wantdest.grp\n \n[Twin Dragon]: tdragon.zip (Leave ZIP'd)\n \n NOTE: Twin Dragon might not appear in the SW Main Menu\n Select the Code of Honor Episode instead if applicable\n \n*Expansions Require the Full Version of Shadow Warrior*"
rp_module_licence="GPL https://github.com/jonof/jfsw/blob/master/GPL.TXT"
rp_module_repo="git https://github.com/jonof/jfsw.git master"
rp_module_section="exp"
rp_module_flags=""

function depends_jfsw() {
    # libsdl1.2-dev libsdl-mixer1.2-dev xorg xinit x11-xserver-utils xinit libgl1-mesa-dev libsdl2-dev libvorbis-dev rename
    local depends=(cmake build-essential libsdl2-dev libsdl2-mixer-dev flac libflac-dev libvorbis-dev libvpx-dev freepats zip unzip rename)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "gl" || isPlatform "mesa" && depends+=(libgl1-mesa-dev libglu1-mesa-dev)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_jfsw() {
    gitPullOrClone
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/jfsw/ShadowWarrior_48x48.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/jfsw/ShadowWarrior_68x68.xpm" "$md_build"
    download "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/jfsw/ShadowWarrior_70x56.xpm" "$md_build"
}

function build_jfsw() {
    local params=(DATADIR="$romdir/ports/ksbuild/shadowwarrior" RELEASE=1 WITHOUT_GTK=1)
    ( isPlatform "gl" || isPlatform "gles" ) && params+=(USE_POLYMOST=1)
    isPlatform "gl2" && params+=(USE_GL2)
    isPlatform "gl3" && params+=(USE_GL3)
    isPlatform "gles" && params+=(USE_OPENGL=USE_GLES2)
    ! ( isPlatform "gl" || isPlatform "mesa" ) && params+=(USE_POLYMOST=0 USE_OPENGL=0)
    echo [PARAMS]: ${params[@]}
    make -j"$(nproc)" "${params[@]}"
    md_ret_require="$md_build/sw"
}

function install_jfsw() {
    md_ret_files=(        
        'sw'
        'ShadowWarrior_48x48.xpm'
        'ShadowWarrior_68x68.xpm'
        'ShadowWarrior_70x56.xpm'
    )
}

function gamedata_jfsw() {
    local dest="$romdir/ports/ksbuild/shadowwarrior"
    mkUserDir "$dest"

    if [[ ! -f "$dest/sw.grp" ]]; then # Download Shareware Data from JonoF's GIT
        downloadAndExtract "https://www.jonof.id.au/files/jfsw/swsw12.zip" "$dest"
        pushd "$dest"; rename 'y/A-Z/a-z/' *; popd
    fi

    if [[ ! -f "$dest/tdragon.zip" ]] || [[ ! -f "$dest/wantdest.grp" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/scriptmodules/ports/$md_id/$md_id-rp-assets.tar.gz" "$dest"
    fi

    if [[ ! -f "$dest/sw.grp" ]]; then # Download Shareware Data from 3DRealms FTP
        local tempdir="$(mktemp -d)"
        download ftp://ftp.3drealms.com/share/3dsw12.zip "$tempdir"
        unzip -Lo "$tempdir/3dsw12.zip" swsw12.shr -d "$tempdir"
        unzip -Lo "$tempdir/swsw12.shr" sw.grp sw.rts -d "$dest"
        rm -rf "$tempdir"
        pushd "$dest"; rename 'y/A-Z/a-z/' *; popd
    fi

    chown -R $__user:$__user "$dest"
}

function remove_jfsw() {
    if [[ -f "/usr/share/applications/Shadow Warrior.desktop" ]]; then sudo rm -f "/usr/share/applications/Shadow Warrior.desktop"; fi
    if [[ -f "$home/Desktop/Shadow Warrior.desktop" ]]; then rm -f "$home/Desktop/Shadow Warrior.desktop"; fi

    if [[ -f "/usr/share/applications/Shadow Warrior Twin Dragon.desktop" ]]; then sudo rm -f "/usr/share/applications/Shadow Warrior Twin Dragon.desktop"; fi
    if [[ -f "$home/Desktop/Shadow Warrior Twin Dragon.desktop" ]]; then rm -f "$home/Desktop/Shadow Warrior Twin Dragon.desktop"; fi

    if [[ -f "/usr/share/applications/Shadow Warrior Wanton Destruction.desktop" ]]; then sudo rm -f "/usr/share/applications/Shadow Warrior Wanton Destruction.desktop"; fi
    if [[ -f "$home/Desktop/Shadow Warrior Wanton Destruction.desktop" ]]; then rm -f "$home/Desktop/Shadow Warrior Wanton Destruction.desktop"; fi
}

function configure_jfsw() {
    mkRomDir "ports/ksbuild"
    chown -R $__user:$__user "$romdir/ports/ksbuild"
    moveConfigDir "$home/.jfsw" "$md_conf_root/sw"

    local launch_prefix
    isPlatform "kms" && launch_prefix="XINIT-WM:"
    addPort "$md_id" "sw" "Shadow Warrior" "$launch_prefix$md_inst/sw %ROM%" ""
    #local gamedir="$romdir/ports/ksbuild/shadowwarrior"
    addPort "$md_id" "sw" "Shadow Warrior Twin Dragon (JFSW)" "$launch_prefix$md_inst/sw %ROM%" "-gtdragon.zip" #[[ -f "$gamedir/dragon.zip" ]] &&
    addPort "$md_id" "sw" "Shadow Warrior Wanton Destruction (JFSW)" "$launch_prefix$md_inst/sw %ROM%" "-gwantdest.grp" #[[ -f "$gamedir/wt.grp" ]] &&

    cat >"$md_inst/sw.cfg" << _EOF_
[Screen Setup]
ScreenWidth = 1920
ScreenHeight = 1080
ScreenMode = 1
ScreenBPP = 8
UseGammaBrightness = 2

[Sound Setup]
FXDevice = 0
MusicDevice = 0
NumVoices = 32
NumChannels = 2
NumBits = 16
MixRate = 44100
FXVolume = 192
MusicVolume = 128
ReverseStereo = 0
OggTrackName = "track??.ogg"

[Setup]
ForceSetup = 1

[Controls]
UseMouse = 1
UseJoystick = 1
MouseSensitivity = 32768
MouseAiming = 0
MouseButton0 = "Fire"
MouseButtonClicked0 = ""
MouseButton1 = "Strafe"
MouseButtonClicked1 = ""
MouseButton2 = "Move_Forward"
MouseButtonClicked2 = ""
MouseButton3 = ""
MouseButtonClicked3 = ""
MouseButton4 = ""
MouseButton5 = ""
MouseAnalogAxes0 = "analog_turning"
MouseDigitalAxes0_0 = ""
MouseDigitalAxes0_1 = ""
MouseAnalogScale0 = 65536
MouseAnalogAxes1 = "analog_moving"
MouseDigitalAxes1_0 = ""
MouseDigitalAxes1_1 = ""
MouseAnalogScale1 = 65536
JoystickButton0 = "Jump"
JoystickButtonClicked0 = ""
JoystickButton1 = "Open"
JoystickButtonClicked1 = ""
JoystickButton2 = "Crouch"
JoystickButtonClicked2 = ""
JoystickButton3 = "Holster_Weapon"
JoystickButtonClicked3 = ""
JoystickButton4 = "Map"
JoystickButtonClicked4 = ""
JoystickButton5 = "Toggle_Crosshair"
JoystickButtonClicked5 = ""
JoystickButton6 = "Show_Menu"
JoystickButtonClicked6 = ""
JoystickButton7 = "Run"
JoystickButtonClicked7 = ""
JoystickButton8 = "Center_View"
JoystickButtonClicked8 = ""
JoystickButton9 = "Previous_Weapon"
JoystickButtonClicked9 = ""
JoystickButton10 = "Next_Weapon"
JoystickButtonClicked10 = ""
JoystickButton11 = "AutoRun"
JoystickButtonClicked11 = ""
JoystickButton12 = "Inventory"
JoystickButtonClicked12 = ""
JoystickButton13 = "Inventory_Left"
JoystickButtonClicked13 = ""
JoystickButton14 = "Inventory_Right"
JoystickButtonClicked14 = ""
JoystickButton15 = ""
JoystickButtonClicked15 = ""
JoystickButton16 = ""
JoystickButtonClicked16 = ""
JoystickButton17 = ""
JoystickButtonClicked17 = ""
JoystickButton18 = ""
JoystickButtonClicked18 = ""
JoystickButton19 = ""
JoystickButtonClicked19 = ""
JoystickButton20 = ""
JoystickButtonClicked20 = ""
JoystickButton21 = ""
JoystickButtonClicked21 = ""
JoystickButton22 = ""
JoystickButtonClicked22 = ""
JoystickButton23 = ""
JoystickButtonClicked23 = ""
JoystickButton24 = ""
JoystickButtonClicked24 = ""
JoystickButton25 = ""
JoystickButtonClicked25 = ""
JoystickButton26 = ""
JoystickButtonClicked26 = ""
JoystickButton27 = ""
JoystickButtonClicked27 = ""
JoystickButton28 = ""
JoystickButtonClicked28 = ""
JoystickButton29 = ""
JoystickButtonClicked29 = ""
JoystickButton30 = ""
JoystickButtonClicked30 = ""
JoystickButton31 = ""
JoystickButtonClicked31 = ""
JoystickAnalogAxes0 = "analog_strafing"
JoystickDigitalAxes0_0 = ""
JoystickDigitalAxes0_1 = ""
JoystickAnalogScale0 = 65536
JoystickAnalogDead0 = 4096
JoystickAnalogSaturate0 = 31743
JoystickAnalogAxes1 = "analog_moving"
JoystickDigitalAxes1_0 = ""
JoystickDigitalAxes1_1 = ""
JoystickAnalogScale1 = 65536
JoystickAnalogDead1 = 4096
JoystickAnalogSaturate1 = 31743
JoystickAnalogAxes2 = "analog_turning"
JoystickDigitalAxes2_0 = ""
JoystickDigitalAxes2_1 = ""
JoystickAnalogScale2 = 32768
JoystickAnalogDead2 = 4096
JoystickAnalogSaturate2 = 31743
JoystickAnalogAxes3 = "analog_lookingupanddown"
JoystickDigitalAxes3_0 = ""
JoystickDigitalAxes3_1 = ""
JoystickAnalogScale3 = -32768
JoystickAnalogDead3 = 4096
JoystickAnalogSaturate3 = 31743
JoystickAnalogAxes4 = ""
JoystickDigitalAxes4_0 = ""
JoystickDigitalAxes4_1 = "TurnAround"
JoystickAnalogScale4 = 49152
JoystickAnalogDead4 = 1024
JoystickAnalogSaturate4 = 31743
JoystickAnalogAxes5 = ""
JoystickDigitalAxes5_0 = ""
JoystickDigitalAxes5_1 = "Fire"
JoystickAnalogScale5 = 65536
JoystickAnalogDead5 = 1024
JoystickAnalogSaturate5 = 31743
JoystickAnalogAxes6 = ""
JoystickDigitalAxes6_0 = ""
JoystickDigitalAxes6_1 = ""
JoystickAnalogScale6 = 65536
JoystickAnalogDead6 = 1024
JoystickAnalogSaturate6 = 31743
JoystickAnalogAxes7 = ""
JoystickDigitalAxes7_0 = ""
JoystickDigitalAxes7_1 = ""
JoystickAnalogScale7 = 65536
JoystickAnalogDead7 = 1024
JoystickAnalogSaturate7 = 31743
JoystickAnalogAxes8 = ""
JoystickDigitalAxes8_0 = ""
JoystickDigitalAxes8_1 = ""
JoystickAnalogScale8 = 65536
JoystickAnalogDead8 = 1024
JoystickAnalogSaturate8 = 31743
JoystickAnalogAxes9 = ""
JoystickDigitalAxes9_0 = ""
JoystickDigitalAxes9_1 = ""
JoystickAnalogScale9 = 65536
JoystickAnalogDead9 = 1024
JoystickAnalogSaturate9 = 31743
JoystickAnalogAxes10 = ""
JoystickDigitalAxes10_0 = ""
JoystickDigitalAxes10_1 = ""
JoystickAnalogScale10 = 65536
JoystickAnalogDead10 = 1024
JoystickAnalogSaturate10 = 31743
JoystickAnalogAxes11 = ""
JoystickDigitalAxes11_0 = ""
JoystickDigitalAxes11_1 = ""
JoystickAnalogScale11 = 65536
JoystickAnalogDead11 = 1024
JoystickAnalogSaturate11 = 31743

[Comm Setup]
PlayerName = "KATO"

[Options]
BorderNum = 2
Brightness = 0
BorderTile = 0
PanelScale = 5
Bobbing = 1
Tilting = 0
Shadows = 1
AutoRun = 1
Crosshair = 1
AutoAim = 1
Messages = 1
Talking = 1
Ambient = 1
FxOn = 1
MusicOn = 1
NetGameType = 0
NetLevel = 0
NetMonsters = 0
NetHurtTeammate = 0
NetSpawnMarkers = 1
NetTeamPlay = 0
NetKillLimit = 0
NetTimeLimit = 0
NetColor = 0
Voxels = 1
MouseAimingOn = 0
MouseInvert = 0
Stats = 0
Rooster = ""
Kiwi = 0
PlayCD = 0
CDDevice = 0
Chickens = 0

[KeyDefinitions]
Move_Forward = "Up" "Kpad8"
Move_Backward = "Down" "Kpad2"
Turn_Left = "Left" "Kpad4"
Turn_Right = "Right" "Kpad6"
Strafe = "LAlt" "RAlt"
Fire = "LCtrl" "RCtrl"
Open = "Space" ""
Run = "LShift" "RShift"
AutoRun = "CapLck" ""
Jump = "A" "/"
Crouch = "Z" ""
Look_Up = "PgUp" "Kpad9"
Look_Down = "PgDn" "Kpad3"
Strafe_Left = "," ""
Strafe_Right = "." ""
Aim_Up = "Home" "Kpad7"
Aim_Down = "End" "Kpad1"
Weapon_1 = "1" ""
Weapon_2 = "2" ""
Weapon_3 = "3" ""
Weapon_4 = "4" ""
Weapon_5 = "5" ""
Weapon_6 = "6" ""
Weapon_7 = "7" ""
Weapon_8 = "8" ""
Weapon_9 = "9" ""
Weapon_10 = "0" ""
Inventory = "Enter" "KpdEnt"
Inventory_Left = "[" ""
Inventory_Right = "]" ""
Med_Kit = "M" ""
Smoke_Bomb = "S" ""
Night_Vision = "N" ""
Gas_Bomb = "G" ""
Flash_Bomb = "F" ""
Caltrops = "C" ""
TurnAround = "BakSpc" ""
SendMessage = "T" ""
Map = "Tab" ""
Shrink_Screen = "-" "Kpad-"
Enlarge_Screen = "=" "Kpad+"
Center_View = "Kpad5" ""
Holster_Weapon = "ScrLck" ""
Map_Follow_Mode = "F" ""
See_Co_Op_View = "K" ""
Mouse_Aiming = "U" ""
Toggle_Crosshair = "I" ""
Next_Weapon = "'" ""
Previous_Weapon = ";" ""
Show_Menu = "" ""
Show_Console = "NumLck" ""
_EOF_
    if [[ ! -f "$home/.jfsw/sw.cfg" ]]; then
        cp "$md_inst/sw.cfg" "$home/.jfsw/sw.cfg"
        chown -R $__user:$__user "$home/.jfsw/sw.cfg"
    fi

    cat >"$md_inst/Shadow Warrior.desktop" << _EOF_
[Desktop Entry]
Name=Shadow Warrior
GenericName=Shadow Warrior
Comment=Shadow Warrior
Exec=$md_inst/sw
Icon=$md_inst/ShadowWarrior_48x48.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Shadow;Warrior
StartupWMClass=ShadowWarrior
Name[en_US]=Shadow Warrior
_EOF_
    chmod 755 "$md_inst/Shadow Warrior.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Shadow Warrior.desktop" "$home/Desktop/Shadow Warrior.desktop"; chown $__user:$__user "$home/Desktop/Shadow Warrior.desktop"; fi
    mv "$md_inst/Shadow Warrior.desktop" "/usr/share/applications/Shadow Warrior.desktop"

    cat >"$md_inst/Shadow Warrior Twin Dragon.desktop" << _EOF_
[Desktop Entry]
Name=Shadow Warrior Twin Dragon
GenericName=Shadow Warrior Twin Dragon
Comment=Shadow Warrior Twin Dragon
Exec=$md_inst/sw -gtdragon.zip
Icon=$md_inst/ShadowWarrior_68x68.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Shadow;Warrior;Twin;Dragon
StartupWMClass=ShadowWarriorTwinDragon
Name[en_US]=Shadow Warrior Twin Dragon
_EOF_
    chmod 755 "$md_inst/Shadow Warrior Twin Dragon.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Shadow Warrior Twin Dragon.desktop" "$home/Desktop/Shadow Warrior Twin Dragon.desktop"; chown $__user:$__user "$home/Desktop/Shadow Warrior Twin Dragon.desktop"; fi
    mv "$md_inst/Shadow Warrior Twin Dragon.desktop" "/usr/share/applications/Shadow Warrior Twin Dragon.desktop"

    cat >"$md_inst/Shadow Warrior Wanton Destruction.desktop" << _EOF_
[Desktop Entry]
Name=Shadow Warrior Wanton Destruction
GenericName=Shadow Warrior Wanton Destruction
Comment=Shadow Warrior Wanton Destruction
Exec=$md_inst/sw -gwantdest.grp
Icon=$md_inst/ShadowWarrior_70x56.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Shadow;Warrior;Wanton;Destruction
StartupWMClass=ShadowWarriorWantonDestruction
Name[en_US]=Shadow Warrior Wanton Destruction
_EOF_
    chmod 755 "$md_inst/Shadow Warrior Wanton Destruction.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Shadow Warrior Wanton Destruction.desktop" "$home/Desktop/Shadow Warrior Wanton Destruction.desktop"; chown $__user:$__user "$home/Desktop/Shadow Warrior Wanton Destruction.desktop"; fi
    mv "$md_inst/Shadow Warrior Wanton Destruction.desktop" "/usr/share/applications/Shadow Warrior Wanton Destruction.desktop"

    [[ "$md_mode" == "install" ]] && gamedata_jfsw
    [[ "$md_mode" == "remove" ]] && remove_jfsw
}
