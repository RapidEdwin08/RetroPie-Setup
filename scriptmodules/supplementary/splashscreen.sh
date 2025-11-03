#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

# Config for mpv Image Viewing [/etc/mpv/mpv.conf] [~/.config/mpv/mpv.conf]:
mpvIMAGESreference=$(
echo '
# Infinite Duration If the current file is an Image
image-display-duration=inf

# Loop files in case of webms or gifs
#loop-file=inf

scale=spline36
cscale=spline36
dscale=mitchell
dither-depth=auto
correct-downscaling
sigmoid-upscaling
')

rp_module_id="splashscreen"
rp_module_desc="Configure Splashscreen"
rp_module_section="main"
rp_module_repo="git https://github.com/RetroPie/retropie-splashscreens.git master"
#rp_module_flags="noinstclean !all rpi !osmc !xbian !aarch64"
REGEX_VIDEO="\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"
rp_splash_boot=/opt/retropie/supplementary/splashscreen/asplashscreen.sh

function _update_hook_splashscreen() {
    # make sure splashscreen is always up to date if updating just RetroPie-Setup
    if rp_isInstalled "$md_id"; then
        install_bin_splashscreen
        configure_splashscreen
    fi
}

function _image_exts_splashscreen() {
    echo '\.bmp\|\.jpg\|\.jpeg\|\.gif\|\.png\|\.ppm\|\.tiff\|\.webp'
}

function _video_exts_splashscreen() {
    echo '\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac'
}

function depends_splashscreen() {
    getDepends fbi mpv vlc vorbis-tools; # fim insserv
    if [ ! -f /etc/mpv/mpv.conf ]; then echo "$mpvIMAGESreference" > /etc/mpv/mpv.conf; fi
    if [ ! -f ~/.config/mpv/mpv.conf ]; then mkdir ~/.config/mpv > /dev/null 2>&1; echo "$mpvIMAGESreference" > ~/.config/mpv/mpv.conf; fi
    if [ ! -f /home/pi/.config/mpv/mpv.conf ]; then mkdir /home/pi/.config/mpv > /dev/null 2>&1; echo "$mpvIMAGESreference" > /home/pi/.config/mpv/mpv.conf; fi
}

function install_bin_splashscreen() {
    cat > "/etc/systemd/system/asplashscreen.service" << _EOF_
[Unit]
Description=Show custom splashscreen
DefaultDependencies=no
After=console-setup.service
Wants=console-setup.service
ConditionPathExists=$md_inst/asplashscreen.sh

[Service]
Type=oneshot
ExecStart=$md_inst/asplashscreen.sh
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
_EOF_

    ##rp_installModule "omxiv" "_autoupdate_"

    gitPullOrClone "$md_inst"

    cp "$md_data/asplashscreen.sh" "$md_inst"

    iniConfig "=" '"' "$md_inst/asplashscreen.sh"
    iniSet "ROOTDIR" "$rootdir"
    iniSet "DATADIR" "$datadir"
    iniSet "REGEX_IMAGE" "$(_image_exts_splashscreen)"
    iniSet "REGEX_VIDEO" "$(_video_exts_splashscreen)"

    if [[ ! -f "$configdir/all/$md_id.cfg" ]]; then
        iniConfig "=" '"' "$configdir/all/$md_id.cfg"
        iniSet "RANDOMIZE" "disabled"
    fi
    chown $user:$user "$configdir/all/$md_id.cfg"

    mkUserDir "$datadir/splashscreens"
    echo "Place your own splashscreens in here." >"$datadir/splashscreens/README.txt"
    chown $user:$user "$datadir/splashscreens/README.txt"

    echo 'while pgrep vlc >/dev/null; do sleep 1; done #Splashscreen-wait' > /dev/shm/09-splashscreen-wait.sh
    echo 'while pgrep mpv >/dev/null; do sleep 1; done #Splashscreen-wait' >> /dev/shm/09-splashscreen-wait.sh
    echo 'while pgrep fbi >/dev/null; do sleep 1; done #Splashscreen-wait' >> /dev/shm/09-splashscreen-wait.sh
    if [ -f /usr/bin/omxplayer ]; then echo 'while pgrep omxplayer >/dev/null; do sleep 1; done #Splashscreen-wait' >> /dev/shm/09-splashscreen-wait.sh; fi
    chmod 755 /dev/shm/09-splashscreen-wait.sh
    sudo mv /dev/shm/09-splashscreen-wait.sh /etc/profile.d/09-splashscreen-wait.sh
    sudo chown root /etc/profile.d/09-splashscreen-wait.sh

    cp ~/RetroPie-Setup/scriptmodules/supplementary/splashscreen/asplashscreen.sh /dev/shm/asplashscreen.sh
    chmod 755 /dev/shm/asplashscreen.sh
    mv /dev/shm/asplashscreen.sh /opt/retropie/supplementary/splashscreen/asplashscreen.sh
    chown root /opt/retropie/supplementary/splashscreen/asplashscreen.sh
}

function enable_plymouth_splashscreen() {
    local config="/boot/cmdline.txt"
    if [[ -f "$config" ]]; then
        sed -i "s/ *plymouth.enable=0//" "$config"
    fi
}

function disable_plymouth_splashscreen() {
    local config="/boot/cmdline.txt"
    if [[ -f "$config" ]] && ! grep -q "plymouth.enable" "$config"; then
        sed -i '1 s/ *$/ plymouth.enable=0/' "$config"
    fi
}

function default_splashscreen() {
    echo "$md_inst/retropie-default.png" >/etc/splashscreen.list
}

function enable_splashscreen() {
    systemctl enable asplashscreen
}

function disable_splashscreen() {
    systemctl disable asplashscreen
}

function configure_splashscreen() {
    [[ "$md_mode" == "remove" ]] && return

    # remove legacy service
    [[ -f "/etc/init.d/asplashscreen" ]] && insserv -r asplashscreen && rm -f /etc/init.d/asplashscreen

    disable_plymouth_splashscreen
    enable_splashscreen
    [[ ! -f /etc/splashscreen.list ]] && default_splashscreen
}

function remove_splashscreen() {
    enable_plymouth_splashscreen
    disable_splashscreen
    ##rp_callModule "omxiv" remove
    rm -f /etc/splashscreen.list /etc/systemd/system/asplashscreen.service
    systemctl daemon-reload
}

function choose_path_splashscreen() {
    local options=(
        1 "RetroPie splashscreens"
        2 "Own/Extra splashscreens (from $datadir/splashscreens)"
    )
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ "$choice" -eq 1 ]] && echo "$md_inst"
    [[ "$choice" -eq 2 ]] && echo "$datadir/splashscreens"
}

function set_append_splashscreen() {
    local mode="$1"
    [[ -z "$mode" ]] && mode="set"
    local path
    local file
    while true; do
        path="$(choose_path_splashscreen)"
        [[ -z "$path" ]] && break
        file=$(choose_splashscreen "$path")
        if [[ -n "$file" ]]; then
            if [[ "$mode" == "set" ]]; then
                echo "$file" >/etc/splashscreen.list
                printMsgs "dialog" "Splashscreen set to '$file'"
                break
            fi
            if [[ "$mode" == "append" ]]; then
                echo "$file" >>/etc/splashscreen.list
                printMsgs "dialog" "Splashscreen '$file' appended to /etc/splashscreen.list"
            fi
        fi
    done
}

function choose_splashscreen() {
    local path="$1"
    local type="$2"

    local regex
    [[ "$type" == "image" ]] && regex=$(_image_exts_splashscreen)
    [[ "$type" == "video" ]] && regex=$(_video_exts_splashscreen)

    local options=()
    local i=0
    while read splashdir; do
        splashdir=${splashdir/$path\//}
        if echo "$splashdir" | grep -q "$regex"; then
            options+=("$i" "$splashdir")
            ((i++))
        fi
    done < <(find "$path" -type f ! -regex ".*/\..*" ! -regex ".*LICENSE" ! -regex ".*README.*" ! -regex ".*\.sh"  ! -regex ".*\.pkg" | sort)
    if [[ "${#options[@]}" -eq 0 ]]; then
        printMsgs "dialog" "There are no splashscreens installed in $path"
        return
    fi
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose splashscreen." 22 76 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    [[ -n "$choice" ]] && echo "$path/${options[choice*2+1]}"
}

function randomize_splashscreen() {
    options=(
        0 "Disable splashscreen randomizer"
        1 "Randomize RetroPie splashscreens"
        2 "Randomize own splashscreens (from $datadir/splashscreens)"
        3 "Randomize all splashscreens"
        4 "Randomize /etc/splashscreen.list"
    )
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
    local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    iniConfig "=" '"' "$configdir/all/$md_id.cfg"
    chown $user:$user "$configdir/all/$md_id.cfg"

    case "$choice" in
        0)
            iniSet "RANDOMIZE" "disabled"
            sudo sed -i 's+^RANDOMIZE=.*+RANDOMIZE=\"disabled\"+g' "$rp_splash_boot" #64bit_Bookworm
            printMsgs "dialog" "Splashscreen randomizer disabled."
            ;;
        1)
            iniSet "RANDOMIZE" "retropie"
            sudo sed -i 's+^RANDOMIZE=.*+RANDOMIZE=\"retropie\"+g' "$rp_splash_boot" #64bit_Bookworm
            printMsgs "dialog" "Splashscreen randomizer enabled in directory $rootdir/supplementary/$md_id"
            ;;
        2)
            iniSet "RANDOMIZE" "custom"
            sudo sed -i 's+^RANDOMIZE=.*+RANDOMIZE=\"custom\"+g' "$rp_splash_boot" #64bit_Bookworm
            printMsgs "dialog" "Splashscreen randomizer enabled in directory $datadir/splashscreens"
            ;;
        3)
            iniSet "RANDOMIZE" "all"
            sudo sed -i 's+^RANDOMIZE=.*+RANDOMIZE=\"all\"+g' "$rp_splash_boot" #64bit_Bookworm
            printMsgs "dialog" "Splashscreen randomizer enabled for both splashscreen directories."
            ;;
        4)
            iniSet "RANDOMIZE" "list"
            sudo sed -i 's+^RANDOMIZE=.*+RANDOMIZE=\"list\"+g' "$rp_splash_boot" #64bit_Bookworm
            printMsgs "dialog" "Splashscreen randomizer enabled for entries in /etc/splashscreen.list"
            ;;
    esac
}

function preview_splashscreen() {
    local options=(
        1 "View single splashscreen"
        2 "View slideshow of all splashscreens"
        3 "Play video splash"
    )

    local path
    local file
    local omxiv="/opt/retropie/supplementary/omxiv/omxiv" #Deprecated
    while true; do
        local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        [[ -z "$choice" ]] && break
        path="$(choose_path_splashscreen)"
        [[ -z "$path" ]] && break
        while true; do
            case "$choice" in
                1)
                    file=$(choose_splashscreen "$path" "image")
                    [[ -z "$file" ]] && break
                    ##clear; fbi -T 2 -a -noverbose "$file" > /dev/null 2>&1 & read -p "" </dev/tty && kill $(pgrep fbi)
                    #clear; fim -a -q -T 2 "$line" > /dev/null 2>&1 & read -p "" </dev/tty && kill $(pgrep fim)
                    #clear; mpv -vo sdl -fs --ontop --no-terminal "$line" > /dev/null 2>&1 & read -p "" </dev/tty && kill $(pgrep mpv)
                    clear; mpv -vo sdl -fs --ontop --no-terminal "$file" > /dev/null 2>&1 & read -p "" </dev/tty && kill $(pgrep mpv)
                    #clear; cvlc -q --no-osd -L --no-loop -f --no-video-title-show --play-and-exit --x11-display :0.0 "$file" > /dev/null 2>&1 & read -p "" </dev/tty && kill $(pgrep vlc)
                    ;;
                2)
                    file=$(mktemp)
                    find "$path" -type f ! -regex ".*/\..*" ! -regex ".*LICENSE" ! -regex ".*README.*" ! -regex ".*\.sh" ! -regex ".*retropie.pkg.*" | grep -v "$REGEX_VIDEO" | sort > "$file"
                    if [[ -s "$file" ]]; then
                        ##Uinput=/dev/shm/input.u; echo 'read -p "" </dev/tty && kill $(pgrep fbi) > /dev/null 2>&1 & rm $0 > /dev/null 2>&1' > $Uinput; chmod 755 $Uinput; clear; bash $Uinput & fbi -T 2 -a -t 2 --noverbose --once --list "$file" > /dev/null 2>&1; while pgrep fbi; do sleep 0.1 > /dev/null 2>&1; done; kill -KILL $(ps -eaf | grep "input.u" | awk '{print $2}') > /dev/null 2>&1; rm $Uinput > /dev/null 2>&1
                        #Uinput=/dev/shm/input.u; echo 'read -p "" </dev/tty && kill $(pgrep fim) > /dev/null 2>&1 & rm $0 > /dev/null 2>&1' > $Uinput; chmod 755 $Uinput; clear; bash $Uinput & fim -a -q -T 2 "$file" > /dev/null 2>&1; while pgrep fim; do sleep 0.1 > /dev/null 2>&1; done; kill -KILL $(ps -eaf | grep "input.u" | awk '{print $2}') > /dev/null 2>&1; rm $Uinput > /dev/null 2>&1
                        Uinput=/dev/shm/input.u; echo 'read -p "" </dev/tty && kill $(pgrep mpv) > /dev/null 2>&1 & rm $0 > /dev/null 2>&1' > $Uinput; chmod 755 $Uinput; clear; bash $Uinput & mpv -vo sdl -fs --ontop --no-terminal "$file" > /dev/null 2>&1; while pgrep mpv; do sleep 0.1 > /dev/null 2>&1; done; kill -KILL $(ps -eaf | grep "input.u" | awk '{print $2}') > /dev/null 2>&1; rm $Uinput > /dev/null 2>&1
                        #Uinput=/dev/shm/input.u; echo 'read -p "" </dev/tty && kill $(pgrep vlc) > /dev/null 2>&1 & rm $0 > /dev/null 2>&1' > $Uinput; chmod 755 $Uinput; clear; bash $Uinput & cvlc -q --no-osd -L --no-loop -f --no-video-title-show --play-and-exit --x11-display :0.0 "$file" > /dev/null 2>&1; while pgrep vlc; do sleep 0.1 > /dev/null 2>&1; done; kill -KILL $(ps -eaf | grep "input.u" | awk '{print $2}') > /dev/null 2>&1; rm $Uinput > /dev/null 2>&1
                    else
                        printMsgs "dialog" "There are no splashscreens installed in $path"
                    fi
                    rm -f "$file"
                    break
                    ;;
                3)
                    file=$(choose_splashscreen "$path" "video")
                    [[ -z "$file" ]] && break
                    Uinput=/dev/shm/input.u; echo 'read -p "" </dev/tty && kill $(pgrep mpv) > /dev/null 2>&1 & rm $0 > /dev/null 2>&1' > $Uinput; chmod 755 $Uinput; clear; bash $Uinput & mpv -vo sdl -fs --audio-device=alsa/sysdefault:CARD=vc4hdmi0 "$file" > /dev/null 2>&1 && kill -KILL $(ps -eaf | grep "input.u" | awk '{print $2}') > /dev/null 2>&1; rm $Uinput > /dev/null 2>&1
                    #Uinput=/dev/shm/input.u; echo 'read -p "" </dev/tty && kill $(pgrep vlc) > /dev/null 2>&1 & rm $0 > /dev/null 2>&1' > $Uinput; chmod 755 $Uinput; clear; bash $Uinput & cvlc -q --no-osd -L --no-loop -f --no-video-title-show --play-and-exit --x11-display :0.0 "$file" > /dev/null 2>&1 && kill -KILL $(ps -eaf | grep "input.u" | awk '{print $2}') > /dev/null 2>&1; rm $Uinput > /dev/null 2>&1
                    ;;
            esac
        done
    done
}

function download_extra_splashscreen() {
    gitPullOrClone "$datadir/splashscreens/retropie-extra" https://github.com/HerbFargus/retropie-splashscreens-extra
    chown -R $user:$user "$datadir/splashscreens/retropie-extra"
}

function gui_splashscreen() {
    if [[ ! -d "$md_inst" ]]; then
        rp_callModule splashscreen depends
        rp_callModule splashscreen install
    fi
    local cmd=(dialog --backtitle "$__backtitle" --menu "Choose an option." 22 86 16)
    while true; do
        local enabled=0
        [[ -n "$(find "/etc/systemd/system/"*".wants" -type l -name "asplashscreen.service")" ]] && enabled=1
        local options=(1 "Choose splashscreen")
        if [[ "$enabled" -eq 1 ]]; then
            options+=(2 "Show splashscreen on boot (currently: Enabled)")
            iniConfig "=" '"' "$configdir/all/$md_id.cfg"
            iniGet "RANDOMIZE"
            options+=(3 "Randomizer options (currently: ${ini_value^})")
        else
            options+=(2 "Show splashscreen on boot (currently: Disabled)")
        fi
        options+=(
            4 "Use default splashscreen"
            5 "Manually edit splashscreen list"
            6 "Append splashscreen to list (for multiple entries)"
            7 "Preview splashscreens"
            8 "Update RetroPie splashscreens"
            9 "Download RetroPie-Extra splashscreens"
        )

        iniConfig "=" '"' "$configdir/all/$md_id.cfg"
        iniGet "DURATION"
        # default splashscreen duration is 12 seconds
        local duration=${ini_value:-12}

        options+=(
            A "Configure image splashscreen duration ($duration sec)"
            )
        local choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    set_append_splashscreen set
                    ;;
                2)
                    if [[ "$enabled" -eq 1 ]]; then
                        disable_splashscreen
                        printMsgs "dialog" "Disabled splashscreen on boot."
                    else
                        [[ ! -f /etc/splashscreen.list ]] && rp_callModule splashscreen default
                        enable_splashscreen
                        printMsgs "dialog" "Enabled splashscreen on boot."
                    fi
                    ;;
                3)
                    randomize_splashscreen
                    ;;
                4)
                    iniSet "RANDOMIZE" "disabled"
                    default_splashscreen
                    enable_splashscreen
                    printMsgs "dialog" "Splashscreen set to RetroPie default."
                    ;;
                5)
                    editFile /etc/splashscreen.list
                    ;;
                6)
                    set_append_splashscreen append
                    ;;
                7)
                    preview_splashscreen
                    ;;
                8)
                    rp_callModule splashscreen install
                    ;;
                9)
                    rp_callModule splashscreen download_extra
                    printMsgs "dialog" "The RetroPie-Extra splashscreens have been downloaded to $datadir/splashscreens/retropie-extra"
                    ;;
                A)  
                    duration=$(dialog --title "Splashscreen duration" --clear --rangebox "Configure how many seconds the splashscreen is active" 0 60 5 100 $duration 2>&1 >/dev/tty)
                    if [[ -n "$duration" ]]; then
                        iniSet "DURATION" "${duration//[^[:digit:]]/}"
                    fi
                    ;;
            esac
        else
            break
        fi
    done
}
