#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="reicast"
rp_module_desc="Dreamcast emulator Reicast"
rp_module_help="ROM Extensions: .cdi .gdi\n\nCopy your Dreamcast roms to $romdir/dreamcast\n\nCopy the required BIOS files dc_boot.bin and dc_flash.bin to $biosdir/dc"
rp_module_licence="GPL2 https://raw.githubusercontent.com/reicast/reicast-emulator/master/LICENSE"
rp_module_repo="git https://github.com/reicast/reicast-emulator.git master"
rp_module_section="opt"
rp_module_flags="!armv6"

function depends_reicast() {
    local depends=(libsdl2-dev python3-dev python3-pip python3-setuptools libevdev-dev libasound2-dev libudev-dev)
    if [[ $(apt-cache search alsa-oss | grep 'alsa-oss ') == '' ]]; then
        depends+=(alsaplayer-oss)
    else
        depends+=(alsa-oss)
    fi
    isPlatform "vero4k" && depends+=(vero3-userland-dev-osmc)
    isPlatform "mesa" && depends+=(libgles2-mesa-dev)
    getDepends "${depends[@]}"
    isPlatform "vero4k" && pip3 install wheel
    pip3 install evdev
}

function sources_reicast() {
    gitPullOrClone
    applyPatch "$md_data/0001-enable-rpi4-sdl2-target.patch"
    applyPatch "$md_data/0002-enable-vsync.patch"
    applyPatch "$md_data/0003-fix-sdl2-sighandler-conflict.patch"
    sed -i "s#/usr/bin/env python#/usr/bin/env python3#" shell/linux/tools/reicast-joyconfig.py
}

function _params_reicast() {
    local platform
    local subplatform
    local params=()

    # platform-specific params
    if isPlatform "rpi" && isPlatform "32bit"; then
        # platform configuration
        if isPlatform "rpi4"; then
        #if isPlatform "rpi4" || isPlatform "rpi5"; then
            platform="rpi4"
        elif isPlatform "rpi3"; then
            platform="rpi3"
        else
            platform="rpi2"
        fi

        # subplatform configuration
        if isPlatform "rpi4"; then
        #if isPlatform "rpi4" || isPlatform "rpi5"; then
            # we need to target SDL with GLES3 disabled for KMSDRM compatibility
            subplatform="-sdl"
        elif isPlatform "mesa"; then
            subplatform="-mesa"
        fi

        params+=("platform=${platform}${subplatform}")
    else
        # generic flags
        isPlatform "x11" && params+=("USE_X11=1")
        isPlatform "kms" || isPlatform "gles" && params+=("USE_GLES=1")
        isPlatform "kms" || isPlatform "tinker" && params+=("USE_X11=" "HAS_SOFTREND=" "USE_SDL=1")
    fi

    echo "${params[*]}"
}

function build_reicast() {
    cd shell/linux
    make $(_params_reicast) clean
    make $(_params_reicast)

    md_ret_require="$md_build/shell/linux/reicast.elf"
}

function install_reicast() {
    cd shell/linux
    make $(_params_reicast) PREFIX="$md_inst" install

    md_ret_files=(
        'LICENSE'
        'README.md'
    )
}

function remove_reicast() {
    rm -f /usr/share/applications/Reicast.desktop
    rm -f "$home/Desktop/Reicast.desktop"
    rm -f "$home/RetroPie/roms/dreamcast/+Start Reicast.sh"
}

function configure_reicast() {
    local backend
    local backends=(alsa omx oss)
    local params=("%ROM%")

    # KMS reqires Xorg context & X/Y res passed.
    if isPlatform "kms"; then
        params+=("%XRES%" "%YRES%")
    fi

    # copy hotkey remapping start script
    cp "$md_data/reicast.sh" "$md_inst/bin/"
    chmod +x "$md_inst/bin/reicast.sh"

    mkRomDir "dreamcast"

    # move any old configs to the new location
    moveConfigDir "$home/.reicast" "$md_conf_root/dreamcast/"

    # Create home VMU, cfg, and data folders. Copy dc_boot.bin and dc_flash.bin to the ~/.reicast/data/ folder.
    mkdir -p "$md_conf_root/dreamcast/"{data,mappings}

    # symlink bios
    mkUserDir "$biosdir/dc"
    ln -sf "$biosdir/dc/"{dc_boot.bin,dc_flash.bin} "$md_conf_root/dreamcast/data"

    # copy default mappings
    cp "$md_inst/share/reicast/mappings/"*.cfg "$md_conf_root/dreamcast/mappings/"

    chown -R "$__user":"$__group" "$md_conf_root/dreamcast"

    if [[ "$md_mode" == "install" ]]; then
        cat > "$romdir/dreamcast/+Start Reicast.sh" << _EOF_
#!/bin/bash
$md_inst/bin/reicast.sh
_EOF_
        chmod a+x "$romdir/dreamcast/+Start Reicast.sh"
        chown "$__user":"$__group" "$romdir/dreamcast/+Start Reicast.sh"
    else
        rm "$romdir/dreamcast/+Start Reicast.sh"
    fi

    if [[ "$md_mode" == "install" ]]; then
        # possible audio backends: alsa, oss, omx
        if isPlatform "videocore"; then
            backends=(omx oss)
        else
            backends=(alsa)
        fi
    fi

    # add system(s)
    for backend in "${backends[@]}"; do
        addEmulator 1 "${md_id}-audio-${backend}" "dreamcast" "$md_inst/bin/reicast.sh $backend ${params[*]}"
    done
    addSystem "dreamcast"

    addAutoConf reicast_input 1

    [[ "$md_mode" == "remove" ]] && remove_reicast
    [[ "$md_mode" == "install" ]] && shortcuts_icons_reicast
}

function input_reicast() {
    local temp_file="$(mktemp)"
    cd "$md_inst/bin"
    ./reicast-joyconfig -f "$temp_file" >/dev/tty
    iniConfig " = " "" "$temp_file"
    iniGet "mapping_name"
    local mapping_file="$configdir/dreamcast/mappings/evdev_${ini_value//[:><?\"]/-}.cfg"
    mv "$temp_file" "$mapping_file"
    chown "$__user":"$__group" "$mapping_file"
}

function gui_reicast() {
    while true; do
        local options=(
            1 "Configure input devices for Reicast"
        )
        local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option" 22 76 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        case "$choice" in
            1)
                clear
                input_reicast
                ;;
        esac
    done
}

function shortcuts_icons_reicast() {
    local shortcut_name="Reicast"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=Dreamcast Emulator
Exec=$md_inst/bin/reicast -config config:homedir=\$HOME -config x11:fullscreen=0
Icon=$md_inst/Reicast_72x72.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=DC;$shortcut_name
StartupWMClass=$shortcut_name
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/Reicast_72x72.xpm" << _EOF_
/* XPM */
static char * Reicast_72x72_xpm[] = {
"72 72 295 2",
"   c None",
".  c #4254A7",
"+  c #4053A4",
"@  c #4052A2",
"#  c #4053A3",
"\$     c #3F51A0",
"%  c #4051A1",
"&  c #3F509E",
"*  c #3F519F",
"=  c #3E509C",
"-  c #3E4F9D",
";  c #3E509E",
">  c #3E4F9C",
",  c #3F509F",
"'  c #4052A0",
")  c #40519F",
"!  c #3F519E",
"~  c #3E509D",
"{  c #4154A3",
"]  c #4153A4",
"^  c #3F509D",
"/  c #3F4F9D",
"(  c #3C4D99",
"_  c #3B4B96",
":  c #394991",
"<  c #36458A",
"[  c #344285",
"}  c #303D7C",
"|  c #2E3B78",
"1  c #2A376F",
"2  c #28356B",
"3  c #242F62",
"4  c #222D5E",
"5  c #1C2651",
"6  c #19224B",
"7  c #1E2855",
"8  c #3A4A93",
"9  c #3D4E99",
"0  c #253061",
"a  c #171F45",
"b  c #111736",
"c  c #0B0F29",
"d  c #070A1E",
"e  c #030411",
"f  c #02020B",
"g  c #000004",
"h  c #000005",
"i  c #000007",
"j  c #000009",
"k  c #00000A",
"l  c #00000B",
"m  c #0D112C",
"n  c #344385",
"o  c #253063",
"p  c #01010C",
"q  c #00000C",
"r  c #00000D",
"s  c #00000E",
"t  c #000011",
"u  c #040516",
"v  c #2C3772",
"w  c #3E4E9B",
"x  c #283368",
"y  c #01010E",
"z  c #000012",
"A  c #00000F",
"B  c #000015",
"C  c #03041B",
"D  c #11173C",
"E  c #010213",
"F  c #01010F",
"G  c #1E2753",
"H  c #3C4D98",
"I  c #4152A3",
"J  c #2A366E",
"K  c #01010D",
"L  c #4052A1",
"M  c #3F52A1",
"N  c #4256AA",
"O  c #0F1538",
"P  c #000008",
"Q  c #121939",
"R  c #37468B",
"S  c #2E3B76",
"T  c #030416",
"U  c #40529F",
"V  c #06081C",
"W  c #324080",
"X  c #040619",
"Y  c #01010B",
"Z  c #242F60",
"\`     c #334183",
" . c #06081D",
".. c #161D3F",
"+. c #3A4A92",
"@. c #4051A0",
"#. c #354487",
"\$.    c #090C24",
"%. c #3E4F9B",
"&. c #0A0F29",
"*. c #323F80",
"=. c #0A0D29",
"-. c #0E122F",
";. c #3D4E9B",
">. c #37458B",
",. c #313E7E",
"'. c #2F3D7A",
"). c #2B3871",
"!. c #29356D",
"~. c #28346B",
"{. c #3A4B94",
"]. c #02030E",
"^. c #273267",
"/. c #121736",
"(. c #3D4F9B",
"_. c #3A4A91",
":. c #101532",
"<. c #1F2855",
"[. c #000003",
"}. c #0A0E27",
"|. c #2F3C79",
"1. c #3D4E9A",
"2. c #1C244D",
"3. c #101633",
"4. c #202957",
"5. c #161E43",
"6. c #37478D",
"7. c #171F44",
"8. c #4153A2",
"9. c #2A3770",
"0. c #151C3F",
"a. c #212B5A",
"b. c #05081C",
"c. c #232E60",
"d. c #0A0E28",
"e. c #38478D",
"f. c #020211",
"g. c #222C5C",
"h. c #101635",
"i. c #303D7A",
"j. c #020312",
"k. c #37478E",
"l. c #060922",
"m. c #2C3874",
"n. c #232E5F",
"o. c #2A366F",
"p. c #2D3A75",
"q. c #0B112E",
"r. c #3C4C96",
"s. c #151C40",
"t. c #1D2751",
"u. c #131A3C",
"v. c #384890",
"w. c #4152A4",
"x. c #040515",
"y. c #3B4B95",
"z. c #101533",
"A. c #4154A6",
"B. c #34448A",
"C. c #000016",
"D. c #313F7D",
"E. c #000010",
"F. c #06091F",
"G. c #4154A5",
"H. c #263165",
"I. c #4256A9",
"J. c #364589",
"K. c #3F52A0",
"L. c #324081",
"M. c #4153A5",
"N. c #232E64",
"O. c #4458AE",
"P. c #00010C",
"Q. c #05071D",
"R. c #394A92",
"S. c #13193B",
"T. c #3A4991",
"U. c #06091E",
"V. c #4053A5",
"W. c #1F2955",
"X. c #0D1331",
"Y. c #0D122C",
"Z. c #0D132E",
"\`.    c #161E44",
" + c #07091F",
".+ c #303D7B",
"++ c #4154A4",
"@+ c #1F2956",
"#+ c #02020E",
"\$+    c #303E7C",
"%+ c #37468C",
"&+ c #161E42",
"*+ c #4255A8",
"=+ c #3F509C",
"-+ c #3B4D99",
";+ c #232D5D",
">+ c #242F61",
",+ c #0A0F26",
"'+ c #3B4D97",
")+ c #080D25",
"!+ c #3C4C97",
"~+ c #2A356D",
"{+ c #2D3A74",
"]+ c #1D2651",
"^+ c #0B0F27",
"/+ c #01020E",
"(+ c #0D122E",
"_+ c #3C4C98",
":+ c #0C0F2A",
"<+ c #38488F",
"[+ c #4050A0",
"}+ c #03030F",
"|+ c #3B4C94",
"1+ c #0B102B",
"2+ c #07091E",
"3+ c #070B21",
"4+ c #4052A3",
"5+ c #0B102A",
"6+ c #364488",
"7+ c #050515",
"8+ c #3B4C96",
"9+ c #263265",
"0+ c #090D25",
"a+ c #3A4A94",
"b+ c #3F50A0",
"c+ c #070A1F",
"d+ c #344284",
"e+ c #2B3873",
"f+ c #040617",
"g+ c #38478E",
"h+ c #030311",
"i+ c #2F3B78",
"j+ c #202A58",
"k+ c #212A59",
"l+ c #040517",
"m+ c #2B366F",
"n+ c #364489",
"o+ c #283468",
"p+ c #1D2551",
"q+ c #01010A",
"r+ c #263166",
"s+ c #3C4D97",
"t+ c #334182",
"u+ c #0A0D25",
"v+ c #121837",
"w+ c #344386",
"x+ c #253166",
"y+ c #1A234C",
"z+ c #0F1432",
"A+ c #06081B",
"B+ c #01020D",
"C+ c #1B234B",
"D+ c #3E4E9A",
"E+ c #253062",
"F+ c #010211",
"G+ c #121838",
"H+ c #334284",
"I+ c #070A21",
"J+ c #00010D",
"K+ c #4151A3",
"L+ c #394890",
"M+ c #01020F",
"N+ c #141A3C",
"O+ c #324180",
"P+ c #3D4D98",
"Q+ c #3B4C97",
"R+ c #141A3B",
"S+ c #020210",
"T+ c #2B3872",
"U+ c #3D4D99",
"V+ c #0D1330",
"W+ c #3A4B93",
"X+ c #2F3D7B",
"Y+ c #020313",
"Z+ c #020310",
"\`+    c #1D2652",
" @ c #354589",
".@ c #3B4B94",
"+@ c #2C3974",
"@@ c #1B244D",
"#@ c #04071A",
"\$@    c #020414",
"%@ c #151C3E",
"&@ c #334082",
"*@ c #324082",
"=@ c #121839",
"-@ c #060A21",
";@ c #13193A",
">@ c #1D2550",
",@ c #111838",
"'@ c #05081D",
")@ c #000006",
"!@ c #0C102B",
"~@ c #0A0F28",
"{@ c #010109",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                . + @ # \$ % & * = - - \$                                                         ",
"                                                \$ ; & - > > > > > > > > > > > > > > > > > , +                                                   ",
"                                              > > > > > > > > > > > > > > > > > > > > > > > > - %                                               ",
"                                          ' > > > > > > > > > > > > > > > > > > > > > > > > > > > - ,                                           ",
"                                        ) > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > !                                       ",
"                                      , > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > ~ {                                 ",
"                                    & > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > > ]                               ",
"                                  ; > > > > > > > > > > > > > > > > > > > - ~ ^ / - > > > > > > > > > > > > > > >                               ",
"                                - > > > > > > > & * ^ ~ ( _ : < [ } | 1 2 3 4 5 6 7 8 > > > > > > > > > > > > > > -                             ",
"                              > > > > > > > > 9 0 a b c d e f g g g h i i j k l l j m n ~ > > > > > > > > > > > > > ;                           ",
"                          @ > > > > > > > > > o p l l l l l l q q q q r q s r t r l l u v w > > > > > > > > > > > > > ,                         ",
"                        ) > > > > > > > > - x y z A B C D D                       E l l F G H > > > > > > > > > > > > > I                       ",
"                      ! > > > > > > > > > J K           , & L * & L M & \$ ] L \$ N @ O l l P Q R - > > > > > > > > > > > >                       ",
"                    & > > > > > > > > > S T         U - > > > > > > > > > > > > > > L   k l k V | > > > > > > > > > > > > ~                     ",
"                  ~ > > > > > > > > - W X         L > > > > > > > > > > > > > > > > > &   P l l Y Z H > > > > > > > > > > > &                   ",
"                M > > > > > > > > > \`  .        & > > > > > > > > > > > > > > > > > > > *   t l l l ..+.> > > > > > > > > > > @.                ",
"                - > > > > > > > > #.\$.        * > > > > > %.> > > > > > > > > > > > > > > -     l l k &.*.> > > > > > > > > > &                 ",
"              =._ > > > > > > > R -.        , > > > > > > ;.>.#.,.'.).!.~.{.> > > > > > > > ~     s l l ].^.w > > > > > > > > ~                 ",
"              /.(.> > > > > > _.:.        = > > > > > > 9 <.g [.g g i i i }.|.1.> > > > > > > ,     s l l i 2.8 > > > > > > > >                 ",
"              G & > > > > > 8 3.        & > > > > > > 1.4.p q l r q r q l l K 5.6.> > > > > > > >       l l k 7.%.> > > > > > > 8.              ",
"              9.^ > > > > ( 0.        > > > > > > > %.a.F               A l l l b.c.( > > > > > > ^       r l d.H > > > > > > > M               ",
"              n > > > > > e.f.        > > > > > > > g.j                     r l l P h.i.> > > > > > >       A j.k.> > > > > > > ;               ",
"            l.: > > > > > w         m.> > > > > 1.n.i           @ @ \$ ; ~     A q l l i o.~ > > > > > -       j p.~ > > > > > > ~               ",
"            q.r.> > > > > >       s 3 - > > > > R j.        , > > > > > > >       s l l s.& > > > > > -       k t.~ > > > > > > -               ",
"            u.1.> > > > > >       q 3 - > > > > v.          > > > > > > > > > w.      r x.y.> > > > > >       s z.1.> > > > > > >               ",
"            2.> > > > > > )       q 3 - > > > > A.        B.> > > > > > > > > > L     C.h D.> > > > > >       E.F.8 > > > > > > > #             ",
"            ^.- > > > > > G.      q 3 - > > > >           y.> > > > > > > > > > > \$     j H.> > > > > > I.      f.J.> > > > > > > K.            ",
"            L.> > > > > > M.      q 3 - > > > >         N.w > > > > > > > > > > > ~     q a / > > > > > O.      P.p.- > > > > > > ~             ",
"          Q.R.> > > > > > ]       q 3 - > > > -         S.T.> > > > > > > > > > > &     s U.H > > > > > V.      q W.& > > > > > > %.            ",
"          X.1.> > > > > > ]       q 3 - > > > &         l Y.J.> > > > > > > > > > &     t g L.> > > > > M       r Z.> > > %.%.%.> %.            ",
"          \`.> > > > > > > ]       q 3 - > > > ~         l k  +.+^ > > > > > > > > -       i n.> > > > > ++      E.e : > %.%.%.%.%.%.!           ",
"          @+> > > > > > > ]       q 3 - > > > > =       A l l #+o \$+%+H > > > > > ~       q &+;.> > > > *+        j L.> > =+^ 9 e.-+            ",
"          ;+> > > > > > > ]       q >+- > > > > > - @     A l l k j K ,+'+> > > > >       A )+!+> > > > {         k ~+y.< {+]+^+/+              ",
"          (+_+> > > > > > ]       s :+<+> > > > > > > [+      q l l l }+|+> > > > >       t 1+!+> > > > !         r 2+3+j.P.l l q A             ",
"        t P o > > > > > > 4+      A k 5+6+- > > > > > > &           z 7+8+> > > > ~         9+> > > > > L         A l l q A z                   ",
"          l 0+a+> > > > > > b+    s l k c+d+^ > > > > > > ~           e+1.> > > > >         H > > > > > ]           z                           ",
"          r l c./ > > > > > > ,     z l l u ,.~ > > > > > > - % * ^ > - > > > > J.        # > > > > > > #                                       ",
"            l f+g+> > > > > > > *     q l l h+i+> > > > > > > > > > > > > > > %.j+        - > > > > > > ~                                       ",
"            r l k+^ > > > > > > > ~       l l l+m+> > > > > > > > > > > > > > p.        @.> > > > > > > [+                                      ",
"              l #+n+> > > > > > > > >       l l j.o+- > > > > > > > > > & & y.          ~ > > > > > > !+                                        ",
"              s k p+- > > > > > > > > > @     q l q+r+> & & - s+e.t+| ~.j+0.u+        , > > > > > > a+v+                                        ",
"                l Y w+> > > > > > > > > > \$     l l P 7 x+y+z+A+B+j j k k l           - > > > > > 9 C+                                          ",
"                A k 7.D+> > > > > > > > > > ,     q l l l l l l l q r s A t       + & > > > > > > E+                                            ",
"                  q f.t+- > > > > > > > > > > ^     q r s z B                 \$ - > > > > > > > ).F+                                            ",
"                  E.k G+1.> > > > > > > > > > > ~                         & > > > > > > > > > H+I+                                              ",
"                    l J+]+[ w ~ > > > > > > > > > > K+              @ & > > > > > > > > > > L+m                                                 ",
"                    z l l M+N+O+P+- > > > > > > > > > > > %.> > > %.> > > > > > > > > > > Q+R+                                                  ",
"                      r l l l S+z.T+U+> > > > > > > > > > > > > > > > > > > > > > > > > > <.                                                    ",
"                          s l l k i V+H.W+~ > > > > > > > > > > > > > > > > > > > > > > x l                                                     ",
"                              r q l l i V Z R ^ > > > > > > > > > > > > > > > > > ~ & X+Y+                                                      ",
"                                  A q l l k Z+\`+ @1.- > > > > > > > > > - ~ ;..@< +@@@#@                                                        ",
"                                      A q l l l \$@%@&@1.> > > > > %.1.y.*@n.=@-@j.P.q                                                           ",
"                                            r l l k M+;@T+1.;.6.o.>@,@'@p j k l q s                                                             ",
"                                                s l l k )@!@~@{@g j l l s E.z                                                                   ",
"                                                    s q l l l q s t                                                                             ",
"                                                        r t                                                                                     ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                                                                                                "};
_EOF_
}
