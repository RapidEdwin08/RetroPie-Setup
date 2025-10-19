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

rp_module_id="lr-duckstation"
rp_module_desc="PlayStation emulator - Duckstation for libretro"
rp_module_help="ROM Extensions: .exe .cue .bin .chd .psf .m3u .pbp\n\nCopy your PlayStation roms to $romdir/psx\n\nCopy compatible BIOS files to $biosdir"
rp_module_licence="PROP https://creativecommons.org/licenses/by-nc-nd/4.0"
rp_module_section="exp"
rp_module_flags="!all arm !armv6 aarch64 64bit"

function __binary_url_lr-duckstation() {
    local url="https://github.com/batocera-linux/lr-duckstation/raw/master/duckstation_libretro_linux_"
    isPlatform "aarch64" && echo "${url}aarch64.zip"
    isPlatform "arm" && echo "${url}armv7.zip"
    isPlatform "x86" && isPlatform "64bit" && echo "${url}x64.zip"
}

function install_bin_lr-duckstation() {
    downloadAndExtract "$(__binary_url_lr-duckstation)" "$md_inst"
}

function configure_lr-duckstation() {
    mkRomDir "psx"
    ensureSystemretroconfig "psx"

    if isPlatform "gles" && ! isPlatform "gles3"; then
        # Hardware renderer not supported on GLES2 devices
        setRetroArchCoreOption "duckstation_GPU.Renderer" "Software"
    fi

    # Pi 4 has occasional slowdown with hardware rendering
    # e.g. Gran Turismo 2 (Arcade) race start
    if [[ "$__os_debian_ver" -le 10 ]]; then
        isPlatform "rpi4" && setRetroArchCoreOption "duckstation_GPU.Renderer" "Software"
    fi

    # Configure the memory card 1 saves through the libretro API
    setRetroArchCoreOption "duckstation_MemoryCards.Card1Type" "NonPersistent"

    # dynarec segfaults without redirecting stdin from </dev/null
    addEmulator 0 "$md_id" "psx" "$md_inst/duckstation_libretro.so </dev/null"
    addSystem "psx"
}