#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/macOS-onboarder#🏂
# License: MIT

# Copyright (c) © 2021-2023 Landon Bouma. All Rights Reserved.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE:
#
#   # On fresh macOS, run it:
#   cd path/to/macOS-onboarder
#   ./bin/slather-defaults.sh
#
#   # To see list of reminders, and to test script runs, dry-run it:
#   ./bin/slather-defaults.sh --dry-run
#
#   # ALTLY: If you've got DepoXy installed:
#   cd ~/.depoxy/ambers
#   ./bin/onboarder/slather-defaults.sh --dry-run

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# HINTS:
#
# - You can access the global domain three different ways, e.g.,
#
#     defaults write -g <key> <value>
#     defaults write -globalDomain <key> <value>
#     defaults write NSGlobalDomain <key> <value>
#
#   For no reason, or perhaps for readability, this file uses the long format.
#
# - If you're unsure the value type after changing a setting and reading
#   its value, query it:
#
#     defaults read-type <domain> <key>
#
# - NSUserKeyEquivalents characters:
#
#     @ Cmd / ~ Alt / $ Shift / ^ Ctrl
#
# - See also for editing plist files: /usr/libexec/PlistBuddy
#
# - For a count of `defaults write` commands, replace-all in Vim:
#
#     \(^\s\+\)defaults write
#
#   with \1defaults write
#
#   - Today's `defaults write` count: 127.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

DXY_SCREENCAPS_LOCATION="${DXY_SCREENCAPS_LOCATION:-${HOME}/screencaps}"

# YOU: Set this false if you want to keep GarageBand and iMovie.
DXY_REMOVE_BLOATWARE=false

# DXY_ONB_EXPECTED_MAJOR_VERS=13
# DXY_ONB_EXPECTED_MAJOR_VERS_NAME="Ventura"
DXY_ONB_EXPECTED_MAJOR_VERS=14
DXY_ONB_EXPECTED_MAJOR_VERS_NAME="Sonoma"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# This script only supports the latest macOS (that the author's used).
# - If anyone needs to support an old OS, look through this project's
#   commit history instead, and checkout an old revision.
#   - MAYBE: Ideally I'll version this project after each macOS update.
#            I could even version this project to track macOS versions.
insist_is_latest_macos_version () {
  local major_vers=""

  # `sw_vers -productVersion` prints, e.g., '13.0.1'.
  major_vers="$(sw_vers -productVersion | awk -F '.' '{print $1}')"

  if [ ${major_vers} -ne ${DXY_ONB_EXPECTED_MAJOR_VERS} ]; then
    >&2 echo "FAILD: This script is designed for macOS ${DXY_ONB_EXPECTED_MAJOR_VERS_NAME}."
    >&2 echo
    >&2 echo "- Please uncomment this guard clause and run the"
    >&2 echo "  script knowing you will have some chores to do."

    exit_1
  fi
}

# Because macOS just rebranded System Preferences → System Settings
# and rearranged and reworded everything therein, might as well pull
# out and abstract some of those bits susceptible to disruption, so
# we're prepared if it happens again.
CRUMB_APP_SHORTCUTS="Keyboard: Keyboard Shortcuts...: App Shortcuts"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

check_deps () {
  # In lieu of checking `os_is_macos`, just check what really matters.
  ( true \
    && command -v defaults > /dev/null \
    && command -v osascript > /dev/null \
  ) && return 0 || true

  >&2 echo "ERROR: Missing \`defaults\` and/or \`osascript\`"
  >&2 echo "- Hint: On Linux? Try --dry-run"

  exit_1
}

fake_it () {
  fg_skyblue () { printf "\033[38;2;135;175;255m"; }
  attr_reset () { printf "\033[0m"; }
  highlight () { printf "%s" "$(fg_skyblue)$1$(attr_reset)"; }

  defaults () {
    echo "  $(highlight "defaults") $@"; }
  killall () {
    echo "  $(highlight "killall") $@"; }
  osascript () {
    echo "  $(highlight "osascript") $@"; }
  sudo_bin_rm_rf () {
    echo "  $(highlight "command rm -rf --") $@"; }
}

# INPUT: ENV: Expects:
#   local cnt_defaults=0
#   local cnt_defaults_write=0
#   local cnt_defaults_delete=0
#   local cnt_defaults_other=0
#   declare -A cnt_defaults_domain
#   local cnt_killalls=0
#   local cnt_ascripts=0
#   local cnt_binrmrfs=0
count_it () {
  defaults () {
    let 'cnt_defaults += 1'

    if [ "$1" = "write" ]; then
      let 'cnt_defaults_write += 1'
    elif [ "$1" = "delete" ]; then
      let 'cnt_defaults_delete += 1'
    else
      let 'cnt_defaults_other += 1'
    fi

    let "cnt_defaults_domain[$2] += 1"

    echo "  defaults $@";
  }
  killall () {
    let 'cnt_killalls += 1'

    echo "  killall $@";
  }
  osascript () {
    let 'cnt_ascripts += 1'

    echo "  osascript $@";
  }
  sudo_bin_rm_rf () {
    let 'cnt_binrmrfs += 1'

    echo "  sudo /usr/bin/env rm -rf $@";
  }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# LOPRI/2023-01-26: Rename "System Preferences" → "System Settings"
# in all the progress echoes, reminders, and comments below.
# - FIXME: Apple also reorganized all the settings panels, so many
#          of the System Preferences > Bread > Crumb > Trails below
#          will be outdated.

# ***

# 2023-01-26: Apple rebranded "System Preferences" → "System Settings"
# in latest macOS Ventura 13.0.1 update.
# - Hopefully this doesn't break too much of my code.
#   - At least the tell-app name is backwards-compatible, e.g., you
#     can call either of these:
#       osascript -e 'tell application "System Preferences" to quit'
#       osascript -e 'tell application "System Settings" to quit'
#   - But it did at least break my Ctrl-q binding, because the menu item
#     was renamed "Quit System Preferences" → "Quit System Settings".
# - At least it's easier to say "System Settings". The "pref" prefix
#   in "Preferences" seems like a tougher English sound to pronounce.
system_settings_close () {
  # System Settings, née System Preferences.
  echo "System Settings: Closing to prevent conflict with our settings"
  osascript -e 'tell application "System Settings" to quit'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

general_appearance_customize () {
  general_appearance_customize_dark_mode
}

# Hrmm, I don't care for Dark mode after all. It applies to all apps that
# support it, but I'd rather choose Dark mode for those apps that do it
# well. E.g., Meld is too difficult to read in Dark mode. Also, my Vim
# already does a great dark mode, and I set Slack to dark mode. And I'll
# be hiding the dock and menu bar anyway, so, yeah, leave this one be.
general_appearance_customize_dark_mode () {
  # No thanks, not pretty with some apps, so apply per-app as desired.
  false && (
    echo "Appearance: Dark. Use dark menu bar and dock"
    echo '- BWARE: `killall Dock` does not bake this value.'
    echo "  You may need to open System Settings and set this one manually."

    defaults write NSGlobalDomain AppleInterfaceStyle 'Dark'

    restart_dock=true  # Albeit doesn't change Appearance for me.
  )
  print_at_end+=("🔳 System Settings: Appearance: Appearance: ✓ Dark")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

desktop_and_screen_saver_customize () {
  desktop_and_screen_saver_customize_desktop_black
}

# I changed the desktop to black, but I didn't see any plist change.
desktop_and_screen_saver_customize_desktop_black () {
  print_at_end+=("🔳 System Settings: Wallpaper: *Configure to taste* (Generally I choose Black)")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY/2024-04-14: `killall Dock` to see window behavior change,
# then reopen System Settings to see GUI widget updated (or, toggle
# one of the widgets, then the other widgets should update).

dock_and_menu_bar_customize () {
  dock_reset_dock

  dock_and_menu_bar_customize_dock_position_on_screen_left
  dock_and_menu_bar_customize_dock_minimize_windows_using_scale_effect
  dock_and_menu_bar_customize_dock_animate_opening_applications_disable
  dock_and_menu_bar_customize_dock_automatically_hide_and_show_the_dock
  dock_and_menu_bar_customize_dock_show_indicators_for_open_applications_disable
  dock_and_menu_bar_customize_dock_show_recent_application_in_dock_false

  dock_and_menu_bar_customize_dock_remove_superfluous_dock_icons
  dock_and_menu_bar_customize_dock_pin_and_rearrange_apps_to_taste

  dock_and_menu_bar_customize_menu_bar_automatically_hide_and_show_the_menu_bar_on_desktop

  dock_and_menu_bar_customize_control_center_now_playing_show_in_menu_bar_disable

  dock_and_menu_bar_customize_menu_bar_only_clock_use_a_24_hour_clock_enable
  dock_and_menu_bar_customize_menu_bar_clock_customize_day_date_time_format

  dock_and_menu_bar_customize_menu_bar_only_spotlight_show_in_menu_bar_disable

  restart_dock=true
}

# Just FYI, how you'd reset all Dock options.
# https://github.com/herrbischoff/awesome-macos-command-line#reset-dock
dock_reset_dock () {
  false && (
    defaults delete com.apple.dock 2> /dev/null || true
  )
}

# I like the Dock on the left, otherwise it interrupts my flow.
# Specifically, when I have the browser open, and DevTools on the bottom,
# when I mouse to the bottom of the window to access the console,
# I don't want the Dock to pop up.
dock_and_menu_bar_customize_dock_position_on_screen_left () {
  echo "Dock & Menu Bar: Dock: Position on screen: Left"
  defaults write com.apple.dock orientation -string "left"
}

# ISOFF/2024-04-14: Yes, no, the author still thinks the Genie animation
# is distracting.
dock_and_menu_bar_customize_dock_minimize_windows_using_scale_effect () {
  echo "Desktop & Dock: Dock: Minimize windows using: Scale Effect"
  defaults write com.apple.dock mineffect -string "scale"
}

# When you open an app, the dock icon bounces a few times. Whee!
dock_and_menu_bar_customize_dock_animate_opening_applications_disable () {
  echo "Desktop & Dock: Dock: ✗ Animate opening applications"
  defaults write com.apple.dock launchanim -bool false
}

dock_and_menu_bar_customize_dock_automatically_hide_and_show_the_dock () {
  echo "Desktop & Dock: Dock: ✓ Automatically hide and show the Dock"
  defaults write com.apple.dock autohide -bool true
}

dock_and_menu_bar_customize_dock_show_indicators_for_open_applications_disable () {
  echo "Desktop & Dock: Dock: ✗ Show indicators for open applications"
  defaults write com.apple.dock show-process-indicators -bool false
}

dock_and_menu_bar_customize_dock_show_recent_application_in_dock_false () {
  echo "Desktop & Dock: Dock: ✗ Show suggested and recent apps in Dock"
  defaults write com.apple.dock show-recents -bool false
}

dock_and_menu_bar_customize_dock_pin_and_rearrange_apps_to_taste () {
  print_at_end+=("\
🔳 Dock: Pin and rearrange apps to taste
   - Possible order: Finder / Chrome / Slack / Vim / iTerm2 / Activity Monitor
   - See also Spotlight search (Cmd-space) for apps you could add and “Keep in Dock”")
}

dock_and_menu_bar_customize_dock_remove_superfluous_dock_icons () {
  print_at_end+=("\
🔳 Dock: Remove superfluous Dock icons: Control-click (or right-click) and *Options > Remove from Dock*:
   - Remove from Dock: Launchpad [don't use; can run via Spotlight]
   - Remove from Dock: Photos [wouldn't use on a @work machine]
   - Remove from Dock: FaceTime, Messages, Mail, Music, TV [require accounts/subscriptions]
   - Remove from Dock: Calendar, Maps (GTK they're there, but I use browser apps)
   - Remove from Dock: Contacts, Reminders, Notes
   - Remove from Dock: Safari [prefer Chrome], News [prefer browser]
   - Remove from Dock: Freeform, Keynote, Numbers, Pages (Office apps)
   - Remove from Dock: Downloads [Use Cmd-Ctrl-Space or Cmd-F]
   - Remove from Dock: MacVim [because clicking Dock icon won't run correct --servername]
   - Remove from Dock: System Settings, App Store [both available under Apple menu]
   - Remove from Dock: Microsoft Outlook [maybe, if installed and you don't need or have a license]
   - Remove from Dock: [Anything else you might not use or would access from the terminal: E.g.,: Siri, iTunes [now Music], Xcode, Self Service, Firefox]")
}

dock_and_menu_bar_customize_menu_bar_automatically_hide_and_show_the_menu_bar_on_desktop () {
  echo "Control Center: Menu Bar Only: ✓ Automatically hide and show the menu bar"
  echo "  [*Always* | On Desktop Only | In Full Screen Only | Never]"
  # These four options are controlled by two booleans:
  #                                     Always   Desktop   Full Screen   Never
  #   AppleMenuBarVisibleInFullscreen      0        1           0          1
  #   _HIHideMenuBar                       1        1           0          0
  defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -bool false
  defaults write NSGlobalDomain _HIHideMenuBar -bool true
}

# I thought if I disabled "Now Playing" that I wouldn't see the "Music" tile
# in the Control Center, but it's still there.
# - Also, I see no change in the `defaults read` plist.
# Not sure what-if-anything this setting does, so skip't.
# - DUNNO/2024-04-15: Was new option added? Sonoma 14.4.1 default
#   is "Show When Active". Other 2 options: Always Show in Menu Bar,
#   and Don't Show in Menu Bar.
dock_and_menu_bar_customize_control_center_now_playing_show_in_menu_bar_disable () {
  # echo "Dock & Menu Bar: Control Center: Now Playing: ✗ Show in Menu Bar"
  #  defaults write ??? ??? -bool false
  :
}

dock_and_menu_bar_customize_menu_bar_only_clock_use_a_24_hour_clock_enable () {
  echo "General: Date & Time: ✓ 24-hour time"
  defaults write NSGlobalDomain AppleICUForce24HourTime -bool true

  restart_systemuiserver=true
}

dock_and_menu_bar_customize_menu_bar_clock_customize_day_date_time_format () {
  # Circa 2020-21 I used the DateFormat "EEE HH:mm:ss", which I probably found
  # online. The format here, "EEE MMM d  H:mm", is what I saw on defaults-read.
  # - 2022-10-17: Though now that I look at the menu bar again, those two spaces
  #   between the date and time might bother me, especially now that I see them.
  #   - TRYME: Demo the DateFormat with a single space between date and time.
  # SAVVY: Sonoma 14.4.1 Clock default: Mon Apr 15 0:15
  # - ISOFF/2024-04-15: I don't see a System Settings option for this,
  #   nor can I find an existing default for it, and if we're just setting
  #   the default value, anyway, don't bother.
   
  #  echo "General: Language & Region: (Hidden option): DateFormat"
  #  defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  H:mm"
  #
  #  restart_systemuiserver=true
  :
}

dock_and_menu_bar_customize_menu_bar_only_spotlight_show_in_menu_bar_disable () {
  # SAVVY: This settings exists in `defaults`, but it's just a mirror value.
  # - When *Show in Menu Bar* is set (the default), e.g.,
  #     Control Center: Menu Bar Only: Spotlight: ✓ Show in Menu Bar
  #   you'll see in defaults:
  #     $ defaults read com.apple.Spotlight "NSStatusItem Visible Item-0"
  #     1
  #   which you can delete:
  #     defaults delete com.apple.Spotlight "NSStatusItem Visible Item-0"
  #   (though note if it's already deleted, you'll see a warning instead, e.g.,
  #     2022-10-16 23:51:29.409 defaults[57101:1403399]
  #     Domain (com.apple.Spotlight) not found.
  #     Defaults have not been changed.
  #   ) but the real problem is the value is not canon.
  # - SAVVY: If you `killall SystemUIServer`, nothing changes.
  #   - SAVVY: If you delete the key, then logout and logon again,
  #     the previous key value is restored.

  print_at_end+=("🔳 System Settings: Control Center: Menu Bar Only: Spotlight: ✓ Don't Show in Menu Bar")
  # AVOID: Per note above, this does no good:
  #
  #  echo "Control Center: Menu Bar Only: Spotlight: ✓ Don't Show in Menu Bar"
  #  # Default setting:
  #  #   defaults write com.apple.Spotlight "NSStatusItem Visible Item-0" -bool true
  #  defaults delete com.apple.Spotlight "NSStatusItem Visible Item-0"
  #
  #  restart_systemuiserver=true
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

mission_control_customize () {
  # System Settings > Mission Control shows three of the Keyboard shortcuts
  # we set via System Settings > Keyboard > Shortcuts: Mission Control (^⌥ ↑),
  # Application windows (^⌥ ↓), and Show Desktop (^⌥ D).

  mission_control_customize_automatically_rearrange_spaces_based_on_most_recent_use_false

  mission_control_customize_hot_corners_lower_corners_mission_control
}

mission_control_customize_automatically_rearrange_spaces_based_on_most_recent_use_false () {
  echo "Desktop & Dock: Mission Control: ✗ Automatically rearrange Spaces based on most recent use"
  defaults write com.apple.dock mru-spaces -bool false
  restart_dock=true
}

mission_control_customize_hot_corners_lower_corners_mission_control () {
  echo "Desktop & Dock: Mission Control: Hot Corners... > Mission Control (Lower-left, and Lower-right)"
  # Factory defaults: All off except Quick Note lower-right: "wvous-br-corner" = 14
  defaults write com.apple.dock wvous-bl-corner -int 2
  defaults write com.apple.dock wvous-bl-modifier -int 0
  defaults write com.apple.dock wvous-br-corner -int 2
  defaults write com.apple.dock wvous-br-modifier -int 0

  restart_dock=true
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# See `com.apple.ncprefs` `apps` array, which stores the toggle state.
# - For some reason, I see two Google Chrome items in the Notifications & Focus dialog.
#   - The first item uses *Google Chrome alert style: "Banners"*. The second uses "Alerts".
# - When I toggle both on, I see two items in the `apps` array:
#   { "bundle-id" = ... "com.google.Chrome"; ... flags = 8396814 → 41951246; ... }
#   { "bundle-id" = ... "com.google.Chrome.framework.AlertNotificationService"; ...
#                                                flags = 8396822 → 41951254; ... }
# - I would've expected Chrome to ask for Notification escalation,
#   but it hasn't, and I was finally late to a meeting!
#
# SAVVY: "Banners" style means notification disappears after a few seconds.
#        "Aletts" style means notification hangs around until dismissed.
#
# NEXTM/2022-10-31: Ya know, Slack notifications also disabled...
# - TRACK: I wonder if the macOS update/reboot on Friday disabled Notifications?
# - So make this a general Notifications & Focus reminder.
notifications_ampersand_focus_customize () {
  print_at_end+=("🔳 System Settings: Notifications: Google Chrome: ✓✓ Allow Notifications (you may see two Google Chrome entries")
  print_at_end+=("🔳 System Settings: Notifications: Google Chrome: Style: ✓✓ Alerts [Banners timeout; Alerts persist]")

  appendPAE () {
    local app_name="$1"

    print_at_end+=("🔳 System Settings: Notifications: ${app_name}: ✓ Allow Notifications")
    print_at_end+=("🔳 System Settings: Notifications: ${app_name}: Style: ✓ Alerts [Banners timeout; Alerts persist]")
  }

  # DUNNO/2022-10-31: I called `terminal-notifier -message foo` and a popup
  # let me enable those notifications, but I don't see "Allow Notifications"
  # toggle enabled for either iTerm or terminal-notifier.
  # - So not sure these will work, but hey:
  appendPAE "iTerm"
  appendPAE "terminal-notifier"

  appendPAE "brew-autoupdate"

  # MAYBE: If you don't see this on fresh @macOS, you may need to run
  # `notify "any message"` from the terminal.
  appendPAE "Script Editor"

  appendPAE "Slack"

  # FIXME/2022-10-31: I'm going to try Alerts for Chrome, for Email and Calendar events.
  # - Note that first Google Chrome entry was set to Banners, and second to Alerts,
  #   so I only had to change the first Google Chrome entry's alert style.
  # TRYNG/2022-12-08: Let's try Alert style for all, I'm curious if that'll
  # improve my workflowproductivitysynergy.
  print_at_end+=("🔳 Notifications & Focus: AUDIT: For each app, disable notifs, or set alert style to *Alerts* style...?")
  #
  # 2022-12-08: It's easier to reason if this is a binary, I think.
  # - On second thought, make unary, enable same for all.
  #   - The only setting that might annoy me is Slack notifications.
  #     Though I've previously discovered that I like when Email notifications
  #     to hang around until I process them, so maybe similarly with Slack
  #     (and I also like the idea of seeing what I missed when I return to
  #     my machine; and Slack isn't too noisy, because I only let certain
  #     messages activate notifications).
  #
  # - Enable ✓ Allow Notifications, and using *Alerts* alert style:
  #   - brew-autoupdate
  #   - Calendar      [though I'd be surprised if I ever saw a Calendar alert]
  #   - Citrix Viewer [was disabled, but I enabled to see if it has any notifs;
  #                    and I'm unsure whether this app is even in use.]
  #   - CylanceUI     [a software or network guard? that I've never seen notif]
  #   - FaceTime      [don't use, but enabled because curious if it ever would]
  #   - Find My       [was enabled except style "None" (so, what, would only
  #                    appear in Notification Center? Set to *Alerts* to see]
  #   - Finicky       [changed from *Banners* to *Alerts* b/c don't expect any,
  #                    at least now that I've set the config; though setting to
  #                    *Alerts* would tell me if config unexpectedly changed...
  #                    which would be weird and ya know unexpected]
  #   - Game Center   [whatever, turn it on full blast, don't expect any]
  #   - GhostTile
  #   - Google Chrome
  #   - Google Chrome [dunno why it's listed twice!]
  #   - Headphone Notifications [no idea what causes these, because connecting
  #                    and disconnecting a Bluetooth headset hasn't been]
  #   - Home          [I'd be curious to know what this would have to say]
  #   - iTerm         [was disabled; `terminal-notifier` has its own notifs
  #                    settings, so maybe this is specifically for notifs
  #                    from the iTerm2 app... but I've never seen any]
  #   - Kerberos
  #   - Mail          [expect none]
  #   - Management Action [locked on and set to *Alerts*, and cannot modify]
  #   - Messages      [expect none]
  #   - Microsoft Outlook [expect none, because I use web portal]
  #   - Microsoft Teams [expect none, though I use Teams twice a week]
  #   - Microsoft Update Assist... [I'd be curious if this every notifs]
  #   - NoMAD         [yes, please, I want to see all your notifs, especially
  #                    those reminding me of a pending password expiration]
  #   - Reminders     [expecting none, as I don't use this macOS feature]
  #   - Script Editor [of course yes, that's ~/.depoxy/ambers/bin/notify,
  #                    which calls osascript's `display notifications`;
  #                    also why I started enumerating this list just now,
  #                    because I was tinkering with `notify` and wanted to
  #                    make notifications sticky until explicitly dismissed]
  #   - Self Service  [uneditable and enabled and *Alerts*]
  #   - Slack
  #   - terminal-notifier [the Homebrew app]
  #   - Tips          [I've rarely enjoyed OS logon or app startup hints]
  #   - Wallet        [I don't even know what macOS feature this is]
  # - Disable ✗ Allow Notifications:
  #   - [None]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# I've never demoed these Launchpad options. I rarely use Launchpad,
# and its layout seems fine to me. (But I do like collecting all the
# `defaults` options in this script!)
#  https://www.makeuseof.com/tag/hidden-mac-settings-defaults-command/amp/0
launchpad_customize () {
  false && (
    # Reset Launchpad, including the arrangement of the apps:
    defaults write com.apple.dock ResetLaunchPad -bool true

    # Reset the rows and columns settings:
    defaults delete com.apple.dock springboard-rows 2> /dev/null || true
    defaults delete com.apple.dock springboard-columns 2> /dev/null || true

    # Customize Launchpad rows and columns:
    defaults write com.apple.dock springboard-rows -int {num_rows}
    defaults write com.apple.dock springboard-columns -int {num_columns}

    restart_dock=true
  )
}

# 2023-02-07: Just noting-to-self, should I ever choose to try it,
# you can disable the Quarantine popup when you first run an app
# that's not signed by Apple dev account. But I don't mind, really,
# it's a one-off popup, and it's also informative — e.g., it tells
# me it's the first time running an app, and I might have some more
# customization to do.
# - CXREF: https://github.com/rusty1s/dotfiles/blob/master/macos/defaults.sh
launchservices_customize () {
  false && (
    # Disable the "Are you sure you want to open this application?" dialog.
    defaults write com.apple.LaunchServices LSQuarantine -bool false
  )
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

keyboard_customize () {
  keyboard_customize_key_repeat_fastest
  keyboard_customize_delay_until_repeat__disabled
  keyboard_customize_press_and_hold_enabled_false__disabled

  keyboard_customize_reclaim_fkeys

  keyboard_reminder_discourage_bluetooth_peripherals

  # DUNNO: Is it really necessary to logout?
  # - There's no `killall` we could perform?
  print_at_end+=("🔳 Keyboard: Logout and logon again to realize Keyboard settings changes")
}

# Default Key Repeat as shown in GUI is on 7th of 8 ticks,
# from Off (1) and Slow (2) to Fast (8).
# - Here's what I observed with the slider at each tick stop:
#   - 1 (Off):  (Removed: KeyRepeat)    InitialKeyRepeat = 300000;
#   - 2 (Slow): KeyRepeat = 120;        InitialKeyRepeat = 68;
#   - 3:        KeyRepeat = 90;         InitialKeyRepeat = 68;
#   - 4:        KeyRepeat = 60;         InitialKeyRepeat = 68;
#   - 5:        KeyRepeat = 30;         InitialKeyRepeat = 68;
#   - 6:        KeyRepeat = 12;         InitialKeyRepeat = 68;
#   - 7 (Deft): KeyRepeat = 6;          InitialKeyRepeat = 68;
#   - 8 (Fast): KeyRepeat = 2;          InitialKeyRepeat = 68;
# - Also set and static after I first moved the slider:
#     InitialKeyRepeat_Level_Saved = 3;
#   Though I'd swear the default InitialKeyRepeat level was 5 of 6,
#   and that setting KeyRepeat Off changed it. (Though when I changed
#   the KeyRepeat slider, I had not touched InitialKeyRepeat yet, so there
#   was no entry in the plist, and maybe it recorded the wrong value?)
# - The lowest the GUI lets you set KeyRepeat is 2, which I read is 30 ms.
# - You can also set a KeyRepeat of 1, if you use the CLI.
# - An Awesome List suggests you can even go even lower, fractionally, e.g.,
#     defaults write -g KeyRepeat -int 0.02
#   But I did not try this. And the `-int` makes me suspect it's wrong.
#   - Indeed, `defaults write -g KeyRepeat -int 1.5 && defaults read -g KeyRepeat`
#     responds '1'.
#   REFER: https://github.com/herrbischoff/awesome-macos-command-line#key-repeat-rate
# REFER: https://apple.stackexchange.com/a/83923/388088
keyboard_customize_key_repeat_fastest () {
  echo "Keyboard: Keyboard: Key repeat rate: 1 [Faster than Fast]"
  # Sonoma widget (8 ticks): Off | Slow | XX | XX | XX | XX | XX | Fast
  # - Values:                120    120   90   60   30   12    5     2
  # - GUI fastest is -int 2 (30 ms).                           |
  # - GUI default (not written to defaults):                   5
  defaults write NSGlobalDomain KeyRepeat -int 1
}

# I like the default Delay Until Repeat, which is tick 5 of 6 (second shortest).
# - Here's what I observed:
#   - 1 (Long):  InitialKeyRepeat = 120;  "InitialKeyRepeat_Level_Saved" = 5;
#   - 2:         InitialKeyRepeat = 94;   "InitialKeyRepeat_Level_Saved" = 5;
#   - 3:         InitialKeyRepeat = 68;   "InitialKeyRepeat_Level_Saved" = 5;
#   - 4:         InitialKeyRepeat = 35;   "InitialKeyRepeat_Level_Saved" = 5;
#   - 5:         InitialKeyRepeat = 25;   "InitialKeyRepeat_Level_Saved" = 5;
#   - 6 (Short): InitialKeyRepeat = 15;   "InitialKeyRepeat_Level_Saved" = 5;
# - Ha, Level 6 is too quick to repeat! 5 is the sweet spot for my fingers.
# - If you really wanted to mess with someone, you go even lower than 15,
#   such that you won't be able to type anything, much less the `defaults`
#   command to reset the repeat rate (though I suppose you could always
#   mouse over to System Preferences to fix things).
#     # Don't try this!
#     #  defaults write -g InitialKeyRepeat -int 10
# REFER: https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x#comment380315_83923
keyboard_customize_delay_until_repeat__disabled () {
  echo "Keyboard: Keyboard: Delay until repeat: 25 [5th of 6 tick stops]"
  # Sonoma widget (6 ticks): Long | XX | XX | XX | XX | Short
  # - Values:                 120   94   68   30   25     15
  # - GUI default (written to defaults):      30
  defaults write NSGlobalDomain InitialKeyRepeat -int 25
}

# I had an issue circa 2020 that disabling ApplePressAndHoldEnabled helped.
# It was something about the speed of the repeat increasing the longer I
# held, and it made if difficult to control accuracy of a key repeat
# operation. But I didn't record the issue more specifically than that,
# so I'm leaving this disabled until I have a reason to try it.
# REFER: *a GitHub issue for NyaoVim* https://github.com/rhysd/NyaoVim/issues/18
keyboard_customize_press_and_hold_enabled_false__disabled () {
  false && (
    echo "Keyboard: Disable press-and-hold keys to increase key repeat rate"
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  )
}

keyboard_customize_reclaim_fkeys () {
  # SAVVY/2024-04-15: I think this affects MacBook keyboards, and doesn't
  # have any effect on external keyboards, e.g., such as one attached to a
  # Mac mini.
  if ! is_probably_a_laptop; then
    echo "The following *Function Keys* setting is likely unnecessary..."
  fi

  echo "Keyboard: Keyboard Shortcuts...: Function Keys: Use F1, F2, etc. keys as standard function keys"
  defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
}

keyboard_reminder_discourage_bluetooth_peripherals () {
  print_at_end+=("🔳 Keyboard: BWARE: Author had keyboard connectivity issues over Bluetooth
   - Circa 2022-2023, author's Logitech Ergo K860 began disconnecting after 1 second idle,
     but works fine on Linux. I fiddled with macOS System Settings but eventually gave up
     and substituted the 2.4 Ghz USB dongle for Bluetooth, problem solved (then got a
     *NovelKeys NK87*, wicked lovely)")

  print_at_end+=("🔳 Keyboard: BWARE: Author had mouse connectivity issues over Bluetooth
   - Circa 2022-2023, author's Bluetooth-only Logitech M535 would stop responding briefly,
     e.g., you'd be moving the mouse and all of a sudden it would just stop moving. Swapping
     for 2.4G cordless mouse fixed the issue")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

sound_preferences_customize () {
  sound_preferences_customize_sound_effects_play_user_interface_sound_effects_false
  sound_preferences_customize_sound_effects_select_an_alert_sound_jump
}

sound_preferences_customize_sound_effects_play_user_interface_sound_effects_false () {
  false && (
    echo "Sound: Sound Effects: ✗ Play user interface sound effects"
    defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool false
  )
  # 2022-11-02: Why was this disabled? It silences Slack notifications, which
  # I like to hear when I'm not paying attention to my MacBook screen.
  # ISOFF/2024-04-15 02:15: Enabled by default, so leave alone (then if user
  # manually disables, running this script again won't reactivate).
  false && (
    echo "Sound: Sound Effects: ✓ Play user interface sound effects"
    defaults write NSGlobalDomain com.apple.sound.uiaudio.enabled -bool true
  )
}

sound_preferences_customize_sound_effects_select_an_alert_sound_jump () {
  echo "Sound: Sound Effects: Alert sound: Jump [aka Frog]"
  defaults write NSGlobalDomain com.apple.sound.beep.sound "/System/Library/Sounds/Frog.aiff"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

mouse_customize () {
  mouse_customize_scroll_direction_unnatural
  mouse_customize_scrolling_speed
}

# There's nothing natural about it! Feels backwards to me.
mouse_customize_scroll_direction_unnatural () {
  echo "Mouse: ✗ Natural scrolling [Content tracks finger movement]"
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
}

# The default scrolling speed seems awkward in Chrome, like, I spin the
# mouse wheel a little and nothing happens, and then the pages jumps
# much further that I'd want.
# - 3rd of 8 ticks: 0.215
# - 4th of 8 ticks: 0.3125
mouse_customize_scrolling_speed () {
  # Sonoma widget (8 ticks): Slow | XXXXX | XXXXX | XXXXXX | XXXX | XXXX | XX | Fast
  # - Values:                   0   0.125   0.215   0.3125    0.5   0.75    1    1.7
  # - GUI default (written to defaults):            0.3125
  echo "Mouse: Scrolling Speed: 3rd of 8 ticks (4th is default)"
  defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.215
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

display_customize () {
  # Each of these reminders is applicable to a laptop.
  # - Each fcn. is guarded by is_probably_a_laptop
  display_customize_external_monitor_mirror_displays
  display_customize_battery_power_adapter_turn_display_off_after_never
  display_customize_battery_power_adapter_no_sleep_when_display_is_off
  display_customize_gripe_cannot_not_sleep_nor_lock_when_latched
  display_customize_external_enable_notifications
}

# SAVVY: Get the Mac model ID, e.g.,
#   $ sysctl hw.model
#   hw.model: Mac14,3
# Or:
#   $ system_profiler SPHardwareDataType
#   Hardware:
#
#       Hardware Overview:
#
#         Model Name: Mac mini
#         Model Identifier: Mac14,3
#         ...
# - BWARE/2024-04-15: Apparently `sysctl hw.model` has been wrong,
#   at least on some person's 2019 MacBook Pro:
#     https://apple.stackexchange.com/a/364808
#   Not sure if still an issue, but can just as easily use
#   system_profiler instead.
# - REFER: Long discussion on determining if laptop:
#     https://apple.stackexchange.com/questions/98080/can-a-macs-model-year-be-determined-with-a-terminal-command
# - REFER: Database of Machine Identifiers:
#     https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
#   From the Ultimate Mac Lookup by Order No., Model No., Serial No., etc.
#     https://everymac.com/ultimate-mac-lookup/
#   - SAVVY: Checking for 'Book' in the ID is mostly accurate, but
#     it's a fragile Kludge, and doesn't always work, e.g., there
#     are at least 2 laptops without 'Book' in their IDs:
#       Description                         Model Identifier
#       MacBook Air "M2" 8 CPU/8 GPU 13     Mac14,2
#       MacBook Air "M2" 8 CPU/10 GPU 13    Mac14,2

is_probably_a_laptop () {
  system_profiler SPHardwareDataType \
    | grep -q -e "^ *Model Identifier: " \
    | grep -q -e "Book"
}

display_customize_external_monitor_mirror_displays () {
  is_probably_a_laptop || return 0

  print_at_end+=('🔳 System Settings: Displays:
  - If using a laptop connected to an external monitor,
    and the laptop lid is always closed, set up mirroring;
    otherwise skip this step.

    - Mirror both monitors:
      - 1920x1080
      - "Color LCD" color profile.
    - Note that the *Display Settings...* button appears when an external
      monitor connected (in my case, HDMI to USB-C).
    - Note circa 2022 on M1 Mac I needed to change resolution to 1280 x 720
      first, then to 1920 x 1080.
    - Unsure whether HDMI ghost dongle necessary.
      - On 2020 Intel MacBook, I needed the bi-directional EDID ghost to
        keep macOS from disconnecting the display when I changed HDMI inputs.
      - On 2020 M1 MacBook, I did not use the EDID ghost, because when it is
        used, the external monitor received no signal.')
}

display_customize_battery_power_adapter_turn_display_off_after_never () {
  is_probably_a_laptop || return 0

  print_at_end+=("🔳 System Settings: Battery: Power Adapter:
  - Turn display off after: Change from '10m' to 'Never'.")
}

display_customize_battery_power_adapter_no_sleep_when_display_is_off () {
  is_probably_a_laptop || return 0

  print_at_end+=("🔳 System Settings: Battery: Power Adapter:
  - ✓ Prevent your Mac from automatically sleeping when the display is off.
    - This prompts you about affecting battery life.")
}

display_customize_gripe_cannot_not_sleep_nor_lock_when_latched () {
  is_probably_a_laptop || return 0

  print_at_end+=("🤷 System Settings: Display Preferences: Do not Lock when Lid Closed
  - Throw a coaster on the laptop keyboard to keep lid from closing all the way.")
}

# Seems like a poor default, but notifs are disabled when an external
# display is connected (though perhaps it's a privacy concern, e.g.,
# so you don't unintentionally broadcast your notifs while screen
# casting, which is another form of external display).
display_customize_external_enable_notifications () {
  # ITSOK: This setting meant for laptop, but doesn't hurt regardless:
  #  is_probably_a_laptop || return 0

  print_at_end+=("🔳 System Settings: Notifications:
    ✓ Allow notifications when mirroring or sharing the display")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

accessibility_customize () {
  accessibility_customize_pointer_control_ignore_built_in_trackpad_when_mouse_is_present
  accessibility_customize_spoken_content_download_voices
}

# When I use the built-in keyboard, especially the modifier keys with my
# left hand, I often brush up against the trackpad.
accessibility_customize_pointer_control_ignore_built_in_trackpad_when_mouse_is_present () {
  is_probably_a_laptop || return 0

  echo "Accessibility: Motor: Pointer Control: ✓ Ignore built-in trackpad when mouse ... is present"
  defaults write com.apple.AppleMultitouchTrackpad USBMouseStopsTrackpad -bool true
}

# SAVVY: Sonoma includes a lot of *Enhanced* and *Premium* voices
# that sounds a lot less robotic.
# - I like: Fiona (Enhanced), Scottish-English; also Matilda (Enhanced,
#   not Premium, latter has weird inflections).
accessibility_customize_spoken_content_download_voices () {
  print_at_end+=("🔳 System Settings: Accessibility: Spoken Content: System Voice: Drop-down: Manage Voices...:
  - Select and download voices (e.g., pick a few \"Enhanced\" or \"Premium\" voices you like).")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

screenshots_customize () {
  screenshots_customize_location
  screenshots_customize_disable_shadow
  screenshots_customize_basename
  screenshots_customize_type__disabled

  restart_systemuiserver=true
}

# ***

screenshots_customize_location () {
  mkdir -p "${DXY_SCREENCAPS_LOCATION}"

  echo "Screencapture: Save screenshots to: ${DXY_SCREENCAPS_LOCATION}"
  defaults write com.apple.screencapture location "${DXY_SCREENCAPS_LOCATION}"
}

screenshots_customize_disable_shadow () {
  echo "Screencapture: Disable (annoyingly large, ~100px) window capture border"
  defaults write com.apple.screencapture disable-shadow -bool true
}

screenshots_customize_basename () {
  local screencap_basename="scrap"

  echo "Screencapture: Change basename 'Screen Shot YYYY-MM-DD at HH.MM.SS XM.png' → '${screencap_basename}... [datestamp] at [timestamp].[ext]'"
  defaults write com.apple.screencapture name "${screencap_basename}"
}

# I'm fine with the default, PNG, but here's how you'd change it.
screenshots_customize_type__disabled () {
  defaults delete com.apple.screencapture type 2> /dev/null || true
  false && (
    # Options: png, jpg, gif, pdf, bmp, jpeg, tiff.
    echo "Screencapture: Change image format: JPG"
    defaults write com.apple.screencapture type jpg
  )
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

finder_customize () {
  finder_customize_general_show_these_items_on_desktop_hard_disks_false
  finder_customize_general_show_these_items_on_desktop_connected_servers_false
  finder_customize_sidebar_show_these_items_in_the_sidebar
  finder_customize_advanced_show_all_filename_extensions
 
  finder_customize_disable_desktop_focus
  finder_customize_always_show_hidden_files

  finder_customize_add_quit_menu_option__disabled
  finder_customize_show_full_path_in_finder_window_title__disabled
  finder_customize_show_path_bar

  # https://gist.github.com/naotone/d2cbb30cd8d54d34869f
  finder_customize_disable_file_extension_change_warning
  finder_customize_set_preferred_view_style
  finder_customize_avoid_ds_store_file_creation_on_network_volumes

  # https://github.com/rusty1s/dotfiles/blob/master/macos/defaults.sh
  finder_customize_show_status_bar
  finder_customize_hide_tags_in_sidebar
  finder_customize_greater_sidebar_width
  finder_customize_empty_trash_sans_confirmation
  finder_customize_search_scope
  finder_customize_set_default_path_for_new_windows
}

# 2022-10-17: My latest MacBook (preconfigured from a client) already had these
# two items deselected -- Hard disks and Connected servers -- but my previous
# machine did not, so might as well include 'em.
finder_customize_general_show_these_items_on_desktop_hard_disks_false () {
  echo "Finder: Settings...: General > Show these items on the desktop: ✗ Hard disks"
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  restart_finder=true
}

finder_customize_general_show_these_items_on_desktop_connected_servers_false () {
  echo "Finder: Settings...: General > Show these items on the desktop: ✗ Connected servers"
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
  restart_finder=true
}

# These names are user- and machine-dependent, and I didn't see anything
# change under com.apple.finder, so add manually reminder.
finder_customize_sidebar_show_these_items_in_the_sidebar () {
  # SAVVY: $(id -un) aka ${LOGNAME}
  # - Add your user home so you can access directories you've created in your home directory.
  # - Add your host machine so you can access the root of the file system.
  print_at_end+=("\
🔳 Finder: Settings... (⌘ ,): Sidebar > Show these items in the sidebar:
   - Favorites: ✓ 🏡 $(id -un)
   - Locations: ✓ 💻 $(hostname)")
}

finder_customize_advanced_show_all_filename_extensions () {
  echo "Finder: Settings...: Advanced > ✓ Show all filename extensions"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  restart_finder=true
}

finder_customize_disable_desktop_focus () {
  echo "Finder: Disable Desktop so it doesn't steal focus when you click on it"
  defaults write com.apple.finder CreateDesktop -bool false
  restart_finder=true
}

# https://github.com/herrbischoff/awesome-macos-command-line#show-all-file-extensions
finder_customize_always_show_hidden_files () {
  echo "Finder: Always show hidden files (akin to always-on Shift-Command-.)"
  defaults write com.apple.finder AppleShowAllFiles -bool true
  restart_finder=true
}

finder_customize_add_quit_menu_option__disabled () {
  # Circa 2020-2021, Finder would show up in AltTab, which was annoying,
  # but I had found a way to Quit the Finder (and then I'd use Alt-Cmd-Space
  # or Shift-Cmd-F to open a Finder window).
  # - But nowadays, circa 2022-10-17, I don't see Finder in the AltTab list.
  #   So documenting here, but not enabling.
  false && (
    echo "Finder: Add Quit menu option"
    defaults write com.apple.finder QuitMenuItem -bool true
    restart_finder=true
  )
}

# I've never tried this option, nor does it sound appealing, but I do
# appreciate hidden features, and I like to document... *everything!*
#  https://github.com/herrbischoff/awesome-macos-command-line#show-full-path-in-finder-title
finder_customize_show_full_path_in_finder_window_title__disabled () {
  false && (
    echo "Finder: Show full path in Finder window title"
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    restart_finder=true
  )
}

finder_customize_show_path_bar () {
  echo "Finder: View > Show Path Bar (Cmd-Alt-P)"
  defaults write com.apple.finder ShowPathbar -bool true
  restart_finder=true
}

# ***

# https://gist.github.com/naotone/d2cbb30cd8d54d34869f

finder_customize_disable_file_extension_change_warning () {
  # Not sure if typo, or aliased, but rusty1s/dotfiles uses pluralized name:
  #   # Disable file extension change warning.
  #   defaults write com.apple.finder FXEnableExtensionsChangeWarning -bool false
  #                                                    ^
  # CXREF: https://github.com/rusty1s/dotfiles/blob/master/macos/defaults.sh
  echo "Finder: (Hidden?) Don't warn when user changes a file extension"
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  restart_finder=true
}

# DUNNO: Not sure where I found this list, nor if this ever worked for me,
# and doesn't seem to do anything.
# - Behavior seems to be if set view (e.g., View > List (Cmd-2)), then
#   directories you have not ever opened will use that view; otherwise
#   for directories you've previously viewed, they each use the last
#   used view used on them.
#
# Icon View   : `icnv`
# List View   : `Nlsv`
# Column View : `clmv`
# Cover Flow  : `Flwv`
finder_customize_set_preferred_view_style () {
  if false; then
    echo "Finder: Set preferred view style — Column View"
    defaults write com.apple.finder FXPreferredViewStyle clmv
    restart_finder=true
  else
    # 
    print_at_end+=("\
🔳 Finder: Choose List view early so it applies to directories you haven't viewed yet:
     Finder > View > List (Cmd-2)")
  fi
}

finder_customize_avoid_ds_store_file_creation_on_network_volumes () {
  # INERT/2022-11-18: If you have `.DS_Store` annoyances later, try:
  false && (
    echo "Finder: (Hidden?) Avoid creating .DS_Store files on network volumes"
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    restart_finder=true
  )
}

# ***

# https://github.com/rusty1s/dotfiles/blob/master/macos/defaults.sh

# FIXME/2023-02-07: Using reminders to demo these settings, which
# I have not tried, not because I'm lazy, but I don't have access
# to a MacBook currently.

# Shows '<> items, <> GB available' in footer below Path Bar, not
# very interesting.
finder_customize_show_status_bar () {
  if false; then
    echo "Finder: View > Show Status Bar (Cmd-/)"
    defaults write com.apple.finder ShowStatusBar -bool true
  fi
}

# Tags are last sidebar group (Favorites, iCloud, Locations, Tags).
# - Tags are colorful circles with colors namesa:
#     Red, Orange, Yellow, Green, Blue, Purple, Gray, All Tags...
#   - All Tags: also incl. Home, Important, Work
# - I've never used tags, and rarely use finder (or any file system
#   GUI). And I enjoy declutter. So hide the Tags group.
finder_customize_hide_tags_in_sidebar () {
  # CALSO: Finder: Settings...: Tags: Show these tags inthe sidebar:
  # - And then click '-' for each tag.
  echo "Finder: Hide tags in sidebar"
  defaults write com.apple.finder ShowRecentTags -bool false
}

# SAVVY: Should you need to increase the sidebar width:
finder_customize_greater_sidebar_width () {
  if false; then
    echo "Finder: Increase sidebar width"
    # - macOS Sonoma 14.4.1 default SidebarWidth -int 155
    defaults write com.apple.finder SidebarWidth -int 175
  fi
}

# WHTVR: Author uses sh-rm_safe ~/.trash, not macOS Trash.
finder_customize_empty_trash_sans_confirmation () {
  if false; then
    echo "Finder: Skip confirmation prompt when emptying trash"
    defaults write com.apple.finder WarnOnEmptyTrash -bool false
  fi
}

# Set search scope.
# This Mac       : `SCev`
# Current Folder : `SCcf`
# Previous Scope : `SCsp`
# WHTVR: Author is sure they don't care. Uses `locate`, `fd`, and
# other tools to search.
finder_customize_search_scope () {
  if false; then
    echo "Finder: Set search scope — Current Folder"
    # - macOS Sonoma 14.4.1 default FXDefaultSearchScope <delete>
    defaults write com.apple.finder FXDefaultSearchScope SCcf
  fi
}

# Finder Settings choices (Sonoma):
#   💻 @host
#   💽 Macintosh HD
#   ───────────────
#   📁 ~
#   📁 Desktop
#   📁 Documents
#   🌥 iCloud Drive
#   ───────────────
#   ✓ 🕘 Recents
#   ───────────────
#   Other...
#
# - Author is fond of user home
#
# Computer     : `PfCm`
# Volume       : `PfVo`
# $HOME        : `PfHm`
# Desktop      : `PfDe`
# Documents    : `PfDo`
# All My Files : `PfAF`
# Other…       : `PfLo`
finder_customize_set_default_path_for_new_windows () {
  echo "Finder Settings: General: New Finder windows show: ${LOGNAME}"
  if false; then
    defaults write com.apple.finder NewWindowTarget PfHm
  else
    print_at_end+=("\
🔳 Finder: Demo: Set default path for new windows: *See source for options*:
     defaults write com.apple.finder NewWindowTarget [PfCm|PfVo|PfHm|PfDe|PfDo|PfAF|PfLo]")
  fi
}

# ***

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

macos_customize () {
  # https://github.com/rusty1s/dotfiles/blob/master/macos/defaults.sh
  macos_customize_quit_printer_when_queue_empties
  macos_customize_disable_device_plug_opening_preview
  macos_customize_disable_itunes_listening_media_keys
}

# ***

# https://github.com/rusty1s/dotfiles/blob/master/macos/defaults.sh

# REFER: The following settings are disabled but captured because they
# seem like settings that might be difficult to find out about later
# if any of these issues bugs me later (but currently I don't print,
# and I don't use external devices, and I don't recall having issues
# with the media keys (though I think I usually adjust volume with
# menu bar drop-down).

# "Automatically quit printer app once the print jobs complete."
macos_customize_quit_printer_when_queue_empties () {
  echo "DISABLED: macOS Misc.: Printer: Quit when finished"
  false &&
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
}

# "Prevent Photos from opening automatically when devices are plugged in."
macos_customize_disable_device_plug_opening_preview () {
  echo "DISABLED: macOS Misc.: External devices: Do not launch Photos on mount"
  false &&
    defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
}

# "Stop iTunes from responding to the keyboard media keys."
macos_customize_disable_itunes_listening_media_keys () {
  echo "DISABLED: macOS Misc.: Media keys: Disable iTunes listening on media keys"
  false &&
    launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CXREF: app_shortcuts_customize_google_chrome
google_chrome_customize () {
  # 2023-01-29: Using Finicky as default browser now, as intermediary.
  if false; then
    ${non_disruptive} ||
      google_chrome_customize_make_default_browser
  fi

  google_chrome_customize_suggest_setup

  google_chrome_customize_continue_where_you_left_off

  google_chrome_customize_devtools_show_timestamps
  google_chrome_customize_devtools_show_user_agent_shadow_dom

  google_chrome_customize_add_extension_react_developer_tools
  google_chrome_customize_add_extension_redux_devtools
  google_chrome_customize_add_extension_clear_cache
  google_chrome_customize_add_extension_visbug

  google_chrome_customize_import_bookmarks
}

# ***

# Note there's a third-party app to set the default browser:
#   brew install defaultbrowser
#   defaultbrowser chrome
# - 2022-10-18: Never mind, I tried `default browser` on 2020-09-01, and it
#   popped up a new iTerm2 window to confirm the change, which was a might
#   peculiar for an app I executed from the terminal! Seems more distruptive
#   and no less automated that telling Google Chrome --make-default-browser.
# Or better yet we can use AppleScript.
google_chrome_customize_make_default_browser () {
  echo "Google Chrome: Make default browser"

  echo "- Google Chrome: Closing so we can open-tell it to --make-default-browser"
  # MAYBE: There's probably a way to make this work with needing to quit the app.
  osascript -e 'tell application "Google Chrome" to quit'

  # Note: If Chrome is already open and windows minimized, this unminimizes one.
  open -a "Google Chrome" --args --make-default-browser
}

google_chrome_customize_suggest_setup () {
  print_at_end+=("\
🔳 Google Chrome: Initial setup:
  - Remove New Tab shortcut(s) (e.g., Web Store)
  - Click *Customize Chrome* (lower-right)
    - Decide *My shortcuts* vs. *Most visited sites*
  - Skip setting Chrome as default browser (We use *Finicky*)
  - Decline Chrome Sync
")
}

google_chrome_customize_continue_where_you_left_off () {
  print_at_end+=("🔳 Google Chrome: ⋮ > Settings (Command-,) > On startup > Continue where you left of")
}

google_chrome_customize_devtools_show_timestamps () {
  print_at_end+=("🔳 Google Chrome: DevTools: [Gear icon]: Preferences > Console > ✓ Timestamps")
}

# REFER: https://css-tricks.com/sliding-nightmare-understanding-range-input/
google_chrome_customize_devtools_show_user_agent_shadow_dom () {
  print_at_end+=("🔳 Google Chrome: DevTools: [Gear icon]: Preferences > Elements > ✓ Show user agent shadow DOM")
}

# ***

google_chrome_customize_add_extension_react_developer_tools () {
  print_at_end+=("\
🔳 Google Chrome: Add extenstion: React Developer Tool
     sensible-open https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi?hl=en
     sensible-open https://github.com/facebook/react/tree/master/packages/react-devtools-extensions")
}

google_chrome_customize_add_extension_redux_devtools () {
  print_at_end+=("\
🔳 Google Chrome: Add extenstion: Redux DevTools
     sensible-open https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd/related?hl=en
- 🔳 Configure Redux DevTools: [Icon right of location] > Options: ✓ Allow in incognito
- 🔳 Configure Redux DevTools: Keyboard shortcut: Shift-Cmd-E → Alt-Shift-R
       sensible-open chrome://extensions/shortcuts")
}

# Clear Cache is helpful where Shift-F5 not clearing what you need cleared
# (e.g., temporary access tokens).
google_chrome_customize_add_extension_clear_cache () {
  print_at_end+=("\
🔳 Google Chrome: Add extenstion: Clear Cache
     sensible-open https://chrome.google.com/webstore/detail/clear-cache/cppjkneekbjaeellbfkmgnhonkkjfpdn/RK%3D2/RS%3DzwqaryCReNAACSfd_oYYPpX0_tw-
- 🔳 Configure Clear Cache: Reload: ✔ Automatically reload active tab after clearing data
- 🔳 Configure Clear Cache: Date to Remove: ☑ Local Storage
- 🔳 Configure Clear Cache: Time Period: 🔘 Last Day
- 🔳 Configure Redux DevTools: Keyboard shortcut: (none) → Alt-Shift-E [rEload]
       sensible-open chrome://extensions/shortcuts")
}

# What I said 2021-02-02: I'm just tossing this in the mix, as recommended
# by co-workers, but not something I've used or for which I can vouch.
# - Looks like mostly for developing/debugging UI components, CSS and related.
google_chrome_customize_add_extension_visbug () {
  print_at_end+=("\
🔳 Google Chrome: Add extenstion: VisBug
     sensible-open https://chrome.google.com/webstore/detail/visbug/cdockenadnadldjbbgcallicgledbeoc?hl=en")
}

# ***

# Not sure you'll have bookmarks. (I currently don't ship bookmarks with DepoXy.)
# - FIXME: Ya know, you could make bookmarks for all the Google Chrome extensions
#          you want to install!
#          - Then update this item with a filepath to said bookmarks file.
google_chrome_customize_import_bookmarks () {
  print_at_end+=("🔳 Google Chrome: Bookmarks manager (Ctrl-Shift-O): ⋮ > Import bookmarks")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CXREF: app_shortcuts_customize_firefox
mozilla_firefox_customize() {
  mozilla_firefox_customize_devtools_show_user_agent_shadow_dom
  mozilla_firefox_customize_customize_add_extension_redux_devtools
}

# REFER: https://css-tricks.com/sliding-nightmare-understanding-range-input/
mozilla_firefox_customize_devtools_show_user_agent_shadow_dom () {
  print_at_end+=("\
🔳 Mozilla Firefox: DevTools: Verify `devtools.inspector.showAllAnonymousContent` is true
    firefox about:config")
}

mozilla_firefox_customize_customize_add_extension_redux_devtools () {
  print_at_end+=("\
🔳 Mozilla Firefox: Add extenstion: Redux DevTools
     sensible-open https://github.com/zalmoxisus/redux-devtools-extension")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

alttab_customize () {
  alttab_customize_controls_minimized_windows__hide
  alttab_customize_controls_hidden_windows__hide
  alttab_customize_controls_while_open_quit_app_noop
  alttab_customize_controls_while_open_select_previous_window_q
  alttab_customize_controls_while_open_close_window_noop
  alttab_customize_controls_also_select_windows_using_mouse_hover_off
  alttab_customize_appearance_theme_windows_10
  alttab_customize_blocklist_hide_in_alttab

  killall "AltTab"
}

# ***

alttab_customize_controls_minimized_windows__hide () {
  echo "AltTab: Preferences... > Controls > Shortcut 1
    > Minimized windows: Hide"
  defaults write com.lwouis.alt-tab-macos showMinimizedWindows -int 1

  # Alternatively:
  false && (
    echo "AltTab: Preferences... > Controls > Shortcut 1
      > Minimized windows: Show at the end"
    defaults write com.lwouis.alt-tab-macos showMinimizedWindows -int 2
  )
}

# DUNNO: This option doesn't hide what I think are hidden windows,
# like Activity Monitor, and Pulse Secure. Doesn't seem to change
# a thing for me. But I can hide them using the blocklist. Though
# we'll still set this option to show our intent, to hide hiddens.
alttab_customize_controls_hidden_windows__hide () {
  echo "AltTab: Preferences... > Controls > Shortcut 1
    > Hidden windows: Hide"
  defaults write com.lwouis.alt-tab-macos showHiddenWindows -int 1
}

# My brain is hard-wired to Alt-tab and then press 'q' to reverse direction
# in the list, but that keeps closing the app!
# Default: *Removed*.
alttab_customize_controls_while_open_quit_app_noop () {
  echo "AltTab: Preferences... > Controls > Shortcut 1
    > While open, press: ✗ — Quit app (default: 'Q')"
  defaults write com.lwouis.alt-tab-macos quitAppShortcut ''
}

alttab_customize_controls_while_open_select_previous_window_q () {
  echo "AltTab: Preferences... > Controls > Shortcut 1
    > While open, press: 'q' — Select previous window (default: ⇧ Shift)"
  defaults write com.lwouis.alt-tab-macos previousWindowShortcut "Q"
}

# Might as well nix the Close window action, too.
alttab_customize_controls_while_open_close_window_noop () {
  echo "AltTab: Preferences... > Controls > Shortcut 1
    > While open, press: ✗ — Close window (default: 'W')"
  defaults write com.lwouis.alt-tab-macos closeWindowShortcut ''
}

# I often have my hand on the mouse when Alt-Tabbing, and even the smallest
# mouse movement causes the selection to change to the window under mouse.
# - UGH: This one is tough. It really bothers me that the smallest mouse
#   movement moves focus, at least when I don't intend to do so; but it
#   really bothers me that I cannot click on windows.
#   - But you can Mission Control via either lower corner, and via
#     Ctrl-Alt-Up, and you can click MC windows, so maybe I just need
#     to remember to use Mission Control if I'm looking for an app
#     window to click.
alttab_customize_controls_also_select_windows_using_mouse_hover_off () {
  echo "AltTab: Preferences... > Controls > Shortcut 1
    > Also select windows using: ✗ Mouse hover"
  defaults write com.lwouis.alt-tab-macos mouseHoverEnabled -string "false"
}

# AltTab defaults to "macOS" theme but also has a "Windows 10" theme.
# - I prefer the Windows 10 theme because AltTab draws a white border
#   around the currently selected window. The macOS theme uses a darkish
#   background, but the whole AltTab popup is somewhat dark, so it's
#   difficult to see which window is selected with the macOS theme.
# - ALSOY/2024-04-24: Also yes: I thought the "macOS" theme appearance on
#   Sonoma was initially pretty good, and the Windows 10 theme a little
#   too bright, too contrasty. But within days I found it a struggle to
#   find what I'm looking for with the default "macOS" theme. So another
#   vote to keep the "Windows 10" theme (and the noticeable white border).
alttab_customize_appearance_theme_windows_10 () {
  echo "AltTab: Preferences... > Appearance
    > Theme: “Windows 10” (easier to see selected window; default: macOS)"
  defaults write com.lwouis.alt-tab-macos theme -string "1";
}

# I'd rather not try to write the blocklist value, which is a large array
# with ten entries by default, something like this:
#
#   blacklist = "[{\\"ignore\\":\\"0\\",\\"bundleIdentifier\\":\\"com.McAfee.McAfeeSafariHost\\",\\"hide\\":\\"1\\"},{\\"ignore\\":\\"0\\",\\"bundleIdentifier\\":...}]";
#
# MAYBE: Though maybe `defaults -array-add` would work.
#
# If you perform the additions listed below, you'll see the following new entries
# appended to the array:
# - Pulse Secure:
#   {\\"ignore\\":\\"0\\",\\"bundleIdentifier\\":\\"net.pulsesecure.Pulse-Secure\\",\\"hide\\":\\"1\\"},
# - Activity Monitor:
#   {\\"ignore\\":\\"0\\",\\"bundleIdentifier\\":\\"com.apple.ActivityMonitor\\",\\"hide\\":\\"1\\"}
# - Webex :
#   {\\"ignore\\":\\"0\\",\\"bundleIdentifier\\":\\"Cisco-Systems.Spark\\",\\"hide\\":\\"1\\"}]	";
# Note that Webex is the Sign in/Join a meeting window, and not the video call window.
#   - Note that I couldn't find a way to add the "Webex Meetings" to the AltTab
#     blockllist, which I wanted to do because when you AltTab to the meetings
#     window, it does not foreground the window (though it will foreground the
#     app, as you'll see the Webex Meetings menu bar). So you'll want to fore-
#     ground Webex Meetings using another method: Apple's Cmd-tab or Mission
#     Control, or our Karabiner-Elementes Shift-Ctrl-Cmd-W mapping.
#
# ISOFF/2024-04-16: I don't see Activity Monitor in Alt-tab list unless it's open.
#   - /System/Applications/Utilities/Activity Monitor.app
alttab_customize_blocklist_hide_in_alttab () {
  print_at_end+=("$(cat << 'EOF'
🔳 AltTab: Preferences...: Blacklists: +: [Select app] / Hide in AltTab: Always
   - Hide apps that appear in AltTab even when not open, e.g.,:
     - /Applications/Pulse Secure.app
     - /Applications/Webex.app
EOF
  )")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# What the *function*?! *Easy Move+Resize* is such a pompous app, it uses
# a completely generic and non-compliant plist domain, "userPrefs", ha!
# Someone should open a pull request to fix this... aka "someone not me".
# - Aka easy-move-plus-resize
easy_move_plus_resize_customize () {
  easy_move_plus_resize_customize_drag_modifier

  killall "Easy Move+Resize"
}

easy_move_plus_resize_customize_drag_modifier () {
  echo "Easy Move+Resize: Click window and drag modifiers: CTRL,CMD → ALT"
  defaults write userPrefs ModifierFlags -string "ALT"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

karabiner_elements_customize () {
  karabiner_elements_customize_devices_devices_modify_events
  karabiner_elements_customize_complex_modifications_add_rule_all
}

karabiner_elements_customize_devices_devices_modify_events () {
  print_at_end+=("🔳 Karabiner Elements: Settings...: Devices:
   - Verify *Modify events* enabled on all keyboards")
  print_at_end+=("🔳 Karabiner Elements: Settings...: Devices:
   - Verify *Modify events* enabled on all mouse")
}

karabiner_elements_customize_complex_modifications_add_rule_all () {
  print_at_end+=("🔳 Karabiner Elements: Settings...: Complex Modications:
   - Click (+) “Add predefined rule” and *Enable All* for each set of rules you want)")
  print_at_end+=("🔳 Karabiner Elements: Restart some apps for changes to take effect, e.g., MacVim")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# List of Keyboard Key icons:
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
#     ⌽  - On/Off/Power symbol (maybe?) (APL Functional Symbol Circle Stile)
#       - Apple logo approximation (U+F8FF, try Option (⌥)-Shift (⇧)-K on a Mac)
#          (Apple devices only: Uses last private-use codepoint.
#           Looks like Pi symbol in a solid square on Linux/Hack Font.)
#     ⊞  - Windows logo approximation (Squared Plus)
#     🐧 - Linux (Tux) approximation (Penguin).
#        - ⇞ Page Up / ⇟ Page Down / ↖︎ Top (Home) / ↘︎ End
#
#     macOS display order: Ctrl-Option-Shift-Command-<key> / ^⌥⇧⌘<key>

# REFER: Apple Support's *Mac keyboard shortcuts*
#   https://support.apple.com/en-us/HT201236

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# So nice: Note that changes to Rectangle's plist take effect immediately.

rectangle_customize () {
  echo "Rectangle: ✓ Check for updates automatically"
  defaults write com.knollsoft.Rectangle SUEnableAutomaticChecks -bool true

  # ***

  # We'll set those settings you see in the upper-right of the Rectangle
  # Preferences dialog first, because *Maximize Height* uses the same
  # shortcut we want to apply to *Top Half*, so let's release the shortcut
  # first and not create a conflict (not that I know what would happen,
  # but if you try to record a shortcut in Rectangle that's already being
  # used, Rectangle performs the shortcut action, rather than recording
  # the keys-stroke. So, at least via the dialog, you need to clear a
  # shortcut if in use before recording it for another action.

  echo "Rectangle: Miscellany: Maximize: ^⌥ ⏎  → ^⇧⌘ * aka Ctrl-Shift-Cmd-*"
  defaults write com.knollsoft.Rectangle maximize "{ keyCode = 67; modifierFlags = 917504; }"
  echo "Rectangle: Miscellany: Almost Maximize: (Unset) → ^⇧⌘ ? aka Ctrl-Shift-Cmd-?"
  defaults write com.knollsoft.Rectangle almostMaximize "{ keyCode = 44; modifierFlags = 917504; }"
  echo "Rectangle: Miscellany: Maximize Height: ^⌥ ⇧↑ → ^⇧⌘ H aka Ctrl-Shift-Cmd-H"
  defaults write com.knollsoft.Rectangle maximizeHeight "{ keyCode = 4; modifierFlags = 917504; }"

  echo "Rectangle: Miscellany: Make Smaller: ^⌥ - → ^⇧⌘ - aka Ctrl-Shift-Cmd--"
  defaults write com.knollsoft.Rectangle smaller "{ keyCode = 78; modifierFlags = 917504; }"
  echo "Rectangle: Miscellany: Make Larger: ^⌥ = → ^⇧⌘ + aka Ctrl-Shift-Cmd-+"
  defaults write com.knollsoft.Rectangle larger "{ keyCode = 69; modifierFlags = 917504; }"

  echo "Rectangle: Miscellany: Center: ^⌥ C → ^⇧⌘ 5 aka Ctrl-Shift-Cmd-Numpad5"
  defaults write com.knollsoft.Rectangle center "{ keyCode = 87; modifierFlags = 917504; }"
  echo "Rectangle: Miscellany: Restore: ^⌥ ⌫  → ^⇧⌘ 0 aka Ctrl-Shift-Cmd-Numpad0"
  defaults write com.knollsoft.Rectangle restore "{ keyCode = 82; modifierFlags = 917504; }"

  # The Display motions are no-ops unless you have a second display attached.
  # - One option to disable them (to release the keybindings):
  if false; then
    echo "Rectangle: Miscellany: Next Display: ^⌥ ⌘ → → (Unset)"
    defaults write com.knollsoft.Rectangle nextDisplay "{ }"
    echo "Rectangle: Miscellany: Previous Display: ^⌥ ⌘ ← → (Unset)"
    defaults write com.knollsoft.Rectangle previousDisplay "{ }"
  fi

  # ***

  echo "Rectangle: Halfs: Left Half: ^⌥ ← → ^⇧⌘ ← aka Ctrl-Shift-Cmd-LeftArrow"
  defaults write com.knollsoft.Rectangle leftHalf "{ keyCode = 123; modifierFlags = 917504; }"
  echo "Rectangle: Halfs: Right Half: ^⌥ → → ^⇧⌘ → aka Ctrl-Shift-Cmd-RightArrow"
  defaults write com.knollsoft.Rectangle rightHalf "{ keyCode = 124; modifierFlags = 917504; }"
  echo "Rectangle: Halfs: Center Half: (Leave unset)"
  # SAVVY: If you try to set ^⇧⌘ ↑ manually, it's already set to Maximize Height, so
  #        rather than recording the shortcut, Rectangle performs Maximize Height.
  #        - So you have to clear the Maximize Height Shortcut first.
  echo "Rectangle: Halfs: Top Half: ^⌥ ↑ → ^⇧⌘ ↑ aka Ctrl-Shift-Cmd-UpArrow"
  defaults write com.knollsoft.Rectangle topHalf "{ keyCode = 126; modifierFlags = 917504; }"
  echo "Rectangle: Halfs: Bottom Half: ^⌥ ↓ → ^⇧⌘ ↓ aka Ctrl-Shift-Cmd-DownArrow"
  defaults write com.knollsoft.Rectangle bottomHalf "{ keyCode = 125; modifierFlags = 917504; }"

  # ***

  echo "Rectangle: Corners: Top Left: ^⌥ U → ^⇧⌘ 7 aka Ctrl-Shift-Cmd-Numpad7"
  defaults write com.knollsoft.Rectangle topLeft "{ keyCode = 89; modifierFlags = 917504; }"
  echo "Rectangle: Corners: Top Right: ^⌥ I → ^⇧⌘ 9 aka Ctrl-Shift-Cmd-Numpad9"
  defaults write com.knollsoft.Rectangle topRight "{ keyCode = 92; modifierFlags = 917504; }"
  echo "Rectangle: Corners: Bottom Left: ^⌥ J → ^⇧⌘ 1 aka Ctrl-Shift-Cmd-Numpad1"
  defaults write com.knollsoft.Rectangle bottomLeft "{ keyCode = 83; modifierFlags = 917504; }"
  echo "Rectangle: Corners: Bottom Right: ^⌥ K → ^⇧⌘ 3 aka Ctrl-Shift-Cmd-Numpad3"
  defaults write com.knollsoft.Rectangle bottomRight "{ keyCode = 85; modifierFlags = 917504; }"

  # ***

  echo "Rectangle: Thirds: First Third: ^⌥ D → ^⇧⌘ { aka Ctrl-Shift-Cmd-{"
  defaults write com.knollsoft.Rectangle firstThird "{ keyCode = 33; modifierFlags = 917504; }"
  echo "Rectangle: Thirds: Center Third: ^⌥ F → ^⇧⌘ | aka Ctrl-Shift-Cmd-|"
  defaults write com.knollsoft.Rectangle centerThird "{ keyCode = 42; modifierFlags = 917504; }"
  echo "Rectangle: Thirds: Last Third: ^⌥ G → ^⇧⌘ } aka Ctrl-Shift-Cmd-}"
  defaults write com.knollsoft.Rectangle lastThird "{ keyCode = 30; modifierFlags = 917504; }"
  echo "Rectangle: Thirds: First Two Thirds: ^⌥ E → ^⇧⌘ < aka Ctrl-Shift-Cmd-<"
  defaults write com.knollsoft.Rectangle firstTwoThirds "{ keyCode = 43; modifierFlags = 917504; }"
  echo "Rectangle: Thirds: Last Two Thirds: ^⌥ T → ^⇧⌘ > aka Ctrl-Shift-Cmd->"
  defaults write com.knollsoft.Rectangle lastTwoThirds "{ keyCode = 47; modifierFlags = 917504; }"

  # ***

  echo "Rectangle: Fourths: First Fourth: (Leave unset)"
  echo "Rectangle: Fourths: Second Fourth: (Leave unset)"
  echo "Rectangle: Fourths: Third Fourth: (Leave unset)"
  echo "Rectangle: Fourths: Last Fourth: (Leave unset)"
  echo "Rectangle: Fourths: First Three Fourths: (Leave unset)"
  echo "Rectangle: Fourths: Last Three Fourths: (Leave unset)"


  # ***

  echo "Rectangle: Edge-Centered: Move Left: (Unset) → ^⇧⌘ 4 aka Ctrl-Shift-Cmd-Numpad4"
  defaults write com.knollsoft.Rectangle moveLeft "{ keyCode = 86; modifierFlags = 917504; }"
  echo "Rectangle: Edge-Centered: Move Right: (Unset) → ^⇧⌘ 6 aka Ctrl-Shift-Cmd-Numpad6"
  defaults write com.knollsoft.Rectangle moveRight "{ keyCode = 88; modifierFlags = 917504; }"
  echo "Rectangle: Edge-Centered: Move Up: (Unset) → ^⇧⌘ 8 aka Ctrl-Shift-Cmd-Numpad8"
  defaults write com.knollsoft.Rectangle moveUp "{ keyCode = 91; modifierFlags = 917504; }"
  echo "Rectangle: Edge-Centered: Move Down: (Unset) → ^⇧⌘ 2 aka Ctrl-Shift-Cmd-Numpad2"
  defaults write com.knollsoft.Rectangle moveDown "{ keyCode = 84; modifierFlags = 917504; }"

  # ***

  echo "Rectangle: Sixths: Top Left Sixth: (Leave unset)"
  echo "Rectangle: Sixths: Top Center Sixth: (Leave unset)"
  echo "Rectangle: Sixths: Top Right Sixth: (Leave unset)"
  echo "Rectangle: Sixths: Bottom Left Sixth: (Leave unset)"
  echo "Rectangle: Sixths: Bottom Center Sixth: (Leave unset)"
  echo "Rectangle: Sixths: Bottom Right Sixth: (Leave unset)"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

activity_monitor_customize () {
  activity_monitor_customize_dock_icon_show_cpu_history
}

activity_monitor_customize_dock_icon_show_cpu_history () {
  false && (
    echo "Activity Monitor: Right-click Dock Icon: Dock Icon > ✓ Show CPU Usage"
    defaults write com.apple.ActivityMonitor IconType -int 5
  )
  echo "Activity Monitor: Right-click Dock Icon: Dock Icon > ✓ Show CPU History"
  defaults write com.apple.ActivityMonitor IconType -int 6
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CXREF: app_shortcuts_customize_iterm2
iterm2_customize () {
  iterm2_customize_general_selection_copy_to_pasteboard_on_selection_off

  iterm2_customize_profiles_color_scheme_pastel
  iterm2_customize_profiles_color_foreground_color
  iterm2_customize_profiles_text_font_hack_nerd_font
  iterm2_customize_profiles_window_settings_for_new_windows_columns_rows
  iterm2_customize_profiles_terminal_scrollback_buffer_scrollback_lines
  iterm2_customize_profiles_terminal_notifications_silence_bell_true
  iterm2_customize_profiles_terminal_notifications_show_bell_icon_in_tabs_false
  iterm2_customize_profiles_keys_left_option_key_escape_plus

  # Profile keybindings.
  iterm2_customize_keys_key_bindings_register_inputrc_bindings

  # Application keybindings.
  iterm2_customize_keys_key_bindings_add__ctrl_shift_c_remap_mods_in_iTerm2_only
  iterm2_customize_keys_key_bindings_add__ctrl_command_f_toggle_fullscreen
  # gnome-terminal/mate-terminal parity.
  # - Note that gnome-terminal documents -- as immutable! -- the bindings:
  #   ctrl-shift-up/down, and shift-(page)up/(page)down. But mate-terminal
  #   also maps ctrl-shift-(page)up/(page)down, so if you just remember
  #   the ctrl-shift-prefix, you can perform terminal scroll motion.
  # - On macOS, you'll find iTerm maps Cmd-Home/End, and Shift-PageUp/Down
  #   and Cmd-PageUp/Down, which we'll rebind like @linux so that we don't
  #   have to rewire our brains to remember to check which terminal we're
  #   on before pressing a scroll motion (it's like riding a fixed gear
  #   bike, where to rewire your brain so that when you want to stop
  #   pedaling, you no longer just stop pedaling, but your brain intercepts
  #   the request and double-checks what type of bike you're riding, and
  #   if you're riding a fixed gear bike, then it'll engage resistance
  #   pedaling instead). This new wirings are fun and all, but they cost
  #   time and energy. And I'd enjoy a more seamless experience, hence
  #   these mappings.
  #
  # By default, Ctrl-Shift-Up/Down do nothing...
  # No, wait, these jump Vim windows, and may be wired to tmux window jumping, too...
  # - In Vim in iTerm2 by default, Ctrl-Shift-Up/Down move cursor between windows.
  #   - But I rarely use multiple windows in terminal Vim, so this settings I guess
  #     I con't mind shadowing.
  iterm2_customize_keys_key_bindings_add__ctrl_shift_up__scroll_one_line_up
  iterm2_customize_keys_key_bindings_add__ctrl_shift_down__scroll_one_line_down
  #
  # By default, Ctrl-Shift-PageUp/PageDown cycle through history, like Up/Down does.
  # In Vim, selects up/down to page boundary without scrolling.
  # - In Vim in iTerm2 by default, Ctrl-Shift-PageUp/PageDown moves cursors
  #   and scrolls by page, but doesn't select.
  #   - So nothing lost by shadowing Vim's Ctrl-Shift-PageUp/PageDown.
  iterm2_customize_keys_key_bindings_add__ctrl_shift_pageup__scroll_one_page_up
  iterm2_customize_keys_key_bindings_add__ctrl_shift_pagedown__scroll_one_page_down
  # By default, Ctrl-Shift-Home/End do nothing.
  # In Vim, selects up/down by document.
  # - It Vim in Iterm2 by default, Ctrl-Shift-Up/Down selects by document...
  #   - So maybe I don't want to shadow this? Though I rarely selecting all
  #     of a document from terminal Vim. I'd do that from GVim. So... maybe
  #     don't care if shadowed?
  #     - GRIPE: Maybe I wish gnome-terminal support re-binding these motions.
  #       Then maybe I would choose the Cmd key or something, so I wasn't
  #       shadowing Vim motions.
  iterm2_customize_keys_key_bindings_add__ctrl_shift_home__scroll_to_top
  iterm2_customize_keys_key_bindings_add__ctrl_shift_end__scroll_to_bottom

  iterm2_customize_advanced_pasteboard_pressing_a_key_will_remove_the_selection_no
  iterm2_customize_advanced_pasteboard_trim_whitespace_when_copying_to_pasteboard_no

  iterm2_customize_increase_paste_buffer_size

  iterm2_customize_permission_full_disk_access

  iterm2_customize_profiles_general_command
  iterm2_customize_profiles_add_profile_norc_5x
  iterm2_customize_profiles_add_profile_norc_5x_lite
  iterm2_customize_profiles_add_profile_bash_5x
  iterm2_customize_profiles_add_profile_norc_3x
}

# ***

iterm2_customize_general_selection_copy_to_pasteboard_on_selection_off () {
  echo "iTerm2: General > Selection > ✗ Copy to pasteboard on selection"
  defaults write com.googlecode.iterm2 CopySelection -bool false
}

# ***

# SAVVY: iTerm2 > Settings... brings up "Preferences" dialog.
# - I bet macOS automatically changes all the apps' "Preferences..."
#   menu labels to "Settings...", because I've seen this disconnect
#   with other apps, too.

iterm2_customize_profiles_color_scheme_pastel () {
  # I see too many settings changed, so tell user to do this manually.
  # - Sonoma 14.4.1 default: Color Presets...: Dark Background
  # ISOFF/2024-04-16: Did iTerm2 make a better preset? Because default
  #   colors in Sonoma 14.4.1 look... great?
  false && (
    print_at_end+=("🔳 iTerm2: Preferences: Profiles: Colors: Color Presets...: ✓ Pastel (Dark Background)")
  )
}

iterm2_customize_profiles_color_foreground_color () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Colors: Basic Colors: Foreground: c7c7c7 → e3e3e3 (a brighter white)")
  # This appears to be a setting under "New Bookmarks", and I'm not sure if I'd
  # have to set the whole value or not (and the whole values is one hundred or
  # more lines, lots of entries. E.g.,
  # - Maybe the `-dict-add` option would work here?
  #
  #  "New Bookmarks" = ( {
  #    "ASCII Anti Aliased" = 1;
  #    ...
  #    "Foreground Color" = {
  #      "Alpha Component" = 1;
  #      "Blue Component" = "0.8901960784313725";
  #      "Color Space" = sRGB;
  #      "Green Component" = "0.8901960784313725";
  #      "Red Component" = "0.8901960784313725";
  #    };
  #    ...
  #  } )
}

iterm2_customize_profiles_text_font_hack_nerd_font () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Text: Font: Hack Nerd Font Mono")
}

iterm2_customize_profiles_window_settings_for_new_windows_columns_rows () {
  # Well, I tried:
  #   $ defaults write com.googlecode.iterm2 "New Bookmarks" -dict-add Columns 141
  #   Value for key New Bookmarks is not a dictionary; cannot append.  Leaving defaults unchanged.
  #   # defaults write com.googlecode.iterm2 "New Bookmarks" -dict-add Rows 47
  # So not sure how to set these values.
  #   $ defaults read-type com.googlecode.iterm2 "New Bookmarks"
  #   Type is array
  # Oh, it's an array of dictionaries, I think because iTerm2 supports multiple
  # *Profiles*. Hrmmm.
  # `defaults` has a similar `-array-add` command... but I bet I'd have to re-write
  # the entire array... which maybe I would read it first...
  #   defaults read com.googlecode.iterm2 "New Bookmarks"
  # and then /bin/sed the changes and write the blob back...
  # but I don't want to spend a bunch of time trying to figure this out!
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Window: Settings for New Windows: Columns: 140")
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Window: Settings for New Windows: Rows: 47")
}

iterm2_customize_profiles_terminal_scrollback_buffer_scrollback_lines () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Terminal: Scrollback lines: ✓ Unlimited scrollback")
}

iterm2_customize_profiles_terminal_notifications_silence_bell_true () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Terminal: Notifications: ✓ Silence bell")
}

iterm2_customize_profiles_terminal_notifications_show_bell_icon_in_tabs_false () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Terminal: Notifications: ✗ Show bell icon in tabs")
}

# Make Option behave like Alt (e.g., type Alt-. to print last word of last commands).
iterm2_customize_profiles_keys_left_option_key_escape_plus () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Keys: General: Left Option key: Esc+")
}

# ***

iterm2_customize_keys_key_bindings_register_inputrc_bindings () {
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Keys: Key Mappings: +: Action: Send Escape Sequence / Keyboard Shortcut: Alt-Left / Esc+: [1;3D")
  print_at_end+=("🔳 iTerm2: Preferences: Profiles: Keys: Key Mappings: +: Action: Send Escape Sequence / Keyboard Shortcut: Alt-Right / Esc+: [1;3C")
}

# ***

# The Key Bindings property list defaults settings are potentially
# encodable, but they're also obtuse enough I don't want to bother
# now seeing how easy these might be to set programmatically.
#
# E.g., here are the bindings for mapping Ctrl-Shift-Home/End to "Scroll To Top/End":
#
#     GlobalKeyMap = {
#         ...
#
#         "0xf729-0x60000-0x73" = {
#             Action = 5;
#             Label = "";
#             Text = "";
#             Version = 1;
#         };
#         "0xf72b-0x60000-0x77" = {
#             Action = 4;
#             Label = "";
#             Text = "";
#             Version = 1;
#         };

# Prevent Ctrl-Shift-C from sending Ctrl-C when nothing is selected.
iterm2_customize_keys_key_bindings_add__ctrl_shift_c_remap_mods_in_iTerm2_only () {
  # This adds a big section to GlobalKeyMap that I don't want to mess with.
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Remap Modifiers in iTerm2 Only / Shortcut: Ctrl-Shift-C")
}

iterm2_customize_keys_key_bindings_add__ctrl_command_f_toggle_fullscreen () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Toggle Fullscreen / Shortcut: Ctrl-Cmd-F")
}

# ***

iterm2_customize_keys_key_bindings_add__ctrl_shift_up__scroll_one_line_up () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll One Line Up / Shortcut: Ctrl-Shift-Up
   - Note this conflicts with a profile key binding, and the profile
     shortcut overrides the global keyboard shortcut.
   - Delete the profile key mapping first from the Default profile:
     - 🔳 iTerm2: Preferences: Profiles: Keys: Key Mappings: - (Del): “Send ^[[1;6A”
          ^⇧↑ (Ctrl-Shift-Up) / Action: Send Escape Sequence / Esc+: [1;6A")
  # ISOFF/2024-04-16: Didn't happen in Sonoma 14.4.1:
  #  - You'll still have to \"OK\" a Warning popup about conflicts with the other profiles' mappings,
  #    but nothing to worry about if you mostly use the Default profile.
}

iterm2_customize_keys_key_bindings_add__ctrl_shift_down__scroll_one_line_down () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll One Line Down / Shortcut: Ctrl-Shift-Down
   - Ditto delete the profile key mapping first from the Default profile:
     - 🔳 iTerm2: Preferences: Profiles: Keys: Key Mappings: - (Del): “Send ^[[1;6B”
          ^⇧↓ (Ctrl-Shift-Down) / Action: Send Escape Sequence / Esc+: [1;6B")
}

iterm2_customize_keys_key_bindings_add__ctrl_shift_pageup__scroll_one_page_up () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll One Page Up / Shortcut: Ctrl-Shift-PageUp")
}

iterm2_customize_keys_key_bindings_add__ctrl_shift_pagedown__scroll_one_page_down () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll One Page Down / Shortcut: Ctrl-Shift-PageDown")
}
iterm2_customize_keys_key_bindings_add__ctrl_shift_home__scroll_to_top () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll to Top / Shortcut: Ctrl-Shift-Home")
}

iterm2_customize_keys_key_bindings_add__ctrl_shift_end__scroll_to_bottom () {
  print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll to Bottom / Shortcut: Ctrl-Shift-End")
}

# ***

# Ensure that what you've selected stays selected as you type a command.
iterm2_customize_advanced_pasteboard_pressing_a_key_will_remove_the_selection_no () {
  echo "iTerm2: Advanced > Pasteboard > Pressing a key will remove the selection: No"
  defaults write com.googlecode.iterm2 TypingClearsSelection -bool false
}

# Be like Gnome terminal, and copy verbotim whatever is selected.
iterm2_customize_advanced_pasteboard_trim_whitespace_when_copying_to_pasteboard_no () {
  echo "iTerm2: Advanced > Pasteboard > Trim whitespace when copying to pasteboard: No"
  defaults write com.googlecode.iterm2 TrimWhitespaceOnCopy -bool false
}

# ***

# When pasting a lot of text to the terminal, iTerm will insert a newline unexpectedly
# at some point, and then what you're pasting will be misinterpreted. (And seems to
# be a race condition, because newline does not always appear at the same point in a
# paste).
# REFER:
#   https://apple.stackexchange.com/questions/226096/increase-amount-of-text-copied-in-iterm2
#   https://iterm2.com/documentation-hidden-settings.html
#   - From the doc:
#
#     Pastes (both regular and slow) are done by splitting the text to paste into chunks.
#     There is a delay between the transmission of each chunk.
#     To change the speed that "paste" pastes at:
#
#       defaults write com.googlecode.iterm2 QuickPasteBytesPerCall -int 1024
#       defaults write com.googlecode.iterm2 QuickPasteDelayBetweenCalls -float 0.01
#
iterm2_customize_increase_paste_buffer_size () {
  # None of these exist by default:
  #  $ defaults read com.googlecode.iterm2 QuickPasteBytesPerCall
  #  $ defaults read com.googlecode.iterm2 QuickPasteDelayBetweenCalls
  #  $ defaults read com.googlecode.iterm2 SlowPasteBytesPerCall
  #  $ defaults read com.googlecode.iterm2 SlowPasteDelayBetweenCalls

  # ISOFF/2024-04-16: Wait until you sense an issue with default
  # paste "speed", then fiddle with these values (and maybe see
  # if you can determine roughly what the defaults are (or search
  # the iTerm2 source for the answer)).
  if true; then
    print_at_end+=("🔳 iTerm2: Preferences: Keys: Key Bindings: + (Add): Action: Scroll to Top / Shortcut: Ctrl-Shift-Home")
  else
    # FIXME: Given this doesn't exist at first, what's the default BytesPerCall?
    echo "iTerm2: Increase paste buffer size"
    defaults write com.googlecode.iterm2 QuickPasteBytesPerCall -int 32

    # FIXME: Given this doesn't exist at first, what's the default DelayBetweenCalls?
    echo "iTerm2: Increase paste buffer size"
    defaults write com.googlecode.iterm2 QuickPasteDelayBetweenCalls -float 0.05

    # FIXME: killall iTerm(2)... well, tell user, don't want to zap their terms
  fi
}

# ***

# Give iTerm2 permissions to access the trash, e.g., `ls ~/.Trash`.
iterm2_customize_permission_full_disk_access () {
  print_at_end+=("🔳 iTerm2: System Settings... > Privacy & Security: Privacy: Full Disk Access: ✓ iTerm2.app")
  # Might as well, long as we're here...
  print_at_end+=("🔳 iTerm2: System Settings... > Privacy & Security: Privacy: Full Disk Access: ✓ Terminal.app")
}

# ***

# Basic Homefries:
#   print_at_end+=("   /bin/bash -c 'eval \"\$(/opt/homebrew/bin/brew shellenv)\" && /bin/bash")
# Homefries with loading dots, which might be nice because Homebrew is so slow to load Homefries!
#   print_at_end+=("   /bin/bash -c 'eval \"\$(/opt/homebrew/bin/brew shellenv)\" && /bin/bash -c 'HOMEFRIES_LOADINGDOTS=true /bin/bash")
iterm2_customize_profiles_general_command () {
  # ISOFF/2024-04-16: Previously, iTerm2 profile would load Homebrew.
  # But nowadays, the Bashrc script does it (specifically, DepoXy's
  # brewskies.sh, which is wired into Homefries (2 separate projects)).
  # - Also, DepoXy calls `chsh` to set `/bin/bash` as default shell
  #   (still 3.2.57(1)), as running Homebrew bash as the login shell
  #   can be or at least at one time was annoyingly sluggish at times.
  false && (
    # WRONG: This mostly works, but you'll see $BASH_VERSION="3.2.57(1)-release" (or whatever)
    #   print_at_end+=("   /bin/bash -c 'eval \"\$(/opt/homebrew/bin/brew shellenv)\" && /bin/bash")
    # CPYST: /opt/homebrew/bin/bash -c 'eval "$(/opt/homebrew/bin/brew shellenv)" && /opt/homebrew/bin/bash
    print_at_end+=("\
🔳 iTerm2: Preferences: Profiles: General: Default Profile:
   - Command: /opt/homebrew/bin/bash -c 'eval \"\$(/opt/homebrew/bin/brew shellenv)\" && /opt/homebrew/bin/bash")
 )
}

iterm2_customize_profiles_add_profile_bash_5x () {
  print_at_end+=("\
🔳 iTerm2: Preferences: Profiles: General: + New Profile: Name: Bash 5.x
   - Command: /opt/homebrew/bin/bash")
}

iterm2_customize_profiles_add_profile_norc_3x () {
  print_at_end+=("\
🔳 iTerm2: Preferences: Profiles: General: + New Profile: Name: NORC-3.x
   - Command: /bin/bash --noprofile --norc")
}

iterm2_customize_profiles_add_profile_norc_5x () {
  # CPYST: eval "$(/opt/homebrew/bin/brew shellenv)"
  print_at_end+=("\
🔳 iTerm2: Preferences: Profiles: General: + New Profile: Name: NORC-5.x
   - Command: /opt/homebrew/bin/bash --noprofile --norc
   - Send text at start: eval \"\$(/opt/homebrew/bin/brew shellenv)\"'

   HINT: If you make changes to the Default profile, you should delete
         the other profiles and recreate them fresh from the default")
}

iterm2_customize_profiles_add_profile_norc_5x_lite () {
  print_at_end+=("\
🔳 iTerm2: Preferences: Profiles: General: + New Profile: Name: NORC-5.x--no-HB
   - Command: /opt/homebrew/bin/bash --noprofile --norc")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

macvim_customize () {
  macvim_customize_general_after_last_window_closes_quit_macvim
}

# TRYME: How does this setting affect windows from another --servername?
macvim_customize_general_after_last_window_closes_quit_macvim () {
  echo "MacVim: Settings...: General > After last window closes > Keep MacVim Running → ✓ Quit MacVim"
  defaults write org.vim.MacVim MMLastWindowClosedBehavior -int 2
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Other options:
# - Editor > Display > ✓ Show whitespace
#   - ... "/org/gnome/meld/enable-space-drawer" -int 1
#   - Specifically, shows non-diff whitespace (dots and CR icons).
#   - Note that I see whitespace dots and CR icons in diff highlights,
#     and I am unable to disable this (which I find distracting).
# - Editor > Display > ✓ Prefer dark theme
#   - Doesn't seem to change anything
# - Editor > Display > ✓ Use syntax highlighting
#   - ... "/org/gnome/meld/highlight-syntax" -int 1

meld_customize () {
  meld_customize_disable_use_the_system_fixed_width_font
  meld_customize_editor_font
  meld_customize_tab_width
  meld_customize_insert_spaces_instead_of_tabs
  meld_customize_highlight_current_line
  meld_customize_show_line_numbers
  meld_customize_syntax_highlighting_color_scheme

  meld_customize_filename_filters
}

# On macOS Sonoma 14.4.1, this setting already disabled.
meld_customize_disable_use_the_system_fixed_width_font () {
  echo "Meld: Settings...: Editor > Font > ✗ Use the system fixed width font"
  defaults write org.gnome.meld /org/gnome/meld/use-system-font -int 0
}

# On macOS Sonoma 14.4.1, this setting already Hack (but seems weird,
# 'cause I don't remember changing anything manually; but maybe I did?).
# - Note that DepoXy on @Linux uses Hack 10.
meld_customize_editor_font () {
  echo "Meld: Settings...: Editor > Font > Editor font: Hack Nerd Font Regular 14"
  defaults write org.gnome.meld /org/gnome/meld/custom-font "Hack Nerd Font 14"
}

meld_customize_tab_width () {
  echo "Meld: Settings...: Editor > Display > Tab width: 4"
  defaults write org.gnome.meld /org/gnome/meld/indent-width -int 4
}

meld_customize_insert_spaces_instead_of_tabs () {
  echo "Meld: Settings...: Editor > Display > ✓ Insert spaces instead of tabs"
  defaults write org.gnome.meld /org/gnome/meld/insert-spaces-instead-of-tabs -int 1
}

meld_customize_highlight_current_line () {
  echo "Meld: Settings...: Editor > Display > ✓ Highlight current line"
  defaults write org.gnome.meld /org/gnome/meld/highlight-current-line -int 1
}

meld_customize_show_line_numbers () {
  echo "Meld: Settings...: Editor > Display > ✓ Show line numbers"
  defaults write org.gnome.meld /org/gnome/meld/show-line-numbers -int 1
}

# The dark themes don't use a bright enough foreground font, so I prefer one
# of the 2 light themes, "Kate". The other light theme is Solarized Light,
# which uses a yellowish background. See also Classic, Classic (Meld), and
# Tango, which all look the same, blue diff highlights on dark gray bg with
# a not-quite-white-enough foreground color. Cobalt, as its name indicates,
# uses a dark blue bg, less dark blue highlight, and whiter foreground.
# Meld dark scheme aka Solarized Dark is real hard to read, aqua bg and med.
# gray fg. Finally, Oblivion is an all-around gray theme w/ blue highlights.
meld_customize_syntax_highlighting_color_scheme () {
  echo "Meld: Settings...: Editor > Display > Syntax highlighting color scheme: Kate"
  defaults write org.gnome.meld /org/gnome/meld/style-scheme "kate"
}

# ***

# DUNNO/2024-04-24: Not sure how Meld stores Filename filters, but from the
# looks of what's in it's plist, it's not there (or at least what's there
# is abbreviated):
#
#   "/org/gnome/meld/filename-filters" =     (
#       {length = 51, bytes = 0x28274261 636b7570 73272c20 74727565 ... 6b2c7377 707d2729 },
#       {length = 94, bytes = 0x28274f53 2d737065 63696669 63206d65 ... 6f702e69 6e692729 },
#       {length = 102, bytes = 0x28275665 7273696f 6e20436f 6e74726f ... 6e202e6f 73632729 },
#       {length = 55, bytes = 0x28274269 6e617269 6573272c 20747275 ... 6c2c6578 657d2729 },
#       {length = 72, bytes = 0x28274d65 64696127 2c206661 6c73652c ... 662c7870 6d7d2729 },
#       {length = 65, bytes = 0x28275079 74686f6e 20427569 6c64272c ... 746d6c63 6f762729 },
#       {length = 66, bytes = 0x28275472 75737420 4d652120 4349272c ... 6d652e6c 6f672729 },
#       {length = 65, bytes = 0x28275079 74686f6e 20627974 65636f64 ... 672d696e 666f2729 },
#       {length = 22, bytes = 0x282774616773272c20747275652c2027746167732729},
#       {length = 45, bytes = 0x28275079 74686f6e 20434927 2c207472 ... 67652e78 6d6c2729 },
#       {length = 32, bytes = 0x28274e6f 64654a53 272c2074 7275652c ... 6f64756c 65732729 },
#       {length = 47, bytes = 0x28275079 74686f6e 20766972 7475616c ... 2e76656e 762a2729 },
#       {length = 33, bytes = 0x28274465 76656c6f 70657220 63727566 ... 20275442 442a2729 }
#   );
#
# - PHAPS: Perhaps it's this binary file:
#
#   ~/Library/Preferences/org.gnome.meld.plist

meld_customize_filename_filters () {
  print_at_end+=("\
🔳 Meld: Settings: File Filters: Filename filters: (Press +):
   - Developer cruft: TBD*
   - NodeJS: node_modules
   - Python Build: .make.out *.mo .tox _build dist htmlcov
   - Python bytecode: __pycache__ .pytest_cache *.egg-info
   - Python CI: .coverage coverage.xml
   - Python virtualenv: .editable .venv*
   - tags: tags
   - Trust Me! CI: .trustme.kill .trustme.lock .trustme.log
  ")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

outlook_customize () {
  outlook_customize_notifications
  outlook_customize_style
}

outlook_customize_notifications () {
  print_at_end+=("🔳 Outlook Mail (via Web): Settings: ✓ Desktop notifications")
  print_at_end+=("🔳 Outlook Calendar (via Web): Settings: ✓ Desktop notifications")
}

outlook_customize_style () {
  print_at_end+=("🔳 Outlook Mail (via Web): Settings: ? Dark mode [not the best impl]")
  print_at_end+=("🔳 Outlook Calendar (via Web): Settings: ? Dark mode [not the best impl]")
  print_at_end+=("🔳 Outlook Calendar (via Web): Settings: ? Bold event colors [pairs well with Dark mode?]")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

slack_customize () {
  slack_customize_notifications_sound_and_appearance

  slack_customize_find_and_group_channels
}

slack_customize_notifications_sound_and_appearance () {
  print_at_end+=("🔳 Slack: Preferences: Notifications: Sound & appearance: Notification sound (messages): *Hummus*")
  print_at_end+=("🔳 Slack: Preferences: Notifications: Sound & appearance: Notification sound (huddles): *Here you go*")
}

slack_customize_find_and_group_channels () {
  print_at_end+=("🔳 Slack: Look for Channels to join: Channels > + Add Channels > Browse Channels > Sort: Most members")
  print_at_end+=("🔳 Slack: Group Channels and DMs by Importance: Channels > ⋮ > Create a section")
  print_at_end+=("- E.g., “🔖 Priority”, “[Dr. Evil] Devops & Corp”, “💤 Irregular DMs”, “[Proj logo] <Work project>”, “🔩 Tech”, “🌺 Social”")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

dbeaver_customize () {
  dbeaver_customize_text_editors_word_wrap
}

dbeaver_customize_text_editors_word_wrap () {
  print_at_end+=("🔳 DBeaver: Window > Preferences > Editors > Text Editors: ✓ *Enable word wrap when opening an editor* > Apply and Close")
}

# Keyboard Shortcuts config is a hot mess! Or at least somewhat opaque,
# in that the entries are keyed and valued by integers, so it's not
# obvious what does what without just observing changes in the plist.
# REFER:
#   http://krypted.com/mac-os-x/defaults-symbolichotkeys/
#   https://github.com/diimdeep/dotfiles/blob/master/osx/configure/hotkeys.sh

# Note that I've see two different approaches for writing keys.
# - The `defaults read` shows well-formatted text
#
# - You could write such a key with XML, e.g.,
#
#     defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 124 \
#       "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>26</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"
#
#   THNKS: https://apple.stackexchange.com/questions/405937/
#     how-can-i-enable-keyboard-shortcut-preference-after-modifying-it-through-defaul
#
# - Another option I saw is more concise, using what looks like JSON, e.g.,
#
#     defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 73 \
#       "{enabled = 0; value = { parameters = (65535, 53, 1048576); type = 'standard'; }; }"
#
#   THNKS: https://krypted.com/mac-os-x/defaults-symbolichotkeys/ 
#
# FAILD: I tried the shorter command version, but it didn't work.
# - The `defaults read` output looked fine, but neither `/.../activateSettings -u`
#   nor a reboot caused them to take effect. Meanwhile, System Preferences still
#   showed F11, and F11 still Show(ed) Desktop.
# - But using the XML format, a `/.../activateSettings -u` works great, the
#   binding takes effect immediately, and open System Preferences and you'll
#   see the key binding is updated, too.
# - Specifically, this did not work for me:
#     # Doesn't work!
#     defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 36 \
#       "{ enabled = 1; value = { parameters = (100, 2, 786432); type = 'standard'; }; }"
#     defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 37 \
#       "{ enabled = 1; value = { parameters = (100, 2, 917504); type = 'standard'; }; }"
#     # One person online suggested a `defaults read` was necessary after writing.
#     defaults read com.apple.symbolichotkeys.plist > /dev/null &&
#     /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
#     # Another person(s) said to reboot, but that didn't work, either.
# - Thankfully (phew! because I don't want to have to do this manually!),
#   the XML varierty works!

# BWARE: I didn't see the com.apple.symbolichotkeys settings populated until
# *after* I opened System Preferences and viewed the Keyboard Shortcuts.
# - BWARE: Obviously, this won't be an issue for me anymore, but it might
#          be a problem when setting up a fresh Mac again.

shortcuts_customize_macos () {
  local rewire_shortcuts=false

  # The function order and naming reflects what you see in System Preferences > Keyboard > Shortcuts.

  shortcuts_launchpad_ampersand_dock_remap

  shortcuts_display_remap

  shortcuts_mission_control_remap

  shortcuts_keyboard_remap

  shortcuts_screenshots_remap

  shortcuts_services_remap

  shortcuts_spotlight_remap

  shortcuts_accessibility_remap

  shortcuts_app_shortcuts_remap

  ${rewire_shortcuts} &&
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
}

# ***

shortcuts_launchpad_ampersand_dock_remap () {
  # Nothing to change here:
  #
  #   ✓ Turn Dock Hiding On/Off: Opt-Cmd-D
  #   ✗ Show Launchpad
  :
}

# ***

shortcuts_display_remap () {
  # Nothing to change here, and neither the MacBook keyboard
  # nor my (loves it!) Logi Ergo K860 goes above F12 (which
  # is one more than Spinal Tap's These-go-to-eleven):
  #
  #   ✓ Decrease display brightness: F14
  #   ✓ Increase display brightness: F15
  :
}

# ***

shortcuts_mission_control_remap () {
  # ✓ Mission Control: I'd swear this was F12 until I hit *Restore Defaults*,
  #                    and then it changed to ^↑. (Same with another setting,
  #                    don't remember which now, but I feel like, well, maybe
  #                    my client set some non-standard defauts, who knows.
  # ✓ Mission Control: F12 or ^↑ → Ctrl-Opt-↑
  shortcuts_mission_control_remap_mission_control
  # ✗ Show Notification Center: Leave (Unset)
  # ✗ Turn Do Not Disturb On/Off: Leave (Unset)
  # ✓ Application windows: ^↓ → Ctrl-Opt-↓
  shortcuts_mission_control_remap_application_windows
  # ✓ Show Desktop: F11 → Ctrl+Alt+d
  #   - Note that Rectangle uses a conflicting Ctrl-Alt-d mapping for its "First Third"
  #     shortcut, so this script tackles Rectangle remaps before remapping macOS Shortcuts.
  shortcuts_mission_control_remap_show_desktop
  # ✓ Mission Control: Move left a space: ^← → Ctrl-Opt-←
  shortcuts_mission_control_remap_move_left_a_space
  # ✓ Mission Control: Move right a space: ^→ → Ctrl-Opt-→
  shortcuts_mission_control_remap_move_right_a_space
  # ✓ Mission Control: Switch to Desktop 1: ^1 → (Unset)
  shortcuts_mission_control_remap_switch_to_desktop
  # ✓ Quick Note: 🌐 q aka Fn+q → (Unset)
  shortcuts_mission_control_remap_quick_note

  rewire_shortcuts=true
}

shortcuts_mission_control_remap_mission_control () {
  echo "Keyboard Shortcuts: Mission Control: Mission Control: ^↑ → ^⌥ ↑"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>126</integer><integer>11272192</integer></array><key>type</key><string>standard</string></dict></dict>"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 34 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>126</integer><integer>11403264</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

shortcuts_mission_control_remap_application_windows () {
  echo "Keyboard Shortcuts: Mission Control: Application windows: ^↓ → ^⌥ ↓"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 33 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>125</integer><integer>11272192</integer></array><key>type</key><string>standard</string></dict></dict>"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 35 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>125</integer><integer>11403264</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

shortcuts_mission_control_remap_show_desktop () {
  # My original instinct was to just disable Show Desktop:
  false && (
    echo "Keyboard Shortcuts: Mission Control: Show Desktop: F11 → (Unset)"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
      -dict-add 36 "<dict><key>enabled</key><false/></dict>"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
      -dict-add 37 "<dict><key>enabled</key><false/></dict>"
  )

  # But then I remember that I like dressing up my Mac as Linux.
  echo "Keyboard Shortcuts: Mission Control: Show Desktop: F11 → Ctrl+Alt+d"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 36 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>100</integer><integer>2</integer><integer>786432</integer></array><key>type</key><string>standard</string></dict></dict>"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 37 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>100</integer><integer>2</integer><integer>917504</integer></array><key>type</key><string>standard</string></dict></dict>"

  # For posterity, here's the original setting.
  false && (
    echo "Keyboard Shortcuts: Mission Control: Show Desktop: ?? → F11 (Reset)"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 36 \
      "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>103</integer><integer>8388608</integer></array><key>type</key><string>standard</string></dict></dict>"
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 37 \
      "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>103</integer><integer>8519680</integer></array><key>type</key><string>standard</string></dict></dict>"
  )

  rewire_shortcuts=true
}

shortcuts_mission_control_remap_move_left_a_space () {
  echo "Keyboard Shortcuts: Mission Control: Move left a space: ^← → ^⌥ ←"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>123</integer><integer>11272192</integer></array><key>type</key><string>standard</string></dict></dict>"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>123</integer><integer>11403264</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

shortcuts_mission_control_remap_move_right_a_space () {
  echo "Keyboard Shortcuts: Mission Control: Move right a space: ^→ → ^⌥ →"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>124</integer><integer>11272192</integer></array><key>type</key><string>standard</string></dict></dict>"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>124</integer><integer>11403264</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

# I rarely use multiple desktops.
shortcuts_mission_control_remap_switch_to_desktop () {
  echo "Keyboard Shortcuts: Mission Control: Switch to Desktop 1: ^1 → (Unset)"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 118 \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>18</integer><integer>262144</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

shortcuts_mission_control_remap_quick_note () {
  echo "Keyboard Shortcuts: Mission Control: Quick Note: 🌐 q → (Unset)"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 190 \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>113</integer><integer>12</integer><integer>8388608</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

# ***

shortcuts_keyboard_remap () {
  # ✓ Keyboard: Change the way Tab moves focus: ^F7 → (Leave it)
  # ✓ Keyboard: Turn keyboard access on or off: ^F1 → (Leave it)
  # ✓ Keyboard: Move focus to the menu bar: ^F2 → (Leave it)
  # ✓ Keyboard: Move focus to the Dock: ^F3 → (Leave it)
  # ✓ Keyboard: Move focus to active of next window: ^F4 → (Leave it)
  # ✓ Keyboard: Move focus to the window toolbar: ^F5 → (Leave it)
  # ✓ Keyboard: Move focus to the floating window: ^F6 → (Leave it)
  # ✓ Keyboard: Move focus to next window: ⌘ ` → (Unset)
  shortcuts_keyboard_remap_move_focus_to_next_window
  # ✓ Keyboard: Move focus to status menus: ^F8 → (Leave it)
}

# AltTab maps Alt-` to switching between windows within an application,
# and I've got a Karabiner-Elements Cmd-` shortcut to bring GVim front,
# both of which seem to override this ⌘ ` mapping, so disable it.
shortcuts_keyboard_remap_move_focus_to_next_window () {
  echo "Keyboard Shortcuts: Keyboard: Move focus to next window: ⌘ \` → (Unset)"
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 27 \
    "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>96</integer><integer>50</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"

  rewire_shortcuts=true
}

# ***

shortcuts_screenshots_remap () {
  # ✓ Screenshots: Save picture of screen as a file: ⇧⌘ 3
  # ✓ Screenshots: Copy picture of screen to the clipboard: ^⇧⌘ 3
  # ✓ Screenshots: Save picture of selected area as a file: ⇧⌘ 4
  # ✓ Screenshots: Copy picture of selected area to the clipboard: ^⇧⌘ 4
  #   - This is actual displayed "Copy picture of se...ea to the clipboard"
  #     but there's no way to expand the window or to see the full name, so
  #     I only assume it's "Copy picture of selected area to the clipboard".
  # ✓ Screenshots: Screenshot and recording options: ⇧⌘ 5
  :
}

# ***

# Note there are a bunch of Services shortcuts that are (✓) enabled but have no mapping ("none").
shortcuts_services_remap () {
  # ✓ Services: Pictures: Set Desktop Picture: (none)
  # ✓ Services: Internet: Add to Reading List: (none)
  # ✓ Services: Internet: Open URL: (none)
  # ✓ Services: Messaging: New Email To Address: (none)
  # ✓ Services: Messaging: New Email With Selection: (none)
  # ✗ Services: Files and Folders: Open Selected File in TextEdit: (none)
  # ✓ Services: Files and Folders: New Terminal at Folder: (none)
  # ✓ Services: Files and Folders: New Terminal Tab at Folder: (none)
  # ✓ Services: Files and Folders: Encode Selected Audio Files: (none)
  # ✓ Services: Files and Folders: Encode Selected Video Files: (none)
  # ✓ Services: Files and Folders: Folder Actions Setup...: (none)
  # ✓ Services: Files and Folders: New iTerm2 Tab Here: (none)
  # ✓ Services: Files and Folders: New iTerm2 Window Here: (none)
  # ✗ Services: Files and Folders: Send File To Bluetooth Device: ⇧⌘ B
  # ✓ Services: Searching: Look Up in Dictionary: (none)
  # ✓ Services: Searching: Search With Google: ⇧⌘ L → (✗ Off) [Does nothing for me anyway]
  shortcuts_services_remap_searching_search_with_google_unmap
  # ✗ Services: Searching: Spotlight: ⇧⌘ L
  # ✓ Services: Text: Add to Music as a Spoken Track: (none)
  # ✓ Services: Text: Convert Text to Full Width: (none)
  # ✓ Services: Text: Convert Text to Half Width: (none)
  # ✓ Services: Text: Convert Text to...implified Chinese: ^⌥ ⇧⌘ C → (✗ Off)
  shortcuts_services_remap_text_convert_to_simplified_chinese_unmap
  # ✓ Services: Text: Convert Text to...aditional Chinese: ^⇧⌘ C → (✗ Off)
  shortcuts_services_remap_text_convert_to_traditional_chinese_unmap
  # ✗ Services: Text: Create Collection From Text: (none)
  # ✗ Services: Text: Create Font Library From Text: (none)
  # ✗ Services: Text: Display Font Information: (none)
  # ✓ Services: Text: Make New Sticky Note: ⇧⌘ Y → (✗ Off) [Does nothing for me anyway]
  shortcuts_services_remap_text_make_new_sticky_note_unmap
  # ✓ Services: Text: New MacVim B...er With Selection: (none)
  # ✗ Services: Text: New TextEdit Wi...aining Selection: (none)
  # ✓ Services: Text: Open: (none)
  # ✓ Services: Text: Show in Finder: (none)
  # ✓ Services: Text: Show Info in Finder: (none)
  # ✓ Services: Text: Open man Page in terminal: ⇧⌘ M → (✗ Off)
  shortcuts_services_remap_text_open_man_page_in_terminal_unmap
  # ✓ Services: Text: Open man Page in terminal: ⇧⌘ M → (✗ Off)
  shortcuts_services_remap_text_search_man_pag_ndex_in_terminal_unmap
  # ✓ Services: Text: Show Map: (none)
  # ✗ Services: Text: Summarize: (none)
  # ✗ Services: Development: Create Service: (none)
  # ✗ Services: Development: Create Workflow: (none)
  # ✗ Services: Development: Get Result of AppleScript: ⌘ *
  # ✗ Services: Development: Make New AppleScript: (none)
  # ✗ Services: Development: Run as AppleScript: (none)
  # ✓ Services: General: New MacVim Buffer Here: (none)

  # Apparently all the settings I touched live under one domain key.
  shortcuts_services_remap_pbs_unmap_all
}

shortcuts_services_remap_searching_search_with_google_unmap () {
  # - If you re-enable the option, you'll see NSServicesStatus = { }, i.e., it
  #   removes (zeroes?) the dictionary.
  # - It doesn't seem `/System/.../activateSettings -u` works: I closed System Preferences,
  #   ran this `defaults write`, ran `activateSettings -u`, reopened System Preferences,
  #   and the option was still selected. I then deselected "Search With Google" and
  #   ran a defaults dump and compared, and nothing changed! So I think this defaults-write
  #   works, but I'm not sure the `activateSettings -u` work. (Note also the weird domain, `pbs`!
  #   Why doesn't Apple conform to its stated domain format, aka reverse URL, such nonconformist.)
  # - Oh, hey now, Apple also packs multiple settings into the same key-value.
  #   Here's the setting if you start from defaults and then disable Search With Google:
  #     defaults write pbs NSServicesStatus '{
  #       "com.apple.Safari - Search With %WebSearchProvider@ - searchWithWebSearchProvider" = {
  #         "enabled_context_menu" = 0;
  #         "enabled_services_menu" = 0;
  #         "presentation_modes" = {
  #           ContextMenu = 0;
  #           ServicesMenu = 0;
  #         };
  #       };
  #     }'
  #   But then if you disable "Convert Text to...implified Chinese", you'll see
  #   a second dictionary added to the same key-value. Oy. So we'll tackle all
  #   these together in a separate function.
  echo "Keyboard Shortcuts: Services: Searching: Search With Google: ⇧⌘ L → (✗ Off) [Does nothing for me anyway]"
}

shortcuts_services_remap_text_convert_to_simplified_chinese_unmap () {
  # See note above, for the function:
  #   shortcuts_services_remap_searching_search_with_google_unmap,
  # Apparently a number of settings are combined in the same key-value.
  # See the combined unmapping below, in the function:
  #   shortcuts_services_remap_pbs_unmap_all
  echo "Keyboard Shortcuts: Services: Text: Convert Text from Traditional to Simplified Chinese: ^⌥ ⇧⌘ C → (✗ Off)"
}

shortcuts_services_remap_text_convert_to_traditional_chinese_unmap () {
  # See previous comments, and shortcuts_services_remap_pbs_unmap_all.
  echo "Keyboard Shortcuts: Services: Text: Convert Text from Simplified to Traditional Chinese: ^⌥ ⇧⌘ C → (✗ Off)"
}

shortcuts_services_remap_text_make_new_sticky_note_unmap () {
  # See previous comments, and shortcuts_services_remap_pbs_unmap_all.
  echo "Keyboard Shortcuts: Services: Text: Make New Sticky Note: ⇧⌘ Y → (✗ Off)"

}

shortcuts_services_remap_text_open_man_page_in_terminal_unmap () {
  # See previous comments, and shortcuts_services_remap_pbs_unmap_all.
  echo "Keyboard Shortcuts: Services: Text: Open man Page in terminal: ⇧⌘ M → (✗ Off)"
}

shortcuts_services_remap_text_search_man_pag_ndex_in_terminal_unmap () {
  # See previous comments, and shortcuts_services_remap_pbs_unmap_all.
  echo "Keyboard Shortcuts: Services: Text: Search map Page...ndex in Terminal: ⇧⌘ A → ✗ Off)"
}

shortcuts_services_remap_pbs_unmap_all () {
  # 2022-10-16: Whatever. This `defaults write` seems to have the opposite effect:
  # When I run this script, it seems like all these options are enabled again...
  # - So we'll just tell user to do this manually.
  print_at_end+=("\
🔳 System Settings: Keyboard: Keyboard Shortcuts...: Services: Disable all active items that are mapped:
   - Searching: Search With Google: ⇧⌘ L → (✗ Off) [Does nothing for me anyway]
   - Text: Convert Text to Simplified Chinese: ^⌥ ⇧⌘ C → (✗ Off)
   - Text: Convert Text to Traditional Chinese: ^⇧⌘ C → (✗ Off)
   - Text: Make New Sticky Note: ⇧⌘ Y → (✗ Off)
   - Text: Open man Page in terminal: ⇧⌘ M → (✗ Off)
   - Text: Search map Page Index in Terminal: ⇧⌘ A → ✗ Off)")

  # The following mapping apparently re-enables all those settings.
  # Or at least they show up re-enabled in
  #   System Preferences > Keyboard > Shortcuts > Services
  # after running the following `defaults write`...
  # though I then manually disabled each of the options and
  # re-ran `defaults write`, and the `pbs` section was unchanged.
  # - So very confused.
  # In any case, not a big deal to have the user do this manually,
  # and then we avoid having Keyboard Shortcuts appear to show these
  # re-enabled, whether or not that's the case.
  return 0

  defaults write pbs NSServicesStatus '{
    "com.apple.ChineseTextConverterService - Convert Text from Simplified to Traditional Chinese - convertTextToTraditionalChinese" = {
      "enabled_context_menu" = 0;
      "enabled_services_menu" = 0;
      "presentation_modes" = {
        ContextMenu = 0;
        ServicesMenu = 0;
      };
    };
    "com.apple.ChineseTextConverterService - Convert Text from Traditional to Simplified Chinese - convertTextToSimplifiedChinese" = {
      "enabled_context_menu" = 0;
      "enabled_services_menu" = 0;
      "presentation_modes" = {
        ContextMenu = 0;
        ServicesMenu = 0;
      };
    };
    "com.apple.Safari - Search With %WebSearchProvider@ - searchWithWebSearchProvider" = {
      "enabled_context_menu" = 0;
      "enabled_services_menu" = 0;
      "presentation_modes" = {
        ContextMenu = 0;
        ServicesMenu = 0;
      };
    };
    "com.apple.Stickies - Make Sticky - makeStickyFromTextService" = {
      "enabled_services_menu" = 0;
      "presentation_modes" = {
        ContextMenu = 0;
        ServicesMenu = 0;
      };
    };
    "com.apple.Terminal - Open man Page in Terminal - openManPage" = {
      "enabled_context_menu" = 0;
      "enabled_services_menu" = 0;
      "presentation_modes" = {
        ContextMenu = 0;
        ServicesMenu = 0;
      };
    };
    "com.apple.Terminal - Search man Page Index in Terminal - searchManPages" = {
      "enabled_context_menu" = 0;
      "enabled_services_menu" = 0;
      "presentation_modes" = {
        ContextMenu = 0;
        ServicesMenu = 0;
      };
    };
  }'
}

# ***

shortcuts_spotlight_remap () {
  # ✓ Spotlight: Show Spotlight search: ⌘ Space
  # ✓ Spotlight: Show Finder search window: ⌥ ⌘ Space
  #   - This is sorta like Alt-Cmd-F I have mapped via Karabiner-Elements
  #      to open a new Finder window, but the *Finder search window* is
  #      slightly different, and I don't have a mapping at Alt-Cmd-Space,
  #      so might as well leave it be (for now, at least, but if I want
  #      this mapping for something else, steal it later, I've never used
  #      the *Show Finder search window* feature.
  :
}

# ***

shortcuts_accessibility_remap () {
  # ✗ Accessibility: Zoom: Turn zoom on or off: ⌥ ⌘ 8
  # ✗ Accessibility: Zoom: Turn image smoothing on or off: ⌥ ⌘ \
  # ✗ Accessibility: Zoom: Zoom out: ⌥ ⌘ -
  # ✗ Accessibility: Zoom: Zoom on: ⌥ ⌘ =
  # ✗ Accessibility: Zoom: Turn focus following on or off: (none)
  # ✗ Accessibility: Contrast: Increase contrast: ⌥ ⌘ .
  # ✗ Accessibility: Contrast: Decrease contrast: ⌥ ⌘ ,
  # ✗ Accessibility: Invert colors: ^⌥ ⌘ 8
  # ✓ Accessibility: Turn VoiceOver on or off: ⌘ F5 → (✗ Off, or maybe I don't care)
  # ✓ Accessibility: Show Accessibility controls: ⌥ ⌘ F5 → (✗ Off, or maybe I don't care)
  #   - Huh, I demoed ⌘ F5 and ⌥ ⌘ F5, and two new domains appeared:
  #       com.apple.speech.voice.prefs
  #       com.apple.VoiceOver4.local
  #     Also, the com.apple.Accessibility domain showed key-value changes:
  #       AccessibilityEnabled = 1; (new)
  #       ApplicationAccessibilityEnabled = 1; (was 0)
  #       VoiceOverTouchEnabled = 1; (was 0)
  :
}

# ***

# Keyboard > Shortcuts > App Shortcuts is where you customize each
# application's menu item shortcuts.
# - On a fresh macOS install, it contains a single entry, *Show Help menu*.
# - For custom application shortcuts we add elsewhere in this script,
#   search:
#
#     *shortcuts_customize*     # To find all individual settings' echoes
#
#     NSUserKeyEquivalents      # To find each app's set of new shortcuts
#
shortcuts_app_shortcuts_remap () {
  # ✓ App Shortcuts: All Applications: Show Help menu: ⇧⌘ / → (✗ Off, or maybe I don't care)
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# I use Cmd-t to open new browser window (Cmd-t: Chromium, Cmd-y: Chrome).
app_shortcuts_reclaim_cmd_t () {
  # Because each app's App Shortcuts are recorded in a single key-value,
  # NSUserKeyEquivalents, we won't remap all the Cmd-T shortcuts from the
  # different apps here, but will do so in their app-specific functions.
  # Just FYI. So look for the following function:
  #
  #  app_shortcuts_customize_macvim_new_tab
  #  app_shortcuts_customize_macvim_open_tab
  #
  #  app_shortcuts_customize_iterm2_new_tab
  #  app_shortcuts_customize_iterm2_show_tabs_in_fullscreen
  #
  #  app_shortcuts_customize_google_chrome_new_tab
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# DUNNO: I added MacVim.app Keyboard Shortcuts to App Shortcuts, and now
#        I see a new plist entry:
#          "com.apple.universalaccess" = {
#            "com.apple.custommenu.apps" = (
#              "com.apple.finder",
#              "org.vim.MacVim"
#            );
#            ...
#          }
#        and I had recently added Finder.app, too.
#        - Not sure I need to update this entry when running this script --
#          but I won't find out until the next time I onboard a fresh macOS.
#
# Indeed, after adding iTerm.app shortcuts:
#
#    "com.apple.universalaccess" =     {
#        ...
#        "com.apple.custommenu.apps" =         (
#            "com.apple.finder",
#            "org.vim.MacVim",
#            "com.googlecode.iterm2"
#        );

app_shortcuts_update_universalaccess () {
  echo
  echo "FIXME: Do you need to update com.apple.universalaccess for shortcuts to work?"
  echo

  # FIXME: It'd be like this, but not sure it's necessary.
  # - CPYST: And run this to grab a copy:
  #     defaults read com.apple.universalaccess com.apple.custommenu.apps
  false &&
  defaults write com.apple.universalaccess com.apple.custommenu.apps '{
    "com.apple.finder",
    "org.vim.MacVim",
    "com.googlecode.iterm2",
    "com.google.Chrome",
    "com.apple.Safari"
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++ Application NSUserKeyEquivalents settings

app_shortcuts_customize_finder () {
  app_shortcuts_customize_finder_new_finder_window
  app_shortcuts_customize_finder_new_folder
  app_shortcuts_customize_finder_new_tab
  app_shortcuts_customize_finder_open
  app_shortcuts_customize_finder_close_window
  app_shortcuts_customize_finder_rename
  app_shortcuts_customize_finder_find
  app_shortcuts_customize_finder_close_quick_look
  app_shortcuts_customize_finder_enter_full_screen

  app_shortcuts_customize_finder_all
}

app_shortcuts_customize_finder_new_finder_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: New Finder Window: Cmd-N → Ctrl-N"
}

app_shortcuts_customize_finder_new_folder () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: New Folder: Cmd-Shift-N → Ctrl-Shift-N"
}

app_shortcuts_customize_finder_new_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: New Tab: Cmd-T → Ctrl-T"
}

app_shortcuts_customize_finder_open () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: Open: Cmd-O → Ctrl-O"
}

app_shortcuts_customize_finder_close_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: Close Window: Cmd-W → Ctrl-W"
}

app_shortcuts_customize_finder_rename () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: Rename: <n/a> → F2"
}

app_shortcuts_customize_finder_find () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: Find: Cmd-F → Ctrl-F"
}

app_shortcuts_customize_finder_close_quick_look () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: Close Quick Look: Cmd-Y → Ctrl-Shift-W"
}

app_shortcuts_customize_finder_enter_full_screen () {
  echo "${CRUMB_APP_SHORTCUTS}: Finder: Enter Full Screen: Cmd-Shift-F → Ctrl-Shift-F"
}

app_shortcuts_customize_finder_all () {
  defaults write com.apple.finder NSUserKeyEquivalents '{
    "Close Quick Look" = "^$w";
    "Close Window" = "^w";
    "Enter Full Screen" = "^$f";
    Find = "^f";
    "New Finder Window" = "^n";
    "New Folder" = "^$n";
    "New Tab" = "^t";
    Open = "^o";
    Rename = "\Uf705";
  }'

  restart_finder=true
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_preview () {
  app_shortcuts_customize_preview_close_window
  app_shortcuts_customize_preview_quit_preview
  app_shortcuts_customize_preview_minimize

  app_shortcuts_customize_preview_all
}

app_shortcuts_customize_preview_close_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Preview: Close Window: Cmd-W → Ctrl-W"
}

app_shortcuts_customize_preview_quit_preview () {
  echo "${CRUMB_APP_SHORTCUTS}: Preview: Quit Preview: Cmd-Q → Ctrl-Q"
}

app_shortcuts_customize_preview_minimize () {
  echo "${CRUMB_APP_SHORTCUTS}: Preview: Minimize: Cmd-M → Cmd-N"
}

app_shortcuts_customize_preview_all () {
  defaults write com.apple.Preview NSUserKeyEquivalents '{
    "Close Window" = "^w";
    Minimize = "@n";
    "Quit Preview" = "^q";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2023-01-26: Effin Apple, seriously, why would you remove settings?
# - The com.apple.systempreferences.plist is a shell of its former self,
#   just one one setting -- { ThirdPartyCount = 0; } -- and not the dozens
#   it had before, including the usual NSUserKeyEquivalents.
#
# - I grepped _all_defaults.plist but did not locate either the binding I
#   manually updated (renamed from "Quit System Preferences"), nor a few of
#   the old settings I looked for (e.g., DisableAutoLoginButtonIsHidden).
#
# Ugh, Apple, just doin' your own thing all the time for the sake of
# changing things when nothing's broken and you're just creating work
# for the rest of us who try to automate our environments atop yours.
false && (
  # This worked in macOS 12/Monteray, but no longer in macOS 13/(Jesse) Ventura.
  app_shortcuts_customize_system_preferences () {
    app_shortcuts_customize_system_preferences_quit_system_preferences

    app_shortcuts_customize_system_preferences_all
  }

  app_shortcuts_customize_system_preferences_quit_system_preferences () {
    echo "${CRUMB_APP_SHORTCUTS}: System Settings.app: Quit System Settings: Cmd-Q → Ctrl-Q"
  }

  app_shortcuts_customize_system_preferences_all () {
    defaults write com.apple.systempreferences NSUserKeyEquivalents '{
      "Quit System Settings" = "^q";
    }'

    # INERT: User needs to restart System Preferences to realize the change:
    #
    #  restart_system_preferences=true
  }
)

app_shortcuts_customize_system_preferences () {
  # Requires restarting System Settings to take effect.
  print_at_end+=("🔳 ${CRUMB_APP_SHORTCUTS}: System Settings.app: “Quit System Settings”: Cmd-Q → Ctrl-Q")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_macvim () {
  app_shortcuts_customize_macvim_new_tab
  app_shortcuts_customize_macvim_open_tab
  app_shortcuts_customize_macvim_close_window
  app_shortcuts_customize_macvim_use_selection_for_find
  app_shortcuts_customize_macvim_next_error
  app_shortcuts_customize_macvim_previous_error
  app_shortcuts_customize_macvim_older_list
  app_shortcuts_customize_macvim_newer_list
  app_shortcuts_customize_macvim_edit_font_bigger
  app_shortcuts_customize_macvim_edit_font_smaller
  app_shortcuts_customize_macvim_edit_font_reset
  app_shortcuts_customize_macvim_minimize

  app_shortcuts_customize_macvim_all
}

app_shortcuts_customize_macvim_new_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: New Tab: Cmd-T → Ctrl-Opt-Cmd-T"
}

app_shortcuts_customize_macvim_open_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Open Tab...: Shift-Cmd-T → Shift-Ctrl-Opt-Cmd-T"
}

app_shortcuts_customize_macvim_close_window () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Close Window: Shift-Cmd-W → Shift-Ctrl-Opt-Cmd-W"
}

app_shortcuts_customize_macvim_use_selection_for_find () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Use Selection for Find: Cmd-E → Ctrl-Opt-Cmd-E"
}

app_shortcuts_customize_macvim_next_error () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Next Error: ^⌘ → → Ctrl-Opt-Shift-Cmd-Right"
}

app_shortcuts_customize_macvim_previous_error () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Previous Error: ^⌘ ← → Ctrl-Opt-Shift-Cmd-Left"
}

app_shortcuts_customize_macvim_older_list () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Older List: ^⌘ ↑ → Ctrl-Opt-Shift-Cmd-Up"
}

app_shortcuts_customize_macvim_newer_list () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Newer List: ^⌘ ↓ → Ctrl-Opt-Shift-Cmd-Down"
}

# ***

# MAYBE/2022-10-18: SAVVY: Cmd-0 resets the view. Care?
# - FIXME/2022-10-18: Where's the reset-zoom option?
#
# 2022-10-18: Dubs Vim maps Ctrl-- to seven-of-spines, and DepoXy
# use Ctrl-Shift-* modifiers to act on window positions, so seems
# like bigger/smaller should be similarly double-modifiered. (And
# who uses bigger/smaller often enough to justify them being a
# single modifier plus key combination? These should be "buried"
# somewhat, as in, they should be at least two modifiers plus a key.)

app_shortcuts_customize_macvim_edit_font_bigger () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Edit > Font > Bigger: ⌘ + → Ctrl-Shift-="
  # CXREF: app_shortcuts_customize_macvim_all: "Bigger"
}

app_shortcuts_customize_macvim_edit_font_smaller () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Edit > Font > Smaller: ⌘ _ → Ctrl-Shift--"
  # CXREF: app_shortcuts_customize_macvim_all: "Smaller"
}

app_shortcuts_customize_macvim_edit_font_reset () {
  : # Who knows! Doesn't appear to be an option.
}

app_shortcuts_customize_macvim_minimize () {
  echo "${CRUMB_APP_SHORTCUTS}: MacVim.app: Window > Minimize: Cmd-M → Cmd-N"
}

# ***

# - Some of these key mappings are ridulously complicated,
#   because there's not a *disable* option. So we "unmask"
#   key combinations (especially for Karabiner-Elements)
#   by assigning obtuse key cominbations to release the
#   default key mappings that we'd like to steal-repurpose.
#   - Specifically, *Next Error*, *Previous Error*, *Older List*,
#     and *Newer List* default to using Ctrl-Command-Arrow bindings,
#     which are valuable to DepoXy, and I never use those commmands
#     anyway.
# - If you make changes via System Preferences > Keyboard > Shortcuts, grab the new dict:
#     defaults read org.vim.MacVim NSUserKeyEquivalents
app_shortcuts_customize_macvim_all () {
  defaults write org.vim.MacVim NSUserKeyEquivalents '{
    Bigger = "^$=";
    "Close Window" = "@~^$w";
    Minimize = "@n";
    "New Tab" = "@~^t";
    "Newer List" = "@~^$\U2193";
    "Next Error" = "@~^$\U2192";
    "Older List" = "@~^$\U2191";
    "Open Tab..." = "@~^$t";
    "Previous Error" = "@~^$\U2190";
    Smaller = "^$-";
    "Use Selection for Find" = "@~^e";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# CXREF: iterm2_customize
app_shortcuts_customize_iterm2 () {
  app_shortcuts_customize_iterm2_new_window
  app_shortcuts_customize_iterm2_new_tab
  app_shortcuts_customize_iterm2_close
  app_shortcuts_customize_iterm2_copy
  app_shortcuts_customize_iterm2_paste
  app_shortcuts_customize_iterm2_use_selection_for_find
  app_shortcuts_customize_iterm2_show_tabs_in_fullscreen
  app_shortcuts_customize_iterm2_view_make_text_bigger
  app_shortcuts_customize_iterm2_view_make_text_smaller
  app_shortcuts_customize_iterm2_view_make_text_reset
  app_shortcuts_customize_iterm2_reset
  app_shortcuts_customize_iterm2_minimize

  app_shortcuts_customize_iterm2_all
}

app_shortcuts_customize_iterm2_new_window () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Shell > New Window: Cmd-N → Ctrl-N"
}

app_shortcuts_customize_iterm2_new_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: New Tab: Cmd-T → Ctrl-Opt-Cmd-T"
}

app_shortcuts_customize_iterm2_close () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Close: Cmd-W → Shift-Cmd-Alt-Cmd-W"
}

app_shortcuts_customize_iterm2_copy () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Copy: Cmd-C → Ctrl-Shift-C"
}

app_shortcuts_customize_iterm2_paste () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Paste: Cmd-V → Ctrl-Shift-V"
}

app_shortcuts_customize_iterm2_use_selection_for_find () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Use Selection for Find: Cmd-E → Ctrl-Opt-Cmd-E"
}

app_shortcuts_customize_iterm2_show_tabs_in_fullscreen () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Show Tabs in Fullscreen: Shift-Cmd-T → Ctrl-Opt-Shift-Cmd-T"
}

app_shortcuts_customize_iterm2_view_make_text_bigger () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: View > Make Text Bigger: Cmd-= → Ctrl-Shift-="
  # CXREF: app_shortcuts_customize_iterm2_all: "Make Text Bigger"
}

app_shortcuts_customize_iterm2_view_make_text_smaller () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: View > Make Text Smaller: Cmd-_ → Ctrl-Shift--"
  # CXREF: app_shortcuts_customize_iterm2_all: "Make Text Smaller"
}

# View > "Make Text Normal Size" reads very ableist.
app_shortcuts_customize_iterm2_view_make_text_reset () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Restore Text and Session Size aka Make Text Normal Size: Cmd-0 → Ctrl-Shift-0"
  # CXREF: app_shortcuts_customize_iterm2_all: "Make Text Normal Size"
}

app_shortcuts_customize_iterm2_reset () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Reset: Cmd-R → Ctrl-Opt-Cmd-R"
}

app_shortcuts_customize_iterm2_minimize () {
  echo "${CRUMB_APP_SHORTCUTS}: iTerm.app: Window > Minimize: Cmd-M → Cmd-N"
}

# ***

# If you make changes via System Preferences > Keyboard > Shortcuts, grab the new dict:
#   defaults read com.googlecode.iterm2 NSUserKeyEquivalents
app_shortcuts_customize_iterm2_all () {
  defaults write com.googlecode.iterm2 NSUserKeyEquivalents '{
    Close = "@~$w";
    Copy = "^$c";
    "Make Text Bigger" = "^$=";
    "Make Text Normal Size" = "^$0";
    "Make Text Smaller" = "^$-";
    Minimize = "@n";
    "New Tab" = "@~^t";
    "New Window" = "^n";
    Paste = "^$v";
    Reset = "@~^r";
    "Show Tabs in Fullscreen" = "@~^$t";
    "Use Selection for Find" = "@~^e";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 31 mappings!
app_shortcuts_customize_google_chrome () {
  app_shortcuts_customize_google_chrome_new_tab
  app_shortcuts_customize_google_chrome_new_window
  app_shortcuts_customize_google_chrome_new_incognito_window
  app_shortcuts_customize_google_chrome_reopen_closed_tab
  app_shortcuts_customize_google_chrome_open_file
  app_shortcuts_customize_google_chrome_open_location
  app_shortcuts_customize_google_chrome_close_window
  app_shortcuts_customize_google_chrome_close_tab
  app_shortcuts_customize_google_chrome_save_page_as
  app_shortcuts_customize_google_chrome_print
  app_shortcuts_customize_google_chrome_undo
  app_shortcuts_customize_google_chrome_redo
  app_shortcuts_customize_google_chrome_find
  app_shortcuts_customize_google_chrome_find_next
  app_shortcuts_customize_google_chrome_find_previous
  app_shortcuts_customize_google_chrome_use_selection_for_find
  app_shortcuts_customize_google_chrome_reload_this_page
  app_shortcuts_customize_google_chrome_force_reload_this_page
  app_shortcuts_customize_google_chrome_view_source
  app_shortcuts_customize_google_chrome_developer_tools
  app_shortcuts_customize_google_chrome_inspect_elements
  app_shortcuts_customize_google_chrome_javascript_console
  app_shortcuts_customize_google_chrome_back
  app_shortcuts_customize_google_chrome_forward
  app_shortcuts_customize_google_chrome_bookmark_manager
  app_shortcuts_customize_google_chrome_bookmark_this_tab
  app_shortcuts_customize_google_chrome_bookmark_all_tabs
  app_shortcuts_customize_google_chrome_zoom
  app_shortcuts_customize_google_chrome_quit_and_keep_windows
  app_shortcuts_customize_google_chrome_zoom_in_bigger
  app_shortcuts_customize_google_chrome_zoom_out_smaller
  app_shortcuts_customize_google_chrome_zoom_actual_size_reset
  app_shortcuts_customize_google_chrome_minimize

  app_shortcuts_customize_google_chrome_all
}

app_shortcuts_customize_google_chrome_new_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: New Tab: Cmd-T → Ctrl-T"
}

app_shortcuts_customize_google_chrome_new_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: New Window: Cmd-N → Ctrl-N"
}

app_shortcuts_customize_google_chrome_new_incognito_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: New Incognito Window: Cmd-Shift-N → Ctrl-Shift-N"
}

app_shortcuts_customize_google_chrome_reopen_closed_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Reopen Closed Tab: Cmd-Shift-T → Ctrl-Shift-T"
}

app_shortcuts_customize_google_chrome_open_file () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Open File...: Cmd-O → Ctrl-O"
}

app_shortcuts_customize_google_chrome_open_location () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Open Location...: Cmd-L → Ctrl-L"
}

app_shortcuts_customize_google_chrome_close_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Close Window: Cmd-Shift-W → Ctrl-Shift-W"
}

app_shortcuts_customize_google_chrome_close_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Close Tab: Cmd-W → Alt-W"
}

app_shortcuts_customize_google_chrome_save_page_as () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Save Page As...: Cmd-S → Ctrl-S"
}

app_shortcuts_customize_google_chrome_print () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Print...: Cmd-P → Ctrl-P"
}

app_shortcuts_customize_google_chrome_undo () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Undo: Cmd-Z → Ctrl-Z"
}

app_shortcuts_customize_google_chrome_redo () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Redo: Cmd-Shift-Z → Ctrl-Shift-Z"
}

app_shortcuts_customize_google_chrome_find () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Find...: Cmd-F → Ctrl-F"
}

app_shortcuts_customize_google_chrome_find_next () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Find Next: Cmd-G → F3"
}

app_shortcuts_customize_google_chrome_find_previous () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Find Previous: Cmd-Shift-G → Shift-F3"
}

app_shortcuts_customize_google_chrome_use_selection_for_find () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Use Selection for Find: Cmd-E → F1"
}

app_shortcuts_customize_google_chrome_reload_this_page () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Reload This Page: Cmd-R → Ctrl-R"
}

app_shortcuts_customize_google_chrome_force_reload_this_page () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Force Reload This Page: Cmd-Shift-R → Ctrl-Shift-R"
}

app_shortcuts_customize_google_chrome_view_source () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: View Source: Opt-Cmd-U → Ctrl-Shift-U"
}

app_shortcuts_customize_google_chrome_developer_tools () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Developer Tools: Opt-Cmd-I → Ctrl-Shift-I"
}

app_shortcuts_customize_google_chrome_inspect_elements () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Inspect Elements: Opt-Cmd-C → Ctrl-Shift-C"
}

app_shortcuts_customize_google_chrome_javascript_console () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: JavaScript Console: Opt-Cmd-J → Ctrl-Shift-J"
}

# FIXME: TRYME: Not sure if suppose to be Alt-L/R or Ctrl-L/R.
#        - See also KE bindings.
#        - In Linux: Alt-L/R is Back/Forward,
#          and Ctrl-L/R should jump cursor by word.
app_shortcuts_customize_google_chrome_back () {
  # echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Back: Cmd-[ → Alt-Left"
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Back: Cmd-Left → Ctrl-Left"
}

app_shortcuts_customize_google_chrome_forward () {
  # echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Forward: Cmd-] → Alt-Right"
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Forward: Cmd-Right → Ctrl-Right"
}

app_shortcuts_customize_google_chrome_bookmark_manager () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Bookmark Manager: Opt-Cmd-B → Ctrl-Shift-O"
}

app_shortcuts_customize_google_chrome_bookmark_this_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Bookmark This Tab...: Cmd-D → Ctrl-D"
}

app_shortcuts_customize_google_chrome_bookmark_all_tabs () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Bookmark All Tabs...: Cmd-Shift-D → Ctrl-Shift-D"
}

app_shortcuts_customize_google_chrome_zoom () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Zoom: (unset) → F11"
}

app_shortcuts_customize_google_chrome_quit_and_keep_windows () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Quit and Keep Windows: Cmd-Q → Ctrl-Shift-Q"
}

# ***

# Google Chrome has a ⋮ > Zoom > [ - XXX% + ] widget, but you want to
# look in the menubar for the names of those keyboard-mapped items.
# (I confess, I forget to check the menu bar, especially because I
# hide it). See:
# - View > Zoom In: Ctrl-= → Ctrl-Shift-=
# - View > Zoom Out: Ctrl-_ → Ctrl-Shift-- [Same as default, but I find
#                              it odd that Zoom In is one mod + one key,
#                              but that Zoom Out is two mods + one key,
#                              seems like a lack of parity]
# - View > Actual Size: Cmd-0 → Ctrl-Shift-0

app_shortcuts_customize_google_chrome_zoom_in_bigger () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: View: Zoom In: Cmd-= → Ctrl-Shift-="
}

app_shortcuts_customize_google_chrome_zoom_out_smaller () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: View: Zoom Out: Cmd-_ → Ctrl-Shift--"
}

app_shortcuts_customize_google_chrome_zoom_actual_size_reset () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: View: Actual Size: Cmd-0 → Ctrl-Shift-0"
}

app_shortcuts_customize_google_chrome_minimize () {
  echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Window: Minimize: Cmd-M → Cmd-N"
}

# ***

# The edit keys are remapped globally courtesy Karabiner-Elements, so skip this
# (but here for notoriety):
false && (
  app_shortcuts_customize_google_chrome_cut () {
    echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Cut: Cmd-X → Ctrl-X"
  }

  app_shortcuts_customize_google_chrome_copy () {
    echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Copy: Cmd-C → Ctrl-C"
  }

  app_shortcuts_customize_google_chrome_paste () {
    echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Paste: Cmd-V → Ctrl-V"
  }

  app_shortcuts_customize_google_chrome_select_all () {
    echo "${CRUMB_APP_SHORTCUTS}: Google Chrome.app: Select All: Cmd-A → Ctrl-A"
  }
)

# ***

# If you make changes via System Preferences > Keyboard > Shortcuts, grab the new dict:
#   defaults read com.google.Chrome NSUserKeyEquivalents
app_shortcuts_customize_google_chrome_all () {
  defaults write com.google.Chrome NSUserKeyEquivalents '{
    "Actual Size" = "^$0";
    Back = "^\U2190";
    "Bookmark All Tabs..." = "^$d";
    "Bookmark Manager" = "^$o";
    "Bookmark This Tab..." = "^d";
    "Close Tab" = "~w";
    "Close Window" = "^$w";
    "Developer Tools" = "^$i";
    "Find Next" = "\Uf706";
    "Find Previous" = "$\Uf706";
    "Find..." = "^f";
    "Force Reload This Page" = "^$r";
    Forward = "^\U2192";
    "Inspect Elements" = "^$c";
    "JavaScript Console" = "^$j";
    Minimize = "@n";
    "New Incognito Window" = "^$n";
    "New Tab" = "^t";
    "New Window" = "^n";
    "Open File..." = "^o";
    "Open Location..." = "^l";
    "Print..." = "^p";
    "Quit and Keep Windows" = "^$q";
    Redo = "^$z";
    "Reload This Page" = "^r";
    "Reopen Closed Tab" = "^$t";
    "Save Page As..." = "^s";
    Undo = "^z";
    "Use Selection for Find" = "\Uf704";
    "View Source" = "^$u";
    Zoom = "\Uf70e";
    "Zoom In" = "^$=";
    "Zoom Out" = "^$-";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_firefox () {
  app_shortcuts_customize_firefox_quit_firefox
  app_shortcuts_customize_firefox_new_tab
  app_shortcuts_customize_firefox_new_window
  app_shortcuts_customize_firefox_close_tab
  app_shortcuts_customize_firefox_undo
  app_shortcuts_customize_firefox_redo
  app_shortcuts_customize_firefox_find_in_this_page
  app_shortcuts_customize_firefox_find_again
  # FIXME/2022-10-19: Add Minimize.

  app_shortcuts_customize_firefox_all
}

app_shortcuts_customize_firefox_quit_firefox () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: Quit Firefox: Cmd-Q → Ctrl-Shift-Q"
}

app_shortcuts_customize_firefox_new_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: New Tab: Cmd-T → Ctrl-T"
}

app_shortcuts_customize_firefox_new_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: New Window: Cmd-N → Ctrl-N"
}

app_shortcuts_customize_firefox_close_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: Close Tab: Cmd-W → Alt-W"
}

app_shortcuts_customize_firefox_undo () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: Undo: Cmd-Z → Ctrl-Z"
}

app_shortcuts_customize_firefox_redo () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: Redo: Cmd-Shift-Z → Ctrl-Shift-Z"
}

app_shortcuts_customize_firefox_find_in_this_page () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: Find in This Page...: Cmd-F → Ctrl-F"
}

app_shortcuts_customize_firefox_find_again () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox.app: Find Again: Cmd-G → Ctrl-G"
}

# FIXME/2022-10-17: I haven't installed Firefox yet, nor remapped shortcuts:
#   defaults read com.mozilla.firefox NSUserKeyEquivalents
# If you make changes via System Preferences > Keyboard > Shortcuts, grab the new dict:
#   defaults read com.mozilla.firefoxXXXXX NSUserKeyEquivalents
app_shortcuts_customize_firefox_all () {
  echo
  echo "FIXME: Complete the Firefox customization."
  echo
  # defaults write XXX NSUserKeyEquivalents '{
  # }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_firefox_developer_edition () {
  app_shortcuts_customize_firefox_developer_edition_web_developer_tools
  # FIXME/2022-10-19: Add Minimize.

  app_shortcuts_customize_firefox_developer_edition_all
}

app_shortcuts_customize_firefox_developer_edition_web_developer_tools () {
  echo "${CRUMB_APP_SHORTCUTS}: Firefox Developer Edition.app: Web Developer Tools: Opt-Cmd-I → Ctrl-Shift-J"
}

# FIXME/2022-10-17: I haven't installed Firefox yet, nor remapped shortcuts:
#   defaults read com.mozilla.firefoxXXXXX NSUserKeyEquivalents
# If you make changes via System Preferences > Keyboard > Shortcuts, grab the new dict:
#   defaults read com.mozilla.firefoxXXXXX NSUserKeyEquivalents
app_shortcuts_customize_firefox_developer_edition_all () {
  echo
  echo "FIXME: Complete the Firefox Developer Edition customization."
  echo
  # defaults write XXX NSUserKeyEquivalents '{
  # }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_safari () {
  app_shortcuts_customize_safari_quit_safari
  app_shortcuts_customize_safari_new_window
  app_shortcuts_customize_safari_new_private_window
  app_shortcuts_customize_safari_new_tab
  app_shortcuts_customize_safari_new_tab_at_end
  app_shortcuts_customize_safari_close_window
  app_shortcuts_customize_safari_undo
  app_shortcuts_customize_safari_redo
  app_shortcuts_customize_safari_find
  app_shortcuts_customize_safari_find_next
  app_shortcuts_customize_safari_find_previous
  app_shortcuts_customize_safari_reload_page
  app_shortcuts_customize_safari_show_web_inspector
  app_shortcuts_customize_safari_show_javascript_console
  # FIXME/2022-10-19: Add Minimize.

  app_shortcuts_customize_safari_all
}

app_shortcuts_customize_safari_quit_safari () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Quit Safari: Cmd-Q → Ctrl-Shift-Q"
}

app_shortcuts_customize_safari_new_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: New Window: Cmd-N → Ctrl-N"
}

app_shortcuts_customize_safari_new_private_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: New Private Window: Cmd-Shift-N → Ctrl-Shift-N"
}

app_shortcuts_customize_safari_new_tab () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: New Tab: Cmd-T → Ctrl-T"
}

app_shortcuts_customize_safari_new_tab_at_end () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: New Tab at End: Opt-Cmd-T → Ctrl-Shift-T"
}

app_shortcuts_customize_safari_close_window () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Close Window: Cmd-W → Alt-W"
}

app_shortcuts_customize_safari_undo () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Undo: Cmd-Z → Ctrl-Z"
}

app_shortcuts_customize_safari_redo () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Redo: Cmd-Shift-Z → Ctrl-Shift-Z"
}

app_shortcuts_customize_safari_find () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Find...: Cmd-F → Ctrl-F"
}

app_shortcuts_customize_safari_find_next () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Find Next: Cmd-G → Ctrl-G"
}

app_shortcuts_customize_safari_find_previous () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Find Previous: Cmd-Shift-G → Ctrl-Shift-G"
}

app_shortcuts_customize_safari_reload_page () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Reload Page: Cmd-R → Ctrl-R"
}

app_shortcuts_customize_safari_show_web_inspector () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Show Web Inspector: Opt-Cmd-I → Ctrl-Shift-I"
}

app_shortcuts_customize_safari_show_javascript_console () {
  echo "${CRUMB_APP_SHORTCUTS}: Safari.app: Show JavaScript Console: Opt-Cmd-C → Ctrl-Shift-J"
}

# If you make changes via System Preferences > Keyboard > Shortcuts, grab the new dict:
#   defaults read com.apple.Safari NSUserKeyEquivalents
app_shortcuts_customize_safari_all () {
  defaults write com.apple.Safari NSUserKeyEquivalents '{
    "Close Window" = "~w";
    "Find Next" = "^g";
    "Find Previous" = "^$g";
    "Find..." = "^f";
    "New Private Window" = "^$n";
    "New Tab" = "^t";
    "New Tab at End" = "^$t";
    "New Window" = "^n";
    "Quit Safari" = "^$q";
    Redo = "^$z";
    "Reload Page" = "^r";
    "Show JavaScript Console" = "^$j";
    "Show Web Inspector" = "^$i";
    Undo = "^z";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# 2022-10-18: Yeah, you wish you could set custom keyboard mappings on
# Meld, but ya can't: It has no respect.
# E.g.,
#   - Apple [menu] > System Preferences... > Keyboard [launcher] > Shortcuts [tab]
#     > App Shortcuts [left tab]:
#       Press ``+`` and enter:
#         *Application*: Choose ``Meld.app``
#           - *Menu Title*: ``Quit Meld``
#             *Keyboard Shortcut*: ``Ctrl-Q`` (``^Q``) [Default: ``Cmd-Q``]
#     then run Meld, and you'll see the Meld > Quit Meld menu entry shows
#     the Ctrl-Q that you assigned, but pressing Ctrl-Q has no effect. And
#     then you press Cmd-Q and Meld quits, and so you realize Meld doesn't
#     respect keyboard mappings.
#
# - ANIDA: You wanna be a hero to the Meld community? Make this work.
#
# NOTE: DepoXy use KE to bind Ctrl-q, but now *both* shortcuts work:
#       - Pressing either Cmd-q or Ctrl-q will Quit Meld.
#
# NOTE: Meld has no *Minimize* menu item, which is another common
#       menu item we like to remap.

app_shortcuts_customize_meld () {
  :
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_slack () {
  app_shortcuts_customize_slack_undo
  app_shortcuts_customize_slack_redo
  app_shortcuts_customize_slack_paste_and_match_style
  app_shortcuts_customize_slack_find
  app_shortcuts_customize_slack_search
  app_shortcuts_customize_slack_minimize

  app_shortcuts_customize_slack_all
}

# Globally remapped by KE: Cut, Copy, Paste, and Select All.

app_shortcuts_customize_slack_undo () {
  echo "${CRUMB_APP_SHORTCUTS}: Slack.app: Undo: Cmd-Z → Ctrl-Z"
}

app_shortcuts_customize_slack_redo () {
  echo "${CRUMB_APP_SHORTCUTS}: Slack.app: Redo: Cmd-Shift-Z → Ctrl-Shift-Z"
}

app_shortcuts_customize_slack_paste_and_match_style () {
  echo "${CRUMB_APP_SHORTCUTS}: Slack.app: Paste and Match Style: Cmd-Shift-V → Ctrl-Shift-V"
}

app_shortcuts_customize_slack_find () {
  echo "${CRUMB_APP_SHORTCUTS}: Slack.app: Window: Find...: Cmd-F → Cmd-F"
}

app_shortcuts_customize_slack_search () {
  echo "${CRUMB_APP_SHORTCUTS}: Slack.app: Window: Search: Cmd-G → Cmd-G"
}

app_shortcuts_customize_slack_minimize () {
  echo "${CRUMB_APP_SHORTCUTS}: Slack.app: Window: Minimize: Cmd-M → Cmd-N"
}

app_shortcuts_customize_slack_all () {
  defaults write com.tinyspeck.slackmacgap NSUserKeyEquivalents '{
    "Find..." = "^f";
    Minimize = "@n";
    "Paste and Match Style" = "^$v";
    Redo = "^$z";
    Search = "^g";
    Undo = "^z";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_teams () {
  app_shortcuts_customize_teams_quit_microsoft_teams

  app_shortcuts_customize_teams_all
}

app_shortcuts_customize_teams_quit_microsoft_teams () {
  echo "${CRUMB_APP_SHORTCUTS}: Microsoft Teams.app: Quit Microsoft Teams: Cmd-Q → Ctrl-q"
}

app_shortcuts_customize_teams_all () {
  defaults write com.microsoft.teams NSUserKeyEquivalents '{
    "Quit Microsoft Teams" = "^q";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Note that "Webex Meetings.app" is not in the usual /Applications/
# location, but rather under user home, e.g.,
#
#   $HOME/Library/Application Support/WebEx Folder/MC_42.11.3.14/
#     Cisco Webex Meetings.app
#
# However, if you Show Path Bar (under Finder > View, or <Cmd-Alt-p>), you'll
# see a different application name if you right-click the app name in the path 
# line and select *Copy “Cisco Webex Meetings.app” as Pathname*, e.g.,
#
#   $HOME/Library/Application Support/WebEx Folder/MC_42.11.3.14/
#     Meeting Center.app
#
# This illustrates how macOS is using the value from the Package Contents
# property list, e.g., if you view Contents/Info.plist, you'll see that
# "Meeting Center" is <value> for the CFBundleExecutable and CFBundleName
# <key>s (and com.webex.meetingmanager is the CFBundleIndentifier, FYI).
app_shortcuts_customize_webex () {
  app_shortcuts_customize_webex_leave_meeting
  app_shortcuts_customize_webex_end_meeting
  app_shortcuts_customize_webex_undo
  app_shortcuts_customize_webex_redo
  # Conveniently, View > Full Screen already using Ctrl, at Ctrl-Shift-F
  app_shortcuts_customize_webex_mute_me
  app_shortcuts_customize_webex_unmute_me
  app_shortcuts_customize_webex_minimize

  app_shortcuts_customize_webex_all
}

app_shortcuts_customize_webex_leave_meeting () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: Leave Meeting: Cmd-L → Ctrl-L"
}

app_shortcuts_customize_webex_end_meeting () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: End Meeting: Cmd-L → Ctrl-L"
}

app_shortcuts_customize_webex_undo () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: Undo: Cmd-Z → Ctrl-Z"
}

app_shortcuts_customize_webex_redo () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: Redo: Cmd-Shift-Z → Ctrl-Shift-Z"
}

app_shortcuts_customize_webex_mute_me () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: Mute Me: Cmd-Shift-M → Ctrl-Shift-M"
}

app_shortcuts_customize_webex_unmute_me () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: Unmute Me: Cmd-Shift-M → Ctrl-Shift-M"
}

app_shortcuts_customize_webex_minimize () {
  echo "${CRUMB_APP_SHORTCUTS}: Cisco Webex Meetings.app: Window: Minimize: Cmd-M → Cmd-N"
}

app_shortcuts_customize_webex_all () {
  defaults write com.webex.meetingmanager NSUserKeyEquivalents '{
    "End Meeting" = "^l";
    "Leave Meeting" = "^l";
    Minimize = "@n";
    "Mute Me" = "^$m";
    Redo = "^$z";
    Undo = "^z";
    "Unmute Me" = "^$m";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_dbeaver () {
  app_shortcuts_customize_dbeaver_quit_dbeaver

  app_shortcuts_customize_dbeaver_all
}

app_shortcuts_customize_dbeaver_quit_dbeaver () {
  echo "${CRUMB_APP_SHORTCUTS}: DBeaver.app: Quit DBeaver: Cmd-Q → Ctrl-Q"
}

app_shortcuts_customize_dbeaver_all () {
  defaults write org.jkiss.dbeaver.core.product NSUserKeyEquivalents '{
    "Quit DBeaver" = "^q";
  }'
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

app_shortcuts_customize_macdown () {
  app_shortcuts_customize_macdown_quit_macdown

  app_shortcuts_customize_macdown_all
}

app_shortcuts_customize_macdown_quit_macdown () {
  echo "${CRUMB_APP_SHORTCUTS}: MacDown.app: “Quit MacDown”: Cmd-Q → Ctrl-q"
}

app_shortcuts_customize_macdown_all () {
  defaults write com.uranusjr.macdown NSUserKeyEquivalents '{
    "Quit MacDown" = "^q";
  }'
}

# +++ END: Application NSUserKeyEquivalents settings
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ================================================================= #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

locatedb_configure () {
  print_at_end+=("\
🔳 CLI: Create \`locate\` database:
   \`sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist\`

   - AWAIT: This command takes a moment

     - TRACK: \`ps aux | grep locate.updatedb\`

     - NTHEN: Test: \`locate something\`")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

pass_configure () {
  print_at_end+=("$(cat << 'EOF'
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

# ISOFF/2024-04-16: Whatever, I finally bought my own Mac, so keeping
# these (DXY_REMOVE_BLOATWARE=false now), who doesn't like to compose
# their own music, or to edit their own blarghbusters.
#   The author doesn't use GarageBand or iMovie for development, and I
#   don't like seeing these popup in Spotlight, or seeing them elsewhere,
#   so I like them gone. I also don't run macOS personally (Linux here)
#   so don't see myself wanting to try either app (never opened either).
macos_remove_bloatware () {
  if ! ${DXY_REMOVE_BLOATWARE:-false}; then
    echo "✗ Skipping bloatware removal"

    return 0
  fi

  macos_remove_bloatware_app "/Applications/GarageBand.app"
  macos_remove_bloatware_app "/Library/Application Support/GarageBand"
  macos_remove_bloatware_app "/Applications/iMovie.app"
}

macos_remove_bloatware_app () {
  local appdir="$1"

  if [ -d "${appdir}" ]; then
    echo "Removing bloatware: $(basename -- "${appdir}")"

    sudo_bin_rm_rf "${appdir}"
  else
    echo "✓ Bloatware absent: $(basename -- "${appdir}")"
  fi
}

sudo_bin_rm_rf () {
  local target="$1"

  [ -n "${target}" ] || return 1

  command rm -rf -- "${target}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# These GRIPEs merely exist so I don't waste time trying to solve
# these again in the future, having forgot that I already tried.
macos_uncustomizable_gripes () {
  gripe_macos_cannot_customize_disable_notch_aka_camera_housing
  gripe_macos_cannot_customize_command_tab_disable_q_quit
}

# GRIPE/2022-11-04: AFAIK, there's no way to *disable* the MacBook notch
# area, aka Camera Housing. *If only you could.*
# - Specifically, I liked being able to throw the cursor to the top of the
#   screen and easily grab the top of a window, or to click on a tab.
#   - E.g., especially with Google Chrome, it was easy to click tabs
#     but moving the cursor to the top of the screen. But now, with
#     the *Notch*, the Chrome bar sits below the vertical notch area,
#     and if you toss the cursor all the way top, it flies past the
#     Chrome window (triggers the menu bar to slide down). So now I
#     have to more careful move the cursor to a tab and click.
# - I was hoping to just disable the whole notch area, so the mouse
#   would stop just below it.
#   - Alas, I could not find a solution online.
#   - At least now when the menu bar appears, it doesn't cover the top
#     of any windows, like it does on non-Notch MacBooks.
# - From my limited searching, I found two notch-related apps, but they
#   simply make the menu bar black so that the notch isn't noticeable,
#   which is not an issue on my MacBook (perhaps because my background
#   is black):
#   - Forehead: https://goodsnooze.gumroad.com/l/nASbe
#   - TopNotch: https://topnotch.app/
gripe_macos_cannot_customize_disable_notch_aka_camera_housing () {
  is_probably_a_laptop || return 0

  print_at_end+=("🤷 MacBook Camera Housing aka Notch Preferences: AFAIK you’re stuck with it")
}

# GRIPE/2022-11-04: macOS Command-Tab not customizable, and I haven't
# found any apps to tweak it. Fortunately, you shouldn't need to use Cmd-Tab!
gripe_macos_cannot_customize_command_tab_disable_q_quit () {
  print_at_end+=("🤷 macOS Command-Tab: Cannot disable Quit app on <Cmd-tab q> (whereas <Alt-tab q> selects backward")
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

slather_macos_defaults () {
  local dry_run=false
  local cnt_run=false
  local non_disruptive=false

  # ***

  while [ "$1" != '' ]; do
    case $1 in
      --dry-run) dry_run=true; shift; ;;
      --cnt-run) cnt_run=true; shift; ;;
      --tame) non_disruptive=true; shift; ;;
      *) shift; ;;
    esac
  done

  # ***

  if ${cnt_run}; then
    local cnt_defaults=0
    local cnt_defaults_write=0
    local cnt_defaults_delete=0
    local cnt_defaults_other=0
    declare -A cnt_defaults_domain
    local cnt_killalls=0
    local cnt_ascripts=0
    local cnt_binrmrfs=0

    count_it
  elif ${dry_run}; then
    fake_it
  fi

  check_deps

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  os_is_macos () {
    [ "$(uname)" = 'Darwin' ]
  }

  os_is_macos || return 0

  insist_is_latest_macos_version

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  system_settings_close

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  local print_at_end=()  # 🔳 ◻
  # Killallers
  local restart_dock=false
  local restart_finder=false
  local restart_systemuiserver=false

  domains_customize

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  ${non_disruptive} || ( ${restart_dock} && killall Dock )

  ${non_disruptive} || ( ${restart_finder} && killall Finder )

  ${restart_systemuiserver} && killall SystemUIServer

  # ***

  [ -z "${print_at_end}" ] || (
    echo
    echo "CPYST: Please perform the following tasks manually:"
    echo

    for print_ln in "${print_at_end[@]}"; do
      echo -e "${print_ln}"
    done
  )

  # ***

  print_cnt_run_report
}

# ***

domains_customize () {

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  # ***
  #
  # ░░░ This section aligns with *[Apple Menu] > System Preferences...* on macOS v12.6.

  general_appearance_customize

  desktop_and_screen_saver_customize

  dock_and_menu_bar_customize

  mission_control_customize

  # Not of interest:
  #   siri_customize
  #   spotlight_customize
  #   language_ampersand_region

  notifications_ampersand_focus_customize

  # Not of interest:
  #   internet_account
  #   passwords
  #   users_ampersand_groups

  accessibility_customize

  # Nothing of interest:
  #   screen_time
  #   extensions
  #   security_ampersand_privacy
  # <HR>
  #   software_update
  #   network
  #   bluetooth

  sound_preferences_customize

  # Nothing of interest:
  #   touch_id

  keyboard_customize

  # Nothing of interest:
  #   trackpad

  mouse_customize

  display_customize

  # Nothing of interest:
  #   printers_ampersand_scanners
  #   battery
  #   date_ampersand_time
  #   sharing
  #   time machine
  #   startup disk
  #   profiles

  # ░░░ End: macOS v12.6 System Preferences... alignment.
  # ***

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  # ***

  launchpad_customize
  launchservices_customize

  # ***

  screenshots_customize

  # ***

  finder_customize

  # ***

  macos_customize

  # ***

  google_chrome_customize

  # ***

  mozilla_firefox_customize

  # ***

  alttab_customize

  # ***

  easy_move_plus_resize_customize

  # ***

  karabiner_elements_customize

  # ***

  rectangle_customize

  # ***

  activity_monitor_customize

  # ***

  iterm2_customize

  # ***

  macvim_customize

  # ***

  meld_customize

  # ***

  outlook_customize

  # ***

  slack_customize

  # ***

  dbeaver_customize

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  # ***

  shortcuts_customize_macos

  # ***

  app_shortcuts_reclaim_cmd_t

  app_shortcuts_update_universalaccess

  # Application NSUserKeyEquivalents settings:

  app_shortcuts_customize_finder

  app_shortcuts_customize_preview

  app_shortcuts_customize_system_preferences

  app_shortcuts_customize_macvim

  app_shortcuts_customize_iterm2

  app_shortcuts_customize_google_chrome

  app_shortcuts_customize_firefox

  app_shortcuts_customize_firefox_developer_edition

  app_shortcuts_customize_safari

  app_shortcuts_customize_meld

  app_shortcuts_customize_slack

  app_shortcuts_customize_teams

  app_shortcuts_customize_webex

  app_shortcuts_customize_dbeaver

  app_shortcuts_customize_macdown

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  # ***

  locatedb_configure

  # ***

  pass_configure

  # ***

  macos_remove_bloatware

  # ***

  macos_uncustomizable_gripes

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

  # ***
}

# ***

print_cnt_run_report () {
  if ! ${cnt_run}; then

    return 0
  fi

  echo "Counts report:"
  echo "- \`defaults\` calls   : ${cnt_defaults}"
  echo "  - 'write'   $(printf "%4d" "${cnt_defaults_write}")"
  echo "  - 'delete'  $(printf "%4d" "${cnt_defaults_delete}")"
  echo "  -  other    $(printf "%4d" "${cnt_defaults_other}")"
  echo "- no. domains        : ${#cnt_defaults_domain[@]}"
  # USAGE: Use this list to audit lib/defaults-domains-block.list
  for domain in "${!cnt_defaults_domain[@]}"; do
    printf "  - %3d : %s\n" "${cnt_defaults_domain[$domain]}" "${domain}"
  done
  echo "- \`killall\`   calls  : ${cnt_killalls}"
  echo "- \`osascript\` calls  : ${cnt_ascripts}"
  echo "- \`rm -rf --\` calls  : ${cnt_binrmrfs}"
  echo "- No. reminders      : ${#print_at_end[@]}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

# UCASE/2024-04-14: Requires Bash v4 because of --cnt-run `declare -A`
# usage (though we could convert associative array to flattened array;
# but no reason not to require that which should already be installed,
# assuming user previously ran install-homebrew.sh).
# - SAVVY: While script *requires* v4, it supports running from v3.
#   - UCASE: The author's shell remains built-in macOS bash v3 (/bin/bash),
#     because years ago, Homebrew bash v5 seemed to run slowly (at least as
#     my terminal shell, in my experience).
#     - So Homebrew bash is available, but it's not #!/bin/bash nor
#       #!/usr/bin/env bash. Rather, it's findable at a known location.

promote_homebrew_bash () {
  # SAVVY: SHELL remains /bin/bash, even when running Homebrew bash,
  #   so use ps lookup.
  # SAVVY: Alt. `ps -o cmd` works on @linux LM, but not @macOS.
  if $(ps -o command $$ | tail -n 1 | cut -d ' ' -f1) --version \
      | grep -q -e "^GNU bash, version \([4-9]\.\|[0-9][0-9]\+\.\)" \
  ; then
    # Bash v4 or better.

    return 1
  fi

  # Bash v3.

  local brew_prefix="$(print_homebrew_prefix)"

  if [ -n "${brew_prefix}" ]; then
    if ${SLATHER_DEJA_VU:-false}; then
      >&2 echo "ERROR: Requires Bash v4 or better (and Homebrew bash <= v3?!)"

      exit_1
    fi

    # Run via Homebrew bash.
    SLATHER_DEJA_VU=true "${brew_prefix}/bin/bash" "$0" "$@"
  else
    >&2 echo "ERROR: Requires Bash v4 or better (and Homebrew bash not found)"

    exit_1
  fi

  # Unreachable.
  return 0
}

print_homebrew_prefix () {
  local brew_prefix="${HOMEBREW_PREFIX}"

  # Apple Silicon (arm64) brew path is /opt/homebrew
  [ -d "${brew_prefix}" ] || brew_prefix="/opt/homebrew"

  # Otherwise on Intel Macs it's under /usr/local
  [ -d "${brew_prefix}" ] || brew_prefix="/usr/local/Homebrew"

  if [ ! -d "${brew_prefix}" ]; then

    return 0
  fi

  printf "%s" "${brew_prefix}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

_NORMAL_EXIT=false

exit_1 () { _NORMAL_EXIT=true; exit 1; }
exit_0 () { _NORMAL_EXIT=true; exit 0; }

exit_cleanup () {
  if ! ${_NORMAL_EXIT}; then
    # USAGE: Alert on unexpected error path, so you can add happy path.
    >&2 echo "ALERT: "$(basename -- "$0")" exited abnormally!"
    >&2 echo "- Hint: Enable \`set -x\` and run again..."
  fi

  trap - EXIT INT

  ${_NORMAL_EXIT} && exit 0 || exit 1
}

int_cleanup () {
  _NORMAL_EXIT=true

  exit_cleanup
}

# ***

main () {
  set -e

  trap -- exit_cleanup EXIT
  trap -- int_cleanup INT

  slather_macos_defaults "$@"

  trap - EXIT INT
}

if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  # Being executed.
  if ! promote_homebrew_bash "$@"; then
    main "$@"
  fi
fi

