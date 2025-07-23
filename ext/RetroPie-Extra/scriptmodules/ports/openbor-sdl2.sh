#!/usr/bin/env bash

# This file is part of RetroPie-Extra, a supplement to RetroPie.
# For more information, please visit:
#
# https://github.com/RetroPie/RetroPie-Setup
# https://github.com/Exarkuniv/RetroPie-Extra
#
# See the LICENSE file distributed with this source and at
# https://raw.githubusercontent.com/Exarkuniv/RetroPie-Extra/master/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="openbor-sdl2"
rp_module_desc="OpenBOR - Beat 'em Up Game Engine - SDL2 edition"
rp_module_help=" [OpenBOR games should Not need to be extracted]\nPAK files can be placed in:\n$romdir/ports/openbor/\n$romdir/openbor\n \nPAK Extract Utility still available: $rootdir/ports/openbor/extract.sh\n \nPut the PAK you want to Extract in:\n$romdir/ports/openbor/pak\n \nAfter Extract Original PAK files can be found in:\n$romdir/ports/openbor/*.original"
rp_module_licence="BSD https://raw.githubusercontent.com/DCurrent/openbor/refs/heads/master/LICENSE"
rp_module_repo="git https://github.com/DCurrent/openbor.git master"
rp_module_section="exp"
rp_module_flags="sdl2 !mali !rpi3"

function depends_openbor-sdl2() {
    # libsdl1.2-dev libsdl-gfx1.2-dev libogg-dev libvorbisidec-dev libvorbis-dev libpng-dev zlib1g-dev libvpx-dev libsdl-gfx1.2-5
    getDepends libogg-dev libvorbisidec-dev libvorbis-dev libpng-dev zlib1g-dev libvpx-dev libsdl2-dev libsdl2-mixer-dev libsdl2-image-dev libsdl2-gfx-dev
}

function sources_openbor-sdl2() {
    gitPullOrClone
    download "http://raw.githubusercontent.com/crcerror/RetroPie-OpenBOR-scripts/master/extract.sh" "$md_build"
    sed -i s+'/home/pi/'+"/home/$__user/"+g "$md_build/extract.sh"
    sed -i s"+pi\!+$__user\!+g" "$md_build/extract.sh"
    sed -i s"+EXTRACT_BOREXE=.*+EXTRACT_BOREXE=\""$md_inst\""+g" "$md_build/extract.sh"
    sed -i s'+"Aborting.*+"Aborting... No files to extract in $BORPAK_DIR!"; sleep 5+g' "$md_build/extract.sh"
}

function build_openbor-sdl2() {
    btarget=universal; dtarget="UNIVERSAL"
    if [[ "$__platform_arch" =~ (i386|i686) ]]; then btarget=x86; dtarget="X86"; fi
    if [[ "$__platform_arch" == 'x86_64' ]]; then btarget=amd64; dtarget="AMD64"; fi
    if isPlatform "aarch64"; then btarget=arm64; dtarget="ARM64"; fi
    cmake -DBUILD_LINUX=ON -DUSE_SDL=ON -DTARGET_ARCH=$dtarget -S . -B build.lin.$btarget && cmake --build build.lin.$btarget --config Release -- -j
    cd "$md_build/tools/borpak/source"
    chmod 755 ./build.sh; ./build.sh Linux
    md_ret_require=(
        "$md_build/build.lin.$btarget/OpenBOR"
        "$md_build/tools/borpak/source/borpak"
        "$md_build/extract.sh"
    )
}

function install_openbor-sdl2() {
    md_ret_files=(
       "build.lin.$btarget/OpenBOR"
       'tools/borpak/source/borpak'
       'extract.sh'
    )
}

function configure_openbor-sdl2() {
    chmod 755 "$md_inst/extract.sh"
    chmod 755 "$md_inst/borpak"

    mkRomDir "openbor"
    mkRomDir "ports/openbor/"

    local dir
    for dir in ScreenShots Saves; do
        mkUserDir "$md_conf_root/openbor/$dir"
        ln -snf "$md_conf_root/openbor/$dir" "$md_inst/$dir"
    done

    ln -snf "$romdir/ports/openbor" "$md_inst/Paks"
    ln -snf "/dev/shm" "$md_inst/Logs"
    addEmulator 0 "$md_id" "openbor" "pushd $md_inst; $md_inst/OpenBOR %ROM%; popd"

    addSystem "openbor" "OpenBOR" ".zip .pak .bor"
    sed -i s'+_SYS_\ openbor+_PORT_\ openbor+g' /etc/emulationstation/es_systems.cfg
    sed -i s'+<platform>openbor</platform>+<platform>pc</platform>+g' /etc/emulationstation/es_systems.cfg
    if [[ -f /opt/retropie/configs/all/emulationstation/es_systems.cfg ]]; then
        sed -i s'+_SYS_\ openbor+_PORT_\ openbor+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
        sed -i s'+<platform>openbor</platform>+<platform>pc</platform>+g' /opt/retropie/configs/all/emulationstation/es_systems.cfg
    fi
    
    chown -R $__user:$__user "$md_conf_root/$md_id"

}
