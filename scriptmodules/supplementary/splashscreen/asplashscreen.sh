#!/bin/sh

ROOTDIR="/opt/retropie"
DATADIR="/home/pi/RetroPie"
RANDOMIZE="all"
REGEX_VIDEO="\.avi\|\.mov\|\.mp4\|\.mkv\|\.3gp\|\.mpg\|\.mp3\|\.wav\|\.m4a\|\.aac\|\.ogg\|\.flac"
REGEX_IMAGE="\.bmp\|\.jpg\|\.jpeg\|\.gif\|\.png\|\.ppm\|\.tiff\|\.webp"

do_start () {
    local config="/etc/splashscreen.list"
    local line
    local re="$REGEX_VIDEO\|$REGEX_IMAGE"
    case "$RANDOMIZE" in
        disabled)
            line="$(head -1 "$config")"
            ;;
        retropie)
            line="$(find "$ROOTDIR/supplementary/splashscreen" -type f | grep "$re" | shuf -n1)"
            ;;
        custom)
            line="$(find "$DATADIR/splashscreens" -type f | grep "$re" | shuf -n1)"
            ;;
        all)
            line="$(find "$ROOTDIR/supplementary/splashscreen" "$DATADIR/splashscreens" -type f | grep "$re" | shuf -n1)"
            ;;
        list)
            line="$(cat "$config" | shuf -n1)"
            ;;
    esac
    if $(echo "$line" | grep -q "$REGEX_VIDEO"); then
        # wait for dbus
        while ! pgrep "dbus" >/dev/null; do
            sleep 1
        done
		mpv -vo sdl -fs -ao=alsa --no-terminal --audio-device=alsa/sysdefault:CARD=vc4hdmi0 "$line" >/dev/null 2>&1
		#cvlc -q --no-osd -L --no-loop -f --no-video-title-show --play-and-exit --x11-display :0 "$line" >/dev/null 2>&1
    elif $(echo "$line" | grep -q "$REGEX_IMAGE"); then
        if [ "$RANDOMIZE" = "disabled" ]; then
            local count=$(wc -l <"$config")
        else
            local count=1
        fi
        [ $count -eq 0 ] && count=1
        [ $count -gt 20 ] && count=20
        local delay=$((20/count))
        delay="$(cat /opt/retropie/configs/all/splashscreen.cfg | grep "DURATION" | awk -F'=' '{print $2}'| cut -c 2- | rev | cut -c 2- | rev)"; if [ "$delay" == '' ]; then delay=12; fi
        if [ "$RANDOMIZE" = "disabled" ]; then
            ( sleep "$delay" ; kill $(pgrep mpv) ) & mpv -vo sdl -fs --ontop --no-terminal $(cat "$config")
            #( sleep $delay ; kill $(pgrep fbi) ) & fbi -T 2 -a -noverbose $(cat "$config")
            #( sleep $delay ; kill $(pgrep vlc) ) & cvlc -q --no-osd -L --no-loop -f --no-video-title-show --play-and-exit --x11-display :0.0 $(cat "$config")
        else
            ( sleep "$delay" ; kill $(pgrep mpv) ) & mpv -vo sdl -fs --ontop --no-terminal "$line"
            #( sleep $delay ; kill $(pgrep fbi) ) & fbi -T 2 -a -noverbose "$line"
            #( sleep $delay ; kill $(pgrep vlc) ) & cvlc -q --no-osd -L --no-loop -f --no-video-title-show --play-and-exit --x11-display :0.0 "$line"
        fi
    fi
    exit 0
}

case "$1" in
    start|"")
        do_start &
        ;;
    restart|reload|force-reload)
        echo "Error: argument '$1' not supported" >&2
        exit 3
       ;;
    stop)
        # No-op
        ;;
    status)
        exit 0
        ;;
    *)
        echo "Usage: asplashscreen [start|stop]" >&2
        exit 3
        ;;
esac

:
