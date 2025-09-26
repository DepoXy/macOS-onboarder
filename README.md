Gnarly `brew install` × Shrewd `defaults` (macOS) ᴼᴿ `gsettings` (GNOME) settings 🏂
====================================================================================

## DESCRIPTION

  Opinionated macOS and GNOME Shell onboarders.

## COMMANDS

  [`bin/install-homebrew.sh`](bin/install-homebrew.sh)
  brew-installs 74 [Homebrew](https://brew.sh/) apps
  and counting, for macOS and GNOME.

  [`bin/slather-defaults.sh`](bin/slather-defaults.sh)
  manages 127 macOS `defaults`
  and counting.

  [`bin/slather-gsettings.sh`](bin/slather-gsettings.sh)
  manages 176 GNOME `gsettings`
  and counting.

- This project also includes two small shell function libraries
  to help manage user settings.

  See [`macOS-defaults-commands.sh`](lib/macOS-defaults-commands.sh)
  for a collection of useful macOS shell commands.

  See [`linux-gsettings-commands.sh`](lib/linux-gsettings-commands.sh)
  for a collection of useful GNOME shell commands.

## Will you find this useful?

  Of course! Everyone can benefit from customizing their
  desktop environment.

- Just be aware that the settings applied by this project
  are very opinionated.

  - For instance, on macOS, most apps' Menu and Keyboard Shortcuts
    are changed to match Linux conventions 🤪 — mostly swapping
    the &lt;Ctrl&gt; key for the &lt;Command&gt; key.

    This helps maintain parity between macOS and GNOME,
    so you can move fluidly between the two without
    having to think about the keyboard differently.

  - But feel free to fork this repo and hack away.

    It includes most the settings you'll find in
    the macOS Settings and GNOME settings GUIs,
    as well as lots of additional, hidden settings.

    It should make a good starting point for you to
    manage your own settings preferences!

Here's how you might use this project:

- Fork it so you can manage your own Brew apps and
  `defaults` or `gsettings` (and `dconf`) settings!

- Poke around and look for inspiration for customizing
  your own desktop environment!

And feel free to submit Pull Requests for improvements.
But you'd likely need to have a decent argument for
changing any keybindings. I'd love other improvements,
though — I'm always seeking ways to improve my desktop
experience.

## Usage

  Because this project is mostly intended for me, your
  author, you'll find most of the documentation embedded
  as comments in each script.

  But you'll also find that most commands have a typical
  CLI interface.

  For instance, you can *dry-run* the `gsettings`
  script, and it'll report the changes it will make,
  e.g.,

        $ ./bin/slather-gsettings.sh --dry-run
        Slathering gsettings...

        *** GNOME Settings

          Settings > Appearance > Style:
            'default' → 'prefer-dark' 🔨

        ...

  See the top of each script for addition usage help.

It's also easy to use the shell libraries.

- Source either `lib/` file to see the list of its commands.

  For macOS:

        $ . lib/macOS-defaults-commands.sh
        You can now use the following commands:

          default-print-help            Print this message

          defaults-domains-list         List all the defaults domains, sorted

          defaults-domains-dump         Write each domain's key-values to a
                                        file, all saved to a new directory
        ...

  - The `defaults-domains-dump` command, for instance,
    prints `defaults read` output from all domains.

  Or for GNOME:

        $ . lib/linux-gsettings-commands.sh
        You can now use the following commands:

          gsettings-print-help          Print this message

          gsettings-schemas-list        List all the defaults domains, sorted

          gsettings-schemas-dump        Write each domain's key-values to a
                                        file, all saved to a new directory
        ...

  Obviously, you don't need either library file, but they're
  good reminders of what you can do, especially if you haven't
  used `defaults` or `gsettings` recently (or ever).

## SEE ALSO

  For a sick collection of powerful macOS keybindings to
  further empower and supercharge your desktop environment,
  check out this collection of Hammerspoon Spoons:

  <https://github.com/DepoXy/macOS-Hammyspoony>🥄

  For the GNOME equivalent (*almost*) of Hammerspoon, check out the fabulous
  [`run-or-raise`](https://extensions.gnome.org/extension/1336/run-or-raise/)
  Shell extension.

  Many of the author's projects are each part of a larger dev stack
  bound together by the DepoXy Development Environment Orchestrator:

  <https://github.com/DepoXy/depoxy>🍯

  which extends the [`slather-defaults.sh`](./bin/slather-defaults.sh)
  behavior found in this project (to add even more opinionated
  settings for other applications and features that DepoXy supports).

  - See this file for how DepoXy extends this project:

    <https://github.com/DepoXy/depoxy/blob/release/bin/onboarder/slather-defaults.sh>

  DepoXy also leverages both Hammerspoon (on macOS) and
  `run-or-raise` (on GNOME) to further customize and
  elevate the desktop and development environment experiences.

  - You'll find the DepoXy Hammerspoon config here:

    <https://github.com/DepoXy/depoxy/blob/release/home/.hammerspoon/depoxy-hs.lua>

    - Note that DepoXy wires Hammerspoon so that it loads
      the Hammyspoony config, the DepoXy config, and also
      and optional, private user config.

  - You'll find the DepoXy `run-or-raise` config here:

    <https://github.com/DepoXy/depoxy/blob/release/home/.config/run-or-raise/shortcuts-depoxy>

    - Because `run-or-raise` does not support loading more
      than one config file (i.e., you cannot *import* additional
      config into the main config), DepoXy defines a bespoke
      shell function, `reload-run-or-raise`, that builds a
      `run-or-raise` config from both the (public) DepoXy
      `run-or-raise/shortcuts.conf` file, as well as an
      optional (private) user config file.

## AUTHOR

Copyright (c) 2021-2025 Landon Bouma &lt;<depoxy@tallybark.com>&gt;

This software is released under the MIT license (see [`LICENSE`](./LICENSE) file for more)

## REPORTING BUGS

&lt;<https://github.com/DepoXy/macOS-onboarder/issues>&gt;
