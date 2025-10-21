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

rp_module_id="prboom-plus"
rp_module_desc="Doom/Doom II engine - Enhanced PRBoom Port"
rp_module_help="*[libpcre3-dev] HAS BEEN DEPRECATED SINCE 202503*\n \n[libpcre3-dev] is Required for PRBoom-Plus\n \nTHIS SCRIPT CAN/WILL INSTALL [libpcre3-dev] FROM .DEBs\n \n[libpcre3-dev]*.DEBs CAN BE UNINSTALLED MANUALLY WITH:\n \nsudo dpkg -r libpcre3-dbg libpcre16-3 libpcrecpp0v5 libpcre32-3 libpcre3-dev libpcre3"
rp_module_licence="https://github.com/coelckers/prboom-plus"
rp_module_repo="git https://github.com/coelckers/prboom-plus.git master"
rp_module_section="exp"

function depends_prboom-plus() {
    #local depends=(libsdl2-dev libsdl2-net-dev libsdl2-image-dev libsdl2-mixer-dev libfluidsynth-dev libportmidi-dev libmad0-dev libdumb1-dev libvorbis-dev zlib1g-dev libogg-dev)
    local depends=(
        cmake libsdl2-dev libsdl2-net-dev libsdl2-image-dev
        libsdl2-mixer-dev libfluidsynth-dev libportmidi-dev
        libmad0-dev libdumb1-dev libvorbis-dev zlib1g-dev libogg-dev)

    if [[ "$__os_debian_ver" -le 12 ]]; then
        depends+=(libpcre3-dev)
    fi
    [[ "$__gcc_version" -gt 12 ]] && depends+=(gcc-12 g++-12)
    getDepends "${depends[@]}"

    if [[ "$md_mode" == "install" ]] && [[ $(dpkg -l | grep libpcre3) == '' ]]; then deb_pcre3_prboom-plus; fi
}

function deb_pcre3_prboom-plus() {
    # pcre3 was Removed between February-March of 2025
    if [[ "$__os_debian_ver" -ge 13 ]]; then
        #depends+=(libpcre2-dev)
        local pcre3_arch=$(dpkg --print-architecture)
        wget http://http.us.debian.org/debian/pool/main/p/pcre3/libpcre3_8.39-15_$pcre3_arch.deb -P /tmp
        wget http://http.us.debian.org/debian/pool/main/p/pcre3/libpcrecpp0v5_8.39-15_$pcre3_arch.deb -P /tmp
        wget http://http.us.debian.org/debian/pool/main/p/pcre3/libpcre3-dbg_8.39-15_$pcre3_arch.deb -P /tmp
        wget http://http.us.debian.org/debian/pool/main/p/pcre3/libpcre16-3_8.39-15_$pcre3_arch.deb -P /tmp
        wget http://http.us.debian.org/debian/pool/main/p/pcre3/libpcre32-3_8.39-15_$pcre3_arch.deb -P /tmp
        wget http://http.us.debian.org/debian/pool/main/p/pcre3/libpcre3-dev_8.39-15_$pcre3_arch.deb -P /tmp

        # Retain this Installation 0rder...
        dpkg -i /tmp/libpcre3_8.39-15_$pcre3_arch.deb
        dpkg -i /tmp/libpcrecpp0v5_8.39-15_$pcre3_arch.deb
        dpkg -i /tmp/libpcre3-dbg_8.39-15_$pcre3_arch.deb
        dpkg -i /tmp/libpcre16-3_8.39-15_$pcre3_arch.deb
        dpkg -i /tmp/libpcre32-3_8.39-15_$pcre3_arch.deb
        dpkg -i /tmp/libpcre3-dev_8.39-15_$pcre3_arch.deb

        rm -f /tmp/libpcre3_8.39-15_$pcre3_arch.deb
        rm -f /tmp/libpcrecpp0v5_8.39-15_$pcre3_arch.deb
        rm -f /tmp/libpcre3-dbg_8.39-15_$pcre3_arch.deb
        rm -f /tmp/libpcre16-3_8.39-15_$pcre3_arch.deb
        rm -f /tmp/libpcre32-3_8.39-15_$pcre3_arch.deb
        rm -f /tmp/libpcre3-dev_8.39-15_$pcre3_arch.deb

        echo *PCRE3 HAS BEEN REMOVED FROM TRIXIE AND WILL NO LONGER BE UPDATED*
        echo LIBPCRE3*.DEBs CAN BE UNINSTALLED MANUALLY WITH: [sudo dpkg -r libpcre3-dbg libpcre16-3 libpcrecpp0v5 libpcre32-3 libpcre3-dev libpcre3]
    fi
}

function sources_prboom-plus() {
    gitPullOrClone
}

function build_prboom-plus() {
    cd prboom2
#    ./bootstrap
#    ./configure
    if [[ "$__gcc_version" -gt 12 ]]; then export CC=/usr/bin/gcc-12; export CXX=/usr/bin/g++-12; fi
    cmake .
    make
    md_ret_require="$md_build/prboom2/prboom-plus"
    if [[ "$__gcc_version" -gt 12 ]]; then unset CC; unset CXX; fi
}

function install_prboom-plus() {
    md_ret_files=(
        'prboom2/prboom-plus'
        'prboom2/prboom-plus.wad'
    )
}

function game_data_prboom-plus() {
    if [[ ! -f "$romdir/ports/doom/doom1.wad" ]]; then
        # download doom 1 shareware
        wget -nv -O "$romdir/ports/doom/doom1.wad" "$__archive_url/doom1.wad"
        chown $__user:$__user "$romdir/ports/doom/doom1.wad"
    fi
}

function _add_games_prboom-plus() {
    local cmd="$1"
    declare -A games=(
        ['doom1']="Doom"
        ['doom2']="Doom 2"
        ['tnt']="TNT - Evilution"
        ['plutonia']="The Plutonia Experiment"
    )
    local game
    local wad
    for game in "${!games[@]}"; do
        wad="$romdir/ports/doom/$game.wad"
        if [[ -f "$wad" ]]; then
            addPort "$md_id" "doom" "${games[$game]}" "$cmd" "$wad"
        fi
    done
}

function add_games_prboom-plus() {
    _add_games_prboom-plus "pushd $md_inst; $md_inst/prboom-plus -iwad %ROM%; popd"
}

function gui_prboom-plus() {
    choice=$(dialog --title "[$md_id] Configuration Options" --menu "      ADD or REMOVE DEPRECATED LIBPCRE3*.DEBs\n\nsudo dpkg -r libpcre3-dbg libpcre16-3 libpcrecpp0v5 libpcre32-3 libpcre3-dev libpcre3\n\nSee [Package Help] for Details" 15 60 5 \
        "1" "INSTALL libpcre3*.deb PKGs" \
        "2" "REMOVE libpcre3*.deb PKGs" \
        "3" "apt --fix-broken install" \
        "4" "Cancel" 2>&1 >/dev/tty)

    case $choice in
        1)
            deb_pcre3_prboom-plus
            ;;
        2)
            sudo dpkg -r libpcre3-dbg libpcre16-3 libpcrecpp0v5 libpcre32-3 libpcre3-dev libpcre3
            ;;
        3)
            sudo apt --fix-broken install
            ;;
        4)
            echo "Canceled"
            ;;
        *)
            echo "Invalid Selection"
            ;;
    esac
}

function configure_prboom-plus() {
    setConfigRoot "ports"

    mkRomDir "ports/doom"
    moveConfigDir "$home/.prboom-plus" "$md_conf_root/prboom-plus"

    [[ "$md_mode" == "install" ]] && game_data_prboom-plus

    add_games_prboom-plus

    cp prboom-plus.wad "$romdir/ports/doom/"
    chown $__user:$__user "$romdir/ports/doom/prboom-plus.wad"
}
