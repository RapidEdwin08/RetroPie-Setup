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

rp_module_id="lr-geolith"
rp_module_desc="Libretro version of Geolith emulator for the Neo Geo AES, MVS, CD, and CDZ"
rp_module_help="ROM Extension: .neo .bin .cue .chd\n\nCopy your roms to\n$romdir/neogeo\n$romdir/neogeocd\n\nBIOS files from a recent MAME set are required:\n- aes.zip for Neo Geo AES (Home Console)\n- neogeo.zip for Neo Geo MVS (Arcade) and Universe BIOS\n- neocd.zip + neocdz.zip for NeoGeoCD (both required)\n- neocdz.zip for Neo Geo CDZ and CD Universe BIOS\n- irrmaze.zip for The Irritating Maze in MVS mode\n\nBIOS files should be copied to:\n$biosdir/"
rp_module_licence="GPL3 https://raw.githubusercontent.com/libretro/geolith-libretro/master/LICENSE"
rp_module_repo="git https://github.com/libretro/geolith-libretro.git master"
rp_module_section="exp"

function sources_lr-geolith() {
    gitPullOrClone
}

function build_lr-geolith() {
    pushd "$md_build/libretro"
    make clean
    make
    popd
    md_ret_require="$md_build/libretro/geolith_libretro.so"
}

function install_lr-geolith() {
    md_ret_files=(
        'README'
        'LICENSE'
        'libretro/geolith_libretro.so'
    )
}

function configure_lr-geolith() {
    mkRomDir "neogeo"
    mkRomDir "neogeocd"

    defaultRAConfig "neogeo"
    defaultRAConfig "neogeocd"

    addEmulator 0 "$md_id" "neogeo" "$md_inst/geolith_libretro.so"
    addEmulator 1 "$md_id" "neogeocd" "$md_inst/geolith_libretro.so"

    # neogeo_exts=".7z .chd .cue .fba .iso .zip" # geolith_exts=".neo .bin"
    addSystem "neogeo" "Neo Geo" ".7z .chd .cue .fba .iso .zip .neo .bin"
    addSystem "neogeocd" "NeoGeoCD" ".7z .chd .cue .fba .iso .zip .neo .bin"
}
