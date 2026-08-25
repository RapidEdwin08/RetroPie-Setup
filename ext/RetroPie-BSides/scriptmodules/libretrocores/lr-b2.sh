#! /usr/bin/env bash

# RetroPie scriptmodule to install the libretro core of b2,
# the BBC Micro emulator

# Copyright 2026 Gemba @ Github
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# ---
# **Additional Notes**
#
# - Review `~/.emulationstation/es_systems.cfg` at the
#   `<name>bbcmicro</name>` section system, if you need to add more file
#   extensions. This module sets `.dsd` and `.ssd` as extensions in that file.
# - This libretro core set the game focus to ON by default
#   (`input_auto_game_focus=1`) in `/opt/retropie/configs/retroarch.cfg` respective
#   `retroarch.cfg.rp-dist`.
# - The key to toggle the game focus behaviour is by default _Scroll Lock_
# - The toggle game focus is set to button 3 of the joystick/gamecontroller. To
#   change, review the information at:
#   `https://retropie.org.uk/docs/RetroArch-Configuration/#determining-button-values`
#
# **References**
#
# - Extensive [libretro core
# documentation](https://docs.libretro.com/library/b2/) and further links at the
# end of that page.
# - Project site: https://github.com/zoltanvb/b2-libretro

rp_module_id="lr-b2"
rp_module_desc="BBC Micro emulator: Libretro core of the b2 emulator for RetroArch"
rp_module_help="ROM Extension: .dsd .ssd .zip\n\nCopy your roms to $romdir/bbcmicro"
rp_module_licence="GPL2 https://raw.githubusercontent.com/zoltanvb/b2-libretro/refs/heads/master/src/COPYING"
rp_module_repo="git https://github.com/zoltanvb/b2-libretro.git master"
rp_module_section="exp"
rp_module_flags=""

function sources_lr-b2() {
    gitPullOrClone
}

function build_lr-b2() {
    pushd "$md_build/src/libretro"
    make clean
    make
    popd
    md_ret_require="$md_build/src/libretro/b2_libretro.so"
}

function install_lr-b2() {
    md_ret_files=(
        'src/COPYING'
        'src/libretro/b2_libretro.so'
    )
}

function configure_lr-b2() {
    local system_name="bbcmicro"

    # input_game_focus_toggle_btn:
    # Disable at all if defined in parent Retroarch configs or
    # adjust button number below to your controller setup.
    # cf: https://retropie.org.uk/docs/RetroArch-Configuration/#determining-button-values
    defaultRAConfig "$system_name" "input_game_focus_toggle_btn" "3"

    if [[ "$md_mode" == "install" ]]; then
        local path="/opt/retropie/configs/$system_name"
        local ra_conf="$path/retroarch.cfg"
        local ra_conf_rpdist="$path/retroarch.cfg.rp-dist"

        local fn="$ra_conf"
        if [[ -e "$ra_conf_rpdist" ]]; then
            fn="$ra_conf_rpdist"
        fi

        # input_auto_game_focus: {0: off, 1: on, 2: detect}
        ! grep -q "input_auto_game_focus =" "$fn" &&
            sed -i "/^input_remapping_directory =/a input_auto_game_focus = \"1\"" "$fn"

        mkRomDir "$system_name"
        # update ~/.emulationstation/es_systems.cfg
        local xpath="/systemList/system[name='$system_name']"
        local system_bbc_es_cfg="$(xmlstarlet select \
            --template \
            --copy-of "$xpath" \
            "/etc/emulationstation/es_systems.cfg")"

        local user_es_cfg="$home/.emulationstation/es_systems.cfg"
        # if not there add system from global es_systems.cfg
        if [[ $(xmlstarlet select \
            --template \
            -v "count($xpath)" \
            "$user_es_cfg") -eq 0 ]]; then
            sed -i "/<\/systemList>/d" "$user_es_cfg"
            printf "%s" "$system_bbc_es_cfg" >>"$user_es_cfg"
            printf "%s" "</systemList>" >>"$user_es_cfg"
        fi

        # set system fullname if not present
        [[ -z "$(xmlstarlet select \
            --template \
            --copy-of "$xpath/fullname/text()" "$user_es_cfg" | xargs)" ]] &&
            xmlstarlet edit \
                --inplace \
                --update "$xpath/fullname" \
                --value "BBC Microcomputer System" "$user_es_cfg"

        # check mandatory extensions present
        local current_exts=$(xmlstarlet select \
            --template \
            --copy-of "$xpath/extension/text()" \
            "$user_es_cfg" | xargs)

        for ext in ".dsd" ".ssd"; do
            if [[ "$current_exts" != *"$ext"* ]]; then
                current_exts=$(printf "%s" "$current_exts $ext" | xargs)
                xmlstarlet edit \
                    --inplace \
                    --update "$xpath/extension" \
                    --value "$current_exts" \
                    "$user_es_cfg"
            fi
        done

        # sort user's es_systems.cfg
        local tmp_piggy=$(mktemp)
        cp "$user_es_cfg" "$tmp_piggy"
        xmlstarlet select --xml-decl --indent \
            --template --match "/" --elem "systemList" \
            --match "//system" --sort A:T:U "name" --copy-of "." \
            "$tmp_piggy" >"$user_es_cfg"
        rm "$tmp_piggy"
    fi

    addEmulator 0 "$md_id" "$system_name" "$md_inst/b2_libretro.so"
    addSystem "$system_name"
}
