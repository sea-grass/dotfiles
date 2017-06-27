tt() {
  today="$HOME/timesheet/$(date +%Y-%m-%d).txt"
  touch "$today"

  # If no arguments are given, print the existing timesheet
  if [ $# -eq 0 ]; then
    cat "$today"
  else
    echo "`date +%H:%M` $USER: $@" >> "$today";
  fi
}
