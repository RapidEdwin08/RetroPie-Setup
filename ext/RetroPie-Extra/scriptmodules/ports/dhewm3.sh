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

rp_module_id="dhewm3"
rp_module_desc="dhewm3 - Doom 3 GPL Source Port"
rp_module_licence="GPL3 https://github.com/dhewm/dhewm3/blob/master/COPYING.txt"
#rp_module_repo="git https://github.com/dhewm/dhewm3.git master"
rp_module_repo="git https://github.com/warriormaster12/dhewm3.git master"
rp_module_help="Place Game Files in [ports/doom3/base]:\npak000.pk4\npak001.pk4\npak002.pk4\npak003.pk4\npak004.pk4\npak005.pk4\npak006.pk4\npak007.pk4\npak008.pk4\n\nPlace Expansion Files in [ports/doom3/d3xp]:\npak000.pk4\npak001.pk4"
rp_module_section="exp"
rp_module_flags=""

function depends_dhewm3() {
    #getDepends cmake libsdl2-dev libopenal-dev libogg-dev libvorbis-dev zlib1g-dev libcurl4-openssl-dev xorg
    local depends=(cmake libsdl2-dev libopenal-dev libogg-dev libvorbis-dev zlib1g-dev libcurl4-openssl-dev)
    depends+=(xorg matchbox-window-manager)
    getDepends "${depends[@]}"
}

function sources_dhewm3() {
    gitPullOrClone
}

function build_dhewm3() {
    mkdir "$md_build/build"

    cd "$md_build/build"

    cmake "../neo"
    make clean
    make
    md_ret_require="$md_build/build"
}

function install_dhewm3() {
    md_ret_files=(
        "build/dhewm3"
        "build/d3xp.so"
        "build/base.so"
	"base"
    )
}

function remove_dhewm3() {
    local shortcut_name
    shortcut_name="Doom 3"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
}

function configure_dhewm3() {
    mkdir -p "$home/.config/dhewm3/base"
    mkdir -p "$home/.config/dhewm3/d3xp"
    mkdir -p "$home/.local/share/dhewm3"
    moveConfigDir "$home/.config/dhewm3" "$md_conf_root/doom3"
    moveConfigDir "$home/.local/share/dhewm3" "$md_conf_root/doom3"
    chown -R $__user:$__user "$md_conf_root/doom3"

    mkRomDir "ports/doom3/base"
    mkRomDir "ports/doom3/d3xp"
    moveConfigDir "$md_inst/base" "$romdir/ports/doom3/base"
    moveConfigDir "$md_inst/d3xp" "$romdir/ports/doom3/d3xp"
    if [[ -f "$romdir/ports/doom3/base/renderprogs/ShaderCompiler.sh" ]]; then
        mv "$romdir/ports/doom3/base/renderprogs/ShaderCompiler.sh" "$romdir/ports/doom3/base/renderprogs/ShaderCompiler.sh.0ff"
    fi
    chown -R $__user:$__user "$romdir/ports/doom3"

    local launch_prefix
    if isPlatform "rpi" && ! isPlatform "kms"; then launch_prefix="XINIT-WMC:"; fi
    addPort "$md_id" "doom3" "Doom 3" "$launch_prefix$md_inst/dhewm3"
    local launch_suffix
    if isPlatform "vulkan"; then
        launch_suffix=" +set r_renderApi 1"
        addPort "$md_id-vulkan" "doom3" "Doom 3" "$launch_prefix$md_inst/dhewm3$launch_suffix"
    fi

    # seta r_mode "5" = 1024x768 | seta r_mode "9" = 1280x720 | seta r_mode "15" = 1920x1080
    cat >"$md_inst/dhewm.cfg" << _EOF_
unbindall
bind "TAB" "_impulse19"
bind "ENTER" "_button2"
bind "ESCAPE" "togglemenu"
bind "SPACE" "_moveup"
bind "/" "_impulse14"
bind "0" "_impulse27"
bind "1" "_impulse0"
bind "2" "_impulse1"
bind "3" "_impulse2"
bind "4" "_impulse3"
bind "5" "_impulse4"
bind "6" "_impulse5"
bind "7" "_impulse6"
bind "8" "_impulse7"
bind "9" "_impulse8"
bind "[" "_impulse15"
bind "\\" "_mlook"
bind "]" "_impulse14"
bind "a" "_moveleft"
bind "c" "_movedown"
bind "d" "_moveright"
bind "f" "_impulse11"
bind "q" "_impulse12"
bind "r" "_impulse13"
bind "s" "_back"
bind "t" "clientMessageMode"
bind "w" "_forward"
bind "y" "clientMessageMode 1"
bind "z" "_zoom"
bind "BACKSPACE" "clientDropWeapon"
bind "PAUSE" "pause"
bind "UPARROW" "_forward"
bind "DOWNARROW" "_back"
bind "LEFTARROW" "_left"
bind "RIGHTARROW" "_right"
bind "ALT" "_strafe"
bind "CTRL" "_attack"
bind "SHIFT" "_speed"
bind "DEL" "_lookdown"
bind "PGDN" "_lookup"
bind "END" "_impulse18"
bind "F1" "_impulse28"
bind "F2" "_impulse29"
bind "F3" "_impulse17"
bind "F5" "savegame quick"
bind "F6" "_impulse20"
bind "F7" "_impulse22"
bind "F9" "loadgame quick"
bind "F10" "dhewm3Settings"
bind "F12" "screenshot"
bind "MOUSE1" "_attack"
bind "MOUSE2" "_moveup"
bind "MOUSE3" "_zoom"
bind "MWHEELDOWN" "_impulse14"
bind "MWHEELUP" "_impulse15"
bind "JOY_BTN_SOUTH" "_moveUp"
bind "JOY_BTN_EAST" "_zoom"
bind "JOY_BTN_WEST" "_moveDown"
bind "JOY_BTN_NORTH" "_impulse13"
bind "JOY_BTN_BACK" "_impulse19"
bind "JOY_BTN_LSTICK" "_speed"
bind "JOY_BTN_RSTICK" "_impulse18"
bind "JOY_BTN_LSHOULDER" "_impulse15"
bind "JOY_BTN_RSHOULDER" "_impulse14"
bind "JOY_DPAD_UP" "_impulse3"
bind "JOY_DPAD_DOWN" "_impulse11"
bind "JOY_DPAD_LEFT" "_impulse1"
bind "JOY_DPAD_RIGHT" "_impulse2"
bind "JOY_STICK1_UP" "_forward"
bind "JOY_STICK1_DOWN" "_back"
bind "JOY_STICK1_LEFT" "_moveLeft"
bind "JOY_STICK1_RIGHT" "_moveRight"
bind "JOY_STICK2_UP" "_lookUp"
bind "JOY_STICK2_DOWN" "_lookDown"
bind "JOY_STICK2_LEFT" "_left"
bind "JOY_STICK2_RIGHT" "_right"
bind "JOY_TRIGGER1" "_speed"
bind "JOY_TRIGGER2" "_attack"
seta in_toggleZoom "1"
seta in_toggleCrouch "1"
seta in_toggleRun "0"
seta in_alwaysRun "0"
seta r_brightness "2"
seta r_gamma "1"
seta r_swapInterval "1"
seta r_fullscreenDesktop "0"
seta r_fullscreen "1"
seta r_renderer "best"
seta r_mode "5"
seta ui_name "DoomGuy"
_EOF_
    if [[ ! -f "$home/.config/dhewm3/base/dhewm.cfg" ]]; then
        cp "$md_inst/dhewm.cfg" "$home/.config/dhewm3/base/dhewm.cfg"
        chown -R $__user:$__user "$home/.config/dhewm3/base/dhewm.cfg"
    fi

    cat >"$md_inst/dhewm-d3xp.cfg" << _EOF_
unbindall
bind "TAB" "_impulse19"
bind "ENTER" "_button2"
bind "ESCAPE" "togglemenu"
bind "SPACE" "_moveUp"
bind "0" "_impulse27"
bind "1" "_impulse1"
bind "2" "_impulse3"
bind "3" "_impulse4"
bind "4" "_impulse6"
bind "5" "_impulse7"
bind "6" "_impulse8"
bind "7" "_impulse9"
bind "8" "_impulse10"
bind "9" "_impulse11"
bind "[" "_impulse15"
bind "\\" "_mlook"
bind "]" "_impulse14"
bind "a" "_moveleft"
bind "c" "_movedown"
bind "d" "_moveright"
bind "f" "_impulse0"
bind "q" "_impulse12"
bind "r" "_impulse13"
bind "s" "_back"
bind "t" "clientMessageMode"
bind "w" "_forward"
bind "y" "clientMessageMode 1"
bind "z" "_zoom"
bind "BACKSPACE" "clientDropWeapon"
bind "PAUSE" "pause"
bind "LEFTARROW" "_left"
bind "RIGHTARROW" "_right"
bind "ALT" "_strafe"
bind "CTRL" "_attack"
bind "DEL" "_lookdown"
bind "PGDN" "_lookup"
bind "END" "_impulse18"
bind "F1" "_impulse28"
bind "F2" "_impulse29"
bind "F3" "_impulse17"
bind "F5" "savegame quick"
bind "F6" "_impulse20"
bind "F7" "_impulse22"
bind "F9" "loadgame quick"
bind "F12" "screenshot"
bind "JOY_BTN_SOUTH" "_moveUp"
bind "JOY_BTN_EAST" "_zoom"
bind "JOY_BTN_WEST" "_moveDown"
bind "JOY_BTN_NORTH" "_impulse13"
bind "JOY_BTN_BACK" "_impulse19"
bind "JOY_BTN_LSTICK" "_speed"
bind "JOY_BTN_RSTICK" "_impulse18"
bind "JOY_BTN_LSHOULDER" "_impulse15"
bind "JOY_BTN_RSHOULDER" "_impulse14"
bind "JOY_DPAD_UP" "_impulse6"
bind "JOY_DPAD_DOWN" "_impulse0"
bind "JOY_DPAD_LEFT" "_impulse3"
bind "JOY_DPAD_RIGHT" "_impulse4"
bind "JOY_STICK1_UP" "_forward"
bind "JOY_STICK1_DOWN" "_back"
bind "JOY_STICK1_LEFT" "_moveLeft"
bind "JOY_STICK1_RIGHT" "_moveRight"
bind "JOY_STICK2_UP" "_lookUp"
bind "JOY_STICK2_DOWN" "_lookDown"
bind "JOY_STICK2_LEFT" "_left"
bind "JOY_STICK2_RIGHT" "_right"
bind "JOY_TRIGGER1" "_speed"
bind "JOY_TRIGGER2" "_attack"
seta in_toggleZoom "1"
seta in_toggleCrouch "1"
seta in_toggleRun "0"
seta in_alwaysRun "0"
seta r_brightness "2"
seta r_gamma "1"
seta r_swapInterval "1"
seta r_fullscreenDesktop "0"
seta r_fullscreen "1"
seta r_renderer "best"
seta r_mode "5"
seta ui_name "DoomGuy"
_EOF_
    if [[ ! -f "$home/.config/dhewm3/d3xp/dhewm.cfg" ]]; then
        cp "$md_inst/dhewm-d3xp.cfg" "$home/.config/dhewm3/d3xp/dhewm.cfg"
        chown -R $__user:$__user "$home/.config/dhewm3/d3xp/dhewm.cfg"
    fi

    [[ "$md_mode" == "remove" ]] && remove_dhewm3
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && shortcuts_icons_dhewm3
}

function shortcuts_icons_dhewm3() {
    local shortcut_name
    shortcut_name="Doom 3"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=$shortcut_name
Exec=$md_inst/dhewm3
Icon=$md_inst/Doom3_72x72.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Doom3;TooDark
StartupWMClass=Doom3
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/Doom3_72x72.xpm" << _EOF_
/* XPM */
static char * Doom3_72x72_xpm[] = {
"72 72 257 2",
"   c None",
".  c #47704C",
"+  c #000000",
"@  c #000000",
"#  c #000000",
"\$     c #000000",
"%  c #000000",
"&  c #000000",
"*  c #000000",
"=  c #000000",
"-  c #000000",
";  c #000000",
">  c #000000",
",  c #000000",
"'  c #0C0805",
")  c #000000",
"!  c #000000",
"~  c #010000",
"{  c #040101",
"]  c #0E0603",
"^  c #271810",
"/  c #0A0506",
"(  c #B37B48",
"_  c #8C7B5F",
":  c #010000",
"<  c #513F2B",
"[  c #110805",
"}  c #4A3527",
"|  c #A97552",
"1  c #0B0503",
"2  c #241109",
"3  c #5F554C",
"4  c #0E0403",
"5  c #714429",
"6  c #8F6D5D",
"7  c #26160C",
"8  c #8C3624",
"9  c #5C554B",
"0  c #24160F",
"a  c #0C0404",
"b  c #AB937B",
"c  c #471E10",
"d  c #756F60",
"e  c #6C5847",
"f  c #3B2315",
"g  c #834528",
"h  c #321D11",
"i  c #62280F",
"j  c #221109",
"k  c #5C534D",
"l  c #5B301D",
"m  c #381D10",
"n  c #97432A",
"o  c #783216",
"p  c #56190F",
"q  c #7F705E",
"r  c #9C562D",
"s  c #000001",
"t  c #040201",
"u  c #090401",
"v  c #1E0E04",
"w  c #180C04",
"x  c #0E0501",
"y  c #120A04",
"z  c #291606",
"A  c #2D1909",
"B  c #221307",
"C  c #261004",
"D  c #150501",
"E  c #3B2511",
"F  c #321F0C",
"G  c #0A0805",
"H  c #27160D",
"I  c #452A15",
"J  c #33180A",
"K  c #53301A",
"L  c #4C2E19",
"M  c #2D1D10",
"N  c #3E2B13",
"O  c #140F0A",
"P  c #381E11",
"Q  c #453119",
"R  c #38220A",
"S  c #53381E",
"T  c #412313",
"U  c #4B2B10",
"V  c #694A2D",
"W  c #593E24",
"X  c #65391F",
"Y  c #1F0300",
"Z  c #4E3B29",
"\`     c #8B4B18",
" . c #3D2F1D",
".. c #372818",
"+. c #241C14",
"@. c #604B34",
"#. c #300F05",
"\$.    c #744D2E",
"%. c #290401",
"&. c #612D0B",
"*. c #4C371E",
"=. c #453423",
"-. c #302316",
";. c #1D140C",
">. c #6C421E",
",. c #6A533A",
"'. c #7C4821",
"). c #A15517",
"!. c #5E503F",
"~. c #644225",
"{. c #804213",
"]. c #522105",
"^. c #0B0E14",
"/. c #54422E",
"(. c #AC550D",
"_. c #79360A",
":. c #714127",
"<. c #764116",
"[. c #8D430E",
"}. c #994D12",
"|. c #262D3E",
"1. c #5C361F",
"2. c #5D432D",
"3. c #3B1904",
"4. c #4C1805",
"5. c #5D2003",
"6. c #6D2F08",
"7. c #C06213",
"8. c #29221F",
"9. c #353948",
"0. c #422309",
"a. c #443A2D",
"b. c #322B23",
"c. c #1C1D22",
"d. c #3A342A",
"e. c #62544B",
"f. c #562B0B",
"g. c #80522B",
"h. c #3E4351",
"i. c #04070E",
"j. c #87390C",
"k. c #653811",
"l. c #350701",
"m. c #181616",
"n. c #9A5B2B",
"o. c #805936",
"p. c #905524",
"q. c #574639",
"r. c #431709",
"s. c #A74909",
"t. c #B45F14",
"u. c #99663A",
"v. c #5B3715",
"w. c #BA550D",
"x. c #BC6626",
"y. c #3C0D03",
"z. c #554E43",
"A. c #7C6C55",
"B. c #77533D",
"C. c #894C28",
"D. c #23262D",
"E. c #8D5A33",
"F. c #CB6A13",
"G. c #4C4236",
"H. c #AD5F20",
"I. c #33343A",
"J. c #6D665F",
"K. c #403C3A",
"L. c #964C21",
"M. c #AB6330",
"N. c #713515",
"O. c #6F5E43",
"P. c #333F59",
"Q. c #2E2D32",
"R. c #414961",
"S. c #0E1323",
"T. c #541405",
"U. c #A37142",
"V. c #4A4545",
"W. c #8B6D42",
"X. c #735F52",
"Y. c #9C4306",
"Z. c #4E2115",
"\`.    c #460D03",
" + c #29354C",
".+ c #98684B",
"++ c #4E4D58",
"@+ c #896650",
"#+ c #872B0A",
"\$+    c #7D6344",
"%+ c #5F585B",
"&+ c #B0511C",
"*+ c #BE7138",
"=+ c #804831",
"-+ c #7C3C22",
";+ c #933A11",
">+ c #7B2606",
",+ c #A0835F",
"'+ c #DA641C",
")+ c #172133",
"!+ c #CD7128",
"~+ c #CC5E1A",
"{+ c #9E7B50",
"]+ c #622B1A",
"^+ c #957F6A",
"/+ c #6B1F07",
"(+ c #8A5C41",
"_+ c #AF7039",
":+ c #CA540D",
"<+ c #A48F66",
"[+ c #412723",
"}+ c #C57D41",
"|+ c #B1835E",
"1+ c #7B7068",
"2+ c #5C1F14",
"3+ c #A54E2D",
"4+ c #4F576C",
"5+ c #DE7523",
"6+ c #EFC176",
"7+ c #BF8A4C",
"8+ c #8D784E",
"9+ c #827A74",
"0+ c #CE9350",
"a+ c #CDC7AB",
"b+ c #988976",
"c+ c #EFC98A",
"d+ c #C5522D",
"e+ c #EAB682",
"f+ c #DC8B38",
"g+ c #EADCBE",
"h+ c #F4B76A",
"i+ c #A53719",
"j+ c #DAAA70",
"k+ c #DCD7C1",
"l+ c #C89C7D",
"m+ c #DBA25D",
"n+ c #D67D3B",
"o+ c #F0A958",
"p+ c #CA9A64",
"q+ c #8F8D89",
"r+ c #BD3913",
"s+ c #DFC29F",
"t+ c #E3A046",
"u+ c #E39448",
"v+ c #616674",
"w+ c #E2A77F",
"x+ c #BF8E69",
"y+ c #F2D1AA",
"z+ c #EBE1D3",
"A+ c #BEAA8B",
"B+ c #6B768B",
"C+ c #D08861",
"D+ c #BAA66C",
"E+ c #D1B499",
"F+ c #BAAFAA",
"G+ c #B2A298",
"H+ c #81A2B8",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                  +.0 t u [ t t                                                                 ",
"                                                                +.+.8.O [ [ ~ t [                                                               ",
"                                                              .. .+.0 ' +.0 ' s t ;.                                                            ",
"                                                            =.q.e @. .O +. .;.u 7 E H                                                           ",
"                                                        w =.@.@.\$+!.} ;.^ W F 1 F N E                                                           ",
"                                                      -...2.,.,.O.\$+Z F 7 2.A y F Q Q E                                                         ",
"                                                  Q =.Q ~.V Z V \$+O./.M M  .M y h Q E E                                                         ",
"                                          +.+.-.W W N ~.W Z =.B.\$+O.Z -...^ -.y  .N F M h                                                       ",
"                                        } a.d.V o.W R E K K ~.o.@.2.< M -.0 8.;.m ..N N M M                                                     ",
"                                    L E.o.a.} ( ( L F E T L W 2.f ,.=.L 0 #.' v 3.O f F M N A v v 0                                             ",
"                                  \$.u.7+2. .o.m+o.R R R c X S I C r.Z.X +.8.O w #.[ M ..M Q 7 ] B A  .                                          ",
"                                  }+_+\$.S o.E.( 1.z R E H E *.I 3 :.]+V 8.8.O 3.0 ..h y 7 L 1.v 1 A E  .                                        ",
"                                u.*+5 *.S E.g.\$.F B A z w 1.~.I m L =+%+D.O 8.l j z i M w E g.>.u w E N W E                                     ",
"                              Q M.C.X ~.S L ~.E w A h 2 3.>.P L #.v L J.R.m.V.J t #.r.-.t A '.n.T { v E 5 >.N E                                 ",
"                              >.}+g.S W 5 S Q B I X 4.#.f ~.N Q Z.0 t h.9.^.a.y.2 J v ..' v v._+>.~ t z :._+:.I E                               ",
"                            7 '.m+_+'.g.E.*.f A < 1.T f S >.X K 2+/ s m.^./ ^.v f #.O I M { A X '.A ~ w 1.}+M.K L P                             ",
"                          M N L _+}+C.\$.\$.} M N B.2.N r.l E.E.W 4.~ [ 8.S.v i.c I Y 0 =.N s ] R >.U ] v I n.M.>.1.L                             ",
"                        -.=...P 1.n.E.V < ..E N ,.Q E r.1.U.u.E.4.1 C d.h.O c.O c D -.S S s s A U B w z K X r >.K K I                           ",
"                        N ..-.m :.*+_+V  .W P h Q =.N T m U.U.V 2+#.H q+%+#.Q.[ r.w =.W E ~ s v z y w F >.C.C.>.L S K h                         ",
"                      2 1.h w m K >.K A B v y M F  .=.L U K u.~.l 4.=+G.b.j 0 Z.2+-.E H w u s t u u y F 1.:.X 1.1.1.K X E                       ",
"                      F L I y A A B y 1 u 1 w ^ ^ h -.E I C 7 1.W X r U.o #.J K I M u 1 w w ~ ~ t 1 ] B F N I L L I I 1.L I P                   ",
"                      I I K B B I L E 7 v w v v j 7 B F F A F J 7 1.=+b+T J O b.;.s ~ B ] ] u s ] v v B z z F E I h E L F I I                   ",
"                      T I L A y m T E 2 w y w y y y B v A z z v z A I ..O 7 w ;.s { B E v u s s t [ j M F 2 v h L I P h v A I                   ",
"                    T K X -+E w 1 w v w D x x x t u z A A z y 1 w v y t ~ y v s t B E E 7 ~ ~ ~ s ~ ] v h z F K K I B 1 t A T                   ",
"                    T ]+I >.E v t ~ u x u t ~ u x w z E J A y t u w w 1 y z C ] w A z A [ t u [ w w w j M B P L K F y ~ u z I L                 ",
"                  A m T J E C [ t ~ ~ ~ s s u 2 F A v F E A w { u ~ t y v B z B A B ] u ~ ~ t D w w H H j j 7 F P ;.~ s ] C K 1.                ",
"                D A m v v v y t t t t t 2 E K X 5 X A F E A v t u ~ 1 v v z z A E 2 w ~ s s ~ t 1 1 y ] 1 [ y w w t s s [ 2 K 1.                ",
"                v z z u w ] t t t t     1 z m I 1.1.T A z z w x ~ u ] w B z 7 f f B v [ ~ s ~ ~ t u 4   t u u t t s s s [ B l L I               ",
"              w z B w ~ 1 t t u           t y v B B v w ] ] ] t s u x u ] w ;.;.0 v ] ] [ 1 u u { {             { s s s u u I P T               ",
"          b+9+9+1+9+9+9+9+9+9+!.        b q+9+9+9+1+9+9+9+c.~ s ~ d 9+b+^+^+^+9+9+9+1+O 8.1+^+^+^+b+b       9+q+b+^+^+^+q / X._ _ b+b+X.q b+    ",
"          X.Q.D.Q.8.8.8.b.Q.Q.\$+q   _ X.b.I.Q.K.I.Q.d.Q.d.J.8.s e q.K.d.d.d.d.d.d.d.z.^+++q a.a.K.I.q.      e K.d.d.a._ J.A.!.S W 1.W L P e.    ",
"          !. +P.P.|.D.|.)+D.D.D.G...!.D.|.h.h.R.h.|.I.|.|.h.V.] !.9.9.I.Q.D.D.D.c.m.^.b.%+++8.9.P. +Q.%+  a.K.9.P. +)+e.D._ ^+_ _ _ _ =.E z.    ",
"          !.^.|.P.D.I.|.|. +9.9.V.I.z.P.I.h.I.c.Q.R.R. +9.4+k y e.++V.v+R.9.h.R.h.9.Q.8.k V.d.h.++9.R.e.  z.D.9.h. +)+!.S ( U.\$.B.| (+5.c !.    ",
"          !. + +|.b.=.=.d.8.8.c.G.K.G.K.Q.9.d.=.a.G.h.I.9.4+e.O z.k q e.K.G.G.G.h.|.9.K.z.%+a.z.V.K.4+3 b.!.Q.I. +|.)+e f Z.#.O.\$+X &.c {+D+    ",
"          ,.c.I.I.{+0+0+x+8.I.d.G.G.9 %+K.b.{+u+u+0+e K.V.++%+0 e _ A.K.|+0+0+x+/.K.V.I.V.%+X.e 9 a.3 G.e.!.I.Q.D.|.c.O.    B.|+< f.6.~.b       ",
"          O.d.I.I.@.g (+,.G.K.I.V.d.z.m.8.8.e.C.3+g /.a.z.z.J.c.e e.%+d.o.}.C.B.3 k V.G.z.k /.q.q.a.z.a.q =.b.+.' m.G O.    } B.X.< L k.2.1+    ",
"          O.a.d.b.q.8.K.G.G.-.+.G.=.!.a.} -.3 /.S } @.Z Z =.%++.,.e ,.< q.f ..q.9 3 q.a.9 %+G.!.!.q.=. .O.} =.b.b.Q.c.O._ ^+^+{+{+|+f.o >+/.d   ",
"          ,.z.3 G.G.^.  /.=.Z a.q.*.,.Z V  .3 D.  G./.S @.!.J.8.\$+,.,.< !.  ^.q.G.a.q.d.9 v+q.!.a. .e e a.!.a.d.Q.K.Q.e z.d.X o o L.[.#+>+0.G.  ",
"          ,.V.3 G.q.^.  G.!.2.2./.S ,.@.V =.3 Q.    q.1.W Z J.-.,.V B.@./.  c.z.!.../. .e.%+=.q.M -.q.q./.@.@.@.G.z.d.O.e W ~.~.5 -+~.V ~./.X.  ",
"          ,...b. .q.c.  q.!.,.~.2.1.\$.V =+} e K.    2.k.Z.I A...\$.\$.\$.K ,.  c.z.@.2.< } e.v+Z /.+.a.q.@.Z @.2.2.@.q. .,.,+7+7+7+( ( 7+7+7+x+<+A.",
"          O.G. .Z @.m.  q.,.B.W < X \$.5 g S B.G.    2.>.1.W A.F \$.g.'.\$.,.  b.e V 2.W < e J.Z 2.M !.< B.q.,./.Q } q.d.O.                        ",
"          O.q.Z 2.,.D.  a.2.~.@./.X \$.'.'.K B.W     V g.>.V X.m \$.C.{.<.!.  W (+V X \$.W ,.J.L l f W.*.o.@.B.2.F Z 2.S \$+                        ",
"          ,.O.(+W ,.d.  q.2.~.~.2.'.\$.>.-+U (+K     5 \` {.>.\$+T \$.p.\` '.!.  X r X N.p.>.\$.X.Q o.Q {+..O.@.:.V v @.\$.1.\$+                        ",
"          ,./.B.o.~.b.  q.5 g.\$.5 p.g.p.p.f.B.W     :.L.\` &.\$+r.g.}.}.k.!.  i L.k.{.p.X \$.O.0.X *.O.=.V V >.f.=.< \$.T (+                        ",
"          ,.a.q.W 2.;.  q.X X >.>.n.g.\` \` v.V L     :.L.}.{.E.4.g.).).<.,.  ].'.'.\` \` >.g.B.X '.W !.q.k.N.:.f.\$.1.5 U (+                        ",
"          V f 2.*.2.A   q.C.C.'.>.).g {.\` &.V c     '.).).{.E.y.5 ).).{.,.  0.>.>.L.}.N.g.B.k.\` X q.!.X <.N.S .+1.'.f.(+                        ",
"          ,.z ~.K 2.C   q.'.'.>.~.L.'.j.j.&.q.C     C.t.(.[.n.#.5 &+(.{.@.  J X X }.(.'.g.\$.N.\` N.V B.f.{.<.5 E.f.'.].(+                        ",
"          ,.J v.f.V D   @+i {.N.~.g \$.[.j.j.B.e     :.t.w.{.r #.=+&+(.{.@.  } o.{.s.s.\` '.=+{.}.{.\$.g f.\` <.o.g v.'.&.E.                        ",
"          @.J 1.U \$.< @+<._.j.{.~.<.5 }.[.}.}.(+@+=.'.t.7.{.C.#.g H.t._.@.@.\$+{.H.(.(.L.g.=+[.H.\` \$.L.1.\` 6.E.C.f.<.&.E.                        ",
"          @.J ~.K U.o.<.[.[.[.{.W X V _.j.;+).H.n..+\` x.t.k.g.v V H.w.[.W.E.}.7.~+t.x.{.:.=+\` H.\` V &+\$.o :.g '.f.X &.E.                        ",
"          \$.I ~.N.'.{.}.;+j.}.[.W 1.A.6.j.Y.(.7.F.t.(.t.\` B.o.C @+<.(.).).t.7.x.7.7.}.o.5 o.{.7.\` V &+r r.,.'.p.f.v.&.o.                        ",
"          \$.W '.L.H.}.).t.H.H.{.*.W.,.| \` &+(.F.F.7.x.[.U.}+L.c g | g &+w.x.F.t.t.L.U..+N.| U ).\` B.&+x.D e C.n.6.k.v.o.                        ",
"          V v.p.x.).(.w.F.t.).f.{+u.#.g.7+u.(.w.~+t.<.( n+&+    o n | E.).7.7.t.'.|+U.  i 3+| 1.U B.\` !+L B.L.p.6.k.K o.                        ",
"          \$.'.M.&+(.7.7.(._.1.7+M.N.      7+u.L.p.>.7+!+&+        ]+;+( u.{.}.g.7+g.        ;+*+V B.i !+E.Z L.p._.o v.B.                        ",
"          \$.<.{.&+t.t.}.&.\$.}+&+            ( | \$.0+~+;+              i+*+| W.(               &+}+.+  ~+}+  L.L.j.{.k.B.                        ",
"          \$.k.[.t.t._.4.U.n+L.                u.n+x.                    i+x.U.                  L.    &+M.  -+p._.[.k.\$.                        ",
"          5 >.\` ).[.K 7+n+L.                    g                         o                           >.    1.\$.o j.k.S                         ",
"          5 v.'.i V 0+!+\`                                                                                   h V {.j.5.o.                        ",
"          ~.J m W.u+x.                                                                                      M ,.&.&.r.o.                        ",
"          V ;.|+n+&+                                                                                      m g | L #.Y B.                        ",
"          u.p+n+L.                                                                                          N.t.}+~.s \$.                        ",
"          0+x.{.                                                                                              <.w.n+W.B.                        ",
"          L.                                                                                                      7.n+7+                        ",
"                                                                                                                    &+'+r                       ",
"                                                                                                                                                ",
"                                                                                                                                                "};
_EOF_
}
