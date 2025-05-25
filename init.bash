#!/bin/bash
# dotfiles/init.bash
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
dots="$root/dots"

error() {
  msg="$1"
  printf "ERRO:\n\t%s\nExiting.\n" "$msg" >&2
  exit 1
}

info() {
  msg="$1"
  printf "Info:\n\t%s\n" "$msg"
}

verbose() {
  [ "$DOTS_VERBOSE" == "1" ] || return
  msg="$1"
  printf "VERB:\n\t%s\n" "$msg"
}

zig build cmd -freference-trace=11
if ! zig build cmd; then
  error "Could not build cmd"
fi
cmd="./zig-out/bin/cmd"

while IFS= read -r -d '' section; do
  "$cmd" install_dots_section "$section"
done < <(find "$dots" -mindepth 1 -maxdepth 1 -type d -print0)
