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

  gnome_settings_customize_displays
  gnome_settings_customize_sound
  gnome_settings_customize_power_general
  gnome_settings_customize_power_power_saving
  gnome_settings_customize_power_hidden
  gnome_settings_customize_multitasking
  gnome_settings_customize_appearance

  gnome_settings_customize_apps
  gnome_settings_customize_notifications
  gnome_settings_customize_search
  gnome_settings_customize_online_accounts
  gnome_settings_customize_sharing
  gnome_settings_customize_wellbeing

  gnome_settings_customize_mouse_and_touchpad
  gnome_settings_customize_keyboard
  gnome_settings_customize_color
  gnome_settings_customize_printers

  gnome_settings_customize_accessibility
  gnome_settings_customize_privacy
  gnome_settings_customize_system
}

#     ========
# *** DISPLAYS
#     ========

# Nothing to change.
# - Orientation
# - Resolution
# - Refresh Rate
# - Scale
# - Night Light
gnome_settings_customize_displays() {
  :
}

#     ==========
# *** APPEARANCE
#     ==========

gnome_settings_customize_appearance() {
  # Appearance > Style: Default ('default') or Dark ('prefer-dark')
  # - Default: 'default' (at least in GNOME Shell 43).
  gsettings_set "Settings > Appearance > Style" \
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  # Appearance > Accent Color
  # - GUI: Blue, Teal, Green, Yellow, Orange, Red, Pink, Purple, Slate
  #   - Setting value is lowercased color name.
  gsettings_set "Settings > Appearance > Accent Color" \
    gsettings set org.gnome.desktop.interface accent-color 'blue'

  # ***

  local menu_path="Settings > Appearance > Background [Hidden]"

  # The GNOME Shell 43 GUI lets you select from 26 different background
  # images and color settings, or you can set your own image.
  # - GNOME Shell 48 shows 38 images.
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

  # Other org.gnome.desktop.background options:
  #   picture-opacity 100
  #   picture-uri 'file:///usr/share/images/desktop-base/desktop-background.xml'
  #   picture-uri-dark 'file:///usr/share/backgrounds/gnome/adwaita-d.webp'
  #   show-desktop-icons false

  # Default: 'solid', but using GUI may change, e.g., to 'horizontal'.
  gsettings_set "${menu_path} > Color Shading Type" \
    gsettings set org.gnome.desktop.background color-shading-type 'solid'

  # Default: 'zoom', but using GUI may change, e.g., to 'zoom'.
  # - Doesn't matter when used with solid color, so leave
  #   at 'zoom', which is what Settings changes it to, so
  #   that ./slather-gsettings.sh --dry-run doesn't diff.
  gsettings_set "${menu_path} > Picture Options" \
    gsettings set org.gnome.desktop.background picture-options 'zoom'

  # SAVVY: Very dark "green", slight contrast with borderless Chrome windows.
  # - Vs. black:
  #   gsettings_set "Settings > Appearance > Background > Primary Color" \
  #     gsettings set org.gnome.desktop.background primary-color '#000000'
  gsettings_set "${menu_path} > Primary Color" \
    gsettings set org.gnome.desktop.background primary-color '#021003'

  gsettings_set "${menu_path} > Secondary Color" \
    gsettings set org.gnome.desktop.background secondary-color '#000000'
}

#     ============
# *** MULTITASKING
#     ============

gnome_settings_customize_multitasking() {
  # Disable the top-left hot corner, which author triggers inadvertently too often.
  # - A better mechanism (IMO) is the (innovative, IMO) <Cmd> keybinding.
  # "Touch the top-left corner to open the Activies Overview"
  # - Default: true
  gsettings_set "Settings > Multitasking > General > Hot Corner" \
    gsettings set org.gnome.desktop.interface enable-hot-corners false

  # "Drag windows against the top, left, and right screen edges to resize them"
  # - Default: true
  gsettings_set "Settings > Multitasking > General > Active Screen Edges" \
    gsettings set org.gnome.mutter edge-tiling true

  # Workspaces options:
  # - Dynamic Workspaces [default]
  #   "Automatically removes empty workspaces"
  # - Fixed Number of Workspaces
  #   "Specify a number of permanent workspaces"
  #   - Number of Workspaces [default: 4]
  gsettings_set "Settings > Multitasking > General > Dynamic Workspaces" \
    gsettings set org.gnome.mutter dynamic-workspaces true
  gsettings_set "Settings > Multitasking > General > Number of Workspaces" \
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

  # Multi-Monitor options:
  # - Workspaces on primary display only [default]
  # - Workspaces on all displays
  gsettings_set "Settings > Multitasking > General > Number of Workspaces" \
    gsettings set org.gnome.mutter workspaces-only-on-primary true

  # App Switching options:
  # - Include apps from all workspaces [default]
  # - Include apps from the current workspace only
  local widget_path="Settings > Multitasking > App Switching"
  gsettings_set "${widget_path} > Include apps from the current workspace only" \
    gsettings set org.gnome.shell.app-switcher current-workspace-only true
}

#     ====
# *** APPS
#     ====

# Nothing to change.
# - Default Apps / "Set which apps open links, files, and media"
#   - Default Apps
#     - Default Apps
#       - Web: Fussy
#       - Mail: Evolution Mail and Calendar
#       - Calendar: Calendar
#       - Music: Videos
#       - Video: Videos
#       - Photos: Image Viewer
#     - Removable Media
#       - Media Autostart: Disabled
#         - "Start apps or prompt when media is connected"
#         - /org/gnome/desktop/media-handling/autorun-never true
#       - CD Audio: Ask what to do
#       - DVD Video: Ask what to do
#       - Music Player: Ask what to do
#       - Photos: Ask what to do
#       - Software: Ask what to do
#       - Other Media Types
# - 2048
#   - [ Open] / [ App Details ]
#   - Permissions > Notifications "Show system notifications" > ✓ Enabled
# - Advanced Network Configuration
#   - Etc.
# - AisleRiot Solitaire
# - (Etc.; List of Apps)
gnome_settings_customize_apps() {
  :
}

#     =============
# *** NOTIFICATIONS
#     =============

gnome_settings_customize_notifications() {
  # Default: false
  gsettings_set "Settings > Notifications > Do Not Disturb: Disabled" \
    gsettings set org.gnome.desktop.notifications show-banners false

  # Default: true
  # - Off. It's not like it's a mobile phone. Either I'm logged on,
  #   or I'm not in front of the display. Also, I don't like a noisy
  #   lock screen.
  gsettings_set "Settings > Notifications > Lock Screen Notifications: Disabled" \
    gsettings set org.gnome.desktop.notifications show-in-lock-screen false

  # Settings > Notifications > App Notifications
  # - A list of apps (though not as inclusive a list as the Apps menu list).
  # - E.g.:
  #   - Artha
  #     - Notifications / "Show in notifications list": Enabled
  #     - Sound / "Allow notification sounds from app": Enabled
  #     - Banners > Show Banners / "Show notifications above apps": Enabled
  #     - Banners > Show Content / "Include msg details in notif banners": Disabled
  #     - Lock Screen > Show Banners / "Show notifications on lock screen": Enabled
  #     - Lock Screen > Show Content / "Include message details on lock screen": Disabled
}

#     ======
# *** SEARCH
#     ======

gnome_settings_customize_search() {
  # "Include app-provided search results"
  # - Default: Enabled (false)
  gsettings_set "Settings > Search > App Search: Enabled" \
    gsettings set org.gnome.desktop.search-providers disable-external false

  # Search > Search Locations
  # - "Filesystem locations which are searched by system apps"
  #   - Search > Search Locations:
  #   - Default Locations
  #     - ✓ Home, ✓ Documents, ✓ Downloads, ✓ Music, ✓ Pictures, ✓ Videos
  #   - Bookmarked Locations
  #     - List of ~/.config/gtk-3.0/bookmarks [each disabled by default]
  #   - Custom Locations
  #     - Desktop
  #     - [ + Add Location ]

  # Search > Search Results
  # - Ordered list of sources: Contacts, Files, Calculator, etc.
  #   - Each enabled by default except Weather.
}

#     ===============
# *** ONLINE ACCOUNTS
#     ===============

# Nothing to change.
gnome_settings_customize_online_accounts() {
  # Settings > Online Accounts > Conntect an Account
  # - List of services: Nextcloud, Google, Microsoft, etc.
  print_at_end+=("\
🔳 Settings > Online Accounts > Add an account
   - Wire a cloud account to enable, e.g., GNOME Calendar & Email apps
   - Providers: Google, Nextcloud, Microsoft, Microsoft Exchange,
                Last.fm, IMAP and SMTP, Enterprise Login (Kerberos)")
}

#     =======
# *** SHARING
#     =======

gnome_settings_customize_sharing() {
  # Nothing to change.
  :

  # Settings > Sharing > Device Name: (Lets you edit hostname)

  # Settings > Sharing > File Sharing > Off
  #
  # Settings > Sharing > Media Sharing > Off
  #
  # By GNOME Shell 48, Remote Desktop and Remote Login
  # options were move to Settings > System.
}

#     =========
# *** WELLBEING
#     =========

gnome_settings_customize_wellbeing() {
  # Settings > Wellbeing > Screen Time
  # - Shows screen time for today and this wee,
  #   and a bar chart for the week.
  #   - DUNNO: Author sees full, 24h bars for each day.

  # ***

  gsettings_set "Settings > Wellbeing > Screen Limits: Screen Time Limit: Disabled" \
    gsettings set org.gnome.desktop.screen-time-limits daily-limit-enabled false
  # Enabling Screen Time Limit also sets application-children, possibly
  # like this, but not necessarily exactly the same "application-children"
  # (so we won't futz with it):
  if false; then
    gsettings_set "Settings > Wellbeing > Screen Limits > Screen Time Limit: application-children" \
      gsettings set org.gnome.desktop.notifications application-children "['gnome-initial-setup', 'org-gnome-software', 'gnome-network-panel', 'firefox-esr', 'alacritty', 'google-chrome', 'gvim', 'org-gnome-settings', 'org-gnome-nautilus', 'libreoffice-startcenter', 'com-github-lyude-neovim-gtk', 'spotify', 'org-gnome-terminal', 'slack-slack', 'org-gnome-extensions', 'gnome-wellbeing-panel', 'io-snapcraft-sessionagent']"
  fi

  # Defaults: 8 hours (28800) / Widget: +/- 1 hr. (3600) and +/- 15 min. (+/- 900)
  gsettings_set "Settings > Wellbeing > Screen Limits > Daily Limit: 8 hours" \
    gsettings set org.gnome.desktop.screen-time-limits daily-limit-seconds 28800

  # "Black and white screen for screen limits"
  # - Default: Enabled (if Screem Time Limit enabled)
  gsettings_set "Settings > Wellbeing > Screen Limits > Grayscale: Enabled" \
    gsettings set org.gnome.desktop.screen-time-limits grayscale true

  # ***

  # "Reminders to look away from the screen" / Default: Disabled
  gsettings_set "Settings > Wellbeing > Break Reminders > Eyesight Reminders: Disabled" \
    gsettings set org.gnome.desktop.break-reminders selected-breaks '@as []'
  # gsettings set org.gnome.desktop.break-reminders selected-breaks "['eyesight']"

  # "Reminders to move around" / Default: Disabled
  gsettings_set "Settings > Wellbeing > Break Reminders > Movement Reminders: Disabled" \
    gsettings set org.gnome.desktop.break-reminders selected-breaks '@as []'
  # gsettings set org.gnome.desktop.break-reminders selected-breaks "['movement']"

  # Default: "5 minutes / 30 minutes"
  # - Opts:
  #   - 1 min / 20 mins (60 / 1200)
  #   - 2 mins / 20 mins (120 / 1200)
  #   - 3 mins / 30 mins (180 / 1800)
  #   - 5 mins / 30 mins (300 / 1800) [default]
  gsettings_set "Settings > Wellbeing > Break Reminders > Movement Break Schedule: 5 mins / 30 mins" \
    gsettings set org.gnome.desktop.break-reminders.movement duration-seconds 'uint32 300'
  gsettings_set "Settings > Wellbeing > Break Reminders > Movement Break Schedule: 5 mins / 30 mins" \
    gsettings set org.gnome.desktop.break-reminders.movement interval-seconds 'uint32 1800'

  # "Play a sound when a break ends" / Default: Enabled (if a Reminder enabled)
  gsettings_set "Settings > Wellbeing > Break Reminders > Sounds: Enabled" \
    gsettings set org.gnome.desktop.break-reminders.movement play-sound true
}

#     ================
# *** MOUSE & TOUCHPAD
#     ================

gnome_settings_customize_mouse_and_touchpad() {
  # Mouse & Touchpad > Mouse > General > Primary Button: Left (default) | Right
  gsettings_set "Settings > Mouse & Touchpad > Mouse > General > Primary Button: ✓ Left | Right" \
    gsettings set org.gnome.desktop.peripherals.mouse left-handed false

  # Mouse & Touchpad > Mouse > Mouse > Pointer Speed: [Slow..Fast slider]
  # - I mean, -0.4, really...
  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Pointer Speed: [Slow..X.......Fast]" \
    gsettings set org.gnome.desktop.peripherals.mouse speed -0.396396396396396

  # Default: Enabled ('default') / Disabled ('flat')
  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Mouse Acceleration: Enabled" \
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'default'

  # Default: Traditional "Scrolling moves the view" / Natural "Scrolling moves the content"
  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Scroll Direction: Traditional" \
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false

  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Double-Click Speed [Hidden]: 400" \
    gsettings set org.gnome.desktop.peripherals.mouse double-click 400

  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Drag Threshold [Hidden]: 400" \
    gsettings set org.gnome.desktop.peripherals.mouse drag-threshold 8

  # CALSO: Tweaks > Keyboard & Mouse > Mouse Click Emulation
  #   org.gnome.desktop.peripherals.mouse middle-click-emulation false
}

#     ==================
# *** PRIVACY & SECURITY
#     ==================

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
  local menu_path="Settings > Privacy & Security > System > Screen Lock"

  # Blank Screen Delay / "Period of inactivity until screen blanks"
  # - Default: 5 minutes (uint32 300)
  # - GUI dropdown: 1..5 minutes (60..300), 8/10/12/15 minutes
  #   (480/600/720/900) [default: 5 minutes (uint32 300)]
  # - CALSO: #_idle_delay: Same settings under:
  #   - Power > Power Saving > Automatic Screen Blank > Delay
  gsettings_set "${menu_path} > Blank Screen Delay: 8 mins" \
    gsettings set org.gnome.desktop.session idle-delay 'uint32 480'

  # Default: Enabled (true)
  gsettings_set "${menu_path} > Automatic Screen Lock" \
    gsettings set org.gnome.desktop.screensaver lock-enabled true

  # Note the GUI only lets you set up to 1 hour.
  # - When it's unrecognized, drop-down shows "Screen Turns Off"
  # - Default: Disabled (uint32 0)
  # - 1 hour:
  #   gsettings_set "Settings > Privacy > Screen > Screen Lock > Automatic Screen Lock Delay: 1 hour" \
  #     gsettings set org.gnome.desktop.screensaver lock-delay 3600
  # - REFER: For hosts at home, author prefers at least 4 hours (14400).
  #   - Sensible timeouts: 4h 14400, 4⅓h 15600, 6h 21600, 6⅔h 24000, 8h 28800.
  gsettings_set "${menu_path} > Automatic Screen Lock Delay: 4 hours" \
    gsettings set org.gnome.desktop.screensaver lock-delay 'uint32 24000'
  # TRACK/2025-01-12: Something is causing Settings to become unresponsive...
  # - BWARE: Or not: Using custom lock-delay makes Settings unresponsive within
  # - seconds of starting Settings app, e.g., if you run this manually:
  #     gsettings set org.gnome.desktop.screensaver lock-delay 14400
  # - DUNNO/2025-01-12: Working again after reboot, albeit with 3600 value.

  # Default: Disabled (false)
  gsettings_set "${menu_path} > Lock Screen Notifications" \
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
# SAVVY: Debian 13 enables auto-delete /tmp and /var/tmp by default.
gnome_settings_customize_privacy_file_history_and_trash() {
  local menu_path="Settings > Privacy & Security > System > File History & Trash"

  # Default: Enabled (true)
  gsettings_set "${menu_path} > File History > File History" \
    gsettings set org.gnome.desktop.privacy remember-recent-files true

  # Default: Forever (-1) / Other GUI opts: 1 day (1), 7 days (7), 30 days (30)
  gsettings_set "${menu_path} > File History > File History Duration" \
    gsettings set org.gnome.desktop.privacy recent-files-max-age -1

  # ***

  # Default: Disabled
  gsettings_set "${menu_path} > Trash & Temporary Files > Automatically Empty Trash" \
    gsettings set org.gnome.desktop.privacy remove-old-trash-files false

  # Default: Disabled
  gsettings_set "${menu_path} > Trash & Temporary Files > Automatically Delete Temporary Files" \
    gsettings set org.gnome.desktop.privacy remove-old-temp-files false

  # Default: 30 days (30) / Other GUI: 1 hour (0), 1 day..7 days (1..7), 14 days (14)
  gsettings_set "${menu_path} > Trash & Temporary Files > Automatic Deletion Period" \
    gsettings set org.gnome.desktop.privacy old-files-age 'uint32 30'
}

#     =====
# *** SOUND
#     =====

# Nothing to change.
# - Output
#   - Output Device
#   - Output Volume
#   - Balance
# - Input
#   - Input Device
#   - Input Volume
# - Sounds
#   - Volume Levels
#   - Alert Sound
gnome_settings_customize_sound() {
  # SAVVY: Not stored in gsettings (`dconf watch /` doesn't report on it).
  print_at_end+=("\
🔳 Settings > Sound > Sounds > Alert Sound > Click|String|Swing|Hum (maybe Click?)")
}

#     =====
# *** POWER
#     =====

gnome_settings_customize_power_general() {
  # GUI: Battery Levels shows horizontal level meters:
  #   Battery Levels > Fully charged
  #   Battery Levels > Main 🔋
  #   Battery Levels > Extra 🔋

  # Battery Charging options:
  # - Maximize Charge [default]
  #   - "Uses all battery capacity. Degrades batteries more quickly."
  # - Preserve Battery Health
  #   - "Increases battery longetivity by maintaining lower charge levels"
  print_at_end+=("\
🔳 Settings > Power > General > Battery Charging > ✓ Preserve Battery Health")

  # GUI: Connected Devices shows horizontal device battery level meters,
  # e.g.,
  #   Connected Devices > Logitech Wireless Mouse 🌡️

  # GUI: Power Mode options:
  # - Performance
  #   - "High performance and power usage"
  # - Balanced [default]
  #   - "Standard performance and power usage"
  # - Power Saver
  #   - "Reduced performance and power usage"
  #
  # Changing this changes /org/gnome/shell/last-selected-power-profile
  # but I only saw it change to 'performance' and 'power-saver', not
  # 'balanced' (or whatever); plus the key name suggests that setting
  # is not this setting.
  print_at_end+=("\
🔳 Settings > Power > General > Power Mode > ✓ Balanced")

  # Power Button Behavior:
  # - Suspend: 'suspend' [Default]
  # - Power Off: 'interactive'
  # - Nothing: 'nothing'
  # Author almost never uses power button, so might as well prompt,
  # so nothing too jarring happens.
  gsettings_set "Settings > Power > General > General > Power Button Behavior > Power Off" \
    gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'

  # "Show exact charge level in the top bar"
  # - Author uses Hide Top Bar extension, so this adds information
  #   without cluttering the display or trying to steal my attention.
  gsettings_set "Settings > Power > General > General > ✓ Show Battery Percentage" \
    gsettings set org.gnome.desktop.interface show-battery-percentage true
}

gnome_settings_customize_power_power_saving() {
  local menu_path="Settings > Powers > Power Saving"

  # "Turn on power saver mode when battery power is low"
  # Default: Enabled (true)
  gsettings_set "${menu_path} > Automatic Power Saver" \
    gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery true

  # "Turn the screen off after a period of inactivity"
  # - Toggle default: Enabled (uint32 300) / Disabled: uint32 0
  # - "Delay" dropdown: 1..5 minutes (60..300), 8/10/12/15
  #   minutes (480/600/720/900) [default: 5 minutes (uint32 300)]
  # - CALSO: #_idle_delay: Same setting under:
  #   - Privacy > Screen Lock #_idle_delay
  gsettings_set "${menu_path} > Automatic Screen Blank" \
    gsettings set org.gnome.desktop.session idle-delay 'uint32 480'

  # Automatic Suspend > On Batter Power:
  # - Enabled ('suspend') / Disabled: 'nothing'
  # - "Delay" dropdown: 15/20/25/30/45 minutes (900/1200/1500/1800/2700),
  #   1 hour (3600), 1 hour 20/30/40 mins (4800/5400/6000), 2 hrs (7200)
  # - Default: Enabled, 20 minutes ('suspend', 1200)
  gsettings_set "${menu_path} > Automatic Suspend > On Battery Power: Enabled" \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
  gsettings_set "${menu_path} > Automatic Suspend > (On Battery Power) Delay: 30 mins." \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800

  # Automatic Suspend > When Plugged In:
  # - Enabled ('suspend') / Disabled: 'nothing'
  # - Same "Delay" dropdown options as "On Battery Power > Delay".
  # - Default: Enabled, 20 minutes ('suspend', 1200) [I think?]
  gsettings_set "${menu_path} > Automatic Suspend > When Plugged In: Disabled" \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
  gsettings_set "${menu_path} > Automatic Suspend > (When Plugged In) Delay: 15 mins." \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 900
}

# Hidden Power settings.
#
#   $ gsettings list-recursively org.gnome.settings-daemon.plugins.power
#   org.gnome.settings-daemon.plugins.power ambient-enabled true
#   org.gnome.settings-daemon.plugins.power idle-brightness 30
#   org.gnome.settings-daemon.plugins.power idle-dim true
#   ...
#
gnome_settings_customize_power_hidden() {
  local menu_path="Settings > Powers > [Hidden]"

  # DUNNO: Author doesn't seen screen dim in GNOME Shell 48, it's just out.
  # Default: Enabled (true)
  gsettings_set "${menu_path} > Dim Screen" \
    gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
}

#     ==================
# *** KEYBOARD SHORTCUTS
#     ==================

gnome_settings_customize_keyboard() {
  echo -e "\n$(
    highlight_soft \
      "**** GNOME Settings > Keyboard > Keyboard Shortcuts > View and Customize Shortcuts"
  )\n"

  # Settings > Keyboard > Input Sources
  # - English
  # - [ + Add Input Source ]

  # Settings > Keyboard > Input Source Switching
  # - ✓ Use the source source for all windows [default]
  # -   Switch input sources individually for each window

  # Settings > Keyboard > Special Character Entry
  # - Alternate Characters Key: ✓ Default
  #   - Other opts: None, Left|Right Alt, Left|Right Super, Menu key, Right Ctrl
  # - Compose Key: Disabled
  #   - Other opts: None, Left|Right Super, Menu key, Left|Right Ctrl,
  #     Caps|Scroll Lock, Print Screen, Insert

  # Settings > Keyboard > Keyboard Shortcuts > View and Customize Shortcuts
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
  #   # BNDNG: <Cmd-Alt-S>
  #   "Keyboard Shortcuts > Accessibility > Turn screen-reader on or off: ['<Super><Alt>s']
  #   # BNDNG: <Cmd-Alt-8>
  #   "Keyboard Shortcuts > Accessibility > Turn zoom on or off: ['<Super><Alt>8']
  #   # BNDNG: <Cmd-Alt-=>
  #   "Keyboard Shortcuts > Accessibility > Zoom in: ['<Super><Alt>=']
  #   # BNDNG: <Cmd-Alt-->
  #   "Keyboard Shortcuts > Accessibility > Zoom out: ['<Super><Alt>-']
  :
}

# These all default disabled except for Launch help browser.
# - Bindings:
#     Home folder
#     Launch calculator
#     Launch email client
#     Launch help browser [default: <Cmd-F1>]
#     Launch web browser
#     Search
#     Settings
gnome_settings_customize_keyboard_launchers() {
  # Defaults <Cmd-F1> — ['<Super>F1']
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

  # Author doesn't assign Print to any key on my keyboard,
  # so the screenshot defaults are not useful.
  # - Default: ['<Shift>Print']
  dconf_write "Keyboard Shortcuts > Screenshots > Take a screenshot: Disabled" \
    dconf write /org/gnome/shell/keybindings/screenshot '@as []'

  # - Default: ['Print']
  dconf_write "Keyboard Shortcuts > Screenshots > Take a screenshot interactively: Disabled" \
    dconf write /org/gnome/shell/keybindings/show-screenshot-ui '@as []'

  # - Default: ['<Alt>Print']
  dconf_write "Keyboard Shortcuts > Screenshots > Take a screenshot of a window: Disabled" \
    dconf write /org/gnome/shell/keybindings/screenshot-window '@as []'
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
  # Focus the active notification
  # - Default: ['<Super>n']
  # - DUNNO: Pressing <Cmd-N> doesn't do anything for the author...
  dconf_write "Keyboard Shortcuts > System > Focus the active notification: Disabled" \
    dconf write /org/gnome/shell/keybindings/focus-active-notification '@as []'

  # Lock screen
  # - Default: ['<Super>l']
  # - BNDNG: <Ctrl-Cmd-Q>
  dconf_write "Keyboard Shortcuts > System > Lock screen" \
    dconf write /org/gnome/settings-daemon/plugins/media-keys/screensaver "['<Control><Super>q']"

  # Log out
  # - Default: ['<Control><Alt>Delete']
  #
  # dconf_write "Keyboard Shortcuts > System > Log out: Disabled" \
  #   dconf write /org/gnome/settings-daemon/plugins/media-keys/logout "['<Control><Alt>Delete']"

  # Open the quick settings menu
  # - Default: ['<Super>s']
  # - DUNNO: Does nothing for the author (literally, not figuratively).
  # - Prev. to GNOME Shell 48, I think this was Open the application menu, <Cmd-F10>.
  dconf_write "Keyboard Shortcuts > System > Open the quick settings menu: Disabled" \
    dconf write /org/gnome/shell/keybindings/toggle-quick-settings '@as []'

  # Power off
  # - Default: Disabled
  dconf_write "Keyboard Shortcuts > System > Power off: Disabled" \
    dconf reset /org/gnome/settings-daemon/plugins/media-keys/shutdown

  # Restart
  # - Default: Disabled
  dconf_write "Keyboard Shortcuts > System > Restart: Disabled" \
    dconf reset /org/gnome/settings-daemon/plugins/media-keys/reboot

  # Restore the keyboard shortcuts
  # - Default: ['<Super>Escape']
  #
  # dconf_write "Keyboard Shortcuts > System > Restore the keyboard shortcuts: Disabled" \
  #   dconf write /org/gnome/mutter/wayland/keybindings/restore-shortcuts '@as []'

  # Show all apps
  # - Default: ['<Super>a']
  # - ISOFF: This shows the Overview application list.
  #   - It's the same as <Cmd> to show Overview, then clicking the 3x3 dots icon (⁙).
  dconf_write "Keyboard Shortcuts > System > Show all apps: Disabled" \
    dconf write /org/gnome/shell/keybindings/toggle-application-view '@as []'

  # Show the notification list
  # - Default: ['<Super>v']
  # - If no notifications, doesn't do anything.
  #   - SAVVY: If Top Bar is hidden, does nothing.
  #     - So roll your mouse to the top of the screen to reveal Top
  #       Bar, and then this binding works. (But at that point, you
  #       could just as easily click the clock to show 'em.)
  # - To disable instead:
  #   dconf_write "Keyboard Shortcuts > System > Show the notification list: Disabled" \
  #     dconf write /org/gnome/shell/keybindings/toggle-message-tray '@as []'
  # BNDNG: <Shift-Ctrl-Cmd-C>
  # - USYNC: Same binding as author uses to Show Notification Center on macOS.
  dconf_write "Keyboard Shortcuts > System > Show the notification list" \
    dconf write /org/gnome/shell/keybindings/toggle-message-tray ["'<Shift><Control><Super>c'"]

  # Show the overview
  # - Same behavior as pressing <Super>.
  #   - Or pressing the top-left button in the Top Bar.
  # - Default: ['<Super>s']
  # - To disable instead:
  #   dconf_write "Keyboard Shortcuts > System > Show the overview: Disabled" \
  #     dconf write /org/gnome/shell/keybindings/toggle-overview '@as []'
  # - BNDNG: <Ctrl-Alt-Down>
  #   - USYNC: Same keybinding as author uses for macOS Mission Control.
  dconf_write "Keyboard Shortcuts > System > Show the overview" \
    dconf write /org/gnome/shell/keybindings/toggle-overview "['<Control><Alt>Down']"

  # Show the run command prompt
  # - Default: ['<Alt>F2']
  #
  # dconf_write "Keyboard Shortcuts > System > Show the run command prompt: Disabled" \
  #   dconf write /org/gnome/mutter/wayland/keybindings/restore-shortcuts '@as []'
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

#     ================
# *** COLOR MANAGEMENT
#     ================

# Nothing to change.
gnome_settings_customize_color() {
  :
}

#     ========
# *** PRINTERS
#     ========

# Nothing to change.
gnome_settings_customize_printers() {
  :
}

#     ====
# *** A11Y
#     ====

# Nothing to change.
gnome_settings_customize_accessibility() {
  # "Display the accessibility menu in the top bar"
  # - Default: Disabled
  gsettings_set "Settings > Accessibility > Always Show Accessibility Menu: Disabled" \
    gsettings set org.gnome.desktop.a11y always-show-universal-access-status false

  # And then lots on interesting options, seems very robust.
}

#     ======
# *** SYSTEM
#     ======

gnome_settings_customize_system() {
  # Settings > System > Region & Language
  # - Settings > System > Region & Language > Language: English (US)
  # - Settings > System > Region & Language > Formats: US (English)

  # "Requires location services enabled and internet access" [Default disabled]
  gsettings_set "Settings > System > Date & Time > ✓ Automatic Time Zone" \
    gsettings set org.gnome.desktop.datetime automatic-timezone true

  # Default: 12-hour ('12h') / 24-hour ('24h')
  gsettings_set "Settings > System > Date & Time > Time Format: 24-hour" \
    gsettings set org.gnome.desktop.interface clock-format '24h'
  #
  # SAVVY: (For reasons unknown) Use dconf here, not gsettings.
  #   $ dconf read /org/gtk/settings/file-chooser/clock-format
  #   '24h'
  #   $ gsettings get org.gtk.settings.file-chooser clock-format
  #   No such schema “org.gtk.settings.file-chooser”
  #   $ gsettings_set "Settings > System > Date & Time > Time Format: 24-hour" \
  #       gsettings set org.gtk.settings.file-chooser clock-format '24h'
  #   $ No such schema “org.gtk.settings.file-chooser”
  dconf_write "Settings > System > Date & Time > Time Format: 24-hour" \
    dconf write /org/gtk/settings/file-chooser/clock-format '24h'

  # Default: Disabled
  gsettings_set "Settings > System > Date & Time > Clock & Calendar > ✓ Week Day" \
    gsettings set org.gnome.desktop.interface clock-show-weekday true

  # Default: Enabled
  gsettings_set "Settings > System > Date & Time > Clock & Calendar > ✓ Date" \
    gsettings set org.gnome.desktop.interface clock-show-date true

  # Default: Disabled
  gsettings_set "Settings > System > Date & Time > Clock & Calendar > ∅ Seconds" \
    gsettings set org.gnome.desktop.interface clock-show-seconds false

  # "Show in the dropdown calendar"
  # - Default: Disabled
  # - OYEAH: Just like Noname Notes and the TBLLC Invoice Generator!
  gsettings_set "Settings > System > Date & Time > Clock & Calendar > ✓ Week Numbers" \
    gsettings set org.gnome.desktop.calendar show-weekdate true

  # Settings > System > Users
  #   - User > Name [You!]
  #   - User > Password
  #   - User > Automatic Login [disabled]
  #   - User > Language
  #   [ Add User > ] [ Add Enterprise Login > ]

  # Settings > System > Remote Desktop
  # - Desktop Sharing
  #   - Desktop Sharing [disabled]
  #   - Remote Control [disabled]
  #   - How to Connect, Login Details, etc.
  # - Remote Login
  #   - Remote Login [disabled]
  #   - How to Connect, Login Details, etc.

  # Settings > System > Secure Shell
  # - Secure Shell [enabled]
  #   - Prompts for password to disable
  # - SSH Login Command: `ssh $(hostname)`

  # Settings > System > About
  # - Device Name: $(hostname)
  # - Operating System
  # - Hardward Model
  # - Processor
  # - Memory
  # - Disk Capacity
  # - System Details
  #   - Popup w/ [ Copy to Cliboard ]
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
  local menu_path="GNOME Terminal > Profiles: Default"

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
    >&2 echo "ERROR: Skipping: ${menu_path}: Could not suss Profile ID"

    exit_1
  fi

  # ***

  if is_hack_font_installed; then
    # Default: Monospace
    dconf_write "${menu_path} > Text > Text Appearance > Custom font: Hack Nerd Font Mono 11" \
      dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/font" \
      'Hack Nerd Font Mono 11'
  else
    >&2 echo "ALERT: Skipping: ${menu_path}: Text > Text Appearance > Custom font: Hack Nerd Font"
  fi

  # ***

  # Default: 80 columns x 24 rows
  dconf_write "${menu_path} > Text > Text Appearance > Initial terminal size: 112 columns" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/default-size-columns" '112'

  # Default: 80 columns x 24 rows
  dconf_write "${menu_path} > Text > Text Appearance > Initial terminal size: 42 rows" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/default-size-rows" '42'

  # ***

  # Default: "Default" ('system'), same as Enabled
  dconf_write "${menu_path}: Cursor > Cursor blinking: Disabled" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/cursor-blink-mode" 'off'

  # Default: Enabled
  dconf_write "GNOME Terminal: Profiles: Default: Sound: Terminal Bell: Disabled" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/audible-bell" 'false'
}

# ***

gnome_terminal_customize_profiles_0_colors() {
  # Default: Enabled (though with GNOME Dark mode, terminal sill black on white).
  # - CALSO: GNOME Terminal: General: Theme variant: Dark
  dconf_write "${menu_path} > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/use-theme-colors" 'false'

  dconf_write "${menu_path} > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/foreground-color" 'rgb(255,255,255)'

  dconf_write "${menu_path} > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/background-color" 'rgb(0,0,0)'

  # *** I think the XTerm color palette is a little brighter and easier to read
  # than GNOME.

  dconf_write "${menu_path} > Colors > Palette > Built-in schemes: XTerm" \
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
  local menu_path="GNOME Extension > Hide Top Bar"

  # DUNNO: There's no schema for org.gnome.shell.extensions.hidetopbar
  # but you can access it via dconf.

  dconf_write "${menu_path} > Sensitivity > ✓ Show panel when mouse approaches edge of the screen" \
    dconf write /org/gnome/shell/extensions/hidetopbar/mouse-sensitive true

  dconf_write "${menu_path} > Intellihide > ✗ Only hide panel when a window takes the space" \
    dconf write /org/gnome/shell/extensions/hidetopbar/enable-intellihide false
}

# ***

gnome_extension_just_perfection_customize() {
  if ! ${LINUX_ONBOARDER_INCLUDE_JUST_PERFECTION:-false}; then

    return
  fi

  local menu_path="GNOME Extension > Just Perfection"

  # The app icon next to application's menu bar dropdown.
  #   dconf_write "GNOME Extension > Just Perfection > Icons > ✓ App Menu Icon" \
  #   dconf write /org/gnome/shell/extensions/just-perfection/app-menu-icon false

  # Defaults: Center (0), also Right (1), Left (2)
  dconf_write "${menu_path} > Customize > Clock Menu Position: Right" \
    dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position 1

  # Defaults: 0, also 1..10
  dconf_write "${menu_path} > Customize > Clock Menu Position Offset: 10" \
    dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position-offset 10
}

# ***

gnome_extension_advanced_alt_tab_window_switcher_customize() {
  if ! ${LINUX_ONBOARDER_INCLUDE_AATWS:-false}; then

    return
  fi

  local menu_path="GNOME Extension > AATWS"

  # Defaults: Bottom (3), also Top (1), Center (2)
  dconf_write "${menu_path} > Common > Behavior > Placement: Center" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/switcher-popup-position 2

  # Defaults: Show Above/Below Item (2), also Top (1), Show Centered (3)
  dconf_write "${menu_path} > Common > Appearance and Content > Tooltip Titles: Disable" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/switcher-popup-tooltip-title 1

  # Defaults: false
  dconf_write "${menu_path} > Window Switcher > Behavior > Skip Minimized Windows: Enable" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/win-switch-skip-minimized true

  # Defaults: true
  dconf_write "${menu_path} > App Switcher > Behavior > Include Favorite (Pinned) Apps: Disable" \
    dconf write /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/app-switcher-popup-fav-apps false

  # Defaults: true
  dconf_write "${menu_path} > App Switcher > Behavior > Include Show Apps Icon: Disable" \
    dconf write \
    /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/app-switcher-popup-include-show-apps-icon false

  # Defaults: false
  dconf_write "${menu_path} > App Switcher > Appearance > Hide Window Count For Single-Window Apps: Enable" \
    dconf write \
    /org/gnome/shell/extensions/advanced-alt-tab-window-switcher/app-switcher-popup-hide-win-counter-for-single-window \
    true
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
