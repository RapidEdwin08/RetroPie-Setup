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

rp_module_id="applepi"
rp_module_desc="ApplePi is an Apple ][ emulator for Raspberry Pi OS and most other Linux distributions."
rp_module_help="ROM Extension: .2mg .po .dsk .nib .do .hdv .gz .zip\n\nCopy your roms to $romdir/apple2"
rp_module_licence="GNU https://raw.githubusercontent.com/FZBunny/applepi/refs/heads/main/LICENSE"
rp_module_repo="git https://github.com/FZBunny/applepi.git main :_get_commit_applepi"
rp_module_section="exp"
rp_module_flags=""

function _get_commit_applepi() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch_tag=main
    local branch_commit="$(git ls-remote https://github.com/FZBunny/applepi.git $branch_tag HEAD | grep $branch_tag  | tail -1 | awk '{ print $1}' | cut -c -8)"

    #echo 8cd141b5; #20250316 Added 'fixme' comment to Screen::enterEvent
    echo $branch_commit
}

function depends_applepi() {
    local depends=(qt5-qmake libasound2-dev libpulse-dev qtdeclarative5-dev libqt5gamepad5-dev qtmultimedia5-dev)
    if ( isPlatform "kms" ) && [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then depends+=(xorg matchbox-window-manager); fi
    getDepends "${depends[@]}"
}

function sources_applepi() {
    gitPullOrClone
}

function build_applepi() {
    pushd "$md_build"
    qmake -makefile applepi.pro
    make clean
    make
    popd
    md_ret_require="$md_build/bin/applepi"
}

function install_applepi() {
    md_ret_files=(
        'LICENSE'
        'HISTORY.md'
        'NOTES.md'
        'README.md'
        'bin/applepi'
    )
}

function game_data_applepi() {
    if [[ ! -f "$romdir/apple2/media/image/ApplePi.png" ]]; then
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/applepi-rp-assets.tar.gz" "$romdir/apple2"
        if [[ ! -f "$romdir/apple2/gamelist.xml" ]] && [[ ! -f "/opt/retropie/configs/all/emulationstation/gamelists/apple2/gamelist.xml" ]]; then mv "$romdir/apple2/gamelist.xml.apple2" "$romdir/apple2/gamelist.xml"; fi
        chown -R $__user:$__user "$romdir/apple2"
    fi
}

function remove_applepi() {
    local shortcut_name
    shortcut_name="ApplePi"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
    rm -f "$romdir/apple2/+Start ApplePi.do"
}

function configure_applepi() {
    mkRomDir "apple2"

    addEmulator 0 "$md_id" "apple2" "$md_inst/applepi"

    if [[ ! $(dpkg -l | grep qjoypad) == '' ]]; then
        local launch_prefix
        isPlatform "kms" && launch_prefix="XINIT-WMC:"
        addEmulator 0 "$md_id-qjoy" "apple2" "${launch_prefix}$md_inst/applepi-qjoy.sh"
    fi

    addSystem "apple2" "Apple II" ".2mg .po .dsk .nib .do .hdv .gz .zip"

    [[ "$md_mode" == "remove" ]] && remove_applepi
    [[ "$md_mode" == "remove" ]] && return

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ "$qjoyui" == '1' ]]; then
        if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'apple2_StartApplePi = "applepi-qjoy"' ; echo $?) == '1' ]]; then echo 'apple2_StartApplePi = "applepi-qjoy"' >> /opt/retropie/configs/all/emulators.cfg; fi
    else
        if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'apple2_StartApplePi = "applepi"' ; echo $?) == '1' ]]; then echo 'apple2_StartApplePi = "applepi"' >> /opt/retropie/configs/all/emulators.cfg; fi
    fi
    chown $__user:$__user /opt/retropie/configs/all/emulators.cfg

    touch "$romdir/apple2/+Start ApplePi.do"; chown -R $__user:$__user "$romdir/apple2"

    # internal_rom_number=1 for Model Apple ][+ # speaker_volume=50 # window_scale=2
    if [ ! -f $home/.config/applepi.conf ]; then cat >"$home/.config/applepi.conf" <<_EOF_; fi
[General]
check-key=DON'T DELETE THIS KEY
directory_for_slot1_print=/home/pi/RetroPie/roms/apple2
disassemble_end=0000
disassemble_end_criterion=0
disassemble_mem_type=0
disassemble_start_address=0000
floppy1_path=/home/pi/RetroPie/roms/apple2
floppy2_path=/home/pi/RetroPie/roms/apple2
game_controller_id=0
game_controller_name=/dev/input/mouse0
hd1_volume_path=/home/pi/RetroPie/roms/apple2
hd2_volume_path=/home/pi/RetroPie/roms/apple2
help_position="10,10"
help_size="420,500"
internal_rom_number=1
rom_path=/home/pi/RetroPie/roms/apple2
speaker_volume=50
tape_path=/home/pi/RetroPie/roms/apple2
tape_write_protect=0
text_echo_path=/home/pi/RetroPie/roms/apple2
trace_end_address=FFFF
trace_start_address=0000
trap0_address=0000
trap0_enable=0
trap1_address=0000
trap1_enable=0
trap2_address=0000
trap2_enable=0
trap3_address=0000
trap3_enable=0
trap_history_dump=0
trap_history_lines=0
use_internal_rom=yes
watch0_address=0000
watch0_enable=0
watch1_address=0000
watch1_enable=0
watch2_address=0000
watch2_enable=0
watch3_address=0000
watch3_enable=0
watch_history_dump=0
watch_history_lines=0
window_position="10,10"
window_scale=2
_EOF_

    sed -i s+'/home/pi/'+"$home/"+g "$home/.config/applepi.conf"
    chown $__user:$__user "$home/.config/applepi.conf"
    moveConfigFile "$home/.config/applepi.conf" "$md_conf_root/apple2/applepi.conf"

    cat >"$md_inst/applepi-qjoy.sh" << _EOF_
#!/bin/bash
# https://github.com/RapidEdwin08/

qjoyLAYOUT="ApplePi"
qjoyLYT=\$(
echo '# QJoyPad 4.3 Layout File

Joystick 1 {
    Axis 3: dZone 25309, xZone 3163, +mouse 3, -key 0
    Axis 4: gradient, maxSpeed 3, tCurve 0, mouse+h
    Axis 5: gradient, maxSpeed 3, tCurve 0, mouse+v
    Axis 6: dZone 25309, xZone 3163, +mouse 1, -key 0
    Button 11: mouse 1
}
')

# Create QJoyPad.lyt if needed
if [ ! -f "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt" ]; then echo "\$qjoyLYT" > "\$HOME/.qjoypad3/\$qjoyLAYOUT.lyt"; fi

# Run qjoypad
pkill -15 qjoypad > /dev/null 2>&1
rm /tmp/qjoypad.pid > /dev/null 2>&1
echo "qjoypad "\$qjoyLAYOUT" &" >> /dev/shm/runcommand.info
qjoypad "\$qjoyLAYOUT" &

# Run $md_id
VC4_DEBUG=always_sync $md_inst/applepi

# Kill qjoypad
pkill -15 qjoypad > /dev/null 2>&1; rm /tmp/qjoypad.pid > /dev/null 2>&1

# Restart qjoypad IF DTWPID qjoypad@Desktop is Enabled + startx is running
if [[ -f /etc/xdg/autostart/qjoypad-start.desktop ]] && pgrep -f startx &> /dev/null 2>&1; then qjoypad-start > /dev/null 2>&1; fi

exit 0
_EOF_
    chmod 755 "$md_inst/applepi-qjoy.sh"

    [[ "$md_mode" == "install" ]] && game_data_applepi
    [[ "$md_mode" == "install" ]] && shortcuts_icons_applepi
}

function shortcuts_icons_applepi() {
    local shortcut_name
    shortcut_name="ApplePi"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Apple ][ Emulator
Exec=$md_inst/applepi
Icon=$md_inst/applepi_128x128.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Mesen
StartupWMClass=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/applepi_128x128.xpm" << _EOF_
/* XPM */
static char * applepi_128x128_xpm[] = {
"128 128 83 1",
"   c None",
".  c #808080",
"+  c #1E1E1E",
"@  c #323232",
"#  c #898989",
"\$ c #262A1D",
"%  c #000000",
"&  c #424242",
"*  c #181818",
"=  c #505050",
"-  c #5E5E5E",
";  c #000005",
">  c #A4A4A4",
",  c #D0D0D0",
"'  c #BABABA",
")  c #0A0A0A",
"!  c #E6E6E6",
"~  c #737373",
"{  c #3A3A3A",
"]  c #676767",
"^  c #797979",
"/  c #B5B5B5",
"(  c #C3C3C3",
"_  c #626262",
":  c #D6D6D6",
"<  c #C9C9C9",
"[  c #4A4A4A",
"}  c #38431F",
"|  c #627535",
"1  c #738D33",
"2  c #7F9843",
"3  c #839F40",
"4  c #91AE4B",
"5  c #97B649",
"6  c #9ABE42",
"7  c #434C2C",
"8  c #4C592F",
"9  c #758B3F",
"0  c #98BC41",
"a  c #97BB41",
"b  c #96B941",
"c  c #383D2C",
"d  c #2B2E21",
"e  c #202317",
"f  c #2D2D2D",
"g  c #969696",
"h  c #586A2D",
"i  c #6B8430",
"j  c #343D20",
"k  c #8D8D8D",
"l  c #000006",
"m  c #9D9D9D",
"n  c #546330",
"o  c #697E38",
"p  c #919191",
"q  c #400F01",
"r  c #561B0E",
"s  c #842814",
"t  c #A62D13",
"u  c #BD3415",
"v  c #CB3615",
"w  c #DE3911",
"x  c #E23100",
"y  c #DE3100",
"z  c #D53C1A",
"A  c #C22F0D",
"B  c #AA2809",
"C  c #371710",
"D  c #8F2712",
"E  c #CA2D03",
"F  c #7D2813",
"G  c #732717",
"H  c #581F12",
"I  c #481E13",
"J  c #2C1914",
"K  c #9C2F18",
"L  c #6E2819",
"M  c #E43100",
"N  c #952205",
"O  c #542116",
"P  c #000E0E",
"Q  c #851F03",
"R  c #A93B26",
"                                                   .+@#                                                                         ",
"                                                  \$%%%%&                                                                        ",
"                                                 &%%%%%*                                                                        ",
"                                                 %%%%%%%=                                                                       ",
"                                                 -%%%%%%;>                                                                      ",
"                                                  &%%%%%%=                           ,>.-*%%%%%*-#'                             ",
"                                                   )%%%%%%.                     !~{{*%%%%%%%%%%%%%&                             ",
"                                                   +%%%%%%]                   ^=%%%%%%%%%%%%%%%%%%*                             ",
"                                                   /%%%%%%%(                _%%%%%%%%%%%%%%%%%%%%%%                             ",
"                                                    -%%%%%%+              _;%%%%%%%%%%%%%%%%%%%%%%%:                            ",
"                                                    '%%%%%%)            -\$%%%%%%%%%%%%%%%%%%%%%%%%%<                            ",
"                                                     ~%%%%%%_          ~%%%%%%%%%%%%%%%%%%%%%%%%%%%<                            ",
"                                                     ^%%%%%%*         [%%%%%%%%%%%%%}|1234567%%%%%%<                            ",
"                                                      {%%%%%%=       @%%%%%%%%%%\$8950abbbbb0c%%%%%%:                            ",
"                                                      (%%%%%%d      &%%%%%%%%%e1bbbbbbbbbbb0e%%%%%%!                            ",
"                                                       f%%%%%%#    ]%%%%%%%%)1babbbbbbbbbbbae%%%%%%                             ",
"                                                       ~%%%%%%=   ~%%%%%%%%84abbbbbbbbbbbbbbe%%%%%d                             ",
"                                                        )%%%%%*  ,%%%%%%%%|0bbbbbbbbbbbbbbb3)%%%%%-                             ",
"                                                        -%%%%%%g .%%%%%%%habbbbbbbbbbbbbbbb3%%%%%%#                             ",
"                                                        ~%%%%%%-<%%%%%%%}bbbbbbbbbbbbbbbbbb9%%%%%%^                             ",
"                                                         %%%%%%f&%%%%%%ebbbbbbbbbbbbbbbbbb08%%%%%)                              ",
"                                                         ~%%%%%%%%%%%%%ibbbbbbbbbbbbbbbbbbb%%%%%%+                              ",
"                                                         &%%%%%%%%%%%%jabbbbbbbbbbbbbbbbbb2%%%%%%*                              ",
"                                                         (%%%%%%%%%%%%1bbbbbbbbbbbbbbbbbba|%%%%%%k                              ",
"                                                          f%%%%%%%%%%lbbbbbbbbbbbbbbbbbbbb*%%%%%%<                              ",
"                                                          m%%%%%%%%%%n0bbbbbbbbbbbbbbbbbao%%%%%%=                               ",
"                                                           ;%%%%%%%%%3bbbbbbbbbbbbbbbbbbb\$%%%%%%]                               ",
"                                                           +%%%%%%%%*4bbbbbbbbbbbbbbbbbah%%%%%%)                                ",
"                                                           +%%%%%%%%eabbbbbbbbbbbbbbbbb3)%%%%%%[                                ",
"                                                           -%%%%%%%%80bbbbbbbbbbbbbbbb4)%%%%%%%                                 ",
"                                                           '%%%%%%%%9abbbbbbbbbbbbbbabe%%%%%%%p                                 ",
"                                                            %%%%%%%%3bbbbbbbbbbbbbba3e%%%%%%%f                                  ",
"                                                            f%%%%%%;bbbbbbbbbbbbbabh%%%%%%%%*                                   ",
"                                                            [%%%%%%)bbbbbbbbbbb04i)%%%%%%%%%f                                   ",
"                                                            _%%%%%%ebbbbbbbabb3n)%%%%%%%%%%p                                    ",
"                                       (.=f*%*f&.'          f%%%%%%ebbbaa52|}e;%%%%%%%%%%%>                                     ",
"                                  pd~@%%%%%%%%%%%%%{.&      f%%%%%%)87}je%%%%%%%%%%%%%%%%%)-+^                                  ",
"                                #%%%%%%%%%%%%%%%%%%%%%%]^   ]%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%^                                ",
"                             '*;%%%%%%%%%%%%%%%%%%%%%%%%%)m ^%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;*/                             ",
"                           #&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=^%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%{~                           ",
"                          ]%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%_                          ",
"                        g%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%k                        ",
"                       &%%%%%%%%%%%%;qrstuvwxyzABsrC%%%%%%%%%%%%%%%%%%%%%%%%CrsBAzyxwvutsrq;%%%%%%%%%%%%@                       ",
"                      {%%%%%%%%%%)qDEyyyyyyyyyyyyyyytr)%%%%%%%%%%%%%%%%%%)rtyyyyyyyyyyyyyyyEDq)%%%%%%%%%%-                      ",
"                     ~%%%%%%%%%%FEyyyyyyyyyyyyyyyyyyyxEG%%%%%%%%%%%%%%%%GExyyyyyyyyyyyyyyyyyxyEG%%%%%%%%%%~                     ",
"                    ;%%%%%%%%%GAxyyyyyyyyyyyyyyyyyyyyyyxAq%%%%%%%%%%%%qAxyyyyyyyyyyyyyyyyyyyyyyxAH%%%%%%%%%*                    ",
"                   -%%%%%%%%qBxyyyyyyyyyyyyyyyyyyyyyyyyyywH%%%%%%%%%%HwyyyyyyyyyyyyyyyyyyyyyyyyyyxBq%%%%%%%%]                   ",
"                  ,)%%%%%%%qEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyF%%%%%%%%syyyyyyyyyyyyyyyyyyyyyyyyyyyyyyEq%%%%%%%),                  ",
"                  +%%%%%%%IwyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyF%%%%%%syyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyI%%%%%%%+                  ",
"                 g%%%%%%%HwyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyG%%%%Fxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywr%%%%%%%m                 ",
"                >%%%%%%%CvyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywC%%rxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyvJ%%%%%%%/                ",
"                ~%%%%%%)uyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA))AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA%%%%%%%.                ",
"               /%%%%%%%KxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxGDxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxs%%%%%%%(               ",
"               -%%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%%]               ",
"               @%%%%%%KyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyD%%%%%%{               ",
"              >%%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%%>              ",
"              +%%%%%%Dyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyys%%%%%%\$              ",
"              f%%%%%;Eyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyv;%%%%%f              ",
"              %%%%%%LxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyMr%%%%%%              ",
"             #%%%%%%ByyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyB%%%%%%#             ",
"             +%%%%%%AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA%%%%%%+             ",
"             )%%%%%)wyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyw)%%%%%)             ",
"             ;%%%%%HMyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyMI%%%%%;             ",
"             %%%%%%Dxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxs%%%%%%             ",
"            >%%%%%%Ayyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyu%%%%%%>            ",
"            p%%%%%)EyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyE%%%%%%g            ",
"            ~%%%%%JEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyE)%%%%%~            ",
"            -%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyEq%%%%%-            ",
"            @%%%%%qwyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyEq%%%%%{            ",
"            *%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywq%%%%%+            ",
"            *%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%*            ",
"            )%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%)            ",
"            )%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%)            ",
"            *%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywq%%%%%*            ",
"            +%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywq%%%%%*            ",
"            @%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywq%%%%%{            ",
"            =%%%%%qEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%-            ",
"            ]%%%%%JEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyvJ%%%%%~            ",
"            #%%%%%)EyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyE)%%%%%#            ",
"            >%%%%%%EyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA;%%%%%>            ",
"            [%%%%%%uyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyu%%%%%%[            ",
"             %%%%%%NxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxK%%%%%%             ",
"             ;%%%%%HxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxO%%%%%;             ",
"             )%%%%%JxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywJ%%%%%)             ",
"             %%%%%%%yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyv%%%%%%;             ",
"             &%%%%%%AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA%%%%%%=             ",
"             p%%%%%%ByyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyB%%%%%%g             ",
"             (%%%%%%sxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxs%%%%%%(             ",
"              *%%%%%CMyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyMC%%%%%*              ",
"              {%%%%%%vyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyv%%%%%%{              ",
"              +%%%%%%DyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyD%%%%%%+              ",
"              >%%%%%%Gyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyr%%%%%%>              ",
"               *%%%%%)yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy)%%%%%*               ",
"               _%%%%%%KyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyD%%%%%%]               ",
"               -%%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyq%%%%%%-               ",
"                %%%%%%)AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA)%%%%%%                ",
"                ~%%%%%%HxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxH%%%%%%^                ",
"                ~%%%%%%)EyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA)%%%%%%^                ",
"                 %%%%%%%Dxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxs%%%%%%)                 ",
"                 .%%%%%%PEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyEP%%%%%%#                 ",
"                  f%%%%%%QyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyQ%%%%%%f                  ",
"                  ]%%%%%%;wyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyw;%%%%%%^                  ",
"                   \$%%%%%%ryyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyr%%%%%%f                   ",
"                   ~%%%%%%)AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA%%%%%%%^                   ",
"                   !+%%%%%%JyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywJ%%%%%%@                    ",
"                    &%%%%%%%DxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyxD%%%%%%%&                    ",
"                     +%%%%%%;AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyA;%%%%%%f                     ",
"                     /*%%%%%%qyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyywq%%%%%%*/                     ",
"                      -%%%%%%%LyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyH%%%%%%%_                      ",
"                       f%%%%%%%Rxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyt%%%%%%%@                       ",
"                       >%%%%%%%;uyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyu;%%%%%%%/                       ",
"                        &%%%%%%%)AyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyAl%%%%%%%=                        ",
"                         =%%%%%%%CEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyvJ%%%%%%%=                         ",
"                          +%%%%%%%qEyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyEC%%%%%%%+                          ",
"                           %%%%%%%%CvyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyEJ%%%%%%%%                           ",
"                           >%%%%%%%%)uxyyyyyyyyyyyyyyyyyyyyyyyxKKxyyyyyyyyyyyyyyyyyyyyyyyxA;%%%%%%%%>                           ",
"                            .%%%%%%%%;NyyyyyyyyyyyyyyyyyyyyyyyD%%DyyyyyyyyyyyyyyyyyyyyyyyD%%%%%%%%%.                            ",
"                             ^;%%%%%%%%IEyyyyyyyyyyyyyyyyyyyyr%%%%ryyyyyyyyyyyyyyyyyyyyEq%%%%%%%%;~                             ",
"                              ~%%%%%%%%%JDyyyyyyyyyyyyyyyyxDJ%%%%%%JDxyyyyyyyyyyyyyyyws)%%%%%%%%%~                              ",
"                               #%%%%%%%%%%JDvxyyyyyyyyyxwtq%%%%%%%%%%qtwxyyyyyyyyyxAD)%%%%%%%%%%#                               ",
"                                >%%%%%%%%%%%%rBEEwyyEEAF;%%%%%%%%%%%%%%lFAEEyywEAtI%%%%%%%%%%%%>                                ",
"                                  f%%%%%%%%%%%%%)qqqq)%%%%%%%%%%%%%%%%%%%%)qqqq)%%%%%%%%%%%%%@                                  ",
"                                   [;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%;[                                   ",
"                                    g%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%g                                    ",
"                                      #%%%%%%%%%%%%%%%%%%%%%%%=<<=%%%%%%%%%%%%%%%%%%%%%%%#                                      ",
"                                       :{@%%%%%%%%%%%%%%%%%*\$      \$*%%%%%%%%%%%%%%%%%@{:                                       ",
"                                          /+*%%%%%%%%%%%*)k          #))%%%%%%%%%%%*+/                                          ",
"                                              >~[+;*@]m                  m]@*;+[~>                                              "};
_EOF_
}
