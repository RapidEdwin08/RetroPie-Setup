#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="vice"
rp_module_desc="C64 emulator VICE"
rp_module_help="ROM Extensions: .crt .d64 .g64 .prg .t64 .tap .x64 .zip .vsf\n\nCopy your Commodore 64 games to $romdir/c64"
rp_module_licence="GPL2 http://svn.code.sf.net/p/vice-emu/code/trunk/vice/COPYING"
rp_module_repo="svn svn://svn.code.sf.net/p/vice-emu/code/tags/v3.7.1/vice - HEAD"
rp_module_section="opt"
rp_module_flags=""

function depends_vice() {
    local depends=(libsdl2-dev libsdl2-image-dev libmpg123-dev libpng-dev zlib1g-dev libasound2-dev libvorbis-dev libflac-dev libpcap-dev automake bison flex libjpeg-dev portaudio19-dev xa65 dos2unix)
    isPlatform "x11" && depends+=(libpulse-dev)
    getDepends "${depends[@]}"
}

function sources_vice() {
    svn checkout "$md_repo_url" "$md_build"
}

function build_vice() {
    local params=(--enable-sdl2ui --without-oss --enable-ethernet --enable-x64 --disable-pdf-docs --with-fastsid)
    ! isPlatform "x11" && params+=(--disable-catweasel --without-pulse)
    ./autogen.sh
    ./configure --prefix="$md_inst" "${params[@]}"
    make
    md_ret_require="$md_build/src/x64"
}

function install_vice() {
    make install
}

function game_data_vice() {
    # Artwork and gamelist.xml
    if [[ ! -f "$romdir/c64/+Start Basic.d64" ]] || [[ ! -f "$md_inst/basic.d64" ]]; then # [$md_inst/basic.d64] Required for [Vice Basic.desktop] shortcut
        downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/vice-rp-assets.tar.gz" "$romdir/c64"
        if [[ ! -f "$romdir/c64/gamelist.xml" ]] && [[ ! -f "/opt/retropie/configs/all/emulationstation/gamelists/c64/gamelist.xml" ]]; then mv "$romdir/c64/gamelist.xml.c64" "$romdir/c64/gamelist.xml"; fi
        chown -R $__user:$__user "$romdir/c64"
        if [[ ! -f "$md_inst/basic.d64" ]]; then cp "$romdir/c64/+Start Basic.d64" "$md_inst/basic.d64"; chmod 755 "$md_inst/basic.d64"; fi
    fi
}

function remove_vice() {
    rm -f /usr/share/applications/Vice Basic.desktop
    rm -f "$home/Desktop/Vice Basic.desktop"
    rm -f "$home/RetroPie/roms/c64/+Start Basic.d64"
}

function configure_vice() {
    # get a list of supported extensions
    local exts="$(getPlatformConfig c64_exts)"

    # install the vice start script
    mkdir -p "$md_inst/bin"
    cat > "$md_inst/bin/vice.sh" << _EOF_
#!/bin/bash

BIN="\${0%/*}/\$1"
ROM="\$2"
PARAMS=("\${@:3}")

romdir="\${ROM%/*}"
ext="\${ROM##*.}"
source "$rootdir/lib/archivefuncs.sh"

archiveExtract "\$ROM" "$exts"

# check successful extraction and if we have at least one file
if [[ \$? == 0 ]]; then
    ROM="\${arch_files[0]}"
    romdir="\$arch_dir"
fi

"\$BIN" -chdir "\$romdir" "\${PARAMS[@]}" "\$ROM"
archiveCleanup
_EOF_

    chmod +x "$md_inst/bin/vice.sh"

    mkRomDir "c64"

    addEmulator 1 "$md_id-x64" "c64" "$md_inst/bin/vice.sh x64 %ROM%"
    addEmulator 0 "$md_id-x64dtv" "c64" "$md_inst/bin/vice.sh x64dtv %ROM%"
    addEmulator 0 "$md_id-x64sc" "c64" "$md_inst/bin/vice.sh x64sc %ROM%"
    addEmulator 0 "$md_id-x128" "c64" "$md_inst/bin/vice.sh x128 %ROM%"
    addEmulator 0 "$md_id-xpet" "c64" "$md_inst/bin/vice.sh xpet %ROM%"
    addEmulator 0 "$md_id-xplus4" "c64" "$md_inst/bin/vice.sh xplus4 %ROM%"
    addEmulator 0 "$md_id-xvic" "c64" "$md_inst/bin/vice.sh xvic %ROM%"
    addEmulator 0 "$md_id-xvic-cart" "c64" "$md_inst/bin/vice.sh xvic %ROM% -cartgeneric"
    addSystem "c64"

    [[ "$md_mode" == "remove" ]] && return

    # copy configs and symlink the old and new config folders to $md_conf_root/c64/
    moveConfigDir "$home/.vice" "$md_conf_root/c64"
    moveConfigDir "$home/.config/vice" "$md_conf_root/c64"

    local config="$(mktemp)"
    echo "[C64]" > "$config"
    iniConfig "=" "" "$config"
    if ! isPlatform "x11"; then
        iniSet "Mouse" "1"
        iniSet "VICIIDoubleSize" "0"
        iniSet "VICIIDoubleScan" "0"
        iniSet "VICIIFilter" "0"
        iniSet "VICIIVideoCache" "0"
        iniSet "SDLWindowWidth" "384"
        iniSet "SDLWindowHeight" "272"
    fi

    if isPlatform "arm"; then
        iniSet "SidEngine" "0"
        isPlatform "armv6" && iniSet "SoundSampleRate" "22050"
    fi

    if isPlatform "x11" || isPlatform "kms"; then
        iniSet "VICIIFullscreen" "1"
    fi

    copyDefaultConfig "$config" "$md_conf_root/c64/sdl-vicerc"
    rm "$config"

    if ! isPlatform "x11"; then
        # enforce a few settings to ensure a smooth upgrade from sdl1
        iniConfig "=" "" "$md_conf_root/c64/sdl-vicerc"
        iniDel "SDLBitdepth"
        iniSet "VICIIDoubleSize" "0"
        iniSet "VICIIDoubleScan" "0"
        iniSet "SDLWindowWidth" "384"
        iniSet "SDLWindowHeight" "272"
    fi

    [[ "$md_mode" == "install" ]] && game_data_vice # [$md_inst/basic.d64] Required for [Vice Basic.desktop] shortcut
    [[ "$md_mode" == "install" ]] && shortcuts_icons_vice
}

function shortcuts_icons_vice() {
    local shortcut_name
    shortcut_name="Vice Basic"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=[F12] for MENU
Exec=$md_inst/bin/vice.sh x64 $md_inst/basic.d64
Icon=$md_inst/vice_64x64.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=C64;Basic;Vice
StartupWMClass=Vice
Name[en_US]=$shortcut_name
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/vice_64x64.xpm" << _EOF_
/* XPM */
static char * vice_64x64_xpm[] = {
"64 64 3 1",
"   c None",
".  c #002255",
"+  c #FF0000",
"                              ...                               ",
"                       ................                         ",
"                    ....................                        ",
"                  ......................                        ",
"                ........................                        ",
"              ..........................                        ",
"             ...........................                        ",
"            ............................                        ",
"           .............................                        ",
"          ..............................                        ",
"         ...............................                        ",
"        ................................                        ",
"       .................................                        ",
"      ..................................                        ",
"      ..................................                        ",
"     ........................     ......                        ",
"    .....................             ..                        ",
"    ...................                                         ",
"   ...................                                          ",
"   ..................                                           ",
"   .................                     ...................... ",
"  .................                      .....................  ",
"  ................                       ....................   ",
"  ...............                        ...................    ",
" ................                        ..................     ",
" ...............                         .................      ",
" ...............                         ................       ",
" ...............                         ................       ",
" ..............                          ...............        ",
" ..............                          ..............         ",
" ..............                          .............          ",
"...............                                                 ",
"...............                                                 ",
" ..............                          +++++++++++++          ",
" ..............                          ++++++++++++++         ",
" ..............                          +++++++++++++++        ",
" ...............                         +++++++++++++++        ",
" ...............                         ++++++++++++++++       ",
" ...............                         +++++++++++++++++      ",
" ................                        ++++++++++++++++++     ",
"  ...............                        +++++++++++++++++++    ",
"  ................                       ++++++++++++++++++++   ",
"  .................                      +++++++++++++++++++++  ",
"   .................                     ++++++++++++++++++++++ ",
"   ..................                                           ",
"   ...................                                          ",
"    ...................                                         ",
"    ......................            ..                        ",
"     ........................     ......                        ",
"      ..................................                        ",
"      ..................................                        ",
"       .................................                        ",
"        ................................                        ",
"         ...............................                        ",
"          ..............................                        ",
"           .............................                        ",
"            ............................                        ",
"             ...........................                        ",
"               .........................                        ",
"                ........................                        ",
"                  ......................                        ",
"                    ....................                        ",
"                        ...............                         ",
"                                                                "};
_EOF_
}
