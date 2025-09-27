#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# https://github.com/DepoXy/macOS-GNOME-onboarder#🏂
# License: MIT

# Copyright (c) © 2021-2024 Landon Bouma. All Rights Reserved.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Call without args to
#         install all the brew apps and casks listed below,
#         to add a few symlinks under ~/.local/bin,
#         and to start one service (currently just "borders",
#           which makes Alacritty windows more usable).
#
#   $ path/to/macOS-onboarder/bin/install-homebrew.sh
#
# This is obviously a very prescriptive list.
# - If you'd like to customize it, consider forking this project
#   and making it your own.
# - Alternatively, if you think everyone would benefit from your
#   changes, please submit a PR.
#
# REFER: See *Homebrew Documentation* for general brew help:
#   https://docs.brew.sh/

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# A few apps below allow opt-in or opt-out via arg ENVIRONs.
#
# OPT-OUTS: (e.g., if your Vendor installs any of these app for you):
#
#   BREW_EXCLUDE_SLACK=true
#
# OPT-INS: (more niche stuff you might not care about):
#
#   # Virtualization tools
#   BREW_INCLUDE_COLIMA=true          # Also installs docker, docker-compose,
#                                     # docker-credential-helper, & kubernetes-cli.
#   BREW_INCLUDE_DOCKER_DESKTOP=true  # Easier to use than colima et al, prob., at
#                                     # least on macOS.
#   BREW_INCLUDE_VIRTUALBOX=true
#
#   # Misc. apps
#   BREW_INCLUDE_ACROBAT_READER       # Adobe Acrobat Reader cask (>500M)
#   BREW_INCLUDE_DROPBOX=true         # Opt-in b/c you prob. won't want on vendor machine.
#   BREW_INCLUDE_PGADMIN4=true        # Postgres tool
#   BREW_INCLUDE_P4MERGE=true         # File diff — opt-in b/c author prefers Meld.
#   BREW_INCLUDE_TRANSMISSION=true    # BitTorrent client
#   BREW_INCLUDE_WIRESHARK
#   BREW_INCLUDE_FINICKY              # ISOFF/2025-08-30: Finicky v4 has issues...
#   BREW_INCLUDE_GEEKBENCH=true
#
#   # Editors
#   BREW_INCLUDE_LICLIPSE
#   BREW_INCLUDE_VIMR
#   BREW_INCLUDE_VV
#
#   # Media players
#   BREW_INCLUDE_SPOTIFY=true         # Opt-in b/c you may not want on vendor machine.
#   BREW_INCLUDE_MEDIA_PLAYERS=true   # Includes mpv, vlc, smplayer (reqs. Rosetta 2).
#   BREW_INCLUDE_ELMEDIA_PLAYER
#   BREW_INCLUDE_SMPLAYER
#
#   # Diagramming apps
#   BREW_INCLUDE_PENCIL=false         # Opt-in b/c author rarely uses.
#
#   # Team collab. software (see also Slack, above)
#   BREW_INCLUDE_MS_TEAMS=true        # SAVVY: Requires admin password.
#   BREW_INCLUDE_ZOOM=true            # SAVVY: Requires admin password.
#   BREW_INCLUDE_WEBEX=true
#
#   # These will enable Rosetta 2 (tho not a big deal)
#   BREW_INCLUDE_DIGIKAM=true         # Photo organizer, and much more.
#   BREW_INCLUDE_GNUCASH=true         # Double-entry ledger, for your #books.
#   BREW_INCLUDE_MEDIA_PLAYERS=true   # smplayer reqs. Rosetta 2 (but not mpv, vlc).
#
#   # Disabled apps (these install but don't work, at least not for the author):
#   #   BREW_EXCLUDE_MELD=true        # Commented out b/c you should build from source.
#   #   BREW_INCLUDE_DIA=true         # Commented out b/c has issues on Apple Silicon.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

declare -a BREW_APPS=()
declare -a BREW_TAPS=()

# Array for `brew link` actions (this script doesn't have any).
declare -a BREW_LINK=()

# Array for `brew services start` actions.
declare -a BREW_SVCS=()
# Array for `eval` actions.
declare -a POST_EVAL=()

# USER_LINK is used to add symlinks under ~/.local/bin
declare -a USER_LINK=()

MACOS_INSTALL_ROSETTA2=false

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# ALERT: This script is not *integration tested* for long stretches.
#
# - The author runs it occassionally (e.g., yearly) to onboard a new host.
#
# - But the author frequently (e.g., weekly) adds a new app to the install
#   list, but then manually installs the app, e.g., `brew install <app>`.
#
# Just FYI in case you run this script and find any issues with it.
#
# - Though note the script is at least unit tested to ensure that it's
#   syntactically correct:
#
#     DRY_RUN=true ./install-homebrew.sh
#
#   This runs the script but stubs out `brew` and other external commands.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Add your preferred Brew formula and tasks to the BREW_APPS and
#        BREW_TAPS arrays, using the brew_app and brew_tap functions.
#
#        But please put *PROMPTY* formula and casks *first*.
#
#        - Some installs require the admin password, and we want
#          to nab the user's attention only when they first run
#          this script, and not when they return 5 minutes later
#          after a tea break to find the script paused for input.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# HSTRY/2024-11-14: This script used to exclusively target macOS, but
# (because lazydocker, and because Homebrew is otherwise convenient),
# it now works on Linux. (And now author is questioning whether to
# relocate script to a different/new project, at least not one that's
# named *macOS-onboarder#🏂*!)
#
# - Previously, the BREW_APP+=("<formula>") statements were each top-
#   level (file scope), but now they're wrapped by a function so we
#   can specify the target host(s).

# Check if target OS matches machine OS:
# - If no target specified: target all hosts;
# - If target is "Darwin": target macOS; or
# - If target is "GNU/Linux", or just "Linux": target Linux.
applies_to_os() {
  local target_os="$1"

  # We could check just `uname` (or `uname -s` (kernel name)),
  # but we'll check `uname -o` (operating system), in case in
  # the future we want to distinguish between Linux platforms.
  # - For now, we'll assume if Linux, user means GNU Linux.
  if [ "${target_os}" = "Linux" ]; then
    target_os="GNU/Linux"
  fi

  if [ -z "${target_os}" ] || [ "$(uname -o)" = "${target_os}" ]; then

    # Applies to host.
    return 0
  fi

  # Does not apply to this host.
  return 1
}

# ------------------------------ #

array_add() {
  local arr_name="$1"
  local cmd_args="$2"
  local target_os="$3"

  if ! applies_to_os "${target_os}"; then

    return 0
  fi

  eval "${arr_name}+=(\"${cmd_args}\")"
}

# *** Conveniences

array_add_both() {
  local arr_name="$1"
  local cmd_args="$2"

  local target_os=""

  array_add "${arr_name}" "${cmd_args}" "${target_os}"
}

array_add_linux() {
  local arr_name="$1"
  local cmd_args="$2"

  local target_os="GNU/Linux"

  array_add "${arr_name}" "${cmd_args}" "${target_os}"
}

array_add_macos() {
  local arr_name="$1"
  local cmd_args="$2"

  local target_os="Darwin"

  array_add "${arr_name}" "${cmd_args}" "${target_os}"
}

# ------------------------------ #

brew_app() {
  array_add "BREW_APPS" "$@"
}

brew_app_both() {
  array_add_both "BREW_APPS" "$@"
}

brew_app_linux() {
  array_add_linux "BREW_APPS" "$@"
}

brew_app_macos() {
  array_add_macos "BREW_APPS" "$@"
}

# ------------------------------ #

brew_tap() {
  array_add "BREW_TAPS" "$@"
}

brew_tap_both() {
  array_add_both "BREW_TAPS" "$@"
}

brew_tap_linux() {
  array_add_linux "BREW_TAPS" "$@"
}

brew_tap_macos() {
  array_add_macos "BREW_TAPS" "$@"
}

# ------------------------------ #

brew_link() {
  array_add "BREW_LINK" "$@"
}

brew_link_both() {
  array_add_both "BREW_LINK" "$@"
}

brew_link_linux() {
  array_add_linux "BREW_LINK" "$@"
}

brew_link_macos() {
  array_add_macos "BREW_LINK" "$@"
}

# ------------------------------ #

service_start() {
  array_add "BREW_SVCS" "$@"
}

service_start_both() {
  array_add_both "BREW_SVCS" "$@"
}

service_start_linux() {
  array_add_linux "BREW_SVCS" "$@"
}

service_start_macos() {
  array_add_macos "BREW_SVCS" "$@"
}

# ------------------------------ #

post_eval() {
  array_add "POST_EVAL" "$@"
}

post_eval_both() {
  array_add_both "POST_EVAL" "$@"
}

post_eval_linux() {
  array_add_linux "POST_EVAL" "$@"
}

post_eval_macos() {
  array_add_macos "POST_EVAL" "$@"
}

# ------------------------------ #

user_link() {
  array_add "USER_LINK" "$@"
}

user_link_both() {
  array_add_both "USER_LINK" "$@"
}

user_link_linux() {
  array_add_linux "USER_LINK" "$@"
}

user_link_macos() {
  array_add_macos "USER_LINK" "$@"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# BWARE: These install(s) prompt the user! **PROMPTY**

# Karabiner Elements: *Powerful* keyboard customization
# - PROMPTS: Requires admin password.
# - CALSO: See also Hammerspoon automator (installed below).
#
# ISOFF/2024-10-29: KE stopped working after upgrading to macOS Sequoia (15.0.1).
# - It's perhaps been fixed since then, but I migrated everything to Hammerspoon.
# - Also Hammerspoon's ~/.hammerspoon/init.lua is wicked faster than having to
#   futz with a GUI to update KE JSON. (Not that I don't love Karabiner Elements!
#   It's always bitter-sweet switching tools when one has served you so lovingly
#   for so long. =)
#
# brew_app_macos "--cask karabiner-elements"

# --------------------------

# - ADMIN: On some client machines, you may need to start an
#   *Admin Access* terminal session to install GIMP.
#   - So this command is potentially **PROMPTY**.
# - F_Y_I: There's also McGIMP — `brew_app_macos "--cask mcgimp"`
#   - It's a user compile with additional plugins, include G’MIC,
#     Google’s NIC collection, and a panoramic stitcher.
#       https://techtips101.wordpress.com/2017/10/05/mcgimp-gimp-gmic-more/
#     So unlikely you'll care unless you're a GIMP power user.
brew_app_macos "--cask gimp"

# Vector (SVG) graphics editor.
# https://inkscape.org/
# https://formulae.brew.sh/cask/inkscape
brew_app_macos "--cask inkscape"

# Other graphics apps you might want:
#  brew_app_macos "--cask blender"

# --------------------------

# Team collaboration applications.
#
# - See below: Webex.
#
# - Following are those apps that require admin access
#   (so they're included early in BREW_APPS, and you're
#   prompted sooner rather than later).

# Microsoft Teams
# https://www.microsoft.com/en-us/microsoft-teams/group-chat-software
# https://formulae.brew.sh/cask/microsoft-teams
#
# - ADMIN: PROMPTS: Requires admin password.
if ${BREW_INCLUDE_MS_TEAMS:-false}; then
  brew_app_macos "--cask microsoft-teams"
fi

# Zoom
# https://www.zoom.com/
# https://formulae.brew.sh/cask/zoom
#
# - ADMIN: PROMPTS: Requires admin password.
if ${BREW_INCLUDE_ZOOM:-false}; then
  brew_app_macos "--cask zoom"
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

brew_app_macos "bash"
# v1: "Programmable completion for Bash 3.2"
#      https://formulae.brew.sh/formula/bash-completion
#        brew_app_macos "bash-completion"
# v2: "Programmable completion for Bash 4.2+"
#      https://formulae.brew.sh/formula/bash-completion@2
brew_app_macos "bash-completion@2"

# https://fishshell.com/
brew_app_both "fish"

# --------------------------

# Readline is a dependency for many apps, so might as well be explicit
# about it here (and then we can talk about it in front of its back).
# - Mainly, I want to mention that there's no /etc/inputrc on macOS,
#   so if you're coming from Linux and are used to Ctrl-Left/Right
#   mapping to 'backward-word'/'forward-word', among a handful of
#   other default bindings, you won't find them on macOS by default.
#   - If you're not using the DepoXy development environment, you can
#     simply copy /etc/inputrc from any Linux machine into your personal
#     ~/.inputrc file.
#   - Or, if you are using DepoXy, look at the home/.inputrc file.
brew_app_macos "readline"

# --------------------------

# Install commands with "g"-prefixes.
# - Link some from ~/.local/bin using their normal names,
#   so that Homefries and DepoXy scripts will use them.
# - Alternatively, you could add `gnubin` to PATH to link them all, e.g.,
#   `PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"`. But that
#   might cause issues, say, if some tool you use expects the non-GNU
#   version. Or, more likely, the Homebrew version runs markedly slower
#   than the built-in app (I'm talking about you, `grep` (see below)).
#   So it's better to leave each GNU app off PATH until you realize you
#   need it, and then link what you need individually, which also means
#   you'll be on the lookout for any issues that may cause.
brew_app_macos "coreutils"
user_link_macos "gcp"
user_link_macos "gdate"
user_link_macos "gdu"
# SAVVY/2024-05-26: Here we symlink ~/.local/bin/ls -> /opt/homebrew/bin/gls
# - Note that Homefries adds `alias ls='/opt/homebrew/bin/gls ...'
#   but this symlink used if user runs `command ls`.
# - If user wants to print macOS ACL details, then can use /bin/ls, e.g.,
#     /bin/ls -led ~/.Trash
user_link_macos "gls"
user_link_macos "gmktemp"
user_link_macos "gsort"
user_link_macos "gtouch"
user_link_macos "gwc"
user_link_macos "grealpath"

# --------------------------

# - HSTRY/2024-07-18: Circa 2020, I tried Brew git, but it was
#   agonizingly slow running custom commands (like those found
#   in https://github.com/landonb/git-smart, or
#   https://github.com/landonb/git-my-merge-status).
#   - But macOS/Apple git trails Brew git, currently by over a
#     year:
#       $ git --version
#       git version 2.39.3 (Apple Git-146)
#       # Apr 17, 2023
#
#       $ /opt/homebrew/bin/git --version
#       git version 2.45.2
#       # May 30, 2024
#   - Most recently, however, I wanted to demo the new
#     --default-prefix option (added in git 2.41) while
#     hacking on tig.
#   - So let's give Brew git another shot.
brew_app_macos "git"
user_link_macos "git"

# tig is my all-time favorite git history viewer and staging tool.
brew_app_macos "tig"

# Author is invested in tig and tig-newtons, but if I had found lazygit
# years ago, maybe I'd be a LazyGit devotee instead.
# - In any case, lazy.nvim's <localleader>l opens git-log using lazygit,
#   or fails on a stacktrace if lazygit is not installed.
# https://github.com/jesseduffield/lazygit
# https://formulae.brew.sh/formula/lazygit
brew_tap_both "jesseduffield/lazygit"
brew_app_both "jesseduffield/lazygit/lazygit"

# https://github.com/extrawurst/gitui
# Supposedly works better on larger repos, where supposedly tig fails.
# - Doesn't seem as intuitive as lazygit... at least for the 3 mins. I
#   demoed it...
brew_app_macos "gitui"

# gitk was my old favorite git history viewer, before I found tig. But gitk
# is a slower GUI application when compared to the screaming-fast tig TUI.
# And it's especially slow on macOS (obviously not Cocoa), and not much fun.
#
#  brew_app_macos "git-gui"

# GitHUB CLI.
brew_app_macos "gh"

# Supercharged `git rebase -i`. Beautiful, obscure tool... though I admit
# I most often just use EDITOR (vim) to edit rebase todos. Though maybe if
# I took the time to memorize this tool's key bindings I'd use it oftener.
# - Often wired via ~/.gitconfig: sequence.editor=interactive-rebase-tool
brew_app_macos "git-interactive-rebase-tool"

# https://github.com/tummychow/git-absorb
brew_app_both "git-absorb"

# https://github.com/dandavison/delta
# https://dandavison.github.io/delta/
# THANX: 25.4k GH ☆'s and I learned about it from spying on someone's dotfiles:
# https://github.com/lukas-reineke/dotfiles/blob/02064d6dc/git/.gitconfig
brew_app_both "git-delta"

# --------------------------

# *** Vim et al
#     ^^^^^^^^^

# If you install MacVim from the formula, you'll see:
#   $ brew install macvim
#   Warning: Treating macvim as a formula. For the cask, use homebrew/cask/macvim
# But an article I read says not to install from the cask:
#   "It is important to have installed macvim from brew directly, and not the cask,
#    or otherwise the vi command will not be changed to the new vim."
#   https://iscinumpy.gitlab.io/post/setup-a-new-mac/#vim
# Note there are multiple MacVim installation options, e.g.,
#   brew_app_macos "macvim"
#   brew_app_macos "--cask macvim"
#   brew_app_macos "macvim --HEAD"
# 2022-10-11: Trying from cask. Not sure the difference between the cask
# and the formula, other than the warning you see if you install from the
# formula. And I checked, and /opt/homebrew/bin/vi, which is a symlink to
# MacVim, is earlier in PATH than /usr/bin/vi, so I don't see the issue
# that Henry Schreiner (setup-a-new-mac article from 2019) documented.
brew_app_macos "--cask macvim"

# SAVVY: Note that Apple Vim is relatively current. E.g.:
# - On 2025-01-22, running v9.1 1-754, compiled 2024-11-09.
# But it lacks several features compared to Homebrew Vim:
#   -arabic         -gettext      -perl         -sodium
#   -balloon_eval   -keymap       -profile      -sound
#   -browse         -langmap      -python       -toolbar
#   -clientserver   -lua          -python3      -vartabs
#   -dnd            -mouseshape   -rightleft    -xim
#   -emacs_tags                   -ruby         -xim
user_link_macos "vi vi"
user_link_macos "view view"
user_link_macos "vim vim"
user_link_macos "vimdiff vimdiff"

# *** Neovim et al
#     ^^^^^^^^^^^^

# REFER/2025-02-23: You may want both stable and latest, especially
# because Neovim very much still under development (they're not even
# at version 1 yet?! =):
#   brew install neovim
#   brew unlink neovim
#   brew install --HEAD neovim
# But this script doesn't support that workflow, so we'll get it
# "in post".
# - CXREF: DepoXy uses an OMR 'install' task, which you'll find here
#   within a DepoXy environment within the Neovim myrepos config file:
#     ~/.depoxy/ambers/home/.kit/nvim/_mrconfig
brew_app_both "neovim"
user_link_both "nvim nvim"

# Neovide — "simple, no-nonsense, cross-platform [GUI] for Neovim
#            (an aggressively refactored and updated Vim editor)"
# https://neovide.dev/
# https://github.com/neovide/neovide
# ONICE/2025-01-22: This is a pleasant surprise, Neovide is very elegant.
brew_app_macos "--cask neovide"

# VimR — "Neovim GUI for macOS in Swift"
# https://github.com/qvacua/vimr
# TRIED/2025-01-20: Starts up with a file browser in the left pane.
# - DUNNO: Normal mode cursor is invisible.
if ${BREW_INCLUDE_VIMR:-false}; then
  brew_app_macos "--cask vimr"
fi

# envim — "Neovim frontend writen by electron."
# https://github.com/tk-shirasaka/envim
#
# - TRIED: Haven't.

# vv — "Neovim client for macOS." Electron.
# https://github.com/vv-vim/vv
# TRIED/2025-01-20: Very similar to `nvim` in terminal.
# - Even cursor icon remains pointer in Insert mode, and doesn't
#   change to I-beam like you see in MacVim or Neovide.
# - BUGGY/2025-01-20: vv uses #!/bin/sh but the script is Bashy.
#   - So run explicitly through Bash:
#     $ bash /opt/homebrew/bin/vv
# - BUGGY/2025-01-20: On :q, throws popup error message:
#     "A JavaScript error occurred in the main process".
#   - Also does not go away on <Cmd-Q> or *Quit VV* [menu].
#     - So kill manually:
#       ps aux | grep vv.vim | awk '{print $2}' | xargs kill -9
if ${BREW_INCLUDE_VV:-false}; then
  brew_app_macos "vv"
fi

# *** Other Editors
#     ^^^^^^^^^^^^^

# "Multiplayer code editor" / "Zed is a next-generation code editor
# designed for high-performance collaboration with humans and AI."
# https://zed.dev/
brew_app_macos "--cask zed"

# TRYME/2025-02-23: See what's all the rage:
if ${BREW_INCLUDE_OBSIDIAN:-false}; then
  brew_app_macos "obsidian"
fi

# windsurf (née Codeium)
# https://windsurf.com/
# https://github.com/Exafunction/windsurf.nvim
brew_app_macos "--cask windsurf"

brew_app_macos "--cask cursor"

# *** Editor-Adjacent
#     ^^^^^^^^^^^^^^^

# https://tree-sitter.github.io/tree-sitter/
brew_app_both "tree-sitter"

# *** Lazyman deps
#     ^^^^^^^^^^^^

if ${BREW_INCLUDE_LAZYMAN_DEPS:-false}; then
  # "Cut, copy, and paste anything, anywhere, all from the terminal"
  # - E.g., can `cb copy` files and directories.
  # https://getclipboard.app/
  # https://github.com/Slackadays/Clipboard
  brew_app_both "clipboard"

  # C/C++/ObjC language server
  # https://github.com/MaskRay/ccls
  brew_app_both "ccls"

  # "convert images into ascii art and print them on the console"
  # https://github.com/TheZoraiz/ascii-image-converter
  # https://github.com/TheZoraiz/homebrew-ascii-image-converter
  brew_app_both "TheZoraiz/ascii-image-converter/ascii-image-converter"

  # "Control nvim processes using `nvr` command-line tool"
  # https://github.com/mhinz/neovim-remote
  # - I think this predates --server CLI arg, or at least
  #   gvim-open-kindness makes it work.
  brew_app_both "neovim-remote"
fi

# --------------------------

# - SAVVY: To view fonts, open Launchpad and run `Font Book`
# - HSTRY/2024-04-14: ==> font-hack-nerd-font: 3.2.1
# - CALSO: See also without Nerd Font:
#     brew_app_macos "--cask homebrew/cask-fonts/font-hack"
brew_app_macos "--cask font-hack-nerd-font"

# Some other text editor/terminal fonts I previewed, but
# not as much to the author's liking as Hack:
#
#   brew_app_macos "--cask font-daddy-time-mono-nerd-font"
#   brew_app_macos "--cask font-intone-mono-nerd-font"
#   brew_app_macos "--cask font-sauce-code-pro-nerd-font"
#
# THOTS/2025-01-31: Monaspice is nice! It's giving Hack a run
# for its money...
# - It's also nice to stare at a slightly different glyph
#   for a change.
#
# https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Monaspace
# https://github.com/githubnext/monaspace
# BEGET: https://github.com/augustocdias/dotfiles/blob/main/.config/alacritty/alacritty.toml
#   https://www.reddit.com/r/neovim/comments/16ug1jf/very_slow_startup_in_macos_sonoma/
brew_app_macos "--cask font-monaspace-nerd-font"

# Unifont adds some glyphs you won't otherwise see on @macOS, like
# the latter half of the *Miscellaneous Symbols and Arrows* block.
# - Note you don't need to explicitly use this font; it just needs
#   to exist and @macOS will fall back on it as necessary.
# https://unifoundry.com/unifont/
# https://formulae.brew.sh/cask/font-gnu-unifont
brew_app_macos "--cask font-gnu-unifont"

# CALSO/2025-03-05: Commit Mono has a nice looking website and customizable downloads.
# https://commitmono.com/

# --------------------------

# SAVVY: "htop requires root privileges to correctly display all running
# processes, so you will need to run `sudo htop`. / You should be certain
# that you trust any software you grant root privileges."
brew_app_macos "htop"

# "Resource monitor. C++ version and continuation of bashtop and bpytop"
# https://github.com/aristocratos/btop
#   https://github.com/aristocratos/bashtop
#   https://github.com/aristocratos/bpytop
brew_app_both "btop"

brew_app_macos "pstree"

brew_app_macos "pidof"

# --------------------------

brew_app_macos "grep"
# 2022-10-17: System `grep` is so much faster than Homebrew `ggrep`.
# - Though I could swear that, circa 2020-21, `ggrep` was speedier!
# - CXREF: See note atop `defaults-domains-dump` that shows when that
#   function uses /usr/bin/grep, it takes 1 sec., but when it uses
#   /opt/homebrew/bin/ggrep, it takes 31 seconds!
# Point being, don't link `ggrep` (and hopefully this doesn't break
# other parts of our environment.
#  user_link_macos "ggrep"

brew_app_macos "ag"

brew_app_macos "rg"

# - The `brew tap aykamko/tag` suggested by the README is incorrect:
#     https://github.com/aykamko/homebrew-tag-ag
#   Because `brew tap <user>/<repo>` is a shortcut to
#           `brew tap <user>/<repo> https://github.com/<user>/homebrew-<repo>`,
#   and there is no https://github.com/aykamko/homebrew-tag project.
# - So this is how you'd install tag-ag:
#     brew_tap_macos "aykamko/tag-ag"
#     brew_app_macos "tag-ag"
#   Alternatively, I think this format (without the tap) also works:
#     brew_app_macos "aykamko/tag-ag/tag-ag"
# - But don't install tag-ag.
#   - 2022-10-17: It worked for me on my previous MacBook (circa 2020-21)
#     but not on my new machine, where I see:
#       $ brew install aykamko/tag-ag/tag-ag
#       $ /opt/homebrew/bin/tag
#       Segmentation fault: 11
# So install from sources instead.
# - CXREF: ~/.depoxy/ambers/home/.kit/go/_mrconfig
#     $ mr -d ~/.depoxy/ambers/home/.kit/go/aykamko-tag install

# REFER:
# https://ast-grep.github.io/
# https://ast-grep.github.io/guide/introduction.html
brew_app_both "ast-grep"

# --------------------------

# *Collection of GNU find, xargs, and locate*
brew_app_macos "findutils"
user_link_macos "gfind"

# *find entries in the filesystem*
brew_app_macos "fd"
# fzf - *a command-line fuzzy finder*
# https://github.com/junegunn/fzf
brew_app_macos "fzf"

# bfs — Breadth-first version of find
# https://tavianator.com/projects/bfs.html
# https://formulae.brew.sh/formula/bfs
brew_app_macos "bfs"

# NCurses Disk Usage
# https://dev.yorhel.nl/ncdu
brew_app_both "ncdu"

# --------------------------

# Some "modern" replacements for 'ls'.
# - Albeit I'm not sure I find these more useful...
#   if anything, the individual colors for the permissions bits
#   and the icon ornamentation is distracting without making it
#   easier or quicker to (visually) consume the output.

# https://github.com/eza-community/eza
# - REFER: Successor to `exa`, which Homebrew dropped support for:
#     "Error: exa has been disbled because it is not maintained upstream!"
# - SAVVY: "Bash completion has been installed to:"
#     /opt/homebrew/etc/bash_completion.d
# - E.g.,
#     eza --icons --long --header
brew_app_macos "eza"

# https://github.com/lsd-rs/lsd
# - SAVVY: "Bash completion has been installed to:"
#     /opt/homebrew/etc/bash_completion.d
# - E.g.,
#     lsd -lhFa --color=always
brew_app_macos "lsd"

# "A smarter cd command."
# https://github.com/ajeetdsouza/zoxide
# CALSO: https://github.com/skywind3000/z.lua
brew_app_both "zoxide"

# --------------------------

# "list contents of directories in a tree-like format."
# ALTLY: You can tree using eza:
#   eza -alT --icons=always
brew_app_macos "tree"

# ranger — "console file manager with VI key bindings"
# https://ranger.fm/
# I'm not much of a file browser person, I `cd` and `ll`
# mostly. But maybe for poking around new code repos or
# something you might appreciate a TUI fs browser.
brew_app_macos "ranger"

# nnn — "n³ The unorthodox terminal file manager"
# https://github.com/jarun/nnn
# ISOFF/2025-02-02: So sophisticated! And yet I don't
# see a use case for me (or at least my workflow).
#
#  brew_app_macos "nnn"

# walk — "Terminal file manager"
# https://github.com/antonmedv/walk
brew_app_both "walk"

# --------------------------

brew_app_macos "less"
# Useful for LESSOPEN, e.g.,
#   LESSOPEN="| highlight %s --out-format xterm256 --force"
brew_app_macos "highlight"

# "Clone of cat(1) with syntax highlighting and Git integration"
brew_app_macos "bat"

# "Rich-cli is a command line toolbox for fancy output in the terminal"
# - Added because a nvim-Lazyman dep, but an interesting tool on its own.
#   - CALSO: pdb + Rich library
#     https://github.com/cansarigol/pdbr
# https://github.com/textualize/rich-cli
brew_app_macos "rich-cli"

brew_app_macos "dhex"

# *Command-line JSON processor*
brew_app_macos "jq"

# "Terminal JSON viewer"
# https://fx.wtf/
# https://github.com/antonmedv/fx
brew_app_both "fx"

# *yq: Command-line YAML/XML/TOML processor - jq wrapper*
#   https://kislyuk.github.io/yq/
# Aka `python-yq`. Installs `yq` and `tomlq` (and prob. `jq`).
#
# - Call tomlq to convert Toml (like .pyproject.toml) to JSON
#   (for plucking values, perhaps).
#     https://kislyuk.github.io/yq/#toml-support
# - See also Go project of same name, but without Toml support:
#     https://github.com/mikefarah/yq/
# - Dasel is another possible utility (I didn't demo it,
#   so not sure how it compares to yq):
#     https://github.com/TomWright/dasel
#     https://daseldocs.tomwright.me/examples/basics
# - Also toml-cli, but installs via Cargo, pass:
#     https://github.com/gnprice/toml-cli
#     https://crates.io/crates/toml-cli
# - This might be the tomlq project the yq uses (albeit
#   this project 5 years stale, so seems unlikely):
#     https://github.com/jamesmunns/tomlq
brew_app_macos "python-yq"

# fzy - Fuzzy finder menu-izer
# https://github.com/jhawthorn/fzy
# - E.g.,
#     declare -a options=(foo bar baz)
#     chosen="$(printf "%s\n" "${options[@]}" | fzy)"
# BEGET:
# https://unix.stackexchange.com/questions/715893/bash-completely-cli-interactive-menu
# - On author's Linux (Debian) hosts, installed via apt.
brew_app_macos "fzy"

# --------------------------

#  # "Perl-powered file rename script with many helpful built-ins"
#  brew_app_macos "rename"

# Already installed:
#  brew_app_macos "unzip"

# --------------------------

# Add gsed, which is more rich than BSD sed.
brew_app_macos "gnu-sed"
user_link_macos "gsed"

# --------------------------

# "GNU implementation of time utility"
brew_app_macos "gnu-time"

# --------------------------

brew_app_macos "wget"

# SAVVY/2024-05-17: @macOS 14.4.1:  "rsync  version 2.6.9  protocol version 29"
#                   @linux LM 21.3: "rsync  version 3.2.7  protocol version 31"
brew_app_macos "rsync"
user_link_macos "rsync rsync"

# --------------------------

# This is "ctags-exuberant".
# - REFER: See also macOS built-in ctags:
#   /Library/Developer/CommandLineTools/usr/bin/ctags
#   /Library/Developer/CommandLineTools/usr/share/man/man1/ctags.1
#
if ${BREW_INCLUDE_OLD_EXUBERANT_CTAGS:-false}; then
  brew_app_macos "ctags"
  user_link_macos "ctags ctags"
fi

# Universal Ctags, a maintained fork of Exuberant Ctags
# - HSTRY/2025-02-12: Ha, new to me, thanks! to
#   https://github.com/preservim/tagbar for the enlightenment
# https://ctags.io/
# - I.e.,
#   brew unlink ctags
#   brew tap universal-ctags/universal-ctags
#   brew install --HEAD universal-ctags
if ! ${BREW_INCLUDE_OLD_EXUBERANT_CTAGS:-false}; then
  brew_tap_macos "universal-ctags/universal-ctags"
  brew_app_macos "--HEAD universal-ctags"
  user_link_macos "ctags ctags"
fi

# --------------------------

# Linux Mint 19.3 `awk` is actually `gawk`, FYI.
# (And I don't see plain `awk` installed; meaning,
#  all my Bash scripts expect `gawk`.)
brew_app_macos "gawk"
user_link_macos "gawk" # Will symlink from ~/.local/bin/awk

# Installs `/opt/homebrew/bin/diff`.
brew_app_macos "diffutils"
# Note that brew's diff is `diff`, not `gdiff`,
# so use a two-word USER_LINK entry.
user_link_macos "diff diff"

# "colordiff — a tool to colorize diff output"
# - Essentially a `diff` wrapper with syntax highlighting.
# https://www.colordiff.org/
# https://github.com/daveewart/colordiff
# - Author has yet to demo colordiff.
#   - See also: diff, git-diff, and meld.
brew_app_macos "colordiff"

# "Good-lookin' diffs. Actually… nah… The best-lookin' diffs. 🎉"
# https://github.com/so-fancy/diff-so-fancy/
# "Good-lookin' diffs with diff-highlight and more"
# https://formulae.brew.sh/formula/diff-so-fancy
brew_app_macos "diff-so-fancy"
user_link_macos "diff-so-fancy diff-so-fancy"

# ISOFF/2024-09-19: Brew has deprecated the since-abandoned macOS Meld package.
# - For now, build and run Meld from sources.
#   - CXREF: For those who run DepoXy:
#       ~/.depoxy/ambers/home/.kit/py/_mrconfig--meld
#     https://github.com/DepoXy/depoxy#🍯
#       https://github.com/DepoXy/depoxy/blob/release/home/.kit/py/_mrconfig--meld
# - Eventually, upstream (GNOME) Meld might release a macOS package
#   (there's currently a macOS asset generated by the pipeline,
#    but it didn't work for the author).
#
#   # NOTE: App is not signed. See our `quarantine-liberate-apps`, or try:
#   #   xattr -dr com.apple.quarantine "/Applications/Meld.app"
#   #
#   # Brew includes a Meld for macOS fork:
#   #   https://github.com/yousseb/meld/
#   #   https://yousseb.github.io/meld/
#   # - It requires Rosetta 2, but from my experience, Rosetta works
#   #   fine, and I'd guess it comes pre-installed, anyway, you just
#   #   need to acknowledge the EULA to use it (so you're not using
#   #   more disk space, i.e.).
#   #   - So we'll install Meld with a default-yes opt-in (which I
#   #     guess makes it an opt-out)
#   if ! ${BREW_EXCLUDE_MELD:-false}; then
#     MACOS_INSTALL_ROSETTA2=true
#
#     brew_app_macos "--cask meld"
#   fi

# P4Merge — Meld alternative, though not quite as slick (it's close).
# https://formulae.brew.sh/cask/p4v
# - SAVVY: Installs more than just P4Merge:
#   - Use Spotlight to run `p4merge.app`, not `p4v.app`
if ${BREW_INCLUDE_P4MERGE:-false}; then
  brew_app_macos "--cask p4v"
fi

# --------------------------

brew_app_macos "direnv"

# --------------------------

# "whois is key-only, which means it was not symlinked into /opt/homebrew,
# because macOS already provides this software and installing another
# version in parallel can cause all kinds of trouble."
brew_app_macos "whois"

# --------------------------

brew_app_macos "cloc"

# --------------------------

# ISOFF/2025-02-23: Requires unlink to install both tldr and tealdeer.
#
#  brew_app_macos "tldr"

# "Very fast implementation of tldr in Rust"
# https://tealdeer-rs.github.io/tealdeer/
brew_app_macos "tealdeer"

# --------------------------

# Just as easily managed from pipx:
#  brew_app_macos "asciinema"

# --------------------------

# Used by Dob plugin, for notification toasts:
#   https://github.com/landonb/dob-plugin-my-post-processor
# - `brew install cowsay` is deprecated:
#   https://formulae.brew.sh/formula/cowsay
# https://github.com/cowsay-org/homebrew-cowsay
# https://github.com/cowsay-org/cowsay
brew_app_macos "cowsay-org/cowsay/cowsay-org"
brew_app_macos "fortune"

# E.g., `/usr/local/bin/terminal-notifier -message "PATH=$PATH"`.
#  https://github.com/julienXX/terminal-notifier
brew_app_macos "terminal-notifier"

# --------------------------

brew_app_macos "restview"

# Big Install:
#  brew_app_macos "grip"

# Markdown GUI editor
# https://macdown.uranusjr.com/
# NOTE: App is not signed. See our `quarantine-liberate-apps`, or try:
#   xattr -dr com.apple.quarantine "/Applications/MacDown.app"
brew_app_macos "macdown"

# Pandoc "a universal document converter"
# https://pandoc.org/
# https://formulae.brew.sh/formula/pandoc
brew_app_macos "pandoc"

# Include `--pdf-engine=xelatex` support, etc.
# - ONBRD: Restart terminal, or reload PATH:
#     eval "$(/usr/libexec/path_helper)"
#     # BWARE: Updating PATH may break some command paths, e.g.,
#     #   # before
#     #   type sed
#     #   sed is /Users/user/.local/bin/sed # -> /opt/homebrew/bin/gsed
#     #   # after
#     #   type sed
#     #   sed is /usr/bin/sed
brew_app_macos "--cask basictex"

# --------------------------

# CXREF: Per its install output, example config and Bash completion:
#   /opt/homebrew/opt/tmux/share/tmux/example_tmux.conf
#   /opt/homebrew/etc/bash_completion.d/tmux
brew_app_macos "tmux"

# Note that some organizations will offer iTerm2 from their app store.
brew_app_macos "iterm2"

# ILIKE/2024-06-23: I'm groovin' on Alacritty so far, simple and elegant.
# - And I think I'm over iTerm2, the immutable nuances are too many.
# - MAYBE/2025-02-23: Change to brew_app_both, and disable custom Debian
#   build in DepoXy project: ~/.depoxy/ambers/home/.kit/rust/_mrconfig
brew_app_macos "--cask alacritty"

# Alacritty does not draw a border, which makes it hard to resize when
# it's overlapping other windows, because you cannot see the corner.
# - Fortunately there's Borders.
brew_tap_macos "FelixKratz/formulae"
brew_app_macos "borders"
# Call `brew services start borders`
service_start_macos "borders"

# https://github.com/kovidgoyal/kitty
brew_app_macos "--cask kitty"

# "GPU-accelerated cross-platform terminal emulator and multiplexer"
# https://wezterm.org/
brew_app_macos "--cask wezterm"

# "Fast, lightweight and minimalistic Wayland terminal emulator"
# https://codeberg.org/dnkl/foot
brew_app_linux "foot"

# https://ghostty.org/
brew_app_macos "--cask ghostty"

# --------------------------

# INERT/2022-10-11: If you find you need Mongo interface.
# - NOTE: On some client machines, you may need to start an
#   *Admin Access* terminal session to install Robo 3T.
#  brew_app_macos "robo-3t"

# --------------------------

brew_app_macos "imagemagick"

# HINT: To remove EXIF data from an image: `exiftool -all= image.jpg`.
brew_app_macos "exiftool"

# *Multithreaded PNG optimizer written in Rust*
# https://github.com/shssoichiro/oxipng
# https://formulae.brew.sh/formula/oxipng
brew_app_macos "oxipng"

# *Versatile and fast Unicode/ASCII/ANSI graphics renderer*
# https://hpjansson.org/chafa/
# - BEGET: Someone's LazyVim dashboard image:
#   https://github.com/folke/snacks.nvim/discussions/111#discussioncomment-11526630
# - E.g.,
#   chafa picture.png --size 50x50
#   chafa picture.png --format symbols --size 50x50
brew_app_both "chafa"

# --------------------------

# Use case: Rotate PDF page(s), esp. helpful to repair scanned docs.
brew_app_macos "qpdf"

# IDGI: Git `log -S` with `--reverse` fails on macOS for want of pdfinfo:
#   $ git --no-pager log -S "some query term" --source -m --reverse
#   error: cannot run pdfinfo: No such file or directory
brew_app_macos "xpdf"

# YIKES: It's 2025, probably don't need this.
# - Also on my ¼TB Mac Mini, space is precious, and this is >500M.
if ${BREW_INCLUDE_ACROBAT_READER:-false}; then
  brew_app_macos "--cask adobe-acrobat-reader"
fi

# --------------------------

# *** Diagramming apps

# Dia: "Draw structured diagrams"
# - Also installs XQuartzx:
#     XQuartz: "An X11 server and client libraries for macOS"
#     brew_app_macos "--cask xquartz"
#
# ISOFF/2024-07-04: I tried Dia (and XQuartz) on @macOS
# but it blips the screen and runs XQuartz, but nothing
# else. Oh, well, I tried. (I enjoy this app on @Linux!)
# - From USAGE above:
#   # Dia requires --cask xquartz (X11 emulator) which requires sudo
#   # and prompts for your password.
#   # - Also you need to *Open Anyway* via macOS Settings because not
#   #   signed (and "not free from malware", says dialog).
#   BREW_INCLUDE_DIA=true
#
#   if ${BREW_INCLUDE_DIA:-false}; then
#     # NOTED: Prompts for PWD:
#     #   ==> Running installer for xquartz with sudo; the password may be necessary.
#     brew_app_macos "--cask dia"
#   fi

# https://www.drawio.com/
# https://formulae.brew.sh/cask/drawio
# - STATS/2024-09-16: 27k installs past 365 days.
# - STATS: Large .tar.gz, 128M
brew_app_macos "--cask drawio"

# https://pencil.evolus.vn/
# https://formulae.brew.sh/cask/pencil
# - STATS/2024-09-16: 566 installs past 365 days.
# - STATS: Large .tar.gz, 170M, also very slow download
#     ls -l ~/Library/Caches/Homebrew/downloads/*Pencil*.dmg
#
# - OPTIN: Pencil download is slow, and you only need one diagramming app,
#   so we'll install draw.io (very popular option) and yed (nice app) and
#   you can opt-in Pencil.
#   - Also draw.io and yed are signed, but Pencil is not signed,
#     so install shows extra prompts and requires System Settings
#     intervention via Privacy & Security unblockage.
if ${BREW_INCLUDE_PENCIL:-false}; then
  brew_app_macos "--cask pencil"
fi

# yEd - graph editor
# https://www.yworks.com/products/yed
# https://formulae.brew.sh/cask/yed
# - STATS/2024-09-16: 904 installs past 365 days.
# - STATS: Large .tar.gz, 153M, also very slow download
# - ILIKE/2024-09-16: Ooooh, this is nice...
brew_app_macos "--cask yed"

# --------------------------

# "Free cross-platform office suite, fresh version"
brew_app_macos "--cask libreoffice"

# --------------------------

# Pure Vanity.
# https://github.com/dylanaraps/neofetch
brew_app_macos "neofetch"

# --------------------------

# SAVVY/2024-04-14: Don't install Homebrew Chrome over corporate
# version, if your laptop already came with Chrome installed.
add_google_chrome_unless_installed() {
  ! [ -e "/Applications/Google Chrome.app" ] ||
    return 0

  brew_app_macos "google-chrome"
}
add_google_chrome_unless_installed

add_firefox_unless_installed() {
  ! [ -e "/Applications/Firefox.app/" ] ||
    return 0

  brew_app_macos "--cask firefox"
}
add_firefox_unless_installed

# https://www.opera.com/
brew_app_macos "--cask opera"
# https://brave.com/

brew_app_macos "--cask brave-browser"

# https://arc.net/
brew_app_macos "--cask arc"

# "A macOS app for customizing which browser to start"
# https://github.com/johnste/finicky
# ISOFF/2025-08-30: I downgraded to manual Finicky v3 because latest v4
# builds have --args regression.
# - TRACK/2025-08-30: *Args [--args] not working on latest version*
#   https://github.com/johnste/finicky/issues/431
if ${BREW_INCLUDE_FINICKY:-false}; then
  brew_app_macos "--cask finicky"
fi

# --------------------------

# Slack might be installed by your organization...

if ! ${BREW_EXCLUDE_SLACK:-false}; then
  brew_app_macos "--cask slack"
fi

if ${BREW_INCLUDE_DISCORD:-false}; then
  # https://discord.com/
  brew_app_macos "--cask discord"
fi

# --------------------------

# SPIKE/2022-10-11: Demo `procps`.
# *Command line and full screen utilities for browsing procfs*
# https://gitlab.com/procps-ng/procps
#  brew_app_macos "procps"

# --------------------------

# - Developer tools

# Golang. Not sure installing system-wide is best idea (is there
# Go environment virtualization like with Python and JS?).
# - But want Go to build aykamko-tag.
brew_app_macos "go"

brew_app_macos "node"
brew_app_macos "yarn"

brew_app_macos "rust"

brew_app_macos "pyenv"
user_link_macos "pyenv pyenv"
# https://github.com/pyenv/pyenv-virtualenv
brew_app_macos "pyenv-virtualenv"

# For `mandb` (used by at least fries-findup's `make install`).
brew_app_macos "man-db"
# If you open Homebrew man pages with Apple man, you'll see an
# error message before the pager starts, e.g.:
#     $ /usr/bin/man /opt/homebrew/share/man/man1/bash.1
#     This manpage is not compatible with mandoc(1) and might display incorrectly.
# - Though you can just as easily redirect to stderr to squelch it.
#
# BWARE: `gman` misbehaves: It prints tilde as accent tilde!
# - E.g., `gman bash` shows:
#     An additional binary operator, =˜, is available, with the same
#     precedence as == and !=.
#   But if you run `/usr/bin/man bash`, you'll see instead:
#     An additional binary operator, =~, is available, with the same
#     precedence as == and !=.
# - I tried some of the formatting options in `man gman` but to no avail.
#   IDGI
#
# ISOFF/2024-10-19: So let's not supercede built-in `man`.
# - We'll change `man` in the terminal to redirect stderr instead.
#
#  user_link_macos "gman"

# Apple `make` is "GNU Make 3.81". Brew's is ≥ 4.4.1.
brew_app_macos "make"

# For dateutils.ddiff, etc.
brew_app_macos "dateutils"
user_link_macos "datediff datediff"

# Ruby
# - @macOS $ /usr/bin/ruby -v
#   ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.arm64e-darwin23]
# - @hbrew $ /opt/homebrew/bin
# REFER:
#   /opt/homebrew/opt/ruby/bin
#   /opt/homebrew/lib/ruby/gems/3.3.0/bin
# Some gems:
#   bashcov
# Caveats:
#   By default, binaries installed by gem will be placed into:
#     /opt/homebrew/lib/ruby/gems/3.3.0/bin
#
#   You may want to add this to your PATH.
#
#   ruby is keg-only, which means it was not symlinked into /opt/homebrew,
#   because macOS already provides this software and installing another version in
#   parallel can cause all kinds of trouble.
#
#   If you need to have ruby first in your PATH, run:
#     echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.profile
#
#   For compilers to find ruby you may need to set:
#     export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
#     export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"
#
#   For pkg-config to find ruby you may need to set:
#     export PKG_CONFIG_PATH="/opt/homebrew/opt/ruby/lib/pkgconfig"
brew_app_macos "ruby"

# SAVVY/2024-11-25: GNU debugger `gdb` doesn't run on macOS, use `lldb` instead:
#   $ brew install gdb
#   gdb: The x86_64 architecture is required for this software.
#   $ lldb -- program <args>
# https://formulae.brew.sh/formula/gdb

# As recommended by Linux Homebrew install.
brew_app_both "gcc"

# https://luarocks.org/
brew_app_both "luarocks"

# "A Lua code formatter"
# https://github.com/JohnnyMorganz/StyLua
brew_app_both "stylua"

# "Language Server for the Lua language" (incl. Lazyman dep, but also
# so you don't have to, e.g., install via :Mason).
# https://github.com/LuaLS/lua-language-server
brew_app_both "lua-language-server"

# https://github.com/astral-sh/uv
# https://docs.astral.sh/uv/
brew_app_both "uv"

# --------------------------

# - DB dev tools

# USYNC/2024-04-13: Must specify Postgres version.
#  https://formulae.brew.sh/formula/postgresql@16
brew_app_macos "postgresql@16"
# MAYBE/2022-11-15:
#   brew services stop postgresql
brew_app_macos "libpq"

# https://www.pgadmin.org/docs/
# - SIZED/2025-02-05: 662M: /Applications/pgAdmin 4.app
# - REFER: pgadmin is uninstallable via its version numbers, e.g.:
#     $ brew uninstall --cask pgadmin4
#     Error: Cask 'pgadmin4' is not installed.
#     $ brew list | grep postgres
#     postgresql@14
#     postgresql@16
#     $ brew list | grep postgres | xargs brew uninstall
if ${BREW_INCLUDE_PGADMIN4:-false}; then
  brew_app_macos "--cask pgadmin4"
fi
# https://github.com/dbeaver/dbeaver
brew_app_macos "--cask dbeaver-community"

# Other db tools:
#   brew_app_both "mysql-client"

# --------------------------

# - API dev tools

brew_app_macos "--cask insomnia"
brew_app_macos "--cask postman"
brew_app_macos "openapi-generator"

# "Modern API client that lives in your terminal"
# https://posting.sh/
# https://github.com/darrenburns/posting
brew_app_both "posting"

# --------------------------

# - Code editors

# brew_app_macos "--cask visual-studio-code"

# 2023-01-06: Not going to the dark side (never leaving Vim for
# anything else) but I am curious if I can find a decent Python
# debugger GUI (mostly so it's easier to inspect variables).
# - Standard Python debug tools:
#   - I current use pdb & pdbr, which are great, but require switching
#     to a terminal window and typing commands, vs., e.g., seeing a
#     list of locals, etc.
# - Python GUI IDEs:
#   - VS Code (might be worth checking out, but difficult for a
#     Vimmer to dive into)
#   - PyCharm (licensed, but not that expensive)
#   - Spyder
#   - LiClipse (has brew install and includes PyDev → easiest route to PyDev)
#   - PyDev (can be installed into Eclipse; and is part of LiClipse)
#       https://www.pydev.org/
#       https://github.com/fabioz/Pydev
#   - Thonny
#   - Wing IDE
#   - eric
#   - Atom

# https://code.visualstudio.com/
# https://formulae.brew.sh/cask/visual-studio-code
# SAVVY: Launch via shell so VS Code resolves your shell properly.
# - E.g., if you use Alacritty and start VS Code from Spotlight,
#   on startup it'll say it timed-out trying to suss the shell.
#     $ open -a /Applications/Visual\ Studio\ Code.app
brew_app_macos "--cask visual-studio-code"

# SPIKE/2023-02-27: Demo LiClipse.
# https://www.liclipse.com/
# https://formulae.brew.sh/cask/liclipse
if ${BREW_INCLUDE_LICLIPSE:-false}; then
  brew_app_macos "--cask liclipse"
fi

# --------------------------

# - Container orchestration systems
#
# Kubernetes is a collection of separate applications, APIs, services, etc.
# - On Linux, you can install the various bits individually, e.g., you
#   could install Docker to build images, you could install containerd
#   to run those images, you could install CNI plugins to configure
#   network interfaces in containers, and you could install kubeadm
#   to manage clusters (the control plane). You'll then need to spin
#   up pods for various tasks: a K8s API server, scheduler, DNS, etcd,
#   etc.
# - You could also install specific tools that include and wire most of
#   these bits for you, e.g., you could install Docker Desktop and enable
#   its Kubernetes plugin, or you could install minikube which manages
#   Kubernetes setup in a VM or docker, or you could install kind or k3d
#   which runs Kubernetes in docker. Or MicroK8s.
#   - These tools can run on macOS, because they use Docker or VMs.
#   - Though note that at least minikube and kind are more for
#     providing a quick and easy development environment and may
#     not be ideal for a production environment. Also note that k3d
#     and MicroK8s target edge and IoT devices (e.g., Raspberry Pi).
# - Also please excuse me if I'm describing anything K8s-related
#   incorrectly. I'm still somewhat of a K8s noob.
#
# REFER:
# https://www.docker.com/products/docker-desktop/
# https://minikube.sigs.k8s.io/docs/
# https://kind.sigs.k8s.io/
# https://k3d.io/v5.7.4/
# https://github.com/k3s-io/k3s
# https://microk8s.io/

# Docker Desktop, a one-stop container orchestration solution.
#   https://www.docker.com/products/docker-desktop/
# - Includes `docker`, `docker-compose`, `kubectl`, and more.
#   - You can enable Docker's Kubernetes via
#       Settings > Kubernetes > Enable Kubernetes
#   - For macOS K8s development, this is probably the easiest solution.
# - Free for personal use — Docker Engine + Kubernetes, Unlimited public
#   repos (on Docker Hub), 200 image pulls per 6 hours, 3 Scout enabled
#   repos, and local Scout analysis (vulnerability detection).
# - I assume you can install Colima (see below) alongside Docker Desktop,
#   but author hasn't tried. If anything, you'll probably have to be
#   careful about paths, because tools will probably be duplicated.
if ${BREW_INCLUDE_DOCKER_DESKTOP:-false}; then
  brew_app_macos "--cask docker"
fi

# Alternatively, you could install Colima.
#   https://github.com/abiosoft/colima
# - Colima is shorthand for *Containers on Lima*.
#   - Lima runs Linux VMs — https://lima-vm.io/
# - My understanding is that Colima launches Docker on Alpine VM, though
#   you could also install Lima separately (though not necessary) to run
#   containered on Ubuntu VM.
#   - REFER: https://www.dae.mn/blog/docker-in-mac-m1/m2-colima
# - Note that Docker Desktop on macOS also runs using virtual machines.
# BWARE: The author only briefly tried Colima in 2023, and I didn't
# get very far until I gave up, uninstalled these components, and
# switched to Docker Desktop. (I was also very fresh to K8s back then.)
if ${BREW_INCLUDE_COLIMA:-false}; then
  # Except for `colima`, Docker Desltop installs each of these apps
  # (and a few more) and symlinks them all from homebrew/bin.
  # - I'm not sure the apps list here is complete. This is just what
  #   I could find when I snooped around Docker Desktops application
  #   folder, specifically:
  #     /Applications/Docker.app/Contents/Resources/bin
  #     /Applications/Docker.app/Contents/Resources/cli-plugins/

  brew_app_macos "docker"
  # Included with `docker`:
  #  brew_app_macos "docker-completion"

  brew_app_macos "docker-compose"
  # SKIPD: "disabled because it no upstream support for v2!" [sic]
  #  brew_app_macos "docker-compose-completion"

  brew_app_macos "docker-credential-helper"

  # Install `kubectl`.
  # https://kubernetes.io/docs/reference/kubectl/
  # https://formulae.brew.sh/formula/kubernetes-cli
  # - Same formula (alias) as `brew install kubectl`.
  brew_app_macos "kubernetes-cli"

  # "Container runtimes on MacOS (and Linux) with minimal setup".
  brew_app_macos "colima"
fi

# - Docker and k8s GUIs/TUIs
#

# k9s: "Kubernetes CLI To Manage Your Clusters In Style!"
# https://k9scli.io/
# https://formulae.brew.sh/formula/k9s
brew_app_macos "k9s"

# https://monokle.io/
# https://github.com/kubeshop/monokle
# https://formulae.brew.sh/cask/monokle
# - *Monokle vs. Lens vs. K9s*
#   https://medium.com/kubeshop-i/monokle-vs-lens-vs-k9s-1d5d94d84b5c
brew_app_macos "--cask monokle"

# https://k8slens.dev/
# https://formulae.brew.sh/cask/lens
# HSTRY/2024-11-15: Years ago, you could build a free (community) version
# of Lens from source — but that project, OpenLens, is now frozen. Lately,
# you can install the proprietary desktop version and use a free license
# for personal use — though requires an account:
#   https://app.k8slens.dev/
# - ONICE: Lens Personal is free "for individuals or companies
#          with < $10M annual revenue or funding* (that's me!).
# REFER: You can find Lens configuration in the expected location:
#   ~/Library/Application Support/Lens/
brew_app_macos "--cask lens"

# "The lazier way to manage everything docker"
# https://github.com/jesseduffield/lazydocker
# https://formulae.brew.sh/formula/lazydocker
# - SAVVY: Note that using GH path clones repo, which should stay more
#   current than the Homebrew formula (`brew install lazydocker`), e.g.,
#     $ brew install jesseduffield/lazydocker/lazydocker
#     ...
#     ==> Tapping jesseduffield/lazydocker
#     Cloning into '/opt/homebrew/Library/Taps/jesseduffield/homebrew-lazydocker'...
#     # Or on Linux:
#     # Cloning into '/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/jesseduffield/homebrew-lazydocker'...
brew_app_both "jesseduffield/lazydocker/lazydocker"

# - Container runtimes
#
# Common container runtimes include:
#   containerd      (Backed by Docker; Docker's default CRI impl.)
#   CRI-O           (Backed by RedHat; RedHat's default CRI impl.)
# Old container runtimes:
#   Docker Engine   (Using cri-dockerd; replaces deprecated dockershim)
#   Mirantis Container Runtime (Commercially supported Docker Engine)
# See also:
#   Colima          (See notes above)
#     https://github.com/abiosoft/colima
#   Incus (sorta a K8s alternative which supports OCI app containers)
#     https://linuxcontainers.org/incus/
#
# REFER:
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#
# CXREF: On Linux, you can install containerd directly.
# - See author's ansible-role-docker fork that adds K8s:
#   https://github.com/geerlingguy/ansible-role-docker
#
# On macOS, Docker Desktop and Colima wrap their own container runtime.

# - Container runtime CLIs
#
#
# Popular container runtime CLIs:
#   ctl       — CLI included with containerd.io (Linux package).
#               https://github.com/containerd/containerd/tree/main/cmd/ctr
#               - A low-level tool meant for debugging more than mgmt.
#   crictl    — Designed for CRI-compatible container runtimes.
#               https://github.com/kubernetes-sigs/cri-tools/blob/HEAD/docs/crictl.md
#               https://github.com/containerd/containerd/blob/HEAD/docs/cri/crictl.md
#   nerdctl   — "contaiNERD CTL"

# "nerdctl: Docker-compatible CLI for containerd"
# https://github.com/containerd/nerdctl
# SAVVY: macOS support is via Lima VM project instead:
#     brew install lima
# - REFER: https://github.com/containerd/nerdctl?tab=readme-ov-file#macos
#   https://github.com/lima-vm/lima
brew_app_linux "nerdctl"

# - K8s configuration tools
#

# Helm manages Charts, packages of pre-configured Kubernetes resources.
# https://github.com/helm/helm
# AFAIK: Helm = Docker Image (w/ CMD -- is that Dockerfile, essentially?) + kubectl patches
brew_app_macos "helm"

# "Kubernetes native configuration management"
# https://kustomize.io/
# "Customization of kubernetes YAML configurations"
# https://github.com/kubernetes-sigs/kustomize
# "Template-free customization of Kubernetes YAML manifests"
# https://formulae.brew.sh/formula/kustomize
brew_app_macos "kustomize"

# https://skaffold.dev/
# "Easy and Repeatable Kubernetes Development"
# https://formulae.brew.sh/formula/skaffold
brew_app_macos "skaffold"

# - Assorted containerization apps
#

# "GitOps Continuous Delivery for Kubernetes"
# https://argo-cd.readthedocs.io/en/stable/
brew_app_macos "argocd"

# Packer creates machine images.
# https://www.packer.io/
brew_tap_macos "hashicorp/tap"
brew_app_macos "hashicorp/tap/packer"

# "⎈ Multi pod and container log tailing for Kubernetes --
#  Friendly fork of https://github.com/wercker/stern"
# https://github.com/stern/stern
brew_app_macos "stern"

# --------------------------

# - VirtualBox
#

if ${BREW_INCLUDE_VIRTUALBOX:-false}; then
  # This is still the Intel version:
  #   brew_app_macos "--cask virtualbox"
  # Here's the Apple Silicon version.
  # - SAVVY: Prompts for PWD.
  brew_app_macos "--cask virtualbox@beta"
fi

# --------------------------

# - Crypto:

# Security stuff.
brew_app_macos "openssl"

brew_app_macos "pass"

brew_app_macos "pwgen"

# https://formulae.brew.sh/formula/pinentry-mac
# https://github.com/GPGTools/pinentry
brew_app_macos "pinentry-mac"

# I had previously installed `gocryptfs` for various DX environment use,
# but Homebrew complains about it now, ever since macFUSE (osxfuse) went
# closed-source, because Homebrew discourages closed-source formulae.
# - But if you can get by with simple password-protected encrypted files
#   instead, consider `gpg -o <output> --cipher-algo AES256 -c <input>`.
# - I also had an issue on my old (Intel) MacBook if I left a `gocryptfs`
#   drive continuously mounted: Every so often, the cursor would start
#   beach-balling, and the machine would be unresponsive for a minute or
#   so. Very annoying, and not obviously related to gocryptfs (the only
#   reason I think it was related is because that problem never happened
#   when I didn't have a `gocryptfs` drive mounted).

# --------------------------

# - Sniffing:

if ${BREW_INCLUDE_WIRESHARK:-false}; then
  brew_app_macos "--cask wireshark"
fi

# "HTTP load testing application written in Rust"
# https://github.com/fcsonline/drill
# https://formulae.brew.sh/formula/drill
brew_app_macos "drill"

# --------------------------

# - macOS Desktop Applications and Extensions:

# SAVVY/2024-04-24: On @macOS Sonoma, Apple shows an icon in the menu bar
# when AltTab is recording. Which is annoying. There is a work-around:
#   https://github.com/lwouis/alt-tab-macos/issues/2606
# - INERT: The author sets menu bar to auto-hide, so doesn't bother me.
brew_app_macos "--cask alt-tab"

# Alt-click-drag any desktop window to move it, like in Linux!
# NOTE: App is not signed. See our `quarantine-liberate-apps`, or try:
#   xattr -dr com.apple.quarantine "/Applications/Easy Move+Resize.app"
brew_app_macos "--cask easy-move-plus-resize"

# Sweet window utility.
#  https://rectangleapp.com/
#  https://github.com/rxhanson/Rectangle
brew_app_macos "--cask rectangle"

# 2022-10-16: GhostTile won't hide Finder, nor Pulse Secure, and I've got
# nothing else I want to hide, so not useful to me (with my latest client
# machine).
# - In the past I used it to keep Cisco AnyConnect out of the Dock
#   (which I could access from the menu bar, and only needed to run
#   once a day, so was otherwise wasting valuable Dock real estate).
#
#  brew_app_macos "--cask ghosttile"

# ISOFF/2024-07-24: I've replicated the Contexts Search menu (<Cmd-Space>)
# and the Sidebar pop-out tray using Hammerspoon (at <Cmd-Space>), so this
# (proprietary, monetarily licensed) application no longer needed.
#
# - CXREF: https://github.com/DepoXy/macOS-Hammyspoony#🥄
#
#   # Ctrl-space shows fuzzy-find-enabled window list menu.
#   #   https://contexts.co/
#   # - Author has been looking for something like MATE's window-list
#   #   that I can use to quickly access specific windows with the mouse.
#   #   - Mission Control sorta works, but users can order window-list how
#   #     they like, so you can find a window just knowing where it "lives"
#   #     in the mate-panel window-list.
#   #   - Contexts is obviously different than window-list, but it shows a
#   #     compact, concise list of windows labeled and ordered well enough
#   #     to make it easy to find what I'm looking for — and allows me to
#   #     click to open or to use the keyboard. Which is what I'm looking
#   #     for, a convenient window switcher different than Alt-Tab,
#   #     different than Mission Control, different than the Dock, etc.
#   # - USAGE: Run Contexts.app via Spotlight to install it — Enable
#   #   Accessibility permissions, and wire to auto-start on boot.
#   #   - Also run Contexts via Spotlight to open its settings GUI —
#   #     because that window hides when it loses focus — or use
#   #     the Contexts <Ctrl+Space> menu to raise the hidden window.
#   brew_app_macos "--cask contexts"

# --------------------------

# 2022-12-04: lsusb (from Linux sources).
# - REFER: macOS alternatives:
#     ioreg -p IOUSB -l -w 0
#     system_profiler SPUSBDataType
# - CXREF: https://stackoverflow.com/questions/17058134/
#             is-there-an-equivalent-of-lsusb-for-os-x
brew_app_macos "mikhailai/misc/usbutils"

# --------------------------

# skhd "is a simple hotkey daemon for macOS"
#   https://github.com/koekeishiya/skhd
# - And not just "simple", wicked easy to configure, just save
#   the config and your new bindings and changes take effect!
#   (Seriously, KE, this is how you should do it!)
brew_app_macos "koekeishiya/formulae/skhd"
# I.e., call `skhd --start-service` after brew-install.
post_eval_macos "skhd --start-service"

# Hammerspoon is a Lua-powered desktop automation application.
#   https://www.hammerspoon.org/
#   https://www.hammerspoon.org/Spoons/
# - Config-based setup makes it easier to edit your keybindings:
#   just edit and save your config, and Hammerspoon immediately
#   reloads.
# - Installs both /Applications/Hammerspoon.app and `hs` to PATH,
#   e.g., `/opt/homebrew/bin/hs`.
# - HSTRY: Author previously used Karabiner Elements (KE).
#   - See KE notes elsewhere in this file.
brew_app_macos "--cask hammerspoon"

# --------------------------

# Opt-in because not dev-related, well, maybe ever dev
# rocks out, but maybe not from the Vendor's equipment.
if ${BREW_INCLUDE_SPOTIFY:-false}; then
  brew_app_macos "--cask spotify"
fi

# Similarly for other media apps, opt-in, so you're not "polluting"
# a vendor machine with non-work related apps.

if ${BREW_INCLUDE_MEDIA_PLAYERS:-false}; then
  # mpv *a free, open source, and cross-platform media player*, CLI player
  # https://mpv.io/
  # https://mpv.io/installation/
  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/m/mpv.rb
  # https://formulae.brew.sh/formula/mpv
  # - "Media player based on MPlayer and mplayer2"
  # SIZED/2024-10-12: 453 MB
  brew_app_macos "mpv"

  # https://www.videolan.org/vlc/
  # See also VLC Remote: https://formulae.brew.sh/cask/vlc-setup
  # SIZED/2024-10-12: 188 MB
  brew_app_macos "--cask vlc"
fi

if ${BREW_INCLUDE_SMPLAYER:-false}; then
  # "SMPlayer is a graphical user interface (GUI) for the award-winning MPlayer"
  # https://www.smplayer.info/en/mplayer
  # http://www.mplayerhq.hu/design7/info.html
  # https://formulae.brew.sh/cask/smplayer
  # - Requires Rosetta 2
  MACOS_INSTALL_ROSETTA2=true
  # SIZED/2024-10-12: 21 MB
  # - SIZED/2025-02-05: /Applications/SMPlayer.app is 152M
  brew_app_macos "--cask smplayer"
fi

if ${BREW_INCLUDE_ELMEDIA_PLAYER:-false}; then
  # MP3 player
  # https://www.elmedia-video-player.com/mp3-player-mac.html
  # https://formulae.brew.sh/cask/elmedia-player
  brew_app_macos "--cask elmedia-player"
fi

if ${BREW_INCLUDE_OBS:-false}; then
  # "Free and open source software for video recording and live streaming."
  # - Open Broadcaster Software
  # https://obsproject.com/
  brew_app_macos "--cask obs"
fi

# --------------------------

if ${BREW_INCLUDE_DROPBOX:-false}; then
  brew_app_macos "--cask dropbox"
fi

# --------------------------

# Team collaboration applications.
#
# https://en.wikipedia.org/wiki/Comparison_of_web_conferencing_software

# REFER: See MS Teams & Zoom, above, which require admin access,
# so installed earlier.

# Webex (Cisco).
# https://webex.com/
# https://formulae.brew.sh/cask/webex
if ${BREW_INCLUDE_WEBEX:-false}; then
  brew_app_macos "--cask webex"
fi

# --------------------------

# Silly, though maybe you'll find a compelling use case (pomadoro?).
# https://github.com/antonmedv/countdown
# USAGE: E.g., `countdown 5s && confetty`
#   https://github.com/Handfish/confetty_rs
# - Or `countdown 17:00`, `countdown -up 30s`.
brew_app_both "countdown"

# --------------------------

# https://www.geekbench.com/
# https://formulae.brew.sh/cask/geekbench
if ${BREW_INCLUDE_GEEKBENCH:-false}; then
  brew_app_macos "--cask geekbench"
fi

# --------------------------

# - Rosetta 2 apps

if ${BREW_INCLUDE_DIGIKAM:-false}; then
  MACOS_INSTALL_ROSETTA2=true

  brew_app_macos "--cask digikam"
fi

if ${BREW_INCLUDE_GNUCASH:-false}; then
  MACOS_INSTALL_ROSETTA2=true

  # Prompts PWD.
  brew_app_macos "--cask gnucash"
fi

# --------------------------

if ${BREW_INCLUDE_TRANSMISSION:-false}; then
  brew_app_macos "--cask transmission"
fi

# --------------------------

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

TESTED_ONCE_BREW_LIST_FALSE=false

TESTED_ONCE_BREW_INFO_FALSE=false

stub_external_commands_if_unit_testing() {
  if ! ${DRY_RUN:-false}; then

    return
  fi

  function brew() {
    if [ "$1" = "list" ] &&
      ! ${TESTED_ONCE_BREW_LIST_FALSE} &&
      [ -x "${BREW_PATH}" ] \
      ; then
      TESTED_ONCE_BREW_LIST_FALSE=true

      ${BREW_PATH} "$@"
    elif [ "$1" = "info" ] &&
      ! ${TESTED_ONCE_BREW_INFO_FALSE} &&
      [ -x "${BREW_PATH}" ] \
      ; then
      TESTED_ONCE_BREW_INFO_FALSE=true

      ${BREW_PATH} "$@"
    else
      case $1 in
      install | tap | link | services | list | info)
        >&2 echo "STUBD: brew $@"
        ;;

      --repository | shellenv)
        if [ -x "${BREW_PATH}" ]; then
          ${BREW_PATH} "$@"
        else
          >&2 echo "STUBD: brew $@"
        fi
        ;;

      *)
        >&2 echo "STUBX: brew $@"
        ;;
      esac
    fi
  }

  function ln() {
    echo "STUBD: ln $@"
  }

  function softwareupdate() {
    echo "STUBD: softwareupdate $@"
  }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Homebrew/install docs suggests installing via curl:
#   /bin/bash -c "$( \
#     curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
#   )"
# - Which uses the following options:
#     -f, --fail / (HTTP) Fail with error code 22 and with no response body output
#                  at all for HTTP transfers returning HTTP response codes ≥ 400.
#     -s, --silent / Silent or quiet mode. Do not show progress meter or error msgs.
#                    Makes Curl mute. It still outputs the data you ask for....
#     -S, --show-error / When used with -s, ... show an error message if it fails.
#     -L, --location / (HTTP) If the server reports that the requested page has moved to
#                      a different location..., ... redo the request on the new place.
# But rather than curl it, we'll keep a local copy under deps/.
# - If you've setup a DepoXy environment, you'll find that project cloned locally at:
#     ~/.kit/odd/homebrew/install
# - And you can keep it up to date within this project thusly:
#     cd ~/.kit/odd/homebrew/install &&
#       git pull
#     cd ~/.kit/mOS/macOS-onboarder &&
#       mr -d . -n updateDeps

BREW_PATH=""

install_homebrew() {
  print_hr

  BREW_PATH="$(print_homebrew_path)"

  if [ -n "${BREW_PATH}" ] && [ -e "${BREW_PATH}" ]; then
    echo "Install: Homebrew is already installed"
    echo

    return 0
  fi

  if [ -n "${HOMEBREW_PREFIX}" ]; then
    echo "Hrmmm: HOMEBREW_PREFIX set (${HOMEBREW_PREFIX}) but Homebrew not installed"
  fi

  echo "Install: Homebrew"
  echo

  $(${DRY_RUN:-false} && echo "echo STUBD:") \
    "$(dirname -- "$0")/../deps/Homebrew/install/install.sh"

  BREW_PATH="$(print_homebrew_path)"

  echo "Installed Homebrew to: ${BREW_PATH}"
  echo
}

# ***

# USYNC: See DXY's `_depoxy_print_homebrew_path`:
#   https://github.com/DepoXy/depoxy#🍯
#     ~/.depoxy/ambers/core/brewskies.sh
#   https://github.com/DepoXy/depoxy/tree/HEAD/core/brewskies.sh
print_homebrew_path() {
  local brew_path=""

  # On Apple Silicon (arm64/AArch64) Macs (M1, M2, etc.) it's /opt/homebrew
  # - ALTLY: [ "$(uname -m)" = "arm64" ]
  [ -x "${brew_path}" ] || brew_path="/opt/homebrew/bin/brew"

  # On Intel Macs it's under /usr/local (tho deprecated)
  [ -x "${brew_path}" ] || brew_path="/usr/local/bin/brew"

  # On Linux, it's under /home (although there's no 'linuxbrew' account)
  [ -x "${brew_path}" ] || brew_path="/home/linuxbrew/.linuxbrew/bin/brew"

  [ -x "${brew_path}" ] || brew_path=""

  printf "%s" "${brew_path}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: Rosetta 2 installs instantaneously (so probably nothing
#        downloaded, more about agreeing to the license).
# - And you can ignore an error like this, or at least digiKam and
#   GnuCash still work:
#     2024-07-04 22:36:59.181 softwareupdate[3570:105238108] Package Authoring Error:
#       062-01890: Package reference com.apple.pkg.RosettaUpdateAuto is missing installKBytes attribute

install_rosetta_2_maybe() {
  if ! os_is_macos || ! ${MACOS_INSTALL_ROSETTA2:-false}; then

    return 0
  fi

  # Aka /usr/sbin/softwareupdate
  softwareupdate --install-rosetta --agree-to-license
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

init_homebrew_or_exit() {
  # Aka: "${HOMEBREW_PREFIX}/bin/brew"
  BREW_PATH="$(print_homebrew_path)"

  if [ ! -e "${BREW_PATH}" ]; then
    if ${DRY_RUN:-false}; then
      >&2 echo "IGNOR: Missing Homebrew."

      return
    fi

    >&2 echo "ERROR: Missing Homebrew."

    exit_1
  fi

  eval "$(${BREW_PATH} shellenv)"
}

brew_install_taps() {
  init_homebrew_or_exit

  local brew_repo="$(brew --repository)"
  # On macOS:
  #   /opt/homebrew/Library/Taps/
  # On Linux:
  #   /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/
  local taps_dir="${brew_repo}/Library/Taps"

  local brew_tap

  for brew_tap in "${BREW_TAPS[@]}"; do
    # Homebrew appears to lowercase the user name (at least author assumes
    # it's Homebrew and not the project config).
    local tap_user="$(echo "${brew_tap}" | cut -d "/" -f1 | tr "[:upper:]" "[:lower:]")"
    local tap_repo="$(echo "${brew_tap}" | cut -d "/" -f2)"
    local local_tap="${taps_dir}/${tap_user}/homebrew-${tap_repo}"

    print_hr
    if [ -d "${local_tap}" ]; then
      echo "Brew tap: ${brew_tap} is already tapped"
      echo

      continue
    fi

    echo "Brew tap: ${brew_tap}"
    echo

    brew tap ${brew_tap}

    echo
  done
}

brew_install_apps() {
  init_homebrew_or_exit

  local brew_app_or_cask

  for brew_app_or_cask in "${BREW_APPS[@]}"; do
    print_hr
    # Note that `brew info` shows info about any match, installed or not,
    # whereas `brew list` only shows info if the formula or cask is installed.
    if brew list ${brew_app_or_cask} >/dev/null 2>&1; then
      echo "Brew install: ${brew_app_or_cask} is already installed"
      echo

      brew info ${brew_app_or_cask} | print_Caveats && echo || true

      # When unit testing, stub `brew info` after running it once for real
      # (and because pipe, `brew info` ran in subprocess).
      TESTED_ONCE_BREW_INFO_FALSE=true

      continue
    fi

    echo "Brew install: ${brew_app_or_cask}"
    echo

    brew install ${brew_app_or_cask}

    echo
  done
}

brew_link_apps() {
  init_homebrew_or_exit

  local brew_link

  for brew_link in "${BREW_LINK[@]}"; do
    print_hr

    echo "Brew link: ${brew_link}"
    echo

    brew link ${brew_link}

    echo
  done
}

brew_start_services() {
  init_homebrew_or_exit

  local brew_svc

  for brew_svc in "${BREW_SVCS[@]}"; do
    print_hr

    echo "Start service: ${brew_svc}"
    echo

    brew services start ${brew_svc}

    echo
  done
}

post_brew_evals() {
  local eval_cmd

  for eval_cmd in "${POST_EVAL[@]}"; do
    print_hr

    echo "Run command: ${eval_cmd}"
    echo

    $(${DRY_RUN:-false} && echo "echo STUBD:") \
      eval "${eval_cmd}"

    echo
  done
}

print_Caveats() {
  awk '
    BEGIN {
      show_line = 0;
      found_caveats = 1;
    }

    {
      if ($0 ~ /^==> Caveats/) {
        show_line = 1;
        found_caveats = 0;
      }
      else if ($0 ~ /^==>/) {
        show_line = 0;
      }
    }

    show_line == 1 {
      print
    }

    END {
      exit found_caveats;
    }
  ' | tac | awk 'NF {p=1} p' | tac
  # ↑ Reverse output, trim leading empty lines, and reverse again
  #   to trim trailing empty lines.

  return ${PIPESTATUS[0]}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

create_user_local_bin_symlinks() {
  init_homebrew_or_exit

  local homebrew_bin="${HOMEBREW_PREFIX}/bin"

  local user_local_bin="${HOME}/.local/bin"

  local before_cd="$(pwd -L)"

  mkdir -p "${user_local_bin}"
  cd "${user_local_bin}"

  [ -d "${homebrew_bin}" ] || (
    >&2 echo "ERROR: Where's Homebrew bin? It's not at: ${homebrew_bin}" &&
      return 1 # Because set -e, dies.
  )

  for gbrew_app in "${USER_LINK[@]}"; do
    gbrew_symlink "${gbrew_app}"
  done

  echo

  cd "${before_cd}"
}

# Not all Homebrew apps we link start with a 'g', so code specifies
# USER_LINK as either one word or two.
# - One word:  E.g., "gdate"     — Symlinks ~/.local/bin/gdate → homebrew/bin/date
# - Two words: E.g., "diff diff" — Symlinks ~/.local/bin/diff  → homebrew/bin/diff
gbrew_symlink() {
  # If two words were specified (as one string), use `set` to split them.
  set -- $1
  local brew_app="$1"
  local bin_name="$2"

  local brew_path="${homebrew_bin}/${brew_app}"

  if [ ! -x "${brew_path}" ]; then
    >&2 echo "ERROR: Specified app not there or not executable: ${brew_path}"

    return 1 # Because set -e, dies.
  fi

  if [ -z "${bin_name}" ]; then
    bin_name="$(echo "${brew_app}" | sed 's/^g//')"
  fi

  echo "Symlinking: Wiring executable: ${brew_app} → ${bin_name}"

  ln -sf "${homebrew_bin}/${brew_app}" "${bin_name}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

print_hr() {
  echo "🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

os_is_macos() {
  [ "$(uname)" = 'Darwin' ]
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

  stub_external_commands_if_unit_testing

  install_homebrew

  install_rosetta_2_maybe

  brew_install_taps
  brew_install_apps
  brew_link_apps
  brew_start_services
  post_brew_evals

  create_user_local_bin_symlinks

  echo "Pizza!"

  clear_traps
}

# Run the installer iff being executed.
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
  main "$@"
else
  >&2 echo "Try running this script instead"
fi

# USAGE: Uncomment 'echo' lines below and source file to see
#        default BREW_APPS count (it won't include opt-in apps).
#
#   # 2023-02-27: Today's count: 74 apps.
#   # 2024-11-14: Today's count: 102 apps, 3 taps.
#   $ . bin/install-homebrew.sh
#   No. BREW_APPS: 102
#   No. BREW_TAPS: 3
#
#  echo "No. BREW_APPS: ${#BREW_APPS[@]}"
#  echo "No. BREW_TAPS: ${#BREW_TAPS[@]}"
