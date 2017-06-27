xsetroot -solid black &
xcompmgr -c -f -D 5 &
xrdb -load ~/.Xresources
exec /usr/bin/ratpoison
