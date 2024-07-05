#!/usr/bin/env bash
# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# https://github.com/DepoXy/macOS-onboarder#🏂
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
#
# A few apps allow opt-in or opt-out via arg ENVIRONs.
# - There's not much sense to add CLI args to opt-in/out
#   every app; you might as well just fork the repo and
#   make it your own.
#
# OPT-OUTS: (e.g., if your Vendor installs this app for you):
#
#   BREW_EXCLUDE_SLACK=true
#
# OPT-INS: (more niche stuff you might not care about):
#
# . # Virtualization tools
#   BREW_INCLUDE_COLIMA=true
#   BREW_INCLUDE_DOCKER_DESKTOP=true
#   BREW_INCLUDE_VIRTUALBOX=true
#
#   BREW_INCLUDE_SPOTIFY=true
#
#   BREW_INCLUDE_DIGIKAM=true
#   BREW_INCLUDE_GNUCASH=true

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

declare -a BREW_TAPS=()
declare -a BREW_APPS=()

# Array for `brew link` actions (this script doesn't have any).
declare -a BREW_LINK=()

# Array for `brew services start` actions.
declare -a BREW_SVCS=()

# USER_LINK is used to add symlinks under ~/.local/bin
declare -a USER_LINK=()

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# BWARE/2023-02-27: This script untested since recent changes
#                   while author awaits new macOS device.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# USAGE: Add your preferred Brew formula and tasks to the BREW_APPS array.
#
#        But please put *PROMPTY* formula and casks *first*.
#
#        - Some installs require the admin password, and we want
#          to nab the user's attention only when they first run
#          this script, and not when they return 5 minutes later
#          after a tea break to find the script paused for input.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# BWARE: These install(s) prompt the user! **PROMPTY**

# Karabiner Elements: *Powerful* keyboard customization
# - PROMPTS: Requires admin password.
# - CALSO: See also Hammerspoon automator (installed below).
BREW_APPS+=("--cask karabiner-elements")

# --------------------------

# - ADMIN: On some client machines, you may need to start an
#   *Admin Access* terminal session to install GIMP.
#   - So this command is potentially **PROMPTY**.
# - F_Y_I: There's also McGIMP [BREW_APPS+=("--cask mcgimp")]
#   - It's a user compile with additional plugins, include G’MIC,
#     Google’s NIC collection, and a panoramic stitcher.
#       https://techtips101.wordpress.com/2017/10/05/mcgimp-gimp-gmic-more/
#     So unlikely you'll care unless you're a GIMP power user.
BREW_APPS+=("--cask gimp")

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

BREW_APPS+=("bash")
# v1: "Programmable completion for Bash 3.2"
#      https://formulae.brew.sh/formula/bash-completion
#        BREW_APPS+=("bash-completion")
# v2: "Programmable completion for Bash 4.2+"
#      https://formulae.brew.sh/formula/bash-completion@2
BREW_APPS+=("bash-completion@2")

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
BREW_APPS+=("readline")

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
BREW_APPS+=("coreutils")
USER_LINK+=("gcp")
USER_LINK+=("gdate")
USER_LINK+=("gdu")
# SAVVY/2024-05-26: Here we symlink ~/.local/bin/ls -> /opt/homebrew/bin/gls
# - Note that Homefries adds `alias ls='/opt/homebrew/bin/gls ...'
#   but this symlink used if user runs `command ls`.
# - If user wants to print macOS ACL details, then can use /bin/ls, e.g.,
#     /bin/ls -led ~/.Trash
USER_LINK+=("gls")
USER_LINK+=("gmktemp")
USER_LINK+=("gsort")
USER_LINK+=("gtouch")
USER_LINK+=("gwc")
USER_LINK+=("grealpath")

# --------------------------

# Don't bother with Brew git.
# - macOS releases git regularly, though not as fast as Brew.
#   - So you're not missing anything sticking with macOS git.
# - Brew git is agonizingly slow running custom commands (like
#   those found in https://github.com/landonb/git-smart,
#   or https://github.com/landonb/git-my-merge-status).
# - If you do install it, I'd advise against linking it:
#     # USER_LINK+=("git git")
#   And I'd suggest sticking with system git, e.g.,
#     ln -s /usr/bin/git ~/.local/bin/git
#
#  BREW_APPS+=("git")

# tig is my all-time favorite git history viewer and staging tool.
BREW_APPS+=("tig")

# gitk was my old favorite git history viewer, before I found tig. But gitk
# is a slower GUI application when compared to the screaming-fast tig TUI.
# And it's especially slow on macOS (obviously not Cocoa), and not much fun.
#
#  BREW_APPS+=("git-gui")

# GitHUB CLI.
BREW_APPS+=("gh")

# Supercharged `git rebase -i`. Beautiful, obscure tool... though I admit
# I most often just use EDITOR (vim) to edit rebase todos. Though maybe if
# I took the time to memorize this tool's key bindings I'd use it oftener.
# - Often wired via ~/.gitconfig: sequence.editor=interactive-rebase-tool
BREW_APPS+=("git-interactive-rebase-tool")

# IDGI: Git `log -S` with `--reverse` fails on macOS for want of pdfinfo:
#   $ git --no-pager log -S "some query term" --source -m --reverse
#   error: cannot run pdfinfo: No such file or directory
BREW_APPS+=("xpdf")

# --------------------------

# If you install MacVim from the formula, you'll see:
#   $ brew install macvim
#   Warning: Treating macvim as a formula. For the cask, use homebrew/cask/macvim
# But an article I read says not to install from the cask:
#   "It is important to have installed macvim from brew directly, and not the cask,
#    or otherwise the vi command will not be changed to the new vim."
#   https://iscinumpy.gitlab.io/post/setup-a-new-mac/#vim
# Note there are multiple MacVim installation options, e.g.,
#   BREW_APPS+=("macvim")
#   BREW_APPS+=("--cask macvim")
#   BREW_APPS+=("macvim --HEAD")
# 2022-10-11: Trying from cask. Not sure the difference between the cask
# and the formula, other than the warning you see if you install from the
# formula. And I checked, and /opt/homebrew/bin/vi, which is a symlink to
# MacVim, is earlier in PATH than /usr/bin/vi, so I don't see the issue
# that Henry Schreiner (setup-a-new-mac article from 2019) documented.
BREW_APPS+=("--cask macvim")

# Remember that DepoXy puts Homebrew after `/usr/bin` in PATH, to avoid
# some (usually slowness) issues with Homebrew apps, so macOS vim, which
# lacks Python3 support, among other deficiencies (my colors appear muted),
# remains wired unless we supercede from ~/.local/bin.
# - If you don't do this, running CLI Vim shows errors when loading:
#     Error detected while processing
#       /Users/user/.vimrc[14]../Users/user/.vim/plugin/dubs_preloads.vim:
#     line   74:
#     E518: Unknown option: macmeta
#   And:
#     Python3 is required when g:easyescape_timeout < 2000
#     Press ENTER or type command to continue
USER_LINK+=("view view")
USER_LINK+=("vim vim")
USER_LINK+=("vimdiff vimdiff")

# --------------------------

# - SAVVY: To view fonts, open Launchpad and run `Font Book`
# - HSTRY/2024-04-14: ==> font-hack-nerd-font: 3.2.1
# - CALSO: See also without Nerd Font:
#     BREW_APPS+=("--cask homebrew/cask-fonts/font-hack")
BREW_APPS+=("--cask font-hack-nerd-font")

# Some other text editor/terminal fonts I previewed, but
# not as much to the author's liking as Hack:
#
#   BREW_APPS+=("--cask font-daddy-time-mono-nerd-font")
#   BREW_APPS+=("--cask font-intone-mono-nerd-font")
#   BREW_APPS+=("--cask font-sauce-code-pro-nerd-font")

# Unifont adds some glyphs you won't otherwise see on @macOS, like
# the latter half of the *Miscellaneous Symbols and Arrows* block.
# - Note you don't need to explicitly use this font; it just needs
#   to exist and @macOS will fall back on it as necessary.
# https://unifoundry.com/unifont/
# https://formulae.brew.sh/cask/font-gnu-unifont
BREW_APPS+=("--cask font-gnu-unifont")

# --------------------------

# SAVVY: "htop requires root privileges to correctly display all running
# processes, so you will need to run `sudo htop`. / You should be certain
# that you trust any software you grant root privileges."
BREW_APPS+=("htop")
BREW_APPS+=("pstree")

BREW_APPS+=("pidof")

# --------------------------

BREW_APPS+=("grep")
# 2022-10-17: System `grep` is so much faster than Homebrew `ggrep`.
# - Though I could swear that, circa 2020-21, `ggrep` was speedier!
# - CXREF: See note atop `defaults-domains-dump` that shows when that
#   function uses /usr/bin/grep, it takes 1 sec., but when it uses
#   /opt/homebrew/bin/ggrep, it takes 31 seconds!
# Point being, don't link `ggrep` (and hopefully this doesn't break
# other parts of our environment.
#  USER_LINK+=("ggrep")

BREW_APPS+=("ag")

BREW_APPS+=("rg")

# - The `brew tap aykamko/tag` suggested by the README is incorrect:
#     https://github.com/aykamko/homebrew-tag-ag
#   Because `brew tap <user>/<repo>` is a shortcut to
#           `brew tap <user>/<repo> https://github.com/<user>/homebrew-<repo>`,
#   and there is no https://github.com/aykamko/homebrew-tag project.
# - So this is how you'd install tag-ag:
#     BREW_TAPS+=("aykamko/tag-ag")
#     BREW_APPS+=("tag-ag")
#   Alternatively, I think this format (without the tap) also works:
#     BREW_APPS+=("aykamko/tag-ag/tag-ag")
# - But don't install tag-ag.
#   - 2022-10-17: It worked for me on my previous MacBook (circa 2020-21)
#     but not on my new machine, where I see:
#       $ brew install aykamko/tag-ag/tag-ag
#       $ /opt/homebrew/bin/tag
#       Segmentation fault: 11
# So install from sources instead.
# - CXREF: ~/.depoxy/ambers/home/.kit/go/_mrconfig
#     $ mr -d ~/.depoxy/ambers/home/.kit/go/aykamko-tag install

# --------------------------

# *Collection of GNU find, xargs, and locate*
BREW_APPS+=("findutils")
USER_LINK+=("gfind")

# *find entries in the filesystem*
BREW_APPS+=("fd")
# *fzf - a command-line fuzzy finder*
BREW_APPS+=("fzf")

# --------------------------

# "Modern replacement for 'ls'".
# - ISOFF/2024-04-13: Brew install fails:
#   "Error: exa has been disbled because it is not maintained upstream!"
#  BREW_APPS+=("exa")

# "list contents of directories in a tree-like format."
BREW_APPS+=("tree")

# --------------------------

BREW_APPS+=("less")
# Useful for LESSOPEN, e.g.,
#   LESSOPEN="| highlight %s --out-format xterm256 --force"
BREW_APPS+=("highlight")

# "Clone of cat(1) with syntax highlighting and Git integration"
BREW_APPS+=("bat")

BREW_APPS+=("dhex")

# *Command-line JSON processor*
BREW_APPS+=("jq")

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
BREW_APPS+=("python-yq")

# --------------------------

#  # "Perl-powered file rename script with many helpful built-ins"
#  BREW_APPS+=("rename")

# Already installed:
#  BREW_APPS+=("unzip")

# --------------------------

# Add gsed, which is more rich than BSD sed.
BREW_APPS+=("gnu-sed")
USER_LINK+=("gsed")

# --------------------------

# "GNU implementation of time utility"
BREW_APPS+=("gnu-time")

# --------------------------

BREW_APPS+=("wget")

# SAVVY/2024-05-17: @macOS 14.4.1:  "rsync  version 2.6.9  protocol version 29"
#                   @linux LM 21.3: "rsync  version 3.2.7  protocol version 31"
BREW_APPS+=("rsync")
USER_LINK+=("rsync rsync")

# --------------------------

BREW_APPS+=("ctags")
# See also "ctags-exuberant", which I think identical to "ctags" formula.

# --------------------------

# Linux Mint 19.3 `awk` is actually `gawk`, FYI.
# (And I don't see plain `awk` installed; meaning,
#  all my Bash scripts expect `gawk`.)
BREW_APPS+=("gawk")
USER_LINK+=("gawk")  # Will symlink from ~/.local/bin/awk

# Installs `/opt/homebrew/bin/diff`.
BREW_APPS+=("diffutils")
# Note that brew's diff is `diff`, not `gdiff`,
# so use a two-word USER_LINK entry.
USER_LINK+=("diff diff")

# FIXME: A colorful diff utility I've yet to demo.
#        - See also: diff, git-diff, and meld.
BREW_APPS+=("colordiff")

# NOTE: App is not signed. See our `quarantine-release-apps`, or try:
#   xattr -dr com.apple.quarantine "/Applications/Meld.app"
#
# ISOFF/2024-04-15: Meld not yet released for Apple Silicon on Homebrew.
# - See slather-defauls for the OMR 'install' reminder.
add_meld_unless_apple_silicon () {
  # ALTLY: test "$(uname -p)" = "arm"  # vs. "i386"
  if [ "$(uname -m)" = "arm64" ]; then
    # Apple Silicon (not "x86_64" Intel).

    return 0
  fi

  BREW_APPS+=("--cask meld")
}
add_meld_unless_apple_silicon

# --------------------------

BREW_APPS+=("direnv")

# --------------------------

# "whois is key-only, which means it was not symlinked into /opt/homebrew,
# because macOS already provides this software and installing another
# version in parallel can cause all kinds of trouble."
BREW_APPS+=("whois")

# --------------------------

BREW_APPS+=("cloc")

# --------------------------

BREW_APPS+=("tldr")

# --------------------------

# Just as easily managed from pipx:
#  BREW_APPS+=("asciinema")

# --------------------------

BREW_APPS+=("cowsay")

# E.g., `/usr/local/bin/terminal-notifier -message "PATH=$PATH"`.
#  https://github.com/julienXX/terminal-notifier
BREW_APPS+=("terminal-notifier")

# --------------------------

BREW_APPS+=("restview")

# Big Install:
#  BREW_APPS+=("grip")

# Markdown GUI editor
# https://macdown.uranusjr.com/
# NOTE: App is not signed. See our `quarantine-release-apps`, or try:
#   xattr -dr com.apple.quarantine "/Applications/MacDown.app"
BREW_APPS+=("macdown")

# --------------------------

# INERT/2022-10-11: I haven't run tmux for work in ages.
#  BREW_APPS+=("tmux")

# Note that some organizations will offer iTerm2 from their app store.
BREW_APPS+=("iterm2")

# ILIKE/2024-06-23: I'm groovin' on Alacritty so far, simple and elegant.
# - And I think I'm over iTerm2, the immutable nuances are too many. 
BREW_APPS+=("--cask alacritty")

# Alacritty does not draw a border, which makes it hard to resize when
# it's overlapping other windows, because you cannot see the corner.
# - Fortunately there's Borders.
BREW_TAPS+=("FelixKratz/formulae")
BREW_APPS+=("borders")
# Call `brew services start borders`
BREW_SVCS+=("borders")

# --------------------------

# INERT/2022-10-11: If you find you need Mongo interface.
# - NOTE: On some client machines, you may need to start an
#   *Admin Access* terminal session to install Robo 3T.
#  BREW_APPS+=("robo-3t")

# --------------------------

BREW_APPS+=("imagemagick")

# HINT: To remove EXIF data from an image: `exiftool -all= image.jpg`.
BREW_APPS+=("exiftool")

# Other graphics apps you might want:
#  BREW_APPS+=("--cask blender")
#  BREW_APPS+=("--cask inkscape")

# --------------------------

# "PGF/TikZ diagram editor"
BREW_APPS+=("--cask tikzit")

# Dia: "Draw structured diagrams"
# - Also installs XQuartzx:
#     XQuartz: "An X11 server and client libraries for macOS"
#     BREW_APPS+=("--cask xquartz")
#
# ISOFF/2024-07-04: I tried Dia (and XQuartz) on @macOS
# but it blips the screen and runs XQuartz, but nothing
# else. Oh, well, I tried. (I enjoy this app on @Linux!)
# - From USAGE above:
#   # Dia requires --cask xquartz (X11 emulator) which requires pwd.
#   # - Also you need to *Open Anyway* via macOS Settings because not
#   #   signed ("not free from malware").
#   BREW_INCLUDE_DIA=true
if false && ${BREW_INCLUDE_DIA:-false}; then
  # NOTED: Prompts for PWD:
  #   ==> Running installer for xquartz with sudo; the password may be necessary.
  BREW_APPS+=("--cask dia")
fi

# "Free cross-platform office suite, fresh version"
BREW_APPS+=("--cask libreoffice")

# --------------------------

# SAVVY/2024-04-14: Don't install Homebrew Chrome over corporate
# version, if your laptop already came with Chrome installed.
add_google_chrome_unless_installed () {
  ! [ -e "/Applications/Google Chrome.app" ] \
    || return 0

  BREW_APPS+=("google-chrome")
}
add_google_chrome_unless_installed

add_firefox_unless_installed () {
  ! [ -e "/Applications/Firefox.app/" ] \
    || return 0

  BREW_APPS+=("--cask firefox")
}
add_firefox_unless_installed

# "A macOS app for customizing which browser to start"
# https://github.com/johnste/finicky
BREW_APPS+=("--cask finicky")

# --------------------------

# Slack might be installed by your organization...

if ! ${BREW_EXCLUDE_SLACK:-false}; then
  BREW_APPS+=("--cask slack")
fi

# --------------------------

# SPIKE/2022-10-11: Demo `procps`.
# *Command line and full screen utilities for browsing procfs*
# https://gitlab.com/procps-ng/procps
#  BREW_APPS+=("procps")

# --------------------------

# - Developer tools

# Golang. Not sure installing system-wide is best idea (is there
# Go environment virtualization like with Python and JS?).
# - But want Go to build aykamko-tag.
BREW_APPS+=("go")

BREW_APPS+=("node")
BREW_APPS+=("yarn")

BREW_APPS+=("rust")

BREW_APPS+=("pyenv")
# https://github.com/pyenv/pyenv-virtualenv
BREW_APPS+=("pyenv-virtualenv")

# For `mandb` (used by at least fries-findup's `make install`).
BREW_APPS+=("man-db")

# --------------------------

# - DB dev tools

# USYNC/2024-04-13: Must specify Postgres version.
#  https://formulae.brew.sh/formula/postgresql@16
BREW_APPS+=("postgresql@16")
# MAYBE/2022-11-15:
#   brew services stop postgresql
BREW_APPS+=("libpq")

# https://www.pgadmin.org/docs/
BREW_APPS+=("--cask pgadmin4")
# https://github.com/dbeaver/dbeaver
BREW_APPS+=("--cask dbeaver-community")

# --------------------------

# - API dev tools

BREW_APPS+=("--cask insomnia")
BREW_APPS+=("--cask postman")
BREW_APPS+=("openapi-generator")

# --------------------------

# - Code editors

# BREW_APPS+=("--cask visual-studio-code")

# 2023-01-06: Not going to the dark side (never leaving Vim for
# anything else) but I am curious if I can find a decent Python
# debugger GUI (mostly so it's easier to inspect variables).
# - VS Code (might be worth checking out)
# - PyCharm (licensed, but not that exensive)
# - Spyder
# - PyDev (can be installed into Eclipse; and is part of LiClipse)
#   https://www.pydev.org/
#   https://github.com/fabioz/Pydev
# - LiClipse (has brew install and includes PyDev → easiest route to PyDev)
#   https://www.liclipse.com/
#   https://formulae.brew.sh/cask/liclipse
# - Thonny
# - Wing IDE
# - eric
# - Atom
# - IDLE (the built-in interactive interpreter GUI app)
#   - If `idle` is on PATH but fails to run, try nonintuitive
#     command to run what's supposed to be a beginner's tool:
#       python -m idlelib.idle
# - See also: `pip install pdbr`, which improves upon pdb.
# SPIKE/2023-02-27: Demo LiClipse.
BREW_APPS+=("--cask liclipse")

# --------------------------

# - Containerization collections

# The Docker Desktop app includes its own docker and kubectl, so
# you either want to install all the pieces individually, and then
# use a container runtime such as `colima`; or, you only want to
# install Docker Desktop (what the --cask installs), and you'll
# get all the pieces from the one source.

# Try colima if you'd like your container ecosystem to be all CLI.
# - Though if you're new to containers, perhaps try Docker Desktop, at
#   least until you start grokking all the tools and how it all works.
if ${BREW_INCLUDE_COLIMA:-false}; then
  # Except for `colima`, Docker Desltop installs each of these apps
  # (and a few more) and symlinks them all from homebrew/bin.
  # - I'm not sure this is a complete list, this is just what I could
  #   find when I snooped around Docker Desktops application folder,
  #   specifically:
  #     /Applications/Docker.app/Contents/Resources/bin
  #     /Applications/Docker.app/Contents/Resources/cli-plugins/

  BREW_APPS+=("docker")
  # Included with `docker`:
  #  BREW_APPS+=("docker-completion")

  BREW_APPS+=("docker-compose")
  # Error w/ typo: "disabled because it no upstream support for v2!"
  #  BREW_APPS+=("docker-compose-completion")

  BREW_APPS+=("docker-credential-helper")

  # Note there's also `brew install kubectl`, which is a formula alias.
  BREW_APPS+=("kubernetes-cli")

  # "Container runtimes on MacOS (and Linux) with minimal setup"
  BREW_APPS+=("colima")
fi

# Docker Desktop kitchen sink GUI container app.
# - Docker Desktop is a one-stop container solution. It includes `docker`,
#   `docker-compose`, `kubectl`, and more.
# - It requires an enterprise license for large companies, but it's cheap.
# - You'll either want to install the standalone docker apps (from the
#   COLIMA section, above), or you'll want to install Docker Desktop, but
#   not both.
#   - You can technically run colima and Docker Desktop side-by-side.
# - If you try colima but want to return to Docker Desktop, install it all:
#     brew uninstall docker docker-compose docker-credential-helper kubernetes-cli colima
# - 2022-10-28: I first installed Docker Desktop from a DMG and it worked great.
#   Then I uninstalled Docker Desktop and installed colima and the docker standalone
#   tools, and my app worked... okay, but maybe there were issues? Then I uninstalled
#   the standalone docker apps but not colima, and I installed Docker Desktop from
#   Homebrew cask, and I had issues. Then I uninstalled colima, but still had issues.
#   Then I uninstalled the Docker Desktop cask, rebooted, and installed Docker Desktop
#   from the DMG file. And Now it's... sorta working again. I wish I knew containers
#   better!
#   - Also, TL_DR/2022-10-28: I currently suggest installing Docker Desktop from
#     the DMG file you get from their website, and not installing via HB cask.
#     At least not until I know more about what I'm doing.
if ${BREW_INCLUDE_DOCKER_DESKTOP:-false}; then
  BREW_APPS+=("--cask docker")
fi

# - Related containerization apps
#

# "GitOps Continuous Delivery for Kubernetes"
BREW_APPS+=("argocd")

# Helm manages Charts, packages of pre-configured Kubernetes resources.
# https://github.com/helm/helm
# AFAIK: Helm = Docker Image (w/ CMD -- is that Dockerfile, essentially?) + kubectl patches
BREW_APPS+=("helm")

# Packer creates machine images.
BREW_TAPS+=("hashicorp/tap")
BREW_APPS+=("hashicorp/tap/packer")

# "⎈ Multi pod and container log tailing for Kubernetes --
#  Friendly fork of https://github.com/wercker/stern"
# https://github.com/stern/stern
BREW_APPS+=("stern")

if ${BREW_INCLUDE_VIRTUALBOX:-false}; then
  # This is still the Intel version:
  #   BREW_APPS+=("--cask virtualbox")
  # Here's the Apple Silicone version.
  # - SAVVY: Prompts for PWD.
  BREW_APPS+=("--cask virtualbox@beta")
fi

# --------------------------

# - Crypto:

# Security stuff.
BREW_APPS+=("openssl")

BREW_APPS+=("pass")

BREW_APPS+=("pwgen")

# https://formulae.brew.sh/formula/pinentry-mac
# https://github.com/GPGTools/pinentry
BREW_APPS+=("pinentry-mac")

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

BREW_APPS+=("--cask wireshark")

# --------------------------

# - macOS Desktop Applications and Extensions:

# SAVVY/2024-04-24: On @macOS Sonoma, Apple shows an icon in the menu bar
# when AltTab is recording. Which is annoying. There is a work-around:
#   https://github.com/lwouis/alt-tab-macos/issues/2606
# - INERT: The author sets menu bar to auto-hide, so doesn't bother me.
BREW_APPS+=("--cask alt-tab")

# Alt-click-drag any desktop window to move it, like in Linux!
# NOTE: App is not signed. See our `quarantine-release-apps`, or try:
#   xattr -dr com.apple.quarantine "/Applications/Easy Move+Resize.app"
BREW_APPS+=("--cask easy-move-plus-resize")

# Sweet window utility.
#  https://rectangleapp.com/
#  https://github.com/rxhanson/Rectangle
BREW_APPS+=("--cask rectangle")

# 2022-10-16: GhostTile won't hide Finder, nor Pulse Secure, and I've got
# nothing else I want to hide, so not useful to me (with my latest client
# machine).
# - In the past I used it to keep Cisco AnyConnect out of the Dock
#   (which I could access from the menu bar, and only needed to run
#   once a day, so was otherwise wasting valuable Dock real estate).
#
#  BREW_APPS+=("--cask ghosttile")

# Ctrl-space shows fuzzy-find-enabled window list menu.
#   https://contexts.co/
# - Author has been looking for something like MATE's window-list
#   that I can use to quickly access specific windows with the mouse.
#   - Mission Control sorta works, but users can order window-list how
#     they like, so you can find a window just knowing where it "lives"
#     in the mate-panel window-list.
#   - Contexts is obviously different than window-list, but it shows a
#     compact, concise list of windows labeled and ordered well enough
#     to make it easy to find what I'm looking for — and allows me to
#     click to open or to use the keyboard. Which is what I'm looking
#     for, a convenient window switcher different than Alt-Tab,
#     different than Mission Control, different than the Dock, etc.
# - USAGE: Run Contexts.app via Spotlight to install it — Enable
#   Accessibility permissions, and wire to auto-start on boot.
#   - Also run Contexts via Spotlight to open its settings GUI —
#     because that window hides when it loses focus — or use
#     the Contexts <Ctrl+Space> menu to raise the hidden window.
BREW_APPS+=("--cask contexts")

# --------------------------

# 2022-12-04: lsusb (from Linux sources).
# - REFER: macOS alternatives:
#     ioreg -p IOUSB -l -w 0
#     system_profiler SPUSBDataType
# - CXREF: https://stackoverflow.com/questions/17058134/
#             is-there-an-equivalent-of-lsusb-for-os-x
BREW_APPS+=("mikhailai/misc/usbutils")

# --------------------------

# Hammerspoon is a Lua-powered desktop automation application.
#   https://www.hammerspoon.org/
#   https://www.hammerspoon.org/Spoons/
# - Config-based setup makes it easier to edit your keybindings:
# - Installs both /Applications/Hammerspoon.app and `hs` to PATH,
#   e.g., `/opt/homebrew/bin/hs`.
# - CALSO: Karabiner Elements (KE) (installed above).
BREW_APPS+=("--cask hammerspoon")

# --------------------------

# Opt-in because not dev-related, well, maybe ever dev
# rocks out, but maybe not from the Vendor's equipment.
if ${BREW_INCLUDE_SPOTIFY:-false}; then
  BREW_APPS+=("--cask spotify")
fi

# --------------------------

# - Rosetta 2 apps

MOSON_INSTALL_ROSETTA_2=false

if ${BREW_INCLUDE_DIGIKAM:-false}; then
  MOSON_INSTALL_ROSETTA_2=true

  BREW_APPS+=("--cask digikam")
fi

if ${BREW_INCLUDE_GNUCASH:-false}; then
  MOSON_INSTALL_ROSETTA_2=true

  # Prompts PWD.
  BREW_APPS+=("--cask gnucash")
fi

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

BREW_PATH=""

install_homebrew () {
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

  "$(dirname -- "$0")/../deps/Homebrew/install/install.sh"

  BREW_PATH="$(print_homebrew_path)"

  echo "Installed Homebrew to: ${BREW_PATH}"
  echo
}

# ***

# COPIED: From ~/.depoxy/ambers/core/brewskies.sh
# - Not sure I want to source that file as a dep,
#   or let this DRY violation continue to violate.
print_homebrew_path () {
  # Apple Silicon (arm64) brew path is /opt/homebrew.
  local brew_bin="/opt/homebrew/bin"

  # Otherwise on Intel Macs it's under /usr/local.
  [ -d "${brew_bin}" ] || brew_bin="/usr/local/bin"

  local brew_path="${brew_bin}/brew"

  printf "%s" "${brew_path}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY: Rosetta 2 installs instantaneously (so probably nothing
#        downloaded, more about agreeing to the license).
# - And you can ignore an error like this, or at least digiKam and
#   GnuCash still work:
#     2024-07-04 22:36:59.181 softwareupdate[3570:105238108] Package Authoring Error:
#       062-01890: Package reference com.apple.pkg.RosettaUpdateAuto is missing installKBytes attribute

install_rosetta_2_maybe () {
  ${MOSON_INSTALL_ROSETTA_2:-false} || return 0

  # Aka /usr/sbin/softwareupdate
  softwareupdate --install-rosetta --agree-to-license
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

init_homebrew_or_exit () {
  # Aka: "${HOMEBREW_PREFIX}/bin/brew"
  BREW_PATH="$(print_homebrew_path)"

  if [ ! -e "${BREW_PATH}" ]; then
    >&2 echo "ERROR: Missing Homebrew."

    exit_1
  fi

  eval "$(${BREW_PATH} shellenv)"
}

brew_install_taps () {
  init_homebrew_or_exit

  local brew_tap

  for brew_tap in "${BREW_TAPS[@]}"; do
    local tap_user="$(dirname -- "${brew_tap}")"
    local tap_repo="$(basename -- "${brew_tap}")"
    local brew_taps="$(brew --repository)/Library/Taps/"
    local local_tap="${brew_taps}/${tap_user}/homebrew-${tap_repo}"

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

brew_install_apps () {
  init_homebrew_or_exit

  local brew_app_or_cask

  for brew_app_or_cask in "${BREW_APPS[@]}"; do
    print_hr
    # Note that `brew info` shows info about any match, installed or not,
    # whereas `brew list` only shows info if the formula or cask is installed.
    if brew list ${brew_app_or_cask} > /dev/null 2>&1; then
      echo "Brew install: ${brew_app_or_cask} is already installed"
      echo
      brew info ${brew_app_or_cask} | print_Caveats && echo || true
      continue
    fi

    echo "Brew install: ${brew_app_or_cask}"
    echo
    brew install ${brew_app_or_cask}
    echo
  done
}

brew_link_apps () {
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

brew_start_services () {
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

print_Caveats () {
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
  ' \
  | tac | awk 'NF {p=1} p' | tac
  # ↑ Reverse output, trim leading empty lines, and reverse again
  #   to trim trailing empty lines.
  return ${PIPESTATUS[0]}
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

create_user_local_bin_symlinks () {
  init_homebrew_or_exit

  local homebrew_bin="${HOMEBREW_PREFIX}/bin"

  local user_local_bin="${HOME}/.local/bin"

  local before_cd="$(pwd -L)"

  mkdir -p "${user_local_bin}"
  cd "${user_local_bin}"

  [ -d "${homebrew_bin}" ] || (
    >&2 echo "ERROR: Where's Homebrew bin? It's not at: ${homebrew_bin}" &&
    return 1  # Because set -e, dies.
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
gbrew_symlink () {
  # If two words were specified (as one string), use `set` to split them.
  set -- $1
  local brew_app="$1"
  local bin_name="$2"

  local brew_path="${homebrew_bin}/${brew_app}"

  if [ ! -x "${brew_path}" ]; then
    >&2 echo "ERROR: Specified app not there or not executable: ${brew_path}"
    return 1  # Because set -e, dies.
  fi

  if [ -z "${bin_name}" ]; then
    bin_name="$(echo "${brew_app}" | sed 's/^g//')"
  fi

  echo "Symlinking: Wiring executable: ${brew_app} → ${bin_name}"
  ln -sf "${homebrew_bin}/${brew_app}" "${bin_name}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

print_hr () {
  echo "🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖☕🫖🫖🫖🫖🫖"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

os_is_macos () {
  [ "$(uname)" = 'Darwin' ]
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

clear_traps () {
  trap - EXIT INT
}

set_traps () {
  trap -- trap_exit EXIT
  trap -- trap_int INT
}

exit_0 () {
  clear_traps

  exit 0
}

exit_1 () {
  clear_traps

  exit 1
}

trap_exit () {
  clear_traps

  # USAGE: Alert on unexpected error path, so you can add happy path.
  >&2 echo "ALERT: "$(basename -- "$0")" exited abnormally!"
  >&2 echo "- Hint: Enable \`set -x\` and run again..."

  exit 2
}

trap_int () {
  clear_traps

  exit 3
}

# ***

main () {
  set -e

  set_traps

  os_is_macos || ( >&2 echo "ERROR: Not macOS" && return 1 )

  install_homebrew

  install_rosetta_2_maybe

  brew_install_taps
  brew_install_apps
  brew_link_apps
  brew_start_services

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

# DEV: Uncomment 'echo' below and source file to see BREW_APPS count.
#
#   # 2023-02-27: Today's count: 74.
#   $ . bin/install-homebrew.sh
#   No. BREW_APPS: 74
#
#  echo "No. BREW_APPS: ${#BREW_APPS[@]}"

