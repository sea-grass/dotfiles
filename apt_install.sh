#!/bin/bash
# dotfiles/apt_install.bash

error() {
  msg="$1"
  printf "error: %s\nExiting.\n" "$msg" >&2
  exit 1
}

info() {
  msg="$1"
  printf "info: %s\n" "$msg"
}

verbose() {
  [ "$DOTS_VERBOSE" == "1" ] || return
  msg="$1"
  printf "debug: %s\n" "$msg"
}

if ! { type apt-get 1>/dev/null 2>&1; }; then
  error "apt-get is not present on this system."
fi

[ $# -eq 1 ] || error "apt_install requires 1 argument"
package="$1"
info "apt_install $package"

if dpkg -s "$package" 2>/dev/null | grep -q "Package: $package"; then
  verbose "apt_install package $package already installed. Nothing to do"
else
  info "apt_install needs to install package $package. You may need to enter your password for sudo privilege"
  sudo apt install "$package"
fi
