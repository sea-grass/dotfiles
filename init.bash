#!/bin/bash
# dotfiles/init.bash
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
dots="$root/dots"

error() {
  msg="$1"
  printf "ERRO:\n\t%s\nExiting.\n" "$msg" >&2
  exit 1
}

zig build cmd -freference-trace=11
if ! zig build cmd; then
  error "Could not build cmd"
fi
cmd="./zig-out/bin/cmd"

"$cmd" install_dots "$dots"
