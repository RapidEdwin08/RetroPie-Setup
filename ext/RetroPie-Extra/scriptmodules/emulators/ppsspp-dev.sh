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

rp_module_id="ppsspp-dev"
rp_module_desc="PlayStation Portable emulator PPSSPP - latest development version"
rp_module_help="ROM Extensions: .chd .iso .pbp .cso\n\nCopy your PlayStation Portable roms to $romdir/psp"
rp_module_licence="GPL2 https://raw.githubusercontent.com/hrydgard/ppsspp/master/LICENSE.TXT"
rp_module_repo="git https://github.com/hrydgard/ppsspp.git master :_get_commit_ppsspp-dev"
rp_module_section="exp"
rp_module_flags=""

function _get_commit_ppsspp-dev() {
    # Pull Latest Commit SHA - Allow RP Module Script to Check against Latest Source
    local branch=master
    local branch_commit="$(git ls-remote https://github.com/hrydgard/ppsspp.git $branch HEAD | grep $branch | tail -1 | awk '{ print $1}' | cut -c -8)"

    echo $branch_commit
    #echo 40a53315; # 20250910 Delete reference to prebuilt libfreetype, pull in the source instead - CMake Error at ext/freetype/CMakeLists.txt:223 (message): In-source builds are not permitted! Make a separate folder for building
    #echo 28f8ce64; # 20250910 Add freetype as a submodule (2.14.0) - Last Commit Before CMake Error
    #echo eb859735; # 20260303 v1.20.1
}

function depends_ppsspp-dev() {
    local depends=(cmake libbrotli-dev libsnappy-dev libbz2-dev libzip-dev zlib1g-dev libzstd-dev libminiupnpc-dev)
    [[ $md_id != "lr-ppsspp-dev" ]] && depends+=(libsdl2-dev libsdl2-ttf-dev libfontconfig-dev)
    [[ $md_id != "lr-ppsspp-dev" ]] && isPlatform "x11" && depends+=(libx11-dev wayland-protocols libwayland-dev)
    isPlatform "x86" && depends+=(nasm)
    isPlatform "videocore" && depends+=(libraspberrypi-dev)
    isPlatform "mesa" && depends+=(libgles2-mesa-dev)
    isPlatform "vero4k" && depends+=(vero3-userland-dev-osmc)
    getDepends "${depends[@]}"
}

function sources_ppsspp-dev() {
    gitPullOrClone "$md_build/ppsspp"
    cd "ppsspp"

    # remove the lines that trigger the ffmpeg build script functions - we will just use the variables from it
    sed -i "/^build_ARMv6$/,$ d" ffmpeg/linux_arm.sh

    # remove -U__GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 as we handle this ourselves if armv7 on Raspbian
    sed -i "/^  -U__GCC_HAVE_SYNC_COMPARE_AND_SWAP_2/d" cmake/Toolchains/raspberry.armv7.cmake
    # set ARCH_FLAGS to our own CXXFLAGS (which includes GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 if needed)
    sed -i "s/^set(ARCH_FLAGS.*/set(ARCH_FLAGS \"$CXXFLAGS\")/" cmake/Toolchains/raspberry.armv7.cmake

    # remove file(READ "/sys/firmware/devicetree/base/compatible" PPSSPP_PI_MODEL)
    # as it fails when building in a chroot
    sed -i "/^file(READ .*/d" cmake/Toolchains/raspberry.armv7.cmake

    # ensure Pi vendor libraries are available for linking of shared library
    sed -n -i "p; s/^set(CMAKE_EXE_LINKER_FLAGS/set(CMAKE_SHARED_LINKER_FLAGS/p" cmake/Toolchains/raspberry.armv?.cmake
}

function build_ffmpeg_ppsspp-dev() {
    cd "$1"
    local arch
    if isPlatform "arm"; then
        if isPlatform "armv6"; then
            arch="arm"
        else
            arch="armv7"
        fi
    elif isPlatform "x86"; then
        if isPlatform "x86_64"; then
            arch="x86_64";
        else
            arch="x86";
        fi
    elif isPlatform "aarch64"; then
        arch="aarch64"
    fi
    # force to arm arch on arm - fixes building on 32bit arm userland with aarch64 kernel
    isPlatform "arm" && local extra_params='--arch=arm'

    local MODULES
    local VIDEO_DECODERS
    local AUDIO_DECODERS
    local VIDEO_ENCODERS
    local AUDIO_ENCODERS
    local DEMUXERS
    local MUXERS
    local PARSERS
    local GENERAL
    local OPTS # used by older lr-ppsspp fork
    # get the ffmpeg configure variables from the ppsspp ffmpeg distributed script
    source linux_arm.sh
    # linux_arm.sh has set -e which we need to switch off
    set +e
    ./configure $extra_params \
        --prefix="./linux/$arch" \
        --extra-cflags="-fasm -Wno-psabi -fno-short-enums -fno-strict-aliasing -finline-limit=300" \
        --disable-shared \
        --enable-static \
        --enable-zlib \
        --enable-pic \
        --disable-everything \
        ${MODULES} \
        ${VIDEO_DECODERS} \
        ${AUDIO_DECODERS} \
        ${VIDEO_ENCODERS} \
        ${AUDIO_ENCODERS} \
        ${DEMUXERS} \
        ${MUXERS} \
        ${PARSERS}
    make clean
    make install
}

function build_ppsspp-dev() {
    local ppsspp_binary="PPSSPPSDL"

    # build ffmpeg
    build_ffmpeg_ppsspp "$md_build/ppsspp/ffmpeg"

    # build ppsspp
    cd "$md_build/ppsspp"
    rm -fr "build" && mkdir "build"
    cd "build"
    local params=()
    if isPlatform "videocore"; then
        if isPlatform "armv6"; then
            params+=(-DCMAKE_TOOLCHAIN_FILE=cmake/Toolchains/raspberry.armv6.cmake -DFORCED_CPU=armv6 -DATOMIC_LIB=atomic)
        else
            params+=(-DCMAKE_TOOLCHAIN_FILE=cmake/Toolchains/raspberry.armv7.cmake)
        fi
    elif isPlatform "mesa"; then
        params+=(-DUSING_GLES2=ON -DUSING_EGL=OFF)
        # force arm target on arm platforms to fix building on arm 32bit userland with aarch64 kernel
        if isPlatform "arm"; then
            if isPlatform "armv6"; then
                params+=(-DFORCED_CPU=armv6)
            else
                params+=(-DFORCED_CPU=armv7)
            fi
        fi
    elif isPlatform "mali"; then
        params+=(-DUSING_GLES2=ON -DUSING_FBDEV=ON)
        # remove -DGL_GLEXT_PROTOTYPES on odroid-xu/tinker to avoid errors due to header prototype differences
        params+=(-DCMAKE_C_FLAGS="${CFLAGS/-DGL_GLEXT_PROTOTYPES/}")
        params+=(-DCMAKE_CXX_FLAGS="${CXXFLAGS/-DGL_GLEXT_PROTOTYPES/}")
    elif isPlatform "tinker"; then
        params+=(-DCMAKE_TOOLCHAIN_FILE="$md_data/tinker.armv7.cmake")
    fi
    isPlatform "vero4k" && params+=(-DCMAKE_TOOLCHAIN_FILE="cmake/Toolchains/vero4k.armv8.cmake")
    if isPlatform "arm" && ! isPlatform "vulkan"; then
        params+=(-DARM_NO_VULKAN=ON)
    fi
    if isPlatform "vulkan"; then
        params+=(-DUSE_VULKAN_DISPLAY_KHR=ON)
    fi
    if isPlatform "x11"; then
        params+=(-DUSE_WAYLAND_WSI=ON -DUSING_X11_VULKAN=ON)
    fi
    if [[ "$md_id" == "lr-ppsspp-dev" ]]; then
        params+=(-DLIBRETRO=On)
        ppsspp_binary="lib/ppsspp_libretro.so"
    fi
    params+=(-DUSE_SYSTEM_SNAPPY=ON -DUSE_SYSTEM_ZSTD=ON -DUSE_SYSTEM_LIBZIP=ON -DUSE_SYSTEM_LIBSDL2=ON -DUSE_SYSTEM_ZSTD=ON -DUSE_SYSTEM_MINIUPNPC=ON)
    params+=(-DUSE_DISCORD=OFF)
    cmake "${params[@]}" ..
    make clean
    make

    md_ret_require="$md_build/ppsspp/build/$ppsspp_binary"
}

function install_ppsspp-dev() {
    md_ret_files=(
        'ppsspp/build/assets'
        'ppsspp/build/PPSSPPSDL'
    )
}

function remove_ppsspp-dev() {
    rm -f /usr/share/applications/PPSSPP.desktop
    rm -f "$home/Desktop/PPSSPP.desktop"
    rm -f "$home/RetroPie/roms/psp/+Start PPSSPP.gui"
}

function configure_ppsspp-dev() {
    local extra_params=()
    if ! isPlatform "x11"; then
        extra_params+=(--fullscreen)
    fi

    mkRomDir "psp"
    if [[ "$md_mode" == "install" ]]; then
        moveConfigDir "$home/.config/ppsspp" "$md_conf_root/psp"
        mkUserDir "$md_conf_root/psp/PSP"
        ln -snf "$romdir/psp" "$md_conf_root/psp/PSP/GAME"
    fi

    local launch_prefix
    ## Use XINIT to Prevent [runcommand.log] Vulkan with working device not detected. DEBUG: Vulkan is not available, not using Vulkan.
    if ( isPlatform "kms" ) && ( isPlatform "vulkan" ); then launch_prefix="XINIT-WMC:"; fi

    ##addEmulator 0 "$md_id" "psp" "pushd $md_inst; $md_inst/PPSSPPSDL ${extra_params[*]} %ROM%; popd"
    ##addSystem "psp"
    addEmulator 1 "$md_id" "psp" "$launch_prefix$md_inst/$md_id.sh %ROM%"
    addSystem "psp" "PSP" ".gui .chd .iso .pbp .cso" # Additional .GUI Extension to hide +Start PPSSPP.gui (dev) from Game List + Load without Errors

    # if we are removing the last remaining psp emu - remove the symlink
    if [[ "$md_mode" == "remove" ]]; then
        if [[ -h "$home/.config/ppsspp" && ! -f "$md_conf_root/psp/emulators.cfg" ]]; then
            rm -f "$home/.config/ppsspp"
        fi
    fi

    cat >"$md_inst/$md_id.sh" << _EOF_
#!/bin/bash

# Run PPSSPP
pushd $md_inst
if [[ "\$1" == *".gui" ]] || [[ "\$1" == *".GUI" ]]; then
    $md_inst/PPSSPPSDL --fullscreen
elif [[ "\$1" == '' ]]; then
    $md_inst/PPSSPPSDL
else
    $md_inst/PPSSPPSDL --fullscreen "\$1"
fi
popd

_EOF_
    chmod 755 "$md_inst/$md_id.sh"

    cat >"$romdir/psp/+Start PPSSPP.gui" << _EOF_
#!/bin/bash
"/opt/retropie/supplementary/runcommand/runcommand.sh" 0 _SYS_ "psp" ""
_EOF_
    chmod 755 "$romdir/psp/+Start PPSSPP.gui"
    chown $__user:$__user "$romdir/psp/+Start PPSSPP.gui"
    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'psp_StartPPSSPP = "ppsspp-dev"' ; echo $?) == '1' ]]; then echo 'psp_StartPPSSPP = "ppsspp-dev"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi

    [[ "$md_mode" == "remove" ]] && remove_ppsspp-dev
    [[ "$md_mode" == "remove" ]] && return
    [[ "$md_mode" == "install" ]] && shortcuts_icons_ppsspp-dev
}

function shortcuts_icons_ppsspp-dev() {
    local shortcut_name="PPSSPP"
    cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=PPSSPP
GenericName=PPSSPP
Comment=PSP Emulator
Exec=$md_inst/$md_id.sh
Icon=$md_inst/ppsspp_72x72.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=PSP;PlayStationPortable
StartupWMClass=PPSSPP
Name[en_US]=PPSSPP
_EOF_
    chmod 755 "$md_inst/$shortcut_name.desktop"
    if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
    rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

    cat >"$md_inst/ppsspp_72x72.xpm" << _EOF_
/* XPM */
static char * ppsspp_72x72_xpm[] = {
"72 72 610 2",
"   c None",
".  c #48738A",
"+  c #4F7D98",
"@  c #4B768F",
"#  c #507F99",
"\$     c #5486A1",
"%  c #5587A3",
"&  c #4A738C",
"*  c #4D7A95",
"=  c #52829E",
"-  c #4F7D97",
";  c #4A758E",
">  c #4F7E98",
",  c #5687A3",
"'  c #6394AE",
")  c #78A8BE",
"!  c #8CBBCE",
"~  c #73A4BA",
"{  c #5384A0",
"]  c #4D7992",
"^  c #51829C",
"/  c #5586A2",
"(  c #588AA5",
"_  c #6B9CB4",
":  c #80AFC4",
"<  c #94C3D4",
"[  c #A8D6E4",
"}  c #AEDCE8",
"|  c #8EBDCF",
"1  c #5484A1",
"2  c #5E8FAA",
"3  c #72A3B9",
"4  c #87B6CA",
"5  c #9CCADA",
"6  c #ADDBE6",
"7  c #A2D1DF",
"8  c #5688A4",
"9  c #6697B0",
"0  c #7AAABF",
"a  c #8FBED0",
"b  c #A3D1DF",
"c  c #5E90AA",
"d  c #4C7993",
"e  c #A9D8E4",
"f  c #72A3BA",
"g  c #51819C",
"h  c #52839F",
"i  c #87B7C9",
"j  c #4D7B94",
"k  c #9ACAD9",
"l  c #578AA5",
"m  c #4A768E",
"n  c #97C5D5",
"o  c #ADDCE8",
"p  c #ADDBE7",
"q  c #ACDBE7",
"r  c #ACDAE7",
"s  c #ABDAE6",
"t  c #6A9BB3",
"u  c #4F7E99",
"v  c #5485A1",
"w  c #81B1C5",
"x  c #ADDBE8",
"y  c #AAD9E6",
"z  c #AAD9E5",
"A  c #A9D9E5",
"B  c #A9D8E5",
"C  c #A8D8E5",
"D  c #A8D8E4",
"E  c #A8D7E4",
"F  c #7BACC1",
"G  c #6D9EB5",
"H  c #A7D7E4",
"I  c #A6D6E3",
"J  c #A5D6E3",
"K  c #A5D5E3",
"L  c #A4D5E2",
"M  c #8BBDCF",
"N  c #4B768E",
"O  c #598CA7",
"P  c #A8D7E3",
"Q  c #A6D7E4",
"R  c #A3D4E2",
"S  c #A3D4E1",
"T  c #A2D4E1",
"U  c #A2D3E1",
"V  c #A1D3E1",
"W  c #A1D3E0",
"X  c #A0D2E0",
"Y  c #9ACDDB",
"Z  c #95C7D6",
"\`     c #A1D2E0",
" . c #9FD2DF",
".. c #9FD1DF",
"+. c #9ED1DF",
"@. c #9DD0DE",
"#. c #9CCFDE",
"\$.    c #5F92AC",
"%. c #81B4C7",
"&. c #9CD0DE",
"*. c #9CCFDD",
"=. c #9BCFDD",
"-. c #9BCEDD",
";. c #9ACEDC",
">. c #99CDDC",
",. c #98CDDB",
"'. c #6EA1B8",
"). c #52829D",
"!. c #49758C",
"~. c #507E98",
"{. c #6FA1B8",
"]. c #98CCDB",
"^. c #97CCDB",
"/. c #97CBDA",
"(. c #96CBDA",
"_. c #95CADA",
":. c #95C9D8",
"<. c #6295AE",
"[. c #4C7891",
"}. c #51819B",
"|. c #5E91AA",
"1. c #95CAD9",
"2. c #94CAD9",
"3. c #93C9D8",
"4. c #92C8D8",
"5. c #92C8D7",
"6. c #77ABC0",
"7. c #4E7B96",
"8. c #53839F",
"9. c #598AA6",
"0. c #6B9DB4",
"a. c #5C8DA8",
"b. c #50809B",
"c. c #8EC3D4",
"d. c #94C9D9",
"e. c #91C8D7",
"f. c #91C7D7",
"g. c #90C7D7",
"h. c #90C7D6",
"i. c #8FC6D6",
"j. c #8EC6D6",
"k. c #87BDCE",
"l. c #5789A5",
"m. c #4A758F",
"n. c #50809A",
"o. c #5F91AA",
"p. c #88B8CB",
"q. c #9CCBDB",
"r. c #75A6BD",
"s. c #5486A2",
"t. c #7EB3C6",
"u. c #8EC6D5",
"v. c #8EC5D5",
"w. c #8DC5D5",
"x. c #8DC4D4",
"y. c #8CC4D4",
"z. c #8BC3D4",
"A. c #8BC3D3",
"B. c #6498B0",
"C. c #5788A4",
"D. c #6798B0",
"E. c #7BABC0",
"F. c #90BFD1",
"G. c #A4D2E1",
"H. c #8AB9CB",
"I. c #5E90AB",
"J. c #7FB6C9",
"K. c #8AC3D3",
"L. c #8AC2D3",
"M. c #89C2D3",
"N. c #89C2D2",
"O. c #88C1D2",
"P. c #74ACC0",
"Q. c #699BB3",
"R. c #82B3C6",
"S. c #98C6D7",
"T. c #9ECDDC",
"U. c #49738A",
"V. c #4E7D97",
"W. c #699EB5",
"X. c #85BECF",
"Y. c #88C1D1",
"Z. c #87C0D1",
"\`.    c #86C0D1",
" + c #86C0D0",
".+ c #85BFD0",
"++ c #84BFD0",
"@+ c #80B9CB",
"#+ c #598BA6",
"\$+    c #4E7A94",
"%+ c #6294AE",
"&+ c #AEDBE7",
"*+ c #5A8CA7",
"=+ c #4E7D95",
"-+ c #73AABF",
";+ c #83BFD0",
">+ c #84BECF",
",+ c #83BECF",
"'+ c #83BDCF",
")+ c #82BDCE",
"!+ c #81BCCE",
"~+ c #81BCCD",
"{+ c #649AB2",
"]+ c #5484A0",
"^+ c #97C6D6",
"/+ c #6D9EB7",
"(+ c #53849F",
"_+ c #5F93AD",
":+ c #78B3C5",
"<+ c #80BBCD",
"[+ c #7FBBCD",
"}+ c #7FBBCC",
"|+ c #7EBACC",
"1+ c #71ABBF",
"2+ c #75A5BC",
"3+ c #81B2C6",
"4+ c #5587A2",
"5+ c #5487A2",
"6+ c #52849E",
"7+ c #5588A4",
"8+ c #679EB6",
"9+ c #7AB6C9",
"0+ c #7BB8CA",
"a+ c #7AB7CA",
"b+ c #78B5C8",
"c+ c #598DA7",
"d+ c #508099",
"e+ c #5B8DA7",
"f+ c #A6D5E2",
"g+ c #92C2D3",
"h+ c #5386A1",
"i+ c #52839E",
"j+ c #4C7992",
"k+ c #598DA8",
"l+ c #6DA8BD",
"m+ c #77B5C8",
"n+ c #639BB2",
"o+ c #8BBACD",
"p+ c #A6D7E3",
"q+ c #A0D1DE",
"r+ c #5386A0",
"s+ c #52859F",
"t+ c #4A778E",
"u+ c #5F95AE",
"v+ c #69A4BA",
"w+ c #5587A4",
"x+ c #699AB3",
"y+ c #ABDBE7",
"z+ c #A3D5E2",
"A+ c #6093AB",
"B+ c #50849D",
"C+ c #4D7E96",
"D+ c #6394AD",
"E+ c #74A5BB",
"F+ c #48758D",
"G+ c #5687A2",
"H+ c #9FD2E0",
"I+ c #70A4B8",
"J+ c #4F839C",
"K+ c #4F829A",
"L+ c #6B9CB3",
"M+ c #7EAFC3",
"N+ c #93C3D3",
"O+ c #A7D6E3",
"P+ c #A5D4E1",
"Q+ c #71A2B9",
"R+ c #4F7F9A",
"S+ c #53869F",
"T+ c #5385A0",
"U+ c #79AABF",
"V+ c #7DB3C5",
"W+ c #4E839A",
"X+ c #4E829A",
"Y+ c #5586A3",
"Z+ c #91C0D1",
"\`+    c #5D8FAA",
" @ c #4A768D",
".@ c #5284A0",
"+@ c #4B7A91",
"@@ c #4E7E96",
"#@ c #5B8FA6",
"\$@    c #9ED0DE",
"%@ c #97CCDA",
"&@ c #95CBDA",
"*@ c #8BC0D1",
"=@ c #4D8299",
"-@ c #4C8298",
";@ c #427083",
">@ c #A8D6E3",
",@ c #77A7BD",
"'@ c #50829B",
")@ c #4C7C93",
"!@ c #51839D",
"~@ c #446E83",
"{@ c #51849E",
"]@ c #88BBCB",
"^@ c #52889E",
"/@ c #4B8197",
"(@ c #47788C",
"_@ c #4B7790",
":@ c #A7D5E2",
"<@ c #4A7A91",
"[@ c #6498AD",
"}@ c #8DC4D5",
"|@ c #8BC4D4",
"1@ c #6097AA",
"2@ c #4A8095",
"3@ c #497E94",
"4@ c #92C2D2",
"5@ c #ABD9E6",
"6@ c #7DADC0",
"7@ c #497A92",
"8@ c #4E839B",
"9@ c #6CA0B4",
"0@ c #87C1D1",
"a@ c #6CA3B6",
"b@ c #497F93",
"c@ c #487F93",
"d@ c #7EAEC2",
"e@ c #9CCBD9",
"f@ c #6194AA",
"g@ c #4F839B",
"h@ c #4A7C93",
"i@ c #4D8298",
"j@ c #4C8198",
"k@ c #53899F",
"l@ c #7DB2C4",
"m@ c #77B0C3",
"n@ c #477E92",
"o@ c #50829C",
"p@ c #689AB1",
"q@ c #6FA1B5",
"r@ c #497D92",
"s@ c #4B8196",
"t@ c #4A8096",
"u@ c #6197AB",
"v@ c #85BDCF",
"w@ c #7EB9CB",
"x@ c #488092",
"y@ c #467E90",
"z@ c #407283",
"A@ c #4A7891",
"B@ c #5388A0",
"C@ c #9ED1DE",
"D@ c #568CA0",
"E@ c #497B91",
"F@ c #47788E",
"G@ c #417081",
"H@ c #498095",
"I@ c #498094",
"J@ c #4E8499",
"K@ c #6FA8B9",
"L@ c #7FBACC",
"M@ c #7DBACB",
"N@ c #7DB9CB",
"O@ c #7CB9CB",
"P@ c #7BB7CA",
"Q@ c #71ADBE",
"R@ c #4D8597",
"S@ c #457D8F",
"T@ c #43788A",
"U@ c #9AC9D7",
"V@ c #71A5B8",
"W@ c #4B8095",
"X@ c #406E80",
"Y@ c #417284",
"Z@ c #44788A",
"\`@    c #487F92",
" # c #568FA2",
".# c #79B3C6",
"+# c #76B4C6",
"@# c #6AA6B8",
"## c #5E99AB",
"\$#    c #528C9E",
"%# c #478092",
"&# c #82B4C4",
"*# c #8BC0CF",
"=# c #407083",
"-# c #487E93",
";# c #467C8F",
"># c #457B8D",
",# c #467E91",
"'# c #649DB0",
")# c #7CB8CB",
"!# c #79B7C9",
"~# c #71AEC1",
"{# c #65A1B2",
"]# c #5993A6",
"^# c #4D8799",
"/# c #457E8F",
"(# c #427889",
"_# c #3E7283",
":# c #4D8198",
"<# c #4D829A",
"[# c #6A9EB1",
"}# c #5A91A3",
"|# c #497F94",
"1# c #457B8E",
"2# c #447689",
"3# c #477E91",
"4# c #407484",
"5# c #3F7080",
"6# c #4F889A",
"7# c #68A3B6",
"8# c #609BAD",
"9# c #558EA1",
"0# c #498293",
"a# c #447B8D",
"b# c #407586",
"c# c #3B6C7C",
"d# c #477A8D",
"e# c #55899F",
"f# c #73AABC",
"g# c #6699AB",
"h# c #487E92",
"i# c #437B8C",
"j# c #43798A",
"k# c #3F7282",
"l# c #407081",
"m# c #91C4D4",
"n# c #86BDCF",
"o# c #4C8396",
"p# c #407383",
"q# c #6398A8",
"r# c #9BCBD8",
"s# c #5D92A3",
"t# c #407587",
"u# c #3B6B7A",
"v# c #447C8D",
"w# c #447C8F",
"x# c #417687",
"y# c #3D6F7F",
"z# c #7BB0C1",
"A# c #5E96A7",
"B# c #447A8C",
"C# c #3D7081",
"D# c #4A8193",
"E# c #A2D1DE",
"F# c #84B6C4",
"G# c #4C8494",
"H# c #457C8E",
"I# c #3A6B7A",
"J# c #3C6D7D",
"K# c #669EAF",
"L# c #90C6D6",
"M# c #84BED0",
"N# c #73ADBE",
"O# c #81B3C2",
"P# c #A6D4E1",
"Q# c #6B9FB0",
"R# c #44788B",
"S# c #548B9E",
"T# c #82BDCF",
"U# c #7CB8C9",
"V# c #4E8799",
"W# c #407585",
"X# c #5C92A3",
"Y# c #94C4D1",
"Z# c #558C9D",
"\`#    c #457D8E",
" \$    c #3D7080",
".\$    c #3E7080",
"+\$    c #467D90",
"@\$    c #467E8F",
"#\$    c #82BCCD",
"\$\$   c #7CB8CA",
"%\$    c #7AB7C9",
"&\$    c #79B6C9",
"*\$    c #5F9AAD",
"=\$    c #447C8E",
"-\$    c #477F91",
";\$    c #9DCCD9",
">\$    c #ACDAE6",
",\$    c #7BAEBD",
"'\$    c #3D6E7E",
")\$    c #70ABBD",
"!\$    c #78B6C8",
"~\$    c #76B5C7",
"{\$    c #75B4C7",
"]\$    c #71ADC1",
"^\$    c #64A0B3",
"/\$    c #3A6878",
"(\$    c #79ACBB",
"_\$    c #9ACBD9",
":\$    c #6096A6",
"<\$    c #417586",
"[\$    c #619BAD",
"}\$    c #75B3C6",
"|\$    c #74B2C6",
"1\$    c #6AA8BB",
"2\$    c #609CAE",
"3\$    c #548FA2",
"4\$    c #4A8396",
"5\$    c #427788",
"6\$    c #568C9D",
"7\$    c #689FAF",
"8\$    c #437A8C",
"9\$    c #538D9F",
"0\$    c #74B3C6",
"a\$    c #73B2C5",
"b\$    c #70AFC2",
"c\$    c #65A2B5",
"d\$    c #5A96A9",
"e\$    c #518B9D",
"f\$    c #417484",
"g\$    c #457E90",
"h\$    c #96C6D4",
"i\$    c #80B4C4",
"j\$    c #3F7283",
"k\$    c #609EB0",
"l\$    c #5691A5",
"m\$    c #4D8698",
"n\$    c #457D90",
"o\$    c #3F7180",
"p\$    c #447B8C",
"q\$    c #71A5B4",
"r\$    c #8EC4D2",
"s\$    c #3B6A7A",
"t\$    c #3D6D7D",
"u\$    c #518899",
"v\$    c #A9D7E3",
"w\$    c #4F8799",
"x\$    c #43798B",
"y\$    c #3E7182",
"z\$    c #7DB0BF",
"A\$    c #5F97A7",
"B\$    c #3F7384",
"C\$    c #42798A",
"D\$    c #6CA0B0",
"E\$    c #6CA5B6",
"F\$    c #3F7182",
"G\$    c #548A9B",
"H\$    c #99CDDB",
"I\$    c #76B1C3",
"J\$    c #A0D0DC",
"K\$    c #80BCCD",
"L\$    c #498093",
"M\$    c #3E6E7F",
"N\$    c #86B8C8",
"O\$    c #417686",
"P\$    c #6EA3B3",
"Q\$    c #86BFD0",
"R\$    c #72B2C5",
"S\$    c #5B97AA",
"T\$    c #3F7484",
"U\$    c #5890A0",
"V\$    c #70B0C4",
"W\$    c #6DAEC2",
"X\$    c #619FB4",
"Y\$    c #3C6B7C",
"Z\$    c #478091",
"\`\$   c #91C6D6",
" % c #6EAEC2",
".% c #6BADC1",
"+% c #69ABBF",
"@% c #65A7BC",
"#% c #3A6979",
"\$%    c #7EB4C6",
"%% c #6EAFC2",
"&% c #69ABC0",
"*% c #66A9BE",
"=% c #64A8BD",
"-% c #61A6BB",
";% c #4A8497",
">% c #407384",
",% c #6AA3B3",
"'% c #7AB8CA",
")% c #71B1C4",
"!% c #6EAFC3",
"~% c #6CADC1",
"{% c #67AABE",
"]% c #62A6BB",
"^% c #5FA4BA",
"/% c #5DA3B8",
"(% c #4F8DA1",
"_% c #417889",
":% c #5992A4",
"<% c #78B6C9",
"[% c #76B4C7",
"}% c #73B2C6",
"|% c #62A6BC",
"1% c #5FA3B9",
"2% c #589BB0",
"3% c #5291A6",
"4% c #4D8A9D",
"5% c #478093",
"6% c #4B8394",
"7% c #7DBACC",
"8% c #6FAFC3",
"9% c #6AACC0",
"0% c #67AABF",
"a% c #63A5BA",
"b% c #5A9AAE",
"c% c #5291A4",
"d% c #4B8799",
"e% c #71B1C5",
"f% c #6CAEC2",
"g% c #65A5B9",
"h% c #5B99AD",
"i% c #528EA1",
"j% c #4A8496",
"k% c #3C6E7D",
"l% c #629FB2",
"m% c #71AFC4",
"n% c #65A4B7",
"o% c #5B97AB",
"p% c #518B9E",
"q% c #488193",
"r% c #3C6A7B",
"s% c #3E7180",
"                                                                                                                                                ",
"                                                                                                                                                ",
"                                                                            . +                                                                 ",
"                                                                    @ # \$ % % % &                                                               ",
"                                                            * = % % % % % % % % -                                                               ",
"                                                  ; > \$ % % % % % % , ' ) ! ~ % {                                                               ",
"                                          ] ^ / % % % % % % ( _ : < [ } } } | % %                                                               ",
"                                    1 % % % % % % % 2 3 4 5 6 } } } } } } } 7 % %                                                               ",
"                                    % % % 8 9 0 a b } } } } } } } } } } } } } c % d                                                             ",
"                                    % % : e } } } } } } } } } } } } } } } } } f % g                                                             ",
"                                    h % 0 } } } } } } } } } } } } } } } } } } i % /                                                             ",
"                                    j % 9 } } } } } } } } } } } } } } } } } } k % %                                                             ",
"                                      % 8 e } } } } } } } } } } } } } } } } } 6 l % m                                                           ",
"                                      % % n } } } } } } } } } } } } o p q q r s t % u                                                           ",
"                                      v % w } } } } x p q q r s s y z A B C D E F % v                                                           ",
"                                      u % G s s s y z A B C D H H H I I J K L L M % %                                                           ",
"                                      N % O P H H Q I I J K L L R S T U V W W X Y % %                                                           ",
"                                        % % Z L R S T U V W \` X X  ...+.+.@.@.@.#.\$.% j                                                         ",
"                                        % % %.X X  ...+.+.@.@.&.*.*.=.-.;.;.>.>.,.'.% ).                                  !.~.\$ %               ",
"                                        ).% {.&.*.=.=.-.;.;.>.>.,.].^.^./.(.(._.:.<.% %                           [.}./ % % % % % [.            ",
"                                        d % |.>.,.].^.^./.(.(.1.1.2.2.3.3.3.4.5.6.% % \$                 . 7.8.% % % % % % 9.0.a.% b.            ",
"                                          % % c.1.2.d.3.3.4.4.5.e.f.g.h.i.i.j.k.l.% % !.        m.n./ % % % % % % o.~ p.q.q } r.% s.            ",
"                                          % % t.f.f.h.h.i.i.u.v.w.w.x.y.y.z.A.B.% % =         % % % % % C.D.E.F.G.} } } } } } H.% %             ",
"                                          { % I.J.w.y.y.y.z.A.K.L.M.N.O.O.O.P.% % %         v % % Q.R.S.z } } } } } } } } } } T.% % U.          ",
"                                          V.% % , W.X.O.O.Y.Z.Z.\`. +.+.+++@+#+% % \$+      - % % %+s } } } } } } } } } } } } } &+*+% =+          ",
"                                            v % % % #+-+;+>+,+,+'+)+)+!+~+{+% % ]+        % % % ^+} } } } } } } } } } } } } } } /+% (+          ",
"                                              7.% % % % _+:+<+[+}+|+|+|+1+% % %         (+% % 2+} } } } } } } } } } } } } } } p 3+4+5+          ",
"                                                  6+% % % 7+8+9+0+0+a+b+c+% % d+      ] % % e+f+} } } } } } } } } p q r s y z B g+h+h+          ",
"                                  \$+i+% ).          j+% % % % k+l+m+m+n+% % /         % % % o+} } } } p q r s y z B C E H p+I J q+r+s+t+        ",
"                        ; > v % % % % % % % ]           ).% % % % u+v+w+% % m       ).% % x+y+r s y z B C E H I I J L z+S T V W X A+B+C+        ",
"                j+}./ % % % % % % D+E+*+% % % (+          !./ % % % % % % ).      F+s.s.G+k C E H I I K L z+S T V W X H+..+.@.@.#.I+J+K+        ",
"      . 7.8.% % % % % % l L+M+N+O+} } P+Q+% % % % R+          n.% % 5+5+s.        S+r+T+U+K L z+S T V W X H+..+.@.@.#.=.-.;.>.>.,.V+W+X+        ",
"    Y+% % % % % c 3 i k 6 } } } } } } } } Z+\`+% % % s. @          .@h+r++@      @@s+s+#@\$@W X  ...+.@.@.#.=.-.;.>.>.,.^.%@(.&@1.2.*@=@-@;@      ",
"    n.% C.0 a b } } } } } } } } } } } } } } >@,@s.\$ h+h+'@          )@!@      ~@{@B+B+]@@.@.#.=.-.;.>.>.].^.%@(.&@1.2.3.3.4.e.f.h.i.^@/@(@      ",
"    _@% % :@} } } } } } } } } } } } } } } } } } ^+o.s+s+s+s+<@                K+J+J+[@;.>.>.].^.%@(.&@1.2.3.3.4.e.f.h.i.i.v.w.}@y.|@1@2@3@      ",
"      % % 4@} } } } } } } } } } } } } } } } } } } 5@6@T+B+B+B+X+            7@8@W+W+8@9@e.1.2.3.3.4.e.f.h.i.i.v.w.x.y.|@A.K.M.N.O.0@a@b@c@      ",
"      5+s.d@} } } } } } } } } } } } } } } } } } } } } e@f@J+g@g@8@h@          (@=@i@-@j@k@l@h.i.i.v.w.x.y.z.A.K.M.N.O.0@Z.\`..+.+>+,+m@n@n@      ",
"      o@r+p@} } } } } } } } } } } } } } } } p q s y A C O+q@X+=@=@;@              r@/@s@s@t@u@v@A.K.M.N.O.0@Z.\`..+.+>+,+'+)+!+~+<+[+w@x@y@z@    ",
"      A@s+B@r } } } } } } } } } p q s y A B D H I J L R C@D@-@j@E@      F@          G@3@H@I@I@J@K@\`..+.+>+,+'+)+!+~+<+[+L@|+M@N@O@P@Q@R@S@T@    ",
"        B+B+U@} } } p q s y A B D H I J L R T U W X ..+.V@/@s@W@      X@2@2@Y@          Z@c@\`@\`@n@ #.#~+<+[+L@|+M@N@O@0+0++#@###\$#%#S@S@S@S@    ",
"        g@g@&#y z B D H I J L R S U W X ..+.@.&.=.-.;.*#s@2@2@=#      -#c@c@c@;#            >#,#y@y@x@'#)#0+0+a+!#~#{#]#^#/#S@S@S@S@S@S@(#_#    ",
"        :#<#[#J L z+S U W X ..+.@.&.*.-.;.>.].^.(.&@2.}#|#|#1#      2#n@n@3#3#3#,#4#          5#S@S@S@S@6#7#8#9#0#S@S@S@S@S@S@a#b#c#            ",
"        d#j@e#X ..+.@.&.*.-.;.>.,.^.(.&@1.d.3.4.e.g.f#\`@\`@n@        ,#y@y@g#h#S@S@S@i#            (#S@S@S@S@S@S@S@S@S@j#k#                      ",
"        l#s@s@m#;.>.,.^.(.(.1.d.3.4.e.g.i.j.v.w.y.n#o#,#,#p#      i#S@S@q#} r#s#S@S@S@S@t#          u#v#S@S@w#x#y#                              ",
"          2@H@z#1.2.3.4.e.g.i.i.v.w.y.z.K.M.O.O.Z.A#S@S@B#      C#S@S@D#E#} } x F#G#S@S@S@H#I#          J#                                      ",
"          -#c@K#L#i.v.w.y.z.K.M.O.O.Z.\`..+M#,+)+N#S@S@S@        S@S@S@O#} } } } } P#Q#S@S@S@S@(#                                                ",
"          R#3#S#K.M.N.O.Z.\`..+M#,+T#)+~+<+}+|+U#V#S@S@W#      (#S@S@X#&+} } } } } } } Y#Z#S@S@S@\`# \$                                            ",
"          .\$+\$@\$#\$M#,+T#)+~+<+[+|+M@O@\$\$0+%\$&\$*\$S@S@=\$      I#S@S@-\$;\$} } } } } } } } } >\$,\$x@S@S@S@'\$                                          ",
"            S@S@)\$[+|+M@O@\$\$0+%\$&\$!\$m+~\${\$]\$^\$-\$S@S@/\$      =\$S@S@(\$} } } } } } } } } } p y _\$:\$S@S@<\$                                          ",
"            S@S@[\$%\$&\$!\$m+~\${\$}\$|\$1\$2\$3\$4\$S@S@S@S@5\$      W#S@S@6\$>\$} } } } } } } } x s C I R W 7\$S@a#                                          ",
"            8\$S@9\$}\$0\$a\$b\$c\$d\$e\$%#S@S@S@S@S@S@i#f\$        S@S@g\$h\$} } } } } } } o s C I L W ..#.i\$S@S@                                          ",
"            j\$S@x@k\$l\$m\$n\$S@S@S@S@S@S@(#o\$              p\$S@S@q\$} } } } } } } s B p+L V ..&.;.^.r\$S@S@                                          ",
"            s\$S@S@S@S@S@S@S@=\$W#t\$                      S@S@u\$v\$} } } } } r B H L U  .@.;.].&@3.g.w\$S@k#                                        ",
"              S@S@S@x\$y\$                                S@S@z\$} } } } r A H L U H+@.-.].(.3.f.v.y.A\$S@T@                                        ",
"              B\$                                        C\$S@D\$} } q z H K T X @.-.,.(.3.f.j.y.L.Z.E\$S@S@                                        ",
"                                                        F\$S@G\$q y H J T X \$@=.H\$(.d.e.i.y.L.0@.+)+I\$S@S@                                        ",
"                                                          S@S@J\$J S X +.=.>.(.2.e.i.y.K.O..+'+K\$|+P@L\$S@M\$                                      ",
"                                                          S@S@N\$\` +.*.>.%@2.5.i.w.K.O..+,+K\$|+\$\$!#m+9\$S@O\$                                      ",
"                                                          a#S@P\$*.>.^.1.4.L#w.A.O.Q\$,+~+|+O@!#m+0\$R\$S\$S@H#                                      ",
"                                                          T\$S@U\$^.1.4.h.w.A.O.\`.>+!+L@O@%\$m+}\$R\$V\$W\$X\$S@S@                                      ",
"                                                          Y\$S@Z\$\`\$h.v.z.N.\`.>+!+}+O@a+m+{\$R\$V\$ %.%+%@%/#S@#%                                    ",
"                                                            S@S@\$%|@N.\`.>+)+[+N@a+!\${\$a\$V\$%%.%&%*%=%-%;%S@>%                                    ",
"                                                            \`#S@,%Z.++)+[+N@'%!\${\$a\$)%!%~%&%{%=%]%^%/%(%S@x\$                                    ",
"                                                            _%S@:%)+<+N@0+<%[%}%)%!%~%&%{%=%|%1%2%3%4%5%S@S@                                    ",
"                                                             \$S@6%7%0+&\$[%0\$)%8%~%9%0%a%b%c%d%y@S@S@S@S@S@S@                                    ",
"                                                              S@S@~#~\$0\$e%8%f%g%h%i%j%/#S@S@S@S@S@S@a#<\$k%                                      ",
"                                                              S@S@l%m%n%o%p%q%S@S@S@S@S@S@S@j#y\$                                                ",
"                                                              x\$S@q%,#S@S@S@S@S@S@w#5\$y#                                                        ",
"                                                              j\$S@S@S@S@S@B#T\$r%                                                                ",
"                                                                S@(#s%                                                                          ",
"                                                                                                                                                ",
"                                                                                                                                                "};
_EOF_
}
