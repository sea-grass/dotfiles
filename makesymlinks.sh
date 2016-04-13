if [ "x$DOTFILES" = "x" ]; then
  echo "WARNING: DOTFILES environment variable must be set. Did NOTHING."
  echo 'Hint: Try DOTFILES="`pwd`" ./makesymlinks'
  exit
fi

DESTDIR=$HOME
#Get SOURCEDIR from DOTFILES environment variable
SOURCEDIR="$DOTFILES"/dots




array_test[0]="test" || (echo "Error: arrays not supported in this version of bash" && exit 2)

#List of dotfiles in this repo
dotfiles=(
  "bash_profile"
  "bashrc"
  "screenrc"
  "vimrc"
  "Xresources"
  "tmux.conf"
  "jsbeautifyrc"
)

clearexisting () {
  if [ -z "$1" ]
  then
    echo "Error!"
    exit 0
  fi

  rm $DESTDIR/.$1
}

makelink () {
  if [ -z "$1" ]
  then
    echo "Error!"
    exit 0
  fi

  echo "ln -s $SOURCEDIR/$1 $DESTDIR/.$1"
  ln -s $SOURCEDIR/$1 $DESTDIR/.$1
  echo "made link $DESTDIR/.$1 -> $SOURCEDIR/$1"
}

index=0
while [ "x${dotfiles[index]}" != "x" ]
do
  clearexisting ${dotfiles[index]}
  makelink ${dotfiles[index]}

  index=$(( $index + 1 ))
done
