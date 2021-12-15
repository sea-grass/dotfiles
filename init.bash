#!/bin/bash
# dotfiles/init.bash

root=$(cd -- "$(dirname -- '${BASH_SOURCE[0]}')" &> /dev/null && pwd)
dots="$root/dots"

error() {
  msg="$1"
  printf "Error: %s\nExiting.\n" "$msg" >&2
  exit 1
}

info() {
  msg="$1"
  printf "Info: %s\n" "$msg"
}

verbose() {
  [ "$DOTS_VERBOSE" == "1" ] || return
  msg="$1"
  printf "INFO: %s\n" "$msg"
}

direxists() {
  [ $# -eq 1 ] || error "direxists requires 1 argument"
  dir="$1"

  info "direxists $dir"
  mkdir -p "$dir"
}

link() {
  [ $# -eq 2 ] || error "link requires 2 arguments"
  target="$1"
  link_name="$2"

  info "link \"$target\" \"$link_name\""
  [ -a "$target" ] || error "target \"$target\" does not exist"

  [ -f "$link_name" ] || error "link \"$link_name\" is a real file. Not overwriting"

  if [ -h "$link_name" ]; then
    if [ "$target" -ef "$link_name" ]; then
      verbose "link \"$link_name\" already exists"
    else
      error "link \"$link_name\" already exists but points to a different file. Not overwriting"
    fi
  else
    ln -s "$target" "$link_name"
  fi
}

# kitty
for section in $(find "$dots" -mindepth 1 -maxdepth 1 -type d); do
  for dir_command in $(find "$section" -type f -name '*.dir'); do
    pat='~/(.+)'
    dir_data=$(head -1 "$dir_command")
    [[ "$dir_data" =~ $pat ]] || error "dir [$section/$dir_command] has malformed contents"
    dir="$HOME/${BASH_REMATCH[1]}"
    direxists "$dir"
  done
  for link_command in $(find "$section" -type f -name '*.link'); do
    pat='(.+)->~/(.+)'
    link_data=$(head -1 "$link_command")   
    [[ "$link_data" =~ $pat ]] || error "link [$section/$link_command] has malformed contents"
    target="$section/${BASH_REMATCH[1]}"
    link_name="$HOME/${BASH_REMATCH[2]}"
    
    link "$target" "$link_name"
  done
done
