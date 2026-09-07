#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# 20230509 Bumped to v1.12.3
# https://github.com/hiulit/RetroPie-Godot-Game-Engine-Emulator
#
# 20251130 Updated to include V4 Godot Engines
# https://github.com/RapidEdwin08/RetroPie-Setup
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

# Scriptmodule variables ############################

rp_module_id="godot-engine-v4"
rp_module_desc="Godot Engine v4 (https://godotengine.org/)."
rp_module_help="Game extensions: .pck .zip."
rp_module_help+="\n\nCopy your games to $romdir/godot-engine."
rp_module_help+="\n\nAuthor: hiulit (https://github.com/hiulit)."
rp_module_help+="\n\nRepository: https://github.com/hiulit/RetroPie-Godot-Game-Engine-Emulator"
rp_module_help+="\n\nLicenses:"
rp_module_help+="\n- Source code, Godot Engine and FRT: MIT."
rp_module_help+="\n- Godot logo: CC BY 3.0."
rp_module_help+="\n- Godot pixel logo: CC BY-NC-SA 4.0."
rp_module_licence="MIT https://raw.githubusercontent.com/hiulit/RetroPie-Godot-Game-Engine-Emulator/master/LICENSE"
rp_module_section="exp"
rp_module_flags="x86 x86_64 aarch64 rpi1 rpi2 rpi3 rpi4 rpi5"

function depends_godot-engine-v4() {
    local depends=(unzip)
    #depends+=(p7zip-full) # Portal.dmg
    isPlatform "kms" && depends+=(xorg matchbox-window-manager)

    getDepends "${depends[@]}"
}

# Global variables ##################################

RP_MODULE_ID=godot-engine
TMP_DIR="$home/.tmp/$RP_MODULE_ID"
SETTINGS_DIR="$romdir/$RP_MODULE_ID/settings"
CONFIGS_DIR="/opt/retropie/configs/$RP_MODULE_ID"

SCRIPT_VERSION="1.12.3"
VERSION_MAJOR="$(echo "$SCRIPT_VERSION" | cut -d "." -f 1)"
VERSION_MINOR="$(echo "$SCRIPT_VERSION" | cut -d "." -f 2)"
VERSION_PATCH="$(echo "$SCRIPT_VERSION" | cut -d "." -f 3)"

GODOT_VERSIONS=(
    "2.1.6"
    "3.0.6"
    "3.2.3"
    "3.4.5"
    "3.5.2"
)

GODOT4_VERSIONS=(
    "4.2.2"
    "4.3"
    "4.4.1"
    "4.5.2"
    "4.6.3"
    "4.7.2"
)

AUDIO_DRIVERS=(
    "SDL2"
    "ALSA"
    "PulseAudio"
)
AUDIO_DRIVER="SDL2"
if [[ ! "$(dpkg --list | grep -i pulseaudio)" == '' ]] && isPlatform "x86"; then AUDIO_DRIVER="PulseAudio"; fi

VIDEO_DRIVERS=(
    "GLES2"
    "GLES3"
)
VIDEO_DRIVER="GLES3"
isPlatform "gl2" && VIDEO_DRIVER="GLES2"

FRT_KEYBOARD_ID=""
FRT_KMSDRM_DEVICE=""

RESOLUTION=""

ES_THEMES_DIR="/etc/emulationstation/themes"
ES_DEFAULT_THEME="carbon-2021"
GODOT_THEMES=(
    "$ES_DEFAULT_THEME"
    "carbon"
    "pixel"
)

CARBON_2021_CONTROLLER_IMAGE="$ES_THEMES_DIR/carbon-2021/art/controllers/godot-engine.svg"
CARBON_2021_SYSTEM_IMAGE="$ES_THEMES_DIR/carbon-2021/art/systems/godot-engine.svg"

OVERRIDE_CFG_DEFAULTS_FILE="$SETTINGS_DIR/.override-defaults.cfg"
OVERRIDE_CFG_FILE="$romdir/$RP_MODULE_ID/override.cfg" # This file must be in the same folder as the games.
SETTINGS_CFG_DEFAULTS_FILE="$SETTINGS_DIR/.godot-engine-settings-defaults.cfg"
SETTINGS_CFG_FILE="$SETTINGS_DIR/godot-engine-settings.cfg"


# Flags ###############################

X11_FLAG="false"

if [[ -n "$(echo $DISPLAY)" ]]; then
    X11_FLAG="true"
fi


# Configuration dialog variables ####################

readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_EXTRA=3
readonly DIALOG_ESC=255
readonly DIALOG_BACKTITLE="Godot Engine Configuration (v$SCRIPT_VERSION)"
readonly DIALOG_HEIGHT=8
readonly DIALOG_WIDTH=60

DIALOG_OPTIONS=()

# Configuration dialog functions ####################

function _main_config_dialog() {
    local i=1
    local options=()
    local commands=()
    local cmd
    local choice

    for option in "${DIALOG_OPTIONS[@]}"; do
        case "$option" in
            "virtual_keyboard")
                if [[ -n "$FRT_KEYBOARD_ID" ]]; then
                    options+=("$i" "GPIO/Virtual keyboard ($FRT_KEYBOARD_ID)")
                else
                    options+=("$i" "GPIO/Virtual keyboard")
                fi
                commands+=("$i" "_gpio_virtual_keyboard_dialog")
                ;;
            "kms_drm_driver")
                if [[ -n "$FRT_KMSDRM_DEVICE" ]]; then
                    options+=("$i" "KMS/DRM driver ("$(basename "$FRT_KMSDRM_DEVICE")")")
                else
                    options+=("$i" "KMS/DRM driver")
                fi
                commands+=("$i" "_kms_drm_driver_dialog")
                ;;
            "audio_driver")
                options+=("$i" "Audio driver ("$AUDIO_DRIVER")")
                commands+=("$i" "_audio_driver_dialog")
                ;;
            "video_driver")
                options+=("$i" "Video driver ("$VIDEO_DRIVER")")
                commands+=("$i" "_video_driver_dialog")
                ;;
            "edit_override")
                options+=("$i" "Edit \"override.cfg\"")
                commands+=("$i" "_edit_override_cfg_dialog")
                ;;
            "install_themes")
                options+=("$i" "Install themes")
                commands+=("$i" "_install_themes_dialog")
                ;;
        esac
        ((i++))
    done

    cmd=(dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "" \
            --ok-label "OK" \
            --cancel-label "Back" \
            --menu "Choose an option." \
            15 "$DIALOG_WIDTH" 15)
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            eval "${commands[choice*2-1]}"
        fi
    fi
}


function _gpio_virtual_keyboard_dialog() {
    local i=1
    local options=()
    local cmd
    local choice
    local message

    options+=("$i" "None")

    while IFS= read -r line; do
        ((i++))
        line="$(echo "$line" | sed -e 's/^"//' -e 's/"$//')" # Remove leading and trailing double quotes.
        options+=("$i" "$line")
    done < <(cat "/proc/bus/input/devices" | grep "N: Name" | cut -d= -f2)

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "GPIO/Virtual keyboard" \
        --ok-label "OK" \
        --cancel-label "Back" \
        --menu "Choose an option." \
        15 "$DIALOG_WIDTH" 15)

    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            if [[ "${options[choice*2-1]}" == "None" ]]; then
                FRT_KEYBOARD_ID=""
                message="The GPIO/Virtual keyboard has been unset."
            else
                FRT_KEYBOARD_ID="${options[choice*2-1]}"
                message="The GPIO/Virtual keyboard ($FRT_KEYBOARD_ID) has been set."
            fi

            _set_config "gpio_virtual_keyboard" "$FRT_KEYBOARD_ID"

            configure_godot-engine-v4

            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "" \
                --ok-label "OK" \
                --msgbox "$message" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

            _main_config_dialog
        else
            # If there is no choice that means the user selected "Back".
            _main_config_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _kms_drm_driver_dialog() {
    local i=1
    local options=()
    local cmd
    local choice
    local message

    options+=("$i" "None")

    for file in "/dev/dri/"*; do
        if [[ ! -d "$file" ]]; then
            ((i++))
            options+=("$i" "$(basename "$file")")
        fi
    done

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "KMS/DRM driver" \
        --ok-label "OK" \
        --cancel-label "Back" \
        --menu "Choose an option." \
        15 "$DIALOG_WIDTH" 15)

    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            if [[ "${options[choice*2-1]}" == "None" ]]; then
                FRT_KMSDRM_DEVICE=""
                message="The KMS/DRM driver has been unset."
            else
                FRT_KMSDRM_DEVICE="/dev/dri/${options[choice*2-1]}"
                message="The KMS/DRM driver ("$(basename "$FRT_KMSDRM_DEVICE")") has been set."
            fi

            _set_config "kms_drm_driver" "$FRT_KMSDRM_DEVICE"

            configure_godot-engine-v4

            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "" \
                --ok-label "OK" \
                --msgbox "$message" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

            _main_config_dialog
        else
            # If there is no choice that means the user selected "Back".
            _main_config_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _audio_driver_dialog() {
    local i=1
    local options=()
    local cmd
    local choice

    for audio_driver in "${AUDIO_DRIVERS[@]}"; do
        options+=("$i" "$audio_driver")
        ((i++))
    done

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Audio driver" \
        --ok-label "OK" \
        --cancel-label "Back" \
        --menu "Choose an option." \
        15 "$DIALOG_WIDTH" 15)

    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            AUDIO_DRIVER="${options[choice*2-1]}"

            _set_config "audio_driver" "$AUDIO_DRIVER"

            configure_godot-engine-v4

            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "" \
                --ok-label "OK" \
                --msgbox "The audio driver ($AUDIO_DRIVER) has been set." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

            _main_config_dialog
        else
            # If there is no choice that means the user selected "Back".
            _main_config_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _video_driver_dialog() {
    local i=1
    local options=()
    local cmd
    local choice

    for video_driver in "${VIDEO_DRIVERS[@]}"; do
        options+=("$i" "$video_driver")
        ((i++))
    done

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Video driver" \
        --ok-label "OK" \
        --cancel-label "Back" \
        --menu "Choose an option." \
        15 "$DIALOG_WIDTH" 15)

    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            VIDEO_DRIVER="${options[choice*2-1]}"

            _set_config "video_driver" "$VIDEO_DRIVER"

            configure_godot-engine-v4

            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "" \
                --ok-label "OK" \
                --msgbox "The video driver ($VIDEO_DRIVER) has been set." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

            _main_config_dialog
        else
            # If there is no choice that means the user selected "Back".
            _main_config_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _edit_override_cfg_dialog() {
    local override_cfg

    override_cfg="$(dialog \
                    --backtitle "$DIALOG_BACKTITLE" \
                    --title "Edit \"override.cfg\"" \
                    --ok-label "Save" \
                    --cancel-label "Back" \
                    --extra-button \
                    --extra-label "Reset" \
                    --editbox "$OVERRIDE_CFG_FILE" 15 "$DIALOG_WIDTH" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        echo "$override_cfg" > "$OVERRIDE_CFG_FILE"

        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "" \
            --ok-label "OK" \
            --msgbox "\"override.cfg\" updated successfully!" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
        dialog \
            --backtitle "$DIALOG_BACKTITLE" \
            --title "" \
            --yesno "Would you like to reset \"override.cfg\" to the default values?" "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty
        local return_value="$?"

        if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
            cat "$OVERRIDE_CFG_DEFAULTS_FILE" > "$OVERRIDE_CFG_FILE"

            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "" \
                --ok-label "OK" \
                --msgbox "\"override.cfg\" has been reset to the default values." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

            _edit_override_cfg_dialog
        elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
            _edit_override_cfg_dialog
        elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
            _edit_override_cfg_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _install_themes_dialog() {
    local i=1
    local options=()
    local themes=()
    local cmd
    local choice

    for theme in "${GODOT_THEMES[@]}"; do
        themes+=("$theme")

        if [[ -d "$ES_THEMES_DIR/$theme/godot-engine" ]]; then
            if [[ "$theme" == "$ES_DEFAULT_THEME" ]]; then
                options+=("$i" "Update $theme (installed)")
            else
                options+=("$i" "Update or uninstall $theme (installed)")
            fi
        else
            if [[ "$theme" == "carbon-2021" ]]; then
                if [[ -f "$CARBON_2021_CONTROLLER_IMAGE" ]] && [[ -f "$CARBON_2021_SYSTEM_IMAGE" ]]; then
                    options+=("$i" "Update or uninstall $theme (installed)")
                else
                    options+=("$i" "Install $theme")
                fi
            else
                options+=("$i" "Install $theme")
            fi
        fi

        ((i++))
    done

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Install themes" \
        --ok-label "OK" \
        --cancel-label "Back" \
        --menu "Choose an option." \
        15 "$DIALOG_WIDTH" 15)

    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            local theme="${themes[choice-1]}"

            if [[ "${options[choice*2-1]}" =~ "(installed)" ]] ; then
                _update_uninstall_themes_dialog "$theme"
            else
                if [[ ! -d "$ES_THEMES_DIR/$theme" ]]; then
                    dialog \
                        --backtitle "$DIALOG_BACKTITLE" \
                        --title "" \
                        --ok-label "OK" \
                        --msgbox "The '$theme' theme must be installed on EmulationStation before installing the 'godot-engine' system in it." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty
                else
                    echo "Installing $theme theme..."
                    action="installed"
                    _install_update_theme "$theme"

                    dialog \
                        --backtitle "$DIALOG_BACKTITLE" \
                        --title "" \
                        --ok-label "OK" \
                        --msgbox "The $theme theme has been installed." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty
                fi

                _install_themes_dialog
            fi
        else
            # If there is no choice that means the user selected "Back".
            _main_config_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _update_uninstall_themes_dialog() {
    local theme="$1"
    local options=()
    local cmd
    local choice

    if [[ "$theme" == "$ES_DEFAULT_THEME" ]]; then
        _install_update_theme "$theme"
        _install_themes_dialog
    fi

    options=(
        1 "Update $theme"
        2 "Uninstall $theme"
    )

    cmd=(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "Update or uninstall theme" \
        --ok-label "OK" \
        --cancel-label "Back" \
        --menu "Choose an option." \
        15 "$DIALOG_WIDTH" 15)

    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            local action

            case "$choice" in
                1)
                    echo "Updating $theme theme..."
                    action="updated"
                    _install_update_theme "$theme"
                    ;;
                2)
                    action="uninstalled"
                    _uninstall_theme "$theme"
                    ;;
            esac

            dialog \
                --backtitle "$DIALOG_BACKTITLE" \
                --title "" \
                --ok-label "OK" \
                --msgbox "The $theme theme has been $action." "$DIALOG_HEIGHT" "$DIALOG_WIDTH" 2>&1 >/dev/tty

            _install_themes_dialog
        else
            # If there is no choice that means the user selected "Back".
            _install_themes_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        _install_themes_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _install_themes_dialog
    fi
}


# Helper functions ##################################

function rmFileExists() {
    if [[ -f "$1" ]]; then
        rm "$1"
    fi
}


function _set_config() {
    if [[ ! -f "$SETTINGS_CFG_FILE" ]]; then
        mkUserDir "$SETTINGS_DIR"
        download "https://raw.githubusercontent.com/hiulit/RetroPie-Godot-Engine-Emulator/master/godot-engine-settings.cfg" "$SETTINGS_DIR"
    fi
    sed -i "s|^\($1\s*=\s*\).*|\1\"$2\"|" "$SETTINGS_CFG_FILE"
    chown -R "$user:$user" "$SETTINGS_CFG_FILE"
}


function _get_config() {
    local config
    config="$(grep -Po "(?<=^$1 = ).*" "$SETTINGS_CFG_FILE")"
    config="${config%\"}"
    config="${config#\"}"
    echo "$config"
}


function _install_update_theme() {
    local theme="$1"
    local tmp_dir="$TMP_DIR/themes"
    mkUserDir "$tmp_dir"
    rmDirExists "$ES_THEMES_DIR/$theme/godot-engine"
    gitPullOrClone "$tmp_dir" "https://github.com/hiulit/RetroPie-Godot-Engine-Emulator"
 
    if [[ "$theme" == "carbon-2021" ]]; then
        cp "$tmp_dir/art/controller.svg" "$CARBON_2021_CONTROLLER_IMAGE"
        cp "$tmp_dir/art/system.svg" "$CARBON_2021_SYSTEM_IMAGE"
    else
        cp -r "$tmp_dir/themes/$theme/godot-engine" "$ES_THEMES_DIR/$theme"
    fi

    rmDirExists "$tmp_dir"
}


function _uninstall_theme() {
    local theme="$1"

    if [[ "$theme" == "carbon-2021" ]]; then
        rm "$CARBON_2021_CONTROLLER_IMAGE"
        rm "$CARBON_2021_SYSTEM_IMAGE"
    else
        rmDirExists "$ES_THEMES_DIR/$theme/godot-engine"
    fi
}


function _install_update_scraper() {
    local scraper_dir=""$home/RetroPie-Itchio-Godot-Scraper""
    rmDirExists "$scraper_dir"
    gitPullOrClone "$scraper_dir" "https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper"
    chown -R "$user:$user" "$scraper_dir"
    chmod +x "$scraper_dir/setup.sh" && chown -R "$user:$user" "$scraper_dir/setup.sh"
    chmod +x "$scraper_dir/retropie-itchio-godot-scraper.sh" && chown -R "$user:$user" "$scraper_dir/retropie-itchio-godot-scraper.sh"
    bash "$scraper_dir/setup.sh" -i retropie-menu
}


# Scriptmodule functions ############################

function sources_godot-engine-v4() {
    local url="https://github.com/hiulit/RetroPie-Godot-Game-Engine-Emulator/releases/download/v${VERSION_MAJOR}.${VERSION_MINOR}.0"

    for version in "${GODOT_VERSIONS[@]}"; do
        if isPlatform "x86" && ! isPlatform "x86_64"; then
            downloadAndExtract "${url}/godot_${version}_x11_32.zip" "$md_build"
        elif isPlatform "x86_64"; then
            downloadAndExtract "${url}/godot_${version}_x11_64.zip" "$md_build"
        elif isPlatform "aarch64"; then
            downloadAndExtract "${url}/frt_${version}_arm64.zip" "$md_build"
        elif isPlatform "rpi1"; then
            downloadAndExtract "${url}/frt_${version}_pi1.zip" "$md_build"
        elif isPlatform "rpi2" || isPlatform "rpi3" || isPlatform "rpi4"; then
            downloadAndExtract "${url}/frt_${version}_pi2.zip" "$md_build"
        fi
    done

    local url="https://github.com/godotengine/godot/releases/download"
    for version in "${GODOT4_VERSIONS[@]}"; do
        if isPlatform "x86" && ! isPlatform "x86_64"; then
            downloadAndExtract "${url}/${version}-stable/Godot_v${version}-stable_linux.x86_32.zip" "$md_build"
        elif isPlatform "x86_64"; then
            downloadAndExtract "${url}/${version}-stable/Godot_v${version}-stable_linux.x86_64.zip" "$md_build"
        elif isPlatform "aarch64"; then
            downloadAndExtract "${url}/${version}-stable/Godot_v${version}-stable_linux.arm64.zip" "$md_build"
        elif isPlatform "rpi1"; then
            downloadAndExtract "${url}/${version}-stable/Godot_v${version}-stable_linux.arm32.zip" "$md_build"
        elif isPlatform "rpi2" || isPlatform "rpi3" || isPlatform "rpi4"; then
            downloadAndExtract "${url}/${version}-stable/Godot_v${version}-stable_linux.arm32.zip" "$md_build"
        fi
    done
}

function game_data_godot-engine-v4() {
    # Super Mario Bros Remastered: https://raw.githubusercontent.com/JHDev2006/Super-Mario-Bros.-Remastered-Public/main/LICENSE
    local smb1r_ver=1.1-stable
    if [[ ! -f "$romdir/godot-engine/SMB1R.pck" ]]; then
        mkdir -p /tmp/smb1r
        #wget https://github.com/JHDev2006/Super-Mario-Bros.-Remastered-Public/releases/download/$smb1r_ver/Linux.zip -O /tmp/smb1r/Linux.zip; unzip /tmp/smb1r/Linux.zip -d /tmp/smb1r/
        downloadAndExtract "https://github.com/JHDev2006/Super-Mario-Bros.-Remastered-Public/releases/download/$smb1r_ver/Linux.zip" "/tmp/smb1r"
        mv "/tmp/smb1r/SMB1R.pck" "$romdir/godot-engine/SMB1R.pck"
        rm -fr /tmp/smb1r
        chown "$__user":"$__group" "$romdir/godot-engine/SMB1R.pck"
        download https://raw.githubusercontent.com/JHDev2006/Super-Mario-Bros.-Remastered-Public/main/README.md "$romdir/godot-engine"
        chown "$__user":"$__group" "$romdir/godot-engine/README.md"
    fi

    # Super-Turbo-Turkey-Puncher-3: a recreation of a mini hidden game from DOOM3.
    # Copyright Kris Occhipinti 2023-11-28 (https://filmsbykris.com) License GPLv3
    # This game's Source Code is Free and Open Source under a GPLv3 license.
    # The Sounds, music, and sprites are Copyright ID Software.
    if [[ ! -f "$romdir/godot-engine/turkey_puncher.pck" ]]; then
        download "https://gitlab.com/metalx1000/Super-Turbo-Turkey-Puncher-3/-/raw/master/bin/turkey_puncher.pck" "$romdir/godot-engine"
        chown "$__user":"$__group" "$romdir/godot-engine/turkey_puncher.pck"
    fi

    # get Portal2D (freeware game data) 100mb+
    ##if [[ ! -f "$romdir/godot-engine/Portal 2D.pck" ]]; then
        ##mkdir -p /tmp/portal2d
        ##download "https://github.com/JulianGaibler/portal2d/releases/download/v1.0.0/Portal2D.dmg" "/tmp/portal2d"
        ##pushd /tmp/portal2d
        ##7z x /tmp/portal2d/Portal2D.dmg -aoa
        ##mv "/tmp/portal2d/Portal 2D/Portal 2D.app/Contents/Resources/Portal 2D.pck" "$romdir/godot-engine/Portal 2D.pck"
        ##popd
        ##rm -fr /tmp/portal2d
        ##chown "$__user":"$__group" "$romdir/godot-engine/Portal 2D.pck"
    ##fi

    if [[ ! -f /opt/retropie/configs/all/emulators.cfg ]]; then touch /opt/retropie/configs/all/emulators.cfg; fi
    ##if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'godot-engine_Portal2D = "godot-engine-3.2.3"' ; echo $?) == '1' ]]; then echo 'godot-engine_Portal2D = "godot-engine-3.2.3"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'godot-engine_turkey_puncher = "godot-engine-v4.4.1-stable"' ; echo $?) == '1' ]]; then echo 'godot-engine_turkey_puncher = "godot-engine-v4.4.1-stable"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi
    if [[ $(cat /opt/retropie/configs/all/emulators.cfg | grep -q 'godot-engine_SMB1R = "godot-engine-v4.6.3-stable"' ; echo $?) == '1' ]]; then echo 'godot-engine_SMB1R = "godot-engine-v4.6.3-stable"' >> /opt/retropie/configs/all/emulators.cfg; chown $__user:$__user /opt/retropie/configs/all/emulators.cfg; fi

    # Artwork and gamelist.xml
    downloadAndExtract "https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup-Assets/main/emulators/godot-engine-v4-rp-assets.tar.gz" "$romdir/godot-engine"
    if [[ ! -f "$romdir/godot-engine/gamelist.xml" ]] && [[ ! -f "/opt/retropie/configs/all/emulationstation/gamelists/godot-engine/gamelist.xml" ]]; then mv "$romdir/godot-engine/gamelist.xml.godot" "$romdir/godot-engine/gamelist.xml"; fi
    chown -R $__user:$__user "$romdir/godot-engine"
    mv "$romdir/godot-engine/retropie.pkg" "$md_inst"
}


function install_godot-engine-v4() {
    if [[ -d "$md_build" ]]; then
        md_ret_files=($(ls "$md_build"))
    else
        echo "ERROR: Can't install '$RP_MODULE_ID'." >&2
        echo "There must have been a problem downloading the sources." >&2
        exit 1
    fi

    # Create the "godot-engine" ROM folder.
    mkRomDir "$RP_MODULE_ID"

    # Install the "godot-engine" system for the default EmulationStation theme.
    echo
    echo "Installing the '$RP_MODULE_ID' system for the '$ES_DEFAULT_THEME' theme..."
    echo
    _install_update_theme "$ES_DEFAULT_THEME"

    # Install the scraper for Godot games.
    ##echo
    ##echo "Installing the scraper..."
    ##echo
    ##_install_update_scraper

    if [[ -d "$TMP_DIR" ]]; then
        # Create the "settings" folder inside the "godot-engine" folder.
        mkUserDir "$SETTINGS_DIR"

        # Install the "default settings" files.
        cp "$TMP_DIR/override.cfg" "$OVERRIDE_CFG_DEFAULTS_FILE" && chown -R "$user:$user" "$OVERRIDE_CFG_DEFAULTS_FILE"
        cp "$TMP_DIR/godot-engine-settings.cfg" "$SETTINGS_CFG_DEFAULTS_FILE" && chown -R "$user:$user" "$SETTINGS_CFG_DEFAULTS_FILE"

        # Install the "user settings" files.
        if [[ ! -f "$OVERRIDE_CFG_FILE" ]]; then
            cp "$TMP_DIR/override.cfg" "$OVERRIDE_CFG_FILE" && chown -R "$user:$user" "$OVERRIDE_CFG_FILE"
        fi
        if [[ ! -f "$SETTINGS_CFG_FILE" ]]; then
            cp "$TMP_DIR/godot-engine-settings.cfg" "$SETTINGS_CFG_FILE" && chown -R "$user:$user" "$SETTINGS_CFG_FILE"
        fi
    else
        echo "ERROR: Can't install the settings files for '$RP_MODULE_ID'." >&2
        echo "There must have been a problem when installing/updating the setup script." >&2
        exit 1
    fi
}


function remove_godot-engine-v4() {
    # Remove the "godot-engine" system for the default EmulationStation theme.
    _uninstall_theme "$ES_DEFAULT_THEME"
    # Remove the "godot-engine" configs folder.
    rmDirExists "$CONFIGS_DIR"
    # Remove the "settings" folder in "godot-engine" ROM folder.
    rmDirExists "$SETTINGS_DIR"
    # Remove the "override.cfg" file in "godot-engine" ROM folder.
    rmFileExists "$OVERRIDE_CFG_FILE"

    local shortcut_name
    shortcut_name="Super Mario Bros Remastered"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"

    shortcut_name="Super Turbo Turkey Puncher 3"
    rm -f "/usr/share/applications/$shortcut_name.desktop"; rm -f "$home/Desktop/$shortcut_name.desktop"
}


function configure_godot-engine-v4() {
    local bin_file_tmp
    local bin_files=()
    local bin_files_tmp=()
    local default
    local index
    local version
    local audio_driver_string
    local main_pack_string
    local video_driver_string

    if [[ -d "$md_inst" ]]; then
        # Get all the files in the installation folder.
        bin_files_tmp=($(ls "$md_inst"))

        # Remove the extra files and create the final array with the needed files.
        for bin_file_tmp in "${bin_files_tmp[@]}"; do
            if [[ "$bin_file_tmp" == *"frt_"* || "$bin_file_tmp" == *"godot_"* || "$bin_file_tmp" == *"Godot_"* ]]; then
                bin_files+=("$bin_file_tmp")
            fi
        done
    else
        echo "ERROR: Can't configure '$RP_MODULE_ID'." >&2
        echo "There must have been a problem installing the binaries." >&2
        exit 1
    fi

    # Remove the file that contains all the configurations for the different Godot "emulators".
    # It will be created from scratch when adding the emulators in the "addEmulator" functions below.
    rmFileExists "$CONFIGS_DIR/emulators.cfg"

    for index in "${!bin_files[@]}"; do
        default=0
        [[ "$index" -eq "${#bin_files[@]}-1" ]] && default=1 # Default to the last item (greater version) in "bin_files".
        
        # Get the version from the file name.
        version="${bin_files[$index]}"
        # Cut between "_".
        version="$(echo $version | cut -d'_' -f 2)"

        if [[ "$version" == "2.1.6" ]]; then
            audio_driver_string="-ad"
            main_pack_string="-main_pack"
            video_driver_string="-vd"
        elif [[ "$version" == "v4."* ]]; then
            audio_driver_string="--audio-driver"
            main_pack_string="--main-pack"
            video_driver_string="--rendering-method gl_compatibility"
            isPlatform "rpi"* && video_driver_string="--rendering-method mobile"
            isPlatform "kms" && video_driver_string="--rendering-method mobile"
        else
            audio_driver_string="--audio-driver"
            main_pack_string="--main-pack"
            video_driver_string="--video-driver"
        fi

        local launch_prefix
        if [[ "$version" == "v4."* ]]; then
            isPlatform "kms" && launch_prefix="XINIT-WMC:"
            if (isPlatform "rpi") && [[ "$__os_debian_ver" -le 10 ]]; then launch_prefix="XINIT:"; fi
        fi

        if isPlatform "x86" || isPlatform "x86_64"; then
            if [[ "$version" == "2.1.6" ]]; then
                addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "$md_inst/${bin_files[$index]} $main_pack_string %ROM% $audio_driver_string $AUDIO_DRIVER $video_driver_string GLES2 -f"
            elif [[ "$version" == "v4."* ]]; then
                #addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "$md_inst/${bin_files[$index]} $main_pack_string %ROM% $audio_driver_string $AUDIO_DRIVER $video_driver_string -f"
                addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "$md_inst/${bin_files[$index]} $main_pack_string %ROM% $video_driver_string -f"
            else
                addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "$md_inst/${bin_files[$index]} $main_pack_string %ROM% $audio_driver_string $AUDIO_DRIVER $video_driver_string $VIDEO_DRIVER -f"
            fi
        else
            local frt_keyboard_id_string=""
            [[ -n "$FRT_KEYBOARD_ID" ]] && frt_keyboard_id_string="FRT_KEYBOARD_ID='$FRT_KEYBOARD_ID'"
            local frt_kms_drm_device_string=""
            [[ -n "$FRT_KMSDRM_DEVICE" ]] && frt_kms_drm_device_string="FRT_KMSDRM_DEVICE='$FRT_KMSDRM_DEVICE'"

            if [[ "$version" == "2.1.6" ]]; then
                addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "${launch_prefix}$md_inst/${bin_files[$index]} $main_pack_string %ROM% $audio_driver_string $AUDIO_DRIVER $video_driver_string GLES2 -f"
            elif [[ "$version" == "v4."* ]]; then
                #addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "${launch_prefix}$md_inst/${bin_files[$index]} $main_pack_string %ROM% $audio_driver_string $AUDIO_DRIVER $video_driver_string -f"
                addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "${launch_prefix}$md_inst/${bin_files[$index]} $main_pack_string %ROM% $video_driver_string -f"
            else
                addEmulator "$default" "godot-engine-$version" "$RP_MODULE_ID" "${launch_prefix}FRT_EXIT_SHORTCUT=shift-enter $md_inst/${bin_files[$index]} $main_pack_string %ROM% $audio_driver_string $AUDIO_DRIVER $video_driver_string $VIDEO_DRIVER -f"
            fi
        fi

        # shortcuts_icons_godot-engine-v4
        local smb1r_exec; local sttp3_exec
        [[ "$version" == *"4.6.3"* ]] && smb1r_exec="$md_inst/${bin_files[$index]} $main_pack_string $romdir/godot-engine/SMB1R.pck $video_driver_string -f"
        [[ "$version" == *"4.4.1"* ]] && sttp3_exec="$md_inst/${bin_files[$index]} $main_pack_string $romdir/godot-engine/turkey_puncher.pck $video_driver_string -f"
    done

    addSystem "$RP_MODULE_ID" "Godot Engine" ".pck .zip"

    moveConfigDir "$home/.local/share/godot" "$md_conf_root/godot-engine"
    moveConfigDir "$home/.local/share/SMB1R" "$md_conf_root/godot-engine/SMB1R"
    chown -R $__user:$__user "$md_conf_root/godot-engine"

    if [[ "$md_mode" == "install" ]]; then
        [[ ! -d "$home/60D0T" ]] && ln -s "$romdir/godot-engine" "$home/60D0T"
        [[ ! -d "$home/SMB1R" ]] && ln -s "$md_conf_root/godot-engine/SMB1R" "$home/SMB1R"
        chown -R $__user:$__user "$home/60D0T"
        chown -R $__user:$__user "$home/SMB1R"
    fi

    [[ "$md_mode" == "remove" ]] && rm -f "$home/60D0T"
    [[ "$md_mode" == "remove" ]] && rm -f "$home/SMB1R"

    [[ "$md_mode" == "install" ]] && _set_config "audio_driver" "$AUDIO_DRIVER"
    [[ "$md_mode" == "install" ]] && _set_config "video_driver" "$VIDEO_DRIVER"

    [[ "$md_mode" == "install" ]] && game_data_godot-engine-v4
    [[ "$md_mode" == "install" ]] && shortcuts_icons_godot-engine-v4

    # Placed here for ${smb1r_exec} ${sttp3_exec} instead of [shortcuts_icons_godot-engine-v4]
    if [[ "$md_mode" == "install" ]]; then
        local shortcut_name
        shortcut_name="Super Mario Bros Remastered"
        cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=A Remake/Celebration of the original Super Mario Bros. games
Exec=${smb1r_exec}
Icon=$md_inst/smb1r_128x128.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=GODOT;SMB1;Remastered
StartupWMClass=smb1r
_EOF_
        chmod 755 "$md_inst/$shortcut_name.desktop"
        if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
        rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"

        shortcut_name="Super Turbo Turkey Puncher 3"
        cat >"$md_inst/$shortcut_name.desktop" << _EOF_
[Desktop Entry]
Name=$shortcut_name
GenericName=$shortcut_name
Comment=A Remake/Celebration of the original Super Mario Bros. games
Exec=${sttp3_exec}
Icon=$md_inst/turkey_puncher_104x128.xpm
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=GODOT;STTP3;Doom3
StartupWMClass=smb1r
_EOF_
        chmod 755 "$md_inst/$shortcut_name.desktop"
        if [[ -d "$home/Desktop" ]]; then rm -f "$home/Desktop/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "$home/Desktop/$shortcut_name.desktop"; chown $__user:$__user "$home/Desktop/$shortcut_name.desktop"; fi
        rm -f "/usr/share/applications/$shortcut_name.desktop"; cp "$md_inst/$shortcut_name.desktop" "/usr/share/applications/$shortcut_name.desktop"; chown $__user:$__user "/usr/share/applications/$shortcut_name.desktop"
    fi
}

function gui_godot-engine-v4() {
    # Reset the dialog options.
    DIALOG_OPTIONS=()

    # Add the options only available for FRT.
    if ! isPlatform "x86" || ! isPlatform "x86_64"; then
        DIALOG_OPTIONS+=(
            "virtual_keyboard"
        )

        FRT_KEYBOARD_ID="$(_get_config "gpio_virtual_keyboard")"

        if [[ -d "/dev/dri" ]]; then
            DIALOG_OPTIONS+=(
                "kms_drm_driver"
            )

            FRT_KMSDRM_DEVICE="$(_get_config "kms_drm_driver")"
        fi
    fi

    # Add the options available for all the systems.
    DIALOG_OPTIONS+=(
        "audio_driver"
        "video_driver"
        ##"edit_override"
        ##"install_themes"
    )

    AUDIO_DRIVER="$(_get_config "audio_driver")"
    VIDEO_DRIVER="$(_get_config "video_driver")"

    _main_config_dialog
}

function shortcuts_icons_godot-engine-v4() {
    cat >"$md_inst/smb1r_128x128.xpm" << _EOF_
/* XPM */
static char * smb1r_128x128_xpm[] = {
"128 128 30 1",
"   c None",
".  c #BA6111",
"+  c #BE6516",
"@  c #BD6516",
"#  c #FAA644",
"\$ c #FDA846",
"%  c #F8A545",
"&  c #433022",
"*  c #1F1F1F",
"=  c #FFAA47",
"-  c #FAA746",
";  c #423022",
">  c #FBA746",
",  c #573C24",
"'  c #C1691A",
")  c #B75F12",
"!  c #41291E",
"~  c #33251F",
"{  c #21201F",
"]  c #413022",
"^  c #4C3321",
"/  c #B76012",
"(  c #F8A544",
"_  c #F6A445",
":  c #B35E12",
"<  c #33241F",
"[  c #201F1F",
"}  c #563C24",
"|  c #34251F",
"1  c #BA6416",
"        ................................................................................................................        ",
"        ................................................................................................................        ",
"        ................................................................................................................        ",
"        ................................................................................................................        ",
"        ................................................................................................................        ",
"        ................................................................................................................        ",
"        ................................................................................................................        ",
"        +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++@        ",
".......+#\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$%&*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$=======>------>================================================================================>------>=======-;*******",
".......+\$======>,;;;;;;,>==============================================================================>,;;;;;;,>======-;*******",
".......+\$======-;******;-==============================================================================-;******;-======-;*******",
".......+\$======-;******;-==============================================================================-;******;-======-;*******",
".......+\$======-;******;-==============================================================================-;******;-======-;*******",
".......+\$======-;******;-==============================================================================-;******;-======-;*******",
".......+\$======-;******;-==============================================================================-;******;-======-;*******",
".......+\$======-;******;-==============================================================================-;******;-======-;*******",
".......+\$======>,;;;;;;,>===============\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$\$=======================>,;;;;;;,>======-;*******",
".......+\$=======>------>===============\$'++++++++++++++++++++++++++++++++++++++'\$=======================>------>=======-;*******",
".......+\$==============================\$+......................................+\$======================================-;*******",
".......+\$==============================\$+......................................+\$======================================-;*******",
".......+\$==============================\$+......................................+\$======================================-;*******",
".......+\$==============================\$+......................................+\$======================================-;*******",
".......+\$==============================\$+......................................+\$======================================-;*******",
".......+\$==============================\$+......................................+\$======================================-;*******",
".......+\$=======================\$\$\$\$\$\$\$#@.......)))))))))))))))))))))))).......@#\$\$\$\$\$\$\$===============================-;*******",
".......+\$======================\$'++++++@.......)!~~~~~~~~~~~~~~~~~~~~~~!).......@++++++'\$==============================-;*******",
".......+\$======================\$+..............)~**********************~)..............+\$==============================-;*******",
".......+\$======================\$+..............)~**********************~)..............+\$==============================-;*******",
".......+\$======================\$+..............)~**********************~)..............+\$==============================-;*******",
".......+\$======================\$+..............)~**********************~)..............+\$==============================-;*******",
".......+\$======================\$+..............)~**********************~)..............+\$==============================-;*******",
".......+\$======================\$+..............)~**********************~)..............+\$==============================-;*******",
".......+\$======================\$+..............)~******{];;;;;;;;;;;;;;^/..............@(------>=======================-;*******",
".......+\$======================\$+..............)~******]_--------------(@............../^;;;;;;,>======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$+..............)~******;-==============\$+..............)~******;-======================-;*******",
".......+\$======================\$'++++++@/)))))):<******;-=======\$\$\$\$\$\$\$#@..............)~******;-======================-;*******",
".......+\$=======================\$\$\$\$\$\$\$(^~~~~~~<[******;-======\$'++++++@...............)~******;-======================-;*******",
".......+\$==============================-;**************;-======\$+......................)~******;-======================-;*******",
".......+\$==============================-;**************;-======\$+......................)~******;-======================-;*******",
".......+\$==============================-;**************;-======\$+......................)~******;-======================-;*******",
".......+\$==============================-;**************;-======\$+......................)~******;-======================-;*******",
".......+\$==============================-;**************;-======\$+......................)~******;-======================-;*******",
".......+\$==============================-;**************;-======\$+......................)~******;-======================-;*******",
".......+\$==============================>,;;;;;;;;;;;;;;}%\$\$\$\$\$\$#@.......))))))))))))))):<******;-======================-;*******",
".......+\$===============================>--------------%'++++++@.......)!~~~~~~~~~~~~~~<[******;-======================-;*******",
".......+\$==============================================\$+..............)~**********************;-======================-;*******",
".......+\$==============================================\$+..............)~**********************;-======================-;*******",
".......+\$==============================================\$+..............)~**********************;-======================-;*******",
".......+\$==============================================\$+..............)~**********************;-======================-;*******",
".......+\$==============================================\$+..............)~**********************;-======================-;*******",
".......+\$==============================================\$+..............)~**********************;-======================-;*******",
".......+\$==============================================\$+..............)~******{];;;;;;;;;;;;;;,>======================-;*******",
".......+\$==============================================\$+..............)~******]_-------------->=======================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$'++++++@/)))))):<******;-======================================-;*******",
".......+\$===============================================\$\$\$\$\$\$\$(^~~~~~~<[******;-======================================-;*******",
".......+\$======================================================-;**************;-======================================-;*******",
".......+\$======================================================-;**************;-======================================-;*******",
".......+\$======================================================-;**************;-======================================-;*******",
".......+\$======================================================-;**************;-======================================-;*******",
".......+\$======================================================-;**************;-======================================-;*******",
".......+\$======================================================-;**************;-======================================-;*******",
".......+\$===============================================\$\$\$\$\$\$\$(^~~~~~~|;;;;;;;,>======================================-;*******",
".......+\$==============================================\$'++++++@/))))))1%------>=======================================-;*******",
".......+\$==============================================\$+..............+\$==============================================-;*******",
".......+\$==============================================\$+..............+\$==============================================-;*******",
".......+\$==============================================\$+..............+\$==============================================-;*******",
".......+\$==============================================\$+..............+\$==============================================-;*******",
".......+\$==============================================\$+..............+\$==============================================-;*******",
".......+\$==============================================\$+..............+\$==============================================-;*******",
".......+\$==============================================\$+..............@(------>=======================================-;*******",
".......+\$==============================================\$+............../^;;;;;;,>======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$==============================================\$+..............)~******;-======================================-;*******",
".......+\$=======>------>===============================\$'++++++@/)))))):<******;-=======================>------>=======-;*******",
".......+\$======>,;;;;;;,>===============================\$\$\$\$\$\$\$(^~~~~~~<[******;-======================>,;;;;;;,>======-;*******",
".......+\$======-;******;-======================================-;**************;-======================-;******;-======-;*******",
".......+\$======-;******;-======================================-;**************;-======================-;******;-======-;*******",
".......+\$======-;******;-======================================-;**************;-======================-;******;-======-;*******",
".......+\$======-;******;-======================================-;**************;-======================-;******;-======-;*******",
".......+\$======-;******;-======================================-;**************;-======================-;******;-======-;*******",
".......+\$======-;******;-======================================-;**************;-======================-;******;-======-;*******",
".......+\$======>,;;;;;;,>======================================>,;;;;;;;;;;;;;;,>======================>,;;;;;;,>======-;*******",
".......+\$=======>------>========================================>-------------->========================>------>=======-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......+\$==============================================================================================================-;*******",
".......@%--------------------------------------------------------------------------------------------------------------_;*******",
"        &;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;        ",
"        ****************************************************************************************************************        ",
"        ****************************************************************************************************************        ",
"        ****************************************************************************************************************        ",
"        ****************************************************************************************************************        ",
"        ****************************************************************************************************************        ",
"        ****************************************************************************************************************        ",
"        ****************************************************************************************************************        "};
_EOF_

    cat >"$md_inst/turkey_puncher_104x128.xpm" << _EOF_
/* XPM */
static char * turkey_puncher_104x128_xpm[] = {
"104 128 3618 2",
"   c None",
".  c #383732",
"+  c #302F28",
"@  c #2F2E27",
"#  c #413B30",
"\$     c #403A30",
"%  c #403A2F",
"&  c #3F392F",
"*  c #3D342E",
"=  c #3C322D",
"-  c #3E332E",
";  c #403E3B",
">  c #44423F",
",  c #3B3935",
"'  c #43423D",
")  c #656560",
"!  c #666661",
"~  c #464137",
"{  c #655C54",
"]  c #6B625A",
"^  c #695D4E",
"/  c #685A48",
"(  c #695B49",
"_  c #635645",
":  c #493E34",
"<  c #362A25",
"[  c #43413E",
"}  c #575450",
"|  c #969593",
"1  c #B3B4B2",
"2  c #B8B9B7",
"3  c #8E8E8A",
"4  c #635D55",
"5  c #675F57",
"6  c #6E655D",
"7  c #6C6051",
"8  c #6B5D4A",
"9  c #594B3E",
"0  c #483932",
"a  c #3F3D3B",
"b  c #7D7973",
"c  c #C7C5C1",
"d  c #D6D7D6",
"e  c #D5D6D5",
"f  c #CDCECD",
"g  c #B9ACAA",
"h  c #686057",
"i  c #534C43",
"j  c #6D645C",
"k  c #615444",
"l  c #5A4D3F",
"m  c #56483C",
"n  c #4E3D36",
"o  c #362A26",
"p  c #35312F",
"q  c #3C3933",
"r  c #3E3B34",
"s  c #6B6966",
"t  c #9E9C98",
"u  c #CCCBC9",
"v  c #D2D1D2",
"w  c #C5C1C2",
"x  c #8A8886",
"y  c #595551",
"z  c #5C554F",
"A  c #64584C",
"B  c #67594A",
"C  c #5F5144",
"D  c #574A3E",
"E  c #4D4036",
"F  c #43362F",
"G  c #382D27",
"H  c #392F28",
"I  c #4D4135",
"J  c #463D37",
"K  c #37332F",
"L  c #393531",
"M  c #39342B",
"N  c #393429",
"O  c #82817C",
"P  c #B1B1AE",
"Q  c #CECDCE",
"R  c #CECBCE",
"S  c #C6CACD",
"T  c #BCC0C2",
"U  c #7F7F7F",
"V  c #4C4744",
"W  c #584C44",
"X  c #5D4F44",
"Y  c #5C4E43",
"Z  c #605142",
"\`     c #685847",
" . c #746450",
".. c #786752",
"+. c #66584D",
"@. c #423B35",
"#. c #514840",
"\$.    c #544A42",
"%. c #413B31",
"&. c #CAC7CA",
"*. c #BDB9BC",
"=. c #BFBCBF",
"-. c #C7CBCE",
";. c #C6CCCF",
">. c #979899",
",. c #4F4A48",
"'. c #51463D",
"). c #57493E",
"!. c #5B4D42",
"~. c #5E5045",
"{. c #67584A",
"]. c #6B5B4A",
"^. c #71604E",
"/. c #796753",
"(. c #71614D",
"_. c #605348",
":. c #483F39",
"<. c #413A35",
"[. c #413A34",
"}. c #3A3632",
"|. c #443E38",
"1. c #706155",
"2. c #6B5D52",
"3. c #4A4237",
"4. c #CBCACB",
"5. c #BEBBBD",
"6. c #9E999B",
"7. c #A19C9E",
"8. c #C3C0C3",
"9. c #C0C4C7",
"0. c #C6CBCE",
"a. c #ACAFB1",
"b. c #595655",
"c. c #4D433B",
"d. c #514338",
"e. c #5A4C41",
"f. c #665749",
"g. c #6A5A49",
"h. c #675847",
"i. c #655646",
"j. c #4E4336",
"k. c #443C36",
"l. c #473F39",
"m. c #4D443D",
"n. c #48403A",
"o. c #493D39",
"p. c #453835",
"q. c #272627",
"r. c #413B33",
"s. c #756355",
"t. c #907A68",
"u. c #6C5D50",
"v. c #4A4036",
"w. c #393329",
"x. c #7E7C79",
"y. c #AAABAA",
"z. c #BAB9BA",
"A. c #A8A5A6",
"B. c #959292",
"C. c #4D4647",
"D. c #665F60",
"E. c #919292",
"F. c #C0C5C6",
"G. c #7B7C7B",
"H. c #59524E",
"I. c #4B3E33",
"J. c #55483C",
"K. c #584A3F",
"L. c #5D5042",
"M. c #5F5242",
"N. c #493D33",
"O. c #362C26",
"P. c #322D27",
"Q. c #453D36",
"R. c #5A4F44",
"S. c #58514B",
"T. c #66605C",
"U. c #6D6765",
"V. c #6E6967",
"W. c #6B6664",
"X. c #2F2E2F",
"Y. c #443C30",
"Z. c #836C59",
"\`.    c #826B59",
" + c #6A5949",
".+ c #493E33",
"++ c #393029",
"@+ c #737271",
"#+ c #9C9E9F",
"\$+    c #B9BCBD",
"%+ c #BDBEBD",
"&+ c #BBBCBB",
"*+ c #373331",
"=+ c #28221F",
"-+ c #7A7C7A",
";+ c #B3B8B3",
">+ c #B5BAB5",
",+ c #808380",
"'+ c #463B30",
")+ c #524539",
"!+ c #524739",
"~+ c #4F4637",
"{+ c #43382E",
"]+ c #3A2E28",
"^+ c #312421",
"/+ c #40392F",
"(+ c #423C31",
"_+ c #453F35",
":+ c #74706B",
"<+ c #908E8B",
"[+ c #9C9B9A",
"}+ c #92918F",
"|+ c #605E5C",
"1+ c #303030",
"2+ c #424142",
"3+ c #453E32",
"4+ c #6B5A4A",
"5+ c #6A5A4A",
"6+ c #534739",
"7+ c #40372E",
"8+ c #4F4A45",
"9+ c #818181",
"0+ c #B0B2B2",
"a+ c #B1B2B0",
"b+ c #524F4D",
"c+ c #383432",
"d+ c #7E807D",
"e+ c #A2A6A2",
"f+ c #B1B6B1",
"g+ c #959995",
"h+ c #65635E",
"i+ c #4B3F34",
"j+ c #504337",
"k+ c #4C4034",
"l+ c #473D31",
"m+ c #40352C",
"n+ c #342723",
"o+ c #7C7875",
"p+ c #C2BFC1",
"q+ c #C4C3C4",
"r+ c #C3C3C2",
"s+ c #C9CAC9",
"t+ c #C2C3C1",
"u+ c #8C8B89",
"v+ c #343334",
"w+ c #54493B",
"x+ c #53483A",
"y+ c #41372E",
"z+ c #625F5D",
"A+ c #8C8B8A",
"B+ c #82817F",
"C+ c #595654",
"D+ c #36322F",
"E+ c #5B5856",
"F+ c #8C8F8C",
"G+ c #A4A8A4",
"H+ c #73706A",
"I+ c #4A3E33",
"J+ c #42372E",
"K+ c #473B31",
"L+ c #473C31",
"M+ c #322522",
"N+ c #3C3029",
"O+ c #433D32",
"P+ c #B0ADAF",
"Q+ c #C6C3C6",
"R+ c #AAA8A8",
"S+ c #B6B6B5",
"T+ c #C2C2C1",
"U+ c #868583",
"V+ c #534839",
"W+ c #4C4642",
"X+ c #9A9A98",
"Y+ c #B1B2B1",
"Z+ c #8A8987",
"\`+    c #63615F",
" @ c #8B8A88",
".@ c #A0A39F",
"+@ c #7D7A74",
"@@ c #382E26",
"#@ c #3B2F28",
"\$@    c #433D33",
"%@ c #979391",
"&@ c #BCB9BB",
"*@ c #848183",
"=@ c #474442",
"-@ c #A6A6A5",
";@ c #575452",
">@ c #3C3B3C",
",@ c #4D4235",
"'@ c #5E5343",
")@ c #584F40",
"!@ c #504438",
"~@ c #453A30",
"{@ c #362D26",
"]@ c #3C342E",
"^@ c #76726F",
"/@ c #96928F",
"(@ c #9F9997",
"_@ c #97918F",
":@ c #A9A8A9",
"<@ c #AAA9AA",
"[@ c #AEADAE",
"}@ c #AFAFAF",
"|@ c #75716F",
"1@ c #3E342B",
"2@ c #332A22",
"3@ c #392F27",
"4@ c #463A30",
"5@ c #493C31",
"6@ c #483B30",
"7@ c #46392F",
"8@ c #44362D",
"9@ c #565351",
"0@ c #A7A7A6",
"a@ c #B2B1B1",
"b@ c #7B797B",
"c@ c #525152",
"d@ c #636162",
"e@ c #919091",
"f@ c #8B8B8B",
"g@ c #393839",
"h@ c #43362C",
"i@ c #4B3F32",
"j@ c #52473A",
"k@ c #5A5142",
"l@ c #54483B",
"m@ c #4D4035",
"n@ c #3A3027",
"o@ c #352C24",
"p@ c #3D362D",
"q@ c #56514B",
"r@ c #837D79",
"s@ c #A49D9B",
"t@ c #A59E9C",
"u@ c #ACA9AC",
"v@ c #ADAAAD",
"w@ c #726D6D",
"x@ c #3B312A",
"y@ c #3B3029",
"z@ c #463B32",
"A@ c #4E4136",
"B@ c #4A3C31",
"C@ c #3D3A39",
"D@ c #878787",
"E@ c #A5A6A5",
"F@ c #848484",
"G@ c #8E8D8E",
"H@ c #8A888A",
"I@ c #626162",
"J@ c #42352B",
"K@ c #4A3E31",
"L@ c #4D4134",
"M@ c #554B3D",
"N@ c #53473A",
"O@ c #504338",
"P@ c #41362D",
"Q@ c #372E25",
"R@ c #332C23",
"S@ c #3E3931",
"T@ c #59544E",
"U@ c #837C78",
"V@ c #A69F9D",
"W@ c #ADA9AC",
"X@ c #ADABAE",
"Y@ c #8B8586",
"Z@ c #5F5856",
"\`@    c #3F352D",
" # c #4E4239",
".# c #5A4D43",
"+# c #55473D",
"@# c #373332",
"## c #5A5A5A",
"\$#    c #797979",
"%# c #6F6F6F",
"&# c #727172",
"*# c #6D6B6D",
"=# c #42342A",
"-# c #44362B",
";# c #4B4033",
"># c #504437",
",# c #312A21",
"'# c #312C21",
")# c #403B33",
"!# c #58534E",
"~# c #797171",
"{# c #7C7474",
"]# c #6C6464",
"^# c #534744",
"/# c #5A4D45",
"(# c #5E5046",
"_# c #615348",
":# c #5C4F44",
"<# c #603A33",
"[# c #783531",
"}# c #8A3331",
"|# c #863331",
"1# c #5F3931",
"2# c #3A3131",
"3# c #313031",
"4# c #3B3A3B",
"5# c #313131",
"6# c #3D3429",
"7# c #3E3429",
"8# c #41392D",
"9# c #4B3F33",
"0# c #4F4237",
"a# c #473B30",
"b# c #342B23",
"c# c #2D2821",
"d# c #504745",
"e# c #5A4F4C",
"f# c #564741",
"g# c #624F47",
"h# c #625244",
"i# c #625442",
"j# c #574B3E",
"k# c #483E37",
"l# c #502D29",
"m# c #652726",
"n# c #722526",
"o# c #6F2626",
"p# c #542A26",
"q# c #302323",
"r# c #42372D",
"s# c #39332E",
"t# c #41362B",
"u# c #4E4135",
"v# c #332D27",
"w# c #57463D",
"x# c #69554B",
"y# c #655148",
"z# c #443B2F",
"A# c #4E4332",
"B# c #4C4131",
"C# c #3A2422",
"D# c #421818",
"E# c #532E22",
"F# c #67412D",
"G# c #220C0B",
"H# c #2F2116",
"I# c #353026",
"J# c #332E25",
"K# c #3B3025",
"L# c #44372B",
"M# c #4F4236",
"N# c #463B31",
"O# c #514239",
"P# c #5D4B42",
"Q# c #614F45",
"R# c #4E3F37",
"S# c #3C332E",
"T# c #67583B",
"U# c #72613F",
"V# c #735B3B",
"W# c #7E5E3C",
"X# c #927348",
"Y# c #AB8B55",
"Z# c #473422",
"\`#    c #36271A",
" \$    c #29241E",
".\$    c #352A20",
"+\$    c #413429",
"@\$    c #514438",
"#\$    c #4C4236",
"\$\$   c #463F32",
"%\$    c #443D31",
"&\$    c #5B4A41",
"*\$    c #5A4940",
"=\$    c #493B33",
"-\$    c #322922",
";\$    c #443A2C",
">\$    c #605237",
",\$    c #8A7448",
"'\$    c #977F4D",
")\$    c #A68854",
"!\$    c #B4925B",
"~\$    c #C5A465",
"{\$    c #DBBB71",
"]\$    c #796440",
"^\$    c #5C4A31",
"/\$    c #29241F",
"(\$    c #29251F",
"_\$    c #332A21",
":\$    c #392F24",
"<\$    c #43382D",
"[\$    c #4A3F34",
"}\$    c #514639",
"|\$    c #463E31",
"1\$    c #4B4235",
"2\$    c #554B3C",
"3\$    c #5A4A3D",
"4\$    c #574831",
"5\$    c #927C4B",
"6\$    c #B19658",
"7\$    c #B69958",
"8\$    c #AD9254",
"9\$    c #BA9F5F",
"0\$    c #C7AC6A",
"a\$    c #CDB26E",
"b\$    c #D6BA73",
"c\$    c #D7BB73",
"d\$    c #C6AE6F",
"e\$    c #A6905C",
"f\$    c #766A47",
"g\$    c #282521",
"h\$    c #292621",
"i\$    c #2F2B21",
"j\$    c #3C352B",
"k\$    c #453C34",
"l\$    c #4F443A",
"m\$    c #514538",
"n\$    c #4B4032",
"o\$    c #54473C",
"p\$    c #5A4D42",
"q\$    c #584A35",
"r\$    c #312821",
"s\$    c #3A3024",
"t\$    c #857047",
"u\$    c #B3995A",
"v\$    c #C2A661",
"w\$    c #A18A51",
"x\$    c #847043",
"y\$    c #85764B",
"z\$    c #867C53",
"A\$    c #9F915F",
"B\$    c #C1AD70",
"C\$    c #C2AF71",
"D\$    c #CAB372",
"E\$    c #CEB673",
"F\$    c #8E8358",
"G\$    c #363026",
"H\$    c #3F382F",
"I\$    c #51463C",
"J\$    c #574B3F",
"K\$    c #54483C",
"L\$    c #584B40",
"M\$    c #524532",
"N\$    c #3C3126",
"O\$    c #846F46",
"P\$    c #A48A56",
"Q\$    c #8A7547",
"R\$    c #675735",
"S\$    c #3E3321",
"T\$    c #413B29",
"U\$    c #444331",
"V\$    c #4A4834",
"W\$    c #7A714C",
"X\$    c #847B54",
"Y\$    c #BAA66A",
"Z\$    c #BCA76B",
"\`\$   c #988C5E",
" % c #7C714D",
".% c #594A32",
"+% c #5A4B33",
"@% c #837452",
"#% c #847552",
"\$%    c #60563C",
"%% c #49412E",
"&% c #2A241A",
"*% c #4B3C2D",
"=% c #68523E",
"-% c #6C5743",
";% c #5E4F3D",
">% c #594B39",
",% c #302B21",
"'% c #3C362C",
")% c #4B4036",
"!% c #594C41",
"~% c #52463A",
"{% c #5A4B34",
"]% c #A18754",
"^% c #867048",
"/% c #5F4F33",
"(% c #352B1C",
"_% c #060308",
":% c #0B0F11",
"<% c #0F1718",
"[% c #0E1718",
"}% c #0A1516",
"|% c #1F2D2E",
"1% c #585B46",
"2% c #8F855B",
"3% c #857652",
"4% c #6E5E42",
"5% c #403730",
"6% c #51432E",
"7% c #6C593C",
"8% c #836C4A",
"9% c #836D4A",
"0% c #5E4F39",
"a% c #514231",
"b% c #6F5843",
"c% c #7B614A",
"d% c #856D53",
"e% c #8B7459",
"f% c #8B745A",
"g% c #796751",
"h% c #514638",
"i% c #342F24",
"j% c #433A2E",
"k% c #4F4336",
"l% c #4A3F31",
"m% c #3B3126",
"n% c #836E46",
"o% c #3D3226",
"p% c #201915",
"q% c #0B0609",
"r% c #080408",
"s% c #0C0F11",
"t% c #101818",
"u% c #243232",
"v% c #5A5C46",
"w% c #58523B",
"x% c #534832",
"y% c #453C29",
"z% c #463D35",
"A% c #352E26",
"B% c #755D3E",
"C% c #856947",
"D% c #886B49",
"E% c #6B5642",
"F% c #6B5742",
"G% c #6A5942",
"H% c #6D5F46",
"I% c #6E5F47",
"J% c #5D4B38",
"K% c #5C4735",
"L% c #67513C",
"M% c #6A533E",
"N% c #6D5641",
"O% c #705943",
"P% c #705944",
"Q% c #766654",
"R% c #7B7061",
"S% c #8D775F",
"T% c #89745C",
"U% c #302B25",
"V% c #312C27",
"W% c #322D28",
"X% c #40362D",
"Y% c #4A3D31",
"Z% c #3F3224",
"\`%    c #7E6E49",
" & c #6D5C3D",
".& c #281D16",
"+& c #190B0C",
"@& c #150408",
"#& c #1C0C0C",
"\$&    c #2C2219",
"%& c #30291E",
"&& c #221915",
"*& c #170C0E",
"=& c #1F1412",
"-& c #2A2625",
";& c #302B26",
">& c #473F37",
",& c #625435",
"'& c #786243",
")& c #725A43",
"!& c #655040",
"~& c #604C3F",
"{& c #5C4A39",
"]& c #584332",
"^& c #594433",
"/& c #5B4534",
"(& c #574132",
"_& c #543E2F",
":& c #513B2D",
"<& c #553927",
"[& c #5B3A24",
"}& c #5E412D",
"|& c #644F3E",
"1& c #735F4B",
"2& c #947D63",
"3& c #917A61",
"4& c #2F2B28",
"5& c #312C29",
"6& c #403224",
"7& c #7B6D4A",
"8& c #4E412D",
"9& c #1B0C0A",
"0& c #180508",
"a& c #180408",
"b& c #2A1C13",
"c& c #3E3222",
"d& c #342B1E",
"e& c #1A0609",
"f& c #190509",
"g& c #2D201D",
"h& c #312B26",
"i& c #473E37",
"j& c #493F29",
"k& c #685938",
"l& c #705C41",
"m& c #665040",
"n& c #5D4A3E",
"o& c #53433B",
"p& c #563F30",
"q& c #543C2C",
"r& c #553F30",
"s& c #513B2E",
"t& c #4D372B",
"u& c #583B28",
"v& c #5A3821",
"w& c #5B3A23",
"x& c #5D402B",
"y& c #574536",
"z& c #6B5845",
"A& c #7A6550",
"B& c #443529",
"C& c #2E2926",
"D& c #3D322B",
"E& c #514339",
"F& c #52432F",
"G& c #4C3E2B",
"H& c #1B0B0A",
"I& c #210E0E",
"J& c #392B1C",
"K& c #483C27",
"L& c #170308",
"M& c #1F0E0D",
"N& c #473E36",
"O& c #6D5D3A",
"P& c #6B5B3A",
"Q& c #5F4E3B",
"R& c #5F4B3F",
"S& c #4E3F3A",
"T& c #4A3C39",
"U& c #574030",
"V& c #57402F",
"W& c #533D2E",
"X& c #4E382B",
"Y& c #4A3429",
"Z& c #523C2E",
"\`&    c #5A3E2A",
" * c #433226",
".* c #413226",
"+* c #4A3A2D",
"@* c #2C2825",
"#* c #423429",
"\$*    c #5B4C35",
"%* c #413522",
"&* c #55482E",
"** c #4C412A",
"=* c #332A1D",
"-* c #180308",
";* c #190609",
">* c #231310",
",* c #2E211E",
"'* c #383738",
")* c #353028",
"!* c #403930",
"~* c #5A4B3D",
"{* c #4A3D33",
"]* c #463C2E",
"^* c #433A2C",
"/* c #64553A",
"(* c #5F5238",
"_* c #584331",
":* c #5D4332",
"<* c #5D3F2E",
"[* c #62442F",
"}* c #63442F",
"|* c #553F31",
"1* c #4F3C30",
"2* c #48352B",
"3* c #4A362B",
"4* c #513B2C",
"5* c #523A2A",
"6* c #473225",
"7* c #4B382B",
"8* c #463123",
"9* c #382F28",
"0* c #3D3229",
"a* c #3E3229",
"b* c #54453A",
"c* c #534135",
"d* c #574734",
"e* c #736546",
"f* c #49392A",
"g* c #1F090E",
"h* c #170309",
"i* c #241714",
"j* c #4C412D",
"k* c #584D34",
"l* c #473C29",
"m* c #2F251B",
"n* c #1C0D11",
"o* c #170A0D",
"p* c #251616",
"q* c #2F2428",
"r* c #3E3632",
"s* c #403834",
"t* c #615041",
"u* c #5D4D3F",
"v* c #524534",
"w* c #67553F",
"x* c #64543E",
"y* c #5B4D3A",
"z* c #4A4131",
"A* c #423B2E",
"B* c #4A3525",
"C* c #543521",
"D* c #5C3A21",
"E* c #684021",
"F* c #603C21",
"G* c #5E412C",
"H* c #563D2B",
"I* c #5C402C",
"J* c #533F33",
"K* c #503F34",
"L* c #4D3C32",
"M* c #48362E",
"N* c #47372E",
"O* c #4F382B",
"P* c #4D3426",
"Q* c #4A3122",
"R* c #4A3021",
"S* c #4F3F30",
"T* c #514435",
"U* c #524535",
"V* c #473C2F",
"W* c #352E27",
"X* c #41352D",
"Y* c #503F35",
"Z* c #5A4539",
"\`*    c #544133",
" = c #6B5D42",
".= c #534132",
"+= c #351E1E",
"@= c #291717",
"#= c #3D3326",
"\$=    c #574E37",
"%= c #564D36",
"&= c #28191D",
"*= c #140C0E",
"== c #1A1012",
"-= c #2E252E",
";= c #41352F",
">= c #42352F",
",= c #473C35",
"'= c #55463A",
")= c #5F4E40",
"!= c #544634",
"~= c #695740",
"{= c #685640",
"]= c #766147",
"^= c #685740",
"/= c #5F503C",
"(= c #483F30",
"_= c #3D372B",
":= c #403024",
"<= c #553621",
"[= c #5C3921",
"}= c #533521",
"|= c #523B2A",
"1= c #4A3829",
"2= c #513B2A",
"3= c #5E4C3C",
"4= c #5D4E3F",
"5= c #58493B",
"6= c #4E3E33",
"7= c #42332A",
"8= c #46392E",
"9= c #554134",
"0= c #523C2F",
"a= c #4E3629",
"b= c #524232",
"c= c #5E4E3C",
"d= c #5E4E3B",
"e= c #3E352B",
"f= c #40342C",
"g= c #503E34",
"h= c #564237",
"i= c #584635",
"j= c #463229",
"k= c #3B2C23",
"l= c #483E2D",
"m= c #5A5139",
"n= c #2E1D21",
"o= c #26181B",
"p= c #28181C",
"q= c #30262E",
"r= c #55433A",
"s= c #382D29",
"t= c #483F37",
"u= c #453D35",
"v= c #3E342C",
"w= c #56473A",
"x= c #4F4136",
"y= c #3B362C",
"z= c #64533E",
"A= c #7B654A",
"B= c #776248",
"C= c #5D4F3B",
"D= c #574A38",
"E= c #4D4333",
"F= c #433B2D",
"G= c #392D24",
"H= c #402B21",
"I= c #482F21",
"J= c #4D3929",
"K= c #593E2C",
"L= c #67442D",
"M= c #6C5946",
"N= c #625343",
"O= c #544437",
"P= c #3B2D25",
"Q= c #32281F",
"R= c #33281F",
"S= c #403429",
"T= c #493B30",
"U= c #5A493C",
"V= c #5C4B3F",
"W= c #554033",
"X= c #66553F",
"Y= c #6B5842",
"Z= c #493D31",
"\`=    c #3A312A",
" - c #3A3029",
".- c #4D3D33",
"+- c #4F3E34",
"@- c #685940",
"#- c #574534",
"\$-    c #4F3C2F",
"%- c #46382B",
"&- c #4D4331",
"*- c #595038",
"=- c #392429",
"-- c #322730",
";- c #624D42",
">- c #4E3E36",
",- c #28211F",
"'- c #2B2622",
")- c #453C35",
"!- c #3C352C",
"~- c #25211E",
"{- c #372F29",
"]- c #584A3D",
"^- c #56493C",
"/- c #4B4237",
"(- c #474131",
"_- c #59513D",
":- c #785D43",
"<- c #745C43",
"[- c #574736",
"}- c #554635",
"|- c #53402E",
"1- c #4E3A29",
"2- c #513D2B",
"3- c #4F3B2A",
"4- c #412F24",
"5- c #3D2B21",
"6- c #412B1F",
"7- c #3D2C23",
"8- c #463023",
"9- c #48372A",
"0- c #553E2E",
"a- c #574130",
"b- c #684732",
"c- c #6A5744",
"d- c #685947",
"e- c #625242",
"f- c #5A4A3C",
"g- c #403329",
"h- c #28211A",
"i- c #271F18",
"j- c #3B3229",
"k- c #635348",
"l- c #5E4B3F",
"m- c #493528",
"n- c #584230",
"o- c #5D4633",
"p- c #594533",
"q- c #4B3C30",
"r- c #41352C",
"s- c #393028",
"t- c #45372E",
"u- c #4C3B32",
"v- c #4B3B2F",
"w- c #544433",
"x- c #554433",
"y- c #3B2925",
"z- c #382B23",
"A- c #463B2B",
"B- c #4E422F",
"C- c #483C33",
"D- c #625144",
"E- c #4B3C34",
"F- c #28211D",
"G- c #322C26",
"H- c #463E36",
"I- c #433B33",
"J- c #423831",
"K- c #2B2522",
"L- c #342E28",
"M- c #484035",
"N- c #544B3E",
"O- c #544B3D",
"P- c #504832",
"Q- c #6B6041",
"R- c #6F4831",
"S- c #624531",
"T- c #544131",
"U- c #613D24",
"V- c #633C21",
"W- c #4D3424",
"X- c #362A21",
"Y- c #2B2219",
"Z- c #3B2E25",
"\`-    c #3D332A",
" ; c #635142",
".; c #604E40",
"+; c #44392F",
"@; c #27231E",
"#; c #211C18",
"\$;    c #2A2722",
"%; c #312F29",
"&; c #483D32",
"*; c #63432B",
"=; c #6B4529",
"-; c #614029",
";; c #47362B",
">; c #41342B",
",; c #372F26",
"'; c #43352C",
"); c #44352C",
"!; c #3C322A",
"~; c #584C36",
"{; c #5C4E38",
"]; c #3B322A",
"^; c #261C1A",
"/; c #33261D",
"(; c #493928",
"_; c #4F4538",
":; c #615749",
"<; c #42392E",
"[; c #2A2119",
"}; c #3F362E",
"|; c #4A4139",
"1; c #413932",
"2; c #3F362F",
"3; c #2E2925",
"4; c #2A2522",
"5; c #463F34",
"6; c #635848",
"7; c #6A5D4C",
"8; c #594E40",
"9; c #564E36",
"0; c #5D4431",
"a; c #524131",
"b; c #664631",
"c; c #653E24",
"d; c #623D23",
"e; c #623E25",
"f; c #4F3728",
"g; c #2D241B",
"h; c #292018",
"i; c #44382F",
"j; c #4C3F34",
"k; c #564639",
"l; c #58483A",
"m; c #5E4C3E",
"n; c #473D33",
"o; c #2E2C26",
"p; c #24201C",
"q; c #302D27",
"r; c #3B352B",
"s; c #524338",
"t; c #5E4A3F",
"u; c #5E412B",
"v; c #654229",
"w; c #674329",
"x; c #634229",
"y; c #513A2B",
"z; c #44352B",
"A; c #393027",
"B; c #42342B",
"C; c #382F29",
"D; c #716140",
"E; c #5D4F36",
"F; c #4A3D29",
"G; c #372B1E",
"H; c #392B20",
"I; c #443526",
"J; c #4D4337",
"K; c #4C4336",
"L; c #372E24",
"M; c #3A3127",
"N; c #443B33",
"O; c #423A33",
"P; c #403630",
"Q; c #3A332C",
"R; c #635847",
"S; c #736552",
"T; c #6E614F",
"U; c #484034",
"V; c #6A6041",
"W; c #724931",
"X; c #734931",
"Y; c #60402A",
"Z; c #5D432F",
"\`;    c #4A3930",
" > c #3B3128",
".> c #4E4034",
"+> c #524337",
"@> c #33312B",
"#> c #231E1A",
"\$>    c #292520",
"%> c #3A3429",
"&> c #534338",
"*> c #49382B",
"=> c #4A3729",
"-> c #543B29",
";> c #5A3E29",
">> c #563D2D",
",> c #4C392E",
"'> c #9B8552",
")> c #877347",
"!> c #6B5939",
"~> c #372A1E",
"{> c #31241B",
"]> c #483928",
"^> c #413525",
"/> c #252221",
"(> c #4C4337",
"_> c #3D342A",
":> c #30271E",
"<> c #443B34",
"[> c #413730",
"}> c #39332C",
"|> c #38322B",
"1> c #4E463A",
"2> c #574E40",
"3> c #635747",
"4> c #685B4A",
"5> c #4D4438",
"6> c #332D21",
"7> c #4B432F",
"8> c #4C4330",
"9> c #564231",
"0> c #634531",
"a> c #5F4431",
"b> c #5C432F",
"c> c #5A4736",
"d> c #584A3C",
"e> c #554D43",
"f> c #5D4E45",
"g> c #5C473D",
"h> c #4E3C32",
"i> c #372B22",
"j> c #382F26",
"k> c #483A30",
"l> c #4E3F34",
"m> c #453D34",
"n> c #383329",
"o> c #3D342B",
"p> c #503929",
"q> c #2C2922",
"r> c #564A35",
"s> c #9A8451",
"t> c #A79057",
"u> c #AB9559",
"v> c #AB9459",
"w> c #9D8852",
"x> c #6F5D3D",
"y> c #625139",
"z> c #5C4B35",
"A> c #383331",
"B> c #38312C",
"C> c #453930",
"D> c #2F2925",
"E> c #433930",
"F> c #5F5345",
"G> c #6A5C4C",
"H> c #7E6956",
"I> c #776351",
"J> c #483D36",
"K> c #2F2A21",
"L> c #463D2C",
"M> c #473D2C",
"N> c #563A26",
"O> c #633F26",
"P> c #684026",
"Q> c #5A3B26",
"R> c #5B4A3C",
"S> c #604F40",
"T> c #5F5042",
"U> c #5A4B3F",
"V> c #504237",
"W> c #3F342B",
"X> c #2E251E",
"Y> c #221C17",
"Z> c #28221B",
"\`>    c #2E2821",
" , c #312B23",
"., c #342C26",
"+, c #352C26",
"@, c #362E27",
"#, c #362D27",
"\$,    c #322824",
"%, c #2D221F",
"&, c #2F2421",
"*, c #332E23",
"=, c #383126",
"-, c #332A23",
";, c #3F3127",
">, c #47372B",
",, c #43392F",
"', c #373028",
"), c #2C2821",
"!, c #2F2922",
"~, c #36312A",
"{, c #292523",
"], c #363028",
"^, c #756746",
"/, c #7C744D",
"(, c #78714A",
"_, c #79744D",
":, c #676041",
"<, c #635439",
"[, c #625338",
"}, c #5D5035",
"|, c #40342B",
"1, c #45392E",
"2, c #261F1A",
"3, c #2B231C",
"4, c #493B2D",
"5, c #4B4035",
"6, c #413A32",
"7, c #2F2824",
"8, c #2C2622",
"9, c #332D28",
"0, c #4E453B",
"a, c #5E5245",
"b, c #705F4F",
"c, c #826C5A",
"d, c #6A5C52",
"e, c #4E423B",
"f, c #493E2D",
"g, c #594C34",
"h, c #453A2B",
"i, c #472E21",
"j, c #452D21",
"k, c #3F342C",
"l, c #4B3E34",
"m, c #524438",
"n, c #463A31",
"o, c #221E17",
"p, c #191511",
"q, c #1B1712",
"r, c #211D17",
"s, c #282320",
"t, c #292421",
"u, c #2E2421",
"v, c #352F24",
"w, c #322A21",
"x, c #312820",
"y, c #372D26",
"z, c #3D332C",
"A, c #423A31",
"B, c #373129",
"C, c #2B261F",
"D, c #221D19",
"E, c #35312A",
"F, c #212021",
"G, c #3D382E",
"H, c #444836",
"I, c #454C38",
"J, c #383E30",
"K, c #2E3429",
"L, c #2F3024",
"M, c #312B1B",
"N, c #362C23",
"O, c #2C241D",
"P, c #4E3E2F",
"Q, c #44372E",
"R, c #3A3129",
"S, c #302924",
"T, c #282421",
"U, c #322F29",
"V, c #3F3931",
"W, c #594D41",
"X, c #6F5E4F",
"Y, c #716358",
"Z, c #675A50",
"\`,    c #4B4039",
" ' c #504530",
".' c #5B4E35",
"+' c #432D21",
"@' c #492F21",
"#' c #392821",
"\$'    c #382721",
"%' c #332A25",
"&' c #3D342C",
"*' c #453931",
"=' c #4A3E34",
"-' c #302B22",
";' c #1F1B15",
">' c #191510",
",' c #28231F",
"'' c #282321",
")' c #272320",
"!' c #322C27",
"~' c #423630",
"{' c #443731",
"]' c #423A2E",
"^' c #2F2B20",
"/' c #302B20",
"(' c #2D261D",
"_' c #2C231B",
":' c #322921",
"<' c #382F27",
"[' c #40382F",
"}' c #2A2724",
"|' c #2B2825",
"1' c #2F342A",
"2' c #31382C",
"3' c #2A3028",
"4' c #202722",
"5' c #2F261F",
"6' c #352B22",
"7' c #473C30",
"8' c #312A25",
"9' c #45392F",
"0' c #2A2621",
"a' c #131A19",
"b' c #252521",
"c' c #34302A",
"d' c #60534A",
"e' c #73655A",
"f' c #6D5F55",
"g' c #574B43",
"h' c #5A4D34",
"i' c #615338",
"j' c #635539",
"k' c #453B2B",
"l' c #4C3121",
"m' c #422C21",
"n' c #322421",
"o' c #2A2421",
"p' c #39302A",
"q' c #3E352D",
"r' c #383328",
"s' c #2C271F",
"t' c #28231C",
"u' c #55483E",
"v' c #766354",
"w' c #806B5A",
"x' c #827060",
"y' c #827363",
"z' c #826D5C",
"A' c #7F6A5A",
"B' c #685849",
"C' c #4A4034",
"D' c #41372F",
"E' c #372E27",
"F' c #2D241C",
"G' c #342D25",
"H' c #39332A",
"I' c #212020",
"J' c #14181A",
"K' c #171E1C",
"L' c #1F2621",
"M' c #403227",
"N' c #2A221C",
"O' c #2D251E",
"P' c #47392C",
"Q' c #3D362F",
"R' c #45382E",
"S' c #372F28",
"T' c #181E1E",
"U' c #161D1D",
"V' c #0C1618",
"W' c #141A1A",
"X' c #433933",
"Y' c #584D44",
"Z' c #6B5D4F",
"\`'    c #5F5244",
" ) c #574B40",
".) c #604E36",
"+) c #675339",
"@) c #655238",
"#) c #574832",
"\$)    c #534130",
"%) c #583C29",
"&) c #483427",
"*) c #2C2521",
"=) c #27211D",
"-) c #26201C",
";) c #382E25",
">) c #352F25",
",) c #3C342A",
"') c #3E362C",
")) c #5C4E42",
"!) c #706154",
"~) c #8A796B",
"{) c #907E70",
"]) c #907D70",
"^) c #907D6F",
"/) c #887768",
"() c #887767",
"_) c #746557",
":) c #4C4139",
"<) c #3F372F",
"[) c #312922",
"}) c #2E261F",
"|) c #3D3129",
"1) c #372B24",
"2) c #23211F",
"3) c #222120",
"4) c #1B1D1D",
"5) c #1A1C1D",
"6) c #0F1214",
"7) c #181A1B",
"8) c #372D24",
"9) c #29221B",
"0) c #342C24",
"a) c #473C32",
"b) c #483E36",
"c) c #4B4138",
"d) c #3D3128",
"e) c #43382F",
"f) c #272927",
"g) c #1D2222",
"h) c #141B1D",
"i) c #091417",
"j) c #141312",
"k) c #1D1A17",
"l) c #3B3228",
"m) c #4C4234",
"n) c #625449",
"o) c #4C4138",
"p) c #634B35",
"q) c #674E38",
"r) c #604935",
"s) c #674E37",
"t) c #5F4330",
"u) c #4D3A2C",
"v) c #433429",
"w) c #2E2A24",
"x) c #1D1915",
"y) c #1C1712",
"z) c #241D16",
"A) c #292019",
"B) c #332820",
"C) c #372B23",
"D) c #453D31",
"E) c #605347",
"F) c #705E50",
"G) c #776657",
"H) c #827266",
"I) c #86766A",
"J) c #887468",
"K) c #897367",
"L) c #7A6D60",
"M) c #796D60",
"N) c #74675B",
"O) c #64554A",
"P) c #51463E",
"Q) c #443C34",
"R) c #342D27",
"S) c #2A241F",
"T) c #241E1A",
"U) c #30251F",
"V) c #423129",
"W) c #413129",
"X) c #3D2E26",
"Y) c #332922",
"Z) c #322821",
"\`)    c #23201D",
" ! c #111818",
".! c #151718",
"+! c #1B1B1B",
"@! c #483B32",
"#! c #181712",
"\$!    c #261E17",
"%! c #483F38",
"&! c #493F37",
"*! c #584C42",
"=! c #51453C",
"-! c #473B32",
";! c #35322E",
">! c #1A2021",
",! c #131A1C",
"'! c #101010",
")! c #0F1010",
"!! c #302A22",
"~! c #5D5045",
"{! c #594D43",
"]! c #5E4835",
"^! c #574331",
"/! c #564230",
"(! c #604934",
"_! c #583F2E",
":! c #392F26",
"<! c #201B16",
"[! c #1A1611",
"}! c #1D1813",
"|! c #1F1914",
"1! c #271E17",
"2! c #2B2119",
"3! c #2C2119",
"4! c #392C24",
"5! c #433B2F",
"6! c #5A4E41",
"7! c #736355",
"8! c #756557",
"9! c #776658",
"0! c #786658",
"a! c #79685A",
"b! c #7C6759",
"c! c #7D6758",
"d! c #6D5F54",
"e! c #6C5F53",
"f! c #5D4D44",
"g! c #4F443C",
"h! c #2C231D",
"i! c #48352C",
"j! c #402F26",
"k! c #1A1C1B",
"l! c #1F2020",
"m! c #202020",
"n! c #53433A",
"o! c #3D332B",
"p! c #1B1914",
"q! c #494038",
"r! c #52473E",
"s! c #4D4239",
"t! c #362E29",
"u! c #483A2F",
"v! c #493B31",
"w! c #34322E",
"x! c #202424",
"y! c #28201B",
"z! c #5F5247",
"A! c #564A40",
"B! c #584535",
"C! c #503E2E",
"D! c #4E3D2D",
"E! c #2A221B",
"F! c #201A14",
"G! c #181410",
"H! c #1E1710",
"I! c #221911",
"J! c #261C14",
"K! c #45362E",
"L! c #564A3E",
"M! c #6D5E51",
"N! c #826F61",
"O! c #847163",
"P! c #827164",
"Q! c #817164",
"R! c #746253",
"S! c #735F4F",
"T! c #735D4C",
"U! c #715B4A",
"V! c #625248",
"W! c #615248",
"X! c #615148",
"Y! c #524139",
"Z! c #2D231E",
"\`!    c #45332A",
" ~ c #503B30",
".~ c #44332A",
"+~ c #493329",
"@~ c #21201D",
"#~ c #272626",
"\$~    c #56463C",
"%~ c #5C4A40",
"&~ c #40372F",
"*~ c #4A413A",
"=~ c #423931",
"-~ c #362F29",
";~ c #453E37",
">~ c #443C35",
",~ c #43362D",
"'~ c #4A3D34",
")~ c #4D4139",
"!~ c #312E29",
"~~ c #242521",
"{~ c #131313",
"]~ c #120F0F",
"^~ c #100C0D",
"/~ c #362E28",
"(~ c #5B4B3B",
"_~ c #584837",
":~ c #514334",
"<~ c #3D322A",
"[~ c #453629",
"}~ c #4A3B2E",
"|~ c #3D3126",
"1~ c #211B15",
"2~ c #1E1813",
"3~ c #241C15",
"4~ c #30261E",
"5~ c #3E3228",
"6~ c #5B493F",
"7~ c #746457",
"8~ c #816F60",
"9~ c #837062",
"0~ c #908075",
"a~ c #95867C",
"b~ c #8A7A6F",
"c~ c #7F6D61",
"d~ c #766355",
"e~ c #746150",
"f~ c #715D4D",
"g~ c #6C5747",
"h~ c #634E3C",
"i~ c #544239",
"j~ c #534139",
"k~ c #56453B",
"l~ c #57453C",
"m~ c #4E423A",
"n~ c #342D26",
"o~ c #2A231E",
"p~ c #241E19",
"q~ c #372C25",
"r~ c #554237",
"s~ c #544137",
"t~ c #503E33",
"u~ c #4A392F",
"v~ c #141816",
"w~ c #222323",
"x~ c #695A50",
"y~ c #6C594E",
"z~ c #534339",
"A~ c #29231C",
"B~ c #322B24",
"C~ c #473D35",
"D~ c #3C322B",
"E~ c #4A3E37",
"F~ c #554B44",
"G~ c #3A332F",
"H~ c #342E2A",
"I~ c #332C27",
"J~ c #584D42",
"K~ c #4A3C34",
"L~ c #3B2D27",
"M~ c #42332D",
"N~ c #4A3B33",
"O~ c #4E3F36",
"P~ c #393126",
"Q~ c #181818",
"R~ c #181518",
"S~ c #191518",
"T~ c #181418",
"U~ c #26221D",
"V~ c #4E4639",
"W~ c #585041",
"X~ c #3F3B34",
"Y~ c #2F2F2C",
"Z~ c #433C31",
"\`~    c #352E24",
" { c #2B231A",
".{ c #30261F",
"+{ c #3F342A",
"@{ c #695747",
"#{ c #6A5849",
"\${    c #7A6959",
"%{ c #806D5F",
"&{ c #8B7B6F",
"*{ c #95867B",
"={ c #928378",
"-{ c #89776D",
";{ c #7D6C60",
">{ c #766859",
",{ c #6D5D4F",
"'{ c #56443A",
"){ c #5F4D41",
"!{ c #604E42",
"~{ c #50443B",
"{{ c #433A32",
"]{ c #2B221B",
"^{ c #40352D",
"/{ c #4C4137",
"({ c #39332B",
"_{ c #2D2921",
":{ c #1A1A12",
"<{ c #232321",
"[{ c #433B35",
"}{ c #645951",
"|{ c #827369",
"1{ c #6C5F54",
"2{ c #3A2F27",
"3{ c #493C35",
"4{ c #40342D",
"5{ c #52433C",
"6{ c #4D3F38",
"7{ c #3E3633",
"8{ c #2C2C2D",
"9{ c #302B24",
"0{ c #50473C",
"a{ c #756558",
"b{ c #6E5D51",
"c{ c #5A4A40",
"d{ c #473831",
"e{ c #44362F",
"f{ c #4D3E35",
"g{ c #463930",
"h{ c #252220",
"i{ c #1B1A19",
"j{ c #201C1B",
"k{ c #1D191A",
"l{ c #191A1F",
"m{ c #2C2B2A",
"n{ c #413D35",
"o{ c #50493D",
"p{ c #494339",
"q{ c #3E382D",
"r{ c #373227",
"s{ c #362F25",
"t{ c #342C23",
"u{ c #2E261D",
"v{ c #58493C",
"w{ c #695647",
"x{ c #756050",
"y{ c #846D5A",
"z{ c #796858",
"A{ c #776656",
"B{ c #7D695E",
"C{ c #847267",
"D{ c #8B7A6F",
"E{ c #88776C",
"F{ c #7F7063",
"G{ c #786B5C",
"H{ c #706052",
"I{ c #635144",
"J{ c #6B594A",
"K{ c #614F43",
"L{ c #534138",
"M{ c #261D15",
"N{ c #52463C",
"O{ c #29261E",
"P{ c #292725",
"Q{ c #544A43",
"R{ c #71655C",
"S{ c #8C7D73",
"T{ c #8A7B71",
"U{ c #73665D",
"V{ c #31271F",
"W{ c #3A3028",
"X{ c #4B3D36",
"Y{ c #382D26",
"Z{ c #322E2C",
"\`{    c #2B2720",
" ] c #51473D",
".] c #827062",
"+] c #715F53",
"@] c #4D3D36",
"#] c #3C3329",
"\$]    c #23211E",
"%] c #211D1B",
"&] c #1B1C1F",
"*] c #181C21",
"=] c #1B1F23",
"-] c #403C34",
";] c #5B5243",
">] c #5E564A",
",] c #4A4337",
"'] c #322D22",
")] c #2A2219",
"!] c #2E251D",
"~] c #6B5849",
"{] c #786757",
"]] c #6E5E4D",
"^] c #725D51",
"/] c #735D52",
"(] c #7D685E",
"_] c #87756A",
":] c #887B6F",
"<] c #817567",
"[] c #4B3931",
"}] c #2F261E",
"|] c #62574C",
"1] c #807268",
"2] c #83746B",
"3] c #564A42",
"4] c #322920",
"5] c #4A3D36",
"6] c #4C3E37",
"7] c #37312F",
"8] c #2F2A23",
"9] c #66554A",
"0] c #7B695C",
"a] c #6A594D",
"b] c #55463D",
"c] c #473A31",
"d] c #3E352F",
"e] c #332C28",
"f] c #191918",
"g] c #1F1C1B",
"h] c #474239",
"i] c #675F52",
"j] c #7A7062",
"k] c #796F61",
"l] c #5C5447",
"m] c #352D23",
"n] c #2C241B",
"o] c #362E25",
"p] c #3D372D",
"q] c #514337",
"r] c #715E4D",
"s] c #6F5F4E",
"t] c #675946",
"u] c #705C4F",
"v] c #84796B",
"w] c #827769",
"x] c #59473C",
"y] c #4A3831",
"z] c #372E26",
"A] c #413830",
"B] c #53473E",
"C] c #3B342C",
"D] c #2A271F",
"E] c #292726",
"F] c #938172",
"G] c #8F7E73",
"H] c #7A6C63",
"I] c #655850",
"J] c #51463F",
"K] c #55453E",
"L] c #352B24",
"M] c #312D2B",
"N] c #34322C",
"O] c #493D35",
"P] c #594E41",
"Q] c #50463A",
"R] c #3E332C",
"S] c #43352E",
"T] c #3F322C",
"U] c #302420",
"V] c #281D1A",
"W] c #261F19",
"X] c #2B241D",
"Y] c #2D2520",
"Z] c #241F1B",
"\`]    c #4D463B",
" ^ c #716355",
".^ c #877363",
"+^ c #816D5C",
"@^ c #705F54",
"#^ c #5A4B42",
"\$^    c #4C3E35",
"%^ c #45382D",
"&^ c #625346",
"*^ c #6A594B",
"=^ c #7D6E5C",
"-^ c #7B6C5A",
";^ c #6D5F50",
">^ c #635648",
",^ c #6B5649",
"'^ c #6E584B",
")^ c #715B4F",
"!^ c #796356",
"~^ c #867262",
"{^ c #8A7666",
"]^ c #887564",
"^^ c #57493C",
"/^ c #6A5644",
"(^ c #6B5745",
"_^ c #524236",
":^ c #3F332C",
"<^ c #392D28",
"[^ c #54473A",
"}^ c #625444",
"|^ c #645747",
"1^ c #5E5044",
"2^ c #564A3F",
"3^ c #463C30",
"4^ c #352F26",
"5^ c #2A2520",
"6^ c #2D2722",
"7^ c #8C7A6B",
"8^ c #8F7C6E",
"9^ c #786F67",
"0^ c #686562",
"a^ c #605F5D",
"b^ c #535351",
"c^ c #3A3531",
"d^ c #362D25",
"e^ c #423833",
"f^ c #312B27",
"g^ c #2E2A27",
"h^ c #393831",
"i^ c #3B322B",
"j^ c #494035",
"k^ c #564B3F",
"l^ c #44352E",
"m^ c #43342D",
"n^ c #392A25",
"o^ c #2D251D",
"p^ c #3C3128",
"q^ c #3D3228",
"r^ c #3B3026",
"s^ c #30261D",
"t^ c #2C2A23",
"u^ c #373229",
"v^ c #54493D",
"w^ c #7E6A59",
"x^ c #917E6F",
"y^ c #907E6F",
"z^ c #7F6E61",
"A^ c #715F54",
"B^ c #524238",
"C^ c #46382D",
"D^ c #615648",
"E^ c #6D6051",
"F^ c #6B5E4F",
"G^ c #594E43",
"H^ c #59483D",
"I^ c #5C4A3D",
"J^ c #645042",
"K^ c #766051",
"L^ c #816C5B",
"M^ c #8A7462",
"N^ c #625245",
"O^ c #5C4A3B",
"P^ c #5C4B3B",
"Q^ c #4D3E32",
"R^ c #392D29",
"S^ c #3F322D",
"T^ c #5B4D3D",
"U^ c #685A49",
"V^ c #605245",
"W^ c #584B39",
"X^ c #483E30",
"Y^ c #2A2521",
"Z^ c #2F2721",
"\`^    c #4B3D32",
" / c #504236",
"./ c #705B48",
"+/ c #706256",
"@/ c #5E554A",
"#/ c #4F4D4A",
"\$/    c #4A4F50",
"%/ c #4B5152",
"&/ c #3E4142",
"*/ c #26211F",
"=/ c #2C2722",
"-/ c #302C28",
";/ c #31302A",
">/ c #3F372E",
",/ c #493F35",
"'/ c #54483F",
")/ c #54483E",
"!/ c #4B4037",
"~/ c #433830",
"{/ c #4D3D35",
"]/ c #4D3C35",
"^/ c #3F352E",
"// c #44372D",
"(/ c #3A2E25",
"_/ c #372C23",
":/ c #292821",
"</ c #38332B",
"[/ c #5E5144",
"}/ c #7A695C",
"|/ c #837164",
"1/ c #8B796B",
"2/ c #887769",
"3/ c #716356",
"4/ c #5D5144",
"5/ c #413328",
"6/ c #53493F",
"7/ c #615649",
"8/ c #6A5D4F",
"9/ c #5D5246",
"0/ c #514136",
"a/ c #544438",
"b/ c #604F41",
"c/ c #675648",
"d/ c #6D5B4D",
"e/ c #5A493A",
"f/ c #4C3E32",
"g/ c #534539",
"h/ c #5A4D3D",
"i/ c #655845",
"j/ c #665847",
"k/ c #514636",
"l/ c #3D352B",
"m/ c #322A23",
"n/ c #4C3E33",
"o/ c #56473B",
"p/ c #5D4D3E",
"q/ c #665343",
"r/ c #745D4A",
"s/ c #47423A",
"t/ c #46423A",
"u/ c #464239",
"v/ c #4A4C4B",
"w/ c #3E4243",
"x/ c #2E2F30",
"y/ c #2E2824",
"z/ c #292521",
"A/ c #2E2A26",
"B/ c #443B31",
"C/ c #423930",
"D/ c #443931",
"E/ c #4D4138",
"F/ c #503F37",
"G/ c #352B23",
"H/ c #483B31",
"I/ c #473A2F",
"J/ c #443D33",
"K/ c #484036",
"L/ c #56463D",
"M/ c #6F5E52",
"N/ c #847365",
"O/ c #8C7F70",
"P/ c #857B6D",
"Q/ c #817768",
"R/ c #655A4D",
"S/ c #56493D",
"T/ c #4B4239",
"U/ c #4E453C",
"V/ c #64584B",
"W/ c #655245",
"X/ c #5E4B3E",
"Y/ c #57453A",
"Z/ c #594839",
"\`/    c #4E3F33",
" ( c #4B3D31",
".( c #544436",
"+( c #5D4F3E",
"@( c #605240",
"#( c #615341",
"\$(    c #645745",
"%( c #645746",
"&( c #3A3329",
"*( c #393229",
"=( c #342B24",
"-( c #534438",
";( c #625040",
">( c #6A5645",
",( c #443A33",
"'( c #4D4037",
")( c #423E36",
"!( c #4E483F",
"~( c #4A4A48",
"{( c #3D4142",
"]( c #262627",
"^( c #27221E",
"/( c #3F362D",
"(( c #42372F",
"_( c #524439",
":( c #57473C",
"<( c #524339",
"[( c #392E26",
"}( c #483E33",
"|( c #494036",
"1( c #494137",
"2( c #5E4F43",
"3( c #726254",
"4( c #837464",
"5( c #877868",
"6( c #8B7B6A",
"7( c #7E6C5C",
"8( c #766454",
"9( c #635347",
"0( c #5A4E42",
"a( c #615447",
"b( c #66594B",
"c( c #6E5A49",
"d( c #675345",
"e( c #5E4D41",
"f( c #5B4B3F",
"g( c #594A3D",
"h( c #554539",
"i( c #4E3E35",
"j( c #665645",
"k( c #675746",
"l( c #625241",
"m( c #5F4F3E",
"n( c #5C4D42",
"o( c #594B41",
"p( c #4B4236",
"q( c #3C332C",
"r( c #3A302A",
"s( c #3C332B",
"t( c #352C25",
"u( c #504137",
"v( c #5D4D3D",
"w( c #695745",
"x( c #534639",
"y( c #3B332D",
"z( c #383530",
"A( c #423F3A",
"B( c #47423B",
"C( c #3A3937",
"D( c #292B2C",
"E( c #1E1C1B",
"F( c #221E1C",
"G( c #2A231D",
"H( c #28251F",
"I( c #372F27",
"J( c #322B22",
"K( c #352C23",
"L( c #4B3B30",
"M( c #40332B",
"N( c #42352C",
"O( c #3F352C",
"P( c #473C33",
"Q( c #483E35",
"R( c #514439",
"S( c #574A3C",
"T( c #605243",
"U( c #726151",
"V( c #7D6959",
"W( c #85705F",
"X( c #887261",
"Y( c #887260",
"Z( c #786453",
"\`(    c #6F5D4E",
" _ c #6F5E4E",
"._ c #6B5A4C",
"+_ c #6F5B49",
"@_ c #6B5847",
"#_ c #645345",
"\$_    c #635345",
"%_ c #635143",
"&_ c #5D4D40",
"*_ c #5C4D3F",
"=_ c #53423A",
"-_ c #56453C",
";_ c #5E4C41",
">_ c #604F3F",
",_ c #5A4939",
"'_ c #5A4A3E",
")_ c #5A4A41",
"!_ c #58483F",
"~_ c #594940",
"{_ c #594A40",
"]_ c #4B4539",
"^_ c #3F342E",
"/_ c #3A2E2A",
"(_ c #3D322D",
"__ c #3C3129",
":_ c #58473E",
"<_ c #5D4B41",
"[_ c #56483B",
"}_ c #584C3C",
"|_ c #3B3834",
"1_ c #4A4542",
"2_ c #45413E",
"3_ c #33312D",
"4_ c #201F1D",
"5_ c #111010",
"6_ c #1B1713",
"7_ c #231C16",
"8_ c #281F18",
"9_ c #312F28",
"0_ c #2F2920",
"a_ c #2A261D",
"b_ c #40352A",
"c_ c #493E32",
"d_ c #4E4236",
"e_ c #4A3D32",
"f_ c #41372D",
"g_ c #40372D",
"h_ c #3C2F26",
"i_ c #43352A",
"j_ c #54473B",
"k_ c #645549",
"l_ c #655649",
"m_ c #705F51",
"n_ c #756254",
"o_ c #7A6654",
"p_ c #7F6957",
"q_ c #756151",
"r_ c #6C5948",
"s_ c #695646",
"t_ c #5F4F42",
"u_ c #675547",
"v_ c #6A584A",
"w_ c #685648",
"x_ c #685748",
"y_ c #665445",
"z_ c #5F4E3E",
"A_ c #5D4B3C",
"B_ c #5A493D",
"C_ c #5A4B41",
"D_ c #5F5046",
"E_ c #5D4E44",
"F_ c #494238",
"G_ c #3D312C",
"H_ c #3A2D2A",
"I_ c #392C29",
"J_ c #342924",
"K_ c #5B4A40",
"L_ c #675349",
"M_ c #57483D",
"N_ c #544839",
"O_ c #5F5240",
"P_ c #574B3B",
"Q_ c #453C31",
"R_ c #433E3A",
"S_ c #3E3A37",
"T_ c #282724",
"U_ c #111511",
"V_ c #101110",
"W_ c #131211",
"X_ c #1B1714",
"Y_ c #1E1914",
"Z_ c #251D16",
"\`_    c #30281F",
" : c #393228",
".: c #403E36",
"+: c #3A3932",
"@: c #383730",
"#: c #28241C",
"\$:    c #453C30",
"%: c #423A2F",
"&: c #413A2F",
"*: c #3D3027",
"=: c #52453A",
"-: c #55483B",
";: c #55473B",
">: c #584B3F",
",: c #5B4E43",
"': c #605146",
"): c #69584C",
"!: c #68584A",
"~: c #746151",
"{: c #6D5A49",
"]: c #6A5847",
"^: c #655446",
"/: c #5F5044",
"(: c #5B4C40",
"_: c #5B4C3F",
":: c #584A3E",
"<: c #625043",
"[: c #645243",
"}: c #625141",
"|: c #604E3F",
"1: c #5F4D3E",
"2: c #5E4E41",
"3: c #5E4F45",
"4: c #5C4D43",
"5: c #625441",
"6: c #615441",
"7: c #504537",
"8: c #393630",
"9: c #222320",
"0: c #161815",
"a: c #101410",
"b: c #111210",
"c: c #141211",
"d: c #181513",
"e: c #251E17",
"f: c #2C241C",
"g: c #383127",
"h: c #413B2F",
"i: c #424037",
"j: c #424139",
"k: c #414038",
"l: c #38312A",
"m: c #373029",
"n: c #2F2820",
"o: c #23211A",
"p: c #24221A",
"q: c #332C22",
"r: c #41372C",
"s: c #3D3328",
"t: c #3F332A",
"u: c #41382E",
"v: c #433A30",
"w: c #45382C",
"x: c #473A2E",
"y: c #635544",
"z: c #685949",
"A: c #5B4D41",
"B: c #605045",
"C: c #69574A",
"D: c #574A3F",
"E: c #665648",
"F: c #69584A",
"G: c #695748",
"H: c #655547",
"I: c #5F5043",
"J: c #5B4D40",
"K: c #5B4C3E",
"L: c #605043",
"M: c #604F42",
"N: c #5A493E",
"O: c #5D4C3D",
"P: c #5B4B3C",
"Q: c #635448",
"R: c #615246",
"S: c #57473D",
"T: c #40352E",
"U: c #372C28",
"V: c #372B27",
"W: c #312822",
"X: c #4B3D34",
"Y: c #5A493F",
"Z: c #56473C",
"\`:    c #584B3C",
" < c #625341",
".< c #57493B",
"+< c #342E27",
"@< c #171713",
"#< c #161713",
"\$<    c #171612",
"%< c #181512",
"&< c #1C1714",
"*< c #302922",
"=< c #3D352C",
"-< c #453F34",
";< c #4A4439",
">< c #3E3E38",
",< c #3C3E39",
"'< c #353530",
")< c #36352E",
"!< c #36342C",
"~< c #2E2921",
"{< c #28231E",
"]< c #31271E",
"^< c #362A20",
"/< c #41332A",
"(< c #42352A",
"_< c #4B4132",
":< c #4B4232",
"<< c #53463A",
"[< c #594939",
"}< c #756354",
"|< c #715F50",
"1< c #5D4C41",
"2< c #624F43",
"3< c #58483D",
"4< c #635244",
"5< c #65564A",
"6< c #63554A",
"7< c #5C4C3D",
"8< c #5A4C3F",
"9< c #5D4E42",
"0< c #605042",
"a< c #5E4F42",
"b< c #614F41",
"c< c #54443A",
"d< c #383029",
"e< c #332A24",
"f< c #312923",
"g< c #2C231C",
"h< c #44382E",
"i< c #59493D",
"j< c #231D19",
"k< c #1C1713",
"l< c #1F1A15",
"m< c #3B332C",
"n< c #362E2A",
"o< c #2C3336",
"p< c #293439",
"q< c #302D25",
"r< c #28221D",
"s< c #27201A",
"t< c #29211B",
"u< c #2C261E",
"v< c #473D34",
"w< c #5B4C42",
"x< c #615048",
"y< c #615049",
"z< c #5B4A3B",
"A< c #615040",
"B< c #635242",
"C< c #58493E",
"D< c #58493D",
"E< c #54463A",
"F< c #5E4E40",
"G< c #5A4A3A",
"H< c #5A4D41",
"I< c #625142",
"J< c #645242",
"K< c #635041",
"L< c #5E4D3F",
"M< c #514137",
"N< c #453630",
"O< c #322923",
"P< c #29231E",
"Q< c #2E2721",
"R< c #29211A",
"S< c #58483C",
"T< c #625041",
"U< c #705B49",
"V< c #4B3C32",
"W< c #43352D",
"X< c #3E312A",
"Y< c #28211B",
"Z< c #352D25",
"\`<    c #463C33",
" [ c #3F3731",
".[ c #272120",
"+[ c #282F33",
"@[ c #2D2922",
"#[ c #312C23",
"\$[    c #2F2B22",
"%[ c #26211C",
"&[ c #221C18",
"*[ c #222018",
"=[ c #2A251D",
"-[ c #3A2E27",
";[ c #43362B",
">[ c #554639",
",[ c #54463B",
"'[ c #5A4A3F",
")[ c #615144",
"![ c #5E4F41",
"~[ c #625348",
"{[ c #625448",
"][ c #605144",
"^[ c #5C4C3E",
"/[ c #5A4C3E",
"([ c #5D4B3E",
"_[ c #514238",
":[ c #2B241F",
"<[ c #483C31",
"[[ c #5A473B",
"}[ c #584539",
"|[ c #453A2F",
"1[ c #4F4339",
"2[ c #463D36",
"3[ c #221D1D",
"4[ c #241F1F",
"5[ c #372F2B",
"6[ c #29251E",
"7[ c #2B261E",
"8[ c #28231D",
"9[ c #2F251D",
"0[ c #302820",
"a[ c #524639",
"b[ c #4B3F36",
"c[ c #433931",
"d[ c #463B33",
"e[ c #705748",
"f[ c #725849",
"g[ c #4E3D34",
"h[ c #3F352B",
"i[ c #252020",
"j[ c #292322",
"k[ c #342C25",
"l[ c #26201B",
"m[ c #302720",
"n[ c #302821",
"o[ c #42382D",
"p[ c #4D4033",
"q[ c #554537",
"r[ c #554739",
"s[ c #544639",
"t[ c #5A4B40",
"u[ c #5F5146",
"v[ c #64564B",
"w[ c #5D4F43",
"x[ c #5E4D3E",
"y[ c #5C4C40",
"z[ c #58473F",
"A[ c #54443D",
"B[ c #3F3229",
"C[ c #302822",
"D[ c #282019",
"E[ c #31281F",
"F[ c #453B32",
"G[ c #453B33",
"H[ c #443A32",
"I[ c #6C5B4A",
"J[ c #6E5C4A",
"K[ c #4E4134",
"L[ c #352D28",
"M[ c #29221D",
"N[ c #1F1C1C",
"O[ c #453C33",
"P[ c #392E25",
"Q[ c #31261E",
"R[ c #2F2722",
"S[ c #433A2F",
"T[ c #493E31",
"U[ c #514335",
"V[ c #5C4F43",
"W[ c #594C3F",
"X[ c #5A4942",
"Y[ c #615349",
"Z[ c #6C6154",
"\`[    c #665947",
" } c #57473B",
".} c #5B4B3E",
"+} c #5D4C3F",
"@} c #5B4A3E",
"#} c #59483F",
"\$}    c #56463E",
"%} c #493A30",
"&} c #332B24",
"*} c #3D342D",
"=} c #473C34",
"-} c #4C4038",
";} c #6A5C4A",
">} c #594D3C",
",} c #3C3226",
"'} c #2E2720",
")} c #2A221A",
"!} c #2B251F",
"~} c #433B34",
"{} c #493E36",
"]} c #41342A",
"^} c #27211C",
"/} c #302721",
"(} c #463C2F",
"_} c #504234",
":} c #544537",
"<} c #5D5044",
"[} c #645446",
"}} c #57463B",
"|} c #5D4D45",
"1} c #63544A",
"2} c #56463B",
"3} c #5E4C3D",
"4} c #685647",
"5} c #675546",
"6} c #625042",
"7} c #5E4C3F",
"8} c #58473C",
"9} c #57463E",
"0} c #594841",
"a} c #4F3F36",
"b} c #433831",
"c} c #5B4E44",
"d} c #5E5141",
"e} c #564A39",
"f} c #382F24",
"g} c #2C251D",
"h} c #2D261E",
"i} c #2A211A",
"j} c #302A26",
"k} c #312D29",
"l} c #40413D",
"m} c #3D403D",
"n} c #4A3F37",
"o} c #372E28",
"p} c #362C25",
"q} c #382E27",
"r} c #3F382C",
"s} c #443B2E",
"t} c #4B3F31",
"u} c #584839",
"v} c #594A3E",
"w} c #574539",
"x} c #5A463A",
"y} c #655444",
"z} c #665545",
"A} c #665546",
"B} c #55443B",
"C} c #534239",
"D} c #53423B",
"E} c #54443C",
"F} c #4C3D33",
"G} c #2F2720",
"H} c #4B3F37",
"I} c #463B2F",
"J} c #453A2D",
"K} c #2B231B",
"L} c #34302B",
"M} c #444440",
"N} c #353735",
"O} c #3F3B3B",
"P} c #413C3A",
"Q} c #423A35",
"R} c #423A34",
"S} c #382E28",
"T} c #362E26",
"U} c #393128",
"V} c #42382C",
"W} c #483D30",
"X} c #504538",
"Y} c #5B4D3E",
"Z} c #635346",
"\`}    c #605143",
" | c #57483A",
".| c #4F4036",
"+| c #4E3F35",
"@| c #554538",
"#| c #56483A",
"\$|    c #54463C",
"%| c #56493E",
"&| c #58453A",
"*| c #4E4037",
"=| c #46382F",
"-| c #2F2821",
";| c #29231D",
">| c #322A22",
",| c #42382F",
"'| c #493D34",
")| c #443930",
"!| c #312720",
"~| c #261D18",
"{| c #231B16",
"]| c #251D17",
"^| c #2B231D",
"/| c #39322E",
"(| c #3C3938",
"_| c #443F3B",
":| c #3E3935",
"<| c #46413E",
"[| c #3B4141",
"}| c #34373D",
"|| c #373637",
"1| c #3A3838",
"2| c #3D332D",
"3| c #382D28",
"4| c #332B23",
"5| c #383228",
"6| c #3F3429",
"7| c #46392D",
"8| c #554A3D",
"9| c #5B4A3A",
"0| c #554437",
"a| c #4D3B33",
"b| c #4E4335",
"c| c #514738",
"d| c #504637",
"e| c #4C4033",
"f| c #4C4233",
"g| c #514838",
"h| c #524939",
"i| c #57483C",
"j| c #5B493E",
"k| c #5D4A3F",
"l| c #5B4C41",
"m| c #56473E",
"n| c #54443B",
"o| c #53463B",
"p| c #4B3F35",
"q| c #322C22",
"r| c #2B261D",
"s| c #27221B",
"t| c #26211B",
"u| c #372F25",
"v| c #41362C",
"w| c #43372E",
"x| c #3E332A",
"y| c #302521",
"z| c #221919",
"A| c #1C1613",
"B| c #2E2520",
"C| c #362B25",
"D| c #433B38",
"E| c #414041",
"F| c #39393A",
"G| c #2D2F30",
"H| c #2F3C40",
"I| c #333232",
"J| c #3C322C",
"K| c #3E332D",
"L| c #3C312C",
"M| c #342D24",
"N| c #373127",
"O| c #483B2F",
"P| c #4F4337",
"Q| c #554A3C",
"R| c #584738",
"S| c #534236",
"T| c #483D2F",
"U| c #493E30",
"V| c #463A2D",
"W| c #4D4234",
"X| c #5C4A3E",
"Y| c #5B4B40",
"Z| c #3E322A",
"\`|    c #362C24",
" 1 c #2F2A20",
".1 c #241F1A",
"+1 c #2B201D",
"@1 c #231A19",
"#1 c #211818",
"\$1    c #28201C",
"%1 c #342923",
"&1 c #433935",
"*1 c #333434",
"=1 c #27292A",
"-1 c #3D3C3D",
";1 c #323132",
">1 c #272726",
",1 c #332623",
"'1 c #3B302B",
")1 c #312921",
"!1 c #352E25",
"~1 c #3E3328",
"{1 c #524538",
"]1 c #544336",
"^1 c #544236",
"/1 c #514035",
"(1 c #4A3C30",
"_1 c #473B2E",
":1 c #57493F",
"<1 c #55453C",
"[1 c #443A30",
"}1 c #2B251E",
"|1 c #2E2920",
"11 c #3F332B",
"21 c #221918",
"31 c #251C1A",
"41 c #392D27",
"51 c #473931",
"61 c #4F3F37",
"71 c #2F2823",
"81 c #171B1B",
"91 c #2C2E2F",
"01 c #352925",
"a1 c #362926",
"b1 c #3A2E29",
"c1 c #3D312D",
"d1 c #3E362B",
"e1 c #453B2F",
"f1 c #493A31",
"g1 c #46372F",
"h1 c #45362F",
"i1 c #42372C",
"j1 c #3F3329",
"k1 c #41352B",
"l1 c #5C4D41",
"m1 c #5D4C40",
"n1 c #4F4034",
"o1 c #47392D",
"p1 c #43362A",
"q1 c #3C312B",
"r1 c #3E342D",
"s1 c #42392F",
"t1 c #42362C",
"u1 c #2D261F",
"v1 c #201C17",
"w1 c #1F1B16",
"x1 c #211C17",
"y1 c #2A241D",
"z1 c #2A251E",
"A1 c #332C24",
"B1 c #483D34",
"C1 c #4D4136",
"D1 c #1F1716",
"E1 c #241C1A",
"F1 c #3A2F28",
"G1 c #453831",
"H1 c #443730",
"I1 c #251F1B",
"J1 c #1D1B19",
"K1 c #1F2120",
"L1 c #2F2F2F",
"M1 c #423431",
"N1 c #3A2C29",
"O1 c #3B332B",
"P1 c #4C3F35",
"Q1 c #58483B",
"R1 c #624E3E",
"S1 c #6B5542",
"T1 c #685341",
"U1 c #433630",
"V1 c #433531",
"W1 c #4F4537",
"X1 c #4E4237",
"Y1 c #212018",
"Z1 c #191911",
"\`1    c #181810",
" 2 c #201C16",
".2 c #2D2620",
"+2 c #28211C",
"@2 c #342F28",
"#2 c #2B2923",
"\$2    c #201B18",
"%2 c #221E1A",
"&2 c #292624",
"*2 c #36312E",
"=2 c #332826",
"-2 c #2F2420",
";2 c #30241F",
">2 c #372A27",
",2 c #362D28",
"'2 c #322A25",
")2 c #2D2622",
"!2 c #2C2522",
"~2 c #2C2621",
"{2 c #2C2720",
"]2 c #2E2B24",
"^2 c #514038",
"/2 c #483D33",
"(2 c #5B493B",
"_2 c #665140",
":2 c #4F4234",
"<2 c #574737",
"[2 c #4E4133",
"}2 c #423A2D",
"|2 c #493F34",
"12 c #4E4437",
"22 c #1C1A13",
"32 c #1C1A12",
"42 c #221D17",
"52 c #1B1611",
"62 c #28221C",
"72 c #2C2520",
"82 c #1F1A17",
"92 c #231F1C",
"02 c #272422",
"a2 c #2A2624",
"b2 c #262321",
"c2 c #291F19",
"d2 c #291F18",
"e2 c #2D221D",
"f2 c #2E2723",
"g2 c #26201F",
"h2 c #231D1E",
"i2 c #231F1A",
"j2 c #232018",
"k2 c #514237",
"l2 c #5A493B",
"m2 c #453B2E",
"n2 c #4A3E35",
"o2 c #4D4236",
"p2 c #41392E",
"q2 c #29201B",
"r2 c #302320",
"s2 c #2E2621",
"t2 c #231D18",
"u2 c #1C1614",
"v2 c #1A1312",
"w2 c #231A12",
"x2 c #221810",
"y2 c #261C15",
"z2 c #241D19",
"A2 c #221D18",
"B2 c #231E1E",
"C2 c #241E1E",
"D2 c #1F191B",
"E2 c #191714",
"F2 c #191810",
"G2 c #1A1911",
"H2 c #242018",
"I2 c #453A32",
"J2 c #483C32",
"K2 c #443932",
"L2 c #3C362B",
"M2 c #453C2F",
"N2 c #40342F",
"O2 c #453833",
"P2 c #473B34",
"Q2 c #463933",
"R2 c #3B312B",
"S2 c #332E24",
"T2 c #322D24",
"U2 c #2F2320",
"V2 c #191410",
"W2 c #191211",
"X2 c #191111",
"Y2 c #181010",
"Z2 c #2C2724",
"\`2    c #383330",
" 3 c #423D3D",
".3 c #332F2F",
"+3 c #1F2325",
"@3 c #191B1B",
"#3 c #161614",
"\$3    c #181715",
"%3 c #18191A",
"&3 c #161819",
"*3 c #171C1D",
"=3 c #171A1B",
"-3 c #131415",
";3 c #151311",
">3 c #1B1813",
",3 c #1F1A14",
"'3 c #231E17",
")3 c #282018",
"!3 c #524239",
"~3 c #373027",
"{3 c #4C4238",
"]3 c #483F36",
"^3 c #3B352D",
"/3 c #2C261D",
"(3 c #28221A",
"_3 c #25201B",
":3 c #29231F",
"<3 c #28211E",
"[3 c #201A16",
"}3 c #2D231F",
"|3 c #261F1C",
"13 c #33302F",
"23 c #1A1613",
"33 c #14100C",
"43 c #130F0B",
"53 c #12110F",
"63 c #111212",
"73 c #161A1A",
"83 c #1E2525",
"93 c #2A3236",
"03 c #2F343C",
"a3 c #2C2B2C",
"b3 c #28353E",
"c3 c #1F2C33",
"d3 c #1A252A",
"e3 c #141E21",
"f3 c #151412",
"g3 c #101112",
"h3 c #121618",
"i3 c #101E1F",
"j3 c #0E1B1B",
"k3 c #0C1010",
"l3 c #0B0C0C",
"m3 c #141210",
"n3 c #322A24",
"o3 c #27241C",
"p3 c #2B271F",
"q3 c #393127",
"r3 c #3E3730",
"s3 c #3C352E",
"t3 c #352D26",
"u3 c #2C251E",
"v3 c #1C1814",
"w3 c #1D1815",
"x3 c #241C18",
"y3 c #291F1C",
"z3 c #211916",
"A3 c #1C1918",
"B3 c #252425",
"C3 c #1F1E1F",
"D3 c #100D09",
"E3 c #100C08",
"F3 c #15191B",
"G3 c #182021",
"H3 c #1F2A2B",
"I3 c #273536",
"J3 c #283637",
"K3 c #273538",
"L3 c #233038",
"M3 c #223038",
"N3 c #233139",
"O3 c #1D2930",
"P3 c #191C1D",
"Q3 c #1A1919",
"R3 c #18140F",
"S3 c #121517",
"T3 c #131B1F",
"U3 c #0F1B1C",
"V3 c #0D1516",
"W3 c #0B0C0D",
"X3 c #0B0B0B",
"Y3 c #11100F",
"Z3 c #191613",
"\`3    c #25221B",
" 4 c #25231B",
".4 c #3B3129",
"+4 c #453830",
"@4 c #45382F",
"#4 c #3A3228",
"\$4    c #2E2823",
"%4 c #352E28",
"&4 c #312A23",
"*4 c #34291F",
"=4 c #34281F",
"-4 c #241E18",
";4 c #231E1B",
">4 c #1E1916",
",4 c #261D1A",
"'4 c #291F1B",
")4 c #221A17",
"!4 c #1B1612",
"~4 c #1F1E1D",
"{4 c #292829",
"]4 c #2B2B2B",
"^4 c #1D1C1D",
"/4 c #100D0A",
"(4 c #141616",
"_4 c #161F24",
":4 c #19262C",
"<4 c #202D30",
"[4 c #263435",
"}4 c #253333",
"|4 c #1E2A30",
"14 c #1F2B32",
"24 c #1F2B33",
"34 c #1E282E",
"44 c #1C2326",
"54 c #17252D",
"64 c #151E23",
"74 c #0D1011",
"84 c #0E0E0E",
"94 c #221B15",
"04 c #231F18",
"a4 c #26221B",
"b4 c #242019",
"c4 c #271F19",
"d4 c #191512",
"e4 c #211A17",
"f4 c #1F1815",
"g4 c #1A1512",
"h4 c #201D1C",
"i4 c #222122",
"j4 c #1E1D1E",
"k4 c #1B1A1B",
"l4 c #16191B",
"m4 c #1A282F",
"n4 c #1E3540",
"o4 c #1F3845",
"p4 c #21333A",
"q4 c #222E2F",
"r4 c #1E2A31",
"s4 c #1C2427",
"t4 c #1E272B",
"u4 c #262C2D",
"v4 c #1D2528",
"w4 c #161B1D",
"x4 c #0A0A0A",
"y4 c #0B0B0A",
"z4 c #110F0D",
"A4 c #181411",
"B4 c #211B16",
"C4 c #1E1915",
"D4 c #1C1813",
"E4 c #1F1C16",
"F4 c #1F1D16",
"G4 c #2A261E",
"H4 c #312A22",
"I4 c #251E18",
"J4 c #1F1C17",
"K4 c #1C1913",
"L4 c #1A1612",
"M4 c #1B1513",
"N4 c #141010",
"O4 c #16130F",
"P4 c #1B1512",
"Q4 c #1E1814",
"R4 c #1E1917",
"S4 c #1B1815",
"T4 c #171410",
"U4 c #201F1F",
"V4 c #222525",
"W4 c #222425",
"X4 c #1C2223",
"Y4 c #1D2A30",
"Z4 c #1E333E",
"\`4    c #282721",
" 5 c #313029",
".5 c #22211C",
"+5 c #171613",
"@5 c #090909",
"#5 c #090908",
"\$5    c #0C0B0A",
"%5 c #13100C",
"&5 c #18130F",
"*5 c #201B17",
"=5 c #1C1514",
"-5 c #17130E",
";5 c #1A1412",
">5 c #1A1712",
",5 c #1C1914",
"'5 c #1F1E17",
")5 c #201F17",
"!5 c #25211B",
"~5 c #221D1A",
"{5 c #17120F",
"]5 c #160F0F",
"^5 c #170F0F",
"/5 c #14110E",
"(5 c #1E1713",
"_5 c #1B1916",
":5 c #181714",
"<5 c #15140F",
"[5 c #212423",
"}5 c #272C2D",
"|5 c #292E2F",
"15 c #252A2B",
"25 c #262A2B",
"35 c #2D2C26",
"45 c #22211B",
"55 c #0F0D0C",
"65 c #110F0C",
"75 c #15110D",
"85 c #1E1716",
"95 c #1D1B14",
"05 c #1E1C15",
"a5 c #25201D",
"b5 c #1B1613",
"c5 c #110E0B",
"d5 c #0D0A09",
"e5 c #0E0B09",
"f5 c #150F0E",
"g5 c #14110D",
"h5 c #17140F",
"i5 c #12120B",
"j5 c #101008",
"k5 c #14140F",
"l5 c #323A3A",
"m5 c #23221D",
"n5 c #191815",
"o5 c #0D0C0B",
"p5 c #120F0D",
"q5 c #13100D",
"r5 c #1F1A16",
"s5 c #1D1A14",
"t5 c #0C0A06",
"u5 c #080805",
"v5 c #090906",
"w5 c #0F0C0A",
"x5 c #13110D",
"y5 c #1D1612",
"z5 c #15120C",
"A5 c #262B2C",
"B5 c #252727",
"C5 c #131110",
"D5 c #140F0E",
"E5 c #15100E",
"F5 c #16110E",
"G5 c #15120E",
"H5 c #191412",
"I5 c #1A1713",
"J5 c #1A1814",
"K5 c #1A1815",
"L5 c #1B1915",
"M5 c #2F2620",
"N5 c #191612",
"O5 c #110D0A",
"P5 c #0E0A08",
"Q5 c #0A0806",
"R5 c #060704",
"S5 c #0A0907",
"T5 c #12100D",
"U5 c #12110E",
"V5 c #191411",
"W5 c #0F0F0A",
"X5 c #0E0E08",
"Y5 c #0F100C",
"Z5 c #141614",
"\`5    c #212526",
" 6 c #222C38",
".6 c #1C2226",
"+6 c #191819",
"@6 c #181310",
"#6 c #10100D",
"\$6    c #15120F",
"%6 c #161615",
"&6 c #1D1A18",
"*6 c #201C18",
"=6 c #191513",
"-6 c #12110B",
";6 c #0E0C08",
">6 c #090508",
",6 c #040404",
"'6 c #020501",
")6 c #0A0906",
"!6 c #100C0B",
"~6 c #0D0D0D",
"{6 c #080808",
"]6 c #0D1013",
"^6 c #131A1F",
"/6 c #20292D",
"(6 c #293031",
"_6 c #2F3E4E",
":6 c #213238",
"<6 c #1D292C",
"[6 c #191617",
"}6 c #090C0B",
"|6 c #080C0B",
"16 c #0F0C09",
"26 c #120E0B",
"36 c #161514",
"46 c #171717",
"56 c #181613",
"66 c #181412",
"76 c #171311",
"86 c #0F0E0C",
"96 c #0C0909",
"06 c #090608",
"a6 c #080606",
"b6 c #09090A",
"c6 c #101619",
"d6 c #182228",
"e6 c #203B41",
"f6 c #1F3439",
"g6 c #1A1A1C",
"h6 c #171310",
"i6 c #141311",
"j6 c #151413",
"k6 c #171411",
"l6 c #100F0D",
"m6 c #080508",
"n6 c #0C0F10",
"o6 c #1B272E",
"p6 c #202E37",
"q6 c #20383E",
"r6 c #1C282B",
"s6 c #19181A",
"t6 c #110D09",
"u6 c #090808",
"v6 c #110D0C",
"w6 c #0C0C0C",
"x6 c #0E1214",
"y6 c #101518",
"z6 c #1A262C",
"A6 c #213039",
"B6 c #25353C",
"C6 c #252E35",
"D6 c #20252B",
"E6 c #191717",
"F6 c #12110D",
"G6 c #12100F",
"H6 c #15110F",
"I6 c #0B0908",
"J6 c #0C0A07",
"K6 c #060505",
"L6 c #050405",
"M6 c #050305",
"N6 c #060403",
"O6 c #090603",
"P6 c #0A0805",
"Q6 c #131010",
"R6 c #12100E",
"S6 c #0D0C0C",
"T6 c #0C0C0B",
"U6 c #161616",
"V6 c #242526",
"W6 c #282F38",
"X6 c #1F2024",
"Y6 c #14120E",
"Z6 c #100E0C",
"\`6    c #0E0D0B",
" 7 c #0E0C0B",
".7 c #060504",
"+7 c #050403",
"@7 c #040303",
"#7 c #030303",
"\$7    c #060401",
"%7 c #080400",
"&7 c #090501",
"*7 c #110F0E",
"=7 c #191614",
"-7 c #292522",
";7 c #21272C",
">7 c #1A1D1C",
",7 c #11100C",
"'7 c #0A0A09",
")7 c #020202",
"!7 c #010101",
"~7 c #050301",
"{7 c #110E0C",
"]7 c #2A2623",
"^7 c #302B28",
"/7 c #202F34",
"(7 c #1E2B2D",
"_7 c #1A1C1A",
":7 c #0D0D0B",
"<7 c #0A0704",
"[7 c #0E0D0C",
"}7 c #0F0E0D",
"|7 c #2B2624",
"17 c #212C2F",
"27 c #212727",
"37 c #181817",
"47 c #110F0B",
"57 c #0E0E0A",
"67 c #100E0A",
"77 c #0E0C0A",
"87 c #0B0A0A",
"97 c #050604",
"07 c #030402",
"a7 c #020402",
"b7 c #020302",
"c7 c #070603",
"d7 c #0D0804",
"e7 c #0E0A07",
"f7 c #11100E",
"g7 c #0F0E0E",
"h7 c #1D1B1B",
"i7 c #2C2824",
"j7 c #312C26",
"k7 c #272D2E",
"l7 c #1C2021",
"m7 c #111414",
"n7 c #110E0A",
"o7 c #0D0B09",
"p7 c #0A0909",
"q7 c #060906",
"r7 c #050805",
"s7 c #010501",
"t7 c #090905",
"u7 c #10100F",
"v7 c #121313",
"w7 c #2B2823",
"x7 c #322D25",
"y7 c #272E2F",
"z7 c #212728",
"A7 c #161410",
"B7 c #120E0D",
"C7 c #100D0D",
"D7 c #0B0C0B",
"E7 c #070A07",
"F7 c #0C0B08",
"G7 c #131516",
"H7 c #1B2123",
"I7 c #1F2022",
"J7 c #2C2924",
"K7 c #373125",
"L7 c #322F24",
"M7 c #312D23",
"N7 c #1B1C1A",
"O7 c #171511",
"P7 c #130F0D",
"Q7 c #110E0E",
"R7 c #0C0D0C",
"S7 c #0E0D0A",
"T7 c #181C1E",
"U7 c #21292C",
"V7 c #232425",
"W7 c #222121",
"X7 c #393327",
"Y7 c #473E2C",
"Z7 c #3F3729",
"\`7    c #2E2923",
" 8 c #3E392B",
".8 c #484231",
"+8 c #544C37",
"@8 c #4B4432",
"#8 c #282E2F",
"\$8    c #232725",
"%8 c #1D1F1D",
"&8 c #151310",
"*8 c #171414",
"=8 c #1A1618",
"-8 c #191517",
";8 c #161212",
">8 c #121416",
",8 c #191D20",
"'8 c #1B2024",
")8 c #1C2328",
"!8 c #1C2429",
"~8 c #1E2225",
"{8 c #1D2124",
"]8 c #1E2124",
"^8 c #293136",
"/8 c #30302B",
"(8 c #2E2A23",
"_8 c #3E3728",
":8 c #514530",
"<8 c #4C4031",
"[8 c #342E24",
"}8 c #7C6D4B",
"|8 c #A49062",
"18 c #83734F",
"28 c #5A513E",
"38 c #2C2D30",
"48 c #4C4433",
"58 c #675D40",
"68 c #675D3F",
"78 c #282F30",
"88 c #17191B",
"98 c #1C1E22",
"08 c #1A1B1F",
"a8 c #0F1012",
"b8 c #161D21",
"c8 c #161E22",
"d8 c #161D22",
"e8 c #1D272C",
"f8 c #212C31",
"g8 c #293039",
"h8 c #292C32",
"i8 c #292C31",
"j8 c #2E2C27",
"k8 c #52452E",
"l8 c #635336",
"m8 c #393427",
"n8 c #2D2A22",
"o8 c #3F3829",
"p8 c #5F5336",
"q8 c #796741",
"r8 c #7A6841",
"s8 c #554B38",
"t8 c #333131",
"u8 c #4B4438",
"v8 c #6F6143",
"w8 c #9F8B52",
"x8 c #9B894D",
"y8 c #342E20",
"z8 c #191C1C",
"A8 c #131515",
"B8 c #111313",
"C8 c #212428",
"D8 c #202B2F",
"E8 c #202B30",
"F8 c #2C281E",
"G8 c #27251D",
"H8 c #343024",
"I8 c #4B412D",
"J8 c #443B2B",
"K8 c #483F2C",
"L8 c #5E5335",
"M8 c #343222",
"N8 c #333122",
"O8 c #534A30",
"P8 c #4B4334",
"Q8 c #5B513D",
"R8 c #85734A",
"S8 c #89764B",
"T8 c #6D603F",
"U8 c #695D37",
"V8 c #655935",
"W8 c #363121",
"X8 c #151D1E",
"Y8 c #242A2F",
"Z8 c #212B30",
"\`8    c #161D20",
" 9 c #2D2A21",
".9 c #584B32",
"+9 c #6C5939",
"@9 c #635637",
"#9 c #302F21",
"\$9    c #776640",
"%9 c #7A6945",
"&9 c #786947",
"*9 c #5B513C",
"=9 c #2F2E31",
"-9 c #32302B",
";9 c #423A25",
">9 c #665A35",
",9 c #373121",
"'9 c #232829",
")9 c #292F30",
"!9 c #212627",
"~9 c #17191A",
"{9 c #182124",
"]9 c #1D2D30",
"^9 c #1F2C30",
"/9 c #3D3728",
"(9 c #463D2B",
"_9 c #51482F",
":9 c #323121",
"<9 c #776540",
"[9 c #796945",
"}9 c #665A40",
"|9 c #363432",
"19 c #353129",
"29 c #423B25",
"39 c #685C36",
"49 c #323129",
"59 c #24211E",
"69 c #191917",
"79 c #181918",
"89 c #212625",
"99 c #252D2C",
"09 c #413624",
"a9 c #4E3F28",
"b9 c #5B4A2D",
"c9 c #443D26",
"d9 c #373421",
"e9 c #363321",
"f9 c #605332",
"g9 c #5F533A",
"h9 c #383326",
"i9 c #4E4732",
"j9 c #47422F",
"k9 c #363023",
"l9 c #2A241B",
"m9 c #1D1D1A",
"n9 c #222422",
"o9 c #232523",
"p9 c #574528",
"q9 c #765D37",
"r9 c #453C25",
"s9 c #26251A",
"t9 c #35311F",
"u9 c #3D3822",
"v9 c #373223",
"w9 c #272622",
"x9 c #2B2A25",
"y9 c #4A4531",
"z9 c #393324",
"A9 c #2C251C",
"B9 c #202220",
"C9 c #503F25",
"D9 c #7C6139",
"E9 c #514629",
"F9 c #222118",
"G9 c #34311F",
"H9 c #393521",
"I9 c #302D1C",
"J9 c #262521",
"K9 c #3B3526",
"L9 c #2E271D",
"M9 c #261F18",
"N9 c #1E1D19",
"O9 c #7B6139",
"P9 c #594C2B",
"Q9 c #232118",
"R9 c #33301E",
"S9 c #433D29",
"T9 c #4A442E",
"U9 c #2B261C",
"V9 c #26211A",
"W9 c #745E3E",
"X9 c #53492F",
"Y9 c #24211A",
"Z9 c #2E2A1D",
"\`9    c #52492E",
" 0 c #4A422B",
".0 c #2D2A1F",
"+0 c #29271E",
"@0 c #6B5942",
"#0 c #544B35",
"\$0    c #665937",
"%0 c #3F3926",
"&0 c #2C291F",
"*0 c #5F4F3B",
"=0 c #695E41",
"-0 c #363125",
";0 c #645736",
">0 c #28261E",
",0 c #473B2C",
"'0 c #645A3E",
")0 c #48422F",
"!0 c #534935",
"~0 c #615434",
"{0 c #2E2A1E",
"]0 c #44382A",
"^0 c #403C2F",
"/0 c #424237",
"(0 c #313431",
"_0 c #2B3537",
":0 c #544830",
"<0 c #6D5D3C",
"[0 c #574A2F",
"}0 c #3C3321",
"|0 c #212E31",
"10 c #30444A",
"20 c #31454A",
"30 c #2A393D",
"40 c #50442C",
"50 c #5D5033",
"60 c #544730",
"70 c #54482E",
"80 c #645637",
"90 c #826F46",
"00 c #998350",
"a0 c #6C5C3C",
"b0 c #3D3422",
"c0 c #5D533E",
"d0 c #625841",
"e0 c #88764B",
"f0 c #97814F",
"g0 c #433828",
"h0 c #443928",
"i0 c #3A3120",
"j0 c #211C12",
"k0 c #8C7244",
"l0 c #9F824C",
"m0 c #8F7749",
"n0 c #A1824D",
"o0 c #A0824D",
"p0 c #736540",
"q0 c #3B3A2A",
"r0 c #524A32",
"s0 c #4B422C",
"t0 c #252219",
"u0 c #A5864D",
"v0 c #9B7F4A",
"w0 c #76643F",
"x0 c #65583B",
"y0 c #846D42",
"z0 c #7D673E",
"A0 c #343A2C",
"B0 c #3A3E2D",
"C0 c #5B5437",
"D0 c #7D6B46",
"E0 c #7B6A45",
"F0 c #413927",
"G0 c #6C5A3E",
"H0 c #887045",
"I0 c #74613D",
"J0 c #474232",
"K0 c #484333",
"L0 c #695B3B",
"M0 c #605537",
"N0 c #293429",
"O0 c #32392B",
"P0 c #454430",
"Q0 c #66583A",
"R0 c #85724A",
"S0 c #554A32",
"T0 c #766142",
"U0 c #3F3B30",
"V0 c #2A2E2B",
"W0 c #212829",
"X0 c #31322C",
"Y0 c #544E35",
"Z0 c #4C4932",
"\`0    c #67593B",
" a c #5A4F35",
".a c #4D422C",
"+a c #866F49",
"@a c #6C5A3C",
"#a c #3B362B",
"\$a    c #2A2B26",
"%a c #474330",
"&a c #423F2E",
"*a c #2C3229",
"=a c #333026",
"-a c #4F4836",
";a c #504731",
">a c #594B32",
",a c #6C5B3B",
"'a c #4D432E",
")a c #383323",
"!a c #302F29",
"~a c #403F37",
"{a c #50452E",
"]a c #5A4C32",
"^a c #625438",
"/a c #50462F",
"(a c #2E291E",
"_a c #52462E",
":a c #5F5237",
"<a c #514630",
"[a c #212218",
"}a c #363122",
"|a c #2C291D",
"1a c #202118",
"                                                                                                                                                                                                                ",
"                                                                                                                          . + @ +   # \$ % & * = -                                                               ",
"                                                                                                                      ; > , ' ) ) ! ~ # { ] ^ / ( _ : <                                                         ",
"                                                                                                                      [ } | 1 2 1 3 4 # 5 6 7 8 8 ( 9 0                                                         ",
"                                                                                                                  a [ > b c d d e f g h i j 7 8 k l m n o <                                                     ",
"                                                                                                                p q r s t u v v v v w x y z A B C D E F G H I J                                                 ",
"                                                                                                            K L L M N O P Q R R R R S T U V W X Y Y C Z \`  ...+.@.                                              ",
"                                                                                                            L #.\$.%.N O P Q &.*.=.R -.;.>.,.'.).!.~.{.].^./.(._.:.<.[.                                          ",
"                                                                                                          }.|.1.2.3.N O P 4.5.6.7.8.9.0.a.b.c.d.e.X f.g.h.i.j.k.l.m.n.o.p.                                      ",
"                                                                                                        q.r.s.t.u.v.w.x.y.z.A.B.C.D.E.F.F.G.H.I.J.K.L.M.I N.O.P.Q.R.S.T.U.V.W.                                  ",
"                                                                                                        X.Y.Z.\`. +.+++@+#+\$+%+&+*+=+-+;+>+,+} '+)+)+!+~+{+]+^+/+(+_+:+<+[+[+}+|+                                ",
"                                                                                                      1+2+3+4+5+6+7+++8+9+0+a+y.b+c+d+e+f+g+h+{+i+j+k+l+m+^+n+% # o+p+q+r+s+t+u+                                ",
"                                                                                                      v+2+w+4+4+x+y+++++z+A+B+C+D+E+F+e+f+G+H+I+J+K+L+l+m+M+N+# O+P+Q+R+| S+T+U+                                ",
"                                                                                                      v+2+w+4+4+V+7+++++W+X+Y+Z+\`+ @.@e+f+>++@'+@@m+L+l+{+#@^+\$@%@&@Q+*@=@-@%+;@                                ",
"                                                                                                      X.>@,@l '@)@!@~@{@]@^@/@(@_@(@:@<@[@}@|@1@2@3@4@5@6@7@8@9@0@a@b@c@d@e@f@                                  ",
"                                                                                                        g@h@i@j@k@l@m@n@o@p@q@r@s@t@u@v@v@v@w@x@y@z@A@B@B@B@B@C@D@E@F@G@H@I@                                    ",
"                                                                                                        g@J@K@L@M@N@O@P@Q@R@S@T@U@V@W@X@X@Y@Z@\`@ #.#+#5@5@5@B@@###\$#%#&#*#                                      ",
"                                                                                                        g@=#-#-#;#>#)+I+1@,#'#'#)#!#~#{#]#^#/#(#_#:#<#[#}#|#1#2#3#4#                                            ",
"                                                                                                        5#6#6#7#8#9#j+0#a#b#c#c#c#c#d#e#f#g#h#i#j#k#l#m#n#o#p#q#r#s#                                            ",
"                                                                                                          N N N N t#6@j+u#1@v#v#v#v#P@w#x#y#O@z#A#B#C#D#E#F#D#G#H#                                              ",
"                                                                                                          I#J#J#J#K#L#M#j+N#p@p@p@p@O#P#Q#R#S#p@T#U#V#W#X#Y#W#Z#\`#                                              ",
"                                                                                                             \$ \$ \$.\$+\$u#@\$#\$\$\$%\$%\$\$\$&\$*\$=\$-\$;\$>\$,\$'\$)\$!\$~\${\$!\$]\$^\$                                              ",
"                                                                                                              /\$(\$_\$:\$<\$[\$}\$~+|\$1\$2\$3\$m+b#4\$5\$6\$7\$8\$9\$0\$a\$b\$c\$d\$e\$f\$                                            ",
"                                                                                                              g\$h\$i\$'#j\$k\$l\$m\$n\$o\$p\$q\$r\$s\$t\$u\$v\$w\$x\$y\$z\$A\$B\$C\$D\$E\$F\$                                            ",
"                                                                                                                h\$i\$'#G\$H\$I\$J\$K\$p\$L\$M\$N\$O\$P\$Q\$R\$S\$S\$T\$U\$U\$V\$W\$X\$Y\$Z\$\`\$ %                                        ",
"                                                                            .%+%@%#%\$%%%  &%*%=%-%;%;%>%          ,%'#G\$'%)%K\$p\$!%~%Q@{%]%^%/%(%_%_%:%<%<%[%}%|%1%1%2%3%4%                                      ",
"        5%                                                            6%7%8%8%9%#%#%@%@%0%a%b%c%d%e%f%f%e%g%h%    '#'#'#i%j%k%p\$L\$l%m%n%t\$o%p%q%r%r%s%t%t%t%t%|%u%u%v%w%x%y%                                    ",
"        z%A%                                                          B%C%D%E%F%G%G%H%I%J%K%L%M%N%O%P%Q%R%S%T%      U%V%W%X%A@p\$L\$Y%Z%\`% &.&+&@&@&#&\$&%&&&*&=&-&                                                ",
"      ;&>&O@                                                        ,&'&)&!&~&~&{&]&^&^&/&(&_&:&<&[&[&}&|&1&2&3&      4&5&\`@A@p\$L\$B@6&7&8&9&0&a&a&b&c&d&e&a&f&g&                                                ",
"      h&i&)+r#                                                    j&k&l&m&~&n&o&p&q&q&q&r&s&t&:&u&v&v&w&x&y&z&A&B&      C&D&6@E&L\$B@F&7&G&H&0&a&I&J&K&d&L&f&M&g&                                                ",
"      h&N&)+{+                                                    O&P&Q&~&R&S&T&U&V&V&V&W&X&Y&Z&\`&v&v&v&v& *.*+*.*      @*y@#*-#K.B@\$*7&G&H&0&a&%*&***=*-*;*>*,*                              '*                ",
"      )*!*~*{*                                                ]*^*/*(*_*:*:*<*<*[*}*}*}*|*1*2*3*4*5*5*5*5*6*7*6*8*        9*0*a*b*c*d*e*f*g*h*i*j*k*l*m*n*o*p*q*                              r*s*              ",
"      N N t*u*                                          v*v*w*x*y*z*A*B*C*D*E*F*G*H*H*I*J*K*L*M*N*B@B@B@B@O*P*Q*R*S*T*U*V*W*x@X*Y*Z*\`* =.=+=@=#=\$=%=    &=*===-=                            ;=>=,=>&            ",
"      N N '=)=4@                                      !=~={=]=^=/=(=_=:=R*<=[=}=|=1=2=I*3=4=5=6=7=J@J@8=B@9=0=a=R*b=c={=d=e=x@f=g=h=\`* =i=j=k=l=m=\$=    n=o=p=q=                          r=0 s=]@t=u=          ",
"      N N v=w=x=                                    y=z=A=B=B=C=D=E=F=G=H=R*I=R*1=J=K=L=M=8 N=O=P=Q=R=S=T=U=V=W=R*b=X=]=Y=Z=\`= -.-+-.=@-#-\$-%-&-*-\$=      =-=---                          ;->-,-'-u=)-          ",
"      !-!-~-{-]-^-/-                              (-_-:-<-[-}-|-1-2-3-4-5-6-7-8-9-0-a-b-c-d-e-f-g-h-i-2@j-'=k-l-m-n-o-o-p-q-r-s-t-u-v-w-x-y-z-A-B-                                      C-D-E-F-G-H-I-          ",
"      J-J-K-L-M-N-O-                              P-Q-R-S-T-T-U-V-V-V-W-X-Y-Z-Z-\`-N#!@)+)= ; ;.;+;@;#;\$;%;&;;-;-L+*;=;=;-;;;>;,;';);!;~;{;];^;/;(;(;                                    _;:;<;[;};|;1;          ",
"      2;J-3;4;5;N-6;7;8;                          9;Q-0;a;b;R-c;d;e;e;f;Z-g;h;h;-\$n@i;j;k;l;m;m;n;o;#;p;q;r;s;t;L+u;v;w;x;y;z;,;A;B; -C;D;E;F;G;H;I;                                    J;K;L;M;N;|;O;          ",
"        P;Q;3;5;N-R;S;T;U;                        %=V;a;a;W;X;c;Y;Z;Z;W=\`;Z-h;h;r\$r\$ >{+5@.>+>k;v.@>#;#>\$>%>L+&>L+*>=>->;>>>,>,;,;,;++C;D;'>)>!>~>{>]>^>                              />(>_>:>M;N;|;<>          ",
"        [>}>3;|>1>2>3>S;4>5>                    6>7>8>9>0>W;a>b>c>d>e>f>g>h>i>h;r\$r\$r\$j>k>B@B@l>m>@>#;#>\$>n>N '+L+o> -p>;>>>,>,;q>,;++++r>s>t>u>v>w>x>y>z>                            A>5>g;h;M;N;|;            ",
"        B>C>9*D>E>N@F>G>H>I>J>                  K>L>M>N>O>P>Q>\`*R>S>T>U>'=V>W>X>Y>Z>\`> ,.,+,+,@,#,\$,%,%,&,*,*,=,,@j--,;,>,6@,,',),!,~,{,],^,/,(,(,_,:,<,[,},                          |,1,2,3,4,5,6,            ",
"          5@T=7,8,9,0,a,b,c,d,e,                f,g,h,I=C*i,j,k,l,m,m,)+)+@\$n,+;o,p,q,r,s,t,t,t,u,^+^+^+^+'#'#'#v,w,x,y,z,A,& B,C,D,E,F,F,G,H,I,J,K,L,M,                              #*N,D,O,P,A@              ",
"          Q,6@R,S,T,U,V,W,X,Y,Z,\`,             '.'.'h,+'@'#'\$'%'&'*'='@\$)+@\$K+K+-';'>';',''')'!'~'{'{'{'{']'^'/''#('_':'<'['& B,C,#;}'F,F,|'1'2'3'4'                                  #*5'#;6'S*7'              ",
"          8'9'6@!;0't%a'b'c'd'e'f'g'        h'i'j'.'k'l'm'n'^+o'8,p'q'N#{*N.K+K+r's'o,t'5%u'v'w'x'y'y'y'y'z'A'B'C'D'E'F'_'G'H'B,C,#;I'F,F,F,J'K'L'                                  M'#*N'O'%-P'N\$  Q't=        ",
"            7@B@R'S'T'U'V'W'X'Y'Z'\`' )      .)+)@)#)\$)%)&)*)o'=)-)-\$;)>;t-t-t-Q,>)K>,)')))!)~){)])^)^)^)^)/)()_)!.:)<)[)N'}){@|)1)N'2)3)4)5)6)7)                                    7@8)9)0)K+a)q'2;b)c)        ",
"            d)T=B@e)f)g)h)i)j)k)l)m)n)(#o)  p)q)r)_*s)t)u)v)w)x)y)z)A)B)C)C)C)C)v,D)a,E)F)G)H)I)J)K)K)K)K)L)M)N)O)P)Q)R)S)T)U)V)W)X)Y)Z)\`) !.!+!                                  @!C-#!\$!N;%!|;&!*!=!2;        ",
"              T=B@-!;!f)>!,!'!'!)!!!l\$~!{!o)]!r)^!/!(!_!u)u):!<![!}!|!1!2!3!B)4!5!6!7!8!9!0!a!a!b!c!c!c!c!d!d!e!f!g!Q)R)S)#;h!V)i!V)j!C),'k!l!m!                                  n!o!p!O'q!z%q!r!.#s!t!        ",
"              u!v!='@.w!x!g)'!'!'!'!y! #z!A!B!]&C!D!D!u)u)u)+\$E!F!G!G!H!I!J!4!K!L!M!N!O!P!Q!a!R!S!T!T!T!U!V!W!X!Y!:)Q)R)S)#;Z!\`! ~.~+~C),'@~#~q.                                \$~%~ \$ \$++i&&~*~{!=!=~-~        ",
"      ;~>~      ,~'~)~&!!~~~{~{~{~{~]~^~/~o)(~_~:~X%<~[~[~[~}~|~:>1~2~3~4~5~&>6~7~O!8~9~0~a~b~c~d~e~f~g~h~i~j~k~l~m~<>n~o~p~q~r~s~t~u~@@\$>v~w~                                x~y~z~A~B~C~D~E~F~m.G~H~I~        ",
"      J~R.K~L~  M~N~Y!O~P~,%Q~Q~Q~Q~R~S~T~U~V~W~2>X~Y~'#'#'#Z~j\$\`~ {h;.{+{+>@{#{9~O!\${%{&{*{={-{;{>{,{ ; ;'{'{){!{~{{{b#[;]{^{p\$L\$/{q!({_{:{<{                            [{}{|{1{2{2!J+3{4{5{6{7{3#8{          ",
"    9{0{a{b{c{0 d{e{C>f{g{\`-h{Q~Q~i{j{j{j{k{l{m{n{o{p{q{r{'#'#s{t{ {u{1,v{w{x{y{z{A{A{A{B{C{D{E{F{G{H{ ; ;I{J{K{L{X*o@h;M{X%N{p\$/{/{q!({_{O{P{                        Q{R{S{T{U{I\$[;V{J+W{X{3{Y{Z{3#X.          ",
"      \`{ ].]+]@]d{e{#]P@O~g{D>Q~Q~\$]%]j{j{j{&]*]=]-];]>],]*,'])]!] {w,a#v{~]y{y{{]]]]]]]^]/](]_]:]<]G{ ; ;J{J{K{[]1)}]}]o@ #p\$p\$/{/{q!({_{O{P{                      |]1]S{S{2]3]W>4]J+J+5]6]y@D&7]3#            ",
"      ),8]9]0]a]b]e{#]#]P@c]d]e]f]Q~g]j{j{j{&]*]*]m{h]i]j]k]l]m]n]o]p].+l>q]r]y{N!z{s]t]u]/](]_]:]v]w] ; ;J{J{x]y]1)}]z]A]B]p\$p\$L\$/{C]D]O{O{E]q.                |]~)F]G]S{H]I]J][;:'J+J+K]L]r\$Z)M]              ",
"        N]O]:#F>P]Q]\`@R,];R]S]T]U]V]W]W]X]O'Y]o~Z]o~G'\`] ^.^+^@^#^N~\$^v!%^u!&^*^=^-^;^>^,^'^)^!^~^{^]^h#^^/^(^_^:^<^o c][^}^|^1^p\$2^3^4^4^5^6^{@|,0*        '=Z,P!7^8^9^0^a^b^c^[;d^7+b)e^!'f^f^g^              ",
"        h^++i^q'j^k^.#~{D' -l^l^m^n^[;o^z]H p^q^r^s^A)t^u^v^w^x^y^z^A^B^#*#*C^8=D^E^F^G^H^I^I^J^K^L^M^N^)+O^P^Q^++R^S^V>T^t]U^V^p\$p\$W^X^,)Y^Z^:!\`^ /-!J-t*././+/@/@/@/#/\$/%/&/*/F'=~t=A]=/-/5&4;                ",
"        ;/>/i^++};,/'/)/!/~/{/]/{/m^4~-,z,^/Q,8=//(/_/:/:/</[/}/|/1/2/3/4/j+5/#*6/7/8/9/d.0/0/a/b/c/d/9 )+e/e/f/++c]m@g/h/i/j/V^p\$p\$k/l%l/n~m/:!n/k;o/O@p/q/r/A s/t/u/v/%/w/x/s,-\$A]{{-,y/z/A/                  ",
"          B/C/\`=++\`=D/E/)/N{Y!Y!Y!F/G/y,5%J-H/B@B@u!I/J/J/J/K/L/&\$M/N/O/P/Q/R/S/T/U/9/V/W/X/Y/_^x=)+)+)+)+Z/\`/ (.(+(@(@(#(\$(%(V^p\$p\$;#l/&(*(=(:!n/-(;(>(@\$,('()(h^h^!(~({(](F,4;b#0)}]h;^(C&                    ",
"          7+/(\`=++9*R,((_(:(<(<(<(<([(o@^{((i;9'9'9'9'}(|(|(1(E&<(2(3(4(5(6(7(8(9(0(a(b(c(d(e(f(g(3\$^^^^^^h(i(s; ;j(k(l(m(Z V^n(o(o(p(q(r(s(t(n@u(b*v(w(x(y(9,z(A(A(B(C(D(E(F(G(}]F'h;h;H(@*                    ",
"            ++++++I(J(K(L(r~!@)+)+)+|,[(M(N(m+O(O(1@W>R'P(P(Q(R()+S(T(U(V(W(X(Y(Z(\`( _._+_@_#_\$_%_t*&_*_9 =_-_;_J{J{#{>_,_'_)_!_~_{_]_^_/_(_t(__:_<_[_@(}_7+y/|_1_2_3_4_5_6_7_8_h;[;_'_'9_                      ",
"              ++++I(0_a_m]b_c_d_d_d_e_R'N(N(f_g_O(d)h_i_R'P(P(@\$)+)+j_C k_l_m_n_o_p_p_q_r_@_s_#_t_b/b/&_N{w#u_v_w_x_y_z_A_B_!_C_D_E_F_G_H_I_J_y,K_L_M_N_O_P_Q_R_S_T_U_V_W_X_Y_Z_[;\`_t{ :.:+:@:                  ",
"              9*++I(t{,##:t{\$:l+l+3^T=//N(N(%:&:/(1@*:i_%^&!q!=:-:^-;:>:,::#':):!:~:~:~:{:]:^:/:(:_:_:::N{K_#{#{<:[:}:|:1:2:E_3:n)4:z%I_I_I_J_r\$R#P#M_N_5:6:7:8:9:0:a:b:c:d:X_e:f:s{g:h:i:j:k:                  ",
"                l:m:J(n:o:p:q:r:r:s:M(p^t:M(u:%:%:v:P@w:w:x:.+d>y:s]z:A:B:C:9(D:))E:F:F:G:H:N^I:J:K:~*;:;:'_L:M:N:u*)=O:P:&_B:Q:R:S:T:R^U:V:W:}]X:Y:Z:m\$\`: <.<+<@<#<#<\$<%<%<&<*<=<-<;<_+><,<'<                  ",
"                )<!<~< \$ \${<2,:>]<^<#@N+N+N+/<(<h@P(7@_<:<<<N@[<>_}<|<2:1<2<3<)+J:4<#{J{5<6<R:t_u*7<,_,_,_f-p\$8<f-e.9<0<a<t_ ; ;b<c<D~d<e<f<g<h;h<)+)+_(i< ;[:,~T)j<#;k<G!>'l<m<|;|;%!n<o<p<                    ",
"                  q<I#K>Z]r<s<j<t<t<u<o@N+M~n,v<&!q!|;j_w<x<y<z<,_A<B<u*C<D<)+E<J:4<G:#{k_R:F<u*2:&_(~G<,_,_,_G<8<H<))I<J<K<.;L<M<N<O<P<Q<r<R<[;9')+)+_(S<T<U<V<W<X<T)k<[!Y<Z<\`<q! [e].[+[                      ",
"                  @[#[\$[%[&[t<t<t<t<*[=[-[N+g-;[R'-!|;j_w<w<w<e/,_,_,_>[)+)+,['[J:4<4<4<)[![u*![~[{[][^[,_,_,_/[8<H<p\$a<I<([_[d{N<I_:[P<P<#;i-s^<[)+)+_(_(b* ;[[}[K!T)k<<!Q@|[1[2[3[4[5[                        ",
"                  6[7[#> \$8[j<t<t<9[n:n:0[d^g-;[R'-!|;a[a[a[a[[<,_,_,_B_'['['['[8<8<8<8<u*u*T>][~[{[][u*u*e/f-8<8<H<p\$p\$p\$C<B^d{H_I_S)#;#;#;i-N,k+)+b[c[c[d[ ;e[f[g[T)k<<!o]h[E'i[j[n<                          ",
"                  k[:'i-R<R<l[j<p~2,m[n[=(x@o[V*p[q[r[S/S/)+)+s[>[>[.<'_t[e.t[e.)_)_u[v[}^4=u*![w[X ))f(f(,_e/x[L<&_y[y[y[c{z[A[K!B[C[#;#;%[D[E[F[s!G[q(H[N{Q:I[J[K[R<e:G(L[@,M[N[C&                            ",
"                O;O[P[Q[h;[;C[R[#;#;m[r\$++^/S[T[U[,_e/V[V[V[V[W[-:)+g/D<t[p\$p\$p\$X[X[Y[Z[\`[K: }.}A:e.'['['[e/1:[:|:L<+}+}@}#}X[X[\$}%}&}r<r<P<R<!]s(A]*}D~=}-}6<;}>},}h;O,'}O')}!}g^                              ",
"                ~}{}]}(/_/_/#,{@:[^}/}-,i^*}<;(}K@_}:}!.<}<}z![}\$_U>;:}}B_t[p\$p\$X[X[|}1}T>:(2}~*A:e.'['['[3}B<4}5}6}7}B_8}9}X[X[0}a}9*Q<S)P<R<!]];};&~b}=}{}c}d}e}f}h;g}h}i}]{j}k}    N&l}m}                    ",
"                z%n}T=u!u!7@++++o}@,p}{@q}\`=j\$r}s}t}u}_#n)<}Y 9 v}-:<<w}x}B_'_t[X[X[X[X[3<:(~**_A:p\$e.N:x}P^y}z}A}[:7}B}C}D}E}E}o&F}x@f<:[P<G}2@];=~C~=}=}=}H}I}J}Q=h;[;[;K}})U%L}i&H-|;M}N}                    ",
"                O}P}Q}Q}Q}R}z,r(S}S}d^p}T}U}6#V}W}X}Y}Z}Z}\`}![ |-(.|+|_^@|[_#|E<\$|%|%|%|S<S<.}+}A:p\$p\$C<&| |\`}\`}\`}*_v{_[*|O~O~O~N~=|,;-|;|r<n:>|s-,|'|z@)|P(P(1,a*!|~|{|]|^|/}/|(|_|:|<|[|                      ",
"                  }|g@'*||1|[>2|3|o b#4|>)5|6|7|i@8|k@ ; ; ;t*9|0|a|[]\`^b|c|d|e|f|g|h|h|[_i|j|k|l|p\$p\$m|n|o|L\$L\$L\$j_@\$p|C-H/k>k>|,|,q|r|s|t|s'0_u|v|6@w|x|~@{*B@-[y|z|A|<!B|C|D|E|F|G|2+H|                      ",
"                    '*||1+I|J|K|L|U:r\$r\$M|N|6|L#O|P|Q|L<L<L<v{R|R|S|+-T=T|i@U|w:V|W|d|d|)+E<H^X|Y|o(o(n|Y!0#x=0#=:O@p|y+v=m+>;Z|\`|\`| 1.1.1.1u<0_u|h[+{d^o@1@)+7@+1@1#1\$1%1S]0 &1*1=1G|-1                        ",
"                      g@;1>1,1o '1L|-,)14|!1~1#*#*L#Y%{1{1{1x(]1^1^1/1(1_1_17|#*-#W|W|W|@\$)+o/B_'[D::1<1=_B@T=T=O@='[1D~++W>>;n@r\$r\$r|#;#;#;}1|1s{#]Q@r\$d^m+)+1121#131415161N~7181x!9191                        ",
"                            01a1b1c19*{@O.{@t:N(N(N(J@d1d1d1e1v!f1g1h1//<\$<\$i1j1k1M#M#M#P|O@E<o/v}l1t_m1v}n1}~o1p1D&q1r1s1I+e_t1)1u1v1w1v1x1y1z1A1j-z]2@o!B1C13@D1E1F1G1H1/}I1J1K1L1                            ",
"                              M1M1M1N1I_I_I_^_J-J-J-J-B@B@B@B@!;++++++++++++++++O1Y!Y!Y!P1='j+)+Q1R1S1T1A_,_,_U[s}U1V1='W1!+X1<;-'Y1Z1\`1;' 2^}.2#,++z]d^{{q!q'+2G!;|9*@2#2\$2%2T,&2*2                            ",
"                              M1M1=2-2;201>2,2L[L[L[L[F1F1R'x|9*'2)2!2~2{2{2{2{2]2D/^2Y!='/2P|)+ |(2O^_2(2:2<2[2}2|212g|g|a[R(0#-'Y1223242 2!}&}o}{@-\$o@q's(h;52G!6272I1\$282829202a2b2                          ",
"                              M1M1=2c2d2d2e2B|72727272G}G}G}G}f2f2g2h2i2j2j2j2j2]2D/^2Y!C>y+C1)+d.V>k2l2V>m2s}s}N D/n2o2o2!@d_p2-'Y1y!q2r2x1%[P<s2f<O'X>];2@h;52G!<!t2#;\$2u2v292&2D+                            ",
"                                M1=2w2x2x2y2z2D,D,D,D,A2A2A2A2B2C2h2D2E2F2G2j2H2l:D/*'I2D~v=J2A@d.P1c[K2c[L2:2M2N N2O2P2Q2R2S2T2\$[Y1y!q2U2x1#;#;:[R[9)_'x,[;h;52G!V2p,W2X2Y2v2Z2\`2                              ",
"                                 3.3+3@3#3\$3X_6_6_6_6_%3%3%3%3&3*3=3-3;3>3,3'3)3.,z,z,z,@,A%P@X:!3O~*'~3~3p@{3]3^3J|z,r1R2[)h}h}/3(3_3:3<3k<6_[3}3-2|30213P{2333434343536373839303                              ",
"                                  a3b3c3d3e3f3G!G!G!G!g3g3g3h3i3j3k3l3m3&<1~7_h;!}n3C;+,o3p3o!=\$f{@!n,q3'#G-r3%!s3\`=t3*<!,u3K}K}K}K}s,p;v3w3x3+1y3z3A3B3;1C3'!D3E3E3F3G3H3I3J3K3                                ",
"                                    L3M3N3O3P3Q3f]R3G!S3S3S3T3U3V3W3X3Y3Z31~7_h;o~.2k[e<\`3 4.4+4@4w|c]#4'#P<\$4Q;%4.,&4\`>\`>x,*4=4E!-4;4x)p,>4,4'4)4!4~4{4]4^4'!/4(4_4:4<4[4I3}4                                  ",
"                                            |4142434445454546474l3X3X384%<1~947_#>#>S)!}o:Y1!!T}U}_>h[#4'#D,#;Z]I1r,04a4b4'3c4W]Z3j)d4G!G!>4e4f4p,g4h4i4m!j4k4l4m4n4o4p4q4                                      ",
"                                                  r4s4t4u4v4w4l3x4x4y4z4A4Y_x1B4C4D4D,j<E4F4o3G4!!T}j-s-H4W]I4I4I4w1J4 2K4L4M4M4N4N4O4P4!4Q4R4S4T4Z3U4V4V4W4W4X4Y4Z4                                            ",
"                                                      \`4 5.5+5@5#5@5\$5%5&5&<#;*5=5-5;5g4>5,5'5)5!572t3.,s2A)[;[;[;I1~5w3p,{5]5]5^5Y2/5(5(5(5_5:5<5\$<[5}5|51525                                                  ",
"                                                        3545+5y4\$5556575&5&<*56_85M4G!G!G!L49505v1#;#;I1#;]{x,-\$-,8,a582b5c5d5d5e5f5g5(5(5(5h5i5j5k5[5|5l5                                                      ",
"                                                          m5n555o5p5q575&5k<r56_M4M4M4M4p,L4s505v1#;#;#;#;X>2@9*9*6^a56_75t5u5u5v5w5x5y5(5y5z5j5j5k5[5A5                                                        ",
"                                                          Y~B5Q~C5D5E5F5G!b5b5L4G5A4A4H5I5J5K5L5J4#;#;#;#;i-3,M5t<*5N5O5P5Q5R5u5u5S5T5U5V5T5W5X5Y5Z5\`5u4                                                        ",
"                                                             6.6+6Y2Y2@6V5M4g4G!#6#6#6\$6f3%6Q~Q~&6#;#;#;#;#;#;*6=6-6;6>6r%,6'6u5)6!6'!'!'!~6x4{6]6^6/6(6                                                        ",
"                                                            _6:6<6[6Y2@6V5M4G!G!U5#6}6|61626364656!4*5*5*5826676869606r%r%a6u5u5!6!6'!'!'!X3@5b6c6d6                                                            ",
"                                                              e6f6g6Y2@6V5M4g4G!h6#6}6|61626i6j6k6V2V2V2V266l6@5{6m6r%r%r%a6u5u5!6!6'!'!84X3@5n6o6p6                                                            ",
"                                                                q6r6s6@6G!G!G!G!G!G!#6#6T5q5i6j6k6V2V2t6t6l6u6{6{6m6r%r%r%a6u5u5v6Y25_~6w6X3x6y6z6A6                                                            ",
"                                                                B6C6D6E6G!G!G!G!G!G!x5F6q565l6G6H6/5z4I6I6J6K6K6K6L6M6M6M6N6O6P655Q6R6S6T6T6)!U6V6                                                              ",
"                                                                  W6W6X6G!G!G!G!Y6g5x5x5q5Z6o5o5\`6 7o5{6{6.7+7+7+7@7#7#7#7\$7%7&7S6'!T5o5o5p5*7=7-7                                                              ",
"                                                                    W6;7>7G!G!G!x5x5x5,7Z6\`6o5o5o5o5o5'7{6+7+7+7+7@7#7)7!7~7%7%7S6'!q5{7{7Z6l6=7]7^7                                                            ",
"                                                                      /7(7_7G!G!x5Y5x5Y5:7o5o5o5o5o5o5\$5{6+7+7+7+7@7#7#7)7~7&7<7o5[7q5q5Z6o5}7=7|7g^                                                            ",
"                                                                        172737m34757476777777777\$58787'7{697979707a7b7b7b7c7d7e77777f7R6g784U6h7i7j7                                                            ",
"                                                                          k7l7m7n7n7E3E3E3E3E3t6o7p7p7p7p7q7r7r7s7s7s7s7s7t7E3E3E3E3u7'!'!v7^4F,w7x7T2                                                          ",
"                                                                            y7z7:5A7%5t6t6t64333B7C7C7C7C7D7E7E7E7E7E7E7E7F7E3E3E3E3'!G7G7H7I7F,J7G\$K7          L7M7                                            ",
"                                                                            (6(6N7O7A7%543433375P7Q7Q7Q7Q7R7w6w6w6w6w6w6w6S7/4{765f763T7T7U7V7W7X7Y7Z7\`7       8.8+8@8                                          ",
"                                                                              #8\$8%8f3&8q5q5/5/5*8=8=8-8;8>8>8>8>8>8>8J'w4,8'8)8!834~8{8]8^8/8(8(8_8:8<8-'  [87>}8|8182838  485868                              ",
"                                                                                78\`5v7'!'!'!'!'!88989808a8b8c8c8c8c8d8e8f8C6g8g8g8g8h8i8i8i8j8'#'#'#k8l8m8n8o8p8q8q8r8s8t8u8v8w8x8y8                            ",
"                                                                                k7\`5z8A8'!'!'!B8C8i8i8i8i8f8D8E8E8f8f8f8                        /'F8G8H8I8J8K8L8M8N8O8P8Q8R8S8T8U8V8W8                          ",
"                                                                                \`5\`5z8A8'!'!'!X8Y8i8i8i8i8Z8\`8                                       9:/_8.9+9@9N8#9\$9%9&9*9=9-9;9>9,9                          ",
"                                                                                '9)9!9~9'!'!{9]9^9                                                    /9o8(9+9_9:9#9<9[9}9|93#192939                            ",
"                                                                                  4959*569798999                                                        09a9b9c9d9e9f9g9h|      h9i9                            ",
"                                                                                  j9k9l9m9n9o9                                                            p9q9r9s9t9u9v9        w9x9                            ",
"                                                                                  y9z9A9m9B9                                                              C9D9E9F9G9H9I9        J9                              ",
"                                                                                K9y9L9M9N9                                                                  O9P9Q9R9                                            ",
"                                                                                S9T9U9V9                                                                    W9X9Y9Z9                                            ",
"                                                                                \`9 0.0+0                                                                    @0#0%[                                              ",
"                                                                                \$0%0&0                                                                      *0=0-0                                              ",
"                                                                                ;0>0>0                                                                      ,0'0)0m8                                            ",
"                                                                              !0~0{0                                                                        ]0^0/0(0_0                                          ",
"                                                                            :0<0[0}0                                                                          |010202030                                        ",
"                                                                        405060<070}0                                                                                                                            ",
"                                                                      809000<0a0b0}0                                                                                                                            ",
"                                                                  c0d0e0s>f0g0h0i0j0                                                                                                                            ",
"                                                                k0l0m0n0o0p0q0r0s0t0                                                                                                                            ",
"                                                              u0v0w0x0y0z0A0B0C0D0E0F0                                                                                                                          ",
"                                                            G0H0I0J0K0L0M0N0O0P0Q0R0S0                                                                                                                          ",
"                                                          T0G0U0V0W0X0Y0Z0N0N0N0z9\`0 a                                                                                                                          ",
"                                                        .a+a@a#a\$a    %a&a*a    =a-a;a                                                                                                                          ",
"                                                        >an%,a'a)a     5 5+     !a~a                                                                                                                            ",
"                                                          {a]a^a/a                                                                                                                                              ",
"                                                          (a_a:a<a                                                                                                                                              ",
"                                                              [a}a|a1a                                                                                                                                          ",
"                                                                                                                                                                                                                "};
_EOF_
}
