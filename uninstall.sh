#!/usr/bin/env bash

set -exv

shopt -q -o xtrace && DEBUG=1
shopt -q -o verbose && VERBOSE=1
[[ -n ${DEBUG:-} ]] && set -x
[[ -n ${VERBOSE:-} ]] && set -v

APPNAME="Locate" # One word is better
export APPNAME
APPNAMELC="$(LC=C tr "[:upper:]" "[:lower:]" <<<"$APPNAME")"
APPNAMELC="${APPNAMELC//[^a-z]/}"
export APPNAMELC

prefix="${XDG_DATA_HOME:-$HOME/.local/share}"
krunner_dbusdir="$prefix/krunner/dbusplugins"

rm -f "$krunner_dbusdir/${APPNAMELC:?}.desktop" || true
rm -f ~/.config/autostart/"${APPNAMELC:?}_autostart.desktop" || true
rm -f "$prefix/dbus-1/services/org.kde.${APPNAMELC:?}.service" || true
pkill -9 "$APPNAMELC.py" || true
kquitapp6 krunner >/dev/null 2>&1 || true
