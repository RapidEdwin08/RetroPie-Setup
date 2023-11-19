#!/usr/bin/env bash

# Choose a [signal_quality_method]:
#   dBm_no_conversion
#   dBm_to_percent_A   # Simple Linear Conversion by David Manpearl
#   dBm_to_percent_B   # Double Logarithm of Signal Power Conversion by Artfaith

signal_quality_method=dBm_to_percent_B
wifi_interface=wlan0
wait_for_wlan=5

# =================================================
# 2023.06 Updated Version of [wifi.sh] with Support for NetworkManager
# https://github.com/RapidEdwin08/wifi-networkmanager

# BASE FILE:
# [wifi.sh] from RetroPie v4.8.4 (OSK moved to scriptmodules/helpers.sh)
# https://github.com/RetroPie/RetroPie-Setup/commit/e1935ab5da917cb81a192002e627646a3438c2b4

# CHANGES:
# Updated Connecting to WiFi to use [nmcli] in addition to updating [wpa_supplicant.conf]
# Updated Remove WiFi Config to Remove [/etc/NetworkManager/system-connections/*.nmconnection] in addition to [wpa_supplicant.conf]
# Updated method of obtaining [ip_wlan] Variable
# Updated Available ESSIDs Menu List to Include [$quality] $essid [$frequency]
# Added Re-Scan for Wireless networks 0ption to Available ESSIDs Menu List
# Added sleep [wait_for_wlan] Variable to [_set_interface_wifi] UP/DOWN due to Device Busy Issue on some Devices
# Added [wifi_interface] Variable for 0ther WiFi Devices
# x3 Options for [signal_quality_method]: [dBm_to_percent_A] [dBm_to_percent_B] [dBm_no_conversion]

# SOURCES:
# ./RetroPie-Setup/scriptmodules/supplementary/wifi.sh
# https://github.com/RetroPie/RetroPie-Setup/blob/master/scriptmodules/supplementary/wifi.sh

# how-to-convert-wifi-signal-strength-from-quality-percent-to-rssi-dbm
# https://stackoverflow.com/questions/15797920/how-to-convert-wifi-signal-strength-from-quality-percent-to-rssi-dbm
# =================================================

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

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

function _set_interface_wifi() {
    local state="$1"

    if [[ "$state" == "up" ]]; then
		if [[ "$(cat /sys/class/net/$wifi_interface/operstate)" == "down" ]]; then
            echo "Setting Interface $wifi_interface $1      "
			ip link set $wifi_interface up
			sleep $wait_for_wlan # Device Busy
        fi
    elif [[ "$state" == "down" ]]; then
		if [[ "$(cat /sys/class/net/$wifi_interface/operstate)" == "up" ]]; then
            echo "Setting Interface $wifi_interface $1      "
			ip link set $wifi_interface down
			sleep $wait_for_wlan # Device Busy
        fi
    fi
}

function remove_wifi() {
    echo "Removing Current $wifi_interface Config   "
    sed -i '/RETROPIE CONFIG START/,/RETROPIE CONFIG END/d' "/etc/wpa_supplicant/wpa_supplicant.conf"
    if [[ -d /etc/NetworkManager ]]; then rm /etc/NetworkManager/system-connections/*.nmconnection 2>/dev/null; fi # NetworkManager Config
    _set_interface_wifi down 2>/dev/null
}

function list_wifi() {
    local line
    local essid
    local type
    while read line; do
        [[ "$line" =~ ^Cell && -n "$essid" ]] && echo -e "$quality $essid $frequency\n$type"
        [[ "$line" =~ ^ESSID ]] && essid=$(echo "$line" | cut -d\" -f2) && if [[ "$essid" == '' ]]; then essid="*"; fi
        [[ "$line" == "Encryption key:off" ]] && type="open"
        [[ "$line" == "Encryption key:on" ]] && type="wep"
        [[ "$line" =~ ^IE:.*WPA ]] && type="wpa"
        [[ "$line" =~ ^Frequency ]] && frequency=[$(echo "$line" | awk '{print $1}' | tr -d 'Frequency:' | awk '{ print substr($0, 0, 4) }')GHz]
        [[ "$line" =~ ^Quality ]] && qualitydBm=$(echo "$line" | awk '{print $3}' | tr -d 'level=')
		quality="$($signal_quality_method "$qualitydBm")"
    done < <(iwlist $wifi_interface scan | grep -o "Cell .*\|ESSID:\".*\"\|IE: .*WPA\|Encryption key:.*\|Quality.*\|Frequency.*")
    echo -e "$quality $essid $frequency\n$type"
}

function connect_wifi() {
    if [[ ! -d "/sys/class/net/$wifi_interface/" ]]; then
        printMsgs "dialog" "No $wifi_interface interface detected"
        return 1
    fi
    local essids=()
    local essid
    local types=()
    local type
    local options=()
    i=0
    
    if [[ "$1" == "" ]]; then _set_interface_wifi up 2>/dev/null; fi # Skip [set_interface_wifi up] on Re-Scan
    dialog --infobox "\nScanning for WiFi networks..." 5 40 > /dev/tty
    sleep 1

    while read essid; read type; do
        essids+=("$essid")
        types+=("$type")
        options+=("$i" "$essid")
        ((i++))
    done < <(list_wifi)
    options+=("H" "Hidden ESSID")
    options+=("R" "Re-Scan for WiFi networks")

    local cmd=(dialog --backtitle "$__backtitle" --menu "Please choose the network you would like to connect to" 22 76 16)
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    if [[ "$choice" == "R" ]]; then
    	connect_wifi Re-Scan
    	return
    fi
    [[ -z "$choice" ]] && return

    local hidden=0
    if [[ "$choice" == "H" ]] || [[ "$(echo "${essids[choice]}" | awk '{print $2}')" == '*' ]]; then # ESSID * Hidden
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
        essid="$(echo "$essid" | awk '{print $2}')" # Pull 0nly ESSID field from: [$quality] $essid [$frequency]
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

    create_config_wifi "$type" "$essid" "$key"

    gui_connect_wifi
}

function create_config_wifi() {
    local type="$1"
    local essid="$2"
    local key="$3"

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

    remove_wifi 
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
    _set_interface_wifi down 2>/dev/null
    _set_interface_wifi up 2>/dev/null
    # BEGIN workaround for dhcpcd trigger failure on Raspbian stretch
    systemctl restart dhcpcd &>/dev/null
    # END workaround
    dialog --backtitle "$__backtitle" --infobox "\nConnecting to $essid ..." 5 40 >/dev/tty
    if [[ -d /etc/NetworkManager ]]; then printf "%s\n" "$key" | sudo nmcli --ask dev wifi connect "$essid" 2>/dev/null; fi # NetworkManager Config
    
    local id=""
    i=0
    while [[ -z "$id" && $i -lt 30 ]]; do
        sleep 1
        id=$(iwgetid -r)
        ((i++))
    done
    if [[ -z "$id" ]]; then
        printMsgs "dialog" "Unable to connect to network $essid"
        _set_interface_wifi down 2>/dev/null
    fi
}

function _check_country_wifi() {
    [[ ! -f /etc/wpa_supplicant/wpa_supplicant.conf ]] && return
    iniConfig "=" "" /etc/wpa_supplicant/wpa_supplicant.conf
    iniGet "country"
    if [[ -z "$ini_value" ]]; then
        if dialog --defaultno --yesno "You don't currently have your WiFi country set in /etc/wpa_supplicant/wpa_supplicant.conf\n\nOn a Raspberry Pi 3B+/4B/400 your WiFI will be disabled until the country is set. You can do this via raspi-config which is available from the RetroPie menu in Emulation Station. Once in raspi-config you can set your country via menu 5 (Localisation Options)\n\nDo you want me to launch raspi-config for you now ?" 22 76 2>&1 >/dev/tty; then
            raspi-config
        fi
    fi
}

function gui_wifi() {

    isPlatform "rpi" && _check_country_wifi

    local default
    while true; do
        local ip_current="$(getIPAddress)"
        local ip_wlan="$(ip addr show $wifi_interface | grep inet | awk '{print $2}' | head -n 1 | sed 's+/.*++')"
        if [[ "$(cat /sys/class/net/$wifi_interface/operstate)" == "down" ]]; then local ip_wlan=""; fi
		local cmd=(dialog --backtitle "$__backtitle" --cancel-label "Exit" --item-help --help-button --default-item "$default" --menu "Configure WiFi: $wifi_interface\nCurrent IP: ${ip_current:-(unknown)}\nWireless IP: ${ip_wlan:-(unknown)}\nWireless ESSID: $(iwgetid -r)" 22 76 16)
        local options=(
            1 "Connect to WiFi network"
            "1 Connect to your WiFi network"
            2 "Disconnect/Remove WiFi config"
            "2 Disconnect and remove any WiFi configuration"
            3 "Import WiFi credentials from /boot/wifikeyfile.txt"
            "3 Will import the SSID (network name) and PSK (password) from a file at /boot/wifikeyfile.txt

The file should contain two lines as follows\n\nssid = \"YOUR WIFI SSID\"\npsk = \"YOUR PASSWORD\""
            4 "Enable WiFi Interface"
            "4 Enable WiFi Interface $wifi_interface for this Session"
            5 "Disable WiFi Interface"
            "5 Disable WiFi Interface $wifi_interface for this Session"
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
                    connect_wifi
                    ;;
                2)
                    dialog --defaultno --yesno "This will remove the WiFi configuration and stop the WiFi.\n\nAre you sure you want to continue ?" 12 35 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    remove_wifi
                    ;;
                3)
                    if [[ -f "/boot/wifikeyfile.txt" ]]; then
                        iniConfig " = " "\"" "/boot/wifikeyfile.txt"
                        iniGet "ssid"
                        local ssid="$ini_value"
                        iniGet "psk"
                        local psk="$ini_value"
                        create_config_wifi "wpa" "$ssid" "$psk"
                        gui_connect_wifi
                    else
                        printMsgs "dialog" "No /boot/wifikeyfile.txt found"
                    fi
                    ;;
                4)
                    dialog --defaultno --yesno "This will Enable the WiFi Interface $wifi_interface for this Session.\n\nAre you sure you want to continue ?" 12 35 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _set_interface_wifi up 2>/dev/null
                    ;;
                5)
                    dialog --defaultno --yesno "This will Disable the WiFi Interface $wifi_interface for this Session.\n\nAre you sure you want to continue ?" 12 35 2>&1 >/dev/tty
                    [[ $? -ne 0 ]] && continue
                    _set_interface_wifi down 2>/dev/null
                    ;;
            esac
        else
            break
        fi
    done
}
