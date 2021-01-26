#!/usr/bin/env bash

shopt -q -o xtrace && DEBUG=1
shopt -q -o verbose && VERBOSE=1
[[ -n ${DEBUG:-} ]] && set -x
[[ -n ${VERBOSE:-} ]] && set -v

APPNAME=Notes
export APPNAME
APPNAMELC="$(LC=C tr "[:upper:]" "[:lower:]" <<<"${APPNAME}")"
export APPNAMELC
PROJECTDIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" || die "Could not find PROJECTDIR"
    pwd -P || die "Could not find PROJECTDIR"
)"
export PROJECTDIR
rm -f ~/.config/autostart/"${APPNAMELC:?}_autostart".desktop || true
rm -f ~/.local/share/kservices5/plasma-runner-"${APPNAMELC:?}".desktop || true
rm -f ~/.local/share/dbus-1/services/org.kde."${APPNAMELC:?}".service || true
rm -f "${PROJECTDIR}/${APPNAMELC:?}.py" || true
kquitapp5 krunner
