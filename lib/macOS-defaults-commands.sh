# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/macOS-onboarder#🏂
# License: MIT

# Copyright (c) © 2022-2023 Landon Bouma. All Rights Reserved.

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

defaults-domains-list () {
  defaults domains | sed "s/, \?/\n/g" | sort
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# Use the blocklist to squelch domains (a) that do not actually exist
# (I see at least 18 such domains that `defaults domains` reports, such
#  as "com.apple.commerce", that `defaults read <domain>` prints msg on.);
# or (b) that don't contain any settings that you care about, so that
# running either `defaults-domains-dump` or `meld-last-two-dumps` will be
# quicker because there are fewer domains being processed.
DEFAULTS_SH_BLOCKLIST="lib/defaults-domains-block.list"

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

# SAVVY/2023-02-27: Note that macOS system grep, at least on an M1
# recently, is much, much slower than Homebrew ggrep.
#
# - E.g.,
#   grep:  `date && defaults-domain-dump && date`: 31 seconds
#   ggrep: `date && defaults-domain-dump && date`:  1 second

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

defaults-domains-dump () {
  # Be nice to user and don't surprise them with a ton of new files in
  # their working directory. Also to help `meld-last-two-dumps` work.
  local unique_dir="domains_dump__$(date +%Y%m%d%H%M%S)"

  mkdir "${unique_dir}"
  cd "${unique_dir}"

  while read name; do
    # Check the blocklist.
    local blocklist="${DEFAULTS_SH_ROOT}/${DEFAULTS_SH_BLOCKLIST}"

    [ "$1" != "--all" ] && grep -q -e "^${name}\$" "${blocklist}" && continue

    echo "Dumping domain: ${name}"

    defaults read "${name}" > "${name}.plist"
  done <<<"$(defaults-domains-list)"
  # Get Bashy with it: This also works:
  #  done < <(defaults-domains-list)

  # Note the "Apple Global Domain" is not listed by `defaults domains`,
  # though it is mentioned in `man defaults`. But what that doesn't say
  # is that most people call it NSGlobalDomain (both work). (And, what,
  # I assume the "NS" stands for NeXTSTEP?!)
  #  # Also works:
  #  defaults read "Apple Global Domain" > _apple_global_domain.plist
  defaults read NSGlobalDomain > _apple_global_domain__nsglobaldomain.plist

  # Also dump all settings together, in case the blocklist hid a domain for
  # a setting the user changed. This should enable `meld-last-two-dumps` to
  # always reveal the domain and key-value of what changed (unless said
  # setting is stored outside the realm of macOS-managed propertly lists).
  defaults read > _all_defaults.plist

  cd ".."

  echo "Your domains dump is ready under the new directory:"
  echo "  ${unique_dir}"
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

meld-last-two-dumps () {
  meld "$(/bin/ls -1 | tail -2 | head -1)" "$(/bin/ls -1 | tail -1)" &
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

apply-macos-defaults () {
  ${DEFAULTS_SH_ROOT}/slather-defaults.sh
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

declare -a QUARANTINE_PARDONS=()
QUARANTINE_PARDONS+=("Easy Move+Resize.app")
QUARANTINE_PARDONS+=("MacDown.app")
QUARANTINE_PARDONS+=("Meld.app")

# Use `xattr -dr` to recursively delete attribute name-value.
# If you wanted to inspect an attribute, print it, e.g.,
#   $ xattr -p com.apple.quarantine /Applications/Easy\ Move+Resize.app
#   0181;6334e1ba;Homebrew\x20Cask;A30E92DD-XXXX-XXXX-XXXX-XXXXXXXXXXXX

quarantine-release-apps () {
  for pardon_me in "${QUARANTINE_PARDONS[@]}"; do
    echo "Pardoning app: ${pardon_me}"

    xattr -dr com.apple.quarantine "/Applications/${pardon_me}"
  done
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

default-print-help () {
  cat <<- EOF
You can now try the following commands:

  default-print-help            Print this message

  defaults-domains-list         List all the defaults domains, sorted

  defaults-domains-dump         Write each domain\'s key-values to a file, all saved to a new directory

  defaults-domains-dump --all   Ignore the defaults-domains-block.list filter

  meld-last-two-dumps           Run meld on the last dumps (last two items \`ls\` shows)

  apply-macos-defaults          Run all your favorite \`defaults write\` key-values!

  apply-macos-defaults --tame   Skip \`killall\` calls and anything interruptive

  quarantine-release-apps       Unrestrict unsigned applications (Meld, Easy Move+Resize, etc.)
EOF
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ #

main () {
  DEFAULTS_SH_ROOT="$(realpath $(dirname ${BASH_SOURCE[0]}))"

  [ -z "${DEFAULTS_SH_ROOT}" ] &&
    >&2 echo "Please source me from Bash!" &&
    exit 1

  default-print-help
}

if ! $(printf %s "$0" | grep -q -E '(^-?|\/)(ba|da|fi|z)?sh$' -); then
  # Being executed.
  echo "Does nothing. Try to source this file instead. “Gedgie out!”"
  exit 1
else
  main "$@"
  unset -f main
fi

