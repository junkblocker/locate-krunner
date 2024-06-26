#!/usr/bin/env bash

set -euo pipefail

APPNAME="Locate" # One word is better
export APPNAME

shopt -q -o xtrace && DEBUG=1
shopt -q -o verbose && VERBOSE=1
[[ -n ${DEBUG:-} ]] && set -x
[[ -n ${VERBOSE:-} ]] && set -v

: "${me:="${0##*/}"}"
die() {
    printf "%s:: \e[0;31m%s\e[0m" "$me" "$*" >&2
    exit 1
}
APPNAMELC="$(LC=C tr "[:upper:]" "[:lower:]" <<<"$APPNAME")"
APPNAMELC="${APPNAMELC//[^a-z]/}"
export APPNAMELC
PROJECTDIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" || die "Could not find PROJECTDIR"
    pwd -P || die "Could not find PROJECTDIR"
)"
export PROJECTDIR
EMAIL="$(git config user.email)" || die "Could not find EMAIL"
export EMAIL
AUTHOR="$(git config user.name) ($USER)" || die "Could not find AUTHOR"
export AUTHOR

render() {
    local src dest
    src="${1:?}"
    dest="${2:?}"
    mkdir -p "$(dirname "$dest")"

    local tmpf
    tmpf="${TMPDIR:-/tmp}/${dest##*/}.$$"
    cp "$src" "$tmpf"
    sed -i -e "s|%{AUTHOR}|$AUTHOR|g" "$tmpf"
    sed -i -e "s|%{APPNAME}|$APPNAME|g" "$tmpf"
    sed -i -e "s|%{APPNAMELC}|$APPNAMELC|g" "$tmpf"
    sed -i -e "s|%{EMAIL}|$EMAIL|g" "$tmpf"
    sed -i -e "s|%{PROJECTDIR}|$PROJECTDIR|g" "$tmpf"
    mv -f "$tmpf" "$dest"
}
prefix="${XDG_DATA_HOME:-$HOME/.local/share}"
krunner_dbusdir="$prefix/krunner/dbusplugins"
services_dir="$prefix/dbus-1/services/"

mkdir -p "$krunner_dbusdir" || die "Could not create directory $krunner_dbusdir"
mkdir -p "$services_dir" || die "Could not create directory $services_dir"

render "$PROJECTDIR/%{APPNAMELC}.desktop" "$krunner_dbusdir/$APPNAMELC.desktop"
render "$PROJECTDIR/%{APPNAMELC}_autostart.desktop" ~/.config/autostart/"${APPNAMELC}_autostart.desktop"
render "$PROJECTDIR/org.kde.%{APPNAMELC}.service" "$services_dir/org.kde.$APPNAMELC.service"
render "$PROJECTDIR/%{APPNAMELC}.py" "$PROJECTDIR/$APPNAMELC.py"
render "$PROJECTDIR/krunner-plugininstallerrc.template" "$PROJECTDIR/krunner-plugininstallerrc"

command rm -rf ~/.cache/krunner || true
kquitapp6 krunner >/dev/null 2>&1 || true
dex-autostart ~/.config/autostart/"${APPNAMELC}_autostart.desktop"
echo "Done."
