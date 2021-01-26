#!/usr/bin/env bash

shopt -q -o xtrace && DEBUG=1
shopt -q -o verbose && VERBOSE=1
[[ -n ${DEBUG:-} ]] && set -x
[[ -n ${VERBOSE:-} ]] && set -v

: "${me:="${0##*/}"}"
if [[ -n "$(command -v notify-send)" ]]; then
    notify() {
        notify-send "$@"
    }
else
    notify() {
        echo "$@" >&2
    }
fi
warn() {
    printf "%s:: \e[0;31m%s\e[0m" "${me}" "$*" >&2
    notify "Error: ${me}" "$*" || true
}
die() {
    warn "${@}"
    exit 1
}
APPNAME=Locate
export APPNAME
APPNAMELC="$(LC=C tr "[:upper:]" "[:lower:]" <<<"${APPNAME}")"
export APPNAMELN
PROJECTDIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" || die "Could not find PROJECTDIR"
    pwd -P || die "Could not find PROJECTDIR"
)"
export PROJECTDIR
EMAIL="$(git config user.email)" || die "Could not find EMAIL"
export EMAIL
AUTHOR="$(git config user.name) (${USER})" || die "Could not find AUTHOR"
export AUTHOR

render() {
    local src dest
    src="${1:?}"
    dest="${2:?}"
    mkdir -p "$(dirname "${dest}")"
    cp "${src}" "${dest}"
    sed -i -e "s|%{AUTHOR}|${AUTHOR}|g" "${dest}"
    sed -i -e "s|%{APPNAME}|${APPNAME}|g" "${dest}"
    sed -i -e "s|%{APPNAMELC}|${APPNAMELC}|g" "${dest}"
    sed -i -e "s|%{EMAIL}|${EMAIL}|g" "${dest}"
    sed -i -e "s|%{PROJECTDIR}|${PROJECTDIR}|g" "${dest}"
}
render "${PROJECTDIR}/plasma-runner-%{APPNAMELC}.desktop" ~/.local/share/kservices5/plasma-runner-"${APPNAMELC}.desktop"
render "${PROJECTDIR}/%{APPNAMELC}_autostart.desktop" ~/.config/autostart/"${APPNAMELC}_autostart.desktop"
render "${PROJECTDIR}/org.kde.%{APPNAMELC}.service" ~/.local/share/dbus-1/services/"org.kde.${APPNAMELC}.service"
render "${PROJECTDIR}/%{APPNAMELC}.py" "${PROJECTDIR}/${APPNAMELC}.py"

command rm -rf ~/.cache/krunner || true
kquitapp5 krunner
