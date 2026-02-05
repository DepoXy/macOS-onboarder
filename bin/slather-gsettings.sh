#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/macOS-GNOME-onboarder#🏂
# License: MIT

# Copyright (c) © 2025 Landon Bouma. All Rights Reserved.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE:
#
#   # On GNOME Shell, run it:
#   path/to/macOS-onboarder/bin/slather-gsettings.sh
#
#   # To see list of reminders, and to smoke-test this script, dry-run it:
#   path/to/macOS-onboarder/bin/slather-gsettings.sh --dry-run --force
#   # Omit the --force if you only want to see settings that differ.
#
#   # This script only sets values if they're different.
#   # - To always dconf-write or gsettings-set, --force:
#   path/to/macOS-onboarder/bin/slather-gsettings.sh --force

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
#     ~/.kit/mOS/macOS-onboarder/bin/slather-gsettings.sh --count
#
# - For a preview of applied settings:
#
#     ~/.kit/mOS/macOS-onboarder/bin/slather-gsettings.sh --dry-run
#
#   - 2025-09-24: No. of settings:
#     - `gsettings set` + `dconf write` + Task reminders:
#                  161            + 15               + 8.
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
#
# - Additional legend: Some settings below use "✓" in their
#   description to indicate when a setting is set to Enabled,
#   or "✗" or "∅" when a setting is set to Disabled.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Set true if you want to disable this checklist reminder.
LINUX_ONBOARDER_SKIP_WAKE_ON_LID=${LINUX_ONBOARDER_SKIP_WAKE_ON_LID:-false}

# ISOFF/2025-09-24: Author no longer uses these extensions.
LINUX_ONBOARDER_INCLUDE_AATWS=${LINUX_ONBOARDER_INCLUDE_AATWS:-false}
LINUX_ONBOARDER_INCLUDE_JUST_PERFECTION=${LINUX_ONBOARDER_INCLUDE_JUST_PERFECTION:-false}

# ***

# COPYD/USYNC: From author's OMR `myrepos` fork-extension:
#   ~/.kit/git/ohmyrepos/lib/echo-install-help.sh
OMR_REMINDER_UNKNOWN="${OMR_REMINDER_UNKNOWN:-🔳}"
OMR_REMINDER_AWAITING="${OMR_REMINDER_AWAITING:-⭕}"
OMR_REMINDER_COMPLETE="${OMR_REMINDER_COMPLETE:-✅}"
OMR_REMINDER_OPTIONAL="${OMR_REMINDER_OPTIONAL:-❓}"
OMR_REMINDER_DISABLED="${OMR_REMINDER_DISABLED:-❌}"
OMR_REMINDER_OFFBUTON="${OMR_REMINDER_OFFBUTON:-❎}"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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

fg_skyblue() { printf "\033[38;2;135;175;255m"; }
fg_lightgray() { printf "\033[37m"; }
attr_underline() { printf "\033[4m"; }
attr_reset() { printf "\033[0m"; }
highlight() { printf "%s" "$(fg_skyblue)$1$(attr_reset)"; }
highlight_soft() { printf "%s" "$(fg_lightgray)$1$(attr_reset)"; }
highlight_diff() { printf "%s" "$(attr_underline)$1$(attr_reset)"; }

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

fake_it() {
  dconf_write() {
    print_dconf_write_setting "$@" ||
      true
  }
  gsettings_set() {
    print_gsettings_set_setting "$@" ||
      true
  }
}

# INPUT: ENV: Expects:
#   local cnt_dconfs=0
#   local cnt_gsetts=0
count_it() {
  dconf_write() {
    local _description="$1"
    local _dconf_command="$2"
    local _dconf_action="$3"
    local dconf_key="$4"
    local dconf_val="$5"

    let 'cnt_dconfs += 1'
    gsett_schemas+=("$(
      echo "${dconf_key}" |
        sed 's#/#\.#g' |
        sed 's/^ *\.\(.*\)\.[^\.]\+$/\1/' |
        sed 's/^org.gnome.terminal.legacy.profiles.*//'
    )")

    echo "  dconf: ${dconf_key} ${dconf_val}"
  }
  gsettings_set() {
    local _description="$1"
    local _gsettings_command="$2"
    local _gsettings_action="$3"
    local gsettings_schema="$4"
    local gsettings_key="$5"
    local gsettings_val="$6"

    let 'cnt_gsetts += 1'
    gsett_schemas+=("${gsettings_schema}")

    echo "  gsett: ${gsettings_schema} ${gsettings_key} ${gsettings_val}"
  }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Ha, this probably isn't necessary in GNOME like it is in (on?) Darwin.
gnome_settings_close() {
  local dry_run=$1

  # I can't imagine this is necessary, like it is on macOS to
  # close System Settings.
  if true; then

    return
  fi

  if ! ${force_run}; then

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

# ALTLY: 📌⛏️🪓⚠️🪚🔨📍❗
LINUX_ONBOARDER_DIFF_ALERT="${LINUX_ONBOARDER_DIFF_ALERT:- 🔨}"

# DEVEL: Something like this if you to monkey-path dconf and gsettings:
#
#   dconf() {
#     if [ "$1" != "read" ]; then
#       >&2 echo "BREAK: dconf $1"
#       exit 1
#     fi
#     /usr/bin/dconf "$@"
#   }
#
#   gsettings() {
#     if [ "$1" != "get" ]; then
#       >&2 echo "BREAK: gsettings $1"
#       exit 1
#     fi
#     /usr/bin/gsettings "$@"
#   }
LINUX_ONBOARDER_VERBOSE="${LINUX_ONBOARDER_VERBOSE:-false}"

dconf_write() {
  local description="$1"
  local _dconf_command="$2"
  local dconf_action="$3"
  local dconf_key="$4"
  local dconf_val="$5"

  if print_dconf_write_setting "$@"; then
    if [ "${dconf_action}" = "reset" ]; then
      ! ${LINUX_ONBOARDER_VERBOSE} ||
        echo "dconf reset \"${dconf_key}\""

      dconf reset "${dconf_key}"
    elif [ "${dconf_action}" = "write" ]; then
      ! ${LINUX_ONBOARDER_VERBOSE} ||
        echo "dconf write \"${dconf_key}\" \"${dconf_val}\""

      dconf write "${dconf_key}" "${dconf_val}"
    fi
  fi
}

gsettings_set() {
  local description="$1"
  local _gsettings_command="$2"
  local gsettings_action="$3"
  local gsettings_schema="$4"
  local gsettings_key="$5"
  local gsettings_val="$6"

  if print_gsettings_set_setting "$@"; then
    if [ "${gsettings_action}" = "reset" ]; then
      ! ${LINUX_ONBOARDER_VERBOSE} ||
        echo "gsettings reset \"${gsettings_schema}\" \"${gsettings_key}\""

      gsettings reset "${gsettings_schema}" "${gsettings_key}"
    elif [ "${gsettings_action}" = "set" ]; then
      ! ${LINUX_ONBOARDER_VERBOSE} ||
        echo "gsettings set \"${gsettings_schema}\" \"${gsettings_key}\" \"${gsettings_val}\""

      gsettings set "${gsettings_schema}" "${gsettings_key}" "${gsettings_val}"
    fi
  fi
}

print_dconf_write_setting() {
  local description="$1"
  local dconf_command="$2"
  local dconf_action="$3"
  local dconf_key="$4"
  local dconf_val="$5"

  if [ "${dconf_command}" != "dconf" ]; then
    >&2 echo "GAFFE: Unknown dconf command: ${dconf_command}"

    exit_1
  fi

  if [ "${dconf_action}" != "write" ]; then
    >&2 echo "GAFFE: Unknown dconf action: ${dconf_action}"

    exit_1
  fi

  let 'cnt_dconfs += 1'

  local curr_val
  curr_val="$(dconf read "${dconf_key}")"

  if [ -z "${curr_val}" ]; then
    curr_val="(unset?)❗"
  fi

  local quoted_val
  # Note that gsettings strings are not quoted, e.g.,
  #   gsettings set org.gnome.desktop.interface clock-format '24h'
  # - Vs.:
  #   dconf write /org/gtk/settings/file-chooser/clock-format "'24h'"
  # Because quote_gvariant used to check values for both dconf (this
  # func.) and gsettings (print_gsettings_set_setting), we'll remove
  # quotes around simple strings here.
  # - Note this check if pretty strict, because author hasn't read
  #   the spec, and I don't know the range of accepted values...
  #   so let's just verify alphanums and whitespace.
  if echo "${dconf_val}" | grep -q -e "^'[ a-zA-Z0-9]*'$"; then
    # To remove quotes:
    #   quoted_val="$(echo "${dconf_val}" | sed "s/^'//;s/'$//")"
    quoted_val="${dconf_val}"
  else
    quoted_val="$(quote_gvariant "${dconf_val}")"
  fi

  local is_changed=false
  compare_gvariants "${curr_val}" "${quoted_val}" ||
    is_changed=true

  local high_val="echo"
  local bang_val=""
  if ${is_changed}; then
    high_val="highlight_diff"
    bang_val="${LINUX_ONBOARDER_DIFF_ALERT}"
  fi

  if ${force_run} || ${is_changed}; then
    echo -e "  $(
      highlight_soft "${description}"
    ):\n    ${curr_val} → $(${high_val} "${quoted_val}")${bang_val}"
  else
    return 1
  fi
}

# There's a `dconf read -d` option that reads default values,
# but it doesn't work as one might expect, e.g., consider:
#   $ dconf reset /org/gnome/desktop/wm/keybindings/begin-move
#   $ dconf read /org/gnome/desktop/wm/keybindings/begin-move
#   $ dconf read -d /org/gnome/desktop/wm/keybindings/begin-move
#   $ gsettings get org.gnome.desktop.wm.keybindings begin-move
#   ['<Alt>F7']
# - I.e., `dconf read -d` prints nothing, but `gsettings get`
#   prints the effective value (and reveals what's effectively
#   the default value).

print_gsettings_set_setting() {
  local description="$1"
  local gsettings_command="$2"
  local gsettings_action="$3"
  local gsettings_schema="$4"
  local gsettings_key="$5"
  local gsettings_val="$6"

  if [ "${gsettings_command}" != "gsettings" ]; then
    >&2 echo "GAFFE: Unknown gsettings command: ${gsettings_command}"

    exit_1
  fi

  if [ "${gsettings_action}" != "set" ] && [ "${gsettings_action}" != "reset" ]; then
    >&2 echo "GAFFE: Unknown gsettings action: ${gsettings_action}"

    exit_1
  fi

  let 'cnt_gsetts += 1'

  # The dconf-read is the current *user* value.
  # - It returns an empty string if the user has not customimzed
  #   a setting.
  local dconf_key
  local dconf_val
  dconf_key="/$(echo "${gsettings_schema}" | sed 's#\.#/#g')${gsettings_key}"
  dconf_val="$(dconf read "${dconf_key}")"

  # The gsettings-get is the current *active* value.
  # - It returns the actual value for a setting, whether or not
  #   the user has customized that setting (so that if you don't
  #   get a value from dconf-read, you will from gsettings-get;
  #   you could think of this as the default value).
  local curr_val
  curr_val="$(gsettings get "${gsettings_schema}" "${gsettings_key}")"

  if [ -n "${dconf_val}" ]; then
    if [ "${dconf_val}" != "${curr_val}" ]; then
      >&2 echo "WEIRD: dconf_val != curr_val: ${dconf_val} != ${curr_val}"
    fi
  fi

  local quoted_val
  if [ "${gsettings_action}" != "reset" ]; then
    # The user is setting an explicit value, which they passed as an arg.
    quoted_val="$(quote_gvariant "${gsettings_val}")"
  elif [ -z "${dconf_val}" ]; then
    # The user is resetting the key value, and the key is currently unset
    # (this'll be a no-op), so the gsettings-get value is the "default".
    quoted_val="${curr_val}"
  else
    # The user is resetting the key value, which is currently customized.
    # - Note when dconf-read returns an empty string, gsettings-get
    #   returns the default value (also that `dconf read -d` does
    #   not also return the default value (or author is using it
    #   wrong)).
    # - So we don't know/can't know what the default value is,
    #   at least not until after we reset the setting.
    quoted_val="(reset)"
  fi

  local is_changed=false
  compare_gvariants "${curr_val}" "${quoted_val}" ||
    is_changed=true

  local high_val="echo"
  local bang_val=""
  if ${is_changed}; then
    high_val="highlight_diff"
    bang_val="${LINUX_ONBOARDER_DIFF_ALERT}"
  fi

  if ${force_run} || ${is_changed}; then
    echo -e "  $(
      highlight_soft "${description}"
    ):\n    ${curr_val} → $(${high_val} "${quoted_val}")${bang_val}"
  else
    return 1
  fi
}

compare_gvariants() {
  local curr_val="$1"
  local quoted_val="$2"

  if echo -e "${curr_val}\n${quoted_val}" | grep -q -e "^\-\?[0-9\.]\+$"; then
    test "$(printf "%.2f" "${curr_val}")" = "$(printf "%.2f" "${quoted_val}")"
  else
    test "${curr_val}" = "${quoted_val}"
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
    echo "${val}" | grep -q -e "^int64 [0-9]\+$" ||
    [ "${val}" = "true" ] || [ "${val}" = "false" ] \
    ; then
    printf "%s" "${val}"
  elif [ "${val}" = "@as []" ]; then
    printf "%s" "${val}"
  elif echo "${val}" | grep -q -e "^\['"; then
    # Start of array starting with string.
    printf "%s" "${val}"
  elif echo "${val}" | grep -q -e "^\[\['"; then
    # Start of array starting with array starting with string.
    printf "%s" "${val}"
  elif echo "${val}" | grep -q -e "^'\[{\""; then
    # Start of array starting with dictionary starting with string (i.e., JSON).
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
  #
  # Default: 100
  gsettings_set "${menu_path} > Picture Opacity" \
    gsettings reset org.gnome.desktop.background picture-opacity
  # Default: 'file:///usr/share/images/desktop-base/desktop-background.xml'
  # - Disable Light Wallpaper Picture
  gsettings_set "${menu_path} > Picture URI" \
    gsettings set org.gnome.desktop.background picture-uri ''
  # Default: 'file:///usr/share/backgrounds/gnome/adwaita-d.jpg'
  # - Disable Dark Wallpaper Picture
  gsettings_set "${menu_path} > Picture URI Dark" \
    gsettings set org.gnome.desktop.background picture-uri-dark ''
  # Default: false
  gsettings_set "${menu_path} > Show Desktop Icons" \
    gsettings reset org.gnome.desktop.background show-desktop-icons

  # Default: 'solid', but using GUI may change, e.g., to 'horizontal'.
  gsettings_set "${menu_path} > Color Shading Type" \
    gsettings set org.gnome.desktop.background color-shading-type 'solid'

  # Default: 'zoom', but using GUI may change, e.g., to 'zoom'.
  # - Doesn't matter when used with solid color, so leave
  #   at 'zoom', which is what Settings changes it to, so
  #   that ./slather-gsettings.sh --dry-run doesn't diff.
  gsettings_set "${menu_path} > Picture Options" \
    gsettings set org.gnome.desktop.background picture-options 'zoom'

  # Set Background Color.
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
  gsettings_set "Settings > Multitasking > General > ∅ Hot Corner" \
    gsettings set org.gnome.desktop.interface enable-hot-corners false

  # "Drag windows against the top, left, and right screen edges to resize them"
  # - Default: true
  gsettings_set "Settings > Multitasking > General > ✓ Active Screen Edges" \
    gsettings set org.gnome.mutter edge-tiling true

  # Workspaces options:
  # - Dynamic Workspaces [default]
  #   "Automatically removes empty workspaces"
  # - Fixed Number of Workspaces
  #   "Specify a number of permanent workspaces"
  #   - Number of Workspaces [default: 4]
  gsettings_set "Settings > Multitasking > General > ✓ Dynamic Workspaces" \
    gsettings set org.gnome.mutter dynamic-workspaces true
  gsettings_set "Settings > Multitasking > General > Number of Workspaces: 4" \
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

  # Multi-Monitor options:
  # - Workspaces on primary display only [default]
  # - Workspaces on all displays
  gsettings_set "Settings > Multitasking > General > ✓ Workspaces on primary display only" \
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
  # Default: Disabled (true)
  gsettings_set "Settings > Notifications > ∅ Do Not Disturb" \
    gsettings set org.gnome.desktop.notifications show-banners true

  # Default: true
  # - Off. It's not like it's a mobile phone. Either I'm logged on,
  #   or I'm not in front of the display. Also, I don't like a noisy
  #   lock screen.
  # USYNC: This option found twice in Settings.
  gsettings_set "Settings > Notifications > ∅ Lock Screen Notifications" \
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
  gsettings_set "Settings > Search > ✓ App Search" \
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
${OMR_REMINDER_UNKNOWN:-🔳} Settings > Online Accounts > Add an account
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

  gsettings_set "Settings > Wellbeing > Screen Limits: ∅ Screen Time Limit" \
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
    gsettings set org.gnome.desktop.screen-time-limits daily-limit-seconds 'uint32 28800'

  # "Black and white screen for screen limits"
  # - Default: Enabled (if Screem Time Limit enabled)
  gsettings_set "Settings > Wellbeing > Screen Limits > ✓ Grayscale" \
    gsettings set org.gnome.desktop.screen-time-limits grayscale true

  # ***

  # "Reminders to look away from the screen" / Default: Disabled
  gsettings_set "Settings > Wellbeing > Break Reminders > ∅ Eyesight Reminders" \
    gsettings set org.gnome.desktop.break-reminders selected-breaks '@as []'
  # gsettings set org.gnome.desktop.break-reminders selected-breaks "['eyesight']"

  # "Reminders to move around" / Default: Disabled
  gsettings_set "Settings > Wellbeing > Break Reminders > ∅ Movement Reminders" \
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
  gsettings_set "Settings > Wellbeing > Break Reminders > ✓ Sounds" \
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
  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > ✓ Mouse Acceleration" \
    gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'default'

  # Default: Traditional "Scrolling moves the view" / Natural "Scrolling moves the content"
  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Scroll Direction: Traditional" \
    gsettings set org.gnome.desktop.peripherals.mouse natural-scroll false

  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Double-Click Speed [Hidden]: 400" \
    gsettings set org.gnome.desktop.peripherals.mouse double-click 400

  gsettings_set "Settings > Mouse & Touchpad > Mouse > Mouse > Drag Threshold [Hidden]: 400" \
    gsettings set org.gnome.desktop.peripherals.mouse drag-threshold 8

  # HSTRY: See old Tweaks setting (for key that still exists in
  # GSettings, though doesn't seem to have GUI exposure):
  # - Tweaks > Keyboard & Mouse > Mouse Click Emulation
  #   org.gnome.desktop.peripherals.mouse middle-click-emulation false

  # HSTRY: Previously found in GNOME Tweaks, these are now in GNOME Settings:
  # - PREVY: Was at: Tweaks > Keyboard & Mouse > Touchpad > Mouse Click Emulation:
  #     ✓ Fingers: Click the touchpad with two fingers for right-click
  #                and three fingers for middle-click.
  #     - Area:    Click the bottom right of the touchpad for right-click
  #                and the bottom middle for middle-click.
  #     - Disable: Don't use mouse click emulation.
  # - CURLY: Now at: Settings > Mouse & Touchpad > Touchpad > Secondary Click:
  #     ✓ Two Finger Push: Push anywhere with 2 fingers
  #     - Corner Push: Push with a single finger in the corner
  # - Default value:
  #     gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
  #
  # CALSO: 2-finger scrolling.
  # - CURLY: Now at: Settings > Mouse & Touchpad > Touchpad > Scroll Method:
  #     ✓ Two Finger: Dray two fingers on the touchpad
  #     - Edge: Drag one finger on the edge
  # - Default value (Two Finger):
  #     gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
  #     gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
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
  gsettings_set "${menu_path} > Blank Screen Delay: 17 mins" \
    gsettings set org.gnome.desktop.session idle-delay 'uint32 1020'

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
  gsettings_set "${menu_path} > Automatic Screen Lock Delay: 6⅔ hours" \
    gsettings set org.gnome.desktop.screensaver lock-delay 'uint32 24000'
  # TRACK/2025-01-12: Something is causing Settings to become unresponsive...
  # - BWARE: Or not: Using custom lock-delay makes Settings unresponsive within
  # - seconds of starting Settings app, e.g., if you run this manually:
  #     gsettings set org.gnome.desktop.screensaver lock-delay 14400
  # - DUNNO/2025-01-12: Working again after reboot, albeit with 3600 value.

  # Default: Disabled (false)
  # USYNC: This option found twice in Settings.
  gsettings_set "${menu_path} > ∅ Lock Screen Notifications" \
    gsettings set org.gnome.desktop.notifications show-in-lock-screen false
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
# - If you upgrade from Debian 12, the feature is opt-in.
#   - The toggle in GNOME Settings GUI are disabled
#   - You can delete /etc/tmpfiles.d/tmp.conf to enable auto-deletion.
#   - DUNNO: Are there two separate /tmp deletion features?
#     - I.e., one based on the 'remove-old-temp-files' GSettings setting,
#       and another one based on the /etc/tmpfiles.d/tmp.conf config?
#     - Or maybe it's one feature that's enabled via
#       'remove-old-temp-files', checks /etc/tmpfiles.d/tmp.conf,
#       and falls-back on 'old-files-age'?
#     - I'll dig deeper someday, but obviously not a major concern.
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
${OMR_REMINDER_UNKNOWN:-🔳} Settings > Sound > Sounds > Alert Sound > Click|String|Swing|Hum (maybe Click?)")
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
${OMR_REMINDER_UNKNOWN:-🔳} Settings > Power > General > Battery Charging > ✓ Preserve Battery Health")

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
${OMR_REMINDER_UNKNOWN:-🔳} Settings > Power > General > Power Mode > ✓ Balanced")

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
  gsettings_set "${menu_path} > Automatic Suspend > ✓ On Battery Power" \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
  gsettings_set "${menu_path} > Automatic Suspend > (On Battery Power) Delay: 30 mins." \
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800

  # Automatic Suspend > When Plugged In:
  # - Enabled ('suspend') / Disabled: 'nothing'
  # - Same "Delay" dropdown options as "On Battery Power > Delay".
  # - Default: Enabled, 20 minutes ('suspend', 1200) [I think?]
  gsettings_set "${menu_path} > Automatic Suspend > ∅ When Plugged In" \
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
  gnome_settings_customize_keyboard_navigation_switchers
  gnome_settings_customize_keyboard_screenshots
  gnome_settings_customize_keyboard_sound_and_media
  gnome_settings_customize_keyboard_system
  gnome_settings_customize_keyboard_typing
  gnome_settings_customize_keyboard_windows
  gnome_settings_customize_keyboard_windows_hidden
  gnome_settings_customize_keyboard_custom_shortcuts
}

#      ++++++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > ACCESSIBILITY
#      ++++++++++++++++++++++++++++++++++

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

#      ++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > LAUNCHERS
#      ++++++++++++++++++++++++++++++

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
  gsettings_set "Keyboard Shortcuts > Launchers > Launch help browser: Disabled" \
    gsettings set org.gnome.settings-daemon.plugins.media-keys help '@as []'
}

#      +++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > NAVIGATION
#      +++++++++++++++++++++++++++++++

# SAVVY: Note that gsettings won't let you assign the same
#        keybinding to more than one command.
# - This might matter to us, especially in a fresh desktop
#   environment, where we might not be able to assign key-
#   bindings in GUI order unless we unassign certains key-
#   bindings first.
#   - This is not currently an issue, however.
#     - There are only a few keybindings where we want to
#       use a default keybinding for a different command.
#     - E.g., below, we change "Switch applications" from
#       its default, <Cmd-Tab>, to our preffered <Alt-`>,
#       then we change "Switch windows of an application"
#       from <Cmd-`> to <Cmd-Tab>. But if we didn't do it
#       in that order, trying to use <Cmd-Tab> would fail.
#     - So just be aware that we might need to change the
#       assignment order herein to avoid conflicts. As of
#       now, though, GUI order works unconflictingly.
#   - Or, more robustly, a full-proof approach would be to
#     gsettings-reset *all* keybindings before reassigning
#     them. But then our UX wouldn't be able to inform the
#     user which keybindings are changing (because more of
#     them would, after being reset), at least not without
#     overcomplicating this script. (So, as usual, an over-
#     ly complicated comment instead.)

gnome_settings_customize_keyboard_navigation() {
  local menu_path="Keyboard Shortcuts > Navigation"

  # "Hide all normal windows" / Default: Disabled
  # - SAVVY: Unlike macOS, whose Show Desktop only temporarily
  #   shows the desktop (and then running the command again
  #   brings all the windows back), this Show Desktop minimizes
  #   all windows (and leaves them minimized).
  #   - UCASE: Author uses Desktop Widgets extension to show
  #     clock time and weather on the desktop, and Show Desktop
  #     can be used to unhide that information if necessary.
  #   - UCASE: Unlike the macOS Show Desktop, this Show Desktop
  #     lets you quickly declutter your desktop. (Author uses
  #     a separate Hammerspoon binding on macOS to hide all.)
  #   - REFER: See similar macOS keybinding: macOS Settings
  #     > Keyboard Shortcuts > Mission Control > Show Desktop
  #     (defaults F11, but ./bin/slather-defaults.sh changes
  #      it to <Ctrl-Alt-D>).
  # - BNDNG: <Ctrl-Alt-D>
  gsettings_set "${menu_path} > Hide all normal windows: <Ctrl-Alt-D>" \
    gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Control><Alt>d']"

  # *** Move window to monitor bindings (4 GUI settings)

  # "Move window one monitor down" / Default: <Shift-Cmd-Down>
  gsettings_set "${menu_path} > Move window one monitor down: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down '@as []'
  # "Move window one monitor to the left" / Default: <Shift-Cmd-Left>
  gsettings_set "${menu_path} > Move window one monitor to the left: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left '@as []'
  # "Move window one monitor to the right" / Default: <Shift-Cmd-Right>
  gsettings_set "${menu_path} > Move window one monitor to the right: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right '@as []'
  # "Move window one monitor up" / Default: <Shift-Cmd-Up>
  gsettings_set "${menu_path} > Move window one monitor up: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up '@as []'

  # *** Move window to workspace bindings (7 GUI settings + 10 hidden)

  # "Move window one workspace to the left" / Default: <Shift-Cmd-PageUp>
  # - Default: When unset, gsettings-get reports three bindings (!?):
  #   ['<Super><Shift>Page_Up',
  #    '<Super><Shift><Alt>Left',
  #    '<Control><Shift><Alt>Left']
  # gsettings_set "${menu_path} > Move window one workspace to the left: Disabled" \
  #   gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left '@as []'
  # BNDNG: <Shift-Ctrl-Alt-Left>
  gsettings_set "${menu_path} > Move window one workspace to the left:  <Shift-Ctrl-Alt-Left>" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Control><Alt>Left']"
  # "Move window one workspace to the right" / Default: <Shift-Cmd-PageDown>
  # - Default: When unset, gsettings-get reports three bindings (!?):
  #   ['<Super><Shift>Page_Down',
  #    '<Super><Shift><Alt>Right',
  #    '<Control><Shift><Alt>Right']
  # gsettings_set "${menu_path} > Move window one workspace to the right: Disabled" \
  #   gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right '@as []'
  # BNDNG: <Shift-Ctrl-Alt-Right>
  gsettings_set "${menu_path} > Move window one workspace to the right: <Shift-Ctrl-Alt-Right>" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Control><Alt>Right']"
  #
  # There are 2 related bindings in GSettings for workspaces above/below,
  # but not exposed in the GUI.
  # - ASIDE: And here I thought workspaces were only logically organized
  #   left to right.
  # - DUNNO: I am confused why these two settings are assigned keybindings
  #   but are not exposed in the GUI — how would normal users either know
  #   these exist so they can use them, or know they exist so they can
  #   disable them to reclaim these two bindings?
  #   - REFER: See the "V-Shell" ("V" as in "Variable") extension, which,
  #     among other features, supports vertical and horizontal workspace
  #     layouts.
  #     https://extensions.gnome.org/extension/5177/vertical-workspaces/
  #     - BEGET: https://askubuntu.com/questions/1419991/
  #         switch-back-workspace-movement-to-up-down-instead-of-left-right-on-22-04
  # "Move window one workspace to the down" / Default: ['<Control><Shift><Alt>Down']
  gsettings_set "${menu_path} > Move window one workspace down [Hidden]: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down '@as []'
  # "Move window one workspace to the up" / Default: ['<Control><Shift><Alt>Up']
  gsettings_set "${menu_path} > Move window one workspace up [Hidden]: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up '@as []'
  #
  # "Move window to last workspace" / Default: <Shift-Cmd-End>
  gsettings_set "${menu_path} > Move window to last workspace: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last '@as []'
  # "Move window to workspace 1" / Default: <Shift-Cmd-Home>
  gsettings_set "${menu_path} > Move window to workspace 1: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 '@as []'
  # There are 3 more move-to-workspace-N options in the GUI:
  #   Keyboard Shortcuts > Navigation > Move window to workspace 2: Disabled
  #   Keyboard Shortcuts > Navigation > Move window to workspace 3: Disabled
  #   Keyboard Shortcuts > Navigation > Move window to workspace 4: Disabled
  # There are 12 total move-to-workspace-N options in GSettings (8 hidden):
  #   move-to-workspace-1..move-to-workspace-9..move-to-workspace-10..move-to-workspace-12

  # *** "Switch" Navigation keybindings (12 GUI settings + 8 hidden)

  # MOVED: The "Switch applications" keybinding is set below, with
  # the other "alt-tabbers":
  # - "Switch applications"
  #
  # REFER:
  # gnome_settings_customize_keyboard_navigation_switchers

  # SAVVY/2025-09-26: These keybindings are inhibited by Hide Top Bar extension:
  #   <Ctrl-Alt-Tab> and <Ctrl-Alt-Esc>.
  # - It'd be fine to leave 'em enabled, but author's Neovim uses
  #   <Ctrl-Alt-Tab>, so we'll disable these settings.
  #
  # These switch between "Windows" and "Top Bar", but only if Top Bar is showing.
  # - Use <Ctrl-Alt-C> or the hover the mouse (or disable Hide Top Bar) to show
  #   the Top Bar, then "Switch system controls" shows an Alt-Tab-like popup
  #   with "Windows" and "Top Bar" icons that lets you send focus to the
  #   Top Bar, for a11y purposes (mouse-less Top Bar interaction).
  # - Note that "Switch system controls directly" is like the other
  #   "... directly" commands, and toggles focus between "Windows" and
  #   "Top Bar" immediately, without showing the popup widget.
  #
  # "Switch system controls" / Default: <Ctrl><Alt>Tab
  # - SAVVY: The Hide Top Bar extension inhibits switch-panels.
  #   - See comments in the Hide Top Bar settings function.
  gsettings_set "${menu_path} > Switch system controls" \
    gsettings set org.gnome.desktop.wm.keybindings switch-panels '@as []'
  gsettings_set "${menu_path} > Switch system controls backward [Hidden]" \
    gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward '@as []'
  # "Switch system controls directly" / Default: <Ctrl><Alt>Escape
  gsettings_set "${menu_path} > Switch system controls directly" \
    gsettings set org.gnome.desktop.wm.keybindings cycle-panels '@as []'
  gsettings_set "${menu_path} > Switch system controls directly backward [Hidden]" \
    gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward '@as []'

  # Author rarely uses Workspaces.
  # - I'll leave <Ctrl-Alt-Left> and <Ctrl-Alt-Right> for simple
  #   navigation to adjacent Workspaces, and I'll disable the others.
  #   - USYNC: These 2 keybindings match similar macOS keybindings.
  #     - CXREF: See rectangle_customize() in ./bin/slather-defaults.sh.

  # "Switch to last workspace" / Default: <Cmd-End>
  gsettings_set "${menu_path} > Switch to last workspace" \
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last '@as []'
  # "Switch to workspace 1" / Default: <Cmd-Home>
  gsettings_set "${menu_path} > Switch to workspace 1" \
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 '@as []'
  # There are 3 more switch-to-workspace-N options in the GUI (same as move-to-workspace-N):
  #   Keyboard Shortcuts > Navigation > Switch to workspace 2: Disabled
  #   Keyboard Shortcuts > Navigation > Switch to workspace 3: Disabled
  #   Keyboard Shortcuts > Navigation > Switch to workspace 4: Disabled
  # There are 12 total switch-to-workspace-N options in GSettings (8 hidden):
  #   switch-to-workspace-1..switch-to-workspace-9..switch-to-workspace-10..switch-to-workspace-12

  # "Switch to workspace on the left"
  # - Default: <Cmd-PageUp>, <Cmd-Alt-Left>, and <Ctrl-Alt-Left>
  #   - E.g.:
  #     gsettings_set "${menu_path} > Switch to workspace on the left" \
  #       gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left \
  #       "['<Super>Page_Up', '<Super><Alt>Left', '<Control><Alt>Left']"
  # - HSTRY: Prior to GNOME Shell 48, I think these were named differently, just FYI:
  #   - Keyboard Shortcuts > Navigation > Move to workspace on the left: <Cmd-PageUp>
  #   - Keyboard Shortcuts > Navigation > Move to workspace on the right: <Cmd-PageDown>
  # - BNDNG: <Ctrl-Alt-Left>
  gsettings_set "${menu_path} > Switch to workspace on the left" \
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left \
    "['<Control><Alt>Left']"
  # "Switch to workspace on the right" / Default: <Cmd-PageDown>
  # - Default: <Cmd-PageDown>, <Cmd-Alt-Right>, and <Ctrl-Alt-Right>
  #   - E.g.:
  #     gsettings_set "${menu_path} > Switch to workspace on the right" \
  #       gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right \
  #       "['<Super>Page_Down', '<Super><Alt>Right', '<Control><Alt>Right']"
  # - BNDNG: <Ctrl-Alt-Right>
  gsettings_set "${menu_path} > Switch to workspace on the right" \
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right \
    "['<Control><Alt>Right']"
  # Just like move-to-workspace-down/move-to-workspace-up, there
  # are 2 related bindings in GSettings for workspaces above/below,
  # but not exposed in the GUI:
  #
  #   org.gnome.desktop.wm.keybindings switch-to-workspace-down @as []
  #   org.gnome.desktop.wm.keybindings switch-to-workspace-up @as []

  # MOVED: The four "Switch windows*" keybindings are set below:
  # - "Switch windows"
  # - "Switch windows directly"
  # - "Switch windows of an app directly"
  # - "Switch windows of an application"
  #
  # REFER:
  # gnome_settings_customize_keyboard_navigation_switchers
}

#      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > NAVIGATION > SWITCH APPLICATIONS/WINDOWS
#      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#        (technically in the same GUI screen as the other Navigation
#         features, but these five controls are probably among the
#         most coveted keybindings any power user has, and the most
#         likely to ignite a heated discourse about how best to set
#         them up. Please post in the comments how you feel about my
#         keybindings and usage examples.)

# These are the 5 primary Navigation commands for switching windows:
# - "Switch applications" (reassigned below to <Alt-`>)
#   - This shows a row of application icons, making it easy
#     to quickly switch between applications.
#   - At the same time, if the highlighted application icon
#     represents an application that has more than one window,
#     the popup expands a row of thumbnails under its icon to
#     show all of its window thumbnails. Then the user can use
#     <Down> and then <Left> and <Right> to pick a different
#     app. window than the last one that was active.
# - "Switch windows" (reassigned below to <Alt-Tab>)
#   - This is your typical Alt-Tab overlay which shows thumbnails
#     for all windows from all apps. Press Tab/Shift-Tab until the
#     desired window thumbnail is highlighted, then release.
#     - Note the author uses the *Hide minimized* extension (by *danigm*)
#         https://extensions.gnome.org/extension/2639/hide-minimized/
#       so that only visible windows are included in this menu,
#       which makes it easier to navigate for those of us prone
#       to opening zillions of browser tabs and windows.
# - "Switch window directly" (wired below to its default, <Alt-Esc>)
#   - This brings the next window to the front immediately, but
#     possibly only temporarily if you keep the keybinding pressed.
#     While keeping the keybinding depressed, the front window is
#     displayed with a thick white window border highlight to show
#     you its state.
#     - While keeping the modifier key(s) down (e.g., <Alt>), you
#       can keep pressing the paired key (e.g., <Esc>) to bring
#       each next window to the front, until you finally release
#       the modifier key(s).
#     - Then only the final, chosen window is fronted, and all the
#       windows brought front and shown are not fronted, and the
#       operation does not change their order in the window stack.
# - "Switch windows of an app directly" (left at its default, <Alt-F6>)
#   - Similar to "Switch window directly", but restricted to the
#     windows for the current application.
# - "Switch windows of an application" (reassigned below to <Cmd-Tab>)
#   - Like "Switch windows", but limited to the current app's windows.
#   - This popup pairs well with the *Hide minimized* extension,
#     which (thankfully, IMO) is not applied to this command.
#     - Specifically, I appreciate that "Switch windows" (<Alt-Tab>)
#       only shows visible windows, so that it's easy to use that
#       popup (otherwise it's cluttered, overflowing, and I'm
#       screamed at with dozens of windows that I'm not currently
#       using, e.g., all the browser windows I tend to leave open,
#       including email, messaging, financial spreadsheets, etc.).
#     - But I also like that this command, "Switch windows of an
#       application" (<Cmd-Tab>) *does* show all windows for an
#       application, including minimized windows.
#       - This lets me find a minimized window easily — I bring
#         its application to the front, and then I use <Cmd-Tab>
#         to find the minimized window I want.
#       - I.e., I generally use <Alt-Tab> to bop between visible
#         windows, and I generally use <Cmd-Tab> to resurrect a
#         previously minimized window (well, that, or I use one of
#         the many task-specific accelerators I define, e.g., I
#         won't <Cmd-Tab> to my email window, but I'll use a
#         custom <Shift-Ctrl-Cmd-A> accelerator instead).
#         - Pro tip: If said app doesn't have any visible windows,
#           create one, then <Cmd-Tab>. E.g., if no browser windows
#           are visible, I <Cmd-T> to create a new browser window,
#           and then <Cmd-Tab> shows all the other browser windows.

# Here's how your author enjoys their "alt-tabber" wiring,
# compared to the default GNOME Shell binding assignments:
#
#   Author's    GNOME's     Description                         GSettings key
#   =========   =========   =================================   ===================
#   <Alt-`>   / <Cmd-Tab> / Switch applications               / switch-applications
#   <Alt-Tab> / -Disabled / Switch windows                    / switch-windows
#   <Alt-Esc> / <Alt-Esc> / Switch windows directly           / cycle-windows
#   <Alt-F6>  / <Alt-F6>  / Switch windows of an app directly / cycle-group
#   <Cmd-Tab> / <Cmd-`>   / Switch windows of an application  / switch-group
#
# - Note that to use <Cmd-Tab> for switch-group, we have to
#   unset <Cmd-Tab> from switch-applications first, which is
#   how the operations are ordered below. (Though note they
#   are still in GUI order; it's just coincidence that GUI
#   order is valid (avoids keybinding conflicts), otherwise
#   we'd have to reorder these operations (or we'd have to
#   unset some commands before reassigning their bindings).)
#
# - BWARE: If you're in the GUI and hit the Delete ⌫ button on
#   "Switch applications", it'll Disable whatever command might
#   be using <Cmd-Tab>, e.g., "Switch windows of an application"
#   will be disabled (and GNOME Settings won't warn-tell the user).
# - BWARE: The same applies for custom keybindings, e.g., if you
#   have <Cmd-`> keybound to front your editor (such as Neovide),
#   then you reset "Switch windows of an application", it will
#   also disable your Custom Keybinding *without telling you*.

gnome_settings_customize_keyboard_navigation_switchers() {
  # "Switch applications" / Defaults: <Super>Tab, <Shift><Super>Tab
  # - Shows app icons you can Alt-Tab or left/right between them,
  #   then <Down> to show one app's window thumbnails.
  # BNDNG: <Alt-`>, <Shift-Alt-`> (<Alt-grave>, <Shift-Alt-grave>)
  gsettings_set "${menu_path} > Switch applications" \
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>grave']"
  gsettings_set "${menu_path} > Switch applications backward [Hidden]" \
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward \
    "['<Shift><Alt>grave']"

  # "Switch windows" / Defaults: Disabled ('@as []', '@as []')
  # - Strange (to me) this defaults disabled, because
  #   it's the author's most-used alt-tabber!
  # BNDNG: <Alt-Tab>, <Shift-Alt-Tab> (but not <Alt-q> =( oh well)
  gsettings_set "${menu_path} > Switch windows" \
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
  gsettings_set "${menu_path} > Switch windows backward [Hidden]" \
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward \
    "['<Shift><Alt>Tab']"
  # - I tried to set <Alt-q> for switch-windows-backward (how I have it
  #   wired on macOS), but it didn't work. Whatever, using <Left> feels
  #   quick enough (though requires second hand; but seems easier than
  #   <Shift>ing <Alt-Tab>).
  #   - This doesn't work:
  #     # - BNDNG: <Alt-Q>
  #     dconf_write "Keyboard Shortcuts > Navigation > Switch windows (backward)" \
  #       dconf write /org/gnome/desktop/wm/keybindings/switch-windows-backward "['<Alt>q']"

  # "Switch windows directly" / Defaults: <Alt>Escape, <Shift><Alt><Escape>
  # BNDNG: <Alt-Esc>, <Shift-Alt-Esc>
  gsettings_set "${menu_path} > Switch windows directly" \
    gsettings reset org.gnome.desktop.wm.keybindings cycle-windows
  gsettings_set "${menu_path} > Switch windows directly backward [Hidden]" \
    gsettings reset org.gnome.desktop.wm.keybindings cycle-windows-backward

  # "Switch windows of an app directly" / Defaults: <Alt>F6, <Shift><Alt>F6
  # - INERT: Meh, I prefer <Cmd-Tab> for switching app windows,
  #   no need to find a more convenient keybinding for this.
  # BNDNG: <Alt-F6>, <Shift-Alt-F6>
  gsettings_set "${menu_path} > Switch windows of an app directly" \
    gsettings reset org.gnome.desktop.wm.keybindings cycle-group
  gsettings_set "${menu_path} > Switch windows of an app directly backward [Hidden]" \
    gsettings reset org.gnome.desktop.wm.keybindings cycle-group-backward

  # "Switch windows of an application" / Defaults: <Super>grave, <Shift><Super>grave
  # - Shows app icons, with current app selected, and a row of its
  #   window thumbnails below. The keybinding cycles through the
  #   app's windows. You can also press <Up> to go to the app icon
  #   row, and select a different app with <Left> and <Right>; then
  #   <Down> and <Left>/<Right> to pick a window from the other app.
  # - ASIDE: Author uses (as do default DepoXy bindings) <Cmd-`> to
  #   front user's editor (because I use it so often, I assigned it
  #   a prominent keybinding).
  # - Note <Cmd-Tab> is the default binding for "Switch applications",
  #   which must be unassigned first or this command will fail (see
  #   gsettings-set switch-applications, above).
  # BNDNG: <Cmd-Tab>, <Shift-Cmd-Tab>
  gsettings_set "${menu_path} > Switch windows of an application" \
    gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Super>Tab']"
  gsettings_set "${menu_path} > Switch windows of an app. bckwrd [Hidden]" \
    gsettings set org.gnome.desktop.wm.keybindings switch-group-backward \
    "['<Shift><Super>Tab']"
}

#      ++++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > SCREENSHOTS
#      ++++++++++++++++++++++++++++++++

# REFER: See macOS screenshot keybindings:
#   - Screenshots: Save picture of screen as a file: ⇧⌘ 3
#   - Screenshots: Copy picture of screen to the clipboard: ^⇧⌘ 3
#   - Screenshots: Save picture of selected area as a file: ⇧⌘ 4
#   - Screenshots: Copy picture of selected area to the clipboard: ^⇧⌘ 4
#   - Screenshots: Screenshot and recording options: ⇧⌘ 5
# - As set by:
#     shortcuts_screenshots_remap()
#   ./bin/slather-defaults.sh

gnome_settings_customize_keyboard_screenshots() {
  # "Record a screencast interactively" / Default: ['<Shift><Control><Alt>r']
  # - Saves files to:
  #     ~/Pictures
  #     ~/Pictures/Screencasts
  #     ~/Videos/Screencasts
  #   - And I don't see an option to change.
  # - BNDNG: <Shift-Ctrl-4>
  gsettings_set "Keyboard Shortcuts > Screenshots > Record a screencast interactively" \
    gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Shift><Control>4']"

  # Author doesn't assign Print to any key on my keyboard,
  # so the screenshot defaults are inaccessible to me.

  # "Take a screenshot" / Default: ['<Shift>Print']
  # - BNDNG: <Shift-Cmd-3>
  gsettings_set "Keyboard Shortcuts > Screenshots > Take a screenshot" \
    gsettings set org.gnome.shell.keybindings screenshot "['<Shift><Super>3']"

  # "Take a screenshot interactively" / Default: ['Print']
  # - BNDNG: <Shift-Ctrl-3>
  gsettings_set "Keyboard Shortcuts > Screenshots > Take a screenshot interactively" \
    gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Control>3']"

  # "Take a screenshot of a window" / Default: ['<Alt>Print']
  # - BNDNG: <Shift-Cmd-4>
  gsettings_set "Keyboard Shortcuts > Screenshots > Take a screenshot of a window" \
    gsettings set org.gnome.shell.keybindings screenshot-window "['<Shift><Super>4']"
}

#      ++++++++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > SOUND AND MEDIA
#      ++++++++++++++++++++++++++++++++++++

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

#      +++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > SYSTEM
#      +++++++++++++++++++++++++++

gnome_settings_customize_keyboard_system() {
  # "Focus the active notification" / Default: ['<Super>n']
  # - DUNNO: Pressing <Cmd-N> doesn't do anything for the author...
  gsettings_set "Keyboard Shortcuts > System > Focus the active notification: Disabled" \
    gsettings set org.gnome.shell.keybindings focus-active-notification '@as []'

  # "Lock screen" / Default: ['<Super>l']
  # - ALTLY: `xdg-screensaver lock`
  # - BNDNG: <Ctrl-Cmd-Q>
  gsettings_set "Keyboard Shortcuts > System > Lock screen" \
    gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Control><Super>q']"

  # "Log out" / Default: ['<Control><Alt>Delete']
  gsettings_set "Keyboard Shortcuts > System > Log out: Disabled" \
    gsettings reset org.gnome.settings-daemon.plugins.media-keys logout

  # "Open the quick settings menu" / Default: ['<Super>s']
  # - DUNNO: Does nothing for the author (literally, not figuratively).
  # - Previous to GNOME Shell 48, I think this was Open the application menu, <Cmd-F10>.
  gsettings_set "Keyboard Shortcuts > System > Open the quick settings menu: Disabled" \
    gsettings set org.gnome.shell.keybindings toggle-quick-settings '@as []'

  # "Power off" / Default: Disabled
  gsettings_set "Keyboard Shortcuts > System > Power off: Disabled" \
    gsettings reset org.gnome.settings-daemon.plugins.media-keys shutdown

  # "Restart" / Default: Disabled
  gsettings_set "Keyboard Shortcuts > System > Restart: Disabled" \
    gsettings reset org.gnome.settings-daemon.plugins.media-keys reboot

  # "Restore the keyboard shortcuts" / Default: ['<Super>Escape']
  # - SAVVY: This binding restore shortcuts if a shortcut inhibitor is active.
  #   - The general use case is inhibiting shortcuts so that all keys are
  #     delivered to the guest VM instead of the host operating system.
  #   - Otherwise, pressing <Cmd-Esc> will have no effect (ha, it won't
  #     reset all your keyboard shortcuts, as its name may suggest).
  #   https://www.reddit.com/r/gnome/comments/qea9c4/
  #     in_keyboard_shortcuts_settings_what_does_it_mean/
  #   https://wayland.app/protocols/keyboard-shortcuts-inhibit-unstable-v1
  # - BNDNG: <Cmd-Esc>
  gsettings_set "Keyboard Shortcuts > System > Restore the keyboard shortcuts" \
    gsettings reset org.gnome.mutter.wayland.keybindings restore-shortcuts

  # "Show all apps" / Default: ['<Super>a']
  # - ISOFF: This shows the Overview application list.
  #   - It's the same as <Cmd> to show Overview, then clicking the 3x3 dots icon (⁙).
  gsettings_set "Keyboard Shortcuts > System > Show all apps: Disabled" \
    gsettings set org.gnome.shell.keybindings toggle-application-view '@as []'

  # "Show the notification list" / Default: ['<Super>v']
  # - SAVVY: If Top Bar is hidden, does nothing.
  #   - Use <Ctrl-Alt-C> binding to show Top Bar.
  #   - Or roll your mouse over the Top Bar area.
  # - To disable instead:
  #   gsettings_set "Keyboard Shortcuts > System > Show the notification list" \
  #     gsettings set org.gnome.shell.keybindings toggle-message-tray '@as []'
  # BNDNG: <Shift-Ctrl-Cmd-C>
  # - USYNC: Same binding as author uses to Show Notification Center on macOS.
  gsettings_set "Keyboard Shortcuts > System > Show the notification list" \
    gsettings set org.gnome.shell.keybindings toggle-message-tray \
    ["'<Shift><Control><Super>c'"]

  # "Show the overview" / Default: ['<Super>s']
  # - Same behavior as pressing <Super>.
  #   - Or pressing the top-left button in the Top Bar.
  # - To disable instead:
  #   gsettings_set "Keyboard Shortcuts > System > Show the overview" \
  #     gsettings set org.gnome.shell.keybindings toggle-overview '@as []'
  # - BNDNG: <Ctrl-Alt-Down>
  #   - USYNC: Same keybinding as author uses for macOS Mission Control.
  gsettings_set "Keyboard Shortcuts > System > Show the overview" \
    gsettings set org.gnome.shell.keybindings toggle-overview "['<Control><Alt>Down']"

  # "Show the run command prompt" / Default: ['<Alt>F2']
  # - UCASE: AFAIK, enables just one feature:
  #   - Type `lg` then <Enter> to run Looking Glass.
  # - BNDNG: <Alt-F2>
  gsettings_set "Keyboard Shortcuts > System > Show the run command prompt" \
    gsettings reset org.gnome.desktop.wm.keybindings panel-run-dialog
}

#      +++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > TYPING
#      +++++++++++++++++++++++++++

# Disable all Typing bindings.
# - SAVVY: If you disable Switch-to-next via GUI, it also disables Switch-to-previous.
gnome_settings_customize_keyboard_typing() {
  # - Default: ['<Super>Space']
  gsettings_set "Keyboard Shortcuts > Typing > Switch to next input source: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source '@as []'

  # - Default: ['<Shift><Super>Space']
  gsettings_set "Keyboard Shortcuts > Typing > Switch to previous input source: Disabled" \
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward '@as []'
}

#      ++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > WINDOWS
#      ++++++++++++++++++++++++++++

gnome_settings_customize_keyboard_windows() {
  # "Activate the window menu" / Default: <Alt-Space>
  # - BNDNG: <Alt-Space>
  gsettings_set "Keyboard Shortcuts > Windows > Activate the window menu: <Alt-Space>" \
    gsettings reset org.gnome.desktop.wm.keybindings activate-window-menu

  # "Close window" / Default: <Alt-F4>
  # - NTRST: GNOME Tweaks is not <Ctrl-Q> or <Ctrl-W> closeable,
  #   but <Alt-F4> works.
  # - BNDNG: <Alt-F4>
  gsettings_set "Keyboard Shortcuts > Windows > Close window: <Alt-F4>" \
    gsettings reset org.gnome.desktop.wm.keybindings close

  # MOVED: "Hide window": See "minimize" alongside "maximize" and "maximize-*".

  # MOVED: "Lower window...": See "lower" alongside "raise" and "raise-or-lower".

  # ***

  # "Hide window" / Default: <Cmd-h>
  # - BNDNG: <Cmd-H>
  gsettings_set "Keyboard Shortcuts > Windows > Hide window: <Cmd-h>" \
    gsettings reset org.gnome.desktop.wm.keybindings minimize

  # "Maximize window" / Default: <Cmd-Up>
  # - SAVVY: Author prefers dual-purpose "toggle-maximized"
  gsettings_set "Keyboard Shortcuts > Windows > Maximize window" \
    gsettings set org.gnome.desktop.wm.keybindings maximize '@as []'

  # "Maximize window horizontally" / Default: Disabled
  # - BNDNG: <Shift-Ctrl-Alt-\> (<Shift-Ctrl-Alt-backslash>)
  gsettings_set "Keyboard Shortcuts > Windows > Maximize window horizontally" \
    gsettings set org.gnome.desktop.wm.keybindings maximize-horizontally \
    "['<Shift><Control><Alt>slash']"

  # "Maximize window vertically" / Default: Disabled
  # - BNDNG: <Shift-Ctrl-Alt-.> (<Shift-Ctrl-Alt-period>)
  gsettings_set "Keyboard Shortcuts > Windows > Maximize window vertically" \
    gsettings set org.gnome.desktop.wm.keybindings maximize-vertically \
    "['<Shift><Control><Alt>period']"

  # "Restore window" / Default: <Cmd-Down>
  # - The toggle-maximized binding is technically sufficient,
  #   but it's nice to have a complementary binding to arrow key
  #   bindings (UCASE: Pressing <Shift-Ctrl-Alt-Up> to maximize
  #   a window, then instinctively trying <Shift-Ctrl-Alt-Down>
  #   to unmaximize.)
  # - BNDNG: <Shift-Ctrl-Alt-Down>
  gsettings_set "Keyboard Shortcuts > Windows > Restore window" \
    gsettings set org.gnome.desktop.wm.keybindings unmaximize \
    "['<Shift><Control><Alt>Down']"

  # "Toggle maximization state" / Default: <Alt-F10>
  # - BNDNG: <Alt-F10>, <Shift-Ctrl-Alt-Up>
  # - ALTLY:
  #   - BNDNG: <Ctrl-Alt-/>, (<Ctrl-Alt-slash>, <C-D-/>)
  #   - REFER: Same binding as macOS > Rectangle > Maximize Height:
  #     - CXREF: See rectangle_customize() in ./bin/slather-defaults.sh.
  #   - LATER: Decide whether to change the Rectangle binding.
  #     - Most Rect. resize bindings are <Shift-Ctrl-Alt>, but not
  #       <Ctrl-Alt-/>. (And I don't remember why I plumbed it that way.)
  gsettings_set "Keyboard Shortcuts > Windows > Toggle maximization state" \
    gsettings set org.gnome.desktop.wm.keybindings toggle-maximized \
    "['<Alt-F10>', '<Shift><Control><Alt>Up', '<Control><Alt>slash']"

  # "Toggle fullscreen mode" / Default: Disabled
  # - Why you might like *toggle-fullscreen*:
  #   - It hides the titlebar.
  #   - It toggles back to the original window dimensions,
  #     *unlike toggle-maximized*.
  #   - Why you might like GNOME/Wayland/mutter
  #     toggle-fullscreen better than macOS fullscreen:
  #     - macOS fullscreen sends the window to another Space,
  #       which is an annoying transition/animation (at least
  #       IMHO), and then Alt-Tab doesn't work smoothly (e.g.,
  #       Alt-Tab does a sideways transition to the adjacent
  #       Space, which is less responsive than normal Alt-Tab,
  #       and also annoying to look at (again, IMHO)).
  #     - In GNOME Shell/Wayland/mutter fullscreen, you can
  #       still bring other windows to the front.
  #       - I find the GNOME Shell/Wayland/mutter experience
  #         to match my mental model of what to expect from
  #         fullscreen, unlike the macOS implementation —
  #         basically, a fullscreen window behaves like any
  #         other normal window; it just doesn't have a
  #         titlebar... well, it also can't be resized (and
  #         not with begin-resize (<Alt-F8> either)).
  # - REFER: This is <Ctrl-Cmd-F> in macOS (the OS default).
  #   - I prefer <Shift-Ctrl-F>, but we'll map both, the
  #     latter for muscle memory/parity.
  # - BNDNG: <Shift-Ctrl-F>, <Ctrl-Cmd-F>
  gsettings_set "Keyboard Shortcuts > Windows > Toggle fullscreen mode" \
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen \
    "['<Shift><Control>f', '<Control><Super>f']"

  # ***

  # MOVED: "Move window": See "begin-move" alongside "begin-resize".

  # ***

  # "Lower window below other windows" / Default: Disabled
  # - BNDNG: <Shift-Alt-/> (Shift-Alt-slash, Shift-Alt-forwardslash)
  gsettings_set "Keyboard Shortcuts > Windows > Lower window below other windows" \
    gsettings set org.gnome.desktop.wm.keybindings lower "['<Shift><Alt>slash']"

  # Raise window above other windows: Disabled [default]
  # - ALTLY: Wire "raise-or-lower" to <Alt-/>, and disable "raise", e.g.:
  #     gsettings_set "Keyboard Shortcuts > Windows > Raise window above other windows" \
  #       gsettings reset org.gnome.desktop.wm.keybindings raise
  #   - UCASE: When "raise-on-click" is disabled, you can focus a
  #     window that's not the frontmost window. Then you can use
  #     "raise" or "raise-or-lower" to bring the focused window
  #     to the front.
  #     - The "issue" with "raise-or-lower" is that it'll minimize
  #       the frontmost window if it's the one with focus. But I
  #       don't think of this operation as a toggle. Rather, it's
  #       just to ensure the focused window is frontmost.
  #     - That said, we'll wire "lower" (to <Shift-Alt-/>) so that
  #       you can deliberately lower the frontmost window — though
  #       note that it'll still have focus! But this allows you to
  #       lower a window behind another window, perhaps to peak at
  #       something temporarily, perhaps to transcribe something
  #       without having to rearrange windows, etc.
  # - BNDNG: <Alt-/> (Alt-slash, Alt-forwardslash)
  #   - BNDNG: <Alt-1> (Alt-one)
  #     - UCASE: So left-handable (e.g., when right is mousing).
  #   - ALTLY: <Shift-Cmd-Z> — "['<Alt>slash', '<Shift><Super>z']"
  #     - ALTLY: <Shift-Ctrl-Alt-Z> also available in DepoXy.
  #       - ALTLY: So is <Shift-Ctrl-Z>.
  gsettings_set "Keyboard Shortcuts > Windows > Raise window above other windows" \
    gsettings set org.gnome.desktop.wm.keybindings raise \
    "['<Alt>slash', '<Alt>1']"

  # "Raise window if covered, otherwise lower it" / Default: Disabled
  # - CALSO: raise-or-lower (<Alt-/>) is esp. useful when raise-on-click is disabled.
  # - ALTLY: Wire "raise-or-lower" to <Alt-/>, and disable "raise", e.g.:
  #     # - BNDNG: <Alt-/> (Alt-slash, Alt-forwardslash)
  #     gsettings_set "Keyboard Shortcuts > Windows > Raise window if covered, otherwise lower it" \
  #       gsettings set org.gnome.desktop.wm.keybindings raise-or-lower \
  #       "['<Alt>slash']"
  gsettings_set "Keyboard Shortcuts > Windows > Raise window if covered, otherwise lower it" \
    gsettings reset org.gnome.desktop.wm.keybindings raise-or-lower

  # ***

  # "Move window" / Default: <Alt-F7>
  # - BNDNG: <Alt-F7>, and <Shift-Ctrl-Alt-;> aka:
  #   - BNDNG: (<Shift-Ctrl-Alt-:>, <Shift-Ctrl-Alt-semicolon>)
  gsettings_set "Keyboard Shortcuts > Windows > Move window: <Alt-F7>" \
    gsettings set org.gnome.desktop.wm.keybindings begin-move \
    "['<Alt>F7', '<Shift><Control><Alt>semicolon']"

  # "Resize window" / Default: <Alt-F8>
  # - BNDNG: <Alt-F8>, and <Shift-Ctrl-Alt-'> aka:
  #   - BNDNG: (<Shift-Ctrl-Alt-apostrophe>)
  gsettings_set "Keyboard Shortcuts > Windows > Resize window: <Alt-F8>" \
    gsettings set org.gnome.desktop.wm.keybindings begin-resize \
    "['<Alt>F8', '<Shift><Control><Alt>apostrophe']"

  # ***

  # MOVED: "Restore window": See "unmaximize" alongside "maximize" and "maximize-*".

  # MOVED: "Toggle fullscreen mode": See "toggle-fullscreen" alongside "maximize" etc.

  # MOVED: "Toggle maximization state": See "toggle-maximized" alongside "maximize" etc.

  # "Toggle window on all workspaces or one" / Default: Disabled
  gsettings_set "Keyboard Shortcuts > Windows > Toggle window on all workspaces or one: Disabled" \
    gsettings reset org.gnome.desktop.wm.keybindings toggle-on-all-workspaces

  # ***

  # USYNC: These two keybindings match similar macOS bindings.
  # - CXREF: See rectangle_customize() in ./bin/slather-defaults.sh.

  # "View split on left" / Default: <Cmd-Left>
  # - BNDNG: <Shift-Ctrl-Alt-[> (<Shift-Ctrl-Alt-LeftBracket>)
  gsettings_set "Keyboard Shortcuts > Windows > View split on left" \
    gsettings set org.gnome.mutter.keybindings toggle-tiled-left \
    "['<Shift><Control><Alt>bracketleft']"

  # "View split on right" / Default: <Cmd-Right>
  # - BNDNG: <Shift-Ctrl-Alt-]> (<Shift-Ctrl-Alt-RightBracket>)
  gsettings_set "Keyboard Shortcuts > Windows > View split on right" \
    gsettings set org.gnome.mutter.keybindings toggle-tiled-right \
    "['<Shift><Control><Alt>bracketright']"
}

#      ++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > WINDOWS > [HIDDEN SETTINGS]
#      ++++++++++++++++++++++++++++

# If you poke around the schemas, you'll find a number of
# unadvertised settings. (Call 'em "hidden" if you want,
# but technically they're visible through dconf/gsettings.)
#
# - CPYST: Execute a dry-run with counts to see a list of
#   all schemas this script manages:
#
#   $ ./bin/slather-gsettings.sh --dry-run --force --count
#
# Hidden Window keybindings.
#
# - A subset of wm.keybindings, including all those not
#   settable from GNOME Settings:
#
#   $ gsettings list-recursively org.gnome.desktop.wm.keybindings
#   ...
#   # Oddly, there's no opposite to *always-on-top*.
#   # - Use instead: *toggle-above*
#   org.gnome.desktop.wm.keybindings always-on-top @as []
#   ...
#   org.gnome.desktop.wm.keybindings move-to-center @as []
#   ...
#   org.gnome.desktop.wm.keybindings move-to-corner-ne @as []
#   org.gnome.desktop.wm.keybindings move-to-corner-nw @as []
#   org.gnome.desktop.wm.keybindings move-to-corner-se @as []
#   org.gnome.desktop.wm.keybindings move-to-corner-sw @as []
#   ...
#   org.gnome.desktop.wm.keybindings move-to-side-e @as []
#   org.gnome.desktop.wm.keybindings move-to-side-n @as []
#   org.gnome.desktop.wm.keybindings move-to-side-s @as []
#   org.gnome.desktop.wm.keybindings move-to-side-w @as []
#   ...
#   org.gnome.desktop.wm.keybindings panel-main-menu ['<Alt>F1']
#   org.gnome.desktop.wm.keybindings panel-run-dialog ['<Alt>F2']
#   ...
#   # DUNNO: I searched the web (but not sources), and couldn't
#   # find an explanation for this strangely-titled setting.
#   org.gnome.desktop.wm.keybindings set-spew-mark @as []
#   ...
#   org.gnome.desktop.wm.keybindings toggle-above @as []
#
# ***
#
# Hidden Preferences settings.
#
# - A partial list of wm.preferences, including all those
#   not settable from GNOME Settings GUI:
#
#   $ gsettings list-recursively org.gnome.desktop.wm.preferences
#   ...
#
# - Reveals:
#
#   # Some of these are exposed in GNOME Tweaks.
#   org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
#   org.gnome.desktop.wm.preferences action-middle-click-titlebar 'none'
#   org.gnome.desktop.wm.preferences action-right-click-titlebar 'menu'
#   org.gnome.desktop.wm.preferences audible-bell true
#   org.gnome.desktop.wm.preferences auto-raise false
#   org.gnome.desktop.wm.preferences auto-raise-delay 500
#   org.gnome.desktop.wm.preferences disable-workarounds false
#   org.gnome.desktop.wm.preferences focus-mode 'click'
#   org.gnome.desktop.wm.preferences focus-new-windows 'smart'
#   org.gnome.desktop.wm.preferences raise-on-click false
#   org.gnome.desktop.wm.preferences resize-with-right-button false
#   org.gnome.desktop.wm.preferences theme 'Adwaita'
#   org.gnome.desktop.wm.preferences titlebar-font 'Hack Nerd Font 11'
#   org.gnome.desktop.wm.preferences titlebar-uses-system-font true
#   org.gnome.desktop.wm.preferences visual-bell false
#   org.gnome.desktop.wm.preferences visual-bell-type 'fullscreen-flash'
#   org.gnome.desktop.wm.preferences workspace-names @as []
#
#   # Exposed in Multitasking settings:
#   org.gnome.desktop.wm.preferences num-workspaces 4
#
#   # Exposed in GNOME Tweaks:
#   org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'
#   org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'
#
# ***
#
# Hidden Mutter keybindings.
#
# - A list of the 5 total wm.preferences settings:
#
#   $ gsettings list-recursively org.gnome.mutter.keybindings
#   org.gnome.mutter.keybindings cancel-input-capture ['<Super><Shift>Escape']
#   org.gnome.mutter.keybindings rotate-monitor ['XF86RotateWindows']
#   org.gnome.mutter.keybindings switch-monitor ['<Super>p', 'XF86Display']
#   # Exposed in Keyboard Shortcuts > Windows:
#   org.gnome.mutter.keybindings toggle-tiled-left ['<Super>Left']
#   org.gnome.mutter.keybindings toggle-tiled-right ['<Super>Right']
#
# ***
#
# Some of the Mutter-Wayland keybindings, including all "hidden" settings.
#
#   $ gsettings list-recursively org.gnome.mutter.wayland.keybindings
#
#   # Exposed in Keyboard Shortcuts > System settings:
#   org.gnome.mutter.wayland.keybindings restore-shortcuts ['<Super>Escape']
#
#   # Hidden settings:
#   org.gnome.mutter.wayland.keybindings switch-to-session-1 ['<Primary><Alt>F1']
#   org.gnome.mutter.wayland.keybindings switch-to-session-2 ['<Primary><Alt>F2']
#   org.gnome.mutter.wayland.keybindings switch-to-session-3 ['<Primary><Alt>F3']
#   org.gnome.mutter.wayland.keybindings switch-to-session-4 ['<Primary><Alt>F4']
#   org.gnome.mutter.wayland.keybindings switch-to-session-5 ['<Primary><Alt>F5']
#   org.gnome.mutter.wayland.keybindings switch-to-session-6 ['<Primary><Alt>F6']
#   org.gnome.mutter.wayland.keybindings switch-to-session-7 ['<Primary><Alt>F7']
#   org.gnome.mutter.wayland.keybindings switch-to-session-8 ['<Primary><Alt>F8']
#   org.gnome.mutter.wayland.keybindings switch-to-session-9 ['<Primary><Alt>F9']
#   org.gnome.mutter.wayland.keybindings switch-to-session-10 ['<Primary><Alt>F10']
#   org.gnome.mutter.wayland.keybindings switch-to-session-11 ['<Primary><Alt>F11']
#   org.gnome.mutter.wayland.keybindings switch-to-session-12 ['<Primary><Alt>F12']
#
# ***
#
#   $ gsettings list-recursively org.gnome.shell.keybindings
#
#   # Hidden settings:
#   org.gnome.shell.keybindings shift-overview-down ['<Super><Alt>Down']
#   org.gnome.shell.keybindings shift-overview-up ['<Super><Alt>Up']
#
#   # By default, these settings claim nice-to-have keybindings
#   # <Cmd-1>..<Cmd-9> and <Ctrl-Cmd-1>..<Ctrl-Cmd-9>.
#   # - We'll free these below (author uses <Cmd-1>..<Cmd-9 to
#   #   front numbered (via their titles) Alacritty windows:
#   org.gnome.shell.keybindings open-new-window-application-1 @as []
#   ...
#   org.gnome.shell.keybindings open-new-window-application-9 @as []
#   org.gnome.shell.keybindings switch-to-application-1 @as []
#   ...
#   org.gnome.shell.keybindings switch-to-application-9 @as []
#
#   # Exposed in Keyboard Shortcuts > System:
#   org.gnome.shell.keybindings focus-active-notification @as []
#   org.gnome.shell.keybindings toggle-application-view @as []
#   org.gnome.shell.keybindings toggle-message-tray ['<Shift><Control><Super>c']
#   org.gnome.shell.keybindings toggle-overview ['<Control><Alt>Down']
#   org.gnome.shell.keybindings toggle-quick-settings @as []
#
#   # Exposed in Keyboard Shortcuts > Screenshots:
#   org.gnome.shell.keybindings screenshot @as []
#   org.gnome.shell.keybindings screenshot-window @as []
#   org.gnome.shell.keybindings show-screen-recording-ui ['<Shift><Super>4']
#   org.gnome.shell.keybindings show-screenshot-ui @as []
#
# ***
#
#   $ gsettings list-recursively org.gnome.settings-daemon.plugins.media-keys
#
#   # These are mostly settings pairs, e.g.,
#   org.gnome.settings-daemon.plugins.media-keys battery-status ['']
#   org.gnome.settings-daemon.plugins.media-keys battery-status-static ['XF86Battery']
#   org.gnome.settings-daemon.plugins.media-keys calculator ['']
#   org.gnome.settings-daemon.plugins.media-keys calculator-static ['XF86Calculator']
#   # etc. (And there are lots of 'em.)
#
#   # There's also the one big array that registers all the custom keybindings:
#   org.gnome.settings-daemon.plugins.media-keys custom-keybindings
#   # - Author currently has 83(!) custom-keybindings registered (and
#   #   that doesn't include other keybindings managed by run-or-raise)
#   #   which looks like this:
#   #   ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', ...
#   #    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom81/']
#
#   # Ignoring everything else, here are the interesting settings,
#   # or at least those assigned keybindings:
#   # - You'll find "logout" on Keyboard Shortcuts > System:
#   org.gnome.settings-daemon.plugins.media-keys logout ['<Control><Alt>Delete']
#   org.gnome.settings-daemon.plugins.media-keys magnifier ['<Alt><Super>8']
#   org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-in ['<Alt><Super>equal']
#   org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-out ['<Alt><Super>minus']
#   org.gnome.settings-daemon.plugins.media-keys rotate-video-lock ['']
#   org.gnome.settings-daemon.plugins.media-keys rotate-video-lock-static ['<Super>o', 'XF86RotationLockToggle']
#   org.gnome.settings-daemon.plugins.media-keys screenreader ['<Alt><Super>s']
#   # - You'll find "screensaver" on Keyboard Shortcuts > System:
#   org.gnome.settings-daemon.plugins.media-keys screensaver ['<Control><Super>q']
#   org.gnome.settings-daemon.plugins.media-keys screensaver-static ['XF86ScreenSaver']

gnome_settings_customize_keyboard_windows_hidden() {
  # Note how move-to compares to toggle-tiled:
  #   org.gnome.mutter.keybindings toggle-tiled-left
  #   org.gnome.mutter.keybindings toggle-tiled-right
  # - The move-to commands *snap* the window to the screen edge
  #   without changing the window dimensions, whereas the
  #   toggle-tiled commands *snap* and resize the window
  #   to half the screen.

  # USYNC: These 4 bindings match similar window-snaps in macOS.
  # - CXREF: See rectangle_customize() in ./bin/slather-defaults.sh.

  # BNDNG: <Shift-Ctrl-Cmd-Left>, <Shift-Ctrl-Alt-Delete> (<M-C-S-Del>)
  gsettings_set "Keyboard Shortcuts > Windows [Hidden] > Move to Left" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-w \
    "['<Shift><Control><Super>Left', '<Shift><Control><Alt>Delete']"

  # BNDNG: <Shift-Ctrl-Cmd-Right>, <Shift-Ctrl-Alt-End>
  gsettings_set "Keyboard Shortcuts > Windows [Hidden] > Move to Right" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-e \
    "['<Shift><Control><Super>Right', '<Shift><Control><Alt>End']"

  # BNDNG: <Shift-Ctrl-Cmd-Up>, <Shift-Ctrl-Alt-PageUp>
  gsettings_set "Keyboard Shortcuts > Windows [Hidden] > Move to Top" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-n \
    "['<Shift><Control><Super>Up', '<Shift><Control><Alt>Page_Up']"

  # BNDNG: <Shift-Ctrl-Cmd-Down>
  # - BNDNG: <Shift-Ctrl-Alt-PageDown>
  #   - UCASE: So author can properly size and position Neovide
  #     window using <Shift-Ctrl-Alt> keybindings (because I
  #     want a mostly-fullscreen window, and I haven't figured
  #     out how to make one without using multiple window
  #     commands: <Shift-Ctrl-Alt-Up>   toggle-maximized (if necessary)
  #               <Shift-Ctrl-Alt-\>    maximize-horizontally
  #               <Shift-Ctrl-Alt-PgDn> move-to-side-s (or begin-move)
  #               <Shift-Ctrl-Alt-'>    begin-resize
  gsettings_set "Keyboard Shortcuts > Windows [Hidden] > Move to Bottom" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-side-s \
    "['<Shift><Control><Super>Down', '<Shift><Control><Alt>Page_Down']"

  # ***

  # move-to-center / Default: Disabled:
  #   gsettings_set "Keyboard Shortcuts > Window [Hidden] > ∅ move-to-center" \
  #     gsettings reset org.gnome.desktop.wm.keybindings move-to-center
  #
  # BNDNG: <Shift-Ctrl-Cmd-'> (<Shift-Ctrl-Cmd-apostrophe>)
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > move-to-center" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-center \
    "['<Shift><Control><Super>apostrophe']"

  # move-to-corner-* / Default: Disabled:
  #   gsettings_set "Keyboard Shortcuts > Window [Hidden] > ∅ move-to-corner-ne" \
  #     gsettings reset org.gnome.desktop.wm.keybindings move-to-corner-ne
  #   gsettings_set "Keyboard Shortcuts > Window [Hidden] > ∅ move-to-corner-nw" \
  #     gsettings reset org.gnome.desktop.wm.keybindings move-to-corner-nw
  #   gsettings_set "Keyboard Shortcuts > Window [Hidden] > ∅ move-to-corner-se" \
  #     gsettings reset org.gnome.desktop.wm.keybindings move-to-corner-se
  #   gsettings_set "Keyboard Shortcuts > Window [Hidden] > ∅ move-to-corner-sw" \
  #     gsettings reset org.gnome.desktop.wm.keybindings move-to-corner-sw
  #
  # Author's keyboard has a nice 2 x 2 grid I use for corners:
  #    Home   PageUp
  #    End    PageDown
  # BNDNG: <Shift-Ctrl-Cmd-PageUp>
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > move-to-corner-ne" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-ne \
    "['<Shift><Control><Super>Page_Up']"
  # BNDNG: <Shift-Ctrl-Cmd-Home>
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > move-to-corner-nw" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-nw \
    "['<Shift><Control><Super>Home']"
  # BNDNG: <Shift-Ctrl-Cmd-PageDown>
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > move-to-corner-se" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-se \
    "['<Shift><Control><Super>Page_Down']"
  # BNDNG: <Shift-Ctrl-Cmd-End>
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > move-to-corner-sw" \
    gsettings set org.gnome.desktop.wm.keybindings move-to-corner-sw \
    "['<Shift><Control><Super>End']"

  # ***

  # ILIKE: I love this! While it might be a little annoying while you
  # get used to the new behavior, it enables a number of interesting
  # workflows, like leaving your text editor fullscreen and working
  # on code while having another window in front of it (but without
  # focus).
  # - This setting works well with the <Alt-/> command which'll
  #   officially raise the window that has focus:
  #     org.gnome.desktop.wm.keybindings raise-or-lower
  # - This also makes Alt-Click-Dragging a background window behave
  #   more like macOS Easy Move+Resize — it won't bring an Alt-Clicked
  #   window to the front while you reposition it.
  # - CALSO: raise-or-lower (<Alt-/>) is esp. useful when raise-on-click is disabled.
  gsettings_set "Keyboard Shortcuts > Window Prefs. [Hidden] > ∅ Raise on Click" \
    gsettings set org.gnome.desktop.wm.preferences raise-on-click false

  # ***

  # As noted above (Oddly), there's no opposite to *always-on-top*.
  # - But you can use *toggle-above* to unsticky such a window.
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > ∅ Always on Top" \
    gsettings reset org.gnome.desktop.wm.keybindings always-on-top
  # Wire 'toggle-above', which sets/unsets Always On Top, which
  # you can also access by right-clicking a window's titlebar.
  # - UCASE: Keep Spotify on top when you're "listening" to a
  #   podcase that includes video.
  # - !CASE: This feature not necessary for Web browser
  #   Picture-in-Picture to be sticky on-top. See instead
  #   the elegant *PiP On Top* GNOME Shell extension:
  #     https://extensions.gnome.org/extension/4691/pip-on-top/
  #     https://github.com/Rafostar/gnome-shell-extension-pip-on-top
  # - UCASE: Is that it, Spotify? I don't think I've ever used
  #   always-on-top other than for video.
  # BNDNG: <Shift-Ctrl-Alt-P>
  # - Mnemonic: always-on-toP
  # - CALSO: <Shift-Ctrl-Alt-O> toggles (mouse) Focus Mode
  #   (sorta related, in that it affects window interaction).
  gsettings_set "Keyboard Shortcuts > Window [Hidden] > Toggle Above" \
    gsettings set org.gnome.desktop.wm.keybindings toggle-above \
    ["'<Shift><Primary><Alt>p'"]

  # ***

  gsettings_set "Keyboard Shortcuts > Window Prefs. [Hidden] > ∅ Titlebar Uses System Font" \
    gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

  # ***

  # Open GNOME 2 Application menu / Default: ['<Alt>F1']
  # - Except there is no Application menu in GNOME 3/GNOME Shell.
  #   - In fact, even though this binding appears like it might be wired, e.g.:
  #       $ gsettings reset org.gnome.desktop.wm.keybindings panel-main-menu
  #       $ gsettings get org.gnome.desktop.wm.keybindings panel-main-menu
  #       ['<Alt>F1']
  #     pressing <Alt-F1> has the same effect as just pressing <F1>
  #     (e.g., my <F1> search binding in Neovim is triggered).
  #   - REFER:
  #     https://discourse.gnome.org/t/difference-between-show-the-overview-and-show-the-activities-overview-keyboard-shortcuts/6572
  # - CALSO: See somewhat-related "panel-run-dialog" GNOME Shell binding:
  #   - *Show GNOME Shell "Run a command" popup / Default: ['<Alt>F2']*
  gsettings_set "Keyboard Shortcuts > System [Hidden] > ∅ Show the main menu" \
    gsettings set org.gnome.desktop.wm.keybindings panel-main-menu '@as []'

  # ***

  # Release <Ctrl-Cmd-1>..<Ctrl-Cmd-9> (open-new-window-application)
  # as well as <Cmd-1>..<Cmd-9> (switch-to-application).
  # - BNDNG: <Cmd-1|2|3|4|5|6|7|8|9>, <Ctrl-Cmd-1|2|3|4|5|6|7|8|9>
  for idx in $(seq 1 9); do
    gsettings_set "Keyboard Shortcuts > Shell Keybindings [Hidden] > ∅ Open New Window App #${idx}" \
      gsettings set org.gnome.shell.keybindings open-new-window-application-${idx} '@as []'
    gsettings_set "Keyboard Shortcuts > Shell Keybindings [Hidden] > ∅ Switch to App #${idx}" \
      gsettings set org.gnome.shell.keybindings switch-to-application-${idx} '@as []'
  done

  # These two commands advance from desktop
  # view > Overview > Apps, and in reverse.
  # - Note that 'shift-overview-up' is similar
  #          to 'toggle-overview',
  #   at least when first pressed.
  #   - When first pressed, 'shift-overview-up' shows the Activities Overview.
  #   - If you press it again, you'll see the Apps list (aka App Grid, or
  #     Application Overview), same as if you clicked the 3x3 grid button ᎒᎒᎒
  #     at the bottom of the dash to view all your installed applications.
  #   - And 'shift-overview-down' advances in reverse, from Apps back to
  #     Overview back to your desktop.
  # - ISOFF: Author's Neovim keybindings use <Cmd-Alt-Up> and <Cmd-Alt-Down>,
  #   so disabling these.
  #   - I use 'toggle-overview' (<Ctrl-Alt-Down>) to show/hide Overview.
  #   - I almost never use the App Grid (maybe once to see what apps
  #     Debian installed by default).
  #
  # "Shift Overview Up" [Hidden] / Default: ['<Super><Alt>Up'] (<Cmd-Alt-Up>)
  gsettings_set "Keyboard Shortcuts > Shell Keybindings [Hidden] > ∅ Shift Overview Up" \
    gsettings set org.gnome.shell.keybindings shift-overview-up '@as []'
  # "Shift Overview Down" [Hidden] / Default: ['<Super><Alt>Down'] (<Cmd-Alt-Down>)
  gsettings_set "Keyboard Shortcuts > Shell Keybindings [Hidden] > ∅ Shift Overview Down" \
    gsettings set org.gnome.shell.keybindings shift-overview-down '@as []'
}

#      +++++++++++++++++++++++++++++++++++++
# **** KEYBOARD SHORTCUTS > CUSTOM SHORTCUTS
#      +++++++++++++++++++++++++++++++++++++

# CXREF: See run-or-raise/shortcuts.conf in DepoXy:
#   https://github.com/DepoXy/depoxy#🍯
#     ~/.depoxy/ambers/home/.config/run-or-raise/shortcuts-depoxy
# - Which is utilizes the stellar run-or-raise extension:
#   https://extensions.gnome.org/extension/1336/run-or-raise/
# CXREF: See also Ansible task for adding custom keybindings:
# - (This is my legacy approach for keybindings; run-or-raise
#    is a much more elegant, simpler approach than this
#    complicated gobbledygook):
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
    dconf write /org/gtk/settings/file-chooser/clock-format "'24h'"

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

  gnome_tweaks_customize_fonts
  gnome_tweaks_customize_appearance
  gnome_tweaks_customize_sound
  gnome_tweaks_customize_mouse_and_touchpad
  gnome_tweaks_customize_keyboard
  gnome_tweaks_customize_windows
  gnome_tweaks_customize_startup_applications
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

gnome_tweaks_customize_appearance() {
  # So that GVim, etc., window titlebars match dark theme.
  # Default: "Adwaita (default)" ('Adwaita')
  gsettings_set "Tweaks > Appearance > Styles > Legacy Applications: " \
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
}

# ***

# Nothing to change.
gnome_tweaks_customize_sound() {
  # *** Tweaks > Windows > Sound
  #
  #     - 1 settings (and 1 GSettings)
  #
  # Default settings:
  # - Tweaks > Sound > System Sound Theme: Default (Choices: Default | Custom)
  #
  # Default GSettings:
  #   # Choices: 'freedesktop' | '__custom'
  #   gsettings set org.gnome.desktop.sound theme-name 'freedesktop'
  #
  # DUNNO: This is 'Custom' on author's machine, but not sure how this setting is used.
  :
}

# ***

# Nothing to change.
gnome_tweaks_customize_mouse_and_touchpad() {
  # *** The 1 org.gnome.desktop.interface mouse-behavior-related setting
  #     (well, 2, if you count enable-hot-corners).
  #
  # HSTRY: Not found in GNOME Shell 48 Tweaks.
  # - Does nothing when enabled in GNOME Shell 48.
  # - PREVY: Was at: Tweaks > Keyboard & Mouse > Pointer Location.
  #   - Note that, in latest Tweaks, Tweaks > Keyboard & Mouse is
  #     separated: Tweaks > Mouse & Touchpad, and Tweaks > Keyboard.
  #   - This would eminate ripples from cursor position:
  #       gsettings set org.gnome.desktop.interface locate-pointer true
  :

  # *** org.gnome.desktop.peripherals.touchpad has 2 GSettings.
  #
  # HSTRY: The old Tweaks Touchpad settings to adjust Mouse Click Emulation
  # and Scrolling Method and now part of normal GNOME Settings > Mouse & Touchpad.
  :
}

# ***

# Nothing to change.
gnome_tweaks_customize_keyboard() {
  :
}

# ***

gnome_tweaks_customize_windows() {
  # *** Tweaks > Windows > Titlebar Actions
  #
  #     - 3 settings (and 3 GSettings)
  #
  # Default settings:
  # - Tweaks > Windows > Titlebar Actions > Double-Click: Toggle Maximize
  # - Tweaks > Windows > Titlebar Actions > Middle-Click: None
  # - Tweaks > Windows > Titlebar Actions > Secondary-Click: Menu
  #
  # Default GSettings (maximize on double-, menu on right-, nothing on middle-click):
  #   gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize'
  #   gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'none'
  #   gsettings set org.gnome.desktop.wm.preferences action-right-click-titlebar 'menu'
  #
  # Each setting has a drop-down with the following options:
  #   Toggle Shade:                 'toggle-shade'
  #   Toggle Maximize:              'toggle-maximize-horizontally'
  #   Toggle Maximize Horizontally: 'toggle-maximize'
  #   Toggle Maximize Vertically:   'toggle-maximize-vertically'
  #   Minimize:                     'minimize'
  #   None:                         'none'
  #   Lower:                        'lower'
  #   Menu:                         'menu'
  :

  # *** Tweaks > Windows > Titlebar Buttons
  #
  #     - 3 settings (and 1 GSettings)
  #
  # Default settings:
  # - Tweaks > Windows > Titlebar Buttons > Maximize: Disabled
  # - Tweaks > Windows > Titlebar Buttons > Minimize: Disabled
  # - Tweaks > Windows > Titlebar Buttons > Placement: Right
  #
  # Default GSettings (close button on the right):
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close'
  #
  # SAVVY: What author prefers: Close and minimize buttons on the left:
  #   gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'
  #
  # Comparing different settings:
  # - Tweaks > Windows > Titlebar Buttons > Maximize: Disabled|Enabled
  #   - When enabled, and Placement is left:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'close,maximize:appmenu'
  #   - When enabled, and Placement is right:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close,maximize'
  # - Tweaks > Windows > Titlebar Buttons > Minimize: Disabled|Enabled
  #   - When enabled, and Placement is left:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'
  #   - When enabled, and Placement is right:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,close'
  #   - When enabled, Maximize also enabled, and Placement is left:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
  #   - When disabled, Maximize also disabled, and Placement is left:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'close:appmenu'
  # - Tweaks > Windows > Titlebar Buttons > Placement: Left|Right
  #   - Defaults close button on the right, and neither Minimize, nor Maximize:
  #     gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:close'
  #
  # - Move the window buttons to the left side of the titlebar,
  #   to be consistent with macOS (noting that the macOS window
  #   buttons placement is not configurable, so if you appreciate
  #   parity, this is the only choice).
  #   - And show Close and Minimize, but not Maximize.
  gsettings_set \
    "Tweaks > Window > Titlebar Buttons > (like macOS): ∅ Maximize + ✓ Minimize + Placement: Left" \
    gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize:appmenu'

  # *** Tweaks > Windows > Click Actions
  #
  #     - 4 settings (and 4 GSettings)
  #
  # Default settings:
  # - Tweaks > Windows > Click Actions > Attach Modal Dialogs: Enabled
  # - Tweaks > Windows > Click Actions > Center New Windows: Disabled
  # - Tweaks > Windows > Click Actions > Window Action Key: Super [Choices: Disabled | Alt | Super]
  # - Tweaks > Windows > Click Actions > Resize with Secondary-Click: Disabled
  #
  # Default GSettings:
  #   gsettings set org.gnome.mutter attach-modal-dialogs true
  #   gsettings set org.gnome.mutter center-new-windows false
  #   # Choices: 'disabled' | '<Alt>' | '<Super>'
  #   gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Super>'
  #   gsettings set org.gnome.desktop.wm.preferences resize-with-right-button false
  #
  # - Tweaks > Windows > Click Actions > Attach Modal Dialogs: Disabled
  #   - *When on, modal dialog windows are attached to their parent window,
  #      and cannot be moved.*
  #   - UCASE: Sometimes when I save a PDF in Chrome, the Save-As dialog blocks
  #     information I might use to name the saved file. When this setting disabled,
  #     I can Alt-drag the Chrome window beneath the save dialog, or I can move the
  #     save dialog itself, independently of the other window, thereby uncovering
  #     said blocked information.
  #     - DUNNO: There might be a disadvantage to "ungrouping" a modal dialog
  #       from its parent window, but I'm not sure what that might be.
  gsettings_set "Tweaks > Windows > Click Actions > ∅ Attach Modal Dialogs" \
    gsettings set org.gnome.mutter attach-modal-dialogs false

  # - Tweaks > Windows > Click Actions > Window Action Key: Alt
  #   - GNOME Shell defaults Cmd-Drag to move windows, whereas ye olde
  #     MATE (effectively GNOME 2) defaults Alt-Drag.
  #   - Author is used to, and probably why they prefer, Alt-dragging (also
  #     how I've got macOS configured using Easy Move+Resize application).
  #   - Defaults: Super (Choices: 'disabled'|'<Alt>'|'<Super>')
  gsettings_set "Tweaks > Windows > Click Actions > Window Action Key: <Alt>" \
    gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'

  # *** Tweaks > Windows > Window Focus
  #
  #     - 2 settings (and 2 GSettings)
  #
  # Default settings:
  # - Tweaks > Windows > Window Focus > ✓ Click to Focus
  #   - [Choices: Click to Focus, Focus on Hover, Focus Follows Mouse]
  # - Tweaks > Windows > Window Focus > Raise Windows When Focused: Disabled
  #
  # Default GSettings:
  #   # Choices: 'click' | 'sloppy'| 'mouse'
  #   gsettings set org.gnome.desktop.wm.preferences focus-mode 'click'
  #   # Applies to 'sloppy' or 'mouse', but not to 'click' focus-mode.
  #   gsettings set org.gnome.desktop.wm.preferences auto-raise false
  :
}

# ***

# Nothing to change.
gnome_tweaks_customize_startup_applications() {
  # HSTRY: Not found in GNOME Shell 48 Tweaks.
  # - PREVY: Previously, when you disable
  #     Tweaks > General > Suspend when laptop lid is closed
  #   you'd see this app under Tweaks > Startup Application:
  #     ignore-lid-switch-tweak
  :
}

# +++ END: GNOME Tweaks GUI settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ GNOME Terminal GUI settings

gnome_terminal_customize() {
  echo -e "\n$(highlight_soft "*** gnome-terminal")\n"

  # ***

  # SAVVY: Use dconf to access org.gnome.Terminal, not gsettings:
  #   $ gsettings list-recursively org.gnome.Terminal
  #   No such schema “org.gnome.Terminal”
  # - Obstensibly because gnome-terminal hasn't defined or
  #   registered a schema, or your author has not installed
  #   whatever provides it.
  #
  # ASIDE: Note the trailing and leading colons.
  # - It that a special gsettings construct, or (more likely?) is
  #   it just part of the key name, and gsettings treats ':' no
  #   different than an alphanum? [I'm just curious, no biggee.]
  # - E.g.:
  #     dconf read \                         ↓ ↓
  #       /org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/font
  #     'Hack Nerd Font Mono 11'             ↑ ↑
  local profile_id
  profile_id="$(
    gsettings get org.gnome.Terminal.ProfilesList default | sed "s/^'\\(.*\\)'\$/\\1/"
  )"

  if [ -z "${profile_id}" ]; then
    >&2 echo
    >&2 echo "ERROR: Skipping GNOME Terminal config: Could not suss Profile ID"
    >&2 echo

    return
  fi

  # ***

  gnome_terminal_customize_general
  gnome_terminal_customize_shortcuts
  gnome_terminal_customize_profiles_0_text "${profile_id}"
  gnome_terminal_customize_profiles_0_colors "${profile_id}"
  gnome_terminal_customize_profiles_0_scrolling "${profile_id}"
  gnome_terminal_customize_profiles_0_command "${profile_id}"
  gnome_terminal_customize_compatibility
}

# ***

gnome_terminal_customize_general() {
  # Defaults: Default ('system'), same as 'light'
  # - CALSO: GNOME Terminal: Profiles: Default: Colors: Text and Background Color
  dconf_write "GNOME Terminal > General > Theme variant: Dark" \
    dconf write "/org/gnome/terminal/legacy/theme-variant" "'dark'"
}

# ***

# INERT: Author has since switched from gnome-terminal to Alacritty,
# otherwise I might've customized gnome-terminal shortcuts.
gnome_terminal_customize_shortcuts() {
  :
}

# ***

# org.gnome.Terminal.ProfilesList default 'b1dcc9dd-5262-4d8d-a863-c897e6d979b9'
# org.gnome.Terminal.ProfilesList list ['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']
# org.gnome.Terminal.Legacy.Settings <key> <val>
# org.gnome.Terminal.Legacy.Keybindings <key> <val>
gnome_terminal_customize_profiles_0_text() {
  local profile_id="$1"

  local menu_path="GNOME Terminal > Profiles: Default"

  if is_hack_font_installed; then
    # Default: Monospace
    dconf_write "${menu_path} > Text > Text Appearance > Custom font: Hack Nerd Font Mono 11" \
      dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/font" \
      "'Hack Nerd Font Mono 11'"
  else
    >&2 echo "ALERT: Skipping: ${menu_path}: Text > Text Appearance > Custom font: Hack Nerd Font"
  fi

  # ***

  # Default: 80 columns x 24 rows
  dconf_write "${menu_path} > Text > Text Appearance > Initial terminal size: 112 columns" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/default-size-columns" "112"

  # Default: 80 columns x 24 rows
  dconf_write "${menu_path} > Text > Text Appearance > Initial terminal size: 42 rows" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/default-size-rows" "42"

  # ***

  # Default: "Default" ('system'), same as Enabled
  dconf_write "${menu_path}: Cursor > Cursor blinking: Disabled" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/cursor-blink-mode" "'off'"

  # Default: Enabled
  dconf_write "GNOME Terminal: Profiles: Default: Sound: Terminal Bell: Disabled" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/audible-bell" "false"
}

# ***

gnome_terminal_customize_profiles_0_colors() {
  local profile_id="$1"

  local menu_path="GNOME Terminal > Profiles: Default"

  # Default: Enabled (though with GNOME Dark mode, terminal sill black on white).
  # - CALSO: GNOME Terminal: General: Theme variant: Dark
  dconf_write "${menu_path} > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/use-theme-colors" "false"

  dconf_write "${menu_path} > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/foreground-color" "'rgb(255,255,255)'"

  dconf_write "${menu_path} > Colors > Text and Background Color > Built-in schemes: White on black" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/background-color" "'rgb(0,0,0)'"

  # Author: IMO, XTerm color palette is a titch brighter, easier to read than GNOME's.

  dconf_write "${menu_path} > Colors > Palette > Built-in schemes: XTerm" \
    dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/palette" \
    "['rgb(0,0,0)', 'rgb(205,0,0)', 'rgb(0,205,0)', 'rgb(205,205,0)', 'rgb(0,0,238)', 'rgb(205,0,205)', 'rgb(0,205,205)', 'rgb(229,229,229)', 'rgb(127,127,127)', 'rgb(255,0,0)', 'rgb(0,255,0)', 'rgb(255,255,0)', 'rgb(92,92,255)', 'rgb(255,0,255)', 'rgb(0,255,255)', 'rgb(255,255,255)']"
}

# ***

# Nothing to change.
gnome_terminal_customize_profiles_0_scrolling() {
  local profile_id="$1"

  # Default: Enabled ('always')
  #   dconf_write "GNOME Terminal: Profiles: Default: Scrolling: Show scrollbar: Disabled" \
  #   dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/scrollbar-policy" "'never'"

  # Default: 10000
  #   dconf_write "GNOME Terminal: Profiles: Default: Scrolling: Limit scrollback to: 10000" \
  #   dconf write "/org/gnome/terminal/legacy/profiles:/:${profile_id}/scrollback-lines" "10000"
  :
}

# ***

# INERT/2025-01-12: Add Profiles.
# - GNOME Terminal > Profiles > Command >
#   - ✓ Run a custom command instead of my shell
#   - Custom command: <E.g., Start Vanilla terminal, etc.>
gnome_terminal_customize_profiles_0_command() {
  local profile_id="$1"

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
# +++ User Application settings

#     ============
# *** APP: FIREFOX
#     ============

firefox_customize() {
  print_at_end+=("\
${OMR_REMINDER_UNKNOWN:-🔳} Firefox > Startup > ✓ Open previous windows and tabs")
}

#     ============
# *** APP: GNUCASH
#     ============

# CXREF: Not configured here (but could be).
# - See separate Ansible play for setting GnuCash settings:
#   https://github.com/landonb/zoidy_apps_et_al 🦞
#     https://github.com/landonb/zoidy_apps_et_al/blob/release/tasks/app-gnucash-conf.yml

gnucash_customize() {
  :
}

# +++ END: User Application settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ GNOME Extensions settings

#     ==========================================
# *** EXTENSION: DESKTOP WIDGETS (DESKTOP CLOCK)
#     ==========================================

# REFER: *Desktop Widgets (Desktop Clock)* by *andrew_z*
# https://extensions.gnome.org/extension/5156/desktop-clock/
# https://gitlab.com/AndrewZaech/azclock

gnome_extension_desktop_widgets_customize() {
  # This extension must be configured manually, AFAICT, ah, well.
  # - FTREQ/2026-02-04: Publish configuration steps,
  #   and add link to ${print_at_end} reminder.

  return 0
}

#     =========================
# *** EXTENSION: HIDE MINIMIZED
#     =========================

# REFER: *Hide minimized* by *danigm*
# https://extensions.gnome.org/extension/2639/hide-minimized/
# https://github.com/danigm/hide-minimized
# https://github.com/landonb/hide-minimized

gnome_extension_hide_minimized_customize() {
  # No-op: No settings dialog.

  return 0
}

#     =======================
# *** EXTENSION: HIDE TOP BAR
#     =======================

# REFER: *Hide Top Bar* by *tuxor1337*
# https://extensions.gnome.org/extension/545/hide-top-bar/
# https://gitlab.gnome.org/tuxor1337/hidetopbar

# SAVVY: The Hide Top Bar extension inhibits
#        the "Switch system controls" commands.
# - Under the schema:
#     org.gnome.desktop.wm.keybindings
#   See these four settings:
#     switch-panels           — Switch system controls
#     switch-panels-backward  — Switch system controls backward [Hidden]
#     cycle-panels            — Switch system controls directly
#     cycle-panels-backward   — Switch system controls directly backward [Hidden]
#
# - If you disable Hide Top Bar, you may want to reactivate
#   the 4 "Switch system controls" commands.

gnome_extension_hide_top_bar_customize() {
  local menu_path="GNOME Extension > Hide Top Bar"

  # SAVVY: There's no schema for org.gnome.shell.extensions.hidetopbar:
  #   $ gsettings list-recursively org.gnome.shell.extensions.hidetopbar
  #   No such schema “org.gnome.shell.extensions.hidetopbar”
  #   $ gsettings get org.gnome.shell.extensions.hidetopbar mouse-sensitive
  #   No such schema “org.gnome.shell.extensions.hidetopbar”
  # so you much access it via dconf.

  dconf_write "${menu_path} > Sensitivity > ✓ Show panel when mouse approaches edge of the screen" \
    dconf write /org/gnome/shell/extensions/hidetopbar/mouse-sensitive true

  # "Sensitivity > In the above case, also show panel when fullscreen: Enabled"
  # "Sensitivity > Show panel in overview: Enabled"
  # "Sensitivity > Keep hot corner sensitive, even in hidden state: Disabled"
  # "Sensitivity > In the above case show overview, too: Disabled"
  # "Sensitivity > Keep round corners when top bar is hidden: Disabled"
  # "Sensitivity > Pressure barrier's threshold: 100 [ -/+ ]"
  # "Sensitivity > Pressure barrier's timeout: 100 [ -/+ ]"

  # "Animation > Slide animation time when entering/leaving overview: 0.4 [ -/+ ]"
  # "Animation > Slide animation time when mouse approaches edge of the screen: 0.2 [ -/+ ]"

  # "Keyboard shortcuts > Key that triggers the bar to be shown: Disabled" ('@as []')
  # - "(press backspace to deactivate the shortcut)"
  #
  # BROKN: Note that Top Bar doesn't work with built-in "Switch system
  # controls" (switch-panels), which defaults to <Ctrl-Alt-Tab>.
  # - E.g., if you <Ctrl-Alt-C> to show the Top Bar, you cannot
  #   <Ctrl-Alt-Tab> to give the Top Bar keyboard focus.
  #   - Nor if you hover the mouse over Top Bar to show, the
  #     switch-panels command still doesn't work.
  # - Specifically, AFAICT, Hide Top Bar breaks Top Bar keyboard a11y.
  #
  # - BNDNG: <Ctrl-Alt-C>
  dconf_write "${menu_path} > Keyboard shortcuts > Key that triggers the bar to be shown" \
    dconf write /org/gnome/shell/extensions/hidetopbar/shortcut-keybind "['<Control><Alt>c']"

  # "Keyboard shortcuts > Delay before the bar rehides after key press: 1.0 [ -/+ ]"
  # - "(a value of 0 disables the hiding)"
  # - Ha, because floating point, `dconf watch /` shows the tenths
  #   of a second the buttons adjust are reported inexactly, e.g.:
  #     /org/gnome/shell/extensions/hidetopbar/shortcut-delay
  #       0.10000000000000014
  #   or even for 0:
  #     /org/gnome/shell/extensions/hidetopbar/shortcut-delay
  #       1.3877787807814457e-16
  #   Although when we dconf-write 0.0, it is reported exactly:
  #     /org/gnome/shell/extensions/hidetopbar/shortcut-delay
  #       0.0
  dconf_write "${menu_path} > Keyboard shortcuts > Delay before the bar rehides after key press" \
    dconf write /org/gnome/shell/extensions/hidetopbar/shortcut-delay "0.0"

  # "Keyboard shortcuts > Pressing the shortcut again rehides the panel: Enabled"

  dconf_write "${menu_path} > Intellihide > Only hide panel when a window takes the space: ∅" \
    dconf write /org/gnome/shell/extensions/hidetopbar/enable-intellihide false

  # "Intellihide > Only when the active window takes the space: Enabled"
}

#     ==========================================
# *** EXTENSION-LIKE APPLICATION: INPUT REMAPPER
#     ==========================================

# REFER: *Input Remapper*
# - Not an extension, but feels like one!
# https://github.com/sezanzeb/input-remapper

gnome_extension_input_remapper_customize() {
  # This application must be configured manually, AFAICT.
  # - FTREQ/2026-02-04: Publish configuration steps,
  #   and add link to ${print_at_end} reminder.

  return 0
}

#     =======================
# *** EXTENSION: TILING SHELL
#     =======================

# REFER: *Tiling Shell* by *domferr*
# https://extensions.gnome.org/extension/7065/tiling-shell/
# https://github.com/domferr/tilingshell

# REFER/2025-11-03: The following config from v17.0:
#   $ dconf read /org/gnome/shell/extensions/tilingshell/last-version-name-installed
#   '17.0'

# IGNRD/2025-11-03: Not sure why Tiling Shell tracks overridden settings,
# e.g.,
#   overridden-settings="{\"org.gnome.mutter.keybindings\":{\"toggle-tiled-right\":\"['<Super>Right']\",\"toggle-tiled-left\":\"['<Super>Left']\"},\"org.gnome.desktop.wm.keybindings\":{\"maximize\":\"['<Super>Up']\",\"unmaximize\":\"['<Super>Down', '<Alt>F5']\"},\"org.gnome.mutter\":{\"edge-tiling\":\"true\"}}"

gnome_extension_tiling_shell_customize() {
  if ${LINUX_ONBOARDER_EXCLUDE_EXTENSION_TILING_SHELL:-false}; then

    return
  fi

  local menu_path="GNOME Extension > Tiling Shell"

  # Note this schema only accessible via dconf, not gsettings.
  local schema_path="/org/gnome/shell/extensions/tilingshell"

  # *** Appearance

  # Defaults: false ???
  dconf_write "${menu_path} > Appearance > ✓ Show Indicator" \
    dconf write ${schema_path}/show-indicator true

  # Defaults: 16
  dconf_write "${menu_path} > Appearance > Inner Gaps" \
    dconf write ${schema_path}/inner-gaps "uint32 16"

  # Defaults: 8
  dconf_write "${menu_path} > Appearance > Outer Gaps" \
    dconf write ${schema_path}/outer-gaps "uint32 8"

  # Blur (experimental feature) > Snap Assistant > Disabled
  # Blur (experimental feature) > Selected tile preview > Disabled

  # Defaults: 54
  dconf_write "${menu_path} > Appearance > Snap Assistant Threshold: 7" \
    dconf write ${schema_path}/snap-assistant-threshold "7"

  # Defaults: false ???
  dconf_write "${menu_path} > Appearance > Window border > ✓ Enable" \
    dconf write ${schema_path}/enable-window-border true

  # Defaults: true
  dconf_write "${menu_path} > Appearance > Window border > ✓ Smart border radius" \
    dconf write ${schema_path}/enable-smart-window-border-radius true

  # Defaults: ???
  dconf_write "${menu_path} > Appearance > Window border > Width" \
    dconf write ${schema_path}/window-border-width "uint32 1"

  # Defaults: 'rgb(119,118,123)'
  dconf_write "${menu_path} > Appearance > Window border > Border color" \
    dconf write ${schema_path}/window-border-color "'rgb(119,118,123)'"

  # Animations > Snap assistant animation time > 180
  # Animations > Tile animation time > 100

  # *** Behavior

  # Defaults: false ???
  dconf_write "${menu_path} > Behavior > ✓ Enable Snap Assistant" \
    dconf write ${schema_path}/enable-snap-assist true

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✓ Enable Tiling System" \
    dconf write ${schema_path}/enable-tiling-system true

  dconf_write "${menu_path} > Behavior > ✓ Enable Tiling System > CTRL" \
    dconf write ${schema_path}/tiling-system-activation-key "['0']"

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > Tiling System deactivation key > (None)" \
    dconf write ${schema_path}/tiling-system-deactivation-key "['-1']"

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✓ Span multiple tiles" \
    dconf write ${schema_path}/enable-span-multiple-tiles true
  dconf_write "${menu_path} > Behavior > ✓ Span multiple tiles > ALT" \
    dconf write ${schema_path}/span-multiple-tiles-activation-key "['1']"

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✗ Enable Auto Tiling" \
    dconf write ${schema_path}/enable-autotiling false

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✓ Enable auto-resize of the complementing tiled windows" \
    dconf write ${schema_path}/resize-complementing-windows true

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✗ Restore window size" \
    dconf write ${schema_path}/restore-window-original-size false

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✓ Add snap assistant and auto-tile buttons to window menu" \
    dconf write ${schema_path}/override-window-menu true

  # Defaults: ???
  dconf_write "${menu_path} > Behavior > ✓ Add tiled windows to ALT+TAB menu" \
    dconf write ${schema_path}/override-alt-tab true

  # *** Screen Edges

  # Defaults: ???
  dconf_write "${menu_path} > Screen Edges > Drag against top edit to maximize window" \
    dconf write ${schema_path}/top-edge-maximize false

  # Defaults: ???
  dconf_write "${menu_path} > Screen Edges > Quarter tiling activation area" \
    dconf write ${schema_path}/quarter-tiling-threshold 'uint32 40'

  # Defaults: ???
  dconf_write "${menu_path} > Screen Edges > Edge tiling offset" \
    dconf write ${schema_path}/edge-tiling-offset 'uint32 16'

  # *** Windows suggestions

  # Defaults: ???
  dconf_write "${menu_path} > Windows suggestions > ✗ Enable window suggestions for the tiling system" \
    dconf write ${schema_path}/enable-tiling-system-windows-suggestions false

  # Defaults: ???
  dconf_write "${menu_path} > Windows suggestions > ✗ Enable window suggestions for the snap assistant" \
    dconf write ${schema_path}/enable-snap-assistant-windows-suggestions false

  # Defaults: ???
  dconf_write "${menu_path} > Windows suggestions > ✗ Enable window suggestions for screen edge snapping" \
    dconf write ${schema_path}/enable-screen-edges-windows-suggestions false

  # *** Layouts

  # Layouts > Edit layouts
  # Layouts > Export layouts
  # Layouts > Import layouts
  # Layouts > Reset layouts

  # HSTRY/2025-11-03: I've tested this on already-installed-and-configured
  # Tiling Shell, but not yet on fresh install, though I assume it should
  # work (and I don't feel like uninstalling Tiling Shell or clicking its
  # [Reset settings] button).
  # - ALTLY: If this doesn't work, you can use the [Import layouts] feature
  #   to restore a previously exported layouts config.

  # Defaults: ???
  dconf_write "${menu_path} > Layouts > Import layouts: layouts-json" \
    dconf write ${schema_path}/layouts-json "'[{\"id\":\"Layout 1\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[2,3]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]},{\"x\":0.78,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]}]},{\"id\":\"Layout 2\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[1]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[1,2]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[2]}]},{\"id\":\"Layout 3\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":1,\"height\":0.09722222222222222,\"groups\":[1]},{\"x\":0,\"y\":0.09722222222222222,\"width\":1,\"height\":0.9027777777777777,\"groups\":[1]}]},{\"id\":\"265147326\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":1,\"height\":0.09861111111111111,\"groups\":[1]},{\"x\":0,\"y\":0.09861111111111111,\"width\":0.558203125,\"height\":0.9013888888888889,\"groups\":[1,2]},{\"x\":0.558203125,\"y\":0.09861111111111111,\"width\":0.441796875,\"height\":0.4541666666666667,\"groups\":[1,3,2]},{\"x\":0.558203125,\"y\":0.5527777777777778,\"width\":0.441796875,\"height\":0.4472222222222222,\"groups\":[3,2]}]}]'"

  # Defaults: ???
  dconf_write "${menu_path} > Layouts > Import layouts: selected-layouts" \
    dconf write ${schema_path}/selected-layouts "[['265147326'], ['265147326']]"

  # *** Keybindings

  # BNDNG: <Cmd-Right>
  # - Defaults: "['<Super>Right']"
  dconf_write "${menu_path} > Keybindings > Move window to right tile" \
    dconf write ${schema_path}/move-window-right "['<Super>Right']"

  # BNDNG: <Cmd-Left>
  # - Defaults: "['<Super>Left']"
  dconf_write "${menu_path} > Keybindings > Move window to left tile" \
    dconf write ${schema_path}/move-window-left "['<Super>Left']"

  # BNDNG: <Cmd-Up>
  # - Defaults: "['<Super>Up']"
  dconf_write "${menu_path} > Keybindings > Move window to tile above" \
    dconf write ${schema_path}/move-window-up "['<Super>Up']"

  # BNDNG: <Cmd-Down>
  # - Defaults: "['<Super>Down']"
  dconf_write "${menu_path} > Keybindings > Move window to tile below" \
    dconf write ${schema_path}/move-window-down "['<Super>Down']"

  # BNDNG: <Shift-Cmd-Right>
  # - Defaults: ???
  dconf_write "${menu_path} > Keybindings > Span window to right tile" \
    dconf write ${schema_path}/span-window-right "['<Shift><Super>Right']"

  # BNDNG: <Shift-Cmd-Left>
  # - Defaults: ???
  dconf_write "${menu_path} > Keybindings > Span window to left tile" \
    dconf write ${schema_path}/span-window-left "['<Shift><Super>Left']"

  # BNDNG: <Shift-Cmd-Up>
  # - Defaults: ???
  dconf_write "${menu_path} > Keybindings > Span window above" \
    dconf write ${schema_path}/span-window-up "['<Shift><Super>Up']"

  # BNDNG: <Shift-Cmd-Down>
  # - Defaults: ???
  dconf_write "${menu_path} > Keybindings > Span window below" \
    dconf write ${schema_path}/span-window-down "['<Shift><Super>Down']"

  # **** Keybindings > View and Customize all the Shortcuts

  # All disabled: "['']"
  #
  #   # DUNNO: *Span window to all tiles* mostly maximizes the window,
  #   # and leaves a few pixels above the window, regardless of the layout
  #   # (and AFAIK, you cannot *not* define a tile, i.e., when you create
  #   # a layout, all screen space except the dividers is part of a tile.
  #   # - So I'm not quite sure how this differs from maximize. (I thought
  #   #   maybe you could define a layout and omit some part of the screen,
  #   #   and then this command would span all the other tiles, but, like
  #   #   I said, I cannot define a layout and omit any screen area.)
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Span window to all tiles" \
  #     dconf write ${schema_path}/span-window-all-tiles "['']"
  #
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Untile focused window" \
  #     dconf write ${schema_path}/untile-window "['']"
  #
  #   # MAYBE: Add keybinding for move-window-center
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Move window to the center" \
  #     dconf write ${schema_path}/move-window-center "['']"
  #
  #   # SAVVY: The focus-window commands will raise the focused window.
  #   # - So these *are not* helpful if you were hoping to be able to
  #   #   change window focus without also changing window order.
  #   #   - Author had considered this feature as a way to keep one
  #   #     window on top, like a browser window, but send focus to my
  #   #     editor without covering the current (e.g., browser) window.
  #   #     - But seems like I need to use mouse to do this
  #   #       (using focus-on-hover without raise-on-focus).
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Focus window to the right" \
  #     dconf write ${schema_path}/focus-window-right "['']"
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Focus window to the left" \
  #     dconf write ${schema_path}/focus-window-left "['']"
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Focus window above" \
  #     dconf write ${schema_path}/focus-window-up "['']"
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Focus window below" \
  #     dconf write ${schema_path}/focus-window-down "['']"
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Focus next window" \
  #     dconf write ${schema_path}/focus-window-next "['']"
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Focus previous window" \
  #     dconf write ${schema_path}/focus-window-prev "['']"

  # "Minimize all the other windows and show only the focused window."
  # - BNDNG: <Shift-Ctrl-Cmd-M>
  # - If not set, in Neovim, <Shift-Ctrl-Cmd-M> same as <Ctrl-M>,
  #   e.g., in Insert mode, begins new line
  #   - |i_CTRL-M| |i_<CR>| Begin new line.
  # - See similar binding in DepoXy macOS Hammyspoony config:
  #   allButFrontmost = { { "shift", "ctrl", "cmd" }, "M" },
  dconf_write "${menu_path} > Keybindings > all the Shortcuts > Highlight focused window" \
    dconf write ${schema_path}/highlight-current-window "['<Shift><Control><Super>m']"

  #   # MAYBE: Find a keybinding for this, if you eventually find yourself using
  #   # more than just the one layout you currently exclusively use.
  #   dconf_write "${menu_path} > Keybindings > all the Shortcuts > Cycle layouts" \
  #     dconf write ${schema_path}/cycle-layouts "['']"

  # Keybindings > ✗ Restrict directional focus to tiled windows
  # Defaults: ???
  dconf_write "${menu_path} > Keybindings > ✓ Enable next/previous window focus to wrap around" \
    dconf write ${schema_path}/enable-wraparound-focus true

  # Defaults: ???
  dconf_write "${menu_path} > Keybindings > ✗ Restrict directional focus to tiled windows" \
    dconf write ${schema_path}/enable-directional-focus-tiled-only false

  # *** Import, export and reset

  # Import, export and reset > Export settings
  # Import, export and reset > Import settings
  # Import, export and reset > Reset settings
}

#     =========================
# *** EXTENSION: SIMPLE WEATHER
#     =========================

# REFER: *SimpleWeather* by *Roman Lefler*
# https://extensions.gnome.org/extension/8261/simpleweather/
# https://github.com/romanlefler/SimpleWeather

gnome_extension_simple_weather_customize() {
  if ${LINUX_ONBOARDER_EXCLUDE_EXTENSION_SIMPLE_WEATHER:-false}; then

    return
  fi

  local menu_path="GNOME Extension > SimpleWeather"

  # Note this schema only accessible via dconf, not gsettings.
  local schema_path="/org/gnome/shell/extensions/simple-weather"

  # *** [Locations]
  #
  # - Set this first, otherwise icon not visible (and auto-detect
  #   location didn't work for author).

  # LOPRI/2025-11-15: Add customizable locations setup...
  dconf_write "${menu_path} > Locations > + Add" \
    dconf write ${schema_path}/locations \
    "['{\"name\":\"Minneapolis\",\"lat\":44.9772995,\"lon\":-93.2654692}']"
  #
  dconf_write "${menu_path} > Locations > (Set)" \
    dconf write ${schema_path}/main-location-index "int64 0"

  # *** [General]

  # Units > Units: US, UK, Metric, Custom
  # - Custom options:
  #   - Temperature: Fahrenheit, Celsius
  #   - Speed: mph, m/s, km/h, Knows, ft/s, Beaufort
  #   - Pressure: inHg, hPa, mmHg
  #   - Rain Measurement: in, mm, cm, pts
  #   - Distance: mi, km, ft, m
  dconf_write "${menu_path} > General > Units > US" \
    dconf write ${schema_path}/unit-preset "'us'"

  # Units > Direction: Degrees, Eight-Point Compass

  # Weather Service > Weather Provider: Open-Meteo

  # My Location > Provider > Online - ipapi.co, Online - IPinfo, System - Geoclue, Disable

  # My Location > Refresh Interval (Minutes): 60m (60.0) [Default]
  dconf_write "${menu_path} > General > My Location > Refresh Interval (Minutes) > 15" \
    dconf write ${schema_path}/my-loc-refresh-min "15.0"

  # Accessibility > High Contrast: Disabled [Default]

  # Panel > Theme: System, Light, Afterdark, Immersive

  # Panel > Side of Panel: Right, Center, Left
  dconf_write "${menu_path} > General > Panel > Side of Panel > Right" \
    dconf write ${schema_path}/panel-box "'right'"

  # Panel > Order in Panel: 1 [Default] (Ranges -N..0..N)
  # - Show leftward of other right-side Tob Bar items,
  #   e.g., left of *System Monitor* extension control,
  #   which is left of *Tiling Shell*, which is left of
  #   GNOME Shell menu (whatever it's called).
  #   - If 1 (default), appears right of System Monitor,
  #     and left of Tiling Shell;
  #   - If 2 or greater, appears betwen Tiling Shell and
  #     GNOME menu.
  #   - If -1 or less, appears right of GNOME menu (so
  #     right of everything).
  #     - DUNNO: I would expect -1 or less to keep moving
  #       the icon left, but apparently not.
  dconf_write "${menu_path} > General > Panel > Order in Panel > 0 (Leftmost)" \
    dconf write ${schema_path}/panel-priority "int64 0"

  # Panel > Use Symbolic Icons in Panel: Disabled [Default]

  # Panel > Always Use Packaged Icons: Disabled [Default]

  # *** [Details]

  # Pop-Up: You can adjust a row of 4 x 2 items displayed in
  # the pop-up (drop-down) menu when you click the Tob Bar
  # weather icon, which defaults:
  #   Temperature, Wind, Gusts, Pressure,
  #   Feels Like, Humidity, UV High, and Precipitation;
  # and also supports Condition, Sunrise, Sunset,
  # Cloud Cover, and Sun Countdown.

  # Panel > Panel Detail: Temperature [Default]
  # - Options:
  #     None ('')
  #     Temperature ('temp')
  #     Condition ('conditionText')
  #     Feels Like ('feelsLike')
  #     Wind ('windSpeedAndDir')
  #     Humidity ('humidity')
  #     Gusts ('gusts')
  #     UV High ('uvIndex')
  #     Pressure ('pressure')
  #     Precipitation ('precipitation')
  #     Sunrise ('sunrise')
  #     (but not Sunset, Cloud Cover, or Sun Countdown).
  dconf_write "${menu_path} > Details > Panel > Panel Detail > Temperature" \
    dconf write ${schema_path}/panel-detail "'temp'"

  # Panel > Secondary Panel Detail > None [Default]
  # - Same options as Panel Detail (see previous).
  # - With Wind enabled, Tob Bar icon shows, e.g., "54° NW, 15 mph ☀️"
  dconf_write "${menu_path} > Details > Panel > Secondary Panel Detail > Wind" \
    dconf write ${schema_path}/secondary-panel-detail "'windSpeedAndDir'"

  # Panel > Show Condition Icon > Enabled [Default]

  # Panel > Show Sunrise/Sunset > Disabled [Default]

  # - Panel > Use Countdown for Sun > Disabled [Default]
}

#     =========================
# *** EXTENSION: SYSTEM MONITOR
#     =========================

# REFER: *System Monitor* by *fmuellner*
# https://extensions.gnome.org/extension/6807/system-monitor/
# https://gitlab.gnome.org/GNOME/gnome-shell-extensions

gnome_extension_system_monitor_customize() {
  if ${LINUX_ONBOARDER_EXCLUDE_EXTENSION_SYSTEM_MONITOR:-false}; then

    return
  fi

  local menu_path="GNOME Extension > System Monitor"

  # Note this schema only accessible via dconf, not gsettings.
  local schema_path="/org/gnome/shell/extensions/system-monitor"

  # *** Top Bar pill drop-down options

  # The download/upload data makes the Top Bar item much wider.
  # - Also, they show tenths of a kB when under 10, e.g., "0.4 kB",
  #   and change frequently, which can change the width of the Top
  #   Bar output, and may shift items to the left (e.g., the weather
  #   pill), which can be really distracting (esp., e.g., when you
  #   are watching a video or downloading something, and the values
  #   are changing often).

  dconf_write "${menu_path} > Show > ✗ Upload" \
    dconf write ${schema_path}/show-download false

  dconf_write "${menu_path} > Show > ✗ Download" \
    dconf write ${schema_path}/show-upload false
}

#     =============================
# *** EXTENSION: SHORTCUTS BY CHRIS
#     =============================

# REFER: *Shortcuts* by *Chris*
# https://extensions.gnome.org/extension/1144/shortcuts/
# https://extensions.gnome.org/accounts/profile/ChrisLauinger77
# https://gitlab.com/paddatrapper/shortcuts-gnome-extension

gnome_extension_shortcuts_customize() {
  if ${LINUX_ONBOARDER_EXCLUDE_EXTENSION_SHORTCUTS:-false}; then

    return
  fi

  local menu_path="GNOME Extension > Shortcuts"

  # Note this schema only accessible via dconf, not gsettings.
  local schema_path="/org/gnome/shell/extensions/shortcuts"

  # ***

  # Default: False
  # FIXME: This should be managed by DepoXy...
  dconf_write "${menu_path} > Settings > Custom Shortcuts File > ✓ Enabled" \
    dconf write ${schema_path}/use-custom-shortcuts true

  # Default: ~/.local/share/gnome-shell/extensions/Shortcuts@kyle.aims.ac.za/shortcuts.json
  # FIXME: This should be managed by DepoXy...
  dconf_write "${menu_path} > Settings > Select shortcut file > ..." \
    dconf write ${schema_path}/shortcuts-file \
    "'/private/user/.depoxy/ambers/home/.local/share/gnome-shell/extensions/Shortcuts@kyle.aims.ac.za/shortcuts.json'"

  # Default: ?? [False, I think]
  dconf_write "${menu_path} > Settings > Application-specific files support > ✓ Enabled" \
    dconf write ${schema_path}/enable-appspecific-files true

  # Default: True
  dconf_write "${menu_path} > Appearance > Show icon" \
    dconf write ${schema_path}/show-icon false

  # Default: True
  dconf_write "${menu_path} > Appearance > Use transparency" \
    dconf write ${schema_path}/use-transparency true

  # Default: 70
  # DUNNO: I changed this, and use-transparency, and couldn't see a (big?) difference.
  dconf_write "${menu_path} > Appearance > Visibility" \
    dconf write ${schema_path}/visibility 70

  # Default: 2 [Range: 2-5]
  dconf_write "${menu_path} > Appearance > Max columns" \
    dconf write ${schema_path}/maxcolumns 2

  # Default: <Ctrl-Cmd-Alt-S>
  # BNDNG: <Alt-F1>
  dconf_write "${menu_path} > Hotkey > Hotkey" \
    dconf write ${schema_path}/shortcuts-toggle-overview "['<Alt>F1']"
}

#     ===============================================
# *** EXTENSION: (AN) ALT TAB WINDOW SWITCHER (AATWS)
#     ===============================================

# REFER: *AATWS (Advanced Alt-Tab Window Switcher)* by *GdH*
# https://extensions.gnome.org/extension/4412/advanced-alttab-window-switcher/
# https://github.com/G-dH/advanced-alttab-window-switcher

# ISOFF/2025-09-18: Author doesn't use this extension
# (I demoed it, but didn't hit).
# - ISOFF really just means UNSUPported; we still update
#   dconf just in case you (or I) want to demo (again).

gnome_extension_advanced_alt_tab_window_switcher_customize() {
  if ! ${LINUX_ONBOARDER_INCLUDE_AATWS:-false}; then

    return
  fi

  local menu_path="GNOME Extension > AATWS"

  local schema_path="/org/gnome/shell/extensions/advanced-alt-tab-window-switcher"

  # Defaults: Bottom (3), also Top (1), Center (2)
  dconf_write "${menu_path} > Common > Behavior > Placement: Center" \
    dconf write ${schema_path}/switcher-popup-position "2"

  # Defaults: Show Above/Below Item (2), also Top (1), Show Centered (3)
  dconf_write "${menu_path} > Common > Appearance and Content > Tooltip Titles" \
    dconf write ${schema_path}/switcher-popup-tooltip-title "1"

  # Defaults: false
  dconf_write "${menu_path} > Window Switcher > Behavior > Skip Minimized Windows: ✓" \
    dconf write ${schema_path}/win-switch-skip-minimized true

  # Defaults: true
  dconf_write "${menu_path} > App Switcher > Behavior > Include Favorite (Pinned) Apps: ∅" \
    dconf write ${schema_path}/app-switcher-popup-fav-apps false

  # Defaults: true
  dconf_write "${menu_path} > App Switcher > Behavior > Include Show Apps Icon: ∅" \
    dconf write ${schema_path}/app-switcher-popup-include-show-apps-icon false

  # Defaults: false
  dconf_write "${menu_path} > App Switcher > Appearance > Hide Window Count For Single-Window Apps: ✓" \
    dconf write ${schema_path}/app-switcher-popup-hide-win-counter-for-single-window \
    true
}

#     ==========================
# *** EXTENSION: JUST PERFECTION
#     ==========================

# REFER: *Just Perfection* by *JustPerfection*
# https://extensions.gnome.org/extension/3843/just-perfection/
# https://gitlab.gnome.org/jrahmatzadeh/just-perfection

# ISOFF/2025-10-27: Author doesn't use this extension
# (I demoed it, just wasn't a perfection connection).
# - ISOFF really just means UNSUPported; we still update
#   dconf just in case you (or I) want to demo (again).

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
    dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position "1"

  # Defaults: 0, also 1..10
  dconf_write "${menu_path} > Customize > Clock Menu Position Offset: 10" \
    dconf write /org/gnome/shell/extensions/just-perfection/clock-menu-position-offset "10"
}

#     ====================
# *** EXTENSIONS CUSTOMIZE
#     ====================

gnome_extensions_customize() {
  echo -e "\n$(highlight_soft "*** GNOME Shell extensions")\n"

  gnome_extension_desktop_widgets_customize

  gnome_extension_hide_minimized_customize

  gnome_extension_hide_top_bar_customize

  gnome_extension_input_remapper_customize

  gnome_extension_tiling_shell_customize

  gnome_extension_simple_weather_customize

  gnome_extension_system_monitor_customize

  gnome_extension_shortcuts_customize

  gnome_extension_advanced_alt_tab_window_switcher_customize

  gnome_extension_just_perfection_customize
}

# +++ END: GNOME Extensions settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ Manual Intervention settings

pass_configure() {
  local passid="${HOME}/.password-store/.gpg-id"

  if test -s "${passid}"; then
    print_at_end+=("$(
      cat <<EOF
${OMR_REMINDER_COMPLETE:-✅} Setup Crypto Tools :: Setup Password Store :: aka Initialize \`pass\`

EOF
    )")
  else
    print_at_end+=("$(
      cat <<EOF
${OMR_REMINDER_AWAITING:-⭕} Setup Crypto Tools :: Setup Password Store :: aka Initialize $(pass):

   - Generate a new key:

       gpg --full-generate-key

   - Get the key UID:

       GPG_ID=\$(gpg --list-secret-keys | awk 'NR == 2 {print}')

     Or, if you have other keys, specify the email you used:

       GPG_ID=\$(gpg --list-secret-keys user@host | awk 'NR == 2 {print}')

   - Use the key to initialize \`~/.password-store/.gpg-id\`:

       pass init \${GPG_ID}

EOF
    )")
  fi
}

# ***

laptop_configure() {
  disable_wakeup_on_lid
}

# On author's Debian 13 on Lenovo laptop, default is to wake
# when the lid is opened; but this runs the risk of the machine
# turning on in one's backpack on the bike ride home. For example.
#
#   $ tail -1 /proc/acpi/wakeup
#   LID	  S4	*enabled   platform:PNP0C0D:00
#
# - After sudo-tee:
#
#   $ tail -1 /proc/acpi/wakeup
#   LID	  S4	*disabled  platform:PNP0C0D:00

# ALTLY: This script doesn't do any sudo, but it could:
# - When script is executed, check this setting immediately
#   and prompt for sudo password if needs changing, then change
#   (prompt immediately so that all user interaction happens
#    when script is first executed, and not, e.g., after a delay).
# - Specifically, this call needs privileges:
#
#     echo " LID" | sudo tee /proc/acpi/wakeup
#
# HSTRY/2025-10-02: Author is surprised how long this weird technique
# has been supported (since at least 2015-01-27, in Linux Mint MATE),
# considering how many other estoric features like this have changed
# over the years.

# ASIDE: HSTRY: On a related note, GNOME used to expose an option to
# disable suspend on lid-closed (sorta the opposite of wake on lid-open),
# but that option is no longer present in Tweaks.
# - Here's an old comment and old reminder, just FYI:
#   # - NTRST: When you disable Suspend-when-lid-closed, starts this daemon:
#   #     python3 /usr/libexec/gnome-tweak-tool-lid-inhibitor
#   #   - Which you'll see listed under Tweaks > Startup Applications as
#   #     ignore-lid-switch-tweak
#   print_at_end+=("\
#     🔳 Tweaks > General > Suspend when laptop lid is closed > Disable")
#   }

disable_wakeup_on_lid() {
  if ${LINUX_ONBOARDER_SKIP_WAKE_ON_LID:-false}; then

    return
  fi

  if ! cat /proc/acpi/wakeup 2>/dev/null | grep -q "^LID"; then
    print_at_end+=("${OMR_REMINDER_DISABLED:-❌} Not applicable: Wake on Lid Open")

    return
  fi

  if cat /proc/acpi/wakeup 2>/dev/null | grep "^LID" | grep -q disabled; then
    print_at_end+=("${OMR_REMINDER_COMPLETE:-✅} Disable Wake on Lid Open")

    return
  fi

  print_at_end+=("$(
    cat <<EOF
${OMR_REMINDER_AWAITING:-⭕} Disable Wake on Lid Open:

   echo " LID" | sudo tee /proc/acpi/wakeup
EOF
  )")
}

# ***

depoxy_configure() {
  print_at_end+=("$(
    cat <<EOF
${OMR_REMINDER_UNKNOWN:-🔳} The Rest: If you're a DepoXy user, you can now install apps from
   sources and perform deeper customization and configuration.

   Run the myrepos 'echoInstallHelp' action to print a checklist of
   remaining tasks:

      mr -d / echoInstallHelp

   Or run its DepoXy alias:

      echoInstallHelp

EOF
  )")
}

# +++ END: Manual Intervention settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

slather_gnome_gsettings() {
  local dry_run=false
  local cnt_run=false
  local force_run=false
  local skip_at_end=false

  # ***

  while [ "$1" != '' ]; do
    case $1 in
    --dry-run)
      dry_run=true
      shift
      ;;
    -C | --count)
      cnt_run=true
      shift
      ;;
    -f | --force)
      force_run=true
      shift
      ;;
    -S | --no-reminders)
      skip_at_end=true
      shift
      ;;
    *)
      >&2 echo "ERROR: Unknown arg: $1"

      exit_1
      ;;
    esac
  done

  if [ -z "${LINUX_ONBOARDER_DISTROS}" ]; then
    reset_linux_onboarder_distro_ids
  fi

  if [ -z "${LINUX_ONBOARDER_DESKTOPS}" ]; then
    reset_linux_onboarder_desktop_ids
  fi

  # ***

  local cnt_dconfs=0
  local cnt_gsetts=0
  declare -a gsett_schemas

  if ${cnt_run}; then
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

  gnucash_customize

  gnome_extensions_customize

  pass_configure

  laptop_configure

  depoxy_configure
}

# ***

print_manual_task_reminders() {
  if ! ${force_run} || ${skip_at_end}; then

    return
  fi

  if [ -z "${print_at_end}" ]; then

    return
  fi

  echo -e "\n$(highlight_soft "*** Manual task reminders")\n"

  echo "💡 STEPS: Please perform the following tasks manually:"
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

  echo -e "\n$(highlight_soft "*** You Love Stats!")\n"

  echo "Schemas managed:"
  local gsett_schema
  for gsett_schema in "${gsett_schemas[@]}"; do
    echo "${gsett_schema}"
  done |
    sort | uniq | sed '/^$/d' | sed 's/^/  /'
  echo

  echo "Settings counts:"
  printf "%-22s %3s\n" "  gsettings (re)set's:" "${cnt_gsetts}"
  printf "%-22s %3s\n" "  dconf reset/write's:" "${cnt_dconfs}"
  printf "%-22s %3s\n" "  user task reminders:" "${#print_at_end[@]}"
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
