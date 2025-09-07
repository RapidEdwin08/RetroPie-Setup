#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# RetroPie-Extra
# https://raw.githubusercontent.com/RapidEdwin08/RetroPie-Setup/master/ext/RetroPie-Extra/LICENSE
#
# If no user is specified (for RetroPie below v4.8.9)
if [[ -z "$__user" ]]; then __user="$SUDO_USER"; [[ -z "$__user" ]] && __user="$(id -un)"; fi

rp_module_id="chocolate-doom"
rp_module_desc="Enhanced Port of the Official DOOM Source"
rp_module_licence="GPL2 https://raw.githubusercontent.com/chocolate-doom/chocolate-doom/sdl2-branch/COPYING"
rp_module_help="Place [iWAD] Files in [ports/doom]:\n \n$romdir/ports/doom/\ndoom1.wad - doom.wad - doomu.wad\ndoom2.wad\nplutonia.wad\ntnt.wad\n \nheretic.wad\nhexen.wad\n \nstrife1.wad\n \nRun 'chocolate-doom-setup' to configure Controls, ect."
if [[ "$__os_debian_ver" -le 10 ]]; then
   rp_module_repo="git https://github.com/chocolate-doom/chocolate-doom.git master 15cfe539f9818152cecb14d9a0cda9aca40fa018"
else
   rp_module_repo="git https://github.com/chocolate-doom/chocolate-doom.git master"
fi
rp_module_section="exp"
rp_module_flags="!mali"

function depends_chocolate-doom() {
    local depends=(libsdl2-dev libsdl2-net-dev libsdl2-mixer-dev libsamplerate0-dev libpng-dev automake autoconf freepats dialog)
    if [[ $(apt-cache search python3-pil) == '' ]]; then
      depends+=(python-pil)
   else
      depends+=(python3-pil)
   fi
   getDepends "${depends[@]}"
}

function sources_chocolate-doom() {
    gitPullOrClone
    download https://raw.githubusercontent.com/RapidEdwin08/chocolate-doom-plus/main/Chocolate%20Doom%20Setup.sh "$md_build"
    download https://raw.githubusercontent.com/RapidEdwin08/chocolate-doom-plus/main/chocolate-doom-setup_64x64.xpm "$md_build"

}

function build_chocolate-doom() {
    ./autogen.sh
    ./configure --prefix="$md_inst"
    make -j"$(nproc)"
    md_ret_require="$md_build/src/chocolate-doom"
    md_ret_require="$md_build/src/chocolate-hexen"
    md_ret_require="$md_build/src/chocolate-heretic"
    md_ret_require="$md_build/src/chocolate-strife"
}

function install_chocolate-doom() {
    md_ret_files=(
        'src/chocolate-doom'
        'src/chocolate-hexen'
        'src/chocolate-heretic'
        'src/chocolate-strife'
        'src/chocolate-doom-setup'
        'src/chocolate-hexen-setup'
        'src/chocolate-heretic-setup'
        'src/chocolate-strife-setup'
        'src/chocolate-setup'
        'src/chocolate-server'
        'data/doom.ico'
        'data/heretic.ico'
        'data/hexen.ico'
        'data/setup.ico'
        'data/strife.ico'
        'chocolate-doom-setup_64x64.xpm'
        'Chocolate%20Doom%20Setup.sh'
    )
}

function game_data_chocolate-doom() {
    mkRomDir "ports"
    mkRomDir "ports/doom"
    if [[ ! -f "$romdir/ports/doom/doom1.wad" ]]; then
        wget "$__archive_url/doom1.wad" -O "$romdir/ports/doom/doom1.wad"
    fi
    # Symbolic Link to [doomu.wad] for [Chocolate Doom.desktop]
    if [[ ! -f "$romdir/ports/doom/doomu.wad" ]]; then
      if [[ -f "$romdir/ports/doom/doom.wad" ]]; then
         ln -s "$romdir/ports/doom/doom.wad" "$romdir/ports/doom/doomu.wad"
      else
         ln -s "$romdir/ports/doom/doom1.wad" "$romdir/ports/doom/doomu.wad"
      fi
      chown $__user:$__user "$romdir/ports/doom/doomu.wad"
   fi

    if [[ ! -f "$romdir/ports/doom/freedoom1.wad" ]]; then
        wget "https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip"
        unzip freedoom-0.13.0.zip
        mv freedoom-0.13.0/* "$romdir/ports/doom"
        rm -rf freedoom-0.13.0
        rm freedoom-0.13.0.zip
    fi
}

function remove_chocolate-doom() {
    if [[ -f "/usr/share/applications/Chocolate Doom.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate Doom.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate Doom.desktop" ]]; then rm -f "$home/Desktop/Chocolate Doom.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate Heretic.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate Heretic.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate Heretic.desktop" ]]; then rm -f "$home/Desktop/Chocolate Heretic.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate HeXen.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate HeXen.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate HeXen.desktop" ]]; then rm -f "$home/Desktop/Chocolate HeXen.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate Strife.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate Strife.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate Strife.desktop" ]]; then rm -f "$home/Desktop/Chocolate Strife.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate Doom Setup.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate Doom Setup.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate Doom Setup.desktop" ]]; then rm -f "$home/Desktop/Chocolate Doom Setup.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate Heretic Setup.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate Heretic Setup.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate Heretic Setup.desktop" ]]; then rm -f "$home/Desktop/Chocolate Heretic Setup.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate HeXen Setup.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate HeXen Setup.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate HeXen Setup.desktop" ]]; then rm -f "$home/Desktop/Chocolate HeXen Setup.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate Strife Setup.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate Strife Setup.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate Strife Setup.desktop" ]]; then rm -f "$home/Desktop/Chocolate Strife Setup.desktop"; fi

    if [[ -f "/usr/share/applications/Chocolate D00M Setup.desktop" ]]; then sudo rm -f "/usr/share/applications/Chocolate D00M Setup.desktop"; fi
    if [[ -f "$home/Desktop/Chocolate D00M Setup.desktop" ]]; then rm -f "$home/Desktop/Chocolate D00M Setup.desktop"; fi
}

function configure_chocolate-doom() {
    mv "$md_inst/Chocolate%20Doom%20Setup.sh" "$md_inst/chocolate_doom_setup"; chmod 755 "$md_inst/chocolate_doom_setup"
    moveConfigDir "$home/.local/share/chocolate-doom" "$md_conf_root/ports/chocolate-doom"
    if [[ "$__os_debian_ver" -le 10 ]]; then
      cat >"$md_inst/chocolate-doom.cfg" << _EOF_
video_driver                  ""
window_position               ""
fullscreen                    1
video_display                 0
aspect_ratio_correct          1
integer_scaling               0
vga_porch_flash               0
window_width                  800
window_height                 600
fullscreen_width              0
fullscreen_height             0
force_software_renderer       0
max_scaling_buffer_pixels     16000000
startup_delay                 1000
show_endoom                   0
show_diskicon                 1
png_screenshots               0
snd_samplerate                44100
snd_cachesize                 67108864
snd_maxslicetime_ms           28
snd_pitchshift                0
snd_musiccmd                  ""
snd_dmxoption                 ""
opl_io_port                   0x388
use_libsamplerate             0
libsamplerate_scale           0.650000
autoload_path                 "/home/pi/.local/share/chocolate-doom/autoload"
music_pack_path               "/home/pi/.local/share/chocolate-doom/music-packs"
timidity_cfg_path             "/etc/timidity/timidity.cfg"
gus_patch_path                ""
gus_ram_kb                    1024
vanilla_savegame_limit        0
vanilla_demo_limit            0
vanilla_keyboard_mapping      1
player_name                   "Hostile Mancubus"
grabmouse                     1
novert                        0
mouse_acceleration            2.000000
mouse_threshold               10
mouseb_strafeleft             -1
mouseb_straferight            -1
mouseb_turnleft               -1
mouseb_turnright              -1
mouseb_use                    -1
mouseb_backward               -1
mouseb_prevweapon             -1
mouseb_nextweapon             -1
dclick_use                    1
joystick_guid                 "030000005e0400008e02000010010000"
joystick_index                0
joystick_x_axis               3
joystick_x_invert             0
joystick_y_axis               1
joystick_y_invert             0
joystick_strafe_axis          0
joystick_strafe_invert        0
joystick_look_axis            -1
joystick_look_invert          0
joystick_physical_button0     5
joystick_physical_button1     1
joystick_physical_button2     2
joystick_physical_button3     4
joystick_physical_button4     4
joystick_physical_button5     5
joystick_physical_button6     2
joystick_physical_button7     3
joystick_physical_button8     8
joystick_physical_button9     7
joystick_physical_button10    6
joyb_strafeleft               -1
joyb_straferight              -1
joyb_menu_activate            9
joyb_toggle_automap           10
joyb_prevweapon               6
joyb_nextweapon               7
key_pause                     69
key_menu_activate             1
key_menu_up                   72
key_menu_down                 80
key_menu_left                 75
key_menu_right                77
key_menu_back                 14
key_menu_forward              28
key_menu_confirm              21
key_menu_abort                49
key_menu_help                 59
key_menu_save                 60
key_menu_load                 61
key_menu_volume               62
key_menu_detail               63
key_menu_qsave                64
key_menu_endgame              65
key_menu_messages             66
key_menu_qload                67
key_menu_quit                 68
key_menu_gamma                87
key_spy                       88
key_menu_incscreen            13
key_menu_decscreen            12
key_menu_screenshot           0
key_map_toggle                15
key_map_north                 72
key_map_south                 80
key_map_east                  77
key_map_west                  75
key_map_zoomin                13
key_map_zoomout               12
key_map_maxzoom               11
key_map_follow                33
key_map_grid                  34
key_map_mark                  50
key_map_clearmark             46
key_weapon1                   2
key_weapon2                   3
key_weapon3                   4
key_weapon4                   5
key_weapon5                   6
key_weapon6                   7
key_weapon7                   8
key_weapon8                   9
key_prevweapon                0
key_nextweapon                0
key_message_refresh           28
key_demo_quit                 16
key_multi_msg                 20
key_multi_msgplayer1          34
key_multi_msgplayer2          23
key_multi_msgplayer3          48
key_multi_msgplayer4          19
_EOF_
      sed -i s+'/home/pi/'+"$home/"+g "$md_inst/chocolate-doom.cfg"
    else
      cat >"$md_inst/chocolate-doom.cfg" << _EOF_
video_driver                  ""
window_position               ""
fullscreen                    1
video_display                 0
aspect_ratio_correct          1
integer_scaling               0
vga_porch_flash               0
window_width                  800
window_height                 600
fullscreen_width              0
fullscreen_height             0
force_software_renderer       0
max_scaling_buffer_pixels     16000000
startup_delay                 1000
show_endoom                   0
show_diskicon                 1
png_screenshots               1
snd_samplerate                44100
snd_cachesize                 67108864
snd_maxslicetime_ms           28
snd_pitchshift                0
snd_musiccmd                  ""
snd_dmxoption                 ""
opl_io_port                   0x388
use_libsamplerate             0
libsamplerate_scale           0.650000
autoload_path                 "/home/pi/.local/share/chocolate-doom/autoload"
music_pack_path               "/home/pi/.local/share/chocolate-doom/music-packs"
fsynth_chorus_active          1
fsynth_chorus_depth           5.000000
fsynth_chorus_level           0.350000
fsynth_chorus_nr              3
fsynth_chorus_speed           0.300000
fsynth_midibankselect         "gs"
fsynth_polyphony              256
fsynth_reverb_active          1
fsynth_reverb_damp            0.400000
fsynth_reverb_level           0.150000
fsynth_reverb_roomsize        0.600000
fsynth_reverb_width           4.000000
fsynth_gain                   1.000000
fsynth_sf_path                ""
timidity_cfg_path             ""
gus_patch_path                ""
gus_ram_kb                    1024
vanilla_savegame_limit        0
vanilla_demo_limit            0
vanilla_keyboard_mapping      1
player_name                   "Redundant Mancubus"
grabmouse                     1
novert                        0
mouse_acceleration            2.000000
mouse_threshold               10
mouseb_strafeleft             -1
mouseb_straferight            -1
mouseb_turnleft               -1
mouseb_turnright              -1
mouseb_use                    -1
mouseb_backward               -1
mouseb_prevweapon             -1
mouseb_nextweapon             -1
dclick_use                    1
joystick_guid                 "0300f2005e040000a102000007010000"
joystick_index                0
use_analog                    0
joystick_x_axis               2
joystick_x_invert             0
joystick_turn_sensitivity     10
joystick_y_axis               1
joystick_y_invert             0
joystick_strafe_axis          0
joystick_strafe_invert        0
joystick_move_sensitivity     10
joystick_look_axis            3
joystick_look_invert          0
joystick_look_sensitivity     10
joystick_physical_button0     22
joystick_physical_button1     1
joystick_physical_button2     2
joystick_physical_button3     21
joystick_physical_button4     4
joystick_physical_button5     5
joystick_physical_button6     9
joystick_physical_button7     10
joystick_physical_button8     8
joystick_physical_button9     6
joystick_physical_button10    4
joystick_physical_button11    11
joystick_physical_button12    12
joystick_physical_button13    13
joystick_physical_button14    14
joystick_physical_button15    15
joystick_physical_button16    16
use_gamepad                   1
gamepad_type                  1
joystick_x_dead_zone          33
joystick_y_dead_zone          33
joystick_strafe_dead_zone     33
joystick_look_dead_zone       33
joyb_strafeleft               -1
joyb_straferight              -1
joyb_menu_activate            9
joyb_toggle_automap           10
joyb_prevweapon               6
joyb_nextweapon               7
key_pause                     69
key_menu_activate             1
key_menu_up                   72
key_menu_down                 80
key_menu_left                 75
key_menu_right                77
key_menu_back                 14
key_menu_forward              28
key_menu_confirm              21
key_menu_abort                49
key_menu_help                 59
key_menu_save                 60
key_menu_load                 61
key_menu_volume               62
key_menu_detail               63
key_menu_qsave                64
key_menu_endgame              65
key_menu_messages             66
key_menu_qload                67
key_menu_quit                 68
key_menu_gamma                87
key_spy                       88
key_menu_incscreen            13
key_menu_decscreen            12
key_menu_screenshot           0
key_map_toggle                15
key_map_north                 72
key_map_south                 80
key_map_east                  77
key_map_west                  75
key_map_zoomin                13
key_map_zoomout               12
key_map_maxzoom               11
key_map_follow                33
key_map_grid                  34
key_map_mark                  50
key_map_clearmark             46
key_weapon1                   2
key_weapon2                   3
key_weapon3                   4
key_weapon4                   5
key_weapon5                   6
key_weapon6                   7
key_weapon7                   8
key_weapon8                   9
key_prevweapon                0
key_nextweapon                0
key_message_refresh           28
key_demo_quit                 16
key_multi_msg                 20
key_multi_msgplayer1          34
key_multi_msgplayer2          23
key_multi_msgplayer3          48
key_multi_msgplayer4          19
_EOF_
      sed -i s+'/home/pi/'+"$home/"+g "$md_inst/chocolate-doom.cfg"
    fi
    if [[ ! -f "$md_conf_root/ports/chocolate-doom/chocolate-doom.cfg" ]]; then cp "$md_inst/chocolate-doom.cfg" "$md_conf_root/ports/chocolate-doom/chocolate-doom.cfg"; fi
    if [[ ! -f "$md_conf_root/ports/chocolate-doom/chocolate-heretic.cfg" ]]; then cp "$md_inst/chocolate-doom.cfg" "$md_conf_root/ports/chocolate-doom/chocolate-heretic.cfg"; fi
    if [[ ! -f "$md_conf_root/ports/chocolate-doom/chocolate-hexen.cfg" ]]; then cp "$md_inst/chocolate-doom.cfg" "$md_conf_root/ports/chocolate-doom/chocolate-hexen.cfg"; fi
    if [[ ! -f "$md_conf_root/ports/chocolate-doom/chocolate-strife.cfg" ]]; then cp "$md_inst/chocolate-doom.cfg" "$md_conf_root/ports/chocolate-doom/chocolate-strife.cfg"; fi
    chown -R $__user:$__user "$md_conf_root/ports/chocolate-doom"

    # Temporary until the official RetroPie WAD selector is complete.
    if [[ -f "$romdir/ports/doom/doom1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doom1.wad"
       addPort "$md_id" "chocolate-doom1" "Chocolate Doom Shareware" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doom1.wad"
    fi

    if [[ -f "$romdir/ports/doom/doom.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doom.wad"
       addPort "$md_id" "chocolate-doom" "Chocolate Doom Registered" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doom.wad"
    fi

    if [[ -f "$romdir/ports/doom/freedoom1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/freedoom1.wad"
       addPort "$md_id" "chocolate-freedoom1" "Chocolate Free Doom: Phase 1" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/freedoom1.wad"
    fi

    if [[ -f "$romdir/ports/doom/freedoom2.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/freedoom2.wad"
       addPort "$md_id" "chocolate-freedoom2" "Chocolate Free Doom: Phase 2" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/freedoom2.wad"
    fi

    if [[ -f "$romdir/ports/doom/doom2.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doom2.wad"
       addPort "$md_id" "chocolate-doom2" "Chocolate Doom II: Hell on Earth" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doom2.wad"
    fi

    if [[ -f "$romdir/ports/doom/doomu.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/doomu.wad"
       addPort "$md_id" "chocolate-doomu" "Chocolate Ultimate Doom" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/doomu.wad"
    fi

    if [[ -f "$romdir/ports/doom/tnt.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/tnt.wad"
       addPort "$md_id" "chocolate-doomtnt" "Chocolate Final Doom - TNT: Evilution" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/tnt.wad"
    fi

    if [[ -f "$romdir/ports/doom/plutonia.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/plutonia.wad"
       addPort "$md_id" "chocolate-doomplutonia" "Chocolate Final Doom - The Plutonia Experiment" "$md_inst/chocolate-doom -iwad $romdir/ports/doom/plutonia.wad"
    fi

    if [[ -f "$romdir/ports/doom/heretic1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/heretic1.wad"
       addPort "$md_id" "chocolate-heretic1" "Chocolate Heretic Shareware" "$md_inst/chocolate-heretic -iwad $romdir/ports/doom/heretic1.wad"
    fi

    if [[ -f "$romdir/ports/doom/heretic.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/heretic.wad"
       addPort "$md_id" "chocolate-heretic" "Chocolate Heretic Registered" "$md_inst/chocolate-heretic -iwad $romdir/ports/doom/heretic.wad"
    fi

    if [[ -f "$romdir/ports/doom/hexen.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/hexen.wad"
       addPort "$md_id" "chocolate-hexen" "Chocolate Hexen" "$md_inst/chocolate-hexen -iwad $romdir/ports/doom/hexen.wad"
    fi

    if [[ -f "$romdir/ports/doom/hexdd.wad" && -f "$romdir/ports/doom/hexen.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/hexdd.wad"
       addPort "$md_id" "chocolate-hexdd" "Chocolate Hexen: Deathkings of the Dark Citadel" "$md_inst/chocolate-hexen -iwad $romdir/ports/doom/hexen.wad -file $romdir/ports/doom/hexdd.wad"
    fi

    if [[ -f "$romdir/ports/doom/strife1.wad" ]]; then
       chown $__user:$__user "$romdir/ports/doom/strife1.wad"
       addPort "$md_id" "chocolate-strife1" "Chocolate Strife" "$md_inst/chocolate-strife -iwad $romdir/ports/doom/strife1.wad"
    fi

    cat >"$md_inst/Chocolate Doom.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate Doom
GenericName=Chocolate Doom
Comment=Chocolate Doom
Exec=$md_inst/chocolate-doom -iwad $romdir/ports/doom/doomu.wad
Icon=$md_inst/doom.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;Doom
StartupWMClass=ChocolateDoom
Name[en_US]=Chocolate Doom
_EOF_
    chmod 755 "$md_inst/Chocolate Doom.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate Doom.desktop" "$home/Desktop/Chocolate Doom.desktop"; chown $__user:$__user "$home/Desktop/Chocolate Doom.desktop"; fi
    mv "$md_inst/Chocolate Doom.desktop" "/usr/share/applications/Chocolate Doom.desktop"

    cat >"$md_inst/Chocolate Heretic.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate Heretic
GenericName=Chocolate Heretic
Comment=Chocolate Heretic
Exec=$md_inst/chocolate-heretic -iwad $romdir/ports/doom/heretic.wad
Icon=$md_inst/heretic.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;Heretic
StartupWMClass=ChocolateHeretic
Name[en_US]=Chocolate Heretic
_EOF_
    chmod 755 "$md_inst/Chocolate Heretic.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate Heretic.desktop" "$home/Desktop/Chocolate Heretic.desktop"; chown $__user:$__user "$home/Desktop/Chocolate Heretic.desktop"; fi
    mv "$md_inst/Chocolate Heretic.desktop" "/usr/share/applications/Chocolate Heretic.desktop"

    cat >"$md_inst/Chocolate HeXen.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate HeXen
GenericName=Chocolate HeXen
Comment=Chocolate HeXen
Exec=$md_inst/chocolate-hexen -iwad $romdir/ports/doom/hexen.wad
Icon=$md_inst/hexen.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;HeXen
StartupWMClass=ChocolateHeXen
Name[en_US]=Chocolate HeXen
_EOF_
    chmod 755 "$md_inst/Chocolate HeXen.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate HeXen.desktop" "$home/Desktop/Chocolate HeXen.desktop"; chown $__user:$__user "$home/Desktop/Chocolate HeXen.desktop"; fi
    mv "$md_inst/Chocolate HeXen.desktop" "/usr/share/applications/Chocolate HeXen.desktop"

    cat >"$md_inst/Chocolate Strife.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate Strife
GenericName=Chocolate Strife
Comment=Chocolate Strife
Exec=$md_inst/chocolate-strife -iwad $romdir/ports/doom/strife1.wad
Icon=$md_inst/strife.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;Strife
StartupWMClass=ChocolateStrife
Name[en_US]=Chocolate Strife
_EOF_
    chmod 755 "$md_inst/Chocolate Strife.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate Strife.desktop" "$home/Desktop/Chocolate Strife.desktop"; chown $__user:$__user "$home/Desktop/Chocolate Strife.desktop"; fi
    mv "$md_inst/Chocolate Strife.desktop" "/usr/share/applications/Chocolate Strife.desktop"

    cat >"$md_inst/Chocolate Doom Setup.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate Doom Setup
GenericName=Chocolate Doom Setup
Comment=Chocolate Doom Setup
Exec=$md_inst/chocolate-doom-setup
Icon=$md_inst/setup.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;Doom;Setup
StartupWMClass=ChocolateDoomSetup
Name[en_US]=Chocolate Doom Setup
_EOF_
    chmod 755 "$md_inst/Chocolate Doom Setup.desktop"
    ##if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate Doom Setup.desktop" "$home/Desktop/Chocolate Doom Setup.desktop"; chown $__user:$__user "$home/Desktop/Chocolate Doom Setup.desktop"; fi
    ##mv "$md_inst/Chocolate Doom Setup.desktop" "/usr/share/applications/Chocolate Doom Setup.desktop"

    cat >"$md_inst/Chocolate Heretic Setup.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate Heretic Setup
GenericName=Chocolate Heretic Setup
Comment=Chocolate Heretic Setup
Exec=$md_inst/chocolate-heretic-setup
Icon=$md_inst/setup.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;Heretic;Setup
StartupWMClass=ChocolateHereticSetup
Name[en_US]=Chocolate Heretic Setup
_EOF_
    chmod 755 "$md_inst/Chocolate Heretic Setup.desktop"
    ##if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate Heretic Setup.desktop" "$home/Desktop/Chocolate Heretic Setup.desktop"; chown $__user:$__user "$home/Desktop/Chocolate Heretic Setup.desktop"; fi
    ##mv "$md_inst/Chocolate Heretic Setup.desktop" "/usr/share/applications/Chocolate Heretic Setup.desktop"

    cat >"$md_inst/Chocolate HeXen Setup.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate HeXen Setup
GenericName=Chocolate HeXen Setup
Comment=Chocolate HeXen Setup
Exec=$md_inst/chocolate-hexen-setup
Icon=$md_inst/setup.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;HeXen;Setup
StartupWMClass=ChocolateHeXenSetup
Name[en_US]=Chocolate HeXen Setup
_EOF_
    chmod 755 "$md_inst/Chocolate HeXen Setup.desktop"
    ##if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate HeXen Setup.desktop" "$home/Desktop/Chocolate HeXen Setup.desktop"; chown $__user:$__user "$home/Desktop/Chocolate HeXen Setup.desktop"; fi
    ##mv "$md_inst/Chocolate HeXen Setup.desktop" "/usr/share/applications/Chocolate HeXen Setup.desktop"

    cat >"$md_inst/Chocolate Strife Setup.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate Strife Setup
GenericName=Chocolate Strife Setup
Comment=Chocolate Strife Setup
Exec=$md_inst/chocolate-strife-setup
Icon=$md_inst/setup.ico
Terminal=false
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;Strife;Setup
StartupWMClass=ChocolateStrifeSetup
Name[en_US]=Chocolate Strife Setup
_EOF_
    chmod 755 "$md_inst/Chocolate Strife Setup.desktop"
    ##if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate Strife Setup.desktop" "$home/Desktop/Chocolate Strife Setup.desktop"; chown $__user:$__user "$home/Desktop/Chocolate Strife Setup.desktop"; fi
    ##mv "$md_inst/Chocolate Strife Setup.desktop" "/usr/share/applications/Chocolate Strife Setup.desktop"

    cat >"$md_inst/Chocolate D00M Setup.desktop" << _EOF_
[Desktop Entry]
Name=Chocolate D00M Setup
GenericName=Chocolate D00M Setup
Comment=Chocolate D00M Setup
Exec=$md_inst/chocolate_doom_setup
Icon=$md_inst/chocolate-doom-setup_64x64.xpm
Terminal=true
Type=Application
Categories=Game;Emulator
Keywords=Chocolate;D00M;Setup
StartupWMClass=ChocolateD00MSetup
Name[en_US]=Chocolate D00M Setup
_EOF_
    chmod 755 "$md_inst/Chocolate D00M Setup.desktop"
    if [[ -d "$home/Desktop" ]]; then cp "$md_inst/Chocolate D00M Setup.desktop" "$home/Desktop/Chocolate D00M Setup.desktop"; chown $__user:$__user "$home/Desktop/Chocolate D00M Setup.desktop"; fi
    mv "$md_inst/Chocolate D00M Setup.desktop" "/usr/share/applications/Chocolate D00M Setup.desktop"

    [[ "$md_mode" == "install" ]] && game_data_chocolate-doom
    [[ "$md_mode" == "remove" ]] && remove_chocolate-doom
}
