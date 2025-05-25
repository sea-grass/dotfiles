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
  "$cmd" all:direxists "$section"
  "$cmd" all:link "$section"
  "$cmd" all:download "$section"

  while IFS= read -r -d '' apt_command; do
    if ! { type apt-get 1>/dev/null 2>&1; }; then
      info "apt-get is not present on this system. Not installing dependencies for [$section/$apt_command]"
    else
      mapfile -t apt_data < <(cat "$apt_command")
      for package in "${apt_data[@]}"; do
        "$cmd" apt_install "$package"
      done
    fi
  done < <(find "$section" -type f -name '*.apt')
done < <(find "$dots" -mindepth 1 -maxdepth 1 -type d -print0)
