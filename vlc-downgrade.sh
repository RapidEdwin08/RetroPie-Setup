#!/usr/bin/env bash
 
# Workaround for libvlc issue with video previews in ES by Lolonois
# https://retropie.org.uk/forum/topic/35717/emulationstation-video-previews-on-raspberry-pi-5/17
 
pkgs=(libvlc5 libvlc-bin libvlccore9 vlc-bin vlc-data vlc-plugin-base)
ver="3.0.20-0+rpt6+deb12u1"

currentVLC=$(dpkg -l | grep libvlc-bin  | awk '{print $3}')

tput reset
echo
echo ISSUE with ES Video Snaps Applies to libvlc: [v1:3.0.21-0]
echo Your Current Version of libvlc: [v$currentVLC]
echo
echo *ONLY DOWNGRADE IF HAVING VIDEO SNAP DELAY ISSUES IN ES*
echo May Interfere with [sudo apt upgrade] until the HOLD is REMOVED
echo [sudo apt --fix-broken install] if needed AFTER the HOLD is REMOVED
echo
echo DOWNGRADE [libvlc] to [v$ver]
echo _OR _
echo Remove the HOLD of [v$ver] + UPGRADE [libvlc]
echo
echo "SELECT: [downgrade] or [upgrade]"
echo "  1) DOWNGRADE libvlc to [v$ver]"
echo "  2) REMOVE the HOLD of [v$ver] + UPGRADE libvlc"
echo "  3) FIX Broken Install [sudo apt --fix-broken install]"
echo "  4) QUIT"
 
read n
case $n in
  1) vlcCHOICE=downgrade;;
  2) vlcCHOICE=upgrade;;
  3) vlcCHOICE=fix;;
  4) exit 0;;
  *) echo "You must SELECT: [downgrade] or [upgrade]"; exit 0;;
esac
 
pushd /tmp > /dev/null 2>&1
for p in "${pkgs[@]}"; do
  arch="arm64"
  if [[ "$p" == "vlc-data" ]] ; then
    arch="all"
  fi
  if [[ "$vlcCHOICE" == "upgrade" ]]; then sudo apt-mark unhold "${pkgs[@]}"; echo HOLD has been REMOVED for [v$ver]; echo Attempting to UPGRADE "${pkgs[@]}"; sudo apt-get install "${pkgs[@]}"; popd; exit 0; fi
  if [[ "$vlcCHOICE" == "fix" ]]; then echo RUNNING [sudo apt --fix-broken install]...; sudo apt --fix-broken install; exit 0; fi
  wget "http://archive.raspberrypi.org/debian/pool/main/v/vlc/${p}_${ver}_${arch}.deb"
done
 
sudo dpkg -i *.deb
sudo apt-mark hold "${pkgs[@]}"
rm /tmp/*.deb
 
popd
 
