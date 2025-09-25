#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/macOS-onboarder#🏂
# License: MIT

# Copyright (c) © 2025 Landon Bouma. All Rights Reserved.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE:
#
#   # On GNOME Shell, run it:
#   path/to/macOS-onboarder/bin/slather-gsettings.sh
#
#   # To see list of reminders, and to smoke-test this script, dry-run it:
#   path/to/macOS-onboarder/bin/slather-gsettings.sh --dry-run

# SAVVY:
#
# - Run Settings app from the command line:
#
#     gnome-control-center
#
# - Run Tweaks from terminal:
#
#     /usr/bin/python3 /usr/bin/gnome-tweaks
#
# - Monitor dconf changes:
#
#     dconf watch /
#
# - Generally `dconf watch /` is all you need.
#
#   But if you want to capture the before and after,
#   and to easily diff it, try something like this:
#
#     . ~/.kit/mOS/macOS-onboarder/lib/linux-gsettings-commands.sh
#     gsettings-schemas-dump
#     # Do something that changes dconf
#     gsettings-schemas-dump
#     meld-last-two-dumps

# CXREF: DepoXy users: See similar macOS bindings:
#
#   ~/.kit/mOS/macOS-onboarder/bin/slather-defaults.sh
#   ~/.kit/mOS/macOS-Hammyspoony/.hammerspoon/init.lua

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# HINTS:
#
# - For a short desciption of a setting, use 'describe', e.g.:
#
#     $ gsettings describe org.gnome.Settings last-panel
#     The identifier for the last Settings panel to be opened. ...
#
# - For a count of applied settings (using DepoXy path):
#
#     ~/.kit/mOS/macOS-onboarder/bin/slather-gsettings.sh --cnt-run
#
# - For a preview of applied settings:
#
#     ~/.kit/mOS/macOS-onboarder/bin/slather-gsettings.sh --dry-run
#
# - LATER/2025-03-09: Record this count after the next run:
#
#   - Today's `gsettings set` + `dconf write` count: XXX.
#
# - NSUserKeyEquivalents characters (used for consistency):
#
#     $: Shift ⇧
#     ^: Ctrl ^
#     @: Command ⌘
#     ~: Option/Alt/Meta ⌥
#      : Globe/Function 🌐 (not addressable)
#
# - Keyboard Key legend:
#
#     ^  - Control
#     ⌥  - Option
#     ⇧  - Shift (Upwards White Arrow ↑)
#     ⌘  - Command
#     🌐 - Function
#
#     ⇥  - Tab (Rightwards Arrow to Bar) (see also: ⇤ Tab left)
#     ⇪  - Caps Lock (Upwards White Arrow from Bar)
#     ⏏  - Eject (Eject Symbol)
#     ⏎  - Return (Return Symbol)
#     ⌫  - Delete (Erase to the Left) (see also: ⌦  Fwd. Del.)
#     ⎋  - Escape (Broken Circle w/ NW Arrow; aka ISO 9995-7 ESC ch.)
#     ⌽  - On/Off/Power symbol (APL Functional Symbol Circle Stile)
#       - Apple logo approximation (U+F8FF, try Option (⌥)-Shift (⇧)-K on a Mac)
#          (Apple devices only: Uses last private-use codepoint.
#           Looks like Pi symbol in a solid square on GNU Linux/Hack Nerd Font)
#     ⊞  - Windows logo approximation (Squared Plus)
#     🐧 - Linux (Tux) approximation (Penguin)
#     …  - ⇞ Page Up / ⇟ Page Down / ↖︎ Top (Home) / ↘︎ End
#
#     macOS display order: Ctrl-Option-Shift-Command-<key> / ^⌥⇧⌘<key>
#
#     Author's/DepoXy's display order and terminology (based on English
#     keyboard layout, top to bottom, left to right): Shift-Ctrl-Cmd-Alt-<key>

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ISOFF/2025-09-24: Author no longer uses these extensions.
LINUX_ONBOARDER_INCLUDE_AATWS=${LINUX_ONBOARDER_INCLUDE_AATWS:-false}
LINUX_ONBOARDER_INCLUDE_JUST_PERFECTION=${LINUX_ONBOARDER_INCLUDE_JUST_PERFECTION:-false}

# USAGE: Update this "list" to reflect currently supported distros.
# - SAVVY: Format is `$ID: $VERSION_ID` from /etc/os-release
# - REFER: See long comments below re: Sussing OS details.
# - E.g.,:
#     LINUX_ONBOARDER_DISTROS="
#       debian: 12
#       debian: 13
#       linuxmint: 21.3
#     "
# - In reality, the author will only support one distro at a time
#   (well, two if you include macOS, but not in this file). And
#   I'll support how many ever versions until one of them deviates
#   significantly. (If you need an old version, see Git tags.)

reset_linux_onboarder_distro_ids() {
  LINUX_ONBOARDER_DISTROS="
    debian: 12
    debian: 13
  "
}

reset_linux_onboarder_desktop_ids() {
  LINUX_ONBOARDER_DESKTOPS="
    GNOME: 48
  "
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# REFER: Any system based on systemd has an /etc/os-release file,
# though some distros include an /etc/lsb-release file, too.
# - E.g., here are relevant files from Linux Mint 19.3:
#     $ fd ".*-release" /etc
#     /etc/lsb-release
#     /etc/os-release
#     /etc/upstream-release/lsb-release
#     ...
#   The lsb-release and os-release files before describe the distro
#   using shell=var syntax. The os-release file has more details.
#   The upstream-release/lsb-release file refs. the base distro, e.g.,
#   for Linux Mint 19.3, `DISTRIB_DESCRIPTION="Ubuntu 18.04 LTS"`.
# - E.g., here are the relevant files from Debian 12:
#     $ command fd ".*-release" /etc
#     /etc/os-release
#     /etc/os-release.debootstrap
#   The two files are almost identical. The os-release file has two
#   additional vars that describe how the distro was installed. E.g.,
#   for the author, it's "IMAGE_ID=live" (I installed from a Live CD)
#   and "BUILD_ID=20241109T101058Z".
# - REFER:
#   https://stackoverflow.com/questions/47838800/etc-lsb-release-vs-etc-os-release

# REFER: On Debian 12:
#   $ /etc/debian_version
#   12.9
#   $ (. /etc/os-release && echo "$ID: $VERSION_ID")
#   debian: 12
#   $ uname -rv
#   6.1.0-27-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.115-1 (2024-11-01)
#   $ cat /proc/version
#   Linux version 6.1.0-27-amd64 (debian-kernel@lists.debian.org)
#     (gcc-12 (Debian 12.2.0-14) 12.2.0, GNU ld (GNU Binutils for Debian) 2.40)
#     #1 SMP PREEMPT_DYNAMIC Debian 6.1.115-1 (2024-11-01)
#   $ cat /etc/issue
#   Debian GNU/Linux 12 \n \l
#
# SAVVY: Debian does not indicate the minor version is some places.
#   @Debian $ (. /etc/os-release && echo "$ID: $VERSION_ID")
#   debian: 12
#   @Debian $ lsb_release -a | grep Release
#   Release:	12
# Vs.:
#   @LinuxMint $ (. /etc/os-release && echo "$ID: $VERSION_ID")
#   linuxmint: 19.3
#   @LinuxMint $ lsb_release -a | grep Release
#   Release:	19.3

# SAVVY: Compare:
#   @Debian $ cat /etc/debian_version
#   12.9
# Vs.:
#   @LinuxMint $ cat /etc/debian_version
#   buster/sid

# USAGE: To not fail on unsupported distro, use environ:
#   LINUX_ONBOARDER_VOUCH=true slather-gsettings.sh

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# This script complains if it's run on an OS that the author has not
# verified works with it. Not that it won't work, but it might not
# work as intended. (It'll likely run on any Debian distro, but
# some of the gsettings keynames might be different.)

insist_is_supported_distro_unless_dry_run() {
  local dry_run=$1

  os_is_linux() {
    [ "$(uname)" = 'Linux' ]
  }

  if ! os_is_linux; then
    if ${dry_run}; then
      >&2 echo "ALERT: Running dry-run, but not on Linux!"
    else
      >&2 echo "ERROR: This script is designed for Linux!"

      exit_1
    fi
  fi

  insist_is_supported_linux_version

  insist_is_supported_desktop_environment
}

insist_is_supported_linux_version() {
  local osrel="/etc/os-release"

  if ! [ -f "${osrel}" ]; then
    >&2 echo "ERROR: Unrecognized distro: No such file: ${osrel}"

    exit_1
  fi

  # ***

  local verified=true

  local fiver="ERROR"
  if ${LINUX_ONBOARDER_VOUCH:-false}; then
    fiver="ALERT"
  fi

  (
    # BWARE: DUNNO: How much of a security risk is blindly sourcing?
    . /etc/os-release

    local distro="${ID}: ${VERSION_ID}"

    if ! echo "${LINUX_ONBOARDER_DISTROS}" | grep -q "^[[:space:]]*${distro}[[:space:]]*$"; then
      verified=false

      >&2 echo "${fiver}: Unrecognized distro: “${ID}: ${VERSION_ID}”"
      >&2 echo "- HINT: Expected “${ID}: ${VERSION_ID}” from ${osrel} to match one of:"
      >&2 echo "${LINUX_ONBOARDER_DISTROS}"
    fi

    if ! ${verified} && ! ${LINUX_ONBOARDER_VOUCH:-false}; then
      >&2 echo "- HINT: Set LINUX_ONBOARDER_VOUCH=true to continue anyway"

      exit_1
    fi
  )
  return 0
}

# Checks XDG_CURRENT_DESKTOP (CALSO: XDG_SESSION_DESKTOP).
insist_is_supported_desktop_environment() {
  local desktop="${XDG_CURRENT_DESKTOP}"

  local verified=true

  local fiver="ERROR"
  if ${LINUX_ONBOARDER_VOUCH:-false}; then
    fiver="ALERT"
  fi

  if ! echo "${LINUX_ONBOARDER_DESKTOPS}" | grep -q -e "^[[:space:]]*${desktop}: "; then
    verified=false

    >&2 echo "${fiver}: Unrecognized desktop: “${desktop}”"
    >&2 echo "- HINT: Expected “${desktop}” from XDG_CURRENT_DESKTOP to match one of:"
    echo "${LINUX_ONBOARDER_DESKTOPS}" | >&2 sed 's/: .*$//'
  fi

  local major_version="$(
    command -v gnome-shell >/dev/null &&
      gnome-shell --version |
      sed 's/^GNOME Shell \+\([0-9]\+\).*/\1/'
  )"
  if ${verified} &&
    ! echo "${LINUX_ONBOARDER_DESKTOPS}" |
    grep -q -e "^[[:space:]]*${desktop}: ${major_version}[[:space:]]*$" \
    ; then

    verified=false

    >&2 echo "${fiver}: Unrecognized desktop version: “${major_version}”"
    >&2 echo "- HINT: Expected \`gnome-shell --version\` to match one of:"
    >&2 echo "${LINUX_ONBOARDER_DESKTOPS}"
  fi

  if ! ${verified} && ! ${LINUX_ONBOARDER_VOUCH:-false}; then
    >&2 echo "- HINT: Set LINUX_ONBOARDER_VOUCH=true to continue anyway"

    exit_1
  fi

  return 0
}

# ***

is_hack_font_installed() {
  # REFER:
  #   fc-list :family=HackNerdFont
  # SAVVY: 'fontconfig' installed by default on Debian 12 [AFAIK].
  # CPYST:
  # - Reload fonts:
  #   sudo fc-cache -frv
  # - List font paths:
  #   fc-list -f '%{file}\n' | sort
  [ -n "$(fc-list :family=HackNerdFont:style=Regular)" ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps() {
  local dry_run=$1

  # Instead of checking, e.g., `os_is_linux`, check what really matters.
  (
    true &&
      command -v gsettings >/dev/null
  ) && return 0 || true

  local fiver="ERROR"
  if ${dry_run}; then
    fiver="ALERT"
  fi

  >&2 echo "${fiver}: Missing \`gsettings\`"

  if ${dry_run}; then

    return 0
  fi

  >&2 echo "- Hint: Are you running from macOS or not Debian? Try --dry-run"

  exit_1
}

fake_it() {
  fg_skyblue() { printf "\033[38;2;135;175;255m"; }
  fg_lightgray() { printf "\033[37m"; }
  attr_underline() { printf "\033[4m"; }
  attr_reset() { printf "\033[0m"; }
  highlight() { printf "%s" "$(fg_skyblue)$1$(attr_reset)"; }
  highlight_soft() { printf "%s" "$(fg_lightgray)$1$(attr_reset)"; }
  highlight_diff() { printf "%s" "$(attr_underline)$1$(attr_reset)"; }

  dconf_write() {
    print_dconf_write_setting "$@"
  }
  gsettings_set() {
    print_gsettings_set_setting "$@"
  }
}

# INPUT: ENV: Expects:
#   local cnt_dconf_write=0
#   local cnt_gsettings_set=0
count_it() {
  dconf_write() {
    local _description="$1"
    local _dconf_cmd="$2"
    local _dconf_write="$3"
    local dconf_key="$4"
    local dconf_value="$5"

    let 'cnt_dconf_write += 1'

    echo "  dconf: ${dconf_key} ${dconf_value}"
  }
  gsettings_set() {
    local _description="$1"
    local _gsettings_cmd="$2"
    local _gsettings_get="$3"
    local gsettings_schema="$4"
    local gsettings_key="$5"
    local gsettings_value="$6"

    let 'cnt_gsettings_set += 1'

    echo "  gsett: ${gsettings_schema} ${gsettings_key} ${gsettings_value}"
  }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Ha, this probably isn't necessary in GNOME like it is in (on?) Darwin.
gnome_settings_close() {
  local dry_run=$1

  if ${diff_run}; then

    return
  fi

  if ! ps aux | grep -q -e " gnome-control-center$"; then

    return
  fi

  echo "Closing GNOME Settings"

  if ! ${dry_run}; then

    killall gnome-control-center 2>/dev/null ||
      true
  fi

  echo "$(highlight_soft "- Reopen with:")"
  echo "$(highlight_soft "    gnome-control-center &")"
  echo
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

dconf_write() {
  local description="$1"
  local _dconf_cmd="$2"
  local _dconf_write="$3"
  local dconf_key="$4"
  local dconf_value="$5"

  echo "${description}: $(dconf read "${dconf_key}") → '${dconf_value}'"

  dconf write "${dconf_key}" "${dconf_value}"
}

gsettings_set() {
  local description="$1"
  local _gsettings_cmd="$2"
  local _gsettings_get="$3"
  local gsettings_schema="$4"
  local gsettings_key="$5"
  local gsettings_value="$6"

  echo "${description}: $(
    gsettings get "${gsettings_schema}" "${gsettings_key}"
  ) → '${gsettings_value}'"

  gsettings set "${gsettings_schema}" "${gsettings_key}" "${gsettings_value}"
}

print_dconf_write_setting() {
  local menu_path="$1"
  local _dconf_cmd="$2"
  local _dconf_write="$3"
  local dconf_key="$4"
  local dconf_val="$5"

  local curr_val
  curr_val="$(dconf read "${dconf_key}")"

  if [ -z "${curr_val}" ]; then
    curr_val="(unset?)❗"
  fi

  local quoted_val
  quoted_val="$(quote_gvariant "${dconf_val}")"

  local high_val="echo"
  local bang_val=""
  if [ "${curr_val}" != "${quoted_val}" ]; then
    high_val="highlight_diff"
    # 📌⛏️🪓⚠️🪚🔨📍❗
    bang_val=" 🔨"
  fi

  if ! ${diff_run} || [ "${curr_val}" != "${quoted_val}" ]; then
    echo -e "  $(
      highlight_soft "${menu_path}"
    ):\n    ${curr_val} → $(${high_val} "${quoted_val}")${bang_val}"
  fi
}

print_gsettings_set_setting() {
  local menu_path="$1"
  local _gsettings_cmd="$2"
  local _gsettings_get="$3"
  local gsettings_schema="$4"
  local gsettings_key="$5"
  local gsettings_val="$6"

  local curr_val
  curr_val="$(gsettings get "${gsettings_schema}" "${gsettings_key}")"

  if [ -z "${curr_val}" ]; then
    curr_val="(unset?)❗"
  fi

  local quoted_val
  quoted_val="$(quote_gvariant "${gsettings_val}")"

  local high_val="echo"
  local bang_val=""
  if [ "${curr_val}" != "${quoted_val}" ]; then
    high_val="highlight_diff"
    bang_val=" 🔨"
  fi

  if ! ${diff_run} || [ "${curr_val}" != "${quoted_val}" ]; then
    echo -e "  $(
      highlight_soft "${menu_path}"
    ):\n    ${curr_val} → $(${high_val} "${quoted_val}")${bang_val}"
  fi
}

quote_gvariant() {
  local val="$1"

  # This is not perfect, but currently works with our dataset.
  # - See also `printf "%q`, but not quite what we need.
  if echo "${val}" | grep -q -e "^\-\?[0-9\.]\+$" ||
    [ "${val}" = "true" ] || [ "${val}" = "false" ] \
    ; then
    printf "%s" "${val}"
  elif echo "${val}" | grep -q -e "^#[0-9]\{6\}$" ||
    [ "${val}" = "true" ] || [ "${val}" = "false" ] \
    ; then
    printf "%s" "'${val}'"
  elif echo "${val}" | grep -q -e "^uint32 [0-9]\+$" ||
    [ "${val}" = "true" ] || [ "${val}" = "false" ] \
    ; then
    printf "%s" "${val}"
  elif [ "${val}" = "@as []" ]; then
    printf "%s" "${val}"
  elif echo "${val}" | grep -q -e "^\['"; then
    printf "%s" "${val}"
  elif echo "${val}" | grep -q -e "'"; then
    >&2 echo "UNCLASSIFIED: ${val}"
    exit_1
  else
    printf "'%s'" "${val}"
  fi
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ GNOME Settings GUI settings

# ***
#
# ░░░ The functions and settings align with The GNOME Project *Settings* GUI on Debian 12.
#

gnome_settings_customize() {
  echo -e "\n$(highlight_soft "*** GNOME Settings")\n"

  # Nothing to configure:
  #   gnome_settings_customize_wifi
  #   gnome_settings_customize_network
  #   gnome_settings_customize_bluetooth

  gnome_settings_customize_appearance
  gnome_settings_customize_notifications
  gnome_settings_customize_search
  gnome_settings_customize_multitasking

  gnome_settings_customize_applications
  gnome_settings_customize_privacy
  gnome_settings_customize_online_accounts
  gnome_settings_customize_sharing

  gnome_settings_customize_sound
  gnome_settings_customize_power
  gnome_settings_customize_displays
  gnome_settings_customize_mouse_and_touchpad
  gnome_settings_customize_keyboard
  gnome_settings_customize_printers
  gnome_settings_customize_removable_media
  gnome_settings_customize_color
}

# ***

gnome_settings_customize_appearance() {
  gnome_settings_customize_appearance_style
  gnome_settings_customize_appearance_background
}

gnome_settings_customize_appearance_style() {
  # Default: 'default'
  gsettings_set "Settings > Appearance > Style" \
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
}

# The GNOME Shell 43 GUI lets you select from 26 different background
# images and color settings, or you can set your own image.
# - There are no GUI options to set a solid color.
# - THANX: For the gsettings hints to use a solid background:
#     https://www.reddit.com/r/debian/comments/3kl3s7/how_do_i_change_the_background_to_a_plain_black/
# - REFER:
#   gsettings list-recursively org.gnome.desktop.background
#   - RESET:
#     gsettings reset-recursively org.gnome.desktop.background

# SAVVY: When you pick a new background using the
# Background GUI, it also changes the screensaver:
#   org.gnome.desktop.screensaver

gnome_settings_customize_appearance_background() {
  # Other org.gnome.desktop.background options:
  #   picture-opacity 100
  #   picture-uri 'file:///usr/share/images/desktop-base/desktop-background.xml'
  #   picture-uri-dark 'file:///usr/share/backgrounds/gnome/adwaita-d.webp'
  #   show-desktop-icons false

  # Default: 'solid', but using GUI may change, e.g., to 'horizontal'.
  gsettings_set "Settings > Appearance > Background > Color Shading Type" \
    gsettings set org.gnome.desktop.background color-shading-type 'solid'

  # Default: 'zoom', but using GUI may change, e.g., to 'zoom'.
  # - Doesn't matter when used with solid color, so leave
  #   at 'zoom', which is what Settings changes it to, so
  #   that ./slather-gsettings.sh --dry-run doesn't diff.
  gsettings_set "Settings > Appearance > Background > Picture Options" \
    gsettings set org.gnome.desktop.background picture-options 'zoom'

  # SAVVY: Very dark "green", slight contrast with borderless Chrome windows.
  # - Vs. black:
  #   gsettings_set "Settings > Appearance > Background > Primary Color" \
  #     gsettings set org.gnome.desktop.background primary-color '#000000'
  gsettings_set "Settings > Appearance > Background > Primary Color" \
    gsettings set org.gnome.desktop.background primary-color '#021003'

  gsettings_set "Settings > Appearance > Background > Secondary Color" \
    gsettings set org.gnome.desktop.background secondary-color '#000000'
}

# ***

# MAYBE/2025-01-12: Disable Lock Screen Notifications?
#   org.gnome.desktop.notifications show-in-lock-screen true|false
gnome_settings_customize_notifications() {
  :
}

# ***

# Nothing to change.
gnome_settings_customize_search() {
  :
}

# ***

gnome_settings_customize_multitasking() {
  # Disable the top-left hot corner, which author triggers inadvertently too often.
  # - Using <Cmd> to open Activities Overview is a much better mechanism.
  # - Default: true
  gsettings_set "Settings > Multitasking > General > Hot Corner" \
    gsettings set org.gnome.desktop.interface enable-hot-corners false

  # Default: true (Include applications from all workspaces)
  gsettings_set "Settings > Multitasking > Application Switching > Include applications from the current workspace only" \
    gsettings set org.gnome.shell.app-switcher current-workspace-only true
}

# ***

# Nothing to change.
gnome_settings_customize_applications() {
  :
}

# ***

gnome_settings_customize_privacy() {
  gnome_settings_customize_privacy_screen
  gnome_settings_customize_privacy_location_services
  gnome_settings_customize_privacy_camera
  gnome_settings_customize_privacy_microphone
  gnome_settings_customize_privacy_thunderbolt
  gnome_settings_customize_privacy_file_history_and_trash
}

# CALSO: Settings > Power > Power Saving Options also shows Screen Blank setting.
gnome_settings_customize_privacy_screen() {
  # Default: 5 minutes (uint32 3000)
  gsettings_set "Settings > Privacy > Screen > Screen Lock > Blank Screen Delay: 8 mins" \
    gsettings set org.gnome.desktop.session idle-delay 'uint32 480'

  # Default: Enabled (true)
  gsettings_set "Settings > Privacy > Screen > Screen Lock > Automatic Screen Lock" \
    gsettings set org.gnome.desktop.screensaver lock-enabled true

  # Note the GUI only lets you set up to 1 hour.
  # - When it's unrecognized, drop-down shows "Screen Turns Off"
  # - Default: Disabled (uint32 0)
  # - 1 hour:
  #   gsettings_set "Settings > Privacy > Screen > Screen Lock > Automatic Screen Lock Delay: 1 hour" \
  #     gsettings set org.gnome.desktop.screensaver lock-delay 3600
  # - REFER: For hosts at home, author prefers at least 4 hours (14400).
  #   - Sensible timeouts: 4h 14400, 4⅓h 15600, 6h 21600, 6⅔h 24000, 8h 28800.
  gsettings_set "Settings > Privacy > Screen > Screen Lock > Automatic Screen Lock Delay: 4 hours" \
    gsettings set org.gnome.desktop.screensaver lock-delay 'uint32 24000'
  # TRACK/2025-01-12: Something is causing Settings to become unresponsive...
  # - BWARE: Or not: Using custom lock-delay makes Settings unresponsive within
  # - seconds of starting Settings app, e.g., if you run this manually:
  #     gsettings set org.gnome.desktop.screensaver lock-delay 14400
  # - DUNNO/2025-01-12: Working again after reboot, albeit with 3600 value.

  # Default: Disabled (false)
  gsettings_set "Settings > Privacy > Screen > Screen Lock > Lock Screen Notifications" \
    gsettings set org.gnome.desktop.notifications show-in-lock-screen true
}

# Nothing to change.
gnome_settings_customize_privacy_location_services() {
  :
}

# Nothing to change.
gnome_settings_customize_privacy_camera() {
  :
}

# Nothing to change.
gnome_settings_customize_privacy_microphone() {
  :
}

# Nothing to change.
gnome_settings_customize_privacy_thunderbolt() {
  :
}

# Nothing to change.
# FIXME/2025-01-12: Considering these options:
#   ✗ Automatically Delete Trash Content
#   ✗ Automatically Delete Temporarily Files
#   Automatically Delete Period: 30 days
# - Does this mean that /tmp files are *never* cleared??
gnome_settings_customize_privacy_file_history_and_trash() {
  :
}

# ***

# Nothing to change.
# FIXME/2025-01-12: Try wiring Google Account.
gnome_settings_customize_online_accounts() {
  print_at_end+=("\
🔳 Settings > Online Accounts > Add an account
   - Wire a cloud account to enable, e.g., GNOME Calendar & Email apps
   - Providers: Google, Nextcloud, Microsoft, Microsoft Exchange,
                Last.fm, IMAP and SMTP, Enterprise Login (Kerberos)")
}

# ***

# Nothing to change.
# - Includes toggles for:
#     File Sharing
#     Remote Desktop
#     Media Sharing
#     Remote Login
# - Changing at least Remote Login requires privileges,
#   and the change is not through `gsettings` (probably
#   starts SSHd server).
gnome_settings_customize_sharing() {
  print_at_end+=("\
🔳 Settings > Sharing > Remote Login > Enable")
}

# ***

# Nothing to change.
gnome_settings_customize_sound() {
  # DUNNO: Where's this setting maintained?
  print_at_end+=("\
🔳 Settings > Sound > Alert Sound > Click|String|Swing|Hum (maybe Click?)")
}

# ***

# CALSO: Settings > Privacy > Screen > Screen Lock also shows Screen Blank setting.
gnome_settings_customize_power() {
  # Other schema options:
  #   org.gnome.settings-daemon.plugins.power ambient-enabled true
  #   org.gnome.settings-daemon.plugins.power idle-brightness 30

  # MAYBE/2025-01-12: Disable Dim Screen
  # Default: Enabled (true)
  gsettings_set "Settings > Power > Power Saving Options > Dim Screen" \
    gsettings set org.gnome.settings-daemon.plugins.power idle-dim true

  # Default: 5 minutes (uint32 3000)
  # - Maintained above: gnome_settings_customize_privacy_screen
  #   gsettings_set "Power: Power Saving Options: Screen Blank: 8 mins" \
  #   gsettings set org.gnome.desktop.session idle-delay 480

  # Default: Enabled (true)
  gsettings_set "Settings > Power > Power Saving Options > Automatic Power Saver" \
    gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery true

  # Default: Enabled: 20 mins. (1200, 'suspend')
  gsettings_set \
    "Settings > Power > Power Saving Options > Automatic Suspend > On Battery Power: 30 mins." \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800
  gsettings_set "Settings > Power > Power Saving Options > Automatic Suspend > On Battery Power: Enabled" \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'

  # Default: Enabled: 20 mins. (1200, 'suspend')
  #   gsettings_set "Power: Power Saving Options: Automatic Suspend: Plugged In: 20 mins." \
  #   gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 1200
  gsettings_set "Settings > Power > Power Saving Options > Automatic Suspend > Plugged In: Disabled" \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

  # Power Button Behavior:
  # - Suspend: 'suspend' [Default]
  # - Power Off: 'interactive'
  # - Nothing: 'nothing'
  # SPIKE/2025-01-12: Demo each option and pick one.
  # - For now, 'interactive' (I almost always have laptop lid closed,
  #   so don't expect any traction on this SPIKE).
  gsettings_set "Settings > Power > Power Button Behavior > Power Off" \
    gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
}

# ***

# Nothing to change.
gnome_settings_customize_displays() {
  :
}

# ***

# Nothing to change.
gnome_settings_customize_mouse_and_touchpad() {
  # Other Mouse & Touchpad settings:
  #   org.gnome.desktop.peripherals.mouse drag-threshold 8
  #   # CALSO: Tweaks > Keyboard & Mouse > Mouse Click Emulation
  #   org.gnome.desktop.peripherals.mouse middle-click-emulation false
  #
  # What you'll see in the GUI:
  #   # Mouse & Touchpad > General > Primary Button: Left|Right
  #   org.gnome.desktop.peripherals.mouse left-handed false
  #
  #   # Mouse & Touchpad > Mouse > Mouse Speed: (Slider)
  #   org.gnome.desktop.peripherals.mouse speed 0.0
  #   # - CALSO: Tweaks > Keyboard & Mouse > Mouse > Acceleration Profile
  #   org.gnome.desktop.peripherals.mouse accel-profile 'default'
  #   org.gnome.desktop.peripherals.mouse double-click 400
  #
  #   # Mouse & Touchpad > Mouse > Natural Scrolling
  #   org.gnome.desktop.peripherals.mouse natural-scroll false
  :
}

# ***

gnome_settings_customize_keyboard() {
  echo -e "\n$(
    highlight_soft \
      "**** GNOME Settings > Keyboard > Keyboard Shortcuts > View and Customize Shortcuts"
  )\n"

  gnome_settings_customize_keyboard_accessibility
  gnome_settings_customize_keyboard_launchers
  gnome_settings_customize_keyboard_navigation
  gnome_settings_customize_keyboard_screenshots
  gnome_settings_customize_keyboard_sound_and_media
  gnome_settings_customize_keyboard_system
  gnome_settings_customize_keyboard_typing
  gnome_settings_customize_keyboard_windows
  gnome_settings_customize_keyboard_custom_shortcuts
}

gnome_settings_customize_keyboard_accessibility() {
  # Bindings:
  #   "Keyboard Shortcuts > Accessibility > Decrease text size: Disabled"
  #   "Keyboard Shortcuts > Accessibility > High contrast on or off: Disabled"
  #   "Keyboard Shortcuts > Accessibility > Increase text size: Disabled"
  #   "Keyboard Shortcuts > Accessibility > Turn on-screen keyboard on or off: Disabled"

  # MAYBE/2025-01-13: Disable these:
  #   "Keyboard Shortcuts > Accessibility > Turn screen-reader on or off: ['<Super><Alt>s']
  #   "Keyboard Shortcuts > Accessibility > Turn zoom on or off: ['<Super><Alt>s']
  #   "Keyboard Shortcuts > Accessibility > Zoom in: ['<Super><Alt>=']
  #   "Keyboard Shortcuts > Accessibility > Zoom out: ['<Super><Alt>-']
  :
}

# These all default disabled except for Launch help browser.
# - Bindings:
#     Home folder
#     Launch calculator
#     Launch email client
#     Launch help browser
#     Launch web browser
#     Search
#     Settings
gnome_settings_customize_keyboard_launchers() {
  # Keyboard > Keyboard Shortcuts > View and Customize Shortcuts
  #   Keyboard Shortcuts > Launchers > Launch help browser: Disabled
  # - Defaults <Cmd-F1>:
  #   /org/gnome/settings-daemon/plugins/media-keys/help ['<Super>F1']
  dconf_write "Keyboard Shortcuts > Launchers > Launch help browser: Disabled" \
    dconf write /org/gnome/settings-daemon/plugins/media-keys/help '@as []'
}

# FIXME/2025-01-13: Normalize against macOS/Rectangle bindings,
# and disable ones you don't need.
gnome_settings_customize_keyboard_navigation() {
  # Bindings:
  #   "Keyboard Shortcuts > Navigation > Hide all normal windows: Disabled"
  #   - HSTRY/2025-09-12: As seen in GNOME Shell 43 (Debian 12) (I think),
  #     but (definitely not) GNOME Shell 48 (Debian 13):
  #       "Keyboard Shortcuts > Navigation > Move to workspace on the left: <Cmd-PageUp>"
  #       "Keyboard Shortcuts > Navigation > Move to workspace on the right: <Cmd-PageDown>"
  #   "Keyboard Shortcuts > Navigation > Move window one monitor down: <Shift-Cmd-Down>"
  #   "Keyboard Shortcuts > Navigation > Move window one monitor to the left: <Shift-Cmd-Left>"
  #   "Keyboard Shortcuts > Navigation > Move window one monitor to the right: <Shift-Cmd-Right>"
  #   "Keyboard Shortcuts > Navigation > Move window one monitor up: <Shift-Cmd-Up>"
  #   "Keyboard Shortcuts > Navigation > Move window one workspace to the left: <Shift-Cmd-PageUp>"
  #   "Keyboard Shortcuts > Navigation > Move window one workspace to the right: <Shift-Cmd-PageDown>"
  #   "Keyboard Shortcuts > Navigation > Move window to last workspace: <Shift-Cmd-End>"
  #   "Keyboard Shortcuts > Navigation > Move window to workspace 1: <Shift-Cmd-Home>"
  #   "Keyboard Shortcuts > Navigation > Move window to workspace 2: Disabled"
  #   "Keyboard Shortcuts > Navigation > Move window to workspace 3: Disabled"
  #   "Keyboard Shortcuts > Navigation > Move window to workspace 4: Disabled"
  #   "Keyboard Shortcuts > Navigation > Switch applications: <Super>Tab"
  # /org/gnome/desktop/wm/keybindings/switch-applications ['<Super>grave']
  # /org/gnome/desktop/wm/keybindings/switch-applications-backward ['<Shift><Super>grave']
  # /org/gnome/desktop/wm/keybindings/switch-applications @as []
  # /org/gnome/desktop/wm/keybindings/switch-applications-backward @as []
  dconf_write "Keyboard Shortcuts > Navigation > Switch applications: Disabled:" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-applications '@as []'
  dconf_write "Keyboard Shortcuts > Navigation > Switch applications backward: Disabled:" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward '@as []'
  #   "Keyboard Shortcuts > Navigation > Switch system controls: <Ctrl><Alt>Tab"
  #   "Keyboard Shortcuts > Navigation > Switch system controls directly: <Ctrl><Alt>Escape"

  #   "Keyboard Shortcuts > Navigation > Switch to last workspace: <Cmd-End>"
  #   "Keyboard Shortcuts > Navigation > Switch to workspace 1: <Cmd-Home>"
  #   "Keyboard Shortcuts > Navigation > Switch to workspace 2: Disabled"
  #   "Keyboard Shortcuts > Navigation > Switch to workspace 3: Disabled"
  #   "Keyboard Shortcuts > Navigation > Switch to workspace 4: Disabled"
  #   "Keyboard Shortcuts > Navigation > Switch windows: Disabled"
  # /org/gnome/desktop/wm/keybindings/switch-windows unset
  # /org/gnome/desktop/wm/keybindings/switch-windows-backward unset
  # /org/gnome/desktop/wm/keybindings/switch-windows @as []
  # /org/gnome/desktop/wm/keybindings/switch-windows ['<Alt>Tab']
  # /org/gnome/desktop/wm/keybindings/switch-windows-backward ['<Shift><Alt>Tab']
  dconf_write "Keyboard Shortcuts > Navigation > Switch windows:" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-applications "['<Alt>Tab']"
  # This doesn't work:
  #   dconf_write "Keyboard Shortcuts > Navigation > Switch windows backward:" \
  #     dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "['<Alt>q']"
  dconf_write "Keyboard Shortcuts > Navigation > Switch windows backward:" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-applications-backward "['<Shift><Alt>Tab']"
  #   "Keyboard Shortcuts > Navigation > Switch windows directly: <Alt>Escape"
  #   "Keyboard Shortcuts > Navigation > Switch windows of an app directly: <Alt>F6"
  #   "Keyboard Shortcuts > Navigation > Switch windows of an application: <Super>`"
  # /org/gnome/desktop/wm/keybindings/switch-group unset
  # /org/gnome/desktop/wm/keybindings/switch-group-backward unset
  # /org/gnome/desktop/wm/keybindings/switch-group @as []
  # /org/gnome/desktop/wm/keybindings/switch-group ['<Super>Tab']
  # /org/gnome/desktop/wm/keybindings/switch-group-backward ['<Shift><Super>Tab']
  dconf_write "Keyboard Shortcuts > Navigation > Switch windows:" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-group "['<Super>Tab']"
  dconf_write "Keyboard Shortcuts > Navigation > Switch windows backward:" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-group-backward "['<Shift><Super>Tab']"
}

gnome_settings_customize_keyboard_screenshots() {
  # FIXME/2025-01-13: Change to match macOS bindings (or close to it)
  #
  # - Default: ['<Shift><Control><Alt>r']
  dconf_write "Keyboard Shortcuts > Screenshots > Record a screencast interactively: Shift-Cmd-4" \
    dconf write /org/gnome/shell/keybindings/show-screen-recording-ui "['<Shift><Super>4']"

  # - Default: ['<Shift>Print']
  dconf_write "Keyboard Shortcuts > Screenshots > Take a screenshot: ???" \
    dconf write /org/gnome/shell/keybindings/screenshot '@as []'

  # - Default: ['Print']
  dconf_write "Keyboard Shortcuts > Screenshots > Take a screenshot interactively: ???" \
    dconf write /org/gnome/shell/keybindings/screenshot '@as []'

  # - Default: ['<Alt>Print']
  dconf_write "Keyboard Shortcuts > Screenshots > Take a screenshot of a window: ???" \
    dconf write /org/gnome/shell/keybindings/screenshot '@as []'
}

# All settings default disabled.
# - Includes:
#     Eject
#     Launch media player
#     Microphone mute/unmute
#     Next track
#     Pause playback
#     Play (or play/pause)
#     Previous track
#     Stop playback
#     Volume down
#     Volume mute/unmute
#     Volume up
gnome_settings_customize_keyboard_sound_and_media() {
  :
}

gnome_settings_customize_keyboard_system() {
  # - Default: ['<Super>n']
  # dconf_write "Keyboard Shortcuts > System > Focus the active notification: Disabled" \
  # dconf write /org/gnome/shell/keybindings/focus-active-notification '@as []'

  # BNDNG: <Ctrl-Cmd-Q>
  # - Default: ['<Super>l']
  dconf_write "Keyboard Shortcuts > System > Lock screen" \
    dconf write /org/gnome/settings-daemon/plugins/media-keys/screensaver "['<Control><Super>q']"

  # - Default: ['<Control><Alt>Delete']
  # dconf_write "Keyboard Shortcuts > System > Log out: Disabled" \
  # dconf write /org/gnome/settings-daemon/plugins/media-keys/logout "['<Control><Alt>Delete']"

  # DUNNO/2025-01-13: Pressing <Cmd-F10> has no effect.
  # - Default: ['<Super>F10']
  # dconf_write "Keyboard Shortcuts > System > Open the application menu: Disabled" \
  # dconf write /org/gnome/shell/keybindings/open-application-menu '@as []'

  # FIXME/2025-01-13: What's this do?
  # - Default: ['<Super>Escape']
  # dconf_write "Keyboard Shortcuts > System > Restore the keyboard shortcuts: Disabled" \
  # dconf write /org/gnome/mutter/wayland/keybindings/restore-shortcuts '@as []'

  # ISOFF: This shows the Overview application list.
  # - It's the same as <Cmd> to show Overview, then clicking the 3x3 dots icon (⁙).
  # - Default: ['<Super>a']
  dconf_write "Keyboard Shortcuts > System > Show all applications: Disabled" \
    dconf write /org/gnome/shell/keybindings/toggle-application-view '@as []'

  # - Default: ['<Super>v']
  # If no notifications, doesn't do anything.
  # FIXME/2025-01-13: Is this similar to Show Notification Center on macOS?
  # - Author's macOS ONBRD doc suggests using <Shift-Ctrl-Cmd-C>
  #   to Show Notification Center.
  #  dconf_write "Keyboard Shortcuts > System > Show the notification list: Disabled" \
  #    dconf write /org/gnome/shell/keybindings/toggle-message-tray '@as []'
  # BNDNG: <Shift-Ctrl-Cmd-C>
  dconf_write "Keyboard Shortcuts > System > Show the notification list" \
    dconf write /org/gnome/shell/keybindings/toggle-message-tray ["'<Shift><Control><Super>c'"]

  # Same behavior as pressing <Super>.
  # - USYNC: Similar to macOS Mission Control.
  # - Default: ['<Super>s']
  #  dconf_write "Keyboard Shortcuts > System > Show the overview: Disabled" \
  #  dconf write /org/gnome/shell/keybindings/toggle-overview '@as []'
  dconf_write "Keyboard Shortcuts > System > Show the overview" \
    dconf write /org/gnome/shell/keybindings/toggle-overview "['<Control><Alt>Down']"

  # - Default: ['<Alt>F2']
  # dconf_write "Keyboard Shortcuts > System > Show the run command prompt: Disabled" \
  # dconf write /org/gnome/mutter/wayland/keybindings/restore-shortcuts '@as []'

}

# Disable all Typing bindings.
# - SAVVY: If you disable Switch-to-next via GUI, it also disables Switch-to-previous.
gnome_settings_customize_keyboard_typing() {
  # - Default: ['<Super>Space']
  dconf_write "Keyboard Shortcuts > Typing > Switch to next input source: Disabled" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-input-source '@as []'

  # - Default: ['<Shift><Super>Space']
  dconf_write "Keyboard Shortcuts > Typing > Switch to previous input source: Disabled" \
    dconf write /org/gnome/desktop/wm/keybindings/switch-input-source-backward '@as []'
}

# FIXME/2025-01-13: Revisit these:
gnome_settings_customize_keyboard_windows() {
  # Bindings:
  #   "Keyboard Shortcuts > Windows > Activates the window menu: <Alt-Space>"
  #   "Keyboard Shortcuts > Windows > Close window: <Alt-F4>"
  #   "Keyboard Shortcuts > Windows > Hide window: <Cmd-h>"
  #   "Keyboard Shortcuts > Windows > Lower window below other windows: Disabled"
  #   "Keyboard Shortcuts > Windows > Maximize window: <Cmd-Up>"
  #   "Keyboard Shortcuts > Windows > Maximize window horizontally: Disabled"
  #   "Keyboard Shortcuts > Windows > Maximize window vertically: Disabled"
  #   "Keyboard Shortcuts > Windows > Move window: <Alt-F7>"
  #   "Keyboard Shortcuts > Windows > Raise window above other windows: Disabled"
  #   "Keyboard Shortcuts > Windows > Raise window if covered, otherwise lower it: Disabled"
  #   "Keyboard Shortcuts > Windows > Resize window: <Alt-F8>"
  #   "Keyboard Shortcuts > Windows > Restore window: <Cmd-Down>"
  #   "Keyboard Shortcuts > Windows > Toggle fullscreen mode: Disabled"
  #   "Keyboard Shortcuts > Windows > Toggle maximization state: <Alt-F10>"
  #   "Keyboard Shortcuts > Windows > Toggle window on all workspaces or one: Disabled"
  #   "Keyboard Shortcuts > Windows > View split on left: <Cmd-Left>"
  #   "Keyboard Shortcuts > Windows > View split on right: <Cmd-Right>"
  :
}

# CXREF: See Ansible task for adding custom keybindings:
#   https://github.com/landonb/zoidy_matecocido#🖥️
#     ~/.kit/ansible/roles/zoidy_matecocido/defaults/main/keybindings.yml
#     ~/.kit/ansible/roles/zoidy_matecocido/tasks/keybinding-circus.yml
#     ~/.kit/ansible/roles/zoidy_matecocido/filter_plugins/to_gvim_keybinding_action.py
gnome_settings_customize_keyboard_custom_shortcuts() {
  :
}

# ***

# Nothing to change.
gnome_settings_customize_printers() {
  :
}

# ***

# Nothing to change.
gnome_settings_customize_removable_media() {
  :
}

# ***

# Nothing to change.
gnome_settings_customize_color() {
  :
}

# +++ END: GNOME Settings GUI settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ GNOME Tweaks GUI settings

# /usr/bin/python3 /usr/bin/gnome-tweaks
gnome_tweaks_customize() {
  echo -e "\n$(highlight_soft "*** GNOME Tweaks")\n"

  gnome_tweaks_customize_general
  gnome_tweaks_customize_appearance
  gnome_tweaks_customize_fonts
  gnome_tweaks_customize_keyboard_and_mouse
  gnome_tweaks_customize_startup_applications
  gnome_tweaks_customize_top_bar
  gnome_tweaks_customize_window_titlebars
  gnome_tweaks_customize_windows
}

# ***

gnome_tweaks_customize_general() {
  # NTRST: When you disable Suspend-when-lid-closed, starts this daemon:
  #   python3 /usr/libexec/gnome-tweak-tool-lid-inhibitor
  # - Which you'll see listed under Tweaks > Startup Applications as
  #   ignore-lid-switch-tweak
  print_at_end+=("\
🔳 Tweaks > General > Suspend when laptop lid is closed > Disable")
}

# ***

gnome_tweaks_customize_appearance() {
  # So that GVim, etc., window titlebars match dark theme.
  # Default: "Adwaita (default)" ('Adwaita')
  gsettings_set "Tweaks > Appearance > Themes > Legacy Applications: " \
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
}

# ***

gnome_tweaks_customize_fonts() {
  if is_hack_font_installed; then
    # Default: Unset (org.gnome.desktop.interface monospace-font-name 'Monospace 11')
    gsettings_set "Tweaks > Fonts > Monospace Text: Hack Nerd Font" \
      gsettings set org.gnome.desktop.interface monospace-font-name 'Hack Nerd Font 11'
  else
    >&2 echo "ALERT: Skipping: Tweaks > Fonts > Monospace Text: Hack Nerd Font"
  fi
}

# ***

# Nothing to change.
gnome_tweaks_customize_keyboard_and_mouse() {
  # This one's cute: Eminate ripples from cursor position
  #   # Tweaks > Keyboard & Mouse > Pointer Location
  #   /org/gnome/desktop/interface/locate-pointer true
  #
  # SAVVY: Tweaks > Keyboard & Mouse > Touchpad > Mouse Click Emulation:
  # ✓ Fingers: Click the touchpad with two fingers for right-click
  #            and three fingers for middle-click.
  # - Area:    Click the bottom right of the touchpad for right-click
  #            and the bottom middle for middle-click.
  # - Disable: Don't use mouse click emulation.
  :
}

# ***

# Nothing to change.
gnome_tweaks_customize_startup_applications() {
  # SAVVY: When you disable Tweaks > General > Suspend when laptop lid is closed
  # you'll see this Startup Application:
  #   ignore-lid-switch-tweak
  :
}

# ***

# Nothing to change.
# - Tweaks > Top Bar > Clock > Weekday: ✗
# - Tweaks > Top Bar > Clock > Date: ✓
# - Tweaks > Top Bar > Clock > Seconds: ✗
# - Tweaks > Top Bar > Calendar > Week Numbers: ✗
gnome_tweaks_customize_top_bar() {
  :
}

# ***

gnome_tweaks_customize_window_titlebars() {
  # Tweaks > Window Titlebars > Titlebar Actions > Double-Click: Toggle Maximize
  # Tweaks > Window Titlebars > Titlebar Actions > Middle-Click: None
  # Tweaks > Window Titlebars > Titlebar Actions > Secondary-Click: Menu

  # Tweaks > Window Titlebars > Titlebar Buttons > Maximize: Disabled
  # - If enabled:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'close,maximize:appmenu'
  #   # OR:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close,maximize'

  # Tweaks > Window Titlebars > Titlebar Buttons > Minimze: Disabled
  # - If enabled:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'
  #   # OR:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,close'
  #   # OR:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'

  # Just close button on left:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'close:appmenu'
  # Close and minimize on left:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'

  # Default: Titlebar Buttons > Placement: Right ('appmenu:close')
  gsettings_set "Tweaks > Window Titlebars > Titlebar Buttons > Placement: Left (like macOS)" \
    gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'
}

# ***

gnome_tweaks_customize_windows() {
  # MAYBE/2025-01-12: Demo disabled Attach Modal Dialogs
  #   gsettings_set "Tweaks > Windows > Attach Modal Dialogs: Disabled" \
  #   gsettings set org.gnome.mutter attach-modal-dialogs false

  # GNOME defaults to Cmd-Drag to move windows, whereas MATE defaults Alt-Drag,
  # which is what author's used to/prefers.
  # - Defaults: Super ('<Alt>'|'disabled'|'<Super>')
  gsettings_set "Tweaks > Windows > Window Action Key: Disabled" \
    gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'
}

# +++ END: GNOME Tweaks GUI settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ GNOME Terminal GUI settings

gnome_terminal_customize() {
  echo -e "\n$(highlight_soft "*** gnome-terminal")\n"

  gnome_terminal_customize_general
  gnome_terminal_customize_shortcuts
  gnome_terminal_customize_profiles_0_text
  gnome_terminal_customize_profiles_0_colors
  gnome_terminal_customize_profiles_0_scrolling
  gnome_terminal_customize_profiles_0_command
  gnome_terminal_customize_compatibility
}

# ***

gnome_terminal_customize_general() {
  # Defaults: Default ('system'), same as 'light'
  # - CALSO: GNOME Terminal: Profiles: Default: Colors: Text and Background Color
  dconf_write "GNOME Terminal > General > Theme variant: Dark" \
    dconf write "/org/gnome/terminal/legacy/theme-variant" 'dark'
}

# ***

# FIXME/2025-01-12: Audit gnome-terminal shortcuts
gnome_terminal_customize_shortcuts() {
  :
}

# ***

# org.gnome.Terminal.ProfilesList default 'b1dcc9dd-5262-4d8d-a863-c897e6d979b9'
# org.gnome.Terminal.ProfilesList list ['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']
# org.gnome.Terminal.Legacy.Settings <key> <val>
# org.gnome.Terminal.Legacy.Keybindings <key> <val>
gnome_terminal_customize_profiles_0_text() {
  # DUNNO: No corresponding gsettings entries?
  # - I.e., no `org.gnome.Terminal.Legacy.Profiles` or `...Profiles:`
  # DUNNO: Note the trailing or leading colon, is that no different than an alphanum,
  # or does it do something special?
  # - E.g.:
  #     /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/font
  #     'Hack Nerd Font Mono 12'
  local profile_id
  profile_id="$(
    gsettings get org.gnome.Terminal.ProfilesList default | sed "s/^'\\(.*\\)'\$/\\1/"
  )"

  if [ -z "${profile_id}" ]; then
    >&2 echo "ERROR: Skipping: GNOME Terminal > Profiles: Default: Could not suss Profile ID"

    exit_1
  fi

  # ***

  if is_hack_font_installed; then
    # Default: Monospace
    dconf_write "GNOME Terminal > Profiles: Default > Text > Text Appearance > Custom font: Hack Nerd Font Mono 11" \
      dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/font" \
      'Hack Nerd Font Mono 11'
  else
    >&2 echo "ALERT: Skipping: GNOME Terminal > Profiles: Default: Text > Text Appearance > Custom font: Hack Nerd Font"
  fi

  # ***

  # Default: 80 columns x 24 rows
  dconf_write "GNOME Terminal > Profiles: Default > Text > Text Appearance > Initial terminal size: 112 columns" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/default-size-columns" '112'

  # Default: 80 columns x 24 rows
  dconf_write "GNOME Terminal > Profiles: Default > Text > Text Appearance > Initial terminal size: 42 rows" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/default-size-rows" '42'

  # ***

  # Default: "Default" ('system'), same as Enabled
  dconf_write "GNOME Terminal > Profiles: Default: Cursor > Cursor blinking: Disabled" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/cursor-blink-mode" 'off'

  # Default: Enabled
  dconf_write "GNOME Terminal: Profiles: Default: Sound: Terminal Bell: Disabled" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/audible-bell" 'false'
}

# ***

gnome_terminal_customize_profiles_0_colors() {
  # Default: Enabled (though with GNOME Dark mode, terminal sill black on white).
  # - CALSO: GNOME Terminal: General: Theme variant: Dark
  dconf_write "GNOME Terminal > Profiles: Default > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/use-theme-colors" 'false'

  dconf_write "GNOME Terminal > Profiles: Default > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/foreground-color" 'rgb(255,255,255)'

  dconf_write "GNOME Terminal > Profiles: Default > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/background-color" 'rgb(0,0,0)'

  # *** I think the XTerm color palette is a little brighter and easier to read
  # than GNOME.

  dconf_write "GNOME Terminal > Profiles: Default > Colors > Palette > Built-in schemes: XTerm" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/palette" \
    "['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,238)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(229,229,229)', 'rgb(127,127,127)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(92,92,255)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
}

# ***

# Nothing to change.
gnome_terminal_customize_profiles_0_scrolling() {
  # Default: Enabled ('always')
  #   dconf_write "GNOME Terminal: Profiles: Default: Scrolling: Show scrollbar: Disabled" \
  #   dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/scrollbar-policy" 'never'

  # Default: 10000
  #   dconf_write "GNOME Terminal: Profiles: Default: Scrolling: Limit scrollback to: 10000" \
  #   dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/scrollback-lines" '10000'
  :
}

# ***

# FIXME/2025-01-12: Add Profiles.
# - GNOME Terminal > Profiles > Command >
#   - ✓ Run a custom command instead of my shell
#   - Custom command: <FIXME- Start Vanilla terminal, etc.>
gnome_terminal_customize_profiles_0_command() {
  :
}

# ***

# Nothing to change.
gnome_terminal_customize_compatibility() {
  :
}

# +++ END: GNOME Terminal GUI settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

firefox_customize() {
  print_at_end+=("\
🔳 Firefox > Startup > ✓ Open previous windows and tabs")
}

# ***

# gsettings get org.gnome.shell enabled-extensions
# ['hidetopbar@mathieu.bidon.ca', 'vim-altTab@kokong.info', 'just-perfection-desktop@just-perfection', 'apps-menu@gnome-shell-extensions.gcampax.github.com', 'browser-tabs@com.github.harshadgavali', 'window-switcher@tbepdb']

# Each Extension uses its own schema, e.g.,:
#   gsettings list-recursively org.gnome.shell.extensions.apps-menu

# - *Hide Top Bar* by *tuxor1337*
#   https://extensions.gnome.org/extension/545/hide-top-bar/
#   https://gitlab.gnome.org/tuxor1337/hidetopbar

gnome_extension_hide_top_bar_customize() {
  # DUNNO: There's no schema for org.gnome.shell.extensions.hidetopbar
  # but you can access it via dconf.

  dconf_write "GNOME Extension > Hide Top Bar > Sensitivity > ✓ Show panel when mouse approaches edge of the screen" \
    dconf write /org/gnome/shell/extensions/hidetopbar/mouse-sensitive true

  dconf_write "GNOME Extension > Hide Top Bar > Intellihide > ✗ Only hide panel when a window takes the space" \
    dconf write /org/gnome/shell/extensions/hidetopbar/enable-intellihide false
}

# ***

gnome_extension_just_perfection_customize() {
  if ! ${LINUX_ONBOARDER_INCLUDE_JUST_PERFECTION:-false}; then

    return
  fi

  # The app icon next to application's menu bar dropdown.
  #   dconf_write "GNOME Extension > Just Perfection > Icons > ✓ App Menu Icon" \
  #   dconf write /org/gnome/shell/extensions/just-perfection/app-menu-icon false

  # Defaults: Center (0), also Right (1), Left (2)
  dconf_write "GNOME Extension > Just Perfection > Customize > Clock Menu Position: Right" \
    dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position 1

  # Defaults: 0, also 1..10
  dconf_write "GNOME Extension > Just Perfection > Customize > Clock Menu Position Offset: 10" \
    dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position-offset 10
}

# ***

gnome_extension_advanced_alt_tab_window_switcher_customize() {
  if ! ${LINUX_ONBOARDER_INCLUDE_AATWS:-false}; then

    return
  fi

  # Defaults: Bottom (3), also Top (1), Center (2)
  dconf_write "GNOME Extension > AATWS > Common > Behavior > Placement: Center" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/switcher-popup-position 2

  # Defaults: Show Above/Below Item (2), also Top (1), Show Centered (3)
  dconf_write "GNOME Extension > AATWS > Common > Appearance and Content > Tooltip Titles: Disable" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/switcher-popup-tooltip-title 1

  # Defaults: false
  dconf_write "GNOME Extension > AATWS > Window Switcher > Behavior > Skip Minimized Windows: Enable" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/win-switch-skip-minimized true

  # Defaults: true
  dconf_write "GNOME Extension > AATWS > App Switcher > Behavior > Include Favorite (Pinned) Apps: Disable" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/app-switcher-popup-fav-apps false

  # Defaults: true
  dconf_write "GNOME Extension > AATWS > App Switcher > Behavior > Include Show Apps Icon: Disable" \
    dconf write \
    /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/app-switcher-popup-include-show-apps-icon false

  # Defaults: false
  dconf_write "GNOME Extension > AATWS > App Switcher > Appearance > Hide Window Count For Single-Window Apps: Enable" \
    dconf write \
    /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/app-switcher-popup-hide-win-counter-for-single-window \
    true
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# FIXME/2025-03-09: Setup locatedb on Debian.
locatedb_configure() {
  print_at_end+=("\
🔳 CLI: Create \`locate\` database:

   - FIXME/2025-03-09: This command untested on Debian:

     \`sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist\`

   - AWAIT: This command takes a moment

     - TRACK: \`ps aux | grep locate.updatedb\`

     - NTHEN: Test: \`locate something\`")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

pass_configure() {
  print_at_end+=("$(
    cat <<'EOF'
🔳 Setup Crypto Tools :: Setup Password Store :: aka Initialize `pass`:

   - Generate a new key:

       gpg --full-generate-key

   - Get the key UID:

       GPG_ID=$(gpg --list-secret-keys | awk 'NR == 2 {print}')

     Or, if you have other keys, specify the email you used:

       GPG_ID=$(gpg --list-secret-keys user@host | awk 'NR == 2 {print}')

   - Use the key to initialize `~/.password-store/.gpg-id`:

       pass init ${GPG_ID}

EOF
  )")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

slather_gnome_gsettings() {
  local dry_run=false
  local cnt_run=false
  local diff_run=false

  # ***

  while [ "$1" != '' ]; do
    case $1 in
    --dry-run)
      dry_run=true
      shift
      ;;
    --cnt-run)
      cnt_run=true
      shift
      ;;
    --diff)
      dry_run=true
      diff_run=true
      shift
      ;;
    *) shift ;;
    esac
  done

  if [ -z "${LINUX_ONBOARDER_DISTROS}" ]; then
    reset_linux_onboarder_distro_ids
  fi

  if [ -z "${LINUX_ONBOARDER_DESKTOPS}" ]; then
    reset_linux_onboarder_desktop_ids
  fi

  # ***

  if ${cnt_run}; then
    local cnt_dconf_write=0
    local cnt_gsettings_set=0

    count_it
  elif ${dry_run}; then
    fake_it
  fi

  check_deps ${dry_run}

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  insist_is_supported_distro_unless_dry_run ${dry_run}

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  gnome_settings_close ${dry_run}

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  echo "Slathering gsettings..."

  local print_at_end=() # 🔳 ◻

  slather_settings

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  print_manual_task_reminders

  # ***

  print_cnt_run_report
}

# ***

slather_settings() {

  gnome_settings_customize

  gnome_tweaks_customize

  gnome_terminal_customize

  firefox_customize

  echo -e "\n$(highlight_soft "*** GNOME Shell extensions")\n"

  gnome_extension_hide_top_bar_customize

  gnome_extension_just_perfection_customize

  gnome_extension_advanced_alt_tab_window_switcher_customize

  # ***

  locatedb_configure

  pass_configure
}

# ***

print_manual_task_reminders() {
  if ${diff_run}; then

    return
  fi

  if [ -z "${print_at_end}" ]; then

    return
  fi

  echo
  echo "CPYST: Please perform the following tasks manually:"
  echo

  for print_ln in "${print_at_end[@]}"; do
    echo -e "${print_ln}\n"
  done

  echo "Good luck!"
}

# ***

print_cnt_run_report() {
  if ! ${cnt_run}; then

    return 0
  fi

  echo "Settings counts:"
  printf "%-22s%2s\n" "- # dconf write's:" "${cnt_dconf_write}"
  printf "%-22s%2s\n" "- # gsettings set's:" "${cnt_gsettings_set}"
  printf "%-22s%2s\n" "- # Manual tasks:" "${#print_at_end[@]}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

source_dep_local() {
  local rel_path="$1"

  local bin_dir="$(dirname -- "$(realpath -- "$0")")"

  if . "${bin_dir}/../${rel_path}"; then

    return 0
  fi

  >&2 echo "ERROR: Could not locate dependency: ${rel_path}"
  >&2 echo "- It should be relative parent dir: ${base_dir}"

  return 1
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

clear_traps() {
  trap - EXIT INT
}

set_traps() {
  trap -- trap_exit EXIT
  trap -- trap_int INT
}

exit_0() {
  clear_traps

  exit 0
}

exit_1() {
  clear_traps

  exit 1
}

trap_exit() {
  clear_traps

  # USAGE: Alert on unexpected error path, so you can add happy path.
  >&2 echo "ALERT: "$(basename -- "$0")" exited abnormally!"
  >&2 echo "- Hint: Enable \`set -x\` and run again..."

  exit 2
}

trap_int() {
  clear_traps

  exit 3
}

# ***

main() {
  set -e

  set_traps

  slather_gnome_gsettings "$@"

  clear_traps
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  # Being executed.
  main "$@"
fi
