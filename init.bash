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
  while IFS= read -r -d '' dir_command; do
    # shellcheck disable=SC2088 # Tilde should not be expanded
    pat='~/(.+)'
    dir_data=$(head -1 "$dir_command")

    [[ "$dir_data" =~ $pat ]] || error "dir [$section/$dir_command] has malformed contents"
    dir="$HOME/${BASH_REMATCH[1]}"

    "$cmd" direxists "$dir"
  done < <(find "$section" -type f -name '*.dir' -print0)

  while IFS= read -r -d '' link_command; do
    pat='(.+)->~/(.+)'
    link_data=$(head -1 "$link_command")   

    [[ "$link_data" =~ $pat ]] || error "link [$section/$link_command] has malformed contents"
    target="$section/${BASH_REMATCH[1]}"
    link_name="$HOME/${BASH_REMATCH[2]}"
    
    "$cmd" link "$target" "$link_name"
  done < <(find "$section" -type f -name '*.link' -print0)

  while IFS= read -r -d '' download_command; do
    pat='(.+)->~/(.+)'
    download_data=$(head -1 "$download_command")

    [[ "$download_data" =~ $pat ]] || error "download [$section/$download_command] has malformed contents"
    url="${BASH_REMATCH[1]}"
    destination_file="$HOME/${BASH_REMATCH[2]}"

    "$cmd" download "$url" "$destination_file"
  done < <(find "$section" -type f -name '*.download' -print0)

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
