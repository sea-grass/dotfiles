DESTDIR=`echo $HOME`
SOURCEDIR=`pwd`

array_test[0]="test" || (echo "Error: arrays not supported in this version of bash" && exit 2)

#List of dotfiles in this repo
dotfiles=(
  "screenrc"
  "vimrc"
  "bash_profile"
  "Xresources"
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
