Knarley `brew install` and `defaults` 🏂
========================================

## DESCRIPTION

  Opinionated macOS onboarder.

## COMMANDS

  [`bin/install-homebrew.sh`](bin/install-homebrew.sh)
  brew-installs 74 [Homebrew](https://brew.sh/) apps
  and counting

  [`slather-defaults.sh`](slather-defaults.sh)
  updates 127 macOS `defaults`
  and counting

  - **ALERT**: Most apps' Menu and Keyboard Shortcuts are
    changed to match Linux conventions 🤪

  [`macOS-defaults-commands.sh`](macOS-defaults-commands.sh)
  is a collection of useful shell commands.

  - Source the file 

        . lib/macOS-defaults-commands.sh

    to see the list of its commands.

    - E.g., `defaults-domains-dump` dumps `defaults read` from all domains

## Will you find this useful?

  Probably not if you expect to run it and be happy.

  But if you're looking for a framework to manage your
  own Brew apps and `defaults` settings, here you go!

  - Feel free to fork this repo and hack away.

## SEE ALSO

  This project complements a collection of Karabiner-Elements
  modifications that add bindings beyond the reach of `defaults`

  https://github.com/DepoXy/Karabiner-Elephants#🐘

  This project is one part of a larger dev stack bound together
  by the DepoXy Development Environment Orchestrator

  https://github.com/DepoXy/depoxy#🍯

  which extends the `slather-defaults` behavior:

  https://github.com/DepoXy/depoxy/blob/release/bin/macOS/onboarder/slather-defaults.sh

## AUTHOR

Copyright (c) 2021-2024 Landon Bouma &lt;depoxy@tallybark.com&gt;

This software is released under the MIT license (see `LICENSE` file for more)

## REPORTING BUGS

&lt;https://github.com/DepoXy/macOS-onboarder/issues&gt;

