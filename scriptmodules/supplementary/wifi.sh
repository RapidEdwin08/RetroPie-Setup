#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# Choose a [signal_quality_method] for [list_wifi] quality:
#   dBm_no_conversion
#   dBm_to_percent_A   # Simple Linear Conversion by David Manpearl
#   dBm_to_percent_B   # Double Logarithm of Signal Power Conversion by Artfaith

rp_module_id="wifi"
rp_module_desc="Configure WiFi"
rp_module_section="config"
rp_module_flags="!x11"

function dBm_no_conversion {
# Retain a (SINGLE_FIELD) here due to [awk '{print $2}'] used below for [$essid] Detection
#echo "($1)"
echo "($1_dBm)"
#echo "($1dBm)"
#echo "(dBm$1)"
}

# https://stackoverflow.com/questions/15797920/how-to-convert-wifi-signal-strength-from-quality-percent-to-rssi-dbm
function dBm_to_percent_A { # Convert dBm to percentage ( quality = 2 * (dBm + 100)  where dBm: [-100 to -50] ); Apr 3, 2013 at 20:59 David Manpearl
if [[ "$1" -lt '-100' ]]; then dBm_as_percent=0
elif [[ "$1" -gt '-50' ]]; then dBm_as_percent=100
else dBm_as_percent=$(( 2 * $(( $1 + 100 )) ))
fi

# Retain a (SINGLE_FIELD) here due to [awk '{print $2}'] used below for [$essid] Detection
echo "[%$dBm_as_percent]"
}

# https://stackoverflow.com/questions/15797920/how-to-convert-wifi-signal-strength-from-quality-percent-to-rssi-dbm
function dBm_to_percent_B { # Convert dBm to percentage (based on https://www.adriangranados.com/blog/dbm-to-percent-conversion); Oct 12, 2018 at 12:08 Artfaith
  dbmtoperc_d=$(echo "$1" | tr -d -)
  dbmtoperc_r=0
  if [[ "$dbmtoperc_d" =~ [0-9]+$ ]]; then
    if ((1<=$dbmtoperc_d && $dbmtoperc_d<=20)); then dbmtoperc_r=100
    elif ((21<=$dbmtoperc_d && $dbmtoperc_d<=23)); then dbmtoperc_r=99
    elif ((24<=$dbmtoperc_d && $dbmtoperc_d<=26)); then dbmtoperc_r=98
    elif ((27<=$dbmtoperc_d && $dbmtoperc_d<=28)); then dbmtoperc_r=97
    elif ((29<=$dbmtoperc_d && $dbmtoperc_d<=30)); then dbmtoperc_r=96
    elif ((31<=$dbmtoperc_d && $dbmtoperc_d<=32)); then dbmtoperc_r=95
    elif ((33==$dbmtoperc_d)); then dbmtoperc_r=94
    elif ((34<=$dbmtoperc_d && $dbmtoperc_d<=35)); then dbmtoperc_r=93
    elif ((36<=$dbmtoperc_d && $dbmtoperc_d<=38)); then dbmtoperc_r=$((92-($dbmtoperc_d-36)))
    elif ((39<=$dbmtoperc_d && $dbmtoperc_d<=51)); then dbmtoperc_r=$((90-($dbmtoperc_d-39)))
    elif ((52<=$dbmtoperc_d && $dbmtoperc_d<=55)); then dbmtoperc_r=$((76-($dbmtoperc_d-52)))
    elif ((56<=$dbmtoperc_d && $dbmtoperc_d<=58)); then dbmtoperc_r=$((71-($dbmtoperc_d-56)))
    elif ((59<=$dbmtoperc_d && $dbmtoperc_d<=60)); then dbmtoperc_r=$((67-($dbmtoperc_d-59)))
    elif ((61<=$dbmtoperc_d && $dbmtoperc_d<=62)); then dbmtoperc_r=$((64-($dbmtoperc_d-61)))
    elif ((63<=$dbmtoperc_d && $dbmtoperc_d<=64)); then dbmtoperc_r=$((61-($dbmtoperc_d-63)))
    elif ((65==$dbmtoperc_d)); then dbmtoperc_r=58
    elif ((66<=$dbmtoperc_d && $dbmtoperc_d<=67)); then dbmtoperc_r=$((56-($dbmtoperc_d-66)))
    elif ((68==$dbmtoperc_d)); then dbmtoperc_r=53
    elif ((69==$dbmtoperc_d)); then dbmtoperc_r=51
    elif ((70<=$dbmtoperc_d && $dbmtoperc_d<=85)); then dbmtoperc_r=$((50-($dbmtoperc_d-70)*2))
    elif ((86<=$dbmtoperc_d && $dbmtoperc_d<=88)); then dbmtoperc_r=$((17-($dbmtoperc_d-86)*2))
    elif ((89<=$dbmtoperc_d && $dbmtoperc_d<=91)); then dbmtoperc_r=$((10-($dbmtoperc_d-89)*2))
    elif ((92==$dbmtoperc_d)); then dbmtoperc_r=3
    elif ((93<=$dbmtoperc_d)); then dbmtoperc_r=1; fi
  fi
  # Retain a (SINGLE_FIELD) here due to [awk '{print $2}'] used below for [$essid] Detection
  echo "[%$dbmtoperc_r]"
}

function _get_interface_wifi() {
    local iface
    # look for the first wireless interface present
    for iface in /sys/class/net/*; do
        if [[ -d "$iface/wireless" ]]; then
            echo "$(basename $iface)"
            return 0
        fi
    done
    return 1
}

function _get_mgmt_tool_wifi() {
    # get the WiFi connection manager
    if systemctl -q is-active NetworkManager.service; then
        echo "nm"
    else
        echo "wpasupplicant"
    fi
}
function _set_interface_wifi() {
    local iface="$1"
    local state="$2"

    if [[ "$state" == "up" ]]; then
        if ! ifup $iface; then
            echo "Setting Interface $iface $state      "
            ip link set $iface up
            sleep 5 # Device Busy
        fi
    elif [[ "$state" == "down" ]]; then
        if ! ifdown $iface; then
            echo "Setting Interface $iface $state      "
            ip link set $iface down
            sleep 5 # Device Busy
        fi
    fi
}

function remove_nm_wifi() {
    local iface="$1"
    # delete the NM connection named RetroPie-WiFi
    nmcli connection delete RetroPie-WiFi 2>&1 | grep -v 'unknown connection'
    _set_interface_wifi $iface down 2>/dev/null
}

function remove_wpasupplicant_wifi() {
    local iface="$1"
    sed -i '/RETROPIE CONFIG START/,/RETROPIE CONFIG END/d' "/etc/wpa_supplicant/wpa_supplicant.conf"
    _set_interface_wifi $iface down 2>/dev/null
}

function list_wifi() {
    local line
    local essid
    local type
    local iface="$1"

    while read line; do
        [[ "$line" =~ ^Cell && -n "$essid" ]] && echo -e "$quality $essid $frequency\n$type"
        [[ "$line" =~ ^ESSID ]] && essid=$(echo "$line" | cut -d\" -f2) && if [[ "$essid" == '' ]]; then essid="*"; fi
        [[ "$line" == "Encryption key:off" ]] && type="open"
        [[ "$line" == "Encryption key:on" ]] && type="wep"
        [[ "$line" =~ ^IE:.*WPA ]] && type="wpa"
        [[ "$line" =~ ^Frequency ]] && frequency=[$(echo "$line" | awk '{print $1}' | tr -d 'Frequency:' | awk '{ print substr($0, 0, 4) }')GHz]
        [[ "$line" =~ ^Quality ]] && qualitydBm=$(echo "$line" | awk '{print $3}' | tr -d 'level=')
        quality="$(dBm_to_percent_B "$qualitydBm")"
    done < <(iwlist $iface scan | grep -o "Cell .*\|ESSID:\".*\"\|IE: .*WPA\|Encryption key:.*\|Quality.*\|Frequency.*")
    echo -e "$quality $essid $frequency\n$type"
}

function connect_wifi() {
    local iface
    local mgmt_tool="wpasupplicant"

    iface="$(_get_interface_wifi)"
    if [[ -z "$iface" ]]; then
        printMsgs "dialog" "No wireless interfaces detected"
        return 1
    fi
    mgmt_tool="$(_get_mgmt_tool_wifi)"

    local essids=()
    local essid
    local types=()
    local type
    local options=()
    i=0
    _set_interface_wifi $iface up 2>/dev/null
    dialog --infobox "\nScanning for WiFi networks..." 5 40 > /dev/tty
    sleep 1

    while read essid; read type; do
        essids+=("$essid")
        types+=("$type")
        options+=("$i" "$essid")
        ((i++))
    done < <(list_wifi $iface)
    options+=("H" "Hidden ESSID")

    local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the WiFi network you would like to connect to" 22 76 16)
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -z "$choice" ]] && return

    local hidden=0
    if [[ "$choice" == "H" ]]; then
        essid=$(inputBox "ESSID" "" 4)
        [[ -z "$essid" ]] && return
        cmd=(dialog --backtitle "$__backtitle" --nocancel --menu "Please choose the WiFi type" 12 40 6)
        options=(
            wpa "WPA/WPA2"
            wep "WEP"
            open "Open"
        )
        type=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        hidden=1
    else
        essid=${essids[choice]}
        essid=$(echo $essid | awk '{ print $2; }')
        type=${types[choice]}
    fi

    if [[ "$type" == "wpa" || "$type" == "wep" ]]; then
        local key=""
        local key_min
        if [[ "$type" == "wpa" ]]; then
            key_min=8
        else
            key_min=5
        fi

        cmd=(inputBox "WiFi key/password" "" $key_min)
        local key_ok=0
        while [[ $key_ok -eq 0 ]]; do
            key=$("${cmd[@]}") || return
            key_ok=1
        done
    fi

    create_${mgmt_tool}_config_wifi "$type" "$essid" "$key" "$iface"
    gui_connect_wifi "$iface"
}

function create_nm_config_wifi() {
    local type="$1"
    local essid="$2"
    local key="$3"
    local dev="$4"
    local con="RetroPie-WiFi"

    remove_nm_wifi
    nmcli connection add type wifi ifname "$dev" ssid "$essid" con-name "$con" autoconnect yes
    # configure security for the connection
    case $type in
        wpa)
            nmcli connection modify "$con" \
                wifi-sec.key-mgmt wpa-psk  \
                wifi-sec.psk-flags 0       \
                wifi-sec.psk "$key"
            ;;
        wep)
            nmcli connection modify "$con" \
                wifi-sec.key-mgmt none     \
                wifi-sec.wep-key-flags 0   \
                wifi-sec.wep-key-type 2    \
                wifi-sec.wep-key0 "$key"
            ;;
        open)
            ;;
    esac

    [[ $hidden -eq 1 ]] && nmcli connection modify "$con" wifi.hidden yes
}

function create_wpasupplicant_config_wifi() {
    local type="$1"
    local essid="$2"
    local key="$3"
    local dev="$4"

    local wpa_config
    wpa_config+="\tssid=\"$essid\"\n"
    case $type in
        wpa)
            wpa_config+="\tpsk=\"$key\"\n"
            ;;
        wep)
            wpa_config+="\tkey_mgmt=NONE\n"
            wpa_config+="\twep_tx_keyidx=0\n"
            wpa_config+="\twep_key0=$key\n"
            ;;
        open)
            wpa_config+="\tkey_mgmt=NONE\n"
            ;;
    esac

    [[ $hidden -eq 1 ]] &&  wpa_config+="\tscan_ssid=1\n"

    remove_wpasupplicant_wifi
    wpa_config=$(echo -e "$wpa_config")
    cat >> "/etc/wpa_supplicant/wpa_supplicant.conf" <<_EOF_
# RETROPIE CONFIG START
network={
$wpa_config
}
# RETROPIE CONFIG END
_EOF_
}

function gui_connect_wifi() {
    local iface="$1"
    local mgmt_tool

    mgmt_tool="$(_get_mgmt_tool_wifi)"
    _set_interface_wifi $iface down 2>/dev/null
    _set_interface_wifi $iface up 2>/dev/null

    if [[ "$mgmt_tool" == "wpasupplicant" ]]; then
        # BEGIN workaround for dhcpcd trigger failure on Raspbian stretch
        systemctl restart dhcpcd &>/dev/null
        # END workaround
    fi
    if [[ "$mgmt_tool" == "nm" ]]; then
        nmcli -w 0 connection up RetroPie-WiFi
    fi

    dialog --backtitle "$__backtitle" --infobox "\nConnecting ..." 5 40 >/dev/tty
    local id=""
    i=0
    while [[ -z "$id" && $i -lt 30 ]]; do
        sleep 1
        id=$(iwgetid -r)
        ((i++))
    done
    if [[ -z "$id" ]]; then
        printMsgs "dialog" "Unable to connect to network $essid"
        _set_interface_wifi $iface down 2>/dev/null
    fi
}

function _check_country_wifi() {
    local country
    country="$(raspi-config nonint get_wifi_country)"
    if [[ -z "$country" ]]; then
        if dialog --defaultno --yesno "You don't currently have your WiFi country set.\n\nOn a Raspberry Pi 3B+ and later your WiFi will be disabled until the country is set. You can do this via raspi-config which is available from the RetroPie menu in Emulation Station. Once in raspi-config you can set your country via menu 5 (Localisation Options)\n\nDo you want me to launch raspi-config for you now ?" 22 76 2>&1 >/dev/tty; then
            raspi-config
        fi
    fi
}

function gui_wifi() {

    isPlatform "rpi" && _check_country_wifi

    local default
    local iface
    local mgmt_tool

    iface="$(_get_interface_wifi)"
    mgmt_tool="$(_get_mgmt_tool_wifi)"

    while true; do
        local ip_current="$(getIPAddress)"
        local ip_wlan="$(getIPAddress $iface)"
        local cmd=(dialog --backtitle "$__backtitle" --colors --cancel-label "Exit" --item-help --help-button --default-item "$default" --title "Configure WiFi" --menu "Current IP: \Zb${ip_current:-(unknown)}\ZB\nWireless IP: \Zb${ip_wlan:-(unknown)}\ZB\nWireless ESSID: \Zb$(iwgetid -r || echo "none")\ZB" 22 76 16)
        local options=(
            1 "Connect to WiFi network"
            "1 Connect to your WiFi network"
            2 "Disconnect/Remove WiFi config"
            "2 Disconnect and remove any WiFi configuration"
            3 "Import WiFi credentials from wifikeyfile.txt"
            "3 Will import the SSID (network name) and PSK (password) from the 'wifikeyfile.txt' file on the boot partition

The file should contain two lines as follows\n\nssid = \"YOUR WIFI SSID\"\npsk = \"YOUR PASSWORD\""
            4 "Enable WiFi Interface"
            "4 Enable WiFi Interface $iface for this Session"
            5 "Disable WiFi Interface"
            "5 Disable WiFi Interface $iface for this Session"
        )

        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ "${choice[@]:0:4}" == "HELP" ]]; then
            choice="${choice[@]:5}"
            default="${choice/%\ */}"
            choice="${choice#* }"
            printMsgs "dialog" "$choice"
            continue
        fi
        default="$choice"

        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    connect_wifi $iface
                    ;;
                2)
                    dialog --defaultno --yesno "This will remove the WiFi configuration and stop the WiFi.\n\nAre you sure you want to continue ?" 12 60 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    remove_${mgmt_tool}_wifi $iface
                    ;;
                3)
                    # check in `/boot/` (pre-bookworm) and `/boot/firmware` (bookworm and later) for the file
                    local file="/boot/wifikeyfile.txt"
                    [[ ! -f "$file" ]] && file="/boot/firmware/wifikeyfile.txt"

                    if [[ -f "$file" ]]; then
                        iniConfig " = " "\"" "$file"
                        iniGet "ssid"
                        local ssid="$ini_value"
                        iniGet "psk"
                        local psk="$ini_value"
                        create_${mgmt_tool}_config_wifi "wpa" "$ssid" "$psk" "$iface"
                        gui_connect_wifi "$iface"
                    else
                        printMsgs "dialog" "File 'wifikeyfile.txt' not found on the boot partition!"
                    fi
                    ;;
                4)
                    dialog --defaultno --yesno "This will Enable the WiFi Interface $iface for this Session.\n\nAre you sure you want to continue ?" 12 35 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _set_interface_wifi $iface up 2>/dev/null
                    ;;
                5)
                    dialog --defaultno --yesno "This will Disable the WiFi Interface $iface for this Session.\n\nAre you sure you want to continue ?" 12 35 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _set_interface_wifi $iface down 2>/dev/null
                    ;;
            esac
        else
            break
        fi
    done
}
