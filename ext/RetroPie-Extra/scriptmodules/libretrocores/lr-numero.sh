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

rp_module_id="lr-numero"
rp_module_desc="lr-numero - Numero is a libretro core for emulating the TI-83 family of graphing calculators."
rp_module_help="ROM Extensions: .8xp .8xk .8xg\n\nPlace TI-83 ROMs in: $romdir/ti83/\n\nPlace TI-83 BIOS in: $biosdir/\nti83se.rom      TI-83 Silver Edition   *Recommended*\nti83plus.rom    TI-83 Plus\nti83.rom        TI-83\n\n{ti83se.rom}:\nhttps://web.archive.org/web/20230208002249/http://tiroms.weebly.com/uploads/1/1/0/5/110560031/ti83se.rom\n\n{ti83plus.rom}\nhttps://web.archive.org/web/20230208002249/http://tiroms.weebly.com/uploads/1/1/0/5/110560031/ti83plus.rom"
rp_module_repo="git https://github.com/nbarkhina/numero.git master"
rp_module_section="exp"
rp_module_flags=""

function sources_lr-numero() {
    gitPullOrClone
}

function build_lr-numero() {
    make -f Makefile.libretro clean
    make -f Makefile.libretro
    md_ret_require="$md_build/numero_libretro.so"
}

function install_lr-numero() {
    md_ret_files=(
        'LICENSE'
        'numero_libretro.so'
    )
}

function configure_lr-numero() {
    mkRomDir "ti83"
    ensureSystemretroconfig "ti83"

    addEmulator 1 "$md_id" "ti83" "$md_inst/numero_libretro.so"
    addSystem "ti83" "TI-83" ".8xp .8xk .8xg"
}
