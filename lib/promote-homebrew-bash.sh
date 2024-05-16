# vim:tw=0:ts=2:sw=2:et:norl:ft=bash
# Author: Landon Bouma <https://tallybark.com/>
# Project: https://github.com/DepoXy/macOS-onboarder#🏂
# License: MIT

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

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
    if ${PROMOTE_BASH_DEJA_VU:-false}; then
      >&2 echo "ERROR: Requires Bash v4 or better (and Homebrew bash <= v3?!)"

      exit_1
    fi

    >&2 echo "Shimming to Homebrew Bash..."

    # Run via Homebrew bash.
    PROMOTE_BASH_DEJA_VU=true exec "${brew_prefix}/bin/bash" "$0" "$@"
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

