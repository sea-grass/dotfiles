#!/bin/bash
# dotfiles/init.bash
root=$(cd -- "$(dirname -- '${BASH_SOURCE[0]}')" &> /dev/null && pwd)
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

  if [ -h "$link_name" ]; then
    if [ "$target" -ef "$link_name" ]; then
      verbose "link \"$link_name\" already exists"
    else
      error "link \"$link_name\" already exists but points to a different file. Not overwriting"
    fi
  elif [ -f "$link_name" ]; then
    error "link \"$link_name\" is a real file. Not overwriting"
  else
    ln -s "$target" "$link_name"
  fi
}

download() {
  [ $# -eq 2 ] || error "download requires 2 arguments"
  url="$1"
  destination_file="$2"
  info "download $url -> $destination_file"

  if [ -f "$destination_file" ]; then
    verbose "download destination file \"$destination_file\" already exists. Not overwriting"
  else
    wget -O "$destination_file" "$url"
  fi

}

apt_install() {
  [ $# -eq 1 ] || error "apt_install requires 1 argument"
  package="$1"
  info "apt_install $package"

  if dpkg -s "$package" 2>/dev/null | grep -q "Package: $package"; then
    verbose "apt_install package $package already installed. Nothing to do"
  else
    info "apt_install needs to install package $package. You may need to enter your password for sudo privilege"
    sudo apt install "$package"
  fi
}

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
  for download_command in $(find "$section" -type f -name '*.download'); do
    pat='(.+)->~/(.+)'
    download_data=$(head -1 "$download_command")
    [[ "$download_data" =~ $pat ]] || error "download [$section/$download_command] has malformed contents"
    url="${BASH_REMATCH[1]}"
    destination_file="$HOME/${BASH_REMATCH[2]}"

    download "$url" "$destination_file"
  done
  for apt_command in $(find "$section" -type f -name '*.apt'); do
    if ! { type apt-get 1>/dev/null 2>&1; }; then
      info "apt-get is not present on this system. Not installing dependencies for [$section/$apt_command]"
    else
      apt_data=( $(cat "$apt_command") )
      for package in $apt_data; do
        apt_install "$package"
      done
    fi
  done
done
